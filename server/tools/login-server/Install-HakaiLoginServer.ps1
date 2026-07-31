[CmdletBinding()]
param(
    [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$serverRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$runtimeRoot = [System.IO.Path]::GetFullPath((Join-Path $serverRoot ".hakai-runtime\login-server"))
$lockPath = Join-Path $PSScriptRoot "login-server.lock.json"

function Assert-ChildPath {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Candidate
    )

    $rootWithSeparator = $Root.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $Candidate.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing path outside the server repository: $Candidate"
    }
}

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)

    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-VerifiedDownload {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$ExpectedSha256,
        [Parameter(Mandatory)][string]$Destination
    )

    if (-not $Url.StartsWith("https://", [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Only HTTPS downloads are allowed: $Url"
    }

    if (Test-Path -LiteralPath $Destination) {
        $actual = Get-Sha256 -Path $Destination
        if ($actual -ne $ExpectedSha256.ToUpperInvariant()) {
            throw "Cached archive hash mismatch: $Destination"
        }
        return
    }

    $temporary = "$Destination.$([guid]::NewGuid().ToString('N')).partial"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
            & $curl.Source -L --fail --silent --show-error --output $temporary $Url
            if ($LASTEXITCODE -ne 0) {
                throw "curl.exe failed to download $Url"
            }
        }
        else {
            Invoke-WebRequest -Uri $Url -OutFile $temporary -UseBasicParsing
        }
        $actual = Get-Sha256 -Path $temporary
        if ($actual -ne $ExpectedSha256.ToUpperInvariant()) {
            throw "Downloaded archive hash mismatch for $Url"
        }
        Move-Item -LiteralPath $temporary -Destination $Destination
    }
    finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }
}

function Assert-SafeZip {
    param([Parameter(Mandatory)][string]$ArchivePath)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName.Replace('\', '/')
            if ([System.IO.Path]::IsPathRooted($name) -or $name -match '(^|/)\.\.(/|$)') {
                throw "Unsafe path in archive: $name"
            }
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Expand-VerifiedArchive {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$ArchiveSha256,
        [Parameter(Mandatory)][string]$Destination
    )

    Assert-SafeZip -ArchivePath $ArchivePath
    $staging = "$Destination.staging-$([guid]::NewGuid().ToString('N'))"
    $backup = "$Destination.backup-$([guid]::NewGuid().ToString('N'))"
    Assert-ChildPath -Root $runtimeRoot -Candidate ([System.IO.Path]::GetFullPath($Destination))
    Assert-ChildPath -Root $runtimeRoot -Candidate ([System.IO.Path]::GetFullPath($staging))
    Assert-ChildPath -Root $runtimeRoot -Candidate ([System.IO.Path]::GetFullPath($backup))

    try {
        Expand-Archive -LiteralPath $ArchivePath -DestinationPath $staging
        Set-Content -LiteralPath (Join-Path $staging ".hakai-archive-sha256") `
            -Value $ArchiveSha256.ToUpperInvariant() -Encoding ASCII

        if (Test-Path -LiteralPath $Destination) {
            Move-Item -LiteralPath $Destination -Destination $backup
        }
        Move-Item -LiteralPath $staging -Destination $Destination
        if (Test-Path -LiteralPath $backup) {
            Remove-Item -LiteralPath $backup -Recurse -Force
        }
    }
    catch {
        if (Test-Path -LiteralPath $backup) {
            if (Test-Path -LiteralPath $Destination) {
                Remove-Item -LiteralPath $Destination -Recurse -Force
            }
            Move-Item -LiteralPath $backup -Destination $Destination
        }
        throw
    }
    finally {
        if (Test-Path -LiteralPath $staging) {
            Remove-Item -LiteralPath $staging -Recurse -Force
        }
        if ((Test-Path -LiteralPath $backup) -and (Test-Path -LiteralPath $Destination)) {
            Remove-Item -LiteralPath $backup -Recurse -Force
        }
    }
}

function Restore-EnvironmentValue {
    param(
        [Parameter(Mandatory)][string]$Name,
        [AllowNull()][string]$Value
    )

    if ($null -eq $Value) {
        Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
    }
    else {
        Set-Item -LiteralPath "Env:$Name" -Value $Value
    }
}

function Apply-LockedOverlays {
    param(
        [Parameter(Mandatory)][object[]]$Overlays,
        [Parameter(Mandatory)][string]$SourceRoot
    )

    foreach ($overlay in $Overlays) {
        $relativeSource = [string]$overlay.source
        $relativeDestination = [string]$overlay.destination
        if ([System.IO.Path]::IsPathRooted($relativeSource) -or
            [System.IO.Path]::IsPathRooted($relativeDestination) -or
            $relativeSource -match '(^|[\\/])\.\.([\\/]|$)' -or
            $relativeDestination -match '(^|[\\/])\.\.([\\/]|$)') {
            throw "Unsafe login-server overlay path."
        }

        $overlayPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $relativeSource))
        $destinationPath = [System.IO.Path]::GetFullPath((Join-Path $SourceRoot $relativeDestination))
        Assert-ChildPath -Root $PSScriptRoot -Candidate $overlayPath
        Assert-ChildPath -Root $SourceRoot -Candidate $destinationPath

        if (-not (Test-Path -LiteralPath $overlayPath -PathType Leaf)) {
            throw "Versioned login-server overlay not found: $overlayPath"
        }
        if ((Get-Sha256 -Path $overlayPath) -ne ([string]$overlay.sha256).ToUpperInvariant()) {
            throw "Versioned login-server overlay hash mismatch: $relativeSource"
        }

        if ($null -eq $overlay.upstreamSha256) {
            if (Test-Path -LiteralPath $destinationPath) {
                throw "New login-server overlay destination already exists upstream: $relativeDestination"
            }
        }
        else {
            if (-not (Test-Path -LiteralPath $destinationPath -PathType Leaf)) {
                throw "Expected upstream login-server file not found: $relativeDestination"
            }
            if ((Get-Sha256 -Path $destinationPath) -ne ([string]$overlay.upstreamSha256).ToUpperInvariant()) {
                throw "Upstream login-server file changed before overlay: $relativeDestination"
            }
        }

        Copy-Item -LiteralPath $overlayPath -Destination $destinationPath -Force
        if ((Get-Sha256 -Path $destinationPath) -ne ([string]$overlay.sha256).ToUpperInvariant()) {
            throw "Applied login-server overlay hash mismatch: $relativeDestination"
        }
    }
}

if (-not (Test-Path -LiteralPath $lockPath)) {
    throw "Login-server lock file not found: $lockPath"
}

if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
    throw "This bootstrap is pinned for Windows AMD64."
}

$lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if ($lock.schemaVersion -ne 1) {
    throw "Unsupported login-server lock schema: $($lock.schemaVersion)"
}
if ($lock.component -ne "opentibiabr/login-server") {
    throw "Unexpected login-server component: $($lock.component)"
}
if ([string]$lock.source.commit -notmatch '^[0-9a-f]{40}$') {
    throw "The pinned login-server commit must be a lowercase 40-character SHA-1."
}
if ([string]$lock.source.archive.sha256 -notmatch '^[0-9A-Fa-f]{64}$') {
    throw "The pinned login-server source archive has an invalid SHA-256."
}
if (@($lock.overlays).Count -eq 0) {
    throw "The pinned login-server source requires a versioned Hakai overlay set."
}
foreach ($overlay in @($lock.overlays)) {
    if ([string]$overlay.source -eq "" -or
        [string]$overlay.destination -eq "" -or
        [string]$overlay.sha256 -notmatch '^[0-9A-Fa-f]{64}$' -or
        ($null -ne $overlay.upstreamSha256 -and [string]$overlay.upstreamSha256 -notmatch '^[0-9A-Fa-f]{64}$')) {
        throw "Invalid login-server overlay declaration in lock file."
    }
}
if ([string]$lock.toolchain.version -notmatch '^go\d+\.\d+\.\d+$' -or
    $lock.toolchain.platform -ne "windows-amd64") {
    throw "The pinned Go toolchain must be a semantic version for windows-amd64."
}
if ([string]$lock.toolchain.archive.sha256 -notmatch '^[0-9A-Fa-f]{64}$') {
    throw "The pinned Go toolchain archive has an invalid SHA-256."
}

$expectedSourceUrl = "https://codeload.github.com/opentibiabr/login-server/zip/$($lock.source.commit)"
$expectedToolchainUrl = "https://go.dev/dl/$($lock.toolchain.version).windows-amd64.zip"
if ($lock.source.archive.url -ne $expectedSourceUrl) {
    throw "Unexpected login-server source URL in lock file."
}
if ($lock.toolchain.archive.url -ne $expectedToolchainUrl) {
    throw "Unexpected Go toolchain URL in lock file."
}
if ($lock.build.package -ne "./src/" -or
    ([string]$lock.build.output).Replace('\', '/') -ne ".hakai-runtime/login-server/bin/login-server.exe") {
    throw "Unexpected login-server build package or output path in lock file."
}

Assert-ChildPath -Root $serverRoot -Candidate $runtimeRoot
$lockHash = Get-Sha256 -Path $lockPath

$downloadsRoot = Join-Path $runtimeRoot "downloads"
$toolchainsRoot = Join-Path $runtimeRoot "toolchains"
$sourcesRoot = Join-Path $runtimeRoot "sources"
$binaryRoot = Join-Path $runtimeRoot "bin"
$cacheRoot = Join-Path $runtimeRoot "cache"

New-Item -ItemType Directory -Path $downloadsRoot, $toolchainsRoot, $sourcesRoot, $binaryRoot, $cacheRoot -Force |
    Out-Null

$goArchive = Join-Path $downloadsRoot "$($lock.toolchain.version).windows-amd64.zip"
$sourceArchive = Join-Path $downloadsRoot "login-server-$($lock.source.commit).zip"

Get-VerifiedDownload `
    -Url $lock.toolchain.archive.url `
    -ExpectedSha256 $lock.toolchain.archive.sha256 `
    -Destination $goArchive
Get-VerifiedDownload `
    -Url $lock.source.archive.url `
    -ExpectedSha256 $lock.source.archive.sha256 `
    -Destination $sourceArchive

$toolchainDestination = Join-Path $toolchainsRoot $lock.toolchain.version
$sourceDestination = Join-Path $sourcesRoot $lock.source.commit

Expand-VerifiedArchive `
    -ArchivePath $goArchive `
    -ArchiveSha256 $lock.toolchain.archive.sha256 `
    -Destination $toolchainDestination
Expand-VerifiedArchive `
    -ArchivePath $sourceArchive `
    -ArchiveSha256 $lock.source.archive.sha256 `
    -Destination $sourceDestination

$goExecutable = Join-Path $toolchainDestination "go\bin\go.exe"
$sourceRoot = Join-Path $sourceDestination "login-server-$($lock.source.commit)"
$binaryPath = [System.IO.Path]::GetFullPath((Join-Path $serverRoot $lock.build.output))
Assert-ChildPath -Root $runtimeRoot -Candidate $binaryPath

if (-not (Test-Path -LiteralPath $goExecutable)) {
    throw "Pinned Go executable not found after extraction: $goExecutable"
}
if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot "go.sum"))) {
    throw "Pinned login-server source was not extracted correctly: $sourceRoot"
}

Apply-LockedOverlays -Overlays @($lock.overlays) -SourceRoot $sourceRoot

$goVersion = (& $goExecutable version)
if ($LASTEXITCODE -ne 0 -or $goVersion -notmatch [regex]::Escape($lock.toolchain.version)) {
    throw "Unexpected Go toolchain: $goVersion"
}

$oldGoToolchain = $env:GOTOOLCHAIN
$oldGoCache = $env:GOCACHE
$oldGoModCache = $env:GOMODCACHE

try {
    $env:GOTOOLCHAIN = "local"
    $env:GOCACHE = Join-Path $cacheRoot "build"
    $env:GOMODCACHE = Join-Path $cacheRoot "modules"

    Push-Location $sourceRoot
    try {
        if (-not $SkipTests) {
            & $goExecutable test ./...
            if ($LASTEXITCODE -ne 0) {
                throw "Official login-server Go tests failed."
            }
        }

        $buildArguments = @("build")
        $buildArguments += @($lock.build.flags)
        $buildArguments += @("-o", $binaryPath, $lock.build.package)
        & $goExecutable @buildArguments
        if ($LASTEXITCODE -ne 0) {
            throw "Login-server build failed."
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    Restore-EnvironmentValue -Name "GOTOOLCHAIN" -Value $oldGoToolchain
    Restore-EnvironmentValue -Name "GOCACHE" -Value $oldGoCache
    Restore-EnvironmentValue -Name "GOMODCACHE" -Value $oldGoModCache
}

$binaryHash = Get-Sha256 -Path $binaryPath
$buildInfo = [ordered]@{
    schemaVersion = 1
    component = $lock.component
    lockSha256 = $lockHash
    sourceCommit = $lock.source.commit
    sourceArchiveSha256 = $lock.source.archive.sha256.ToUpperInvariant()
    toolchainVersion = $lock.toolchain.version
    toolchainArchiveSha256 = $lock.toolchain.archive.sha256.ToUpperInvariant()
    goVersion = $goVersion
    binarySha256 = $binaryHash
    builtAtUtc = [DateTime]::UtcNow.ToString("o")
}
$buildInfo | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runtimeRoot "build-info.json") -Encoding UTF8

Write-Output "Hakai login-server installed and verified."
Write-Output "Source commit: $($lock.source.commit)"
Write-Output "Go: $goVersion"
Write-Output "Binary SHA-256: $binaryHash"
Write-Output "Binary: $binaryPath"

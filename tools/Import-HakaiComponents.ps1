[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ServerSource,

    [Parameter(Mandatory)]
    [string] $ClientSource,

    [string] $RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path

function Test-ExcludedPath {
    param([Parameter(Mandatory)][string] $Path)

    $normalized = $Path.Replace('\', '/')

    return (
        $normalized -match '(?i)(^|/)(\.git|\.github|logs?|build|builds|backup|backups)(/|$)' -or
        $normalized -match '(?i)(^|/)tools/pokemon-data-cache(/|$)' -or
        $normalized -match '(?i)(^|/)(key\.pem|config\.lua|\.env)$' -or
        $normalized -match '(?i)(\.bak($|[-_.])|\.old$|\.orig$|\.rej$|\.zip$|before-|backup_|_old\.)' -or
        $normalized -match '(?i)(^|/)modules/game_wheel(/|$)' -or
        $normalized -match '(?i)(^|/)data/(things|sounds)/1525(/|$)' -or
        $normalized -match '(?i)(^|/)data/items/[^/]*-sync\.json$'
    )
}

function Copy-PublishableComponent {
    param(
        [Parameter(Mandatory)][string] $Source,
        [Parameter(Mandatory)][string] $DestinationName
    )

    $sourceRoot = (Resolve-Path -LiteralPath $Source).Path
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '.git'))) {
        throw "A fonte não é um repositório Git: $sourceRoot"
    }

    $destination = Join-Path $root $DestinationName
    if (Test-Path -LiteralPath $destination) {
        $existing = @(Get-ChildItem -LiteralPath $destination -Force)
        if ($existing.Count -gt 0) {
            throw "O destino precisa estar vazio: $destination"
        }
    } else {
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    $paths = @(
        git -c "safe.directory=$sourceRoot" -c core.quotepath=false -C $sourceRoot ls-files --cached --others --exclude-standard
    )
    if ($LASTEXITCODE -ne 0) {
        throw "Não foi possível inventariar a fonte: $sourceRoot"
    }

    $copiedFiles = 0
    $copiedBytes = [int64] 0
    $excludedFiles = 0
    $excludedBytes = [int64] 0

    foreach ($relativePath in $paths) {
        $sourceFile = Join-Path $sourceRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
            continue
        }

        $length = (Get-Item -LiteralPath $sourceFile).Length
        if (Test-ExcludedPath -Path $relativePath) {
            $excludedFiles++
            $excludedBytes += $length
            continue
        }

        $destinationFile = Join-Path $destination $relativePath
        $destinationDirectory = Split-Path -Parent $destinationFile
        if (-not (Test-Path -LiteralPath $destinationDirectory)) {
            New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
        }

        Copy-Item -LiteralPath $sourceFile -Destination $destinationFile
        $copiedFiles++
        $copiedBytes += $length
    }

    [pscustomobject]@{
        Component = $DestinationName
        CopiedFiles = $copiedFiles
        CopiedBytes = $copiedBytes
        ExcludedFiles = $excludedFiles
        ExcludedBytes = $excludedBytes
    }
}

$results = @(
    Copy-PublishableComponent -Source $ServerSource -DestinationName 'server'
    Copy-PublishableComponent -Source $ClientSource -DestinationName 'client'
)

$results | Format-Table -AutoSize

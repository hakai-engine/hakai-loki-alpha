[CmdletBinding()]
param(
    [string]$ServerRoot,
    [string]$ListenAddress = "127.0.0.1",
    [int]$HttpPort = 8088,
    [int]$GrpcPort = 9090,
    [string]$GameAddress,
    [string]$ServerLocation = "BRA",
    [int]$ReadyTimeoutSeconds = 20,
    [switch]$Foreground
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$resolvedServerRoot = if ([string]::IsNullOrWhiteSpace($ServerRoot)) {
    $repositoryRoot
}
else {
    [System.IO.Path]::GetFullPath($ServerRoot)
}

$configPath = Join-Path $resolvedServerRoot "config.lua"
$runtimeRoot = Join-Path $repositoryRoot ".hakai-runtime\login-server"
$binaryPath = Join-Path $runtimeRoot "bin\login-server.exe"
$buildInfoPath = Join-Path $runtimeRoot "build-info.json"
$lockPath = Join-Path $PSScriptRoot "login-server.lock.json"
$pidPath = Join-Path $runtimeRoot "login-server.pid.json"
$logsRoot = Join-Path $runtimeRoot "logs"

function Assert-ChildPath {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Candidate
    )

    $rootWithSeparator = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $Candidate.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing path outside the login-server tool directory: $Candidate"
    }
}

function Get-RequiredJsonValue {
    param(
        [Parameter(Mandatory)][object]$Object,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Context
    )

    $property = $Object.PSObject.Properties[$Name]
    if (-not $property -or $null -eq $property.Value -or
        [string]::IsNullOrWhiteSpace([string]$property.Value)) {
        throw "Required property '$Name' is missing from $Context."
    }
    return $property.Value
}

function Get-LuaString {
    param([Parameter(Mandatory)][string]$Name)

    $pattern = "^\s*$([regex]::Escape($Name))\s*=\s*[`"']([^`"']*)[`"']"
    $match = Select-String -LiteralPath $configPath -Pattern $pattern | Select-Object -First 1
    if (-not $match) {
        throw "Required string '$Name' was not found in config.lua."
    }
    return $match.Matches[0].Groups[1].Value
}

function Get-LuaNumber {
    param([Parameter(Mandatory)][string]$Name)

    $pattern = "^\s*$([regex]::Escape($Name))\s*=\s*(\d+)"
    $match = Select-String -LiteralPath $configPath -Pattern $pattern | Select-Object -First 1
    if (-not $match) {
        throw "Required number '$Name' was not found in config.lua."
    }
    return [int]$match.Matches[0].Groups[1].Value
}

function Get-VocationsCsv {
    $vocationsPath = Join-Path $resolvedServerRoot "data\XML\vocations.xml"
    if (-not (Test-Path -LiteralPath $vocationsPath)) {
        throw "Vocation catalog not found: $vocationsPath"
    }

    try {
        [xml]$vocationsDocument = Get-Content -LiteralPath $vocationsPath -Raw
    }
    catch {
        throw "Could not parse vocation catalog '$vocationsPath': $($_.Exception.Message)"
    }

    $vocationNodes = @($vocationsDocument.vocations.vocation)
    if ($vocationNodes.Count -eq 0) {
        throw "Vocation catalog '$vocationsPath' contains no vocation entries."
    }

    $vocationsById = @{}
    $maximumVocationId = -1
    foreach ($vocationNode in $vocationNodes) {
        $vocationId = 0
        if (-not [int]::TryParse([string]$vocationNode.id, [ref]$vocationId) -or $vocationId -lt 0) {
            throw "Vocation catalog contains an invalid id '$($vocationNode.id)'."
        }

        $vocationName = [string]$vocationNode.name
        if ([string]::IsNullOrWhiteSpace($vocationName) -or $vocationName.Contains(",")) {
            throw "Vocation $vocationId has an empty name or a name containing a comma."
        }
        if ($vocationsById.ContainsKey($vocationId)) {
            throw "Vocation catalog contains duplicate id $vocationId."
        }

        $vocationsById[$vocationId] = $vocationName
        $maximumVocationId = [Math]::Max($maximumVocationId, $vocationId)
    }

    $indexedVocations = [string[]]::new($maximumVocationId + 1)
    for ($index = 0; $index -le $maximumVocationId; $index++) {
        $indexedVocations[$index] = "None"
    }
    foreach ($vocationId in $vocationsById.Keys) {
        $indexedVocations[[int]$vocationId] = [string]$vocationsById[$vocationId]
    }

    return [string]::Join(",", $indexedVocations)
}

function Test-TcpListener {
    param(
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][int]$Port,
        [int]$TimeoutMilliseconds = 300
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $result = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $result.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) {
            return $false
        }
        $client.EndConnect($result)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Wait-LoginServer {
    param(
        [Parameter(Mandatory)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory)][DateTime]$Deadline
    )

    while ([DateTime]::UtcNow -lt $Deadline) {
        if ($Process.HasExited) {
            throw "login-server exited during startup with code $($Process.ExitCode)."
        }

        if ((Test-TcpListener -HostName $ListenAddress -Port $HttpPort) -and
            (Test-TcpListener -HostName $ListenAddress -Port $GrpcPort)) {
            $body = '{"type":"cacheinfo"}'
            $response = Invoke-WebRequest `
                -Uri "http://${ListenAddress}:${HttpPort}/login" `
                -Method Post `
                -Body $body `
                -ContentType "application/json" `
                -UseBasicParsing `
                -MaximumRedirection 0 `
                -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                $null = $response.Content | ConvertFrom-Json
                return
            }
        }

        Start-Sleep -Milliseconds 250
    }

    throw "Timed out waiting for login-server on HTTP $HttpPort and gRPC $GrpcPort."
}

function Assert-NoRecordedInstance {
    if (-not (Test-Path -LiteralPath $pidPath)) {
        return
    }

    try {
        $record = Get-Content -LiteralPath $pidPath -Raw | ConvertFrom-Json
        $recordSchema = [int](Get-RequiredJsonValue -Object $record -Name "schemaVersion" -Context $pidPath)
        $recordPid = [int](Get-RequiredJsonValue -Object $record -Name "pid" -Context $pidPath)
        $recordBinaryPath = [System.IO.Path]::GetFullPath(
            [string](Get-RequiredJsonValue -Object $record -Name "binaryPath" -Context $pidPath)
        )
        $recordStart = [DateTime]::Parse(
            [string](Get-RequiredJsonValue -Object $record -Name "processStartTimeUtc" -Context $pidPath)
        ).ToUniversalTime()
    }
    catch {
        throw "Invalid login-server PID record '$pidPath'. Inspect it before starting another instance. $($_.Exception.Message)"
    }

    if ($recordSchema -ne 1) {
        throw "Unsupported login-server PID record schema: $recordSchema"
    }

    $recordedProcess = Get-Process -Id $recordPid -ErrorAction SilentlyContinue
    if (-not $recordedProcess) {
        Remove-Item -LiteralPath $pidPath -Force
        return
    }

    $actualBinaryPath = [System.IO.Path]::GetFullPath($recordedProcess.Path)
    $actualStart = $recordedProcess.StartTime.ToUniversalTime()
    if ($recordBinaryPath -ne [System.IO.Path]::GetFullPath($binaryPath) -or
        $actualBinaryPath -ne $recordBinaryPath -or
        [Math]::Abs(($actualStart - $recordStart).TotalSeconds) -gt 1) {
        throw "PID $recordPid is live but does not match the recorded Hakai login-server. Refusing to overwrite its PID record."
    }

    throw "Hakai login-server is already running (PID $recordPid). Stop it before starting another instance."
}

function Remove-OwnedPidRecord {
    param([Parameter(Mandatory)][int]$ProcessId)

    if (-not (Test-Path -LiteralPath $pidPath)) {
        return
    }

    try {
        $record = Get-Content -LiteralPath $pidPath -Raw | ConvertFrom-Json
        $recordPid = [int](Get-RequiredJsonValue -Object $record -Name "pid" -Context $pidPath)
        if ($recordPid -eq $ProcessId) {
            Remove-Item -LiteralPath $pidPath -Force
        }
    }
    catch {
        Write-Warning "Could not clean the login-server PID record: $($_.Exception.Message)"
    }
}

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Runtime config.lua not found: $configPath"
}
if (-not (Test-Path -LiteralPath $binaryPath) -or
    -not (Test-Path -LiteralPath $buildInfoPath) -or
    -not (Test-Path -LiteralPath $lockPath)) {
    throw "Verified login-server runtime not found. Run Install-HakaiLoginServer.ps1 first."
}
if ($ListenAddress -ne "127.0.0.1") {
    throw "Hakai binds the login-server to 127.0.0.1 because its HTTP and gRPC listeners share LOGIN_IP and have no native TLS. Publish only HTTP through a colocated trusted HTTPS reverse proxy."
}
if ($HttpPort -eq $GrpcPort) {
    throw "HTTP and gRPC ports must be different."
}
Assert-NoRecordedInstance
if ((Test-TcpListener -HostName $ListenAddress -Port $HttpPort) -or
    (Test-TcpListener -HostName $ListenAddress -Port $GrpcPort)) {
    throw "HTTP port $HttpPort or gRPC port $GrpcPort is already in use."
}

$authType = Get-LuaString "authType"
if ($authType -ne "session") {
    throw "Hakai HTTP login requires authType = `"session`" in config.lua; found '$authType'."
}

$lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
$buildInfo = Get-Content -LiteralPath $buildInfoPath -Raw | ConvertFrom-Json
$lockSchema = [int](Get-RequiredJsonValue -Object $lock -Name "schemaVersion" -Context $lockPath)
$lockComponent = [string](Get-RequiredJsonValue -Object $lock -Name "component" -Context $lockPath)
$buildSchema = [int](Get-RequiredJsonValue -Object $buildInfo -Name "schemaVersion" -Context $buildInfoPath)
$buildComponent = [string](Get-RequiredJsonValue -Object $buildInfo -Name "component" -Context $buildInfoPath)
$buildLockHash = [string](Get-RequiredJsonValue -Object $buildInfo -Name "lockSha256" -Context $buildInfoPath)
$buildSourceCommit = [string](Get-RequiredJsonValue -Object $buildInfo -Name "sourceCommit" -Context $buildInfoPath)
$buildSourceHash = [string](Get-RequiredJsonValue -Object $buildInfo -Name "sourceArchiveSha256" -Context $buildInfoPath)
$buildToolchainVersion = [string](Get-RequiredJsonValue -Object $buildInfo -Name "toolchainVersion" -Context $buildInfoPath)
$buildToolchainHash = [string](Get-RequiredJsonValue -Object $buildInfo -Name "toolchainArchiveSha256" -Context $buildInfoPath)
$buildGoVersion = [string](Get-RequiredJsonValue -Object $buildInfo -Name "goVersion" -Context $buildInfoPath)
$expectedBinaryHash = [string](Get-RequiredJsonValue -Object $buildInfo -Name "binarySha256" -Context $buildInfoPath)

if ($lockSchema -ne 1 -or $buildSchema -ne 1 -or
    $lockComponent -ne "opentibiabr/login-server" -or
    $buildComponent -ne $lockComponent) {
    throw "Login-server lock/build metadata has an unsupported schema or component."
}
$currentLockHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $lockPath).Hash.ToUpperInvariant()
if ($buildLockHash -notmatch '^[0-9A-Fa-f]{64}$' -or
    $buildLockHash.ToUpperInvariant() -ne $currentLockHash) {
    throw "login-server was not built from the current versioned lock file. Run Install-HakaiLoginServer.ps1."
}
foreach ($overlay in @($lock.overlays)) {
    $relativeSource = [string]$overlay.source
    if ([System.IO.Path]::IsPathRooted($relativeSource) -or
        $relativeSource -match '(^|[\\/])\.\.([\\/]|$)' -or
        [string]$overlay.sha256 -notmatch '^[0-9A-Fa-f]{64}$') {
        throw "Invalid login-server overlay declaration in lock file."
    }
    $overlayPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $relativeSource))
    Assert-ChildPath -Root $PSScriptRoot -Candidate $overlayPath
    if (-not (Test-Path -LiteralPath $overlayPath -PathType Leaf) -or
        (Get-FileHash -Algorithm SHA256 -LiteralPath $overlayPath).Hash.ToUpperInvariant() -ne
        ([string]$overlay.sha256).ToUpperInvariant()) {
        throw "Versioned login-server overlay differs from the lock file. Run Install-HakaiLoginServer.ps1."
    }
}
if ($buildSourceCommit -ne [string]$lock.source.commit -or
    $buildSourceHash.ToUpperInvariant() -ne ([string]$lock.source.archive.sha256).ToUpperInvariant() -or
    $buildToolchainVersion -ne [string]$lock.toolchain.version -or
    $buildToolchainHash.ToUpperInvariant() -ne ([string]$lock.toolchain.archive.sha256).ToUpperInvariant() -or
    $buildGoVersion -ne "go version $($lock.toolchain.version) windows/amd64") {
    throw "login-server build provenance differs from the pinned source or toolchain."
}
if ($expectedBinaryHash -notmatch '^[0-9A-Fa-f]{64}$') {
    throw "login-server build metadata contains an invalid binary SHA-256."
}
$binaryHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $binaryPath).Hash.ToUpperInvariant()
if ($binaryHash -ne $expectedBinaryHash.ToUpperInvariant()) {
    throw "login-server binary hash differs from the verified local build."
}

$mysqlHost = Get-LuaString "mysqlHost"
$mysqlPort = Get-LuaNumber "mysqlPort"
$mysqlDatabase = Get-LuaString "mysqlDatabase"
$mysqlUser = Get-LuaString "mysqlUser"
$mysqlPassword = Get-LuaString "mysqlPass"
$serverName = Get-LuaString "serverName"
$serverPort = Get-LuaNumber "gameProtocolPort"
$configuredGameAddress = Get-LuaString "ip"
$advertisedGameAddress = if ([string]::IsNullOrWhiteSpace($GameAddress)) {
    $configuredGameAddress
}
else {
    $GameAddress
}
$vocationsCsv = Get-VocationsCsv

New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null
$logPath = Join-Path $logsRoot ("login-server-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

$childEnvironment = [ordered]@{
    SERVER_PATH = $resolvedServerRoot
    MYSQL_HOST = $mysqlHost
    MYSQL_PORT = [string]$mysqlPort
    MYSQL_DBNAME = $mysqlDatabase
    MYSQL_USER = $mysqlUser
    MYSQL_PASS = $mysqlPassword
    ENV_LOG_LEVEL = "info"
    ENV_LOG_FILE = $logPath
    LOGIN_IP = $ListenAddress
    LOGIN_HTTP_PORT = [string]$HttpPort
    LOGIN_GRPC_PORT = [string]$GrpcPort
    RATE_LIMITER_BURST = "5"
    RATE_LIMITER_RATE = "2"
    SERVER_IP = $advertisedGameAddress
    SERVER_NAME = $serverName
    SERVER_PORT = [string]$serverPort
    SERVER_LOCATION = $ServerLocation
    VOCATIONS = $vocationsCsv
}
$previousEnvironment = @{}

try {
    foreach ($entry in $childEnvironment.GetEnumerator()) {
        $previousEnvironment[$entry.Key] = [Environment]::GetEnvironmentVariable($entry.Key, "Process")
        [Environment]::SetEnvironmentVariable($entry.Key, [string]$entry.Value, "Process")
    }

    $startArguments = @{
        FilePath = $binaryPath
        WorkingDirectory = $resolvedServerRoot
        PassThru = $true
    }
    if ($Foreground) {
        $startArguments.NoNewWindow = $true
    }
    else {
        $startArguments.WindowStyle = "Hidden"
    }
    $process = Start-Process @startArguments
}
finally {
    foreach ($entry in $previousEnvironment.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
    }
}

try {
    Wait-LoginServer -Process $process -Deadline ([DateTime]::UtcNow.AddSeconds($ReadyTimeoutSeconds))
}
catch {
    if (-not $process.HasExited) {
        $process.Kill()
        $process.WaitForExit(5000) | Out-Null
    }
    throw
}

$pidRecord = [ordered]@{
    schemaVersion = 1
    pid = $process.Id
    processStartTimeUtc = $process.StartTime.ToUniversalTime().ToString("o")
    binaryPath = $binaryPath
    binarySha256 = $binaryHash
    sourceCommit = $buildInfo.sourceCommit
    httpEndpoint = "http://${ListenAddress}:${HttpPort}/login"
    grpcEndpoint = "${ListenAddress}:${GrpcPort}"
    gameEndpoint = "${advertisedGameAddress}:${serverPort}"
    logPath = $logPath
}
$pidRecord | ConvertTo-Json | Set-Content -LiteralPath $pidPath -Encoding UTF8

Write-Output "Hakai login-server is ready (PID $($process.Id))."
Write-Output "HTTP: http://${ListenAddress}:${HttpPort}/login"
Write-Output "Game world: ${advertisedGameAddress}:${serverPort}"
Write-Output "Log: $logPath"

if ($Foreground) {
    $exitCode = 0
    try {
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    }
    finally {
        if (-not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit(5000) | Out-Null
        }
        Remove-OwnedPidRecord -ProcessId $process.Id
    }
    exit $exitCode
}

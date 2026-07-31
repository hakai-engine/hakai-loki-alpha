[CmdletBinding()]
param(
    [string]$Endpoint = "http://127.0.0.1:8088/login",
    [string]$ServerRoot,
    [string]$Email,
    [Security.SecureString]$Password,
    [string]$ExpectedCharacter,
    [string]$ExpectedVocation
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

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Runtime config.lua not found: $configPath"
}

$endpointUri = $null
if (-not [Uri]::TryCreate($Endpoint, [UriKind]::Absolute, [ref]$endpointUri) -or
    $endpointUri.Scheme -notin @("http", "https")) {
    throw "Endpoint must be an absolute HTTP or HTTPS URL."
}
if (-not [string]::IsNullOrEmpty($endpointUri.UserInfo)) {
    throw "Endpoint must not contain user information."
}
if ($endpointUri.Scheme -eq "http" -and -not $endpointUri.IsLoopback) {
    throw "Credentials may be sent over plain HTTP only to a loopback endpoint."
}
$Endpoint = $endpointUri.AbsoluteUri

if (-not [string]::IsNullOrWhiteSpace($Email) -and -not $Password) {
    throw "Pass -Password as a SecureString when -Email is supplied."
}
if ([string]::IsNullOrWhiteSpace($Email) -and $Password) {
    throw "Pass -Email when -Password is supplied."
}

$readinessBody = @{ type = "cacheinfo" } | ConvertTo-Json -Compress
$readiness = Invoke-WebRequest `
    -Uri $Endpoint `
    -Method Post `
    -Body $readinessBody `
    -ContentType "application/json" `
    -UseBasicParsing `
    -MaximumRedirection 0 `
    -TimeoutSec 5
if ($readiness.StatusCode -ne 200) {
    throw "Unexpected readiness HTTP status: $($readiness.StatusCode)"
}
$null = $readiness.Content | ConvertFrom-Json
Write-Output "HTTP login readiness passed."

if ([string]::IsNullOrWhiteSpace($Email)) {
    Write-Output "Authenticated character-list test skipped; no credentials were supplied."
    exit 0
}

$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
try {
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    $requestBody = @{
        type = "login"
        email = $Email
        password = $plainPassword
        stayloggedin = $false
    } | ConvertTo-Json -Compress

    $loginResponse = Invoke-RestMethod `
        -Uri $Endpoint `
        -Method Post `
        -Body $requestBody `
        -ContentType "application/json" `
        -MaximumRedirection 0 `
        -TimeoutSec 10
}
finally {
    if ($bstr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    $plainPassword = $null
    $requestBody = $null
}

$errorCodeProperty = $loginResponse.PSObject.Properties["errorCode"]
if ($errorCodeProperty -and $errorCodeProperty.Value) {
    throw "Login failed with error code $($errorCodeProperty.Value)."
}
if (-not $loginResponse.session -or [string]::IsNullOrWhiteSpace($loginResponse.session.sessionkey)) {
    throw "Login response has no session key."
}
if ([string]$loginResponse.session.sessionkey -notmatch '^[0-9a-fA-F]{64}$') {
    throw "Login response did not return the expected opaque session token."
}

$worlds = @($loginResponse.playdata.worlds)
$characters = @($loginResponse.playdata.characters)
$expectedServerName = Get-LuaString "serverName"
$expectedServerPort = Get-LuaNumber "gameProtocolPort"

if ($worlds.Count -lt 1) {
    throw "Login response contains no game world."
}
$world = $worlds | Where-Object { $_.name -eq $expectedServerName } | Select-Object -First 1
if (-not $world) {
    throw "Login response does not contain the configured world '$expectedServerName'."
}
if ([int]$world.externalportprotected -ne $expectedServerPort) {
    throw "World response advertises port $($world.externalportprotected), expected $expectedServerPort."
}
if ($characters.Count -lt 1) {
    throw "Login response contains no character."
}
if ($characters | Where-Object { [string]$_.vocation -ne "Trainer" } | Select-Object -First 1) {
    throw "Login response exposed a character outside the Hakai Trainer profile."
}
$matchedCharacter = $null
if (-not [string]::IsNullOrWhiteSpace($ExpectedCharacter)) {
    $matchedCharacter = $characters |
        Where-Object { $_.name -eq $ExpectedCharacter } |
        Select-Object -First 1
    if (-not $matchedCharacter) {
        throw "Expected character '$ExpectedCharacter' was not returned."
    }
}
if (-not [string]::IsNullOrWhiteSpace($ExpectedVocation)) {
    if ($matchedCharacter) {
        if ([string]$matchedCharacter.vocation -ne $ExpectedVocation) {
            throw "Character '$ExpectedCharacter' has vocation '$($matchedCharacter.vocation)', expected '$ExpectedVocation'."
        }
    }
    elseif (-not ($characters | Where-Object { $_.vocation -eq $ExpectedVocation } | Select-Object -First 1)) {
        throw "No returned character has the expected vocation '$ExpectedVocation'."
    }
}

Write-Output "Authenticated HTTP login passed."
Write-Output "World: $expectedServerName ($expectedServerPort)"
Write-Output "Characters returned: $($characters.Count)"

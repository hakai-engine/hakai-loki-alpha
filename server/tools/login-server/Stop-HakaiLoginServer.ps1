[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$serverRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$runtimeRoot = Join-Path $serverRoot ".hakai-runtime\login-server"
$pidPath = Join-Path $runtimeRoot "login-server.pid.json"

if (-not (Test-Path -LiteralPath $pidPath)) {
    Write-Output "No Hakai login-server PID record exists."
    exit 0
}

$record = Get-Content -LiteralPath $pidPath -Raw | ConvertFrom-Json
$process = Get-Process -Id ([int]$record.pid) -ErrorAction SilentlyContinue
if (-not $process) {
    Remove-Item -LiteralPath $pidPath -Force
    Write-Output "Removed a stale Hakai login-server PID record."
    exit 0
}

$expectedPath = [System.IO.Path]::GetFullPath([string]$record.binaryPath)
$actualPath = [System.IO.Path]::GetFullPath($process.Path)
$expectedStart = [DateTime]::Parse([string]$record.processStartTimeUtc).ToUniversalTime()
$actualStart = $process.StartTime.ToUniversalTime()

if ($actualPath -ne $expectedPath -or [Math]::Abs(($actualStart - $expectedStart).TotalSeconds) -gt 1) {
    throw "PID $($record.pid) no longer identifies the recorded Hakai login-server. Refusing to stop it."
}

Stop-Process -Id $process.Id
$process.WaitForExit(5000) | Out-Null
Remove-Item -LiteralPath $pidPath -Force
Write-Output "Hakai login-server stopped (PID $($process.Id))."

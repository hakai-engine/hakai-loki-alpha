[CmdletBinding()]
param(
    [string] $RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path.TrimEnd('\', '/')
$errors = [Collections.Generic.List[string]]::new()

function Add-ValidationError {
    param([Parameter(Mandatory)][string] $Message)
    $script:errors.Add($Message)
}

$requiredPaths = @(
    'README.md',
    'server/LICENSE',
    'server/README.md',
    'client/LICENSE',
    'client/README.md',
    'manifests/import-snapshot.json'
)

foreach ($relativePath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf)) {
        Add-ValidationError "Arquivo obrigatório ausente: $relativePath"
    }
}

$forbiddenPaths = @(
    'client/modules/game_wheel',
    'client/data/things/1525',
    'client/data/sounds/1525',
    'client/.github',
    'server/.github',
    'server/key.pem',
    'server/tests/fixture/security/key.pem',
    'server/config.lua',
    'server/tools/pokemon-data-cache'
)

foreach ($relativePath in $forbiddenPaths) {
    if (Test-Path -LiteralPath (Join-Path $root $relativePath)) {
        Add-ValidationError "Caminho proibido na publicação: $relativePath"
    }
}

$gitRoot = Join-Path $root '.git'
$gitPrefix = $gitRoot + [IO.Path]::DirectorySeparatorChar
$files = @(
    Get-ChildItem -LiteralPath $root -Recurse -Force -File |
        Where-Object {
            $_.FullName -ne $gitRoot -and
            -not $_.FullName.StartsWith($gitPrefix, [StringComparison]::OrdinalIgnoreCase)
        }
)

$nestedGitDirectories = @(
    Get-ChildItem -LiteralPath $root -Recurse -Force -Directory -Filter '.git' |
        Where-Object { $_.FullName -ne $gitRoot }
)
foreach ($directory in $nestedGitDirectories) {
    Add-ValidationError "Repositório Git aninhado: $($directory.FullName)"
}

$forbiddenFilePattern = '(?i)(\.bak($|[-_.])|\.old$|\.orig$|\.rej$|before-|backup_|_old\.)'
foreach ($file in $files | Where-Object { $_.FullName -match $forbiddenFilePattern }) {
    Add-ValidationError "Backup ou arquivo temporário detectado: $($file.FullName)"
}

$maximumBytes = 95MB
foreach ($file in $files | Where-Object Length -ge $maximumBytes) {
    Add-ValidationError "Arquivo com 95 MiB ou mais: $($file.FullName) ($($file.Length) bytes)"
}

$privateKeyPattern = '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
$keyCandidates = @(
    $files | Where-Object {
        $_.Extension -in @('.pem', '.key', '.p12', '.pfx') -or
        $_.Name -match '(?i)(private|secret).*(key|pem)'
    }
)
foreach ($file in $keyCandidates) {
    if (Select-String -LiteralPath $file.FullName -Pattern $privateKeyPattern -Quiet -ErrorAction SilentlyContinue) {
        Add-ValidationError "Material de chave privada detectado: $($file.FullName)"
    }
}

if ($errors.Count -gt 0) {
    foreach ($validationError in $errors) {
        Write-Host "ERROR: $validationError" -ForegroundColor Red
    }
    throw "Árvore não publicável: $($errors.Count) erro(s)."
}

$totalBytes = ($files | Measure-Object Length -Sum).Sum
Write-Host "Árvore publicável: $($files.Count) arquivos, $totalBytes bytes, nenhum bloqueio."

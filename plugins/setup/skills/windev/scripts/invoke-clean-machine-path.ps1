# windev: Übergibt genehmigte Machine-PATH-Entfernungen an einen erhöhten,
# systemweit geschützten PowerShell-Prozess. Das Zielskript wird vor UAC als
# Byte-Snapshot gesichert und im Kindprozess vor der Ausführung gehasht.
param(
    [Parameter(Mandatory)][string]$RequestFile
)
$ErrorActionPreference = 'Stop'

$requestPath = (Resolve-Path -LiteralPath $RequestFile -ErrorAction Stop).Path
$request = Get-Content -LiteralPath $requestPath -Raw | ConvertFrom-Json
$remove = [string[]]@($request.remove)
if ($remove.Count -eq 0 -or @($remove | Where-Object { -not $_ }).Count -gt 0) {
    throw 'Requestfile muss mindestens einen nicht-leeren Eintrag in "remove" enthalten.'
}

$programFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
$pwsh = Join-Path $programFiles 'PowerShell\7\pwsh.exe'
if (-not (Test-Path -LiteralPath $pwsh -PathType Leaf)) { throw "Systemweit geschuetztes PowerShell 7 fehlt: $pwsh" }

$cleanScript = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'clean-machine-path.ps1') -ErrorAction Stop).Path
$scriptSnapshot = Join-Path ([IO.Path]::GetTempPath()) ('windev-clean-script-{0}.ps1' -f [guid]::NewGuid().ToString('N'))
$resultFile = Join-Path ([IO.Path]::GetTempPath()) ('windev-machine-path-{0}.txt' -f [guid]::NewGuid().ToString('N'))
$scriptBytes = [IO.File]::ReadAllBytes($cleanScript)
[IO.File]::WriteAllBytes($scriptSnapshot, $scriptBytes)
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $scriptHash = ([BitConverter]::ToString($sha256.ComputeHash($scriptBytes))).Replace('-', '').ToLowerInvariant()
} finally {
    $sha256.Dispose()
}

$payload = [ordered]@{
    scriptSnapshot = $scriptSnapshot
    scriptHash = $scriptHash
    remove = $remove
    backupPath = if ($request.backupPath) { [string]$request.backupPath } else { $null }
    noDedupe = [bool]$request.noDedupe
    resultFile = $resultFile
} | ConvertTo-Json -Compress -Depth 4
$payloadBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))

$bootstrap = @'
$ErrorActionPreference = 'Stop'
$systemRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
if (-not $systemRoot -or -not (Test-Path -LiteralPath $systemRoot -PathType Container)) { throw 'Windows-Systempfad konnte nicht sicher ermittelt werden.' }
$env:SystemRoot = $systemRoot
$env:windir = $systemRoot
$env:PATH = @($PSHOME, (Join-Path $systemRoot 'System32'), $systemRoot, (Join-Path $systemRoot 'System32\WindowsPowerShell\v1.0')) -join ';'
$env:PSModulePath = @((Join-Path $PSHOME 'Modules'), (Join-Path $systemRoot 'System32\WindowsPowerShell\v1.0\Modules')) -join ';'
$request = $null
try {
    $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__'))
    $request = $json | ConvertFrom-Json
    $scriptBytes = [IO.File]::ReadAllBytes([string]$request.scriptSnapshot)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $actualHash = ([BitConverter]::ToString($sha256.ComputeHash($scriptBytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
    if ($actualHash -ne [string]$request.scriptHash) { throw 'Skript-Snapshot wurde vor der erhoehten Ausfuehrung veraendert.' }
    $parameters = @{
        Remove = [string[]]@($request.remove)
        ResultFile = [string]$request.resultFile
    }
    if ($request.backupPath) { $parameters.BackupPath = [string]$request.backupPath }
    if ($request.noDedupe) { $parameters.NoDedupe = $true }
    $scriptBlock = [ScriptBlock]::Create([Text.Encoding]::UTF8.GetString($scriptBytes))
    & $scriptBlock @parameters
    exit 0
} catch {
    try {
        Set-Content -LiteralPath ([string]$request.resultFile) -Value ('FEHLER: ' + $_.Exception.Message) -Encoding utf8
    } catch {}
    exit 1
}
'@.Replace('__PAYLOAD__', $payloadBase64)
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bootstrap))

try {
    $child = Start-Process -FilePath $pwsh -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @(
        '-NoProfile', '-NonInteractive', '-EncodedCommand', $encodedCommand
    )
    $result = if (Test-Path -LiteralPath $resultFile) { (Get-Content -LiteralPath $resultFile -Raw).Trim() } else { '' }
    if ($child.ExitCode -ne 0) { throw "Erhoehte PATH-Bereinigung fehlgeschlagen (ExitCode $($child.ExitCode)). $result" }
    if (-not $result) { throw 'Erhoehte PATH-Bereinigung lieferte keine Ergebnisdatei.' }
    $result
} finally {
    if (Test-Path -LiteralPath $resultFile) { Remove-Item -LiteralPath $resultFile -Force }
    if (Test-Path -LiteralPath $scriptSnapshot) { Remove-Item -LiteralPath $scriptSnapshot -Force }
}

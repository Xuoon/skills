# devdrive: Fuehrt ein Skript aus diesem Ordner in einem erhoehten Prozess aus.
# Parameter kommen als JSON-Requestfile (vermeidet Quoting-Probleme), der
# UAC-Prozess erhaelt nur einen Base64-kodierten Befehl. Ausgabe des Kindprozesses
# landet in einer Ergebnisdatei und wird hier zurueckgegeben.
#
# Requestfile: { "script": "new-devdrive.ps1", "parameters": { "ImagePath": "D:\\Coding\\Coding.vhdx", ... } }
param(
    [Parameter(Mandatory)][string]$RequestFile
)
$ErrorActionPreference = 'Stop'

$requestPath = (Resolve-Path -LiteralPath $RequestFile -ErrorAction Stop).Path
$request = Get-Content -LiteralPath $requestPath -Raw | ConvertFrom-Json
if (-not $request.script) { throw 'Requestfile braucht "script".' }
if ($request.script -match '[\\/]') { throw '"script" darf nur ein Dateiname aus dem scripts-Ordner sein.' }
$allowedScripts = @('new-devdrive.ps1', 'register-mount-task.ps1', 'test-devdrive-admin.ps1')
if ($request.script -notin $allowedScripts) {
    throw 'Erhoeht erlaubt sind nur new-devdrive.ps1, register-mount-task.ps1 und test-devdrive-admin.ps1.'
}

$scriptPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot $request.script) -ErrorAction Stop).Path
$programFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
$pwsh = Join-Path $programFiles 'PowerShell\7\pwsh.exe'
if (-not (Test-Path -LiteralPath $pwsh -PathType Leaf)) { throw "Systemweit geschuetztes PowerShell 7 fehlt: $pwsh" }
$resultFile = Join-Path ([IO.Path]::GetTempPath()) ('devdrive-{0}.txt' -f [guid]::NewGuid().ToString('N'))
$scriptSnapshot = Join-Path ([IO.Path]::GetTempPath()) ('devdrive-script-{0}.ps1' -f [guid]::NewGuid().ToString('N'))
$scriptBytes = [IO.File]::ReadAllBytes($scriptPath)
[IO.File]::WriteAllBytes($scriptSnapshot, $scriptBytes)
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $scriptHash = ([BitConverter]::ToString($sha256.ComputeHash($scriptBytes))).Replace('-', '').ToLowerInvariant()
} finally {
    $sha256.Dispose()
}

$parameters = [ordered]@{}
if ($request.parameters) {
    foreach ($p in $request.parameters.PSObject.Properties) { $parameters[$p.Name] = $p.Value }
}

$payload = [ordered]@{
    scriptName = [string]$request.script
    scriptSnapshot = $scriptSnapshot
    scriptHash = $scriptHash
    parameters = $parameters
    resultFile = $resultFile
} | ConvertTo-Json -Compress -Depth 5
$payloadBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))

$bootstrap = @'
$ErrorActionPreference = 'Stop'
$systemRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
if (-not $systemRoot -or -not (Test-Path -LiteralPath $systemRoot -PathType Container)) { throw 'Windows-Systempfad konnte nicht sicher ermittelt werden.' }
$env:SystemRoot = $systemRoot
$env:windir = $systemRoot
$env:PATH = @(
    $PSHOME,
    (Join-Path $systemRoot 'System32'),
    $systemRoot,
    (Join-Path $systemRoot 'System32\WindowsPowerShell\v1.0')
) -join ';'
$env:PSModulePath = @(
    (Join-Path $PSHOME 'Modules'),
    (Join-Path $systemRoot 'System32\WindowsPowerShell\v1.0\Modules')
) -join ';'
$request = $null
$output = [Text.StringBuilder]::new()
try {
    $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__'))
    $request = $json | ConvertFrom-Json
    $splat = @{}
    if ($request.parameters) {
        foreach ($p in $request.parameters.PSObject.Properties) {
            $v = $p.Value
            if ($v -is [bool] -and $v) { $splat[$p.Name] = [switch]$true }
            elseif ($v -is [bool]) { continue }
            else { $splat[$p.Name] = $v }
        }
    }
    $scriptBytes = [IO.File]::ReadAllBytes([string]$request.scriptSnapshot)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $actualHash = ([BitConverter]::ToString($sha256.ComputeHash($scriptBytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
    if ($actualHash -ne [string]$request.scriptHash) { throw 'Skript-Snapshot wurde vor der erhoehten Ausfuehrung veraendert.' }
    $scriptText = [Text.Encoding]::UTF8.GetString($scriptBytes)
    $scriptBlock = [ScriptBlock]::Create($scriptText)
    & $scriptBlock @splat *>&1 | ForEach-Object {
        [void]$output.AppendLine(($_ | Out-String).TrimEnd())
    }
    Set-Content -LiteralPath ([string]$request.resultFile) -Value $output.ToString() -Encoding utf8
    exit 0
} catch {
    try {
        [void]$output.AppendLine('FEHLER: ' + $_.Exception.Message)
        Set-Content -LiteralPath ([string]$request.resultFile) -Value $output.ToString() -Encoding utf8
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
    if ($child.ExitCode -ne 0) {
        throw "Erhoehter Lauf von $($request.script) fehlgeschlagen (ExitCode $($child.ExitCode)). $result"
    }
    if (-not $result) { throw "Erhoehter Lauf von $($request.script) lieferte keine Ergebnisdatei." }
    $result
} finally {
    if (Test-Path -LiteralPath $resultFile) { Remove-Item -LiteralPath $resultFile -Force }
    if (Test-Path -LiteralPath $scriptSnapshot) { Remove-Item -LiteralPath $scriptSnapshot -Force }
}

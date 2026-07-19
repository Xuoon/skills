# windev: Übergibt genehmigte Machine-PATH-Entfernungen verlustfrei an einen
# erhöhten Prozess. Das JSON-Requestfile vermeidet native Array-/Quoting-Probleme;
# der UAC-Prozess erhält nur einen Base64-kodierten PowerShell-Befehl.
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

$pwsh = (Get-Command pwsh -ErrorAction Stop).Source
$cleanScript = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'clean-machine-path.ps1') -ErrorAction Stop).Path
$resultFile = Join-Path ([IO.Path]::GetTempPath()) ('windev-machine-path-{0}.txt' -f [guid]::NewGuid().ToString('N'))

$payload = [ordered]@{
    scriptPath = $cleanScript
    remove = $remove
    backupPath = if ($request.backupPath) { [string]$request.backupPath } else { $null }
    noDedupe = [bool]$request.noDedupe
    resultFile = $resultFile
} | ConvertTo-Json -Compress -Depth 4
$payloadBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))

$bootstrap = @'
$ErrorActionPreference = 'Stop'
try {
    $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__'))
    $request = $json | ConvertFrom-Json
    $parameters = @{
        Remove = [string[]]@($request.remove)
        ResultFile = [string]$request.resultFile
    }
    if ($request.backupPath) { $parameters.BackupPath = [string]$request.backupPath }
    if ($request.noDedupe) { $parameters.NoDedupe = $true }
    & ([string]$request.scriptPath) @parameters
    exit 0
} catch {
    try {
        Set-Content -LiteralPath ([string]$request.resultFile) -Value ('FEHLER: ' + $_.Exception.Message) -Encoding utf8
    } catch {}
    Write-Error $_
    exit 1
}
'@.Replace('__PAYLOAD__', $payloadBase64)
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bootstrap))

try {
    $child = Start-Process -FilePath $pwsh -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @(
        '-NoProfile',
        '-NonInteractive',
        '-EncodedCommand',
        $encodedCommand
    )
    $result = if (Test-Path -LiteralPath $resultFile) {
        (Get-Content -LiteralPath $resultFile -Raw).Trim()
    } else {
        ''
    }
    if ($child.ExitCode -ne 0) {
        throw "Erhöhte PATH-Bereinigung fehlgeschlagen (ExitCode $($child.ExitCode)). $result"
    }
    if (-not $result) { throw 'Erhöhte PATH-Bereinigung lieferte keine Ergebnisdatei.' }
    $result
} finally {
    if (Test-Path -LiteralPath $resultFile) { Remove-Item -LiteralPath $resultFile -Force }
}

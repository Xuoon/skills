# windev: Erzeugt ein schlankes Oh-My-Posh-Theme aus einer expliziten
# Quellkonfiguration: entfernt teure Segmente (Standard: node) und deaktiviert
# die Git-Upstream-Abfrage. Überschreibt nie eine bestehende Datei.
param(
    [string]$OutPath = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\sven.omp.json'),
    [string]$SourceConfig = (Join-Path $PSScriptRoot '..\assets\base.omp.json'),
    [string[]]$RemoveSegments = @('node'),
    [bool]$GitStatusCounts = $true,
    [switch]$RemoveRightPrompt
)
$ErrorActionPreference = 'Stop'

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { throw 'oh-my-posh nicht gefunden — zuerst installieren.' }
if (Test-Path $OutPath) { throw "Existiert bereits: $OutPath — bewusst umbenennen/löschen und erneut ausführen." }
$source = Resolve-Path -LiteralPath $SourceConfig -ErrorAction Stop
$dir = Split-Path $OutPath -Parent
if (-not $dir) {
    $dir = (Get-Location).Path
    $OutPath = Join-Path $dir $OutPath
}
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$tempPath = Join-Path $dir ('.{0}.{1}.tmp' -f ([IO.Path]::GetFileName($OutPath)), [guid]::NewGuid().ToString('N'))

try {
    # -NoProfile-Sessions haben keinen OMP-Session-Cache. Die Quellkonfiguration
    # deshalb immer explizit übergeben und erst nach erfolgreicher Bearbeitung
    # atomar an den Zielpfad verschieben.
    $exportOutput = @(oh-my-posh config export --config $source.Path --output $tempPath 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tempPath)) {
        throw "Oh-My-Posh-Export fehlgeschlagen: $($exportOutput -join ' ')"
    }

    $cfg = Get-Content -LiteralPath $tempPath -Raw | ConvertFrom-Json -Depth 100
    if ($RemoveRightPrompt) {
        $cfg.blocks = @($cfg.blocks | Where-Object { $_.type -ne 'rprompt' -and $_.alignment -ne 'right' })
    }
    foreach ($b in $cfg.blocks) {
        $b.segments = @($b.segments | Where-Object { $RemoveSegments -notcontains $_.type })
    }
    $gitSegments = $cfg.blocks | ForEach-Object { $_.segments } | Where-Object { $_.type -eq 'git' }
    foreach ($g in $gitSegments) {
        # Export liefert teils properties=null → deshalb Add-Member -Force statt Zuweisung
        if ($null -eq $g.properties) { $g | Add-Member -NotePropertyName properties -NotePropertyValue ([pscustomobject]@{}) -Force }
        $g.properties | Add-Member -NotePropertyName fetch_upstream_icon -NotePropertyValue $false -Force
        $g.properties | Add-Member -NotePropertyName fetch_status -NotePropertyValue $GitStatusCounts -Force
    }
    $cfg | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $tempPath -Encoding utf8
    Move-Item -LiteralPath $tempPath -Destination $OutPath
} finally {
    if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
}

"Theme geschrieben: $OutPath"
"Quelle: $($source.Path)"
"Segmente: " + (($cfg.blocks | ForEach-Object { $_.segments } | ForEach-Object { $_.type }) -join ', ')
"Nachmessen: oh-my-posh debug --plain --config `"$OutPath`""

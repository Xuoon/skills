# windev: Aktualisiert genau zwei Terminal-Werte in einer VS-Code-JSONC-Datei.
# Kommentare und fremde Einstellungen bleiben erhalten; vor Änderungen entsteht
# ein Backup. Mehrfach vorhandene Zielschlüssel führen zum Abbruch.
param(
    [Parameter(Mandatory)][string]$SettingsPath,
    [string]$FontFamily = 'CaskaydiaCove NF',
    [ValidateSet('auto','on','off')][string]$GpuAcceleration = 'auto'
)
$ErrorActionPreference = 'Stop'

function Get-JsoncObjectDepthAt {
    param([string]$Text, [int]$Index)
    $depth = 0
    $inString = $false
    $escaped = $false
    $lineComment = $false
    $blockComment = $false
    for ($i = 0; $i -lt $Index; $i++) {
        $char = $Text[$i]
        $next = if ($i + 1 -lt $Index) { $Text[$i + 1] } else { [char]0 }
        if ($lineComment) {
            if ($char -eq "`n") { $lineComment = $false }
            continue
        }
        if ($blockComment) {
            if ($char -eq '*' -and $next -eq '/') { $blockComment = $false; $i++ }
            continue
        }
        if ($inString) {
            if ($escaped) { $escaped = $false; continue }
            if ($char -eq '\') { $escaped = $true; continue }
            if ($char -eq '"') { $inString = $false }
            continue
        }
        if ($char -eq '/' -and $next -eq '/') { $lineComment = $true; $i++; continue }
        if ($char -eq '/' -and $next -eq '*') { $blockComment = $true; $i++; continue }
        if ($char -eq '"') { $inString = $true; continue }
        if ($char -eq '{') { $depth++ }
        elseif ($char -eq '}') { $depth-- }
    }
    if ($inString -or $lineComment -or $blockComment) { return -1 }
    return $depth
}

function Set-JsoncStringProperty {
    param([string]$Text, [string]$Name, [string]$Value)
    $escapedName = [regex]::Escape($Name)
    # Nur den Wert matchen. So funktionieren auch kompakte JSONC-Objekte,
    # CRLF und Blockkommentare, ohne fremde Formatierung umzuschreiben.
    $trivia = '(?:(?:[ \t\r\n]+|//[^\r\n]*(?:\r?\n|\z)|/\*.*?\*/))*'
    $pattern = '(?s)(?<prefix>"' + $escapedName + '"' + $trivia + ':' + $trivia + ')(?<value>"(?:\\.|[^"\\])*"|null|true|false|-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    $nameMatches = @([regex]::Matches($Text, '(?s)"' + $escapedName + '"' + $trivia + ':') | Where-Object { (Get-JsoncObjectDepthAt -Text $Text -Index $_.Index) -eq 1 })
    if ($nameMatches.Count -gt 1) { throw "Mehrfacher globaler JSONC-Schluessel: $Name" }
    $matches = @([regex]::Matches($Text, $pattern) | Where-Object { (Get-JsoncObjectDepthAt -Text $Text -Index $_.Index) -eq 1 })
    if ($matches.Count -gt 1) { throw "Mehrfacher globaler JSONC-Schluessel: $Name" }
    if ($nameMatches.Count -eq 1 -and $matches.Count -eq 0) { throw "JSONC-Wert fuer $Name kann nicht sicher ersetzt werden." }
    $jsonValue = $Value | ConvertTo-Json -Compress
    if ($matches.Count -eq 1) {
        $match = $matches[0]
        $replacement = $match.Groups['prefix'].Value + $jsonValue
        return $Text.Substring(0, $match.Index) + $replacement + $Text.Substring($match.Index + $match.Length)
    }
    $leadingTrivia = [regex]::Match($Text, '\A(?:(?:[ \t\r\n]+|//[^\r\n]*(?:\r?\n|\z)|/\*.*?\*/))*', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $openBrace = $leadingTrivia.Length
    if ($openBrace -ge $Text.Length -or $Text[$openBrace] -ne '{') { throw 'settings.json ist kein JSONC-Objekt.' }
    return $Text.Insert($openBrace + 1, "`r`n  `"$Name`": $jsonValue,")
}

$settingsDir = Split-Path $SettingsPath -Parent
if (-not $settingsDir) { throw '-SettingsPath braucht einen Elternordner.' }
if (-not (Test-Path -LiteralPath $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }

$exists = Test-Path -LiteralPath $SettingsPath -PathType Leaf
$current = if ($exists) { Get-Content -LiteralPath $SettingsPath -Raw } else { "{`r`n}`r`n" }
$rootPrefix = [regex]::Match($current, '\A(?:(?:[ \t\r\n]+|//[^\r\n]*(?:\r?\n|\z)|/\*.*?\*/))*', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($rootPrefix.Length -ge $current.Length -or $current[$rootPrefix.Length] -ne '{') { throw 'settings.json ist kein JSONC-Objekt.' }
$updated = Set-JsoncStringProperty -Text $current -Name 'terminal.integrated.fontFamily' -Value $FontFamily
$updated = Set-JsoncStringProperty -Text $updated -Name 'terminal.integrated.gpuAcceleration' -Value $GpuAcceleration
if ($updated -ceq $current) { "VS-Code-Settings bereits aktuell: $SettingsPath"; exit 0 }

$backupPath = $null
$tempPath = Join-Path $settingsDir ('.{0}.{1}.tmp' -f ([IO.Path]::GetFileName($SettingsPath)), [guid]::NewGuid().ToString('N'))
try {
    Set-Content -LiteralPath $tempPath -Value $updated -Encoding utf8
    if ($exists) {
        $backupPath = '{0}.backup-{1:yyyyMMdd-HHmmss}-{2}' -f $SettingsPath, (Get-Date), [guid]::NewGuid().ToString('N').Substring(0, 8)
        Copy-Item -LiteralPath $SettingsPath -Destination $backupPath
    }
    Move-Item -LiteralPath $tempPath -Destination $SettingsPath -Force
} finally {
    if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
}

"VS-Code-Settings aktualisiert: $SettingsPath"
if ($backupPath) { "Backup: $backupPath" }

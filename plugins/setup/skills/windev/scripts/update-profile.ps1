# windev: Aktualisiert ausschließlich den markierten windev-Block eines
# PowerShell-Profils. Fremde Inhalte bleiben erhalten; vor Änderungen entsteht
# ein Backup, anschließend wird die PowerShell-Syntax geprüft.
param(
    [string]$ProfilePath = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'),
    [string]$TemplatePath = (Join-Path $PSScriptRoot '..\references\profile.template.ps1')
)
$ErrorActionPreference = 'Stop'

$markerStart = '# >>> windev >>>'
$markerEnd = '# <<< windev <<<'
$template = Get-Content -LiteralPath (Resolve-Path -LiteralPath $TemplatePath) -Raw
$blockPattern = '(?ms)^' + [regex]::Escape($markerStart) + '\r?$.*?^' + [regex]::Escape($markerEnd) + '\r?$'
$templateMatch = [regex]::Match($template, $blockPattern)
if (-not $templateMatch.Success) { throw 'Template enthaelt keinen vollstaendigen windev-Markerblock.' }
$managedBlock = $templateMatch.Value

$profileDir = Split-Path $ProfilePath -Parent
if (-not $profileDir) { throw '-ProfilePath braucht einen Elternordner.' }
if (-not (Test-Path -LiteralPath $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }

$exists = Test-Path -LiteralPath $ProfilePath -PathType Leaf
$current = if ($exists) { Get-Content -LiteralPath $ProfilePath -Raw } else { '' }
$startCount = ([regex]::Matches($current, [regex]::Escape($markerStart))).Count
$endCount = ([regex]::Matches($current, [regex]::Escape($markerEnd))).Count
if ($startCount -ne $endCount -or $startCount -gt 1) { throw 'Profil enthaelt einen unvollstaendigen oder mehrfachen windev-Markerblock.' }

if ($startCount -eq 1) {
    $existingMatch = [regex]::Match($current, $blockPattern)
    $prefix = $current.Substring(0, $existingMatch.Index)
    $blockingPrefix = @($prefix -split "`r?`n" | Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('#') })
    if ($blockingPrefix.Count -gt 0) { throw 'Vor dem windev-Guard steht ausführbarer Profilcode; sicherer Merge nicht möglich.' }
    $updated = [regex]::Replace($current, $blockPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $managedBlock })
} elseif ($current) {
    $updated = $managedBlock + "`r`n`r`n" + $current.TrimStart()
} else {
    $updated = $managedBlock + "`r`n"
}

if ($updated -ceq $current) { "Profil bereits aktuell: $ProfilePath"; exit 0 }

$tempPath = Join-Path $profileDir ('.{0}.{1}.tmp' -f ([IO.Path]::GetFileName($ProfilePath)), [guid]::NewGuid().ToString('N'))
$backupPath = $null
try {
    Set-Content -LiteralPath $tempPath -Value $updated -Encoding utf8
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($tempPath, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw "Profil-Syntax ungueltig: $(($errors.Message) -join '; ')" }
    if ($exists) {
        $backupPath = '{0}.backup-{1:yyyyMMdd-HHmmss}-{2}' -f $ProfilePath, (Get-Date), [guid]::NewGuid().ToString('N').Substring(0, 8)
        Copy-Item -LiteralPath $ProfilePath -Destination $backupPath
    }
    Move-Item -LiteralPath $tempPath -Destination $ProfilePath -Force
} finally {
    if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
}

"Profil aktualisiert: $ProfilePath"
if ($backupPath) { "Backup: $backupPath" }

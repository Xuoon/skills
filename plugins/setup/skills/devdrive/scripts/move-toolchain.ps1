# devdrive: Zieht einen Toolchain-Ordner oder Cache auf das Dev Drive und setzt die
# zugehoerigen Variablen im User-Scope. Kein Admin noetig.
#   -Mode Move      Inhalt erst vollstaendig kopieren, dann Quelle loeschen
#   -Mode Discard   Quelle loeschen, nicht kopieren (ausschliesslich regenerierbare Caches)
#   -Mode EnvOnly   nur Variablen setzen (Quelle existiert nicht oder bleibt bewusst liegen)
# -EnvFile liest Variablen aus einem JSON-Objekt, -PathReplace ersetzt einen Eintrag im User-PATH.
# Vorher werden alle betroffenen User-Variablen und der PATH als JSON gesichert.
param(
    [Parameter(Mandatory)][string]$Name,
    [string]$Source,
    [string]$Target,
    [Parameter(Mandatory)][ValidateSet('Move','Discard','EnvOnly')][string]$Mode,
    [string]$EnvFile,
    [string]$PathReplace,
    [string]$ConfirmDiscardPath,
    [string]$BackupDir = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell')
)
$ErrorActionPreference = 'Stop'

if ($Mode -ne 'EnvOnly' -and -not $Source) { throw "-Source fehlt fuer Modus $Mode." }
if ($Mode -eq 'Move' -and -not $Target) { throw '-Target fehlt fuer Modus Move.' }
if ($Mode -eq 'Discard' -and -not $ConfirmDiscardPath) { throw '-ConfirmDiscardPath fehlt fuer den loeschenden Modus Discard.' }

$sourceFull = if ($Source) { [IO.Path]::GetFullPath($Source).TrimEnd('\') } else { $null }
$targetFull = if ($Target) { [IO.Path]::GetFullPath($Target).TrimEnd('\') } else { $null }
if ($sourceFull -and $targetFull -and (
    $targetFull.Equals($sourceFull, [StringComparison]::OrdinalIgnoreCase) -or
    $targetFull.StartsWith($sourceFull + '\', [StringComparison]::OrdinalIgnoreCase)
)) {
    throw 'Ziel liegt innerhalb der Quelle oder ist mit ihr identisch.'
}
if ($Mode -eq 'Discard') {
    $confirmedFull = [IO.Path]::GetFullPath($ConfirmDiscardPath).TrimEnd('\')
    if (-not $confirmedFull.Equals($sourceFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw '-ConfirmDiscardPath muss exakt dem aufgeloesten Source-Pfad entsprechen.'
    }
    $protected = @(
        [IO.Path]::GetPathRoot($sourceFull),
        [Environment]::GetFolderPath('UserProfile'),
        [Environment]::GetFolderPath('MyDocuments'),
        [Environment]::GetFolderPath('Desktop'),
        [Environment]::GetFolderPath('ApplicationData'),
        [Environment]::GetFolderPath('LocalApplicationData'),
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'),
        $env:OneDrive,
        $env:SystemRoot,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        $env:ProgramData
    ) | Where-Object { $_ } | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') }
    if ($protected | Where-Object {
        $_.Equals($sourceFull, [StringComparison]::OrdinalIgnoreCase) -or
        $_.StartsWith($sourceFull + '\', [StringComparison]::OrdinalIgnoreCase)
    }) {
        throw "Unsicheres Discard-Ziel wird nicht geloescht: $sourceFull"
    }
}

$envUpdates = @()
if ($EnvFile) {
    $envPath = (Resolve-Path -LiteralPath $EnvFile -ErrorAction Stop).Path
    $envObject = Get-Content -LiteralPath $envPath -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($envObject -isnot [pscustomobject]) { throw '-EnvFile muss ein JSON-Objekt enthalten.' }
    foreach ($property in $envObject.PSObject.Properties) {
        if ($property.Name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$' -or $property.Value -isnot [string]) {
            throw "Ungueltiger Eintrag in -EnvFile: '$($property.Name)' (erwartet NAME: String)."
        }
        $envUpdates += [pscustomobject]@{ Name = $property.Name; Value = [string]$property.Value }
    }
}

$pathOld = $null
$pathNew = $null
if ($PathReplace) {
    $pathOld, $pathNew = $PathReplace -split '=>', 2
    if (-not $pathOld -or -not $pathNew) { throw '-PathReplace erwartet "alt=>neu".' }
}

# Backup der User-Umgebung
if (-not (Test-Path -LiteralPath $BackupDir)) { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null }
$backupFile = Join-Path $BackupDir ('devdrive-env-backup-{0:yyyyMMdd-HHmmss}-{1}-{2}.json' -f (Get-Date), ($Name -replace '[^A-Za-z0-9]', ''), [guid]::NewGuid().ToString('N').Substring(0, 8))
$backup = [ordered]@{ Path = [Environment]::GetEnvironmentVariable('Path', 'User') }
foreach ($update in $envUpdates) {
    $backup[$update.Name] = [Environment]::GetEnvironmentVariable($update.Name, 'User')
}
$backup | ConvertTo-Json | Set-Content -LiteralPath $backupFile -Encoding utf8
"Backup: $backupFile"

switch ($Mode) {
    'Move' {
        if (-not (Test-Path -LiteralPath $Source)) { throw "Quelle fehlt: $Source" }
        if (Test-Path -LiteralPath (Join-Path $Source '.labi-devdrive-move.json')) {
            throw 'Quelle enthaelt den reservierten Dateinamen .labi-devdrive-move.json.'
        }
        $gitMarker = Join-Path $Source '.git'
        if (Test-Path -LiteralPath $gitMarker -PathType Leaf) {
            throw 'Verknuepfte Git-Worktrees werden nicht automatisch verschoben.'
        }
        if (Test-Path -LiteralPath (Join-Path $gitMarker 'worktrees') -PathType Container) {
            throw 'Repos mit verknuepften Git-Worktrees werden nicht automatisch verschoben.'
        }
        $absoluteInternalLinks = @(Get-ChildItem -LiteralPath $Source -Recurse -Force -Attributes ReparsePoint -ErrorAction Stop | Where-Object {
            foreach ($linkTarget in @($_.Target)) {
                if ($linkTarget -and [IO.Path]::IsPathRooted([string]$linkTarget)) {
                    $resolvedTarget = [IO.Path]::GetFullPath([string]$linkTarget).TrimEnd('\')
                    if ($resolvedTarget.Equals($sourceFull, [StringComparison]::OrdinalIgnoreCase) -or
                        $resolvedTarget.StartsWith($sourceFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
                        return $true
                    }
                }
            }
            return $false
        })
        if ($absoluteInternalLinks.Count -gt 0) {
            $examples = ($absoluteInternalLinks | Select-Object -First 3 -ExpandProperty FullName) -join ', '
            throw "Quelle enthaelt absolute interne Reparse-Points, die nach dem Umzug brechen wuerden: $examples"
        }
        $markerPath = Join-Path $Target '.labi-devdrive-move.json'
        if (Test-Path -LiteralPath $Target) {
            $targetItems = @(Get-ChildItem -LiteralPath $Target -Force -ErrorAction SilentlyContinue)
            if ($targetItems.Count -gt 0) {
                if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) { throw "Ziel ist nicht leer: $Target" }
                $marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json -ErrorAction Stop
                if (-not ([string]$marker.Source).Equals($sourceFull, [StringComparison]::OrdinalIgnoreCase) -or
                    -not ([string]$marker.Target).Equals($targetFull, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Ziel enthaelt einen Umzugsmarker fuer eine andere Quelle: $Target"
                }
                "Passender Umzugsmarker gefunden, setze fort: $Target"
            }
        } else {
            New-Item -ItemType Directory -Path $Target -Force | Out-Null
        }
        if (-not (Test-Path -LiteralPath $markerPath)) {
            [ordered]@{
                Source = $sourceFull
                Target = $targetFull
                Name = $Name
                CreatedAt = (Get-Date).ToString('o')
            } | ConvertTo-Json | Set-Content -LiteralPath $markerPath -Encoding utf8
        }
        $log = & robocopy $Source $Target /E /COPY:DAT /DCOPY:DAT /SL /SJ /R:2 /W:2 /NFL /NDL /NJH /NP 2>&1
        # robocopy: 0-7 = Erfolg, >= 8 = Fehler
        if ($LASTEXITCODE -ge 8) { throw "robocopy fehlgeschlagen (Exit $LASTEXITCODE): $($log -join ' ')" }
        $moveLog = & robocopy $Source $Target /E /MOVE /IS /IT /COPY:DAT /DCOPY:DAT /SL /SJ /R:2 /W:2 /NFL /NDL /NJH /NP 2>&1
        if ($LASTEXITCODE -ge 8) { throw "robocopy-Abschluss fehlgeschlagen (Exit $LASTEXITCODE): $($moveLog -join ' ')" }
        if (Test-Path -LiteralPath $Source) {
            $remaining = @(Get-ChildItem -LiteralPath $Source -Recurse -Force -ErrorAction SilentlyContinue)
            $remainingData = @($remaining | Where-Object { -not $_.PSIsContainer -or ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) })
            if ($remainingData.Count -gt 0) { throw "Quelle enthaelt nach dem Umzug Restdaten und wurde nicht geloescht: $Source" }
            $remaining | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
            Remove-Item -LiteralPath $Source -Force
        }
        Remove-Item -LiteralPath $markerPath -Force
        "$Name verschoben: $Source -> $Target"
    }
    'Discard' {
        if (Test-Path -LiteralPath $Source) {
            $mb = [math]::Round(((Get-ChildItem -LiteralPath $Source -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB), 0)
            Remove-Item -LiteralPath $Source -Recurse -Force
            "$Name geloescht: $Source ($mb MB, wird neu aufgebaut)"
        } else {
            "$Name Quelle nicht vorhanden, nichts zu loeschen: $Source"
        }
        if ($Target -and -not (Test-Path -LiteralPath $Target)) { New-Item -ItemType Directory -Force -Path $Target | Out-Null }
    }
    'EnvOnly' { "$Name nur Variablen" }
}

foreach ($update in $envUpdates) {
    [Environment]::SetEnvironmentVariable($update.Name, $update.Value, 'User')
    "  $($update.Name) = $($update.Value)"
}

if ($PathReplace) {
    $parts = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
    $hit = $false
    $parts = @(foreach ($p in $parts) {
        $expanded = [Environment]::ExpandEnvironmentVariables($p).TrimEnd('\')
        if ($expanded -ieq ([Environment]::ExpandEnvironmentVariables($pathOld).TrimEnd('\'))) { $hit = $true; $pathNew } else { $p }
    })
    if (-not $hit) { $parts += $pathNew; "  PATH: '$pathOld' nicht gefunden, '$pathNew' angehaengt" }
    else { "  PATH: '$pathOld' -> '$pathNew'" }
    $seen = @{}
    $parts = @($parts | Where-Object {
        $normalized = [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\').ToLowerInvariant()
        if ($seen.ContainsKey($normalized)) { return $false }
        $seen[$normalized] = $true
        return $true
    })
    [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
}

"Neue Terminals noetig, laufende Prozesse sehen die Aenderung nicht."

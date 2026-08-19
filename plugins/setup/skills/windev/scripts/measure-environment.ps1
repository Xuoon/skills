# windev: Read-only-Inventur & Messung der PowerShell-/Terminal-Umgebung.
# Gibt einen Textbericht auf stdout aus; ändert nichts am System.
param(
    [string]$OhMyPoshConfig
)
$ErrorActionPreference = 'Continue'

function Section($t) { "`n=== $t ===" }

function Resolve-OhMyPoshConfig {
    param(
        [string]$ExplicitConfig,
        [string[]]$Profiles,
        [string]$DocumentsPath
    )

    $candidates = @(@($ExplicitConfig, $env:POSH_CONFIG) | Where-Object { $_ })

    $profileCandidates = @()

    # Literal angegebene --config-Pfade aus Profilen lesen, ohne Profile oder
    # sonstigen Nutzercode auszuführen. Variablen-Ausdrücke werden bewusst nicht
    # geraten; der Aufrufer kann sie über -OhMyPoshConfig explizit auflösen.
    foreach ($profilePath in $Profiles) {
        if (-not (Test-Path -LiteralPath $profilePath)) { continue }
        $profileText = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
        foreach ($match in [regex]::Matches($profileText, '(?im)--config\s+(?:"(?<double>[^"]+)"|''(?<single>[^'']+)''|(?<bare>[^\s|;]+))')) {
            $value = @($match.Groups['double'].Value, $match.Groups['single'].Value, $match.Groups['bare'].Value) |
                Where-Object { $_ } | Select-Object -First 1
            if ($value -and $value -notmatch '\$') { $profileCandidates += $value }
        }
    }

    # PowerShell lädt die Profile in der angegebenen Reihenfolge; die letzte
    # OMP-Initialisierung gewinnt. Deshalb rückwärts nach dem aktiven Pfad suchen.
    for ($i = $profileCandidates.Count - 1; $i -ge 0; $i--) {
        $candidates += $profileCandidates[$i]
    }

    # Das mitgelieferte Profil verwendet diesen festen Zielnamen.
    $candidates += (Join-Path $DocumentsPath 'PowerShell\sven.omp.json')

    foreach ($candidate in $candidates) {
        $expanded = [Environment]::ExpandEnvironmentVariables($candidate)
        if ($expanded -eq '~') { $expanded = [Environment]::GetFolderPath('UserProfile') }
        elseif ($expanded.StartsWith('~\') -or $expanded.StartsWith('~/')) {
            $expanded = Join-Path ([Environment]::GetFolderPath('UserProfile')) $expanded.Substring(2)
        }
        if (Test-Path -LiteralPath $expanded -PathType Leaf) {
            return (Resolve-Path -LiteralPath $expanded).Path
        }
    }
    return $null
}

Section 'System & Tools'
"PowerShell: $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
"OS: $([Environment]::OSVersion.VersionString)"
foreach ($tool in 'winget','git','oh-my-posh','zoxide','node','bun','pwsh') {
    $c = Get-Command $tool -ErrorAction SilentlyContinue
    $source = if ($c) { $c.Source } else { 'FEHLT' }
    "{0}: {1}" -f $tool, $source
}

Section 'Startzeiten (je 3x, ms — Differenz = Profilkosten im nicht-interaktiven Pfad)'
$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshCommand) {
    $noP = 1..3 | ForEach-Object { '{0:N0}' -f (Measure-Command { & $pwshCommand.Source -NoProfile -Command 1 }).TotalMilliseconds }
    $wiP = 1..3 | ForEach-Object { '{0:N0}' -f (Measure-Command { & $pwshCommand.Source -Command 1 }).TotalMilliseconds }
    "ohne Profil: $($noP -join ' / ')"
    "mit  Profil: $($wiP -join ' / ')"
    "Hinweis: Ein Guard im Profil wirkt hier bereits; die interaktive Startzeit kann höher liegen."
} else {
    'übersprungen: pwsh fehlt (PowerShell 7 zuerst bootstrappen)'
}

Section 'Profildateien'
$docs = [Environment]::GetFolderPath('MyDocuments')
$profilePaths = @(
    "$env:ProgramFiles\PowerShell\7\profile.ps1",
    "$env:ProgramFiles\PowerShell\7\Microsoft.PowerShell_profile.ps1",
    (Join-Path $docs 'PowerShell\profile.ps1'),
    (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $docs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
)
foreach ($p in $profilePaths) {
    if (Test-Path $p) { "{0}  ({1:N1} KB)" -f $p, ((Get-Item $p).Length / 1KB) }
}
"Alle Dateien im pwsh-Profilordner:"
Get-ChildItem (Join-Path $docs 'PowerShell') -File -ErrorAction SilentlyContinue |
    ForEach-Object { "  {0} ({1:N1} KB)" -f $_.Name, ($_.Length / 1KB) }

Section 'PSReadLine-Historie'
try {
    $h = (Get-PSReadLineOption -ErrorAction Stop).HistorySavePath
    if (Test-Path $h) {
        "{0}: {1:N0} KB, {2} Zeilen" -f $h, ((Get-Item $h).Length / 1KB), (Get-Content $h | Measure-Object -Line).Lines
    }
} catch { "nicht ermittelbar (nicht-interaktive Session): normal, kein Befund" }

Section 'Oh My Posh (Segment-Zeiten im aktuellen Verzeichnis)'
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    "Version: $(oh-my-posh version)"
    $activeConfig = Resolve-OhMyPoshConfig -ExplicitConfig $OhMyPoshConfig -Profiles $profilePaths -DocumentsPath $docs
    if ($activeConfig) {
        "POSH_CONFIG: $activeConfig"
        $debugOutput = @(oh-my-posh debug --plain --config $activeConfig 2>&1)
        if ($LASTEXITCODE -eq 0) {
            $debugOutput | Select-String '\((true|false)\)|Run duration' | ForEach-Object { "  $_" }
        } else {
            "  Segmentmessung fehlgeschlagen: $($debugOutput -join ' ')"
        }
    } else {
        'POSH_CONFIG: nicht ermittelbar'
        '  Segmentmessung übersprungen — aktiven Theme-Pfad mit -OhMyPoshConfig übergeben.'
    }
} else { "nicht installiert" }

Section 'PATH-Audit'
$userKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
$machineKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment')
try {
    $userRaw = $userKey.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $machRaw = $machineKey.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
} finally {
    if ($userKey) { $userKey.Close() }
    if ($machineKey) { $machineKey.Close() }
}
$userParts = @($userRaw -split ';' | Where-Object { $_ })
$machParts = @($machRaw -split ';' | Where-Object { $_ })
"User-PATH: $($userParts.Count) Einträge · Machine-PATH: $($machParts.Count) Einträge (Rohwerte, unexpandiert)"
$tagged = @($userParts | ForEach-Object { [pscustomobject]@{ Scope = 'User   '; Entry = $_ } }) +
          @($machParts | ForEach-Object { [pscustomobject]@{ Scope = 'Machine'; Entry = $_ } })
$issues = foreach ($t in $tagged) {
    $expanded = [Environment]::ExpandEnvironmentVariables($t.Entry)
    if ($expanded -match '%[^%]+%') {
        "  UNAUFGELOEST [$($t.Scope)]: $($t.Entry)"
    } elseif (-not (Test-Path -LiteralPath $expanded)) {
        $detail = if ($expanded -ne $t.Entry) { " -> $expanded" } else { '' }
        "  TOT [$($t.Scope)]: $($t.Entry)$detail"
    }
}
if ($issues) { $issues } else { "  keine toten/unaufgelösten Einträge" }
$dups = $tagged | Group-Object { $_.Entry.TrimEnd('\').ToLowerInvariant() } | Where-Object Count -gt 1
if ($dups) {
    "-- Duplikate (über beide Scopes, normalisiert) --"
    $dups | ForEach-Object { "  {0}x: {1}  [{2}]" -f $_.Count, $_.Group[0].Entry, (($_.Group.Scope | ForEach-Object { $_.Trim() }) -join '+') }
}

Section 'Modul-Mehrfachversionen (CurrentUser-Scope)'
$modRoot = Join-Path $docs 'PowerShell\Modules'
$multi = Get-ChildItem $modRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $v = @(Get-ChildItem $_.FullName -Directory -ErrorAction SilentlyContinue)
    if ($v.Count -gt 1) { "  {0}: {1}" -f $_.Name, (($v.Name | Sort-Object) -join ', ') }
}
if ($multi) { $multi } else { "  keine Mehrfachversionen" }

Section 'VS Code'
$variants = @(
    @{
        Name = 'Stable'
        Exes = @(
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
            "$env:ProgramFiles\Microsoft VS Code\Code.exe"
            "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
        ) | Where-Object { $_ -and $_ -notmatch '^\\' }
        Settings = "$env:APPDATA\Code\User\settings.json"
    },
    @{
        Name = 'Insiders'
        Exes = @(
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code Insiders\Code - Insiders.exe"
            "$env:ProgramFiles\Microsoft VS Code Insiders\Code - Insiders.exe"
            "${env:ProgramFiles(x86)}\Microsoft VS Code Insiders\Code - Insiders.exe"
        ) | Where-Object { $_ -and $_ -notmatch '^\\' }
        Settings = "$env:APPDATA\Code - Insiders\User\settings.json"
    }
)
foreach ($v in $variants) {
    $installedExe = $v.Exes | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    $inst = $null -ne $installedExe
    $set = Test-Path $v.Settings
    $note = if ($set -and -not $inst) { '  <- Settings-LEFTOVER einer deinstallierten Variante' } else { '' }
    "{0}: installiert={1}, Settings={2}{3}" -f $v.Name, $inst, $set, $note
    if ($installedExe) { "  EXE: $installedExe" }
    if ($set) {
        Select-String -Path $v.Settings -Pattern 'fontFamily|gpuAcceleration' -ErrorAction SilentlyContinue |
            ForEach-Object { "    $($_.Line.Trim())" }
    }
}

Section 'Nerd Fonts (installiert)'
$fontNames = @()
foreach ($hive in 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts') {
    $fp = Get-ItemProperty $hive -ErrorAction SilentlyContinue
    if ($fp) { $fontNames += $fp.PSObject.Properties.Name }
}
$nf = $fontNames | Where-Object { $_ -match 'Nerd|NF ' } | Sort-Object -Unique
if ($nf) { $nf | Select-Object -First 8 | ForEach-Object { "  $_" } } else { "  KEINE Nerd Fonts gefunden" }

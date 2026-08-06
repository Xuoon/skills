# ══════════════════════════════════════════════════════════════════════
# PowerShell-Profil — Vorlage aus dem windev-Plugin
# Blöcke: Guard → Prompt → zoxide → PSReadLine → Terminal-Icons →
#         Funktionen & Aliase → Show-Help
# Jede Sektion ist optional — beim Einrichten an die Auswahl des
# Nutzers anpassen. Fremd-Tool-Blöcke (Marker) unverändert anhängen.
# ══════════════════════════════════════════════════════════════════════

# ── Guard ─────────────────────────────────────────────────────────────
# Nicht-interaktive Aufrufe (pwsh -Command/-NonInteractive, Automatisierung,
# CI, umgeleitete Ein-/Ausgabe) brauchen nichts hiervon: sofort raus.
# Spart die volle Profilzeit pro Aufruf und vermeidet PSReadLine-Fehler
# ohne Konsolen-Handle.
if ([Console]::IsOutputRedirected -or [Console]::IsInputRedirected -or
    ([Environment]::GetCommandLineArgs() -match '^-(noni|c(ommand)?$|e(c|ncodedcommand)?$)')) {
    return
}

# ── Prompt: Oh My Posh mit schlankem lokalem Theme ────────────────────
# Theme liegt neben dem Profil (sven.omp.json, erzeugt via new-slim-theme.ps1).
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $__theme = Join-Path $PSScriptRoot 'sven.omp.json'
    if (Test-Path $__theme) {
        oh-my-posh init pwsh --config $__theme | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
    Remove-Variable __theme -ErrorAction SilentlyContinue
}

# ── zoxide: „z <ordner>" springt zu häufig besuchten Pfaden ───────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init --cmd z powershell | Out-String | Invoke-Expression
}

# ── PSReadLine: Vorschlagsliste, Farben, Tastenkürzel ─────────────────
Set-PSReadLineOption -PredictionViewStyle ListView -Colors @{
    Command   = '#87CEEB'
    Parameter = '#98FB98'
    Operator  = '#FFB6C1'
    Variable  = '#DDA0DD'
    String    = '#FFDAB9'
    Number    = '#B0E0E6'
    Type      = '#F0E68C'
    Comment   = '#D3D3D3'
    Keyword   = '#8367c7'
    Error     = '#FF6347'
}

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

# ── Terminal-Icons: rein kosmetisch → im Leerlauf nachladen ───────────
# Blockiert den Start nicht; Icons erscheinen kurz nach dem ersten Prompt.
$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module Terminal-Icons -Global -ErrorAction SilentlyContinue
}

# ── Datei- & Verzeichnis-Helfer ───────────────────────────────────────
function touch ($File) {
    if (Test-Path $File) {
        (Get-Item $File).LastWriteTime = Get-Date
    } else {
        New-Item $File -ItemType File | Out-Null
    }
}

function mkcd ($Path) {
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Set-Location -Path $Path
}

function trash ($Path) {
    if (Test-Path $Path -PathType Container) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Path,'OnlyErrorDialogs','SendToRecycleBin')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Path,'OnlyErrorDialogs','SendToRecycleBin')
    }
}

function ff ($Name) {
    Get-ChildItem -Recurse -Filter $Name -File | Select-Object -ExpandProperty FullName
}

function head ($Path) {
    Get-Content $Path -Head 10
}

function which ($Name) {
    (Get-Command $Name).Source
}

function pgrep ($Name) {
    Get-Process -Name $Name -ErrorAction SilentlyContinue
}

function pkill ($Name) {
    Get-Process -Name $Name -ErrorAction SilentlyContinue | Stop-Process -Force
}

function uptime {
    (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime | Select-Object Days, Hours, Minutes, Seconds
}

# ── Git-Kürzel ────────────────────────────────────────────────────────
function gs { git status }
function ga { git add . }
function gp { git push }
function gpull { git pull }
function gcl { git clone $args }

function gcom {
    git add .
    git commit -m "$args"
}

function lazyg {
    git add .
    git commit -m "$args"
    git push
}

# ── Auflisten & Aliase ────────────────────────────────────────────────
function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

Set-Alias -Name unzip -Value Expand-Archive
Set-Alias -Name grep -Value Select-String

# ── Show-Help: Übersicht der Profil-Funktionen ────────────────────────
function Show-Help {
    $c = $PSStyle.Foreground.BrightGreen
    $d = $PSStyle.Foreground.BrightWhite
    $r = $PSStyle.Reset
    Write-Host @"
${c}gs/ga/gp/gpull/gcl/gcom/lazyg${r} ${d}Git-Kürzel (status/add/push/pull/clone/commit/commit+push)${r}
${c}z <ordner>${r}                    ${d}Sprung zu häufig besuchtem Verzeichnis (zoxide)${r}
${c}la / ll${r}                       ${d}Auflisten (ll inkl. versteckte)${r}
${c}mkcd / touch / trash / ff${r}     ${d}Verzeichnis+cd / Datei anlegen / Papierkorb / Datei suchen${r}
${c}head / which / grep / unzip${r}   ${d}Erste Zeilen / Pfad eines Befehls / Suchen / Entpacken${r}
${c}pgrep / pkill / uptime${r}        ${d}Prozess finden / beenden / Laufzeit${r}
"@
}

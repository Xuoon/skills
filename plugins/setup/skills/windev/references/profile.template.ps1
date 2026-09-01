# ══════════════════════════════════════════════════════════════════════
# PowerShell-Profil — Vorlage aus dem windev-Plugin
# Verwalteter Basissatz: Guard → Prompt → zoxide → PSReadLine → Terminal-Icons.
# Persönliche Funktionen und Aliase gehören nicht in den automatischen Standard.
# ══════════════════════════════════════════════════════════════════════

# >>> windev >>>
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
# Theme liegt neben dem Profil (windev.omp.json, erzeugt via new-slim-theme.ps1).
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $__theme = Join-Path $PSScriptRoot 'windev.omp.json'
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
# <<< windev <<<

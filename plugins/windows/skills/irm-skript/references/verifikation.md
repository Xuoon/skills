# Verifikation — Pflicht vor jeder Lieferung

Es gibt in der Dev-Umgebung kein Windows/AD. Verifiziert wird deshalb statisch
(Parser) und mit gemockten Cmdlets. Erst liefern, wenn alle Punkte grün sind.

## 1. pwsh besorgen (falls nicht vorhanden)

```bash
command -v pwsh || ls /tmp/pwsh/pwsh 2>/dev/null || {
  mkdir -p /tmp/pwsh && cd /tmp/pwsh
  curl -sL https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/powershell-7.4.6-linux-x64.tar.gz | tar xz
}
PWSH=$(command -v pwsh || echo /tmp/pwsh/pwsh)
```

(Version egal, jede 7.x reicht — es geht um Parser und Sprachsemantik.)

## 2. Parser-Check (0 Fehler) + BOM-Check

```bash
$PWSH -NoProfile -Command '
  $t=[IO.File]::ReadAllText("<datei>.ps1")
  $errs=$null
  [System.Management.Automation.Language.Parser]::ParseInput($t,[ref]$null,[ref]$errs)|Out-Null
  if($errs.Count){ $errs|ForEach-Object{ "FEHLER: $($_.Message) @ $($_.Extent.StartLineNumber)" }; exit 1 }
  "PARSE OK"
'
head -c 3 <datei>.ps1 | xxd   # darf NICHT mit "ef bb bf" beginnen
```

BOM-frei schreiben aus Python: `open(p,'w',encoding='utf-8',newline='\n')` (niemals
`utf-8-sig`). Aus pwsh: `[IO.File]::WriteAllText($p,$t)` (default UTF-8 ohne BOM in 7.x).

## 3. Gemockte Tests

Idee: Vor dem Dot-Sourcen des Skripts die Windows-/AD-Cmdlets als Funktionen stubben
und die `Start-*`-Zeile am Ende neutralisieren, dann gezielt Funktionen aufrufen.

```powershell
# test.ps1 (Skizze)
$src = [IO.File]::ReadAllText('<datei>.ps1')
$src = $src -replace '(?m)^Start-\w+\s*$',''      # Autostart abklemmen
function Get-CimInstance { param($ClassName) <# Fake-Objekte je Klasse #> }
function Set-ItemProperty { $script:Writes++ ; }   # Schreibzähler
function Read-Host { 'n' }                          # Bestätigungen verweigern
. ([ScriptBlock]::Create($src))
# ... Funktionen einzeln aufrufen und Annahmen prüfen ...
```

Pflicht-Assertions:

- **Lesende Tools**: Hauptpfad läuft mit Mocks durch; es gibt KEINE schreibenden
  Cmdlets im Skript (grep nach `Set-`, `New-`, `Remove-`, `Start-ScheduledTask`,
  `Restart-Computer` — Treffer erklären oder entfernen).
- **Schreibende Tools**:
  - Vorschau/Dry-Run-Pfad: Schreibzähler bleibt 0.
  - Bestätigung verweigert (`Read-Host` → 'n' / falsches Token): Schreibzähler bleibt 0.
  - Bestätigung erteilt (Mock liefert 'j' bzw. korrektes Token): Schreibpfad wird
    erreicht (Zähler > 0) und Rollback-Objekt enthält den Alt-Zustand.
- Headless: mit `$script:Interactive = $false` crasht nichts (Read-Key-Pfad
  liefert QUIT statt Exception).

## 4. Stil-Selbstcheck (kurz, gegen die Datei greppen)

- `by Sven Labitzki` im Header vorhanden
- `[ OK ]` / `[ !! ]`-Badges statt Eigenkreationen
- keine Umlaute in Write-Host-Strings (`grep -nP '[äöüÄÖÜß]'` auf TUI-Zeilen)
- genau ein `Start-*`-Aufruf am Dateiende
- `TreatControlCAsInput` gesetzt UND im finally zurückgesetzt

## 5. Hinweis an Sven

Bei schreibenden Tools zum Schluss einmal kurz erwähnen: zuerst auf einem
Testsystem/Test-DC laufen lassen — die Mocks prüfen Logik, nicht die Umgebung.

# Stilguide — der verbindliche Hausstil (labi.dev/secureboot)

Referenz-Tools: `labi.dev/secureboot` (Rollout-Assistent) und `labi.dev/loswochos`
(Check mit Fortschritt). Neue Tools MÜSSEN sich so anfühlen. Die Helper unten sind
wörtlich der Hausstandard — Namen und Verhalten beibehalten, damit sich jedes Tool
gleich bedient.

## Grundgerüst

```
<#
  <Toolname> — <Einzeiler, was es tut>

  Aufruf (elevated PowerShell, echtes Terminal):
      irm labi.dev/<route> | iex

  Basis: <KB-Artikel / Doku-Quellen, falls relevant>
#>

# ... alle Funktionen ...

function Start-<Tool> {
    # Breite, State, Helfer (script-scope), Gates, Hauptschleife
}

Start-<Tool>
```

- Genau EINE `Start-*`-Funktion am Ende, einmal aufgerufen. Alles weitere sind
  Funktionen darin oder davor.
- Body der Hauptschleife in `try/finally`: `[Console]::TreatControlCAsInput = $true`
  setzen und im `finally` zurücksetzen.
- Headless-Verhalten festlegen: `[Console]::IsInputRedirected` → bei Lese-Tools ein
  automatischer Einmal-Lauf mit Plain-Ausgabe, bei schreibenden Tools Abbruch mit
  Hinweis (interaktive Bestätigungen sind dort Pflicht).
- Variablen, die der Nutzer vorab setzen kann (`$kd = '1234'`), am Start aus dem
  Global-Scope einsammeln (`Get-Variable -Scope Global`).

## Konsolenbreite

```powershell
$script:Width = 64
try { $w = [Console]::WindowWidth; if ($w -gt 0) { $script:Width = [Math]::Max(40, [Math]::Min(64, $w - 4)) } } catch {}
```

(loswochos nutzt 54–86 bei mehr Inhalt — Bereich nach Bedarf, aber immer geklemmt.)

## Eingabe

```powershell
function Read-Key {
    try { $ki = [Console]::ReadKey($true) }
    catch { return 'QUIT' }
    if (($ki.Modifiers -band [ConsoleModifiers]::Control) -and $ki.Key -eq 'C') { return 'QUIT' }
    switch ($ki.Key) {
        'Enter'      { return 'ENTER' }
        'Escape'     { return 'B' }
        'RightArrow' { return 'RIGHT' }
        'LeftArrow'  { return 'LEFT'  }
        'Spacebar'   { return 'SPACE' }
        default      { return $ki.KeyChar.ToString().ToUpper() }
    }
}
function Wait-Key { if ($script:Interactive) { try { [void][Console]::ReadKey($true) } catch {} } }
```

Warum try/catch: in nicht-interaktiven Hosts wirft ReadKey — `QUIT` statt Crash.
Esc mappt auf `B`, damit "zurück" überall gleich funktioniert.
Freitext (Kundennummer, Pfade) per `Read-Host` mit farbigem `> `-Prompt — Tasten nur,
wo eine Taste reicht.

## Ausgabe-Helfer

```powershell
function Write-Line  { param([string]$Text='',[string]$Color='Gray') Write-Host $Text -ForegroundColor $Color }
function Write-Blank { Write-Host '' }
function Write-Rule  { Write-Host ('  ' + ('-' * $script:Width)) -ForegroundColor DarkCyan }

function Write-Header {
    if ($script:Interactive) { Clear-Host }
    Write-Blank
    Write-Host '   <TOOLNAME>   <Untertitel>' -ForegroundColor Cyan
    Write-Host '   by Sven Labitzki' -ForegroundColor DarkGray
    Write-Rule
    # eine DarkGray-Kontextzeile: Host | OS/Domaene | Rolle/Plattform
    Write-Blank
}

function Write-StatusRow {
    param([string]$Label,[string]$State)
    switch ($State) {
        'done'    { $badge='[ OK ]'; $color='Green' }
        'running' { $badge='[ >> ]'; $color='Cyan' }
        'failed'  { $badge='[ !! ]'; $color='Red' }
        'warn'    { $badge='[ ~~ ]'; $color='Yellow' }
        default   { $badge='[ -- ]'; $color='DarkGray' }
    }
    $pad = [Math]::Max(1, $script:Width - $Label.Length - $badge.Length)
    Write-Host ('   ' + $Label) -ForegroundColor Gray -NoNewline
    Write-Host (' ' * $pad) -NoNewline
    Write-Host $badge -ForegroundColor $color
}

function Write-MenuCell {
    param([string]$Key,[string]$Label,[string]$KeyColor='Cyan',[int]$Cell=22)
    Write-Host "[$Key] " -ForegroundColor $KeyColor -NoNewline
    Write-Host $Label -ForegroundColor DarkGray -NoNewline
    $pad = $Cell - ($Key.Length + 3 + $Label.Length)
    if ($pad -gt 0) { Write-Host (' ' * $pad) -NoNewline }
}

function Write-KeyValue {
    param([string]$Key,[string]$Value,[string]$Color='Gray')
    Write-Host ('   {0,-26}: ' -f $Key) -ForegroundColor DarkGray -NoNewline
    Write-Host $Value -ForegroundColor $Color
}

function Show-FooterPrompt {
    param([string]$Text='Taste zum Zurueck')
    Write-Blank
    Write-Line ("   {0} ..." -f $Text) DarkCyan
    Wait-Key
}
```

Fortschrittsbalken (für Läufe mit mehreren Schritten):

```powershell
function Get-Bar {
    param([int]$Value,[int]$Max,[int]$BarWidth=14)
    if ($Max -le 0) { return ('-' * $BarWidth) }
    $v = [math]::Max(0, [math]::Min($Value, $Max))
    $f = [int][math]::Floor($BarWidth * $v / $Max)
    return ('#' * $f) + ('-' * ($BarWidth - $f))
}
# Anzeige: '   [' + (Get-Bar $done $total ($script:Width - 12)) + ('] {0}/{1}' -f $done,$total)
```

## Badges & Farben (fest)

| Badge    | Farbe      | Bedeutung                          |
|----------|------------|------------------------------------|
| `[ OK ]` | Green      | erledigt                           |
| `[ >> ]` | Cyan       | angestoßen / läuft                 |
| `[ !! ]` | Red        | Fehler / blockiert                 |
| `[ ~~ ]` | Yellow     | Warnung / teilweise                |
| `[ -- ]` | DarkGray oder DarkYellow | offen                |

Textmarker: `[X]` Red = Abbruch/Fehler, `[!]` Yellow = Warnung, `[+]` Green = Erfolg,
`>` Cyan/Yellow = Eingabe-Prompt. Farben: Green ok, Yellow Vorsicht, Red Gefahr,
Cyan Aktion/läuft, White Hervorhebung, Gray Fließtext, DarkGray sekundär,
DarkCyan Rules/Footer, Magenta/DarkRed nur Experten-/Gefahrenzonen.

## Hauptbildschirm

Vollbild-Repaint statt Scrollen: jeder Zustand zeichnet per `Write-Header` neu.
Aufbau: Header → Status (`Write-StatusRow`-Block und/oder `Write-KeyValue`-Block) →
**eine klare "Nächster Schritt"-Zeile** (`-> Naechster Schritt: ...` Cyan, `! Blockiert: ...`
Red mit Verweis auf `[H]`/`[D]`, `.. wartet ...` Cyan) → `Write-Rule` → Menüzeilen aus
`Write-MenuCell` (2–3 Zellen pro Zeile, `[Enter]`-Hauptaktion zuerst, `White` wenn
verfügbar / `DarkGray` wenn nicht, `[B] Beenden` zuletzt).

Hauptschleife:

```powershell
$quit = $false
while (-not $quit) {
    $state = Get-State            # Zustand IMMER frisch erheben, dann zeichnen
    Show-Main -State $state
    switch (Read-Key) {
        'ENTER' { <# Hauptaktion #> }
        'D'     { Show-Details -State $state }
        'H'     { Show-Help }
        'N'     { }               # neu laden = einfach nochmal durch die Schleife
        'B'     { $quit = $true }
        'QUIT'  { $quit = $true }
        default { }
    }
}
```

## Hilfe (mehrseitig)

Seiten als Datenstruktur, eine Render-Schleife. 2–5 Seiten, typisch:
"Was & Warum", "Ablauf/Durchfuehrung", "Status & Tasten", ggf. "Sonderfaelle".

```powershell
$pages = @(
    @{ Title='Was & Warum'; Lines=@(
        @('Erklaert in 1-2 Saetzen das Problem.','White'),
        @('',''),
        @('Dann was das Tool tut und was NICHT.','Gray')
    )}
    # ...
)
$index = 0
while ($true) {
    Write-Header
    $page = $pages[$index]
    Write-Line ("   HILFE   {0}/{1}   -   {2}" -f ($index+1), $pages.Count, $page.Title) Yellow
    Write-Blank
    foreach ($l in $page.Lines) { if ($l[0] -eq '') { Write-Blank } else { Write-Line ('   ' + $l[0]) $l[1] } }
    Write-Blank
    Write-Rule
    Write-Line '   [->/N] weiter      [<-/P] zurueck      [B] Menue' DarkCyan
    switch (Read-Key) {
        'B'     { return }
        'QUIT'  { return }
        'P'     { if ($index -gt 0) { $index-- } }
        'LEFT'  { if ($index -gt 0) { $index-- } }
        default { if ($index -lt $pages.Count - 1) { $index++ } }
    }
}
```

## Voraussetzungs-Gates

Direkt nach dem ersten `Write-Header`, vor der Hauptschleife. Reihenfolge: Admin →
Plattform/Rolle → Module. Jedes Gate: rote/gelbe Meldung + konkrete Abhilfe + 
`Show-FooterPrompt 'Taste zum Beenden'` + `return`.

```powershell
if (-not $prereqs.IsAdmin) {
    Write-Line '   [X] Bitte als Administrator starten.' Red
    Show-FooterPrompt 'Taste zum Beenden'; return
}
```

System-Infos defensiv erheben: jedes `Get-CimInstance`/AD-Cmdlet in try/catch bzw.
`-ErrorAction SilentlyContinue`, Ergebnis als ein `[pscustomobject]`.

## Sprache & Ton

- Deutsch, knapp, technisch. Keine Floskeln, keine Emojis, kein Ausrufezeichen-Marketing.
- ASCII in der TUI: ue/oe/ae/ss ("Pruefung laeuft", "Zurueck"). Umlaute nur, wenn sie
  in Dateiausgaben (Reports) fachlich hingehören.
- Meldungen sagen, was zu TUN ist: nicht "Fehler 0x80070013", sondern
  "Event 1795: Firmware/BIOS-Update vom Hersteller noetig."
- Drei Leerzeichen Einrückung für Inhaltzeilen (passend zu `Write-Rule` mit zwei).

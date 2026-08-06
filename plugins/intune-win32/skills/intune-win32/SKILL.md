---
name: intune-win32
description: Intune-Win32-Pakete aus MSI/EXE bauen und fehlgeschlagene Rollouts eingrenzen.
argument-hint: "[Ordner, Installer oder Fehlerbeschreibung]"
disable-model-invocation: true
---

# intune-win32

Zwei Aufgaben, kein Flag: **was gemeint ist, steht in `$ARGUMENTS`.**

| Im Text steht | Aufgabe |
| --- | --- |
| Ein Ordner, ein Installer, ein Programmname | **Paket bauen** — Ablauf unten ab Schritt 0 |
| Ein Fehlercode, „geht nicht", „schlägt fehl", ein Gerät | **Problem eingrenzen** — Abschnitt „Fehlerbilder", dann gezielt beheben |
| Nichts | Genau **eine** Rückfrage stellen: Paket bauen oder Problem lösen? Kein Raten. |

Ziel beim Bauen: aus einem Ordner, in dem nur ein Installer liegt, ein vollständiges
Win32-Paket machen, das per Doppelklick auf `Pack.cmd` gepackt und direkt in
Intune hochgeladen werden kann.

**Leitprinzip: jeder Paketordner ist in sich geschlossen.** Eigene Kopie der
`IntuneWinAppUtil.exe`, keine `..\`-Verweise, keine geteilten Skripte. Ein
Ordner muss auf einen anderen Rechner kopierbar sein und dort weiterhin
funktionieren – deshalb wird lieber eine 62-KB-Exe dupliziert als eine
Abhängigkeit eingebaut.

## Konventionen kommen aus der Umgebung, nicht aus diesem Skill

Ordnerpräfix, Log-Pfad, Doku-Datei, Zuweisungsgruppen und Anforderungen sind
pro Umgebung verschieden. Sie stehen in einer optionalen `intune-paket.json`
(Fundort, Schlüssel und Standardwerte in `${CLAUDE_SKILL_DIR}/references/konfiguration.md`).
Diese Datei **zuerst suchen und lesen**. Fehlt sie, mit den dort dokumentierten
Standardwerten arbeiten und beim User nachfragen, sobald etwas davon
offensichtlich nicht passt – nicht eine Konvention erfinden und stillschweigend
durchziehen.

## Zielstruktur

```
<Präfix><Programm>\
  App\                   Nutzlast: was in die .intunewin soll
                         Installer + install.ps1 / uninstall.ps1 / detect-<Paket>.ps1
  Output\                fertige .intunewin (erzeugt Pack.cmd)
  IntuneWinAppUtil.exe   eigene Kopie
  Pack.cmd               packt App\ -> Output\, Tool-Ausgabe nach pack.log
  01_*.cmd               optional: Vorbereitung (Image erzeugen/entpacken)
  <Quell-Installer>      optional: Beschaffungsdatei, die NICHT mit ins Paket soll
```

**`App\` ist die Nutzlast, die Paketwurzel ist der Arbeitsbereich.** Alles in
`App\` landet in der `.intunewin` und damit auf jedem Zielgerät. Ein 2-GB-
Download-Bootstrapper, aus dem erst ein Image erzeugt wird, gehört deshalb in
die **Paketwurzel**, nicht in `App\` – sonst schleppt jedes Gerät den
Bootstrapper zusätzlich zum Image mit.

## Ablauf

### 0. Muss das überhaupt paketiert werden?

Vor dem Bauen kurz prüfen – das spart mehr Zeit als jeder Silent-Schalter:

- **Ist die Funktion schon abgedeckt?** Bei Tools, die nach einem Duplikat zu
  bereits verteilter Software aussehen, den User fragen, was konkret damit
  gemacht wird. Ein fertig gebautes Paket, das niemand braucht, ist der teuerste
  Ausgang.
- **Gibt es das als Store-App?** Manche Hersteller liefern nur noch über den
  Microsoft Store – dann in Intune als „Store-App (neu)" zuweisen statt ein
  Win32-Paket zu bauen.
- **Ist die Software überhaupt frei verteilbar?** Named-User-Lizenzen lassen
  sich installieren, aber nicht aktivieren. Vor dem Bauen klären, wie viele
  Lizenzen es gibt und wer sie zuweist.
- **Gibt es eine kostenlose Viewer-Variante?** Oft reicht der Viewer statt der
  Vollversion (typisch bei CAD-Software).

### 1. Ordner ansehen

Den Ordner auflisten, den der User meint (meist frisch angelegt, ein Installer
drin). Prüfen: MSI oder EXE, wie groß, liegen mehrere Dateien da (Setup +
Sprachpakete + Redist), gibt es schon `App\`/`Pack.cmd` aus einem früheren Lauf.

### 2. Installer analysieren, statt Schalter zu raten

Das ist der Teil, der Denkarbeit braucht – der Rest ist Mechanik. Vollständige
Kommandos und Beispiele in `${CLAUDE_SKILL_DIR}/references/installer-analyse.md`.

Kurzfassung:

- `file <installer>` → PE32 / PE32+ (32- oder 64-Bit).
- `strings -n 5 <exe> | grep -Ei "nullsoft|inno setup|installshield|WiX|RunProgram="`
  → Setup-Typ. `RunProgram="setup.exe"` bedeutet **7-Zip-SFX**: das eigentliche
  Setup steckt darin, mit `7z x` entpacken und *dieses* analysieren. Ein anderer
  Wert (`RunProgram="db-bootstrap.exe"` o. ä.) bedeutet **Downloader** – dann
  liegt das Produkt in einem inneren Archiv, siehe Schritt 4.
- `strings -e l <setup.exe> | grep -E "^/[a-z]"` → die tatsächlich
  unterstützten Schalter, direkt aus dem Binary (UTF-16, deshalb `-e l`).
- Bei Wrappern zusätzlich nach `.ini`/`.xml`/`.json` im entpackten Archiv sehen
  – dort stehen Produktname, Version und Standard-Zielordner im Klartext.
- Bei .NET-EXEs die Bitness über den CorFlags-Wert bestimmen, wenn eine
  Abhängigkeit registry-basiert gesucht wird (AnyCPU läuft auf x64 als
  64-Bit-Prozess und sieht `WOW6432Node` **nicht** – dann muss die
  Abhängigkeit ebenfalls 64-Bit installiert werden).

Wenn es trotz Analyse unsicher bleibt: den plausibelsten Wert eintragen und im
Skript als `TODO pruefen` markiert lassen, damit der User es auf einem
Testgerät verifiziert. Erkennungsmuster für `detect-*.ps1` zu eng → Rollout
meldet `0x87D1041C`, zu weit → alte Versionen gelten als installiert. Den
echten Anzeigenamen bestätigt der User nach dem ersten Testgerät.

### 3. Gerüst erzeugen

Modus wählen:

| Modus | Wann | Vorlage |
|---|---|---|
| `msi` | reines MSI ohne Sonderparameter – Pack.cmd packt die MSI direkt, Intune füllt Befehle und Erkennung beim Upload selbst aus | – |
| `exe` | EXE-Setup mit Silent-Schalter | `install-exe.ps1.tmpl` |
| `msi-wrapper` | MSI mit Properties/Transforms | `install-msi.ps1.tmpl` |
| `copy` | portable EXE ohne Setup – nach `Program Files` kopieren + Startmenü-Verknüpfung | `install-copy.ps1.tmpl`, `uninstall-copy.ps1.tmpl` |

Die Mechanik erledigt das Helferskript (liest `intune-paket.json` selbst, falls
vorhanden):

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/new_package.py" "<Paketordner>" \
  --mode auto --name <Paketname> --display-name "<Produkt>*<Version>*" \
  --silent-args "'/S'" --util-search "<Wurzel der Intune-Apps>"
```

Fällt das Skript aus (kein `python3`, oder ein Sonderfall den `--mode` nicht
abdeckt), dieselben vier Schritte von Hand:

1. `mkdir -p "<Ordner>/App" "<Ordner>/Output"` und den Installer nach `App/`
   verschieben. Klammern/Leerzeichen im Dateinamen dabei entfernen
   (`Setup(Channel-1)_V10.3.exe` → `Setup_V10.3.exe`), die machen in cmd und
   PowerShell nur Ärger.
2. `IntuneWinAppUtil.exe` in den Ordner kopieren – eine vorhandene Kopie aus
   einem Nachbarpaket suchen (`find <Wurzel> -name IntuneWinAppUtil.exe`).
   Findet sich keine: beim User anfragen bzw. von
   github.com/microsoft/Microsoft-Win32-Content-Prep-Tool holen.
3. Die Vorlagen aus `${CLAUDE_SKILL_DIR}/assets/` lesen, die
   `{{...}}`-Platzhalter ersetzen und die Dateien schreiben. Platzhalter:
   `PKGNAME`, `SETUPFILE`, `DISPLAYNAME`, `SILENTARGS` (PowerShell-Argumentliste,
   z. B. `'/S','/norestart'`), `UNINSTALLARGS`, `LOGDIR`, bei `copy` zusätzlich
   `TARGETFOLDER`, `EXEFILE`, `PAYLOAD`, `PROCESSNAME`.
   In `Pack.cmd` ist `-s` die Datei, die Intune startet: bei Wrapper-Paketen
   `install.ps1`, bei reinem MSI der MSI-Dateiname.
4. Zeilenenden auf CRLF setzen, sonst stolpern cmd und PowerShell.

**Schreibweg beachten:** `sed`- und Shell-Heredocs fressen Backslashes –
`App\Image\Setup.exe` wird still zu `App\ImageSetup.exe` und der Fehler fällt
erst beim Packen auf. Deshalb Skriptdateien mit einem `python3`-Heredoc und
`r'''...'''`-Rohstrings schreiben und dort direkt `\r\n` erzeugen:

```bash
python3 - <<'PYEOF'
def wps1(p, t): open(p,'wb').write(b'\xef\xbb\xbf' + t.replace('\n','\r\n').encode('utf-8'))
def wcmd(p, t): open(p,'wb').write(t.replace('\n','\r\n').encode('cp1252'))
wps1('App/install.ps1', r'''...''')
PYEOF
```

`.ps1` als UTF-8 **mit BOM** (sonst zerlegt PowerShell Umlaute), `.cmd` als
CP1252. Nach dem Schreiben einmal `grep` auf einen Pfad mit Backslash, um den
Verlust auszuschließen.

Vorhandene Dateien aus einem früheren Lauf nicht kommentarlos überschreiben –
erst ansehen, ob dort schon angepasste Logik drinsteht.

### 4. Vorbereitungsschritt, wenn die Quelle erst erzeugt werden muss

Manche Hersteller liefern keinen fertigen Offline-Installer, sondern einen
Download-Bootstrapper oder ein Selbstentpacker-Archiv. Dafür ein
`01_Image-erzeugen.cmd` bzw. `01_Image-entpacken.cmd` in die **Paketwurzel**
legen (Vorlage `${CLAUDE_SKILL_DIR}/assets/prepare.cmd.tmpl`). Regeln:

- **Mehrere Wege nacheinander probieren**, nicht auf ein Werkzeug verlassen:
  erst der herstellereigene Schalter (z. B. `-suppresslaunch -d <Ziel>`), dann
  7-Zip, zuletzt eine verständliche Fehlermeldung mit Handlungsanweisung.
- **Auf verschachtelte Archive prüfen.** Es gibt Downloader, die entpackt nur
  Hilfsprogramme plus **ein inneres Archiv** enthalten – erst darin liegt das
  Setup. Einstufig entpacken und dann auf `Setup.exe` prüfen ergibt
  „Everything is Ok" **und** trotzdem einen Fehlschlag. Also: nach `*.7z`/`*.zip`
  im Ergebnis suchen und eine zweite Stufe anhängen. Begleitdateien wie
  `*.json` nennen häufig Name, Größe und Prüfsumme des inneren Archivs.
- **Ergebnis verifizieren**, nicht dem Exitcode glauben: prüfen, ob die
  erwartete Datei (`Setup.exe`) wirklich da ist.
- **Verschachtelte Ordner normalisieren**: viele Archive entpacken in einen
  Unterordner. Per `dir /b /s` die `Setup.exe` suchen und deren Ordnerinhalt
  mit `robocopy "<gefunden>." "<Ziel>" /E /MOVE` hochziehen.
- **Alten Stand vorher löschen** (`rd /s /q`), sonst mischen sich zwei
  Entpackläufe und die Prüfung wird wertlos.
- **Platzbedarf ansagen**: Quelldatei + Zwischenstand + Ergebnis. Bei einem
  2-GB-Produkt sind das rund 7 GB.
- **Alles nach `extract.log` protokollieren.** Fehlt die Logdatei hinterher
  komplett, ist das Skript schon vorher ausgestiegen – das ist die wichtigste
  Diagnoseinformation.
- Im Skript ansagen, was passiert: ein `-q`-Bootstrapper öffnet **kein
  Fenster** und lädt still 20–60 Minuten. Ohne Hinweis hält der User das für
  einen Fehlschlag und bricht ab.

**Alternative bei mehreren GB: `$NetworkImage`.** Statt das Image in `App\` zu
packen, bleibt es auf einer Freigabe und `install.ps1` startet es von dort
(Basis-Pfad aus `networkImageRoot` in `intune-paket.json`):

```powershell
$NetworkImage = '\\SERVER\Freigabe\Programm'   # leer = nur lokales App\Image
$local = Join-Path $PSScriptRoot 'Image\Setup.exe'
if (Test-Path $local) { $setup = $local }
elseif ($NetworkImage -and (Test-Path (Join-Path $NetworkImage 'Setup.exe'))) {
    $setup = Join-Path $NetworkImage 'Setup.exe'
} else { Log 'FEHLER: weder App\Image\Setup.exe noch $NetworkImage gefunden.'; exit 1 }
```

Das hält die `.intunewin` bei wenigen KB, setzt aber voraus, dass das
Systemkonto des Clients die Freigabe erreicht (Computerkonto berechtigen).

### 5. Skripte anpassen

Die Templates sind ein Startpunkt, kein Endzustand. Danach durchgehen und an
das konkrete Programm anpassen, typischerweise:

- laufende Prozesse vor der Installation beenden (`Stop-Process`), wenn das
  Setup sonst blockiert
- Altversionen vorher deinstallieren, wenn der Hersteller das verlangt
- Zusatzschritte: Lizenz-/Konfigdateien kopieren, Profile anlegen,
  Desktop-Verknüpfung auf den Public Desktop
- Exitcodes: 3010 als Erfolg behandeln (macht das Template schon)
- nach der Installation **gegenprüfen**, ob der erwartete Registry-Eintrag
  entstanden ist, und das ins Log schreiben – das erspart später die Suche
  nach dem richtigen Detect-Muster

**Abhängigkeiten: fail fast.** Wenn ein Programm eine Voraussetzung braucht
(.NET 3.5, ein Redist, eine Fremdkomponente), gehört sie mit ins Paket und wird
vor dem Hauptprogramm installiert. Schlägt das fehl, mit `exit 1` abbrechen
statt weiterzumachen – eine halbe Installation, die als Erfolg gemeldet wird,
ist schlimmer als ein sichtbarer Fehlschlag. Windows-Features über
`Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart`.
Das Detect-Skript prüft dann **beides** (Hauptprogramm *und* Abhängigkeit),
sonst gilt ein Gerät als fertig, auf dem das Programm nicht startet.

Alle Skripte loggen nach `<logDir>\<Paket>-*.log` (Standard
`C:\ProgramData\Intune-Logs`, überschreibbar in `intune-paket.json`). Ein
einheitlicher Pfad ist die erste Anlaufstelle, wenn ein Rollout scheitert –
diese Konvention innerhalb einer Umgebung nicht mischen.

### 6. Packen und prüfen

`Pack.cmd` doppelklicken lassen oder selbst starten. Danach **immer**
verifizieren:

- liegt in `Output\` eine `.intunewin` und ist sie ungefähr so groß wie die
  Quellen? Eine Datei von wenigen hundert Byte ist kaputt.
- endet `pack.log` mit `Done!!!`?

Hintergrund: `IntuneWinAppUtil.exe` hat einen Bug in der Fortschrittsanzeige
und stürzt in manchen Konsolen mit `Console.MoveBufferArea` ab, meldet aber
trotzdem Erfolg. Deshalb leitet `Pack.cmd` die Ausgabe nach `pack.log` um und
prüft anschließend, ob wirklich eine `.intunewin` entstanden ist.

`Pack.cmd` prüft außerdem vorab, ob die erwartete Quelldatei in `App\` liegt –
bei Paketen mit Vorbereitungsschritt auf `App\Image\Setup.exe` statt auf den
Bootstrapper prüfen.

### 7. Intune-Werte nennen

Zum Schluss dem User die Felder für den Assistenten geben – vollständig und
copy-paste-fertig, nicht als Prosa: Name, Version, Hersteller,
Installations- und Deinstallationsbefehl, Installationsverhalten, Anforderungen,
Erkennungsregel mit dem Pfad zum Detect-Skript, Rückgabecodes, Zuweisungsgruppe
nach `assignment.groupPattern`. Werte und Fallstricke stehen in
`${CLAUDE_SKILL_DIR}/references/intune-portal.md`; die Datei lesen, statt die
Werte aus dem Gedächtnis zu rekonstruieren.

Zuweisungen, Gruppen und Richtlinien werden **nicht** selbst angelegt, sondern
nur benannt – Schreibzugriffe auf Intune, Entra ID oder AD gehören in eine
eigene, ausdrücklich freigegebene Aktion.

## Dokumentation nachziehen

Liegt im Wurzelordner der Intune-Apps die in `docFile` genannte Datei
(Standard `CLAUDE.md`), das neue Paket dort in die Ordnertabelle eintragen und
die Besonderheiten ergänzen: Silent-Weg **mit Begründung, woher er stammt**
(„aus der EXE ausgelesen" / „laut Herstellerdoku" / „geraten, noch zu testen"),
Lizenzlage, Abhängigkeiten, Bezugsquelle des Installers, Standard-Zielordner.
Eine zentrale Datei genügt – keine READMEs in die einzelnen Paketordner legen.

Keine Kennwörter, Zugangsdaten oder sicherheitskritischen Interna in diese
Doku – sie wird typischerweise mitgesichert und weitergegeben.

## Fehlerbilder

| Symptom | Ursache / Vorgehen |
|---|---|
| `.intunewin` nur wenige hundert Byte | IntuneWinAppUtil-Absturz, `pack.log` lesen, neu packen |
| Rollout `0x87D1041C` | Detect-Muster passt nicht oder Installation lief ins Leere – erst `<logDir>` prüfen, dann den Registry-Anzeigenamen abgleichen |
| Installation läuft ewig / Timeout | Setup nicht wirklich silent, falscher Schalter |
| Exitcode 1603 | Setup braucht Voraussetzung (Redist, .NET) oder Konflikt mit vorhandener Version |
| Gerät gilt als installiert, Programm startet nicht | Detect prüft nur das Hauptprogramm, nicht die Abhängigkeit |
| `.intunewin` doppelt so groß wie erwartet | Quell-Bootstrapper liegt zusätzlich zum Image in `App\` – gehört in die Paketwurzel |
| Vorbereitungsskript „lief durch", `App\Image\` ist leer | Werkzeug fehlte (7-Zip nicht installiert); es gibt kein `extract.log`, weil das Skript vorher ausgestiegen ist – Skript mit Fallback-Weg und durchgängigem Logging neu schreiben |
| Entpacker meldet „Everything is Ok", Skript trotzdem FEHLGESCHLAGEN | inneres Archiv – zweite Entpackstufe fehlt, siehe Schritt 4 |
| Ordner sieht leer aus, obwohl entpackt wurde | Sync-Client (OneDrive, Dropbox o. ä.) hat den Ordner noch nicht hochgeladen bzw. legt leere Ordner nicht an – mit `du -sh` gegenprüfen |
| `App\ImageSetup.exe` statt `App\Image\Setup.exe` | Backslash beim Schreiben per `sed`/Heredoc verschluckt – siehe Schritt 3 |
| Detect meldet immer „installiert" | Detect-Skript gibt auch im Negativfall etwas aus (`Write-Host`, Fehlermeldung). Bei „nicht installiert" **nichts** ausgeben, nur `exit 1` |

## Aufräumen

Lässt sich am Zielort nicht löschen, nicht mehr benötigte Dateien nach
`<trashFolder>` (Standard `_to_delete\`) im Wurzelordner verschieben und dem
User sagen, was dort liegt – er löscht es selbst.

Nach erfolgreichem Rollout können auch die Beschaffungsdateien in der
Paketwurzel (Bootstrapper, SFX-Archiv) dorthin – das Image in `App\` reicht
zum Nachbauen. Vorher fragen: bei manchen Herstellern ist der Download später
nicht mehr in derselben Version verfügbar.

# Changelog

Was sich an den Plugins ändert, aus Sicht dessen, der sie benutzt. Jedes Plugin wird nach [Semantic Versioning](https://semver.org/lang/de/) versioniert; ältere Einträge stehen in der Git-Historie.

## Marketplace

### 2026-09-01

Alle vier Plugins lassen sich zusätzlich über denselben Repo-Marketplace in ChatGPT und Codex installieren. Die Skills verwenden portable Bundle-Pfade; OpenAI-spezifische Aktivierungsregeln liegen in `agents/openai.yaml`, andere Clients werden durch enge Beschreibungen und Inhalts-Gates begrenzt.

### 2026-08-28

`handoff` und `bruh` sind in **`kram`** aufgegangen, dem Plugin für die kleinen Alltagsbefehle. Neu dabei: `/kram:kleinanzeigen`. Die baren Befehle `/handoff` und `/bruh` funktionieren unverändert.

**Einmalig auf jedem Gerät** — erst deinstallieren, sonst streiten sich die alten und die neuen Plugins um `/handoff` und `/bruh`:

```
claude plugin uninstall handoff bruh
/plugin install kram@labi
```

### 2026-08-19

Die Befehle sind nach Anlass gruppiert. Statt acht einzelner Plugins gibt es fünf: `code`, `setup`, `windows`, `handoff` und `bruh`. Jeder Skill ist weiterhin auch bar erreichbar — `/ship` funktioniert wie `/code:ship`.

**Einmalig auf jedem Gerät:**

```
claude plugin uninstall agent-docs cleanup windev claudex intune-win32
/plugin install code@labi
/plugin install setup@labi
/plugin install windows@labi
/plugin install bruh@labi
```

`handoff` bleibt unverändert installiert.

## labidesign-email

### [1.0.0] – 2026-09-15

Neu: Emil Kowalskis zwölf Skills für Animation und UI-Design als eigenes Plugin, eins zu eins aus [emilkowalski/skills](https://github.com/emilkowalski/skills) übernommen (MIT). `review-animations`, `pick-ui-library` und `prototype` laufen nur auf ausdrücklichen Aufruf.

```
/plugin install labidesign-email@labi
```

## labidesign-ui

### [1.0.0] – 2026-09-15

Neu: Jakub Krehels elf Skills für Produkt-Interfaces als eigenes Plugin, eins zu eins aus [jakubkrehel/skills](https://github.com/jakubkrehel/skills) übernommen (MIT). `interface-review`, `explain-interface`, `break` und `variant` laufen nur auf ausdrücklichen Aufruf.

```
/plugin install labidesign-ui@labi
```

## code

### [1.2.1] – 2026-09-18

#### Entfernt

- **Erinnerung nach dem Compact.** Der Plugin-Hook ist weg; der Doku-Sync wird wie bisher per `agent-docs` angestoßen.

### [1.2.0] – 2026-09-18

#### Hinzugefügt

- **`agent-docs` läuft in einem eigenen Subagenten.** Der Sync-Agent `agent-docs-sync` erbt das Modell des Hauptthreads und lässt die Discovery von kleinen, schnellen Explore-Kindern erledigen. Ein erneuter Aufruf setzt den bestehenden Agenten fort und liefert nur, was seit dem letzten Lauf neu ist.
- **Erinnerung nach jedem Compact.** Ein Plugin-Hook weist nach der Kontextkomprimierung auf den ausstehenden Doku-Sync hin, sobald der Working Tree Änderungen enthält. Er ruft nichts auf und schreibt nichts.

#### Geändert

- **`rewrite-prune` tauscht nur noch das stale Token.** Eine Korrektur, die die Zeile verlängert oder neue Mechanik erklärt, gilt als Add und muss durchs Add-Gate; `needs verification` blockiert jetzt auch Rewrites.
- **Init-Vorschläge bleiben einsprachig.** Überschriften folgen der Sprache der Repo-Doku, Command-Zeilen nennen nur die Falle, nicht die Script-Interna.

### [1.1.0] – 2026-09-01

#### Behoben

- **`agent-docs` lädt weniger redundante Regeln.** Das asymmetrische Gate, Inhaltsausschlüsse und Prune-Pflichten bleiben an ihrer kanonischen Stelle erhalten, werden aber nicht mehr in den immer gemeinsam geladenen Dateien wiederholt.
- **`ship` ist nicht mehr von einer persönlichen Claude-Code-Datei abhängig.** Commit- und PR-Format stehen vollständig im Skill und erzeugen keine falschen harness-spezifischen Provenienzangaben mehr.

#### Geändert

- **Die Code-Skills sind client-neutral aufrufbar.** Manuell gedachte Workflows bleiben in ChatGPT und Codex explizit; Fragen, Parallelisierung und Forge-Zugriff haben portable Fallbacks.

### [1.0.1] – 2026-08-19

#### Behoben

- **`/code:ship --clean` räumte squash-gemergte Branches nicht auf.** `git branch --merged` führt sie nach einem Squash nicht, weil der Branch-Head unerreichbar bleibt; ship fragt jetzt zusätzlich den PR-Status ab.
- **`/code:ship` blieb in Worktrees nach dem Merge hängen**, wenn der Default-Branch bereits im Hauptrepo ausgecheckt war. Es wechselt dort nicht mehr den Branch.
- Der Beispielblock in `/code:agent-docs` nannte noch den alten Befehl `/agent-docs`.

### [1.0.0] – 2026-08-19

Bündelt die Arbeit am Code: `/code:planning`, `/code:cleanup`, `/code:agent-docs` und `/code:ship`.

#### Hinzugefügt

- **`/code:planning`** — plant ein Vorhaben durch, bevor etwas geschrieben wird. Fragerunde über das Frage-Tool, bis nichts mehr offen ist, dann ein nummerierter Plan zum einzelnen Abnicken. Umgesetzt wird erst nach dem Go, danach ohne Zwischenfragen.
- **`/code:ship`** — committen und PR öffnen. `--merge` mergt zusätzlich und wechselt zurück auf den Default-Branch, `--clean` räumt gemergte Branches und verwaiste Worktrees auf. Allein aufgerufen räumt `--clean` nur auf. Bei öffentlichen Repos prüft ship den Diff vorab auf Secrets und interne Daten.

#### Geändert

- **`/cleanup` heißt `/code:cleanup`**, **`/agent-docs` heißt `/code:agent-docs`**. Argumente und Verhalten bleiben.
- **`/code:agent-docs` pflegt jetzt auch Changelog-Dateien.** Ein Changelog ist für Endnutzer geschrieben: was neu, geändert oder entfernt ist. Keine Migrations- oder Baugeschichte, keine Verifikationsblöcke. Bei mehreren Changelogs im Monorepo nur der zum geänderten Bereich.

## setup

### [2.1.0] – 2026-09-06

#### Hinzugefügt

- **`cloud` bereitet Repos für Cloud-Agenten vor.** Ohne Argumente analysiert der Skill Setups, Editor-Konfigurationen und CI. Mit `--fix` führt er alles auf einen Installer unter `.github/scripts` zusammen und prüft das Ergebnis; Commit und Push bleiben beim Nutzer. Zielbild, belegte Client-Verträge (Amp, Cursor, Codex, Claude Cloud, Devcontainer, Copilot) und eine Skriptvorlage liegen als Referenz bei.

### [2.0.0] – 2026-09-01

#### Hinzugefügt

- **`devdrive`** — vermisst und plant ein Windows Dev Drive read-only. Mit `--fix` stimmt der Skill VHDX oder Partition sowie jeden Cache- und Repo-Umzug einzeln ab, legt das trusted ReFS-Volume über UAC an und prüft den Zustand auch nach dem Neustart.

#### Geändert

- **`windev` hat nur noch das optionale Argument `--best-practice`.** Ohne Argument führt der Skill interaktiv durch Befund und gewählte Änderungen; mit dem Flag stellt er belegte reversible Standards direkt her und fragt nur persönliche oder riskante Entscheidungen.
- **PowerShell 7 wird für erhöhte Setup-Schritte als systemweites WIX-Paket installiert.** `devdrive` prüft Trust und Mount-Task anschließend über denselben abgesicherten UAC-Wrapper.
- **`labi-defaults` heißt jetzt `cc-defaults`.** Der neue Name ist in allen Clients verbindlich; Codex-, Claude-Code- und andere globale Anweisungsdateien werden erkannt oder einmal ausgewählt.

### [1.0.1] – 2026-08-19

#### Behoben

- Der Zielzustand von `/setup:windev` nannte noch den alten Befehl `/windev`.

### [1.0.0] – 2026-08-19

Bündelt die Einrichtung: `/setup:windev`, `/setup:claudex` und `/setup:labi-defaults`.

#### Hinzugefügt

- **`/setup:labi-defaults`** — analysiert die globale `CLAUDE.md` und schärft sie gemeinsam mit dir. Zeigt erst den Befund, fragt dann über das Frage-Tool durch, schreibt erst danach und nur das Zugestimmte. `settings.json` und Hooks werden gelesen und gemeldet, aber nie geändert.

#### Geändert

- **`/windev` heißt `/setup:windev`**, **`/claudex` heißt `/setup:claudex`**. Argumente und Verhalten bleiben.

## windows

### [1.1.0] – 2026-09-01

#### Geändert

- **Die Windows-Skills verwenden portable Bundle-Pfade und Aktivierungsregeln.** Sie funktionieren damit aus ChatGPT, Codex, Claude Code und kompatiblen Agent-Skills-Clients heraus.
- **`intune-win32` nimmt keine Agent-Dokumentationsdatei mehr an.** `docFile` ist standardmäßig deaktiviert und wird nur nach erkannter Repo-Konvention oder expliziter Auswahl gesetzt.

### [1.0.0] – 2026-08-19

Bündelt die Windows-Werkzeuge: `/windows:intune-win32` und `/windows:irm-skript`.

#### Hinzugefügt

- **`/windows:irm-skript`** — erzeugt ein self-contained PowerShell-Tool im labi.dev-Hausstil, aufrufbar per `irm labi.dev/route | iex`: interaktive Oberfläche mit Status-Badges, tastengesteuertem Menü, mehrseitiger Hilfe und Headless-Fallback.

#### Geändert

- **`/intune-win32` heißt `/windows:intune-win32`.** Verhalten bleibt.

## kram

### [1.1.0] – 2026-09-01

#### Geändert

- **`handoff` und `bruh` sind client-neutral verpackt.** Beide bleiben in ChatGPT und Codex explizit aufzurufen; die inhaltlichen Grenzen stehen direkt im Skill statt in herstellerspezifischen Tool-Sperren.

### [1.0.0] – 2026-08-28

Bündelt die kleinen Alltagsbefehle: `/kram:handoff`, `/kram:bruh` und `/kram:kleinanzeigen`.

#### Hinzugefügt

- **`/kram:kleinanzeigen`** — recherchiert den realistischen Gebrauchtpreis eines Artikels und schreibt die fertige Verkaufsanzeige: Titel, Preisempfehlung mit Marktspanne, Beschreibung zum Kopieren mit Gewährleistungsausschluss. Grundlage sind tatsächlich erzielte Verkaufspreise, nicht die Forderungen in laufenden Inseraten.

#### Geändert

- **`/handoff` heißt `/kram:handoff`**, **`/bruh` heißt `/kram:bruh`**. Verhalten bleibt, die baren Befehle ebenfalls.

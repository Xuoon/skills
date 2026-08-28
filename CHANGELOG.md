# Changelog

Was sich an den Plugins ändert, aus Sicht dessen, der sie benutzt. Jedes Plugin wird nach [Semantic Versioning](https://semver.org/lang/de/) versioniert; ältere Einträge stehen in der Git-Historie.

## Marketplace

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

## code

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

### [1.0.0] – 2026-08-19

Bündelt die Windows-Werkzeuge: `/windows:intune-win32` und `/windows:irm-skript`.

#### Hinzugefügt

- **`/windows:irm-skript`** — erzeugt ein self-contained PowerShell-Tool im labi.dev-Hausstil, aufrufbar per `irm labi.dev/route | iex`: interaktive Oberfläche mit Status-Badges, tastengesteuertem Menü, mehrseitiger Hilfe und Headless-Fallback.

#### Geändert

- **`/intune-win32` heißt `/windows:intune-win32`.** Verhalten bleibt.


## kram

### [1.0.0] – 2026-08-28

Bündelt die kleinen Alltagsbefehle: `/kram:handoff`, `/kram:bruh` und `/kram:kleinanzeigen`.

#### Hinzugefügt

- **`/kram:kleinanzeigen`** — recherchiert den realistischen Gebrauchtpreis eines Artikels und schreibt die fertige Verkaufsanzeige: Titel, Preisempfehlung mit Marktspanne, Beschreibung zum Kopieren mit Gewährleistungsausschluss. Grundlage sind tatsächlich erzielte Verkaufspreise, nicht die Forderungen in laufenden Inseraten.

#### Geändert

- **`/handoff` heißt `/kram:handoff`**, **`/bruh` heißt `/kram:bruh`**. Verhalten bleibt, die baren Befehle ebenfalls.

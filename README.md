```text
 _       _     _
| | __ _| |__ (_)
| |/ _` | '_ \| |
| | (_| | |_) | |
|_|\__,_|_.__/|_|
```

Persönlicher Plugin-Marketplace für [Claude Code](https://code.claude.com/docs/en/plugins). Philosophie: Evidenz statt Vermutung, Vorschlag vor Edit, löschen bevorzugt, knapper Output.

Fünf Plugins, gruppiert nach Anlass. Mutierende Skills analysieren nur — geschrieben wird erst mit `--fix`.

## code — Arbeit am Code

| Befehl | Argumente | Verhalten |
| --- | --- | --- |
| `/code:planning` | freier Text | Vorhaben durchplanen, bevor etwas geschrieben wird: Fragerunde bis nichts mehr offen ist, dann Plan, dann Umsetzung nach dem Go |
| `/code:cleanup` | `--skills` · `--fix` | Toten Code und verwaiste Dateien finden, mit `--skills` stattdessen repo-lokale Skills. `--fix` beweist jede Löschung erst in einer Wegwerf-Kopie |
| `/code:agent-docs` | `--audit` · `--fix` | Agent-Doku und Changelog am Code halten. Standard = Diff-Sync als Vorschlag, `--audit` = voller Report mit Scoring |
| `/code:ship` | `--merge` · `--clean` | Committen und PR öffnen. `--merge` mergt zusätzlich, `--clean` räumt Branches und Worktrees auf — allein aufgerufen räumt es nur auf |

## setup — Umgebung einrichten

| Befehl | Argumente | Verhalten |
| --- | --- | --- |
| `/setup:windev` | `--fix` · `--setup` | Windows-Umgebung vermessen (read-only), `--fix` behebt die Befunde mit Backups, `--setup` richtet nach Best Practice ein |
| `/setup:claudex` | – | Claude Code auf macOS mit GPT über CLIProxyAPI einrichten, aktualisieren, reparieren oder entfernen |
| `/setup:labi-defaults` | – | Globale `CLAUDE.md` analysieren und gemeinsam schärfen — Befund, Fragerunde, dann erst schreiben |

## windows — Windows-Werkzeuge

| Befehl | Argumente | Verhalten |
| --- | --- | --- |
| `/windows:intune-win32` | freier Text | Intune-Win32-Paket aus MSI/EXE bauen oder einen fehlgeschlagenen Rollout eingrenzen — was gemeint ist, steht im Text |
| `/windows:irm-skript` | freier Text | Gehostetes PowerShell-Tool im labi.dev-Hausstil erzeugen, aufrufbar per `irm labi.dev/route \| iex` |

## Einzelne Befehle

| Befehl | Argumente | Verhalten |
| --- | --- | --- |
| `/handoff` | freier Text | Session in ein Übergabe-Dokument destillieren, mit dem ein anderer Agent direkt weiterarbeitet — die letzte Antwort ist das Dokument selbst |
| `/bruh` | – | Die letzte Antwort in einfacher Sprache neu erklären. Keine neuen Informationen, Pfade und Befehle bleiben wörtlich |

Jeder Skill ist zusätzlich bar erreichbar: `/ship` funktioniert genauso wie `/code:ship` — solange kein anderer Befehl denselben Namen belegt. `bun run validate` hält die Namen in diesem Katalog eindeutig; gegen eingebaute Befehle oder Skills aus anderen Quellen kann es das nicht prüfen.

## Installation

```
/plugin marketplace add Xuoon/skills
/plugin install code@labi
/plugin install setup@labi
/plugin install windows@labi
/plugin install handoff@labi
/plugin install bruh@labi
```

Updates kommen über `/plugin update` (bzw. Auto-Update), gesteuert über das `version`-Feld der jeweiligen `plugin.json`.

## Aufbau

Die Plugins folgen [Agent Plugins 1.0.0](https://agent-plugins.org/):

```
plugins/<plugin>/
├── plugin.json                  # Agent-Plugins-Standard
├── .claude-plugin/plugin.json   # Claude Code
└── skills/<skill>/SKILL.md      # plus references/, scripts/, assets/
```

Zwei Manifeste, weil Claude Code ausschließlich `.claude-plugin/plugin.json` liest und der Standard ausschließlich das im Plugin-Root. Beide tragen denselben Namen, dieselbe Version und dieselbe Beschreibung.

## Entwicklung

```
bun run fix        # JSON/Markdown formatieren
bun run validate   # Marktplatz-Invarianten prüfen
```

`bun run validate` prüft, was sonst still bricht: beide Manifeste gegeneinander, Ordnername gegen `plugin.json`, Katalog-Vollständigkeit, `name:` in jeder `SKILL.md`, Pfade die aus dem Skill herauszeigen, und Skillnamen die sich den baren Befehl streitig machen. In der CI läuft zusätzlich das Release-Gate — geänderte Plugins brauchen einen Versions-Bump und einen Eintrag in der [CHANGELOG.md](CHANGELOG.md).

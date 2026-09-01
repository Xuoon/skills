```text
 _       _     _
| | __ _| |__ (_)
| |/ _` | '_ \| |
| | (_| | |_) | |
|_|\__,_|_.__/|_|
```

Persönlicher Plugin-Marketplace für [ChatGPT und Codex](https://developers.openai.com/plugins/concepts/plugins), [Claude Code](https://code.claude.com/docs/en/plugins) und Clients des [Agent-Plugins-Standards](https://agent-plugins.org/). Philosophie: Evidenz statt Vermutung, Vorschlag vor Edit, löschen bevorzugt, knapper Output.

Vier Plugins, gruppiert nach Anlass. Mutationen brauchen immer ein dokumentiertes Flag oder eine konkrete Auswahl im laufenden Dialog.

## code — Arbeit am Code

| Skill | Argumente | Verhalten |
| --- | --- | --- |
| `planning` | freier Text | Vorhaben durchplanen, bevor etwas geschrieben wird: Fragerunde bis nichts mehr offen ist, dann Plan, dann Umsetzung nach dem Go |
| `cleanup` | `--skills` · `--fix` | Toten Code und verwaiste Dateien finden, mit `--skills` stattdessen repo-lokale Skills. `--fix` beweist jede Löschung erst in einer Wegwerf-Kopie |
| `agent-docs` | `--audit` · `--fix` | Agent-Doku und Changelog am Code halten. Standard = Diff-Sync als Vorschlag, `--audit` = voller Report mit Scoring |
| `ship` | `--merge` · `--clean` | Committen und PR öffnen. `--merge` mergt zusätzlich, `--clean` räumt Branches und Worktrees auf — allein aufgerufen räumt es nur auf |

## setup — Umgebung einrichten

| Skill | Argumente | Verhalten |
| --- | --- | --- |
| `windev` | `--best-practice` | Ohne Argument interaktiv einrichten; mit Flag belegte Standards direkt herstellen und nur echte Entscheidungen fragen |
| `devdrive` | `--fix` | Windows Dev Drive planen oder anlegen und ausgewählte Caches und Repos umziehen. Standard ist read-only |
| `claudex` | – | Claude Code auf macOS mit GPT über CLIProxyAPI einrichten, aktualisieren, reparieren oder entfernen |
| `cc-defaults` | – | Globale Anweisungsdatei des aktiven Agent-Clients analysieren und gemeinsam schärfen |

## windows — Windows-Werkzeuge

| Skill | Argumente | Verhalten |
| --- | --- | --- |
| `intune-win32` | freier Text | Intune-Win32-Paket aus MSI/EXE bauen oder einen fehlgeschlagenen Rollout eingrenzen — was gemeint ist, steht im Text |
| `irm-skript` | freier Text | Gehostetes PowerShell-Tool im labi.dev-Hausstil für den bewusst gewählten Aufruf `irm https://labi.dev/route \| iex` erzeugen |

## kram — Alltagsbefehle

| Skill | Argumente | Verhalten |
| --- | --- | --- |
| `handoff` | freier Text | Session in ein Übergabe-Dokument destillieren, mit dem ein anderer Agent direkt weiterarbeitet — die letzte Antwort ist das Dokument selbst |
| `bruh` | – | Die letzte Antwort in einfacher Sprache neu erklären. Keine neuen Informationen, Pfade und Befehle bleiben wörtlich |
| `kleinanzeigen` | freier Text | Gebrauchtpreis eines Artikels recherchieren und die fertige Verkaufsanzeige schreiben — Titel, Preisempfehlung mit Marktspanne, Beschreibung zum Kopieren |

Die Aufrufsyntax gehört zum Client: Codex verwendet `$skill-name`, Claude Code `/<plugin>:<skill>` beziehungsweise den baren Alias, ChatGPT kann Skills über das Plugin oder eine natürliche Anfrage aktivieren. `bun run validate` hält die Skillnamen in diesem Katalog eindeutig.

## Installation in Codex

```bash
codex plugin marketplace add Xuoon/skills
codex plugin add code@labi
codex plugin add setup@labi
codex plugin add windows@labi
codex plugin add kram@labi
```

## Installation in ChatGPT Work

Ein Workspace-Admin öffnet `Admin > Plugins`, wählt `Add > Import marketplace` und trägt als Source `https://github.com/Xuoon/skills` ein. Path bleibt leer, weil `.agents/plugins/marketplace.json` im Repo-Root liegt. Nach dem Import die Installation Policy der gewünschten Plugins festlegen; Updates werden täglich synchronisiert oder über `Sync now` angefordert.

Der Repo-Katalog liegt in `.agents/plugins/marketplace.json`. ChatGPT und Codex verwenden dieselben `.codex-plugin/plugin.json`-Manifeste.

## Installation in Claude Code

```
/plugin marketplace add Xuoon/skills
/plugin install code@labi
/plugin install setup@labi
/plugin install windows@labi
/plugin install kram@labi
```

Updates kommen über den jeweiligen Client, gesteuert durch die synchronen Versionsfelder der Plugin-Manifeste.

## Aufbau

Die Plugins folgen [Agent Plugins 1.0.0](https://agent-plugins.org/):

```
plugins/<plugin>/
├── plugin.json                  # Agent-Plugins-Standard
├── .codex-plugin/plugin.json    # ChatGPT und Codex
├── .claude-plugin/plugin.json   # Claude Code
└── skills/<skill>/SKILL.md      # plus references/, scripts/, assets/
```

Drei Manifeste verbinden die Clients mit demselben portablen Skillbestand. `name`, `version`, `description` und `author` bleiben synchron.

## Entwicklung

```
bun run fix        # JSON/Markdown formatieren
bun run validate   # Marktplatz-Invarianten prüfen
```

`bun run validate` prüft alle drei Manifeste, beide Marketplaces, portables Frontmatter, Bundle-Pfade, README-Vollständigkeit und eindeutige Skillnamen. In der CI läuft zusätzlich das Release-Gate — geänderte Plugins brauchen einen Versions-Bump und einen Eintrag in der [CHANGELOG.md](CHANGELOG.md).

```text
 _       _     _
| | __ _| |__ (_)
| |/ _` | '_ \| |
| | (_| | |_) | |
|_|\__,_|_.__/|_|
```

Persönlicher Plugin-Marketplace für [Claude Code](https://code.claude.com/docs/en/plugins) und [Codex](https://developers.openai.com/plugins/concepts/plugins). Philosophie: Evidenz statt Vermutung, Vorschlag vor Edit, löschen bevorzugt, knapper Output.

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
| `cloud` | `--fix` | Cloud-Agent-Setups, gemeinsame Repo-Skripte und CI analysieren; mit `--fix` lokal korrigieren, ohne Commit oder Push |
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

Die Aufrufsyntax gehört zum Client: Claude Code verwendet `/<plugin>:<skill>` beziehungsweise den baren Alias, Codex `$skill-name`. `bun run validate` hält die Skillnamen in diesem Katalog eindeutig.

## Installation in Codex

```bash
codex plugin marketplace add Xuoon/skills
codex plugin add code@labi
codex plugin add setup@labi
codex plugin add windows@labi
codex plugin add kram@labi
```

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

```
plugins/<plugin>/
├── .claude-plugin/plugin.json   # Claude Code
├── .codex-plugin/plugin.json    # Codex
└── skills/<skill>/SKILL.md      # plus references/, scripts/, assets/
```

`name`, `version`, `description` und `author` bleiben in beiden Manifesten gleich.

## Entwicklung

```
bun run fix        # JSON/Markdown formatieren
bun run validate   # Marktplatz-Invarianten prüfen
```

`bun run validate` prüft beide Manifeste, beide Marketplaces, portables Frontmatter, Bundle-Pfade, README-Vollständigkeit und eindeutige Skillnamen. In der CI läuft zusätzlich das Release-Gate — geänderte Plugins brauchen einen Versions-Bump und einen Eintrag in der [CHANGELOG.md](CHANGELOG.md).

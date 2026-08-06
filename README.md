```text
 _       _     _
| | __ _| |__ (_)
| |/ _` | '_ \| |
| | (_| | |_) | |
|_|\__,_|_.__/|_|
```

Persönlicher Plugin-Marketplace für [Claude Code](https://code.claude.com/docs/en/plugins). Philosophie: Evidenz statt Vermutung, Vorschlag vor Edit, löschen bevorzugt, concise Output.

Jedes Plugin hat genau einen Befehl. Ohne Argument wird nur analysiert und vorgeschlagen — geschrieben wird erst mit `--fix`.

| Befehl | Argumente | Verhalten |
| --- | --- | --- |
| `/agent-docs` | `--audit` · `--fix` | Agent-Doku am Code halten. Standard = Diff-Sync als Vorschlag, `--audit` = voller Report mit Scoring und Subagent-Fan-out |
| `/cleanup` | `--skills` · `--fix` | Toten/Legacy-Code und verwaiste Dateien finden, mit `--skills` stattdessen repo-lokale Skills. `--fix` beweist jede Löschung erst in einer Wegwerf-Kopie |
| `/windev` | `--fix` · `--setup` | Windows-Umgebung vermessen (read-only), `--fix` behebt die Befunde mit Backups, `--setup` richtet nach Best Practice ein |
| `/claudex` | – | Claude Code auf macOS mit GPT über CLIProxyAPI einrichten, aktualisieren, reparieren oder entfernen |
| `/intune-win32` | freier Text | Intune-Win32-Paket aus MSI/EXE bauen, oder einen fehlgeschlagenen Rollout eingrenzen — was gemeint ist, steht im Text |

## Installation

```
/plugin marketplace add Xuoon/skills
/plugin install agent-docs@labi
/plugin install cleanup@labi
/plugin install windev@labi
/plugin install claudex@labi
/plugin install intune-win32@labi
```

Updates kommen über `/plugin update` (bzw. Auto-Update), gesteuert über das `version`-Feld der jeweiligen `plugin.json`.

## Entwicklung

```
bun run fix        # JSON/Markdown formatieren
bun run validate   # Marktplatz-Invarianten prüfen
```

`bun run validate` prüft, was sonst still bricht: Ordnername gegen `plugin.json`, Katalog-Vollständigkeit, `name:` in jeder Root-`SKILL.md` und Pfade, die aus dem Plugin herauszeigen. In der CI läuft zusätzlich das Release-Gate — geänderte Plugins brauchen einen Versions-Bump und einen Changelog-Eintrag.

Alle Release-Notizen stehen gesammelt in der [CHANGELOG.md](CHANGELOG.md); jedes Plugin wird unabhängig nach SemVer versioniert.

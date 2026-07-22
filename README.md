```text
 _       _     _
| | __ _| |__ (_)
| |/ _` | '_ \| |
| | (_| | |_) | |
|_|\__,_|_.__/|_|
```

Persönlicher Plugin-Marketplace für [Claude Code](https://code.claude.com/docs/en/plugins). Philosophie: Evidenz statt Vermutung, Vorschlag vor Edit, löschen bevorzugt, concise Output.

| Plugin | Befehle / Verhalten |
| --- | --- |
| **agent-docs** | `/agent-docs:sync` · `:audit` — Agent-Doku aktualisieren oder prüfen; `sync` routet Init/Sync/Review automatisch |
| **cleanup** | `/cleanup:code` · `:skills` — toten/Legacy-Code + verwaiste Dateien entfernen; repo-lokale Skills sortieren (löschen/hochziehen/behalten) |
| **ship** | `/ship` — committen, PR auf main im Hausformat, optional direkt mergen; Public-Repo-Check vorab |
| **load-context** | Hooks: lädt repo-spezifische Doku (CLAUDE.md/AGENTS.md/Rules/AI-Instruktionen) bei Session-Start in den Kontext |
| **claudex-install** | `/claudex-install` — Claude Code auf macOS mit GPT über CLIProxyAPI einrichten |
| **btw-checkout** | `/btw-checkout` — Side-Chat-Ergebnis als kompakten Übergabe-Prompt für den Haupt-Chat ausgeben |
| **windev** | `/windev:setup` · `:optimize` — Windows-Dev-Umgebung einrichten (auch frisches Windows) bzw. vermessen und bereinigen; approval-gated |

## Installation

```
/plugin marketplace add Xuoon/skills
/plugin install agent-docs@labi
/plugin install cleanup@labi
/plugin install ship@labi
/plugin install load-context@labi
/plugin install claudex-install@labi
/plugin install btw-checkout@labi
/plugin install windev@labi
```

Updates kommen über `/plugin update` (bzw. Auto-Update), gesteuert über das `version`-Feld der jeweiligen `plugin.json`.

Alle Release-Notizen stehen gesammelt in der [CHANGELOG.md](CHANGELOG.md); jedes Plugin wird unabhängig nach SemVer versioniert.

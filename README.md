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
| **git-work** | `/git-work:commit` · `:changelog` · `:pr` — Commits, Changelogs und PRs im Haus-Stil |
| **deps** | `/deps:bump` · `:health` — Dependencies aktuell, sicher und sauber lizenziert (bun-first) |
| **notify** | Hooks: Desktop-Benachrichtigung, wenn Claude fertig ist oder Input braucht |
| **load-context** | Hooks: lädt repo-spezifische Doku (CLAUDE.md/AGENTS.md/Rules/AI-Instruktionen) bei Session-Start in den Kontext |
| **claudex-installer** | `/claudex-installer:install` — Claude Code auf macOS mit GPT über CLIProxyAPI einrichten |
| **btw-checkout** | `/btw-checkout` — Side-Chat-Ergebnis als kompakten Übergabe-Prompt für den Haupt-Chat ausgeben |

## Installation

```
/plugin marketplace add Xuoon/skills
/plugin install agent-docs@labi
/plugin install git-work@labi
/plugin install deps@labi
/plugin install notify@labi
/plugin install load-context@labi
/plugin install claudex-installer@labi
/plugin install btw-checkout@labi
```

Updates kommen über `/plugin update` (bzw. Auto-Update), gesteuert über das `version`-Feld der jeweiligen `plugin.json`.

Neues Plugin anlegen, testen, releasen: [CONTRIBUTING.md](CONTRIBUTING.md)

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
| **agent-docs** | `/agent-docs:sync` · `:audit` · `:init` — Agent-Doku mit der Code-Realität konsistent halten |
| **git-work** | `/git-work:commit` · `:changelog` · `:pr` — Commits, Changelogs und PRs im Haus-Stil |
| **deps** | `/deps:bump` · `:audit` — Dependencies aktuell, sicher und sauber lizenziert (bun-first) |
| **notify** | Hooks: Desktop-Benachrichtigung, wenn Claude fertig ist oder Input braucht |

## Installation

```
/plugin marketplace add Xuoon/skills
/plugin install agent-docs@labi
/plugin install git-work@labi
/plugin install deps@labi
/plugin install notify@labi
```

Updates kommen über `/plugin update` (bzw. Auto-Update), gesteuert über das `version`-Feld der jeweiligen `plugin.json`.

Neues Plugin anlegen, testen, releasen: [CONTRIBUTING.md](CONTRIBUTING.md)

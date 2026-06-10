# labi — Claude Code Plugins

Persönlicher Plugin-Marketplace für [Claude Code](https://code.claude.com/docs/en/plugins). Philosophie aller Plugins: **Evidenz statt Vermutung, Vorschlag vor Edit (Approval-Gates), löschen bevorzugt, concise Output.**

## Katalog

| Plugin | Befehle | Zweck | Status |
| --- | --- | --- | --- |
| **agent-docs** `1.0.0` | `/agent-docs:sync` `:audit` `:prune` `:init` | Agent-Doku (CLAUDE.md/AGENTS.md + Rules) mit der Code-Realität konsistent halten | stabil |
| **git-work** `0.1.0` | `/git-work:commit` `:changelog` | Logisch geschnittene Commits + concise Changelogs im Haus-Stil | neu |
| **deps** `0.1.0` | `/deps:bump` | Alle Dependencies aufs letzte offizielle stabile Release (bun-first) | neu |
| **dead-code** `0.1.0` | `/dead-code` | Toten Code finden, belegen, nach Freigabe löschen | neu |

Geplant (noch nicht gebaut): `deps:audit` (CVEs/EOL/Lizenzen), `compose-maintain` (Docker-Hygiene), `runbook` (Ops-Doku).

## Installation

Auf jedem Gerät einmalig in Claude Code:

```
/plugin marketplace add DEIN-GITHUB-USER/claude-plugins
/plugin install agent-docs@labi
/plugin install git-work@labi
/plugin install deps@labi
/plugin install dead-code@labi
```

Danach Claude Code neu starten. Updates kommen über `/plugin update` (bzw. Auto-Update), gesteuert über das `version`-Feld der jeweiligen `plugin.json`.

## Release-Konvention

Pro Plugin: Semver in `.claude-plugin/plugin.json` + Eintrag im `CHANGELOG.md` des Plugin-Ordners. Faustregel: Befehls-/Argument-Änderungen = minor, reine Instruktions-Verbesserungen = patch, Umbenennungen/Entfernungen = major. (`/git-work:changelog plugins/<name>` pflegt die Changelogs selbst.)

## Externe Plugins einbinden

Einträge in `.claude-plugin/marketplace.json` können statt auf lokale Ordner direkt auf fremde GitHub-Repos zeigen — die Dateien liegen dann nie in diesem Repo, `/plugin update` zieht vom Original:

```json
{
  "name": "fremdes-plugin",
  "source": { "source": "github", "repo": "owner/repo", "ref": "v1.2.0" }
}
```

`ref` (Tag/Commit) pinnen statt HEAD folgen — fremder Code mit Hooks/MCP-Servern läuft lokal, Vertrauen + Pinning sind Pflicht.

## Validierung

`python scripts/validate.py` prüft marketplace.json, alle plugin.json, SKILL.md-Frontmatter, Referenz-Pfade und Markdown-Links. Läuft automatisch bei jedem Push (GitHub Action). Lokal: `pip install pyyaml` einmalig.

## Struktur

```
claude-plugins/
├── .claude-plugin/marketplace.json   # der Katalog (name: "labi")
├── plugins/
│   ├── agent-docs/                   # Multi-Skill: skills/<name>/SKILL.md → /agent-docs:<name>
│   ├── git-work/
│   ├── deps/
│   └── dead-code/                    # Single-Skill: SKILL.md im Root → /dead-code
├── scripts/validate.py
├── .github/workflows/validate.yml
└── CONTRIBUTING.md                   # neues Plugin in 5 Schritten
```

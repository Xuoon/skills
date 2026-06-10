# agent-docs

Hält Agent-Doku (`CLAUDE.md`/`AGENTS.md` + Rules-Verzeichnisse wie `.claude/rules/**`) mit der Code-Realität konsistent. Eine Philosophie, vier Befehle: surgical, evidenz-basiert, löschen-bevorzugt, approval-gated.

## Befehle

| Befehl | Zweck | Auto-Invoke durch Claude |
| --- | --- | --- |
| `/agent-docs:sync [base-branch] [pfad]` | Surgical Post-Session-Update entlang des Code-Diffs | Ja — wann immer Code angefasst wurde |
| `/agent-docs:audit [pfad] [solo] [quick]` | Scored Review aller Docs (inkl. Prune-Sweep) | Nein — nur manuell |
| `/agent-docs:prune [pfad]` | Dedup-/Lösch-Pass | Nur bei explizitem Auftrag ("was kann weg") |
| `/agent-docs:init [pfad]` | Minimale Agent-Doku in frischen Repos bootstrappen | Nur bei explizitem Auftrag ("setup CLAUDE.md") |

Argument-Flags: `solo` = ohne Subagenten (kleine Repos / Umgebungen ohne Subagenten), `quick` = Audit ohne Scoring & Coverage-Sweep (nur Red Flags + Below-B-Verdacht).

## Struktur

```
agent-docs/
├── .claude-plugin/plugin.json
├── references/
│   ├── shared.md        # Scope, Ground Rules, Subagenten, Vorschlags-Format, Verify, Anti-Patterns
│   ├── style.md         # Qualitätsmaßstab für Agent-Doku
│   └── prune-sweep.md   # Prune-Prozedur (genutzt von audit + prune)
└── skills/
    ├── sync/SKILL.md
    ├── audit/SKILL.md
    ├── prune/SKILL.md
    └── init/SKILL.md
```

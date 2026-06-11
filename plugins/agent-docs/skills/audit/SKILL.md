---
description: Comprehensive scored review of all agent docs (CLAUDE.md/AGENTS.md plus rules directories) with bidirectional claim verification, coverage sweep, paths-glob validation and prune-sweep. Manual-only — invoke via /agent-docs:audit. Optional arg — `quick` skips scoring and coverage (red flags + below-B list only).
argument-hint: "[quick]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *)
---

# Audit — scored review (inkl. Prune-Sweep)

Comprehensive Review aller Agent-Docs mit Scoring. Teuer und tokenintensiv — läuft nur auf expliziten Befehl.

**Zuerst lesen:** `${CLAUDE_SKILL_DIR}/../../references/shared.md` (Scope, Ground Rules, Subagenten, Vorschlags-Format, Verify, Anti-Patterns) und `${CLAUDE_SKILL_DIR}/../../references/style.md` (Qualitätsmaßstab). Für Sweep 1d: `${CLAUDE_SKILL_DIR}/../../references/prune-sweep.md`.

## Argumente

`quick` (optional) → Spar-Variante: Claim-Verifikation, Link-/Glob-Checks und Duplikat-Scan laufen, aber **kein** 6-Kriterien-Scoring, **keine** Per-File-Tabellen, **kein** Coverage-Sweep. Report = Red Flags + Below-B-Verdachtsliste (1 Zeile pro Datei) + Fix-Proposals nur für Red Flags.

## Workflow

1. **Discovery.** Glob alle Scopes (laut shared.md). Parallel Subagenten (~1 pro 3–5 Files, Output-Format laut shared.md festnageln). Auftrag:
   > *"Verifiziere jeden Claim **beidseitig** (Doku→Code UND Code→Doku) via Grep/Read. Output: `{file, line, claim, verified|stale|wrong|missing|duplicate|generic, evidence}`. Bei Unsicherheit `needs verification` statt raten."*

   Plus separate Sweeps (je 1 Subagent):
   - **a) Coverage** *(entfällt bei `quick`)* — non-triviale Code-Bereiche mit 0 Doc-Coverage. Kriterium "kritisch": Ein neuer Agent würde dort ohne Doku falsche Annahmen treffen oder lange suchen (non-obvious Invariants, Sicherheits-relevantes, überraschende Kopplungen, CI/Deploy-Pipelines, Test-Harnesses, Polyfills/Side-Effect-Imports, nicht-offensichtliche Datenformate). Triviale CRUD-Bereiche zählen NICHT.
   - **b) Frontmatter-`paths:`-Validierung** — Verdicts: `ok|dead|too-broad|too-narrow` mit Beispiel-Treffern bzw. fehlenden erwarteten Treffern. Typische too-narrow-Lücke: Test-Suiten + Lib-Helfer.
   - **c) Code-Kommentar-Refs** zu Doku-Files resolven; alle relativen Markdown-Links prüfen.
   - **d) Prune-Sweep** laut prune-sweep.md.

2. **Scoring** pro File (s.u.). *Entfällt bei `quick`.*
3. **Report** ausgeben (Template s.u.; bei `quick` nur Summary-Zeile, Red Flags und Below-B-Verdachtsliste).
4. **Fix-Proposals** für alle material Issues im Format laut shared.md; Files **< B** priorisieren (bei `quick`: nur Red Flags). Keine kosmetischen Vorschläge.
5. **Approval-Gate.** Stop, auf User-Freigabe warten.
6. **Verify.** Laut shared.md; betroffene Files re-scoren (bei `quick` nur Link-/Glob-Verify).

## Scoring (6 Kriterien)

| Kriterium | Gewicht | Voller Score = |
| --- | ---: | --- |
| Accuracy | 25 | Pfade, Namen, Commands, beschriebene Behavior matchen Code. |
| Completeness | 20 | Repo-spezifische, non-obvious Invariants vollständig. |
| Conciseness | 20 | Keine Generics, kein Source-Duplikat, nichts Selbstverständliches, kein Cross-File-Duplikat. |
| Actionability | 15 | Neue Session kann ohne Code-Reread arbeiten. |
| Currency | 10 | Keine stale Refs, dead Links, removed/renamed Code. |
| Cross-references | 10 | Interne Links resolven, keine Duplikation zwischen Files. |

Grades: **A** 90+, **B** 70+, **C** 50+, **D** 30+, **F** <30.
Brevity ≠ Fail. Bloated ≠ Pass. Akkurates Signal > Score-Padding.

## Report-Template

```markdown
## Documentation Audit
**Summary:** N audited · A:x B:x C:x D:x F:x · Below-B: x · Undocumented: x · Duplikate: x · Prune-Kandidaten: x

**Red Flags**
- <path:line> — <flag>: <stale-path|broken-link|wrong-behavior|duplicate|contradicts-<file>|security-mismatch|undocumented-critical>

**Per-File**
### <path> — XX/100 (X)
| Acc | Comp | Conc | Act | Curr | Cross | Notes |
|---:|---:|---:|---:|---:|---:|---|
| X/25 | X/20 | X/20 | X/15 | X/10 | X/10 | <kurz> |

Issues:
- <doc:line> — <was falsch> — Evidence: <code:line>

**Undocumented Areas**
- <code path> — <Warum kritisch> — <wo dokumentieren (Datei + Sektion)>

**Nebenbefunde (Code, nicht Doku)**
- <code:line> — <Befund>
```

A-Files: One-Liner statt Tabelle.

## Fix-Regeln

- Nur Issues aus der Report-Phase. Kein Scope-Creep.
- Lösch-Kandidaten zuerst: stale Refs, generischer Rat, Code-Paraphrase, Selbstverständliches, Cross-File-Duplikate (in eine Datei kanonisieren → andere verlinken).
- Eine Zeile pro Konzept.
- "Undocumented-critical" → vorschlagen **wo** (existierende Datei + Sektion) + Draft ≤ 10 Zeilen, **kein neues File** (außer es ist wirklich ein eigener Themenbereich).
- Nichts dokumentieren, was nicht existiert. Wenn Fix nur durch Spekulation möglich wäre → Issue droppen.

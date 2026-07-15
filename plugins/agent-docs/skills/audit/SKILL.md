---
description: >
  Agent-Doku prüfen und bewerten (CLAUDE.md/AGENTS.md + Rules).
  Modi: ohne Arg = voller Score · quick = nur Red-Flags · prune = nur löschen; Pfad begrenzt den Scope.
argument-hint: "[quick|prune] [pfad]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(wc *)
---

# Audit — scored review (inkl. Prune-Sweep)

Teuer und tokenintensiv — nur auf expliziten Befehl. Completeness **ohne** Conciseness ist ein Fail-Modus: aufgeblähte korrekte Docs sind **nicht** A.

**Zuerst lesen:** `shared.md`, `style.md`, `prune-sweep.md` (alle unter `${CLAUDE_SKILL_DIR}/../../references/`).

## Argumente (`$ARGUMENTS`)

User-Eingabe nach dem Slash-Command (kann leer sein):

```text
$ARGUMENTS
```

**Parsen** (Tokens whitespace-getrennt, Reihenfolge egal):

| Token | Bedeutung |
| --- | --- |
| *(leer / kein Mode-Token)* | **full** — Claims, Coverage, paths, Links, Prune, Scoring, Fix-Proposals |
| `quick` | Claims + Links/Globs + Duplikat/Prune-Scan; **kein** 6er-Scoring, **keine** Per-File-Tabellen, **kein** Coverage. Report: Red Flags + Below-B (1 Zeile/Datei) + Proposals nur Red Flags **und** klare Deletes |
| `prune` | Nur prune-sweep + Link-Check. Proposals fast nur Delete/Shorten/Merge |
| Pfad (`apps/…`, `packages/…`, `.claude/rules/…`, Dateiname) | Scope auf diesen Subtree; Cross-Refs/kanonische Gegenstellen außerhalb trotzdem prüfen |
| Freitext (`alles`, `dünner`, …) | Mode-Hint wenn kein explizites `quick`/`prune`; sonst ignorieren |

**Beispiele (Autocomplete-Hilfe):**

```text
/agent-docs:audit                 → full, ganzes Repo
/agent-docs:audit quick           → sparsam, Red Flags + Prune-Suspects
/agent-docs:audit prune           → nur dünner machen
/agent-docs:audit quick apps/dash → quick, nur Dash-Docs + gematchte Rules
/agent-docs:audit prune .claude/rules/dash
```

Mode zu Beginn in **einem Satz** festnageln: `Mode=quick · Scope=apps/dash`.

## Workflow

1. **Discovery.** Glob Scope (shared.md). Parallel Subagenten (~1 pro 3–5 Files). Auftrag:

   > Beidseitig verifizieren (Doku→Code **und** Code→Doku).  
   > Output: `{file,line,claim,verified|stale|wrong|missing|duplicate|generic|impl-detail,evidence}`.  
   > `impl-detail` = Implementation die der Code allein tragen sollte.  
   > Unsicher → `needs verification`.

   Separate Sweeps (je 1 Subagent; bei `prune` nur d + Links):

   - **a) Coverage** *(nicht bei quick/prune)* — nur **kritisch** non-obvious (Security, Lifecycle, Kopplung, CI/Deploy, Harness, Side-Effect-Imports, Formate). Trivial-CRUD = 0 Coverage-Issue.
   - **b) `paths:`** — `ok|dead|too-broad|too-narrow` + Beispiele.
   - **c) Links + Code-Kommentar-Refs** resolven.
   - **d) Prune-Sweep** — **immer** (auch full/quick), laut prune-sweep.md.

2. **Scoring** pro File (s.u.) — entfällt bei `quick`/`prune`.
3. **Report** (Template).
4. **Fix-Proposals** (shared.md-Format). Priorität:
   1. Broken/wrong/security  
   2. **Deletes / Prune / Merge**  
   3. missing-blocking (≤10 Zeilen Draft, existierende Datei)  
   4. nie Kosmetik, nie Inventar-Auffüllung  
   Bei `quick`: Red Flags + eindeutige Prunes. Bei `prune`: fast nur Deletes.
5. **Approval-Gate.** Stop.
6. **Verify** (shared.md); Full: re-score; bei Conciseness-Drop durch Add-only-Fixes → revert Add, Prune priorisieren.

## Scoring (6 Kriterien)

| Kriterium | Gewicht | Voller Score |
| --- | ---: | --- |
| Accuracy | 25 | Claims matchen Code |
| Completeness | **15** | **Agent-blocking** Invarianten da — nicht „alles Erwähnenswerte“ |
| Conciseness | **25** | Kein Generic, kein Source-Duplikat, kein Impl-Detail, kein Cross-File-Duplikat, Größe im style.md-Richtwert |
| Actionability | 15 | Session kann ohne Code-Reread die **kritischen** Fehler vermeiden |
| Currency | 10 | Keine stale Refs/Links |
| Cross-references | 10 | Links ok; keine Mechanik-Duplikation |

Grades: **A** 90+ · **B** 70+ · **C** 50+ · **D** 30+ · **F** <30.

**Scoring-Regeln gegen Aufblasen:**

- Completeness darf **nicht** steigen, indem man Impl-Detail oder Inventar ergänzt.
- Datei über style-Richtwert (Overview ~40–50, Domain ~60, hard ~150) **ohne** Security-Rechtfertigung: Conciseness max. 15/25.
- Echtes Cross-File-Duplikat: Cross-references und Conciseness abziehen.
- Brevity ≠ Fail. Bloated korrekte Novelle ≠ A.

## Report-Template

```markdown
## Documentation Audit
**Summary:** N audited · A:x B:x C:x D:x F:x · Below-B: x · Undocumented-critical: x · Duplikate: x · Prune-Kandidaten: x · Σ lines: N (Δ vs start if known)

**Red Flags**
- <path:line> — <stale|broken-link|wrong|duplicate|impl-detail|contradicts-…|security|undocumented-critical>

**Prune (priorisiert)**
- <path:line> — <warum> — <delete|shorten|merge-into>

**Per-File** *(full only; A = one-liner)*
### <path> — XX/100 (X)
| Acc | Comp | Conc | Act | Curr | Cross | Notes |
|---:|---:|---:|---:|---:|---:|---|
| … | … | … | … | … | … | … |

**Undocumented-critical** *(full only)*
- <code path> — warum blocking — wohin (existierende Datei + Sektion) — Draft ≤10 Zeilen

**Nebenbefunde (Code)**
- …
```

## Fix-Regeln

- Nur Report-Issues. Kein Scope-Creep.
- **Lösch-Kandidaten zuerst** im Vorschlagspaket.
- Eine Zeile pro Konzept; Add ≤3 Zeilen (blocking ≤10 nur undocumented-critical).
- Neues File nur wenn eigener Themenbereich **und** Merge unzumutbar.
- Nichts erfinden. Spekulation → drop.

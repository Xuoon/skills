---
name: agent-docs
description: >
  Hält die Agent-Doku (CLAUDE.md/AGENTS.md, .claude/rules) und vorhandene CHANGELOG.md am Code
  — legt neu an, wenn keine da ist, sonst Diff-Sync nach Code-Änderungen. Löschen-bevorzugt,
  strenges Add-Gate; 0 Änderungen ist ein gültiges Ergebnis. Standard nur Vorschlag, geschrieben
  wird erst mit `--fix`. AUSLÖSER: Code geändert, "Doku syncen", "Changelog schreiben/anpassen",
  "kürzen"/"weniger Doku", oder ein Repo ohne CLAUDE.md, das eine braucht. NICHT wenn die
  Änderung kein dokumentiertes Verhalten berührt.
  Von selbst immer nur der Vorschlagsmodus — `--audit` und `--fix` nie ungefragt.
argument-hint: "[--audit] [--fix]"
allowed-tools: Task Agent Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git merge-base *) Bash(git ls-files *) Bash(ls *) Bash(find *) Bash(wc *)
---

# agent-docs — Doku am Code halten

Kleinster passender Modus. **Kein Freifahrtschein zum Aufblasen.**

**Zuerst lesen:**

1. `${CLAUDE_SKILL_DIR}/references/shared.md` — Scope, asymmetrisches Gate, Format, Verify, Anti-Patterns
2. `${CLAUDE_SKILL_DIR}/references/style.md` — was rein / was raus, Größenrichtwerte
3. Bei jedem Add oder User-Wunsch „dünner/prune": `${CLAUDE_SKILL_DIR}/references/prune-sweep.md`

## Argumente (`$ARGUMENTS`)

| Flag | Bedeutung |
| --- | --- |
| *(ohne Flag)* | **Sync** — Doku gegen den Code-Diff prüfen, Vorschlag zeigen. **Kein Edit** |
| `--fix` | Vorschlag direkt schreiben |
| `--audit` | **Audit** — voller Report mit Scoring, Coverage, Prune-Sweep und Link-Check. **Kein Edit** |
| `--audit --fix` | Audit + gefundene Fixes direkt schreiben |

Scope ist immer das aktuelle Verzeichnis. Diff-Basis oder Subtree bei Bedarf im **Fließtext** nennen („gegen main", „nur apps/dash"); ohne Angabe = Working Tree.

```text
/agent-docs                        → Sync, nur Vorschlag
/agent-docs --fix                  → Sync + direkt schreiben
/agent-docs --audit                → voller Report, kein Edit
/agent-docs --audit --fix          → Report + Fixes schreiben
/agent-docs  nur apps/dash gegen main
```

Modus + (freeform) Diff-Basis/Subtree in **einem Satz** festnageln, dann los.

## Routing

Snapshot: `git status --short`, `git diff --stat` (ggf. gegen freeform Ref), `git ls-files` für `CLAUDE.md`/`AGENTS.md`/Rules.

| Situation | Modus |
| --- | --- |
| Keine Agent-Doku im Scope | **Init** → `${CLAUDE_SKILL_DIR}/references/init.md` |
| `--audit` | **Audit** (unten) |
| sonst | **Sync** (unten); Diff-Basis aus freeform Ref wenn genannt |

## Asymmetrisches Gate

Kanonisch in `shared.md`. Essenz: DELETE billig (stale, Duplikat, generisch, Impl-Detail, Historie) — ADD teuer (agent-blocking ∧ non-obvious ∧ single home ∧ ≤3 Zeilen ∧ Netto-Budget). Unsicher → ADD nicht vorschlagen, klaren Müll löschen.

## Sync (Standard)

1. **Snapshot.** Working Tree + Session; User-Ref → Diff gegen `merge-base <ref> HEAD`. Optional `wc -l` auf betroffene Doc-Files als Baseline.

2. **Doc-Discovery.** Parallel Subagenten (1 pro Bereich). Geänderte Code-Pfade + **fester** Auftrag:

   > Finde in CLAUDE.md/AGENTS.md, Rules, Frontmatter-`paths:`, Code-Doku-Refs:
   > (A) Stellen die **falsch/stale** zum Diff sind
   > (B) Stellen die durch den Diff **redundant** werden (löschen)
   > (C) **Nur wenn** agent-blocking und non-obvious: materielle Lücken
   > Output strukturiert: `{file,line,kind:wrong|stale|redundant|missing-blocking,evidence}`.
   > Keine Fixes. Keine „nice to have"-Lücken.

3. **Filter.** Jeden Treffer durchs asymmetrische Gate. Drop: nice-to-have, Inventar, UI-Chrome, Implementation-Spec der frischen Feature-Arbeit, spekulative Completeness.

4. **Mini-Prune (Pflicht wenn irgendein ADD übrig ist).** Kurzer prune-sweep auf **dieselben** Dateien + offensichtliche Cross-Duplikate des Themas. Mindestens ein Delete/Shorten-Kandidat im Paket **oder** schriftlich: warum Netto-Wachstum unvermeidlich (neue Domain-Invariante).

5. **Vorschlag.** Blöcke laut shared.md — **Deletes zuerst**, dann Adds. `Netto:` schätzen. **Ohne `--fix` endet der Lauf hier.**

6. **Anwenden + Verify (nur mit `--fix`).** Bestätigte Blöcke schreiben, dann Verify laut shared.md inkl. **Δ lines**. Reines Wachstum ohne genehmigte Ausnahme im Report markieren.

## Changelog

Gibt es im Scope eine `CHANGELOG.md` und berührt der Diff etwas, das ein Nutzer merkt, gehört sie ins selbe Paket. Ohne vorhandene Datei wird keine angelegt.

**Der Changelog ist für Endnutzer, nicht für Entwickler.** Er beantwortet genau eine Frage: was ist neu, was hat sich geändert, was ist weg.

Raus bleibt: was während der Arbeit schiefging, was zurückgebaut wurde, wie migriert wurde, welche Tests laufen, Verifikationsblöcke, Warnungen wie „nicht abwärtskompatibel" — Breaking Changes stehen als Versionssprung und als Handlungsanweisung da, nicht als Warnhinweis. Interna (Refactorings, Abhängigkeits-Bumps, CI) nur, wenn ein Nutzer sie bemerkt.

Rein gehört, was der Nutzer tun muss, mit exakten Befehlen.

**Mehrere Changelogs im Monorepo:** nur der zum geänderten Bereich. Berührt ein Diff mehrere Bereiche, bekommt jeder seinen eigenen Eintrag — kein Sammeleintrag an der Wurzel. Bestehende Struktur und Sprache der Datei werden übernommen, nicht ersetzt.

## Audit (`--audit`)

Completeness **ohne** Conciseness ist ein Fail-Modus: aufgeblähte korrekte Docs sind **nicht** A. Vorher zusätzlich `prune-sweep.md` lesen.

1. **Discovery — Fan-out.** Scope globben (shared.md), dann parallele Subagenten in **einem** Zug losschicken (~1 pro 3–5 Dateien plus die vier Sweeps). Jeder bekommt einen festen Auftrag und gibt nur strukturierte Funde zurück, keine Fixes:

   > Beidseitig verifizieren (Doku→Code **und** Code→Doku).
   > Output: `{file,line,claim,verified|stale|wrong|missing|duplicate|generic|impl-detail,evidence}`.
   > `impl-detail` = Implementation die der Code allein tragen sollte.
   > Unsicher → `needs verification`.

   Sweeps daneben (je 1 Subagent):

   - **a) Coverage** — nur **kritisch** non-obvious (Security, Lifecycle, Kopplung, CI/Deploy, Harness, Side-Effect-Imports, Formate). Trivial-CRUD = 0 Coverage-Issue.
   - **b) `paths:`** — `ok|dead|too-broad|too-narrow` + Beispiele.
   - **c) Links + Code-Kommentar-Refs** resolven.
   - **d) Prune-Sweep** laut prune-sweep.md.

2. **Scoring** pro Datei (s.u.).
3. **Report** (Template unten).
4. **Fix-Proposals** (shared.md-Format). Priorität: (1) broken/wrong/security, (2) **Deletes/Prune/Merge**, (3) missing-blocking (≤10 Zeilen Draft, existierende Datei), (4) nie Kosmetik, nie Inventar-Auffüllung.
5. **Ohne `--fix` endet der Lauf hier** — Report + Proposals sind das Ergebnis.
6. **Anwenden + Verify (nur mit `--fix`).** Proposals schreiben, Verify laut shared.md, re-scoren; bei Conciseness-Drop durch Add-only-Fixes → Add revert, Prune priorisieren.

### Scoring

| Kriterium | Gewicht | Voller Score |
| --- | ---: | --- |
| Accuracy | 25 | Claims matchen Code |
| Completeness | **15** | **Agent-blocking** Invarianten da — nicht „alles Erwähnenswerte" |
| Conciseness | **25** | Kein Generic, kein Source-Duplikat, kein Impl-Detail, kein Cross-File-Duplikat, Größe im style.md-Richtwert |
| Actionability | 15 | Session kann ohne Code-Reread die **kritischen** Fehler vermeiden |
| Currency | 10 | Keine stale Refs/Links |
| Cross-references | 10 | Links ok; keine Mechanik-Duplikation |

Grades: **A** 90+ · **B** 70+ · **C** 50+ · **D** 30+ · **F** <30.

Gegen Aufblasen: Completeness darf **nicht** steigen, indem man Impl-Detail oder Inventar ergänzt. Datei über style-Richtwert (Overview ~40–50, Domain ~60, hart ~150) **ohne** Security-Rechtfertigung → Conciseness max. 15/25. Echtes Cross-File-Duplikat zieht Cross-references **und** Conciseness. Brevity ≠ Fail; bloated korrekte Novelle ≠ A.

### Report-Template

```markdown
## Documentation Audit
**Summary:** N audited · A:x B:x C:x D:x F:x · Below-B: x · Undocumented-critical: x · Duplikate: x · Prune-Kandidaten: x · Σ lines: N (Δ vs start if known)

**Red Flags**
- <path:line> — <stale|broken-link|wrong|duplicate|impl-detail|contradicts-…|security|undocumented-critical>

**Prune (priorisiert)**
- <path:line> — <warum> — <delete|shorten|merge-into>

**Per-File** *(A = one-liner)*
### <path> — XX/100 (X)
| Acc | Comp | Conc | Act | Curr | Cross | Notes |
|---:|---:|---:|---:|---:|---:|---|

**Undocumented-critical**
- <code path> — warum blocking — wohin (existierende Datei + Sektion) — Draft ≤10 Zeilen

**Nebenbefunde (Code)**
- …
```

## Fix-Regeln

- Nur Issues aus dem Lauf. Kein Scope-Creep.
- **Lösch-Kandidaten zuerst** im Vorschlagspaket.
- Eine Zeile pro Konzept; Add ≤3 Zeilen (≤10 nur bei undocumented-critical).
- Neue Datei nur wenn eigener Themenbereich **und** Merge unzumutbar.
- Nichts erfinden. Spekulation → drop.

## Sonderfälle

### Neue shared Bausteine (Komponente/Hook/Export/Konstante)

Eine Zeile am **kanonischen** Inventar-Ort (Package-CLAUDE oder bestehende Domain-Rule) — **nur** wenn „nutze X nicht Y" agent-blocking ist. Kein Eintrag in mehreren Dateien. Keine Prop-Listen.

### Frisch gebautes Feature

Updated werden **Verträge** (Lifecycle, Security, kanonischer Helper), **nicht** die Implementierungsbeschreibung (Algorithmen, Cache-Pads, Komponenten-Baum). Wenn der Code die Wahrheit trägt → **0 Doc-Zeilen** ist ein valides Ergebnis.

### „Nichts zu tun"

Valides und **erwünschtes** Outcome. Melden: `Sync: 0 candidates (gate).` Nicht erfinden.

## Anti-Patterns

- Nach UI-Arbeit die Rule um Chrome/Prefetch/Debounce erweitern.
- Overview und Rule gleichzeitig mit demselben Fakt füttern.
- Neue Rule-Datei für <15 exklusive Zeilen statt Merge.
- Whole-file rewrite zum Erweitern.
- Approval umgehen („user said go go go" auf Code ≠ Blankoscheck für Doc-Aufblasen; Doc-Edits bleiben approval-gated außer der User hat **explizit** Doc-Apply freigegeben).

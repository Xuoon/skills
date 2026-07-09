# Changelog — agent-docs

## [4.0.1] – 2026-07-09

### Changed

- **Slash Autocomplete / `argument-hint`:**
  - `audit`: `[quick|prune] [pfad]` (vorher nur `[quick|prune]`)
  - `sync`: neu `[main|branch|prune] [pfad]`
- Beide Skills parsen **`$ARGUMENTS`** explizit (Mode, Git-Ref, Subtree, Freitext) mit Beispielen im Body — nicht nur Hint-Text ohne Verarbeitung.
- Descriptions kürzer/scannbarer für Skill-Picker.

## [4.0.0] – 2026-07-09

### Why

Sync/Audit neigten dazu, nach Feature-Arbeit **Implementation-Details und Inventare zu addieren** (Prefetch-Pads, UI-Chrome, Prop-Listen). Mehr Zeilen = mehr Drift. Agents brauchen **Verträge**, nicht Tutorials.

### Changed (breaking behavioral)

- **Asymmetrisches Edit-Gate** in `references/shared.md`: DELETE leicht, ADD schwer (agent-blocking ∧ non-obvious ∧ single home ∧ ≤3 Zeilen ∧ Netto-Budget).
- **Sync** führt bei jedem Add-Kandidaten einen **Mini-Prune** mit; Deletes im Vorschlag **vor** Adds; valides Outcome `0 candidates`.
- **Audit-Scoring:** Conciseness **25**, Completeness **15** — Aufblasen kann Completeness nicht „retten“.
- Audit-Arg **`prune`**: nur Lösch-/Merge-Pass.
- **style.md:** „Code owns implementation detail“; Größenrichtwerte Root/App/Domain; explizite Anti-Inventar-Tabelle.
- **prune-sweep.md:** wann (Sync/Audit/User), Merge-Regel für kleine Rule-Dateien (≤~15 exklusive Zeilen), Netto-Ziel Δ&lt;0.
- Verify meldet **Δ lines**.
- Whole-file rewrite nur noch als **`rewrite-prune`** (Netto kürzer), nicht zum Erweitern.

### Added

- Sync-Trigger-Phrasen: „weniger doku“, „prune“, „unnötig“.
- Claim-Kind `impl-detail` im Audit-Discovery.
- Anti-Pattern: Session-Changelog / frisches Feature 1:1 in Rules spezifizieren.

## [3.0.0] – 2026-06-30

### Changed

- `/agent-docs:sync` ist smarter Alltags-Router (Init/Sync/Review).
- `sync` `allowed-tools` um `ls`/`find` erweitert.

### Removed

- **Breaking:** `/agent-docs:init` als eigener Befehl — Init ist Sync-Modus (`references/init.md`).

## [2.0.0] – 2026-06-11

### Changed

- Argumente vereinfacht; `quick` (audit) bleibt.

### Removed

- **Breaking:** `/agent-docs:prune` — Prune in Sync-Gate + Audit-Sweep; Prozedur in `references/prune-sweep.md`.

## [1.0.0] – 2026-06-10

### Added

- Plugin mit `sync`, `audit`, `prune`, `init`; zentrales Vorschlags-Format in `shared.md`.

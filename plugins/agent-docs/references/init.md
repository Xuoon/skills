# Init-Modus — Agent-Doku bootstrappen

Vom Sync-Router, wenn im Scope **keine** Agent-Doku existiert. Erzeugt das **Minimum**, das ein Audit überleben würde — nicht das Maximum, das beeindruckt.

Qualitätsmaßstab: [style.md](style.md). Gates: [shared.md](shared.md).

## Grundsätze

- **Nur Verifiziertes** mit `file:line`. Keine Annahmen, kein „Projekte dieser Art“.
- **Lieber 15 gute Zeilen als 60 generische.** Root-Ziel: ≤ ~40 Zeilen.
- **Keine leeren Gerüste**, keine TODO-Sektionen, keine Datei „für später“.
- **Nichts Triviales** aus Verzeichnisnamen.
- **Add-Gate gilt auch hier:** jede Zeile muss agent-blocking + non-obvious sein.

## Workflow

1. **Recon.** Parallel Subagenten je Workspace (strukturiert, `file:line`, keine Prosa):
   - Manifest/Tooling: Scripts, Workspaces, packageManager, Test/Lint — nur **nicht-offensichtliche** Befehle/Traps.
   - CI/Deploy: was wann läuft, manuelle Schritte, Breakages.
   - Non-obvious Invarianten: Env, Codegen, Side-Effects, Reihenfolge, Stolperfallen in Kommentaren.
   - Konvention: `AGENTS.md` vs `CLAUDE.md`? Im Zweifel CLAUDE.md; bei klaren Signalen User fragen.

2. **Style-Gate.** Jeden Fund: würde die Zeile style.md + Add-Gate überleben? Nein → raus. Kurz ist Erfolg.

3. **Draft (Minimum).**
   - Root-`CLAUDE.md`: 1-Satz-Was, Commands (nur Traps/Aggregate), 3–7 Invarianten max, Rules-Index falls Rules existieren.
   - `.claude/rules/<thema>.md` **nur** bei ≥1 echter pfadgebundener Regel; `paths:` sofort gegen Dateien prüfen (nicht too-broad; Tests/Libs mitdenken).
   - Package-CLAUDE.md nur bei **eigenen** non-obvious Regeln — nie pro forma pro Workspace.
   - Keine Domain-Rule, die nur Ordner beschreibt.

4. **Vorschlag + Approval.** `**Create:**`-Blöcke (shared.md) mit Evidence pro Aussage. Stop. **Init überschreibt nie Bestehendes** — sonst Sync/Review.

5. **Verify.** Links, Globs; `git status` nur bestätigte neue Dateien. Σ lines melden (soll klein sein).

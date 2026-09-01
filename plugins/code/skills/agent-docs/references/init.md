# Init-Modus — Agent-Doku bootstrappen

Vom Sync-Router, wenn im Scope **keine** Agent-Doku existiert. Erzeugt das **Minimum**, das ein Audit überleben würde — nicht das Maximum, das beeindruckt.

Qualitätsmaßstab: [style.md](style.md). Gates: [shared.md](shared.md).

## Grundsätze

- **Keine leeren Gerüste**, keine TODO-Sektionen, keine Datei „für später“.
- **Add-Gate gilt auch hier:** jede Zeile muss agent-blocking + non-obvious sein.

## Workflow

1. **Recon.** Verfügbare Subagenten parallel je Workspace einsetzen, sonst dieselben Aufträge seriell abarbeiten (strukturiert, `file:line`, keine Prosa):
   - Manifest/Tooling: Scripts, Workspaces, packageManager, Test/Lint — nur **nicht-offensichtliche** Befehle/Traps.
   - CI/Deploy: was wann läuft, manuelle Schritte, Breakages.
   - Non-obvious Invarianten: Env, Codegen, Side-Effects, Reihenfolge, Stolperfallen in Kommentaren.
   - Vorhandene Repo- und Client-Konvention erkennen. Ohne Signal `AGENTS.md` vorschlagen; `CLAUDE.md` und `.claude/rules` nur bei belegter Claude-Code-Konvention oder ausdrücklichem Wunsch.

2. **Style-Gate.** Jeden Fund: würde die Zeile style.md + Add-Gate überleben? Nein → raus. Kurz ist Erfolg.

3. **Draft (Minimum).**
   - Kanonische Root-Agentdatei: 1-Satz-Was, Commands (nur Traps/Aggregate), 3–7 Invarianten max, Rules-Index falls Rules existieren.
   - Nutzt das Repo nachweislich `AGENTS.md` **und** Claude Code, `CLAUDE.md` nur als `@AGENTS.md`-Kompatibilitäts-Pointer plus echte Claude-Deltas vorschlagen; gemeinsame Regeln nie kopieren.
   - Client-spezifische Rules-Verzeichnisse **nur** bei belegter Repo-Konvention und ≥1 echter pfadgebundener Regel; Globs sofort gegen Dateien prüfen.
   - Package-Agentdatei nur bei **eigenen** non-obvious Regeln — nie pro forma pro Workspace.
   - Keine Domain-Rule, die nur Ordner beschreibt.

4. **Vorschlag + Approval.** `**Create:**`-Blöcke (shared.md) mit Evidence pro Aussage. Stop. **Init überschreibt nie Bestehendes** — sonst Sync/Review.

5. **Verify.** Links, Globs; `git status` nur bestätigte neue Dateien. Σ lines melden (soll klein sein).

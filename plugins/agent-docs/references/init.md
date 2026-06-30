# Init-Modus — Agent-Doku bootstrappen

Vom Sync-Router geladen, wenn im Scope **keine** Agent-Doku existiert (`CLAUDE.md`/`AGENTS.md` oder Rules-Verzeichnis fehlen). Erzeugt das **Minimum** an Agent-Doku, das ein Audit überleben würde — nicht das Maximum, das beeindruckend aussieht. Jede Zeile muss den Qualitätsmaßstab aus [style.md](style.md) bestehen, sonst gehört sie nicht in den Erstwurf.

## Grundsätze (zusätzlich zu den Ground Rules)

- **Nur Verifiziertes.** Jede Aussage stammt aus gelesenem Code/Config mit `file:line`-Evidence. Nichts aus Annahmen, nichts "was Projekte dieser Art üblicherweise haben".
- **Lieber 15 gute Zeilen als 60 generische.** Ziel Root-CLAUDE.md: ≤ ~40 Zeilen.
- **Keine leeren Gerüste.** Kein Rules-Verzeichnis ohne echte Regel, keine Platzhalter-Sektionen ("TODO: beschreiben"), keine Datei "für später".
- **Nichts dokumentieren, was Code/Verzeichnisnamen trivial zeigen.** `src/components` enthält Komponenten — das schreibt niemand auf.

## Workflow

1. **Recon.** Repo-Realität erfassen — bei Monorepos parallel Subagenten je Workspace (Output-Format laut shared.md festnageln: nur non-obvious Findings mit `file:line`, keine Prosa):
   - Manifest + Tooling: `package.json` (Scripts, Workspaces, packageManager), Lockfile, Runtime-Versionen, Build-/Test-Setup, Linter/Formatter-Configs.
   - CI/Deploy: Workflows, Dockerfiles, Deploy-Skripte — was läuft wann, was darf nicht brechen.
   - Non-obvious Invarianten: Env-Handling, Codegen-Schritte, Side-Effect-Imports, Reihenfolge-Abhängigkeiten, überraschende Kopplungen, bekannte Stolperfallen (Kommentare wie "do not change").
   - Konvention im Umfeld: Wird im Ökosystem des Repos `AGENTS.md` statt `CLAUDE.md` erwartet? Im Zweifel CLAUDE.md; bei klaren Signalen den User fragen.
2. **Style-Gate.** Jeden Recon-Fund einzeln prüfen: Würde diese Zeile ein Audit nach style.md überleben (repo-spezifisch, non-obvious, actionable)? Was durchfällt, fliegt raus — auch wenn die Datei dadurch kurz wird. Kurz ist das Ziel.
3. **Draft.**
   - Root-`CLAUDE.md`: 1-Satz-Was, nicht-offensichtliche Befehle (nur die, deren Existenz/Wirkung man dem `scripts`-Block nicht ansieht), non-obvious Invarianten/Gotchas, Verweise auf Rules (falls vorhanden).
   - `.claude/rules/<thema>.md` nur, wenn mindestens **eine echte pfadgebundene Regel** existiert; Frontmatter-`paths:`-Glob sofort gegen reale Dateien prüfen (matcht, nicht too-broad, Test-/Lib-Pfade mitgedacht).
   - Monorepo: Package-CLAUDE.md nur für Workspaces mit **eigenen** non-obvious Regeln — niemals pro forma für jedes Package.
4. **Vorschlag + Approval.** Jede neue Datei als `**Create:**`-Block laut shared.md (kompletter Inhalt + Evidence pro Aussage). Stop, auf Freigabe warten, nur Bestätigtes anlegen. **Init überschreibt nie Bestehendes** — existiert wider Erwarten doch Doku im Scope, gehört der Fall in den Sync- bzw. Review-Modus.
5. **Verify.** Laut shared.md (Links, Globs); zusätzlich: `git status` zeigt ausschließlich die neuen, bestätigten Dateien.

---
description: Bootstrap agent docs (CLAUDE.md + rules structure) in a repo or subtree that has none yet. Use ONLY when the user explicitly asks to initialize/set up agent docs — "init claude docs", "setup CLAUDE.md", "bootstrap agent docs", "leg mir eine CLAUDE.md an". Produces minimal, code-verified docs (no boilerplate, no empty scaffolds), approval-gated.
allowed-tools: Bash(git status *) Bash(git log *) Bash(ls *) Bash(find *)
---

# Init — Agent-Doku bootstrappen

Erzeugt das **Minimum** an Agent-Doku, das ein Audit überleben würde — nicht das Maximum, das beeindruckend aussieht. Jede Zeile muss den Qualitätsmaßstab bestehen, sonst gehört sie nicht in den Erstwurf.

**Zuerst lesen:** `${CLAUDE_SKILL_DIR}/../../references/shared.md` (Ground Rules, Vorschlags-Format, Verify, Anti-Patterns) und `${CLAUDE_SKILL_DIR}/../../references/style.md` (Qualitätsmaßstab — beim Init wichtiger als überall sonst).

## Grundsätze (zusätzlich zu den Ground Rules)

- **Nur Verifiziertes.** Jede Aussage stammt aus gelesenem Code/Config mit `file:line`-Evidence. Nichts aus Annahmen, nichts "was Projekte dieser Art üblicherweise haben".
- **Lieber 15 gute Zeilen als 60 generische.** Ziel Root-CLAUDE.md: ≤ ~40 Zeilen.
- **Keine leeren Gerüste.** Kein Rules-Verzeichnis ohne echte Regel, keine Platzhalter-Sektionen ("TODO: beschreiben"), keine Datei "für später".
- **Nichts dokumentieren, was Code/Verzeichnisnamen trivial zeigen.** `src/components` enthält Komponenten — das schreibt niemand auf.

## Workflow

1. **Abort-Check.** Existieren im Scope bereits `CLAUDE.md`/`AGENTS.md` oder ein Rules-Verzeichnis? → Stop mit Hinweis auf `/agent-docs:sync` bzw. `/agent-docs:audit`. Init überschreibt nie.
2. **Recon.** Repo-Realität erfassen — bei Monorepos parallel Subagenten je Workspace (Output-Format laut shared.md festnageln: nur non-obvious Findings mit `file:line`, keine Prosa):
   - Manifest + Tooling: `package.json` (Scripts, Workspaces, packageManager), Lockfile, Runtime-Versionen, Build-/Test-Setup, Linter/Formatter-Configs.
   - CI/Deploy: Workflows, Dockerfiles, Deploy-Skripte — was läuft wann, was darf nicht brechen.
   - Non-obvious Invarianten: Env-Handling, Codegen-Schritte, Side-Effect-Imports, Reihenfolge-Abhängigkeiten, überraschende Kopplungen, bekannte Stolperfallen (Kommentare wie "do not change").
   - Konvention im Umfeld: Wird im Ökosystem des Repos `AGENTS.md` statt `CLAUDE.md` erwartet? Im Zweifel CLAUDE.md; bei klaren Signalen den User fragen.
3. **Style-Gate.** Jeden Recon-Fund einzeln prüfen: Würde diese Zeile ein Audit nach style.md überleben (repo-spezifisch, non-obvious, actionable)? Was durchfällt, fliegt raus — auch wenn die Datei dadurch kurz wird. Kurz ist das Ziel.
4. **Draft.**
   - Root-`CLAUDE.md`: 1-Satz-Was, nicht-offensichtliche Befehle (nur die, deren Existenz/Wirkung man dem `scripts`-Block nicht ansieht), non-obvious Invarianten/Gotchas, Verweise auf Rules (falls vorhanden).
   - `.claude/rules/<thema>.md` nur, wenn mindestens **eine echte pfadgebundene Regel** existiert; Frontmatter-`paths:`-Glob sofort gegen reale Dateien prüfen (matcht, nicht too-broad, Test-/Lib-Pfade mitgedacht).
   - Monorepo: Package-CLAUDE.md nur für Workspaces mit **eigenen** non-obvious Regeln — niemals pro forma für jedes Package.
5. **Vorschlag + Approval.** Jede neue Datei als `**Create:**`-Block laut shared.md (kompletter Inhalt + Evidence pro Aussage). Stop, auf Freigabe warten, nur Bestätigtes anlegen.
6. **Verify.** Laut shared.md (Links, Globs); zusätzlich: `git status` zeigt ausschließlich die neuen, bestätigten Dateien.

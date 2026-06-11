---
description: Surgical post-session sync of agent docs (CLAUDE.md/AGENTS.md plus rules directories like `.claude/rules/**`), driven by the actual code diff. Use whenever code was touched in this session or branch, even if the user doesn't mention docs — and on "sync docs", "doku aktualisieren", "passen die rules noch?", "update CLAUDE.md". Approval-gated, file-line evidence, prefers deletion, never rewrites whole files.
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git merge-base *)
---

# Sync — surgical post-session update

Nur Stellen anfassen, die der tatsächliche Code-Diff berührt hat.

**Zuerst lesen:** `${CLAUDE_SKILL_DIR}/../../references/shared.md` (Scope, Ground Rules, Subagenten, Vorschlags-Format, Verify, Anti-Patterns) und `${CLAUDE_SKILL_DIR}/../../references/style.md` (Qualitätsmaßstab).

## Trigger-Gate (jeder Kandidat)

Ein Edit braucht **eines**:

1. **Factually wrong** oder **materially incomplete** zur aktuellen Code-Realität.
2. Inhalt ist durch die Session **redundant geworden** (Code obsolet, Konzept woanders besser dokumentiert, Selbstverständliches geworden) → **löschen**.

Plus immer: project-specific (nicht generisch), und der nächste Agent wäre ohne Fix misled/blocked oder müsste Müll lesen.

Sonst: **nicht anfassen.**

## Workflow

1. **Snapshot.** `git status --short` + `git diff --stat`. Default-Scope: Working Tree + Änderungen dieser Session; nennt der User im Aufruf einen Branch/Ref → Diff gegen `git merge-base <ref> HEAD` stattdessen. Wenn keine Code-Änderungen → "Nothing to sync." Stop.
2. **Doc-Discovery.** Parallel Subagenten (1 pro Bereich, Output-Format laut shared.md festnageln). Jeder Subagent bekommt die geänderten Code-Pfade + Auftrag:
   > *"Finde alle Stellen, die diese Pfade/Module/Funktionen/Konstanten nennen — in allen CLAUDE.md/AGENTS.md, im Rules-Verzeichnis, in Frontmatter-`paths:`-Blöcken und in Code-Kommentaren mit Doku-Refs. Datei + Zeile. Keine Fixes vorschlagen."*
3. **Filter.** Trigger-Gate auf jeden Kandidaten. Drop alles, was durchfällt.
4. **Vorschlag + Approval.** Blöcke im Vorschlags-Format laut shared.md. Stop, auf Freigabe warten, nur Bestätigtes anwenden.
5. **Verify.** Laut shared.md (alte Strings, Links, Globs).

## Sonderfall: Neue Komponenten/Exports in der Session

Wenn die Session neue geteilte Bausteine angelegt hat (Komponente, Hook, Export, Konstante), prüfen ob die kanonische Inventar-Stelle (z.B. Package-CLAUDE.md, Subpath-Export-Liste) sie kennen muss — **eine** Zeile am kanonischen Ort, kein Eintrag in mehreren Dateien.

---
description: Smart everyday maintenance for agent docs (CLAUDE.md/AGENTS.md plus rules directories like `.claude/rules/**`). Auto-routes between init (no docs yet), diff-driven sync (code changed), and quick/full review (no diff or user asks "alles anschauen"). Use whenever code was touched in this session or branch, even if the user doesn't mention docs — and on "sync docs", "doku aktualisieren", "passen die rules noch?", "update CLAUDE.md", "leg mir eine CLAUDE.md an", "setup CLAUDE.md", "bootstrap agent docs", "init claude docs". Approval-gated, file-line evidence, prefers deletion, never rewrites whole files.
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git merge-base *) Bash(git ls-files *) Bash(ls *) Bash(find *)
---

# Sync — smart maintenance router

Alltags-Einstieg für Agent-Doku. Erst entscheiden, welcher Modus passt; dann nur den kleinsten passenden Workflow ausführen.

**Zuerst lesen:** `${CLAUDE_SKILL_DIR}/../../references/shared.md` (Scope, Ground Rules, Subagenten, Vorschlags-Format, Verify, Anti-Patterns) und `${CLAUDE_SKILL_DIR}/../../references/style.md` (Qualitätsmaßstab).

## Routing-Gate

Vor inhaltlicher Arbeit einen knappen Snapshot ziehen: `git status --short`, `git diff --stat` und `git ls-files` für `CLAUDE.md`, `AGENTS.md`, `.claude/rules/**` bzw. den vom User genannten Subtree.

1. **Keine Agent-Doku im Scope** → Init-Modus: Workflow aus `${CLAUDE_SKILL_DIR}/../../references/init.md` ausführen. Nicht erst auditieren, nicht leer scaffolden.
2. **Code-Änderungen vorhanden** → Sync-Modus: diff-getriebener Workflow unten. Wenn der User zusätzlich "alles", "komplett" oder "audit" verlangt, zuerst Sync-Kandidaten für den Diff liefern; danach einen Quick-Review der betroffenen Doku vorschlagen.
3. **Keine Code-Änderungen, aber Doku vorhanden** → Review-Modus: `quick`-Audit-Workflow aus `${CLAUDE_SKILL_DIR}/../audit/SKILL.md` ausführen. Full Audit nur, wenn der User explizit "voll", "komplett", "scored" oder "alles anschauen" verlangt.

Routing kurz begründen (ein Satz), dann in den gewählten Modus wechseln. Approval-Gate und Verify bleiben immer aus `shared.md` verbindlich.

## Trigger-Gate (jeder Kandidat)

Ein Edit braucht **eines**:

1. **Factually wrong** oder **materially incomplete** zur aktuellen Code-Realität.
2. Inhalt ist durch die Session **redundant geworden** (Code obsolet, Konzept woanders besser dokumentiert, Selbstverständliches geworden) → **löschen**.

Plus immer: project-specific (nicht generisch), und der nächste Agent wäre ohne Fix misled/blocked oder müsste Müll lesen.

Sonst: **nicht anfassen.**

## Workflow

1. **Snapshot.** `git status --short` + `git diff --stat`. Default-Scope: Working Tree + Änderungen dieser Session; nennt der User im Aufruf einen Branch/Ref → Diff gegen `git merge-base <ref> HEAD` stattdessen.
2. **Doc-Discovery.** Parallel Subagenten (1 pro Bereich, Output-Format laut shared.md festnageln). Jeder Subagent bekommt die geänderten Code-Pfade + Auftrag:
   > *"Finde alle Stellen, die diese Pfade/Module/Funktionen/Konstanten nennen — in allen CLAUDE.md/AGENTS.md, im Rules-Verzeichnis, in Frontmatter-`paths:`-Blöcken und in Code-Kommentaren mit Doku-Refs. Datei + Zeile. Keine Fixes vorschlagen."*
3. **Filter.** Trigger-Gate auf jeden Kandidaten. Drop alles, was durchfällt.
4. **Vorschlag + Approval.** Blöcke im Vorschlags-Format laut shared.md. Stop, auf Freigabe warten, nur Bestätigtes anwenden.
5. **Verify.** Laut shared.md (alte Strings, Links, Globs).

## Sonderfall: Neue Komponenten/Exports in der Session

Wenn die Session neue geteilte Bausteine angelegt hat (Komponente, Hook, Export, Konstante), prüfen ob die kanonische Inventar-Stelle (z.B. Package-CLAUDE.md, Subpath-Export-Liste) sie kennen muss — **eine** Zeile am kanonischen Ort, kein Eintrag in mehreren Dateien.

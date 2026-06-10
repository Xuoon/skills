---
description: Dedup and deletion pass over agent docs (CLAUDE.md/AGENTS.md plus rules directories). Use ONLY when the user explicitly asks to declutter, dedupe or shrink docs — "was kann weg", "nichts doppelt dokumentieren", "docs entschlacken", "prune docs" — or as a counter-check right after an audit that added content. Never trigger this just because docs look long. Approval-gated, file-line evidence, deletion-first. Optional arg — subtree path.
argument-hint: "[pfad]"
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *)
---

# Prune — Dedup & Löschen

Der Prune-Sweep aus dem Audit als schneller Standalone-Modus. Läuft nur auf expliziten Auftrag.

**Zuerst lesen:** `${CLAUDE_SKILL_DIR}/../../references/shared.md` (Scope, Ground Rules, Subagenten, Vorschlags-Format, Verify, Anti-Patterns), `${CLAUDE_SKILL_DIR}/../../references/style.md` (Qualitätsmaßstab) und `${CLAUDE_SKILL_DIR}/../../references/prune-sweep.md` (die Prozedur).

## Argumente

`$ARGUMENTS` — optional: existiert das Token als Pfad im Repo → Subtree-Fokus. Kanonische Gegenstellen und Cross-Refs außerhalb des Subtrees trotzdem prüfen, sonst sind Duplikate unsichtbar. Leer → alle Scopes.

## Workflow

1. **Discovery.** Alle Scope-Files laut shared.md globben (bzw. Subtree laut Argument). Docs vollständig lesen — bei vielen Files Subagenten je 3–5 Files (Output-Format laut shared.md festnageln).
2. **Prune-Sweep** laut prune-sweep.md, Schritte 1–5.
3. **Vorschläge** im Format laut shared.md; ganze-Datei-Löschungen mit Verbleib-Nachweis pro Information.
4. **Approval-Gate.** Stop, auf User-Freigabe warten. Nur Bestätigtes anwenden.
5. **Verify.** Laut shared.md (alte Strings, Links, Globs).

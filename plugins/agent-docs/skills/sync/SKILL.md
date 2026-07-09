---
description: >
  Everyday agent-docs router (init / diff-sync / prune-first / review).
  Delete-first, asymmetric add-gate, mini-prune on growth.
  Triggers: code changed, "sync docs", "weniger doku", "prune", bootstrap CLAUDE.md.
argument-hint: "[main|branch|prune] [pfad]"
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git merge-base *) Bash(git ls-files *) Bash(ls *) Bash(find *) Bash(wc *)
---

# Sync — smart maintenance router

Alltags-Einstieg für Agent-Doku. Kleinster passender Modus. **Sync ist kein Freifahrtschein zum Aufblasen.**

**Zuerst lesen:**

1. `${CLAUDE_SKILL_DIR}/../../references/shared.md` — Scope, asymmetrisches Gate, Format, Verify, Anti-Patterns  
2. `${CLAUDE_SKILL_DIR}/../../references/style.md` — was rein / was raus, Größenrichtwerte  
3. Bei jedem Add oder User-Wunsch „dünner/prune“: `${CLAUDE_SKILL_DIR}/../../references/prune-sweep.md`

## Argumente (`$ARGUMENTS`)

```text
$ARGUMENTS
```

Alle optional, whitespace-getrennt, Reihenfolge egal:

| Token | Bedeutung |
| --- | --- |
| `prune` / `dünner` / `weniger` | **Prune-first** erzwingen (auch mit Code-Diff) |
| `review` / `quick` | Review-Modus → Audit `quick` (auch ohne Diff) |
| `full` / `audit` / `alles` / `komplett` | Nach Diff-Sync optional Full-/Quick-Review der betroffenen Docs vorschlagen; ohne Diff → Audit full bzw. quick je nach Wort |
| Git-Ref (`main`, `origin/main`, Tag, SHA-ähnlich) | Diff-Basis = `merge-base <ref> HEAD` statt nur Working Tree |
| Pfad (`apps/dash`, `.claude/rules/…`) | Doc-/Discovery-Scope auf Subtree; Cross-Refs außerhalb trotzdem prüfen |
| Freitext | Routing-Hint („bootstrap“, „init“, …) |

**Beispiele:**

```text
/agent-docs:sync                      → Auto-Route (Init | Diff-Sync | Review)
/agent-docs:sync prune                → nur dünner (delete-first)
/agent-docs:sync main                 → Diff gegen main
/agent-docs:sync prune apps/dash      → Prune nur Dash-Docs
/agent-docs:sync origin/main packages/backend
```

Mode + Scope + Diff-Basis in **einem Satz** festnageln, dann Routing-Gate.

## Routing-Gate

Snapshot: `git status --short`, `git diff --stat` (ggf. gegen Ref aus Args), `git ls-files` für `CLAUDE.md`/`AGENTS.md`/Rules (oder Arg-Subtree).

| Situation | Modus |
| --- | --- |
| Keine Agent-Doku im Scope | **Init** → `${CLAUDE_SKILL_DIR}/../../references/init.md` |
| Args `prune`/`dünner`/`weniger` | **Prune-first Sync**: prune-sweep als Hauptpass; Adds nur mit Add-Gate |
| Code-Diff / Session-Code-Änderungen | **Sync** (unten); Diff-Basis aus Ref-Arg wenn gesetzt |
| Args `review`/`quick` oder kein Diff + User will prüfen | **Review** → Audit `quick` (`../audit/SKILL.md`) |
| Args `full`/`alles`/`komplett` ohne Diff | **Review** → Audit full |
| Code-Diff **und** `full`/`audit`/`alles` | Zuerst Sync-Kandidaten zum Diff; danach Review der **betroffenen** Dateien vorschlagen |

Routing in **einem Satz** begründen, dann ausführen. Approval + Verify aus `shared.md` immer verbindlich.

## Asymmetrisches Gate (Kurzform — Details shared.md)

- **DELETE/Kürzen:** niedrig — stale, Duplikat, generisch, Implementation-Detail, Historie.  
- **ADD:** hoch — agent-blocking **und** non-obvious **und** single home **und** ≤3 Zeilen **und** Netto-Budget (Add ⇒ Prune-Mitvorschlag oder Ausnahmebegründung).  
- Unsicher bei ADD → **nicht** vorschlagen. Unsicher bei klarem Müll → **löschen** vorschlagen.

## Sync-Workflow (Diff-getrieben)

1. **Snapshot.** Working Tree + Session; User-Ref → Diff gegen `merge-base <ref> HEAD`.  
   Optional: `wc -l` auf betroffene Doc-Files als Baseline.

2. **Doc-Discovery.** Parallel Subagenten (1 pro Bereich). Geänderte Code-Pfade + **fester** Auftrag:

   > Finde in CLAUDE.md/AGENTS.md, Rules, Frontmatter-`paths:`, Code-Doku-Refs:
   > (A) Stellen die **falsch/stale** zum Diff sind  
   > (B) Stellen die durch den Diff **redundant** werden (löschen)  
   > (C) **Nur wenn** agent-blocking und non-obvious: materielle Lücken  
   > Output strukturiert: `{file,line,kind:wrong|stale|redundant|missing-blocking,evidence}`.  
   > Keine Fixes. Keine „nice to have“-Lücken.

3. **Filter.** Jeden Treffer durchs asymmetrische Gate. Drop: nice-to-have, Inventar, UI-Chrome, Implementation-Spec der frischen Feature-Arbeit, spekulative Completeness.

4. **Mini-Prune (Pflicht wenn irgendein ADD übrig ist).**  
   Kurzer prune-sweep auf **dieselben** Dateien + offensichtliche Cross-Duplikate des Themas. Mindestens ein Delete/Shorten-Kandidat im Paket **oder** schriftlich: warum Netto-Wachstum unvermeidlich (neue Domain-Invariante).

5. **Vorschlag + Approval.** Blöcke laut shared.md — **Deletes zuerst**, dann Adds. `Netto:` schätzen. Stop, warten, nur Bestätigtes applyen.

6. **Verify.** shared.md inkl. **Δ lines** melden. Reines Wachstum ohne genehmigte Ausnahme im Report markieren.

## Sonderfälle

### Neue shared Bausteine (Komponente/Hook/Export/Konstante)

Eine Zeile am **kanonischen** Inventar-Ort (Package-CLAUDE oder bestehende Domain-Rule) — **nur** wenn „nutze X nicht Y“ agent-blocking ist. Kein Eintrag in mehreren Dateien. Keine Prop-Listen.

### Frisch gebautes Feature

Sync updated **Verträge** (Lifecycle, Security, kanonischer Helper), **nicht** die Implementierungsbeschreibung (Algorithmen, Cache-Pads, Komponenten-Baum). Wenn der Code die Wahrheit trägt → **0 Doc-Zeilen** ist ein valides Ergebnis.

### „Nichts zu tun“

Valides und **erwünschtes** Outcome. Melden: `Sync: 0 candidates (gate).` Nicht erfinden.

## Anti-Patterns (Sync-spezifisch)

- Nach UI-Arbeit die Rule um Chrome/Prefetch/Debounce erweitern.  
- Overview und Rule gleichzeitig mit demselben Fakt füttern.  
- Neue Rule-Datei für <15 exklusive Zeilen statt Merge.  
- Whole-file rewrite zum Erweitern.  
- Approval umgehen („user said go go go“ auf Code ≠ Blankoscheck für Doc-Aufblasen; Doc-Edits bleiben approval-gated außer User hat **explizit** Doc-Apply freigegeben).

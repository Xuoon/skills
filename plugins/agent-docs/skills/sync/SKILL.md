---
description: >
  Hält die Agent-Doku (CLAUDE.md/AGENTS.md, .claude/rules) am Code — wählt selbst den
  kleinsten passenden Modus: neu anlegen wenn keine da ist, sonst Diff-Sync nach
  Code-Änderungen, kürzen oder prüfen. Löschen-bevorzugt, strenges Add-Gate; 0 Änderungen
  ist ein gültiges Ergebnis. Standard nur Vorschlag, Schreiben erst mit `--anwenden`.
  AUSLÖSER: Code geändert, "Doku syncen", "kürzen"/"weniger Doku", oder ein Repo ohne
  CLAUDE.md, das eine braucht. NICHT wenn die Änderung kein dokumentiertes Verhalten berührt.
argument-hint: "[--kürzen | --prüfen] [--anwenden]"
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git merge-base *) Bash(git ls-files *) Bash(ls *) Bash(find *) Bash(wc *)
---

# Sync — smart maintenance router

Alltags-Einstieg für Agent-Doku. Kleinster passender Modus. **Sync ist kein Freifahrtschein zum Aufblasen.**

**Zuerst lesen:**

1. `${CLAUDE_SKILL_DIR}/../../references/shared.md` — Scope, asymmetrisches Gate, Format, Verify, Anti-Patterns  
2. `${CLAUDE_SKILL_DIR}/../../references/style.md` — was rein / was raus, Größenrichtwerte  
3. Bei jedem Add oder User-Wunsch „dünner/prune“: `${CLAUDE_SKILL_DIR}/../../references/prune-sweep.md`

## Argumente (`$ARGUMENTS`)

Alle optional:

| Flag | Bedeutung |
| --- | --- |
| `--kürzen` | Delete-first als Hauptpass erzwingen (auch mit Code-Diff) |
| `--prüfen` | Statt syncen prüfen → Audit `--schnell`; „gründlich"/„full" im Fließtext eskaliert auf Full-Audit |
| `--anwenden` | Vorschlag direkt schreiben. **Ohne dieses Flag wird nichts geändert** — nur analysiert und vorgeschlagen |

Ohne Modus-Flag: **Auto-Route** (neu anlegen, wenn keine Doku da ist; sonst Diff-Sync). Scope ist immer das aktuelle Verzeichnis. Diff-Basis oder Subtree bei Bedarf im **Fließtext** nennen („gegen main", „nur apps/dash"); ohne Angabe = Working Tree.

**Beispiele:**

```text
/agent-docs:sync                       → Auto-Route, nur Vorschlag
/agent-docs:sync --anwenden            → Vorschlag + direkt schreiben
/agent-docs:sync --kürzen              → nur dünner (delete-first), Vorschlag
/agent-docs:sync --prüfen              → prüfen statt syncen
/agent-docs:sync --kürzen  nur apps/dash gegen main
```

Modus + (freeform) Diff-Basis/Subtree in **einem Satz** festnageln, dann Routing-Gate.

## Routing-Gate

Snapshot: `git status --short`, `git diff --stat` (ggf. gegen freeform Ref), `git ls-files` für `CLAUDE.md`/`AGENTS.md`/Rules (oder freeform Subtree).

| Situation | Modus |
| --- | --- |
| Keine Agent-Doku im Scope | **Init** → `${CLAUDE_SKILL_DIR}/../../references/init.md` |
| `--kürzen` | **Prune-first Sync**: prune-sweep als Hauptpass; Adds nur mit Add-Gate |
| Code-Diff / Session-Code-Änderungen | **Sync** (unten); Diff-Basis aus freeform Ref wenn genannt |
| `--prüfen` (oder kein Diff + User will prüfen) | **Review** → Audit `--schnell`; „gründlich"/„full" → Full-Audit (`../audit/SKILL.md`) |
| Code-Diff **und** `--prüfen` | Zuerst Sync-Kandidaten zum Diff; danach Review der **betroffenen** Dateien vorschlagen |

Routing in **einem Satz** begründen, dann ausführen. Standard nur Vorschlag; Schreiben/Verify nur mit `--anwenden` (siehe `shared.md`).

## Asymmetrisches Gate

Kanonisch in `shared.md`. Essenz: DELETE billig (stale, Duplikat, generisch, Impl-Detail, Historie) — ADD teuer (agent-blocking ∧ non-obvious ∧ single home ∧ ≤3 Zeilen ∧ Netto-Budget). Unsicher → ADD nicht vorschlagen, klaren Müll löschen.

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

5. **Vorschlag.** Blöcke laut shared.md — **Deletes zuerst**, dann Adds. `Netto:` schätzen. **Ohne `--anwenden` endet der Lauf hier — kein Edit.**

6. **Anwenden + Verify (nur mit `--anwenden`).** Bestätigte Blöcke schreiben, dann Verify laut shared.md inkl. **Δ lines** melden. Reines Wachstum ohne genehmigte Ausnahme im Report markieren.

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

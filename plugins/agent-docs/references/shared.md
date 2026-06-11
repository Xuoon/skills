# Shared — Scope, Ground Rules, Vorschlags-Format, Verify (alle Modi)

Wird von jedem agent-docs-Skill zuerst geladen. Qualitätsmaßstab für alle Inhalte: [style.md](style.md).

## Scope (alle Modi)

- Alle `CLAUDE.md`/`AGENTS.md` (Root, `.claude/`, `apps/*`, `packages/*` bzw. die Workspace-Struktur des Repos).
- Alle `.md` unter dem Rules-Verzeichnis des Repos (üblich: `.claude/rules/**`).
- Frontmatter `paths:`-Globs in Rules-Files — sie steuern die **Auto-Injection** der Rule beim Editieren matchender Dateien; too-narrow heißt "Regel fehlt genau dann, wenn sie gebraucht wird". Typische Lücke: Test-Suiten und Lib-/Helper-Pfade außerhalb der Feature-Verzeichnisse.
- Code-Kommentare mit Doku-Refs (`grep -rn "\.claude/rules\|CLAUDE\.md\|AGENTS\.md"` über die Source-Verzeichnisse).
- Excludieren: `node_modules/**`, `.turbo/**`, `dist/**`, `build/**`, `.next/**`, `coverage/**`, `.git/**`.
- Nennt der User im Aufruf einen Subtree-Pfad → Scope darauf einschränken; kanonische Gegenstellen und Cross-Refs außerhalb trotzdem prüfen, sonst sind Duplikate unsichtbar.

## Ground Rules (alle Modi)

- **Kein Silent-Fix.** Vorschlag immer vor Edit, Approval-Gate.
- **Evidence Pflicht.** Jeder Claim mit `file:line` in Doku UND Code. Bei Unsicherheit `needs verification` statt raten.
- **Löschen > umschreiben > ergänzen.** Kürzere Doku ist bessere Doku.
- **One Source of Truth.** Jede Mechanik hat genau eine kanonische Stelle; andere Dateien verlinken mit maximal einem Pointer-Satz. Niemals dieselbe Mechanik zweimal ausführen.
- **Repo-spezifisch, non-obvious.** Keine Generics, kein Best-Practice-Boilerplate, keine Code-Paraphrase. Details in [style.md](style.md).
- **Voice/Sprache/Stil der Datei matchen** (DE/EN, Bullet/Tabelle).
- **Future Agent als Maßstab.** Ohne Fix wäre der nächste Agent misled/blocked oder müsste Müll lesen.
- **Nebenbefunde separat.** Code-Befunde, die beim Doku-Check auffallen (Bugs, stale Code-Kommentare), als eigene "Nebenbefunde"-Liste an den Report hängen — nicht fixen, nicht als Doku-Issue zählen.

## Subagenten (Sync-Discovery + Audit)

Parallel gründliche Subagenten einsetzen (Sync: 1 pro Bereich; Audit: ~1 pro 3–5 Files; stärkstes verfügbares Modell) statt Excerpt-only-Suche. Output-Format im Subagenten-Prompt **festnageln**: nur strukturierte Daten, kein Fließtext-Bericht; verified-Claims nur als Gesamtzahl pro Datei, ausführlich nur Abweichungen; am Ende 1-Satz-Einschätzung pro Datei. Sonst liefern Agenten Prosa, die sich nicht aggregieren lässt.

## Vorschlags-Format + Approval (alle Modi)

Pro Kandidat **genau** dieser Block:

````markdown
### <doc-pfad>
**Why:** <ein Satz: was ist falsch/fehlt/verzichtbar>
**Evidence:** <pfad:zeile oder diff>

```diff
- <alt>
+ <neu>
```
````

Ganze-Datei-Löschungen: statt Diff `**Delete:** <pfad>` plus Nachweis, wo jede verbleibende Information liegt (Datei + Zeile).

Neue Dateien (z. B. Init): statt Diff `**Create:** <pfad>` plus kompletter Datei-Inhalt als Codeblock; Evidence = die Code-Stellen, die jede Aussage belegen.

Danach: **Stop. Auf User-Freigabe warten. Nur bestätigte Blöcke anwenden.**

## Verify (nach jedem Apply)

1. Grep nach alten Strings/Pfaden in geänderten Files → 0 Treffer.
2. Alle relativen Markdown-Links in geänderten Files resolven → 0 broken.
3. Neue/geänderte Frontmatter-Globs gegen reale Dateien prüfen → jeder Glob matcht.
4. Audit (Vollmodus): betroffene Files re-scoren; bei Grade-Drop oder Broken-Link → revert + re-propose.
5. Report: `N Dateien, 0 broken links, 0 stale refs.`

## Anti-Patterns (= sofort abbrechen)

- Whole-file rewrites "while we're here".
- Neue Sektionen, die keiner verlangt hat; Features dokumentieren, die nicht existieren.
- Info zwischen Overview-Dateien und Rules duplizieren statt verlinken.
- Code paraphrasieren statt non-obvious Kontext hinzufügen.
- Redundante/generische/selbstverständliche Bullets stehen lassen, weil "schadet ja nicht".
- Hohe Scores als Belohnung für Knappheit bei kritischen Lücken; niedrige Scores als Strafe für korrekte Minimal-Docs.
- Cross-Refs auf unbestätigte Files; Issues ohne `file:line`-Evidence.

# Shared — Scope, Ground Rules, Vorschlags-Format, Verify (alle Modi)

Wird von jedem agent-docs-Skill zuerst geladen. Qualitätsmaßstab: [style.md](style.md). Gegenrichtung (Löschen/Dedup): [prune-sweep.md](prune-sweep.md).

## Scope (alle Modi)

- Kanonische Agent-Doku im Root und in Apps/Packages erkennen (`AGENTS.md`, `CLAUDE.md` oder belegte Client-Konvention); `AGENTS.override.md` einbeziehen, weil es bei Codex ein gleichnamiges `AGENTS.md` im selben Verzeichnis verdrängt.
- Persönliche oder gitignorierte Overrides (`CLAUDE.local.md`, `.claude.local.md`) zusätzlich per direktem Existenzcheck suchen; Inhalte nie in geteilte Docs spiegeln.
- Client-spezifische Rules-Verzeichnisse nur einbeziehen, wenn das Repo sie tatsächlich verwendet.
- Imports, Symlinks und reine Kompatibilitäts-Pointer bis zur kanonischen Datei auflösen; Pointer nicht als zweite Inhaltsquelle behandeln.
- Für jeden betroffenen Subtree die **tatsächlich aktive Anweisungskette** nach belegter Client-Semantik prüfen. „Nächste Datei gewinnt" nicht pauschal auf Clients übertragen, die Eltern und Kinddateien zusammenführen.
- Formatfelder wie Frontmatter-`paths:` nur prüfen, wenn der erkannte Client ihnen nachweislich Auto-Injection-Semantik gibt.
- Code-Kommentare mit Verweisen auf die vorhandene Agent-Doku und Rules einbeziehen.
- Excludieren: `node_modules/**`, `.turbo/**`, `dist/**`, `build/**`, `.next/**`, `coverage/**`, `.git/**`.
- User nennt Subtree → Scope darauf einschränken; kanonische Gegenstellen und Cross-Refs **außerhalb** trotzdem prüfen (sonst Duplikate unsichtbar).

## Ground Rules (alle Modi)

- **Kein Silent-Fix, kein Auto-Apply.** Standard ist **nur der Vorschlag**; geschrieben wird erst mit `--fix` (oder auf ausdrückliches OK). Die Kontrolle bleibt immer beim Nutzer.
- **Evidence Pflicht.** Jeder Claim mit `file:line` in Doku **und** Code. Unsicher → `needs verification`, nicht raten.
- **Löschen > umschreiben > ergänzen.** Kürzere Doku ist bessere Doku. Mehr Zeilen = mehr Drift- und Fehlerfläche.
- **One Source of Truth.** Jede Mechanik/Zahl/Invariante **eine** kanonische Stelle; woanders max. ein Pointer-Satz mit Link. Niemals dieselbe Mechanik zweimal ausführen.
- **Repo-spezifisch, non-obvious.** Keine Generics, kein Best-Practice-Boilerplate, keine Code-Paraphrase. Details: [style.md](style.md).
- **Code owns implementation detail.** Prefetch-Pads, Debounce-ms, UI-Chrome-Layouts, Dateibaum, Prop-Listen — gehören in den Code, nicht in Rules. Docs halten **Verträge** (Invarianten, Lifecycle, Security, „nutze X nicht Y“).
- **Prosa ist keine Enforcement.** Formatierung und mechanisch prüfbare Stilregeln gehören in Formatter/Lint/CI; Agent-Doku nennt nur nicht offensichtliche Ausnahmen oder den exakten Prüfpfad.
- **Voice/Sprache der Datei matchen** (DE/EN, Bullet/Tabelle).
- **Future Agent als Maßstab.** Ohne Fix: misled/blocked **oder** muss Müll lesen (beides zählt).
- **Nebenbefunde separat.** Code-Bugs aus dem Doku-Lauf: eigene Liste, nicht als Doku-Issue fixen.

## Asymmetrisches Edit-Gate (ADD vs DELETE)

Jeder Kandidat muss durch das passende Gate. **Default bei Unsicherheit: nicht anfassen** (bei ADD) bzw. **löschen vorschlagen** (bei klarem Müll).

### DELETE / Kürzen — niedriger Balken (bevorzugt)

Ausreichend **eines** von:

1. Stale/wrong zur Code-Realität.
2. Duplikat (volle Mechanik woanders; hier kein reiner Pointer).
3. Generisch, selbstverständlich, aus Verzeichnisnamen trivial.
4. Drift-anfälliges Implementation-Detail (Zahlen/Pads/UI-Chrome die der Code allein trägt).
5. Historien-Sprache („früher…“, „nicht mehr…“) ohne aktuelle Invariante.

Lösch-Vorschläge brauchen Evidence, **aber keine** „would agent break?“-Angst — weniger Tokens reduzieren Fehler.

### ADD / Erweitern — hoher Balken (selten)

**Alle** müssen gelten:

1. **Agent-blocking:** Ohne die Zeile würde der nächste Agent eine **falsche** Änderung machen (Security, Lifecycle, Naming, kanonischer Helper) — nicht nur „wüsste es schneller“.
2. **Non-obvious:** Steht nicht trivial im Code/Dateinamen/Typ.
3. **Single home:** Kanonischer Ort klar; keine zweite Datei bekommt denselben Fakt.
4. **Minimal:** ≤ **3 Zeilen** Draft pro Konzept (Audit: ≤ 10 nur bei undocumented-critical). Keine neuen Sektionen „für Vollständigkeit“.
5. **Netto-Budget:** Wenn die Session Docs **verlängert**, muss im selben Vorschlagspaket mindestens ein gleichwertiger Prune-Kandidat mitlaufen **oder** begründet werden, warum Netto-Wachstum unvermeidlich ist (neue Domain mit echten Invarianten).

### Verbieten (sofort droppen)

- Feature, das gerade gebaut wurde, als Tutorial/Implementierungsbeschreibung in Rules schreiben.
- Dieselbe Info in Overview **und** Rule **und** Package-CLAUDE.
- Neue Rule-Datei, solange der Inhalt in eine existierende Domain-Rule/Overview passt (≤ ~15 exklusive Zeilen → mergen, nicht neue Datei).
- Inventar-Listen (Exports, Ordnerbäume, alle Placeholder-Keys, alle Props).
- Key-References-Wäsche, die Root-Index + `paths:` schon abdecken.

## Discovery-Ausführung

Falls Subagenten verfügbar sind parallel und gründlich arbeiten (Sync: 1 pro Bereich; Audit: ~1 pro 3–5 Files), sonst dieselben Aufträge seriell abarbeiten. Output-Format **festnageln**: nur strukturierte Daten, kein Fließtext; verified nur als Count; Abweichungen ausführlich; 1-Satz-Einschätzung pro Datei.

## Vorschlags-Format + Approval

Pro Kandidat **genau** dieser Block — **Delete-Blöcke vor Add-Blöcken** listen:

````markdown
### <doc-pfad>
**Why:** <ein Satz: falsch / fehlt agent-blocking / verzichtbar>
**Gate:** delete | add | rewrite-prune
**Evidence:** <pfad:zeile oder diff>
**Netto:** <−N | +N | 0 Zeilen Schätzung>

```diff
- <alt>
+ <neu>
```
````

Ganze-Datei-Löschung: `**Delete:** <pfad>` + Nachweis, wo jede Info verbleibt (Datei + Zeile).

Neue Datei: `**Create:** <pfad>` + voller Inhalt; Evidence pro Aussage; **Gate: add** nur wenn Merge in bestehende Datei unzumutbar.

Whole-file rewrite: nur **`Gate: rewrite-prune`** (Netto kürzer, gleiche Fakten). **Verboten:** rewrite zum Aufblasen oder „while we're here“.

Danach: **ohne `--fix` ist hier Schluss — kein Edit.** Mit `--fix` (oder ausdrücklichem OK) die Blöcke direkt schreiben.

## Verify (nach jedem Apply mit `--fix`)

1. Grep alter Strings/Pfade in geänderten Files → 0.
2. Relative Markdown-Links in geänderten Files → 0 broken.
3. Neue/geänderte `paths:`-Globs matchen reale Dateien.
4. **Netto-Zeilen:** `wc -l` vor/nach der Apply-Menge melden. Reines Wachstum ohne genehmigte Ausnahme → auffällig machen (nicht stillschweigend ok).
5. Audit-Vollmodus: betroffene Files re-scoren; Grade-Drop oder Broken-Link → revert + re-propose.
6. Report: `N Dateien, Δ lines: ±X, 0 broken links, 0 stale refs.`

## Anti-Patterns (= sofort abbrechen / Kandidat droppen)

- Neue Sektionen, die niemand verlangt hat; spekulative Vollständigkeit.
- „Schadet ja nicht"-Bullets stehen lassen.
- Hohe Scores für knappe Docs mit echten Security-Lücken **oder** für fette korrekte Novellen.

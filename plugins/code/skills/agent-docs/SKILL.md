---
name: agent-docs
description: >
  Hält die Agent-Doku (CLAUDE.md/AGENTS.md, .claude/rules) und eine vorhandene CHANGELOG.md
  am Code: legt sie an, wenn keine da ist, sonst Diff-Sync nach Code-Änderungen. Löschen vor
  Ergänzen, strenges Gate für neue Zeilen; 0 Änderungen ist ein gültiges Ergebnis. Standard ist
  nur ein Vorschlag, geschrieben wird erst mit `--fix`. AUSLÖSER: Code geändert, "Doku syncen",
  "Changelog schreiben/anpassen", "kürzen"/"weniger Doku", oder ein Repo ohne Agent-Doku, das
  eine braucht. NICHT, wenn die Änderung kein dokumentiertes Verhalten berührt.
  Von selbst immer nur der Vorschlagsmodus, `--audit` und `--fix` nie ungefragt.
argument-hint: "[--audit] [--fix]"
---

# agent-docs: Doku am Code halten

Kleinster passender Modus. Der Skill macht Doku richtiger oder kürzer, nicht länger.

Zuerst lesen:

1. `references/shared.md`: Scope, Gate, Vorschlagsformat, Verify
2. `references/style.md`: was hineingehört, was nicht, Größenrichtwerte
3. Bei jedem Add oder Wunsch nach „dünner": `references/prune-sweep.md`

## Argumente aus der Nutzeranfrage

| Flag | Bedeutung |
| --- | --- |
| *(ohne Flag)* | Sync: Doku gegen den Code-Diff prüfen, Vorschlag zeigen, nichts schreiben |
| `--fix` | Vorschlag direkt schreiben |
| `--audit` | Audit: voller Report mit Scoring, Coverage, Prune-Sweep und Link-Check, nichts schreiben |
| `--audit --fix` | Audit und gefundene Fixes direkt schreiben |

Scope ist das aktuelle Verzeichnis. Diff-Basis oder Subtree nennt der Nutzer bei Bedarf im Fließtext („gegen main", „nur apps/dash"); ohne Angabe gilt der Working Tree. Modus und Diff-Basis in einem Satz festhalten, dann loslegen.

## Ausführung

Der Skill läuft im Hauptthread. Einen Diff, der sich mit ein paar Lese- und Suchaufrufen prüfen lässt, nicht delegieren. Subagenten nur beim Audit oder bei einem Diff über viele Bereiche: dann je Bereich ein Explore-Subagent, der sucht, liest und nur strukturierte Funde zurückgibt. Bewertet, gefiltert und formuliert wird immer im Hauptthread.

## Routing

Snapshot: `git status --short`, `git diff --stat` (gegebenenfalls gegen die genannte Ref), `git ls-files` für vorhandene Agent-Doku und client-spezifische Rules; `AGENTS.override.md` sowie gitignorierte `CLAUDE.local.md`/`.claude.local.md` zusätzlich direkt auf Existenz prüfen.

| Situation | Modus |
| --- | --- |
| Keine Agent-Doku im Scope | Init, siehe `references/init.md` |
| `--audit` | Audit (unten) |
| sonst | Sync (unten) |

## Sync (Standard)

1. **Snapshot.** Working Tree und Session; bei genannter Ref der Diff gegen `merge-base <ref> HEAD`. Optional `wc -l` auf die betroffenen Doku-Dateien als Baseline.
2. **Doku lesen.** Zu den geänderten Code-Pfaden die Agent-Doku, die client-spezifischen Rules und Code-Kommentare mit Doku-Verweisen durchgehen und sammeln: Stellen, die durch den Diff falsch oder veraltet sind, und Stellen, die durch den Diff überflüssig werden. Je Fund `{file, line, kind: wrong|stale|redundant, evidence}`.
3. **Filtern.** Jeden Fund durchs Gate aus `shared.md`. Raus fallen Nice-to-have, Inventar, UI-Chrome, die Implementierung der frischen Feature-Arbeit und spekulative Vollständigkeit. Eine Lücke zählt nur, wenn der nächste Agent ohne die Zeile etwas Falsches tun würde und es nicht aus dem Code ersichtlich ist.
4. **Mini-Prune, sobald ein Add übrig ist.** Kurzer Prune-Sweep auf dieselben Dateien und offensichtliche Duplikate des Themas. Mindestens ein Kandidat zum Löschen oder Kürzen im Paket, oder schriftlich, warum Netto-Wachstum unvermeidlich ist (neue Domain-Invariante).
5. **Vorschlag.** Blöcke laut `shared.md`, Deletes vor Adds, `Netto:` schätzen. Ohne `--fix` endet der Lauf hier.
6. **Anwenden und prüfen, nur mit `--fix`.** Bestätigte Blöcke schreiben, dann Verify laut `shared.md` samt Δ Zeilen. Reines Wachstum ohne genehmigte Ausnahme im Report markieren.

## Changelog

Gibt es im Scope eine `CHANGELOG.md` und berührt der Diff etwas, das ein Nutzer merkt, gehört sie ins selbe Paket. Ohne vorhandene Datei wird keine angelegt.

Der Changelog ist für Endnutzer, nicht für Entwickler. Er beantwortet eine Frage: Was ist neu, was hat sich geändert, was ist weg.

Draußen bleibt, was während der Arbeit schiefging, was zurückgebaut wurde, wie migriert wurde, welche Tests laufen, Verifikationsblöcke und Warnhinweise wie „nicht abwärtskompatibel". Breaking Changes stehen als Versionssprung und als Handlungsanweisung da. Interna (Refactorings, Abhängigkeits-Bumps, CI) nur, wenn ein Nutzer sie bemerkt. Hinein gehört, was der Nutzer tun muss, mit exakten Befehlen.

Mehrere Changelogs im Monorepo: nur der zum geänderten Bereich. Berührt ein Diff mehrere Bereiche, bekommt jeder seinen eigenen Eintrag, kein Sammeleintrag an der Wurzel. Struktur und Sprache der vorhandenen Datei werden übernommen.

## Audit (`--audit`)

Vollständigkeit ohne Kürze ist ein Fehlschlag: aufgeblähte, korrekte Doku ist nicht A. Vorher zusätzlich `prune-sweep.md` lesen.

1. **Discovery.** Scope laut `shared.md` erfassen. Bei vielen Dateien Explore-Subagenten je Bereich, sonst selbst der Reihe nach. Jede Aussage in beide Richtungen prüfen (Doku gegen Code und Code gegen Doku), Ergebnis je Fund `{file, line, claim, verified|stale|wrong|missing|duplicate|generic|impl-detail, evidence}`; `impl-detail` ist Implementierung, die der Code allein tragen sollte. Unsicher heißt `needs verification`. Daneben fünf Prüfungen:
   - a) Coverage: nur kritische, nicht offensichtliche Punkte (Security, Lifecycle, Kopplung, CI/Deploy, Harness, Side-Effect-Importe, Formate). Triviales CRUD ergibt keine Coverage-Lücke.
   - b) `paths:`: `ok|dead|too-broad|too-narrow` mit Beispielen.
   - c) Links und Verweise in Code-Kommentaren auflösen.
   - d) Prune-Sweep laut `prune-sweep.md`.
   - e) Aktive Kette: für Root und betroffene Subtrees belegen, welche Dateien der erkannte Client tatsächlich lädt, in welcher Reihenfolge und welche Datei im selben Verzeichnis eine andere verdrängt.
2. **Scoring** je Datei (unten).
3. **Report** nach Vorlage (unten).
4. **Fix-Vorschläge** im Format aus `shared.md`. Reihenfolge: (1) kaputt, falsch, Security, (2) Löschen, Kürzen, Zusammenführen, (3) fehlende blockierende Punkte (Entwurf mit höchstens 10 Zeilen in einer vorhandenen Datei). Keine Kosmetik, kein Auffüllen von Inventar.
5. Ohne `--fix` endet der Lauf hier; Report und Vorschläge sind das Ergebnis.
6. **Anwenden und prüfen, nur mit `--fix`.** Vorschläge schreiben, Verify laut `shared.md`, neu bewerten. Sinkt die Kürze durch reine Adds, das Add zurücknehmen und den Prune vorziehen.

### Scoring

| Kriterium | Gewicht | Voller Score |
| --- | ---: | --- |
| Accuracy | 25 | Aussagen stimmen mit dem Code |
| Completeness | 15 | Blockierende Invarianten sind da, nicht „alles Erwähnenswerte" |
| Conciseness | 25 | Nichts Generisches, kein Code-Duplikat, kein Implementierungsdetail, kein Duplikat zwischen Dateien, Größe im Richtwert aus `style.md` |
| Actionability | 15 | Eine Session vermeidet die kritischen Fehler, ohne den Code neu zu lesen |
| Currency | 10 | Keine veralteten Verweise oder Links |
| Cross-references | 10 | Links stimmen, keine doppelt erklärte Mechanik |

Noten: A ab 90, B ab 70, C ab 50, D ab 30, F darunter.

Completeness steigt nicht durch zusätzliches Implementierungsdetail oder Inventar. Eine Datei über dem Richtwert aus `style.md` (Overview etwa 40–50, Domain etwa 60, hart etwa 150 Zeilen) ohne Security-Begründung bekommt höchstens 15/25 bei Conciseness. Ein echtes Duplikat zwischen Dateien kostet bei Cross-references und Conciseness. Kürze ist kein Fehler; eine aufgeblähte, korrekte Datei ist kein A.

### Report-Vorlage

```markdown
## Documentation Audit
**Summary:** N audited · A:x B:x C:x D:x F:x · Below-B: x · Undocumented-critical: x · Duplikate: x · Prune-Kandidaten: x · Σ lines: N (Δ vs start if known)

**Red Flags**
- <path:line> — <stale|broken-link|wrong|duplicate|impl-detail|contradicts-…|security|undocumented-critical>

**Prune (priorisiert)**
- <path:line> — <warum> — <delete|shorten|merge-into>

**Per-File** *(A = one-liner)*
### <path> — XX/100 (X)
| Acc | Comp | Conc | Act | Curr | Cross | Notes |
|---:|---:|---:|---:|---:|---:|---|

**Undocumented-critical**
- <code path> — warum blockierend — wohin (vorhandene Datei und Abschnitt) — Entwurf ≤10 Zeilen

**Nebenbefunde (Code)**
- …
```

## Fix-Regeln

- Nur Befunde aus diesem Lauf, kein Scope-Creep.
- `rewrite-prune` ersetzt das veraltete Token und sonst nichts. Wird die Zeile dabei länger, ist es ein Add und geht durchs Add-Gate; `Netto: 0 Zeilen` tarnt keinen Zuwachs.
- `needs verification` blockiert auch Rewrites. Veraltete Stellen, die nicht aus dem Diff dieser Session stammen, sind ein eigener Kandidat und kein Beifang eines Rewrites.
- Neue Datei nur für einen eigenen Themenbereich, wenn Zusammenführen unzumutbar ist.
- Nichts erfinden; Spekulation fällt weg.
- Eine Freigabe für Code („mach einfach") ist keine Freigabe für Doku-Edits. Geschrieben wird nur mit `--fix` oder ausdrücklichem OK zur Doku.

## Sonderfälle

**Neue gemeinsame Bausteine** (Komponente, Hook, Export, Konstante): eine Zeile am kanonischen Ort (Package-Agentdatei oder bestehende Domain-Rule), und nur, wenn „nutze X statt Y" sonst zu einem Fehler führt. Kein Eintrag in mehreren Dateien, keine Prop-Listen.

**Frisch gebautes Feature:** Aktualisiert werden Verträge (Lifecycle, Security, kanonischer Helper), nicht die Implementierungsbeschreibung (Algorithmen, Cache-Werte, Komponentenbaum). Trägt der Code die Wahrheit, sind 0 Doku-Zeilen ein gültiges Ergebnis.

**Nichts zu tun:** gültiges und erwünschtes Ergebnis. Melden: `Sync: 0 candidates (gate).` und ein Satz, warum. Keine Abgleichstabelle der geprüften Stellen, nichts erfinden.

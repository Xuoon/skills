---
description: Toten/Legacy-/Fallback-Code und verwaiste Dateien finden — Standard nur analysieren, mit --anwenden nach dem Vorschlag direkt entfernen (samt Rest-Erwähnungen). Evidenz-basiert, löschen-bevorzugt.
argument-hint: "[--anwenden]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git log *) Bash(git grep *) Bash(git ls-files *) Bash(find *) Bash(wc *) Grep Glob Read
---

# cleanup:code — toten Code & verwaiste Dateien

Findet nachweislich ungenutzten Code, Legacy-/Fallback-Pfade und verwaiste Dateien. **Standard: nur analysieren und vorschlagen — es wird nichts gelöscht.** Mit `--anwenden` werden die Löschungen nach dem Vorschlag direkt ausgeführt, inklusive der Stellen, die sie sonst noch erwähnen. Grundhaltung: löschen ist billig, aber **jede Löschung braucht Beweis, dass wirklich nichts sie nutzt**. Falsch-Positive bei totem Code sind gefährlich — im Zweifel nicht löschen.

## Argumente (`$ARGUMENTS`)

| Flag | Bedeutung |
| --- | --- |
| *(ohne Flag)* | Nur analysieren + Vorschlag, **kein Edit** |
| `--anwenden` | Vorschlag zeigen **und** direkt löschen + verifizieren |

Scope ist immer das aktuelle Verzeichnis. Einen Subtree bei Bedarf im **Fließtext** nennen („nur src/sync"). Ausschließen: `node_modules`, Build-Output (`dist`/`build`/`.next`/`target`), `.git`, Lockfiles, Vendor.

## Ablauf

1. **Snapshot.** `git status`, betroffener Baum; optional `wc -l` als Baseline.

2. **Discovery (parallel Subagenten, 1 pro Bereich).** Fester Auftrag, nur strukturierte Funde, keine Fixes:

   > Finde Kandidaten, je mit `{path:line, kind, evidence}`:
   > - **tot:** Exports/Funktionen/Dateien ohne Aufrufer/Importeur, auskommentierte Blöcke, unerreichbare Zweige.
   > - **legacy/fallback:** Kompatibilitäts-Shims für Entferntes, Fallback-Pfade für nicht mehr mögliche Zustände, doppelte Pfade wo einer tot ist, „deprecated"/„TODO remove".
   > - **verwaist:** Dateien (Assets/Scripts/Configs), die nichts referenziert.
   > Evidence = **wo es NICHT referenziert ist**. Kein Fix, keine Stil-Meinung.

3. **Verifizieren vor dem Vorschlag (Pflicht).** Jeden Kandidaten gegenprüfen: Symbol/Dateiname im **ganzen** Repo greppen inkl. **dynamischer** Nutzung — String-Imports, Reflection, Glob-/Build-Config, CI, `package.json`-Scripts, Entry-Points. Adversarial fragen: „Was würde das noch benutzen?" Bleibt Zweifel → `needs verification`, **nicht** zum Löschen vorschlagen.

4. **„Nirgends mehr erwähnt"-Pass.** Zu jeder Löschung alle Rest-Erwähnungen sammeln, die mit weg müssen: Doku, README, Kommentare, Configs, Changelog-Verweise.

5. **Vorschlag.** Löschblöcke (delete-first), gruppiert pro Datei: `path:line — warum tot — evidence (wo nicht referenziert) — + Begleit-Erwähnungen`. Netto-Zeilen schätzen. **Ohne `--anwenden` endet der Lauf hier.**

6. **Anwenden + Verify (nur mit `--anwenden`).** Löschen, dann entfernte Symbole/Pfade greppen → 0 Reste, dann vorhandene Scripts (typecheck → build → test), um zu beweisen, dass nichts bricht. Bericht: Δ lines + Testergebnis.

## Grenzen

Nur nachweislich Ungenutztes. **Öffentliche/exportierte Library-Oberfläche** nicht ohne Rückfrage entfernen (externe Nutzer sind im Repo nicht sichtbar). Side-Effect-Importe sind nicht tot. Echte Bugs aus dem Lauf → separate Nebenbefund-Liste, nicht hier mitfixen.

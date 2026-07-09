# Prune-Sweep (Dedup + Löschen)

Gegenrichtung zu Completeness. Verhindert, dass Sync/Audit Docs fett machen.

**Wann:**

- **Audit:** Discovery-Sweep 1d (immer).
- **Sync:** Pflicht-Mini-Pass, sobald irgendein Add-Kandidat vorgeschlagen oder angewendet wurde; optional bei reinem Delete-only-Sync weglassen.
- **Review-only / „dünner machen“:** User verlangt Prune, Token-Effizienz, „weniger Doku“ → diesen Workflow als Hauptpass.

## Verfahren

1. **Thema→Dateien-Map**  
   Alle Docs lesen (oder Scope). Pro Thema: wo steht der volle Text, wo nur Pointer?

2. **Duplikate klassifizieren**
   - `pointer-ok` — ein Satz + Link; Mechanik nicht wiederholt.
   - `echtes-duplikat` — Mechanik/Zahl an ≥2 Stellen ausgeführt (auch **datei-intern** doppelte Bullets).
   - Drift-gefährlich: Limits, Zeiten, Pads, Statusfarben an mehreren Stellen → **eine** kanonische Stelle.

3. **Kanonik-Konflikte**
   - A sagt „kanonisch in B“, führt aber selbst die Mechanik aus → A auf Pointer kürzen.
   - A und B verweisen wechselseitig als SoT → eine Datei wählen (Domain-Rule schlägt Overview; Security schlägt Feature-UI).

4. **Prune-Kandidaten (Zeile/Abschnitt)**

   | Signal | Aktion |
   | --- | --- |
   | Generisch / Best Practice | löschen |
   | Aus Dateinamen trivial | löschen |
   | Implementation-Detail (Code owns it) | löschen |
   | UI-Chrome in Domain-Rule (schon in design) | löschen / Pointer |
   | Inventar / Ordnerbaum / Prop-Dump | löschen |
   | Historien-Sprache | löschen oder auf Gegenwart kürzen |
   | Doppel-Pointer-Listen | auf Root-Index reduzieren |
   | Key-References die `paths:` ersetzen | kürzen |

5. **Ganze Dateien**  
   Pro Rule: exklusive non-obvious Invarianten?
   - Inhalt ≤ ~15 Zeilen exklusiv und passt in existierende Domain-Rule → **mergen + Datei löschen**.
   - Alles woanders abgedeckt oder trivial → **Delete** mit Verbleib-Nachweis.
   - Security/Architecture always-on: nicht aus Bequemlichkeit mergen.

6. **Output (strukturiert)**

```text
DUPE: {thema} | files:lines | pointer-ok|echtes-duplikat | empfehlung
PRUNE: {datei:zeile} | text-kurz | warum | delete|shorten|merge-into:X
FILE: {datei} | keep|merge-into:X|delete | exklusive Fakten → wohin
CLEAN: {thema} | ok
```

Saubere Themen explizit als `CLEAN` listen (sonst neigen Agents zu Phantom-Finds).

## Qualitätsbremse

- Prune **darf** Security/Lifecycle-Invarianten **nicht** entfernen, nur verdichten.
- Nach Merge: alle Links/`paths:`/Root-Index aktualisieren im **selben** Vorschlagspaket.
- Netto-Ziel eines Prune-Laufs: **Δ lines < 0**. Reines Umsortieren ohne Kürzung = kein erfolgreicher Prune.

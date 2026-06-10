# Prune-Sweep (Dedup + Löschen)

Gegenrichtung zum Vollständigkeits-Check — verhindert, dass Audits die Docs fett machen. Wird vom Audit (Discovery-Schritt 1e) und vom Prune-Skill als Standalone-Prozedur genutzt.

1. **Duplikations-Scan**: Alle Docs vollständig lesen, Thema→Dateien-Mapping bauen. Akzeptabel: kurzer Pointer-Satz + Link auf die kanonische Stelle. NICHT akzeptabel: dieselbe Mechanik zweimal inhaltlich ausgeführt (auch datei-intern!). Besonders drift-anfällig: konkrete Zahlen/Zeiten/Limits, die an mehreren Stellen stehen — auf eine kanonische Stelle reduzieren.
2. **Kanonik-Konflikte**: Wenn Datei A Datei B als kanonisch deklariert, aber selbst die Mechanik voll ausführt → A auf Pointer kürzen. Wenn zwei Dateien sich gegenseitig als kanonisch deklarieren → auflösen.
3. **Prune-Kandidaten**: generische Good-Practice-Sätze, Selbstverständliches, aus Code/Verzeichnisnamen trivial Ableitbares, Historien-Sprache ("nicht mehr", "früher war"), Doppel-Pointer auf dasselbe Ziel.
4. **Ganze Dateien**: Pro Rule-Datei fragen: Trägt sie exklusive, non-obvious Invarianten? Wenn der Inhalt komplett woanders abgedeckt oder trivial ist → Datei zur Löschung vorschlagen (mit Nachweis, wo jede Information verbleibt).
5. Output: `{thema, dateien:zeilen, schwere: pointer-ok|echtes-duplikat, empfehlung}` bzw. `{datei:zeile, text, warum verzichtbar, empfehlung}`. Saubere Themen explizit als sauber listen.

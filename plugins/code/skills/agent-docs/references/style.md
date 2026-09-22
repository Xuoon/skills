# Style: Was in Agent-Doku gehört

Maßstab für alle Modi. Code und Tests sind die Quelle der Wahrheit; Agent-Doku hält nur fest, was dort nicht steht. Allgemeine Regeln zum Schreiben für Agenten (Verweise, Hierarchie, Pruning) stehen im Skill `writing-for-agents` aus `mattpocock-skills` (https://github.com/mattpocock/skills). Ist er verfügbar, beim Formulieren neuer oder umgeschriebener Zeilen laden.

## Jede Aussage einordnen

| Klasse | Erkennen | Vorgehen |
| --- | --- | --- |
| `code` | Erzählt nach, was der Code zeigt: Funktionsnamen, Feldlisten, Abläufe, Helper- oder Komponenteninventar, Ordnerbäume | löschen; ein Agent findet es per Suche |
| `test-exists` | Prüfbare Regel, die ein vorhandener Test, Typ oder eine Lint-Regel schon erzwingt | löschen; Beleg ist der Test (`datei:zeile`) |
| `test-missing` | Prüfbare Regel, die nichts erzwingt | Test oder Lint-Regel als Nebenbefund vorschlagen; die Zeile bleibt, bis es ihn gibt |
| `keep` | Nicht aus dem Code ablesbar: Warum und Absicht, bewusste Eigenheiten, die wie Bugs aussehen, Fallen außerhalb des Codes (Deploy, Infra, externe Dienste), Kompatibilitätsverträge, Sicherheitsgrenzen, „nutze X statt Y“, das kein Lint ausdrückt | behalten, knapp mit Grund |
| `human` | Rechts- oder Prozessdoku für Menschen (Verfahrensdokumentation, Runbook) | in den Doku-Ordner für Menschen, in der Agent-Doku ein Verweis |
| `stale` | Stimmt nicht mehr mit dem Code | korrigieren oder löschen; weicht der Code von einer gewollten Regel ab, ist das ein Code-Nebenbefund |

Test für jede Zeile: Würde ein Agent ohne sie etwas Falsches tun, das weder ein Test noch ein Blick in den Code verhindert? Nein heißt streichen.

## Wo was steht

- **Root-Agentdatei** (`AGENTS.md` oder `CLAUDE.md`, nicht beide): Zweck in einem Satz, Befehle mit ihren Fallen, repo-weite Konventionen und ein Verzeichnis „Bereich → Datei“ für alle bereichsbezogenen Dateien.
- **Bereichsregeln**: `.claude/rules/<thema>.md` mit `paths:`, wenn Claude Code sie beim Anfassen der Dateien automatisch laden soll; sonst eine verschachtelte `AGENTS.md` im Bereich. Eine Datei je Thema, kein Thema in zwei Dateien.
- **Menschen-Doku** in einem eigenen Ordner, getrennt von den Agent-Regeln: die vorhandene Konvention des Repos, sonst `.claude/docs/` neben `.claude/rules/`. Die Root-Datei verlinkt sie; Claude lädt `.claude/docs/` nicht automatisch.
- **Codex** lädt beim Start nur `AGENTS.md` vom Repo-Root bis zum Arbeitsordner (höchstens 32 KiB) und kennt `.claude/rules` nicht. Bereichsregeln erreicht Codex nur über das Verzeichnis in der Root-Datei; fehlt es, ist das ein Befund.
- Liest der Client `AGENTS.md` nicht selbst ein, genügt eine `CLAUDE.md` mit `@AGENTS.md`, ohne eigenen Inhalt.

## Form

- Größe ist ein Signal, keine Grenze. Eine lange Datei ist in Ordnung, wenn jede Zeile die Einordnung oben besteht; eine kurze Datei voller Code-Nacherzählung ist es nicht.
- Flach: `#`/`##`, Bullets, Tabellen nur für aufzählbare Fakten.
- Eine Zeile je Konzept, der Grund im selben Satz. Pointer-Satz: `… kanonisch in [foo.md](./foo.md)`, die Mechanik nicht noch einmal ausführen.
- Lifecycle-, Schema- oder Security-Änderung: Doku im selben PR (Sync).

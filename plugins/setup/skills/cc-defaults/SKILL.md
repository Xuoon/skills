---
name: cc-defaults
description: Nur bei ausdrücklichem Nutzerwunsch die globale Anweisungsdatei des aktiven Agent-Clients analysieren und gemeinsam schärfen.
---

# cc-defaults — globale Vorgaben schärfen

Ziel ist die globale Anweisungsdatei des aktiven Agent-Clients: kurze Antworten, sauberes PR- und Changelog-Format, keine Emojis und eine klare Grenze zwischen selbst machen und vorher fragen.

**Keine Argumente. Es wird nichts geschrieben, bevor der Nutzer zugestimmt hat.**

## 1. Ziel und Client ermitteln

- Codex: zuerst `$CODEX_HOME/AGENTS.override.md`, falls die Datei nicht leer ist; sonst `$CODEX_HOME/AGENTS.md`. Ohne gesetztes `CODEX_HOME` ist der Basisordner `~/.codex`. Eine inaktive Geschwisterdatei nur als Kontext lesen, nie statt der aktiven Datei ändern.
- Claude Code: `~/.claude/CLAUDE.md`.
- Anderer oder unklarer Client: dokumentierten globalen Anweisungspfad ermitteln oder einmal nach dem Ziel fragen.

Danach die gewählte Anweisungsdatei und angrenzende Client-Konfiguration read-only ansehen. Settings, Hooks, Skills, Plugins und Marketplaces nur als Kontext lesen, nie ändern.

Vier Fragen an den Bestand: Was ist geregelt? Was widerspricht sich? Was fehlt? Was steht doppelt?

## 2. Befund zeigen

Kurze Liste, gruppiert nach **geregelt / widersprüchlich / fehlt / doppelt**, jede Zeile mit Beleg aus der gewählten Datei. Keine Bewertung ohne Fundstelle.

Widersprüche zwischen Text und angrenzenden Settings oder Hooks gehören in den Befund — sie wirken unsichtbar und werden nur **gemeldet, nie geändert**.

## 3. Fragerunde

Strukturierte Nutzereingabe verwenden, ersatzweise gebündelt im Chat; Empfehlung als erste Option. **Nur fragen, wo es wirklich eine Entscheidung gibt** — was bereits so dasteht, wird nicht nochmal zur Abstimmung gestellt.

## 4. Schreiben

Nur nach Zustimmung, nur das Zugestimmte und nur in der gewählten globalen Anweisungsdatei schreiben. Was der Nutzer streicht, wird nicht geschrieben. Abschluss: ein Satz, welche Abschnitte angefasst wurden.

Der Text muss **schichten statt sammeln**: kurze Abschnitte mit Überschriften, eine Zeile pro Regel, keine Aussage in zwei Abschnitten.

## Vorrat

Die Themen, aus denen sich Befund und Fragerunde speisen, und zugleich die Textbausteine für das, was danach geschrieben wird. Jeder Punkt ist eine Empfehlung, kein Ergebnis — was der Nutzer anders will, gilt.

### Antworten

- Ergebnis zuerst. Kein Nacherzählen der Frage, keine Zusammenfassung der eigenen Schritte, keine Phasenerzählung, kein Selbstlob.
- Der kürzeste vollständige Text gewinnt; dieselbe Aussage nie an zwei Stellen; leere Abschnitte weglassen statt „keine" zu schreiben.
- Muss der Nutzer danach selbst etwas tun: `---`-Trennlinie, darunter „Du machst:" mit nummerierten Schritten. Sonst weglassen.
- Nach einer Freigabe wird durchgezogen — kein „nächste Schritte wären", Bericht am Ende.
- Rückfragen über strukturierte Nutzereingabe, ersatzweise gebündelt im Chat mit Antwortoptionen.
- Keine Emojis in allem, was ausgeliefert oder abgelegt wird: Dokumente, Mails, Commits, Skripte, Skilltexte, Doku.

### Pull Requests

- Titel als Conventional Commit mit deutschem Betreff.
- Kopf ohne Überschrift: 2–4 Sätze, Anlass statt Diff-Nacherzählung.
- `## Changelog`: pro Punkt fetter Anker, Gedankenstrich, ein Satz.
- `## Prüfung`: nur bei echter Evidenz, die der Leser nicht aus dem Diff ableiten kann.
- `## Manuelle Schritte`: nur wenn nach dem Merge wirklich etwas zu tun ist.
- Keine Tabellen, keine Klappblöcke, keine Checkboxen.

### Changelog-Dateien

Für Endnutzer geschrieben, nicht für Entwickler. Nur was neu, geändert oder entfernt ist — keine Migrations-, Bau- oder Rückbaugeschichte, keine Verifikationsblöcke.

### Dateien ändern

| Ohne Rückfrage | Vorher fragen |
| --- | --- |
| Neu anlegen, eigene Dateien ergänzen, genau den Auftrag ausführen | Umbenennen, Verschieben, ganze Inhalte ersetzen |
| Eigenen Text des Nutzers ändern — und danach melden | Änderungen über mehrere Dateien, alles außerhalb des aktuellen Ordners |

Löschen: in einem Git-Repo wird gelöscht, git ist das Backup. Außerhalb der Versionskontrolle nach `_to_delete` verschieben statt löschen.

### Handwerk

- Skripte: PowerShell als Default für Windows; Ausgabe deutsch, aber ASCII statt Umlauten in Konsolenausgaben; keine Platzhalter, keine ausgelassenen Blöcke.
- Prüfen statt vermuten: Ungeprüftes als ungeprüft kennzeichnen, nie behaupten recherchiert zu haben. Lücken bleiben offen statt plausibel gefüllt zu werden.
- Kein Overengineering: minimale Argument- und Optionsfläche, keine Flexibilität auf Vorrat.

## Grenzen

Vorschlagen und schreiben darf dieser Skill ausschließlich in der zuvor gewählten globalen Anweisungsdatei. Settings, Hooks, Skills, Plugins und Marketplaces werden nur gelesen und im Befund erwähnt.

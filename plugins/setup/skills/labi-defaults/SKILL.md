---
name: labi-defaults
description: Die globale Claude-Code-Konfiguration analysieren und gemeinsam schärfen, damit der Agent sich überall gleich verhält.
disable-model-invocation: true
allowed-tools: Read Glob Grep AskUserQuestion
---

# labi-defaults — globale Vorgaben schärfen

Ziel ist ein `~/.claude/CLAUDE.md`, das überall dasselbe Verhalten erzeugt: kurze Antworten, sauberes PR- und Changelog-Format, keine Emojis, klare Grenze zwischen selbst machen und vorher fragen.

**Keine Argumente. Es wird nichts geschrieben, bevor der Nutzer zugestimmt hat.**

## 1. Analysieren (read-only)

Ansehen: `~/.claude/CLAUDE.md`, `~/.claude/settings.json` (Permissions, Env, Hooks), `~/.claude/skills/`, `~/.claude/commands/`, installierte Plugins.

Vier Fragen an den Bestand: Was ist geregelt? Was widerspricht sich? Was fehlt? Was steht doppelt?

## 2. Befund zeigen

Kurze Liste, gruppiert nach **geregelt / widersprüchlich / fehlt / doppelt**, jede Zeile mit Beleg (`~/.claude/CLAUDE.md:42`). Keine Bewertung ohne Fundstelle.

Widersprüche zwischen Text und `settings.json` oder einem Hook gehören in den Befund — sie wirken unsichtbar und werden nur **gemeldet, nie geändert**.

## 3. Fragerunde (AskUserQuestion)

Gebündelt in einer Runde, Empfehlung als erste Option. **Nur fragen, wo es wirklich eine Entscheidung gibt** — was bereits so dasteht, wird nicht nochmal zur Abstimmung gestellt.

## 4. Schreiben

Nur nach Zustimmung, nur das Zugestimmte, nur in `~/.claude/CLAUDE.md`. Was der Nutzer streicht, wird nicht geschrieben. Abschluss: ein Satz, welche Abschnitte angefasst wurden.

Der Text muss **schichten statt sammeln**: kurze Abschnitte mit Überschriften, eine Zeile pro Regel, keine Aussage in zwei Abschnitten.

## Vorrat

Die Themen, aus denen sich Befund und Fragerunde speisen, und zugleich die Textbausteine für das, was danach geschrieben wird. Jeder Punkt ist eine Empfehlung, kein Ergebnis — was der Nutzer anders will, gilt.

### Antworten

- Ergebnis zuerst. Kein Nacherzählen der Frage, keine Zusammenfassung der eigenen Schritte, keine Phasenerzählung, kein Selbstlob.
- Der kürzeste vollständige Text gewinnt; dieselbe Aussage nie an zwei Stellen; leere Abschnitte weglassen statt „keine" zu schreiben.
- Muss der Nutzer danach selbst etwas tun: `---`-Trennlinie, darunter „Du machst:" mit nummerierten Schritten. Sonst weglassen.
- Nach einer Freigabe wird durchgezogen — kein „nächste Schritte wären", Bericht am Ende.
- Rückfragen gebündelt in einer Nachricht über das Frage-Tool mit Antwortoptionen, nicht als Fließtext.
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

Vorschlagen darf dieser Skill ausschließlich `~/.claude/CLAUDE.md`. `settings.json`, Hooks, Skills und Plugins gehören dem Nutzer — sie werden gelesen und im Befund erwähnt, nie angefasst.

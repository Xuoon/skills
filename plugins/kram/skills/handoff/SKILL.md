---
name: handoff
description: Nur bei ausdrücklichem Nutzerwunsch die laufende Session in ein Übergabe-Dokument destillieren.
argument-hint: "[Sonderwünsche als Fließtext]"
---

# handoff — Session-Übergabe an den nächsten Agenten

Erzeuge aus der bisherigen Session ein Übergabe-Dokument, mit dem ein **frischer Agent ohne diesen Kontext** direkt weiterarbeiten kann. Das Dokument bleibt client-neutral: keine Verweise auf Werkzeuge, Skills oder Mechanismen, die nur in der aktuellen Umgebung existieren.

Keine Flags. Zusätzlicher Fließtext in der Nutzeranfrage steuert das Dokument („kürzer", „nur der Backend-Teil", „Empfänger kennt Repo und Rechner nicht") — umsetzen, nicht zitieren.

## Die Aufnahme-Regel

Ein Fakt kommt ins Dokument, **wenn sein Fehlen den nächsten Agenten Arbeit doppelt machen, etwas kaputt machen oder eine bereits getroffene Entscheidung neu verhandeln lässt.** Alles andere fliegt raus. Konkret:

- **Historie raus, Invarianten rein.** „Bug X in Datei Y behoben" ist Erzählung und entfällt. Hat der Fix aber eine Regel hinterlassen, gegen die der Nächste sonst verstößt („Live-Query darf den lokalen Formularzustand nicht überschreiben"), kommt **die Regel** rein — als Tretmine mit Begründung, nicht als Fix-Bericht. Ein Fix ohne solche Regel wird gar nicht erwähnt.
- **Entscheidungen sind das Wertvollste.** Bewusste Produkt- und Architektur-Entscheidungen aus den bisherigen Nutzer-Anweisungen („bewusst öffentlich", „kein Feature X") explizit festhalten — sonst „repariert" der Nachfolger sie als vermeintliches Versehen. Jeweils mit dem Warum, wenn es bekannt ist.
- **Auftrag vor Chronik.** Was ist das Ziel, was ist der Stand, was ist der nächste Schritt. Die Reihenfolge, in der die Session dahin kam, interessiert niemanden.
- **Erledigtes nur als Stand.** Abgeschlossene Arbeit erscheint als Zustandsbeschreibung („Feature X vorhanden, Tests grün"), nicht als Tätigkeitsliste.

## Faktencheck vor dem Schreiben (Pflicht)

Jedes „möglicherweise" über einen prüfbaren Zustand kostet den Nachfolger eine Wiederentdeckungsrunde. Deshalb vor dem Schreiben den Ist-Zustand erheben statt aus dem Gedächtnis behaupten:

```bash
git status --short
git branch --show-current
git log --oneline -5
git worktree list
git stash list
```

- Pfade, Branch, Commit-Stand und Uncommitted-Umfang stehen als **geprüfte Fakten** im Dokument, nicht als Vermutung.
- Was sich seit der Erhebung ändern kann (läuft ein Deploy noch?), als offene Prüfung formulieren — mit dem Befehl, der die Antwort liefert.
- Kein Git oder kein Repo: die relevanten Pfade und Zustände direkt prüfen (`ls`, Config lesen).

## Ehrlichkeit über den Stand

- **Unverifiziertes klar markieren.** Was gebaut, aber nie ausgeführt/gesehen/getestet wurde („UI-Umbau nie im Browser geprüft"), gehört ausdrücklich ins Dokument — das sind die ersten Aufgaben des Nachfolgers.
- Prüfbefehle mitgeben, wo es sie gibt (Test-, Check-, Start-Befehle des Projekts).
- Offene Fragen an den Nutzer als solche kennzeichnen („Der Nutzer muss noch entscheiden: …") und von Agent-Aufgaben trennen.

## Aufbau des Dokuments

Umfang: etwa zwei Seiten Markdown. Überschriften nach Bedarf, aber diese Inhalte in dieser Reihenfolge:

1. **Kopf** — Repo/Projekt, Branch, exakter Arbeitspfad (aus dem Faktencheck), Basis-Branch, geltende Git-Regeln (committen ja/nein).
2. **Auftrag** — was gebaut wird und für wen, in wenigen Sätzen. Der Ziel-Ablauf, nicht die Feature-Liste.
3. **Entscheidungen — nicht ändern** — die bewussten Festlegungen, je mit Warum.
4. **Tretminen** — die Invarianten aus behobenen Fehlern und bekannten Fallstricken: was man falsch machen kann und woran man es erkennt.
5. **Stand** — was vorhanden und verifiziert ist (mit letztem Testergebnis), und **getrennt davon**, was unverifiziert ist.
6. **Nächste Schritte** — konkret und geordnet, mit den nötigen Befehlen. Offene Nutzer-Entscheidungen separat.
7. **Arbeitsregeln** — die projektspezifischen Regeln, die der Nachfolger sonst bricht (Toolchain, Stil-Invarianten, Verbote). Nur was nicht ohnehin in einer Doku steht, die er sicher liest — sonst auf die Doku verweisen.

Was der Empfänger selbst billig herausfinden kann (Dateibäume, Standard-Konventionen, vorhandene Agent-Doku im Repo), wird verwiesen statt kopiert.

## Ausgabe-Vertrag

1. Das Dokument immer als letzte Antwort ausgeben — **nur** das Dokument. Kein Vorspann, Nachsatz oder Verweis auf lokale Dateien.
2. Ist ein beschreibbarer lokaler Workspace vorhanden, zusätzlich eine ungetrackte `HANDOFF.md` anlegen. Existiert sie bereits, einen kollisionsfreien Zeitstempel-Namen verwenden; nie überschreiben. Ein fehlender Schreibzugriff blockiert die Antwort nicht.

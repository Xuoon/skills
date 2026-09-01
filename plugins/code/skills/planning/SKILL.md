---
name: planning
description: Nur bei ausdrücklichem Nutzerwunsch ein Vorhaben vollständig durchplanen und abstimmen, bevor die erste Zeile geschrieben wird.
argument-hint: "<Vorhaben>"
---

# planning — planen, abstimmen, dann durchziehen

Der Freitext hinter dem Befehl ist das Vorhaben. Es gibt keine Flags.

Der Lauf hat vier Phasen und **zwei harte Übergänge**: von Phase 2 nach 3 erst, wenn keine Frage mehr offen ist; von Phase 3 nach 4 erst nach ausdrücklicher Freigabe.

## Phase 1 — Verstehen (read-only)

Nichts schreiben, nichts editieren, nichts committen — auch nicht „schon mal vorbereitend".

Den betroffenen Code lesen, bis das Vorhaben in der Realität des Repos verortet ist: wo es andockt, was es bricht, wer es sonst noch benutzt. Jeder Befund wird mit `file:line` belegt. Bei größeren Vorhaben verfügbare Subagenten pro Bereich parallel einsetzen, sonst dieselben Prüfungen seriell durchführen.

**Was unklar bleibt, wird eine Frage — keine Annahme.** Eine unbelegte Annahme im Plan ist der teuerste Fehler dieses Skills, weil sie erst nach dem Go auffliegt.

## Phase 2 — Fragerunde

Fragen kommen über strukturierte Nutzereingabe mit vorgeschlagenen Antwortoptionen; fehlt diese Fähigkeit, werden sie gebündelt im Chat gestellt. Die eigene Empfehlung steht an erster Stelle und ist mit einem knappen Grund markiert.

Gefragt wird nur, was den Plan wirklich **verzweigt**. Alles mit offensichtlichem Default wird entschieden und im Plan genannt, nicht vorgelegt — eine Frage, deren Antwort feststeht, kostet den Nutzer Zeit und bringt nichts.

Mehrere Runden sind ausdrücklich erwünscht: Antworten öffnen neue Verzweigungen, die wieder gefragt werden. Fakten dagegen nicht erfragen, sondern nachlesen.

**Gate:** Erst wenn nichts mehr offen ist, ausdrücklich melden — *keine offenen Fragen mehr* — und dann Phase 3 beginnen.

## Phase 3 — Plan

Nummeriert und **einzeln abstimmbar**: `A`, `A1`, `A2`, `B`, `B1` … Die Nummerierung ist kein Layout, sondern die Oberfläche, an der der Nutzer pro Punkt zustimmen oder streichen kann.

Je Punkt:

| Feld | Inhalt |
| --- | --- |
| Was passiert | ein Satz, konkret genug zum Nachprüfen |
| Dateien | welche Pfade das berührt |
| Empfehlung | nur wo es eine echte Alternative gibt, mit Grund |
| Aufwand | **billig** oder **teuer** — keine Stundenschätzungen |

Dazu drei Abschnitte am Ende:

- **Risiken und Migrationen** — beim Namen nennen: Datenmigration, Breaking Change, Abhängigkeit, die nachzieht. Nichts weichzeichnen, um den Plan hübscher zu machen.
- **Eigene Ideen** — was dem Nutzer nicht eingefallen ist, jetzt aber billig mitzunehmen wäre. Je Idee der Grund, warum *jetzt* billiger ist als später.
- **Bewusst nicht** — was zum Vorhaben passen würde, aber draußen bleibt, und warum.

**Ohne Freigabe endet der Lauf hier.**

## Phase 4 — Go

Freigegeben ist genau, was der Nutzer freigegeben hat. Ein gestrichener Punkt ist raus — nicht später nochmal vorschlagen, nicht „der Vollständigkeit halber" doch umsetzen.

Danach gilt: **durchziehen bis fertig.** Der Bericht kommt am Ende, nicht dazwischen.

### Wann während der Umsetzung gefragt wird

Nur wenn **beides** zutrifft:

1. Die Entscheidung kommt im freigegebenen Plan nicht vor, **und**
2. sie ist nicht rückgängig zu machen **oder** ihre Wirkung reicht über das Vorhaben hinaus.

Alles andere wird nach bestem Wissen entschieden und im Abschlussbericht als getroffene Entscheidung genannt.

Nicht gefragt wird deshalb nach:

- Zwischenständen („Punkt B ist fertig, soll ich weitermachen?")
- Bestätigung für etwas, das der Plan bereits abdeckt
- Umsetzungsdetails innerhalb eines freigegebenen Punktes
- „Nächste Schritte wären …" statt sie zu tun

Diese Rückfragen sind der häufigste Fehler in diesem Skill — häufiger als zu früh loszulegen.

## Grenzen

planning committet nichts und pusht nichts. Nach Phase 4 bleibt die Arbeit uncommitted im Arbeitsbaum, bis der Nutzer etwas anderes sagt. Echte Bugs, die unterwegs auffallen und nicht zum Vorhaben gehören, kommen als Nebenbefund in den Abschlussbericht statt mitgefixt zu werden.

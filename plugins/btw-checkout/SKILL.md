---
name: btw-checkout
description: Side-Chat-Ergebnis als kompakten Übergabe-Prompt für den Haupt-Chat ausgeben — Codeblock zum Rüberkopieren.
argument-hint: "[hinweise]"
disable-model-invocation: true
---

# btw-checkout — Übergabe an den Haupt-Chat

Destilliere den bisherigen Verlauf dieses Side-Chats in einen Übergabe-Prompt für den Haupt-Chat. Einzige Quelle ist der Konversationskontext — keine Tool-Aufrufe, keine Dateizugriffe. Argumente beim Aufruf (falls vorhanden) als zusätzliche inhaltliche Hinweise behandeln.

## Format des Übergabe-Prompts

- Erste Zeile: `Aus einem Side-Chat übernommen:`
- Danach nur der notwendige Kontext: getroffene Entscheidungen, relevante Fakten und Dateipfade, offene Fragen. Keine Chat-Nacherzählung, keine verworfenen Zwischenstände, kein „wir haben besprochen, dass…".
- Abschnitt `Aufgaben:` mit nummerierten, direkt umsetzbaren Schritten. Gibt es nichts zu tun, steht dort stattdessen exakt: `Keine Aktion nötig, nur zur Kenntnis.`
- Deutsch, imperativ, Ziel ≤ 30 Zeilen.
- Der Haupt-Chat kennt diesen Side-Chat nicht: alles Nötige muss im Prompt selbst stehen — vollständige Pfade, keine Verweise wie „siehe oben" oder „wie besprochen".

## Workflow

1. **Entwurf zeigen.** Den Übergabe-Prompt entwerfen und zeigen, dann genau einmal fragen, ob etwas ergänzt oder geändert werden soll. **Stop, auf Antwort warten.**
2. **Final ausgeben.** Änderungswünsche einarbeiten, dann die finale Fassung als einzelnen Codeblock ausgeben — copy-paste-fertig, ohne weiteren Text drumherum.

## Grenzen

Nur Text produzieren: nichts ausführen, nichts committen, keine Dateien lesen oder schreiben. Bei zu wenig Substanz im Verlauf (z. B. Aufruf direkt am Chat-Anfang) das sagen statt einen leeren Prompt zu erfinden.

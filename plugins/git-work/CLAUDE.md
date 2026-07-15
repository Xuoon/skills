# git-work — Hausregeln (immer aktiv)

## PR-Beschreibungen

Jede PR-Beschreibung (egal ob via `/git-work:pr` oder direkt mit `gh pr create`) hat genau
diese Struktur, Bereiche durch `---` getrennt:

1. **Ganz oben:** kurzer Fließtext oder Punkte — was umgesetzt wurde und warum.
2. **Technischer Changelog:** was alles angepasst wurde (Dateien/Verhalten), prägnant.
3. **„Manuelle Schritte"** ganz unten — nur wenn nach dem Merge tatsächlich etwas manuell zu
   erledigen ist, dann prägnant aufgelistet; sonst den Block komplett weglassen.

Kein „Verifikation"-Block oder ähnliche Boilerplate. Ton und Format der Sätze wie in
[references/commit-style.md](references/commit-style.md).

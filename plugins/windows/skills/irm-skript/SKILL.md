---
name: irm-skript
description: Baut ein self-contained PowerShell-TUI-Tool für den Aufruf `irm labi.dev/<route> | iex` im Hausstil von labi.dev/secureboot.
argument-hint: "[was das Tool tun soll]"
disable-model-invocation: true
---

# irm-skript — gehostete PowerShell-TUI-Tools

Jedes Tool ist EINE self-contained `.ps1`, die per `irm labi.dev/<route> | iex` läuft. Der verbindliche Hausstil (Helper, Header, Badges, Menü, Hilfe, Headless) steht in `${CLAUDE_SKILL_DIR}/references/stilguide.md` — **zuerst lesen**. `${CLAUDE_SKILL_DIR}/assets/template.ps1` ist ein lauffähiges, geparstes Skelett: davon ausgehen, nicht von Null schreiben.

## Ablauf

1. **Anforderung klären.** Der Nutzer sagt direkt nach dem Aufruf, was das Skript tun soll. Nur nachfragen, was wirklich offen ist — eine kurze Rückfrage, kein Verhör:
   - Liest das Tool nur, oder **ändert** es etwas am System? Das entscheidet über das Sicherheitsmuster.
   - Zielsystem (Server/DC, Client, beides) und Voraussetzungen (Admin? bestimmtes Modul?).
   - Routenname, falls nicht genannt — kurz, klein, ohne Sonderzeichen, wird `labi.dev/<route>`.

   Ist die Anforderung klar: nicht fragen, bauen.

2. **Bei schreibenden Aktionen** zusätzlich `${CLAUDE_SKILL_DIR}/references/schreib-muster.md` lesen: Ist/Soll-Vorschau, Einzelbestätigung `j/N`, getipptes Token bei riskanten Aktionen, Rollback vor der ersten Schreiboperation. Ein rein lesendes Tool braucht davon nichts — keine Bestätigungs-Zeremonie für `Get-*`.

3. **Schreiben.** Eine Datei `<route>.ps1`:
   - **UTF-8 ohne BOM, LF.** Ein BOM bricht `irm | iex` (PowerShell sieht `ï»¿<#`).
   - **ASCII in der TUI-Ausgabe** (ue/oe/ae/ss statt Umlauten) — maximale Konsolen-Kompatibilität.
   - **Self-contained**: nichts nachladen, nichts installieren. Externe Abhängigkeiten (z. B. RSAT) werden geprüft und sauber gemeldet.
   - Deutsch, knapp. Keine TUI-Floskeln („Willkommen!"), Kommentar nur, wo ein Warum sonst verloren ginge.
   - Das Write-Tool kappt bei ~33 KB — größere Skripte per Shell-Heredoc schreiben oder in mehreren Edits aufbauen.

4. **Verifizieren — immer, nicht optional.** `${CLAUDE_SKILL_DIR}/references/verifikation.md` lesen und ausführen: pwsh-Parser mit 0 Fehlern, BOM-Check, bei schreibenden Tools ein gemockter Dry-Run (lesender Pfad und Vorschau lösen 0 Schreibzugriffe aus, Bestätigungs-Gates greifen). Erst liefern, wenn alles grün ist.

5. **Liefern: nur die `.ps1`.** Gehostet wird selbst. Im Chat reicht `irm labi.dev/<route> | iex` plus besondere Hinweise („elevated nötig"). Keine README, keine Hosting-Anleitung.

## Merkmale eines Tools im Hausstil

- Ein Aufruf, ein klarer nächster Schritt: das Tool sagt, was als Nächstes zu tun ist (`-> Naechster Schritt: Phase 1 anstossen`), statt nur Daten zu kippen.
- Tasten statt Tippen, wo eine Taste reicht: `[Enter]` Hauptaktion, `[H]` Hilfe, `[D]` Details, `[B]`/Esc zurück, Ctrl+C sauberer Abbruch.
- Farben tragen Bedeutung — Green ok, Yellow Vorsicht, Red Gefahr, Cyan läuft, DarkGray sekundär. Nie dekorativ.
- Voraussetzungen (Admin, Plattform, Module) werden vor der Hauptschleife geprüft und bei Fehlen mit konkreter Abhilfe gemeldet, dann sauber beendet.
- Hilfe erklärt Was/Warum, Ablauf, Tasten und Sonderfälle auf 2–5 Seiten — kein Handbuch.

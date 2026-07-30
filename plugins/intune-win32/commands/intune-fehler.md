---
description: Fehlgeschlagene Intune-Win32-Installation eingrenzen (0x87D1041C, 1603, 3010 …)
argument-hint: [Fehlercode und/oder Paketname und Gerät]
---

Grenze diesen Intune-Fehler ein: $ARGUMENTS

Skill `intune-win32-paket` verwenden, Abschnitt zu Fehlerbildern, plus
`references/intune-portal.md`.

Reihenfolge:

1. Fehlercode zuordnen (`0x87D1041C` = installiert, aber nicht erkannt;
   `1603` = fehlende Voraussetzung; `3010`/`1641` = Erfolg mit Neustart).
2. Die beiden Logquellen anfordern bzw. lesen:
   - Paketlog unter `<logDir>` (Standard `C:\ProgramData\Intune-Logs`),
   - `…\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.
3. Bei Erkennungsproblemen die Uninstall-Registry auf dem Gerät auslesen und
   den echten `DisplayName` mit dem Muster im Detect-Skript vergleichen –
   inklusive `WOW6432Node` und „64-Bit ausführen = Ja".
4. Erst danach eine Ursache benennen. Fehlen Logs, diese anfordern statt zu
   raten.

Keine Schreibänderungen an Intune, Entra ID, AD oder ACLs ohne ausdrückliche
Freigabe – Analyse bleibt read-only.

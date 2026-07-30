---
description: Einen Installer analysieren (Typ, Silent-Schalter, Zielordner, Anzeigename)
argument-hint: [Pfad zur MSI/EXE]
---

Analysiere den Installer: $ARGUMENTS

Nur analysieren, **kein** Paket bauen. Nach `references/installer-analyse.md`
aus dem Skill `intune-win32-paket` vorgehen:

1. Grundtyp und Bitness (`file`, PE-Header).
2. Setup-Framework erkennen (NSIS, Inno, InstallShield, WiX/Burn, MSI, 7-Zip-SFX).
3. Bei 7-Zip-SFX: Konfigblock lesen. `RunProgram="db-bootstrap.exe"` bedeutet
   **Downloader statt Setup** – dann auf ein inneres Archiv prüfen und den
   Platzbedarf nennen.
4. Tatsächlich unterstützte Schalter aus den UTF-16-Strings auslesen
   (`strings -e l`), nicht aus dem Gedächtnis.
5. Registry-Anzeigename und Standard-Zielordner bestimmen.

Liegt die Datei auf dem Gerät des Users, vorher in den Container stagen.

Ergebnis als kurze Tabelle: Typ, Silent-Installation, Silent-Deinstallation,
Zielordner, Erkennungsmuster – jeweils mit Herkunft („aus der EXE ausgelesen",
„laut Herstellerdoku", „geraten, zu testen").

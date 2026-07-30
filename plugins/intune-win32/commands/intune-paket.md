---
description: Aus einem Ordner mit Installer ein vollständiges Intune-Win32-Paket bauen
argument-hint: [Pfad zum Paketordner oder zum Installer]
---

Baue ein Intune-Win32-Paket für: $ARGUMENTS

Vorgehen: Skill `intune-win32-paket` verwenden und dessen Schritte in der dort
beschriebenen Reihenfolge abarbeiten.

Wichtig:

- Zuerst prüfen, ob eine `intune-paket.json` existiert (ab dem Paketordner
  aufwärts). Deren Werte gelten – keine Konventionen erfinden.
- Den Installer **analysieren** (`references/installer-analyse.md`), bevor
  Silent-Schalter, Erkennungsmuster oder Deinstallationsbefehl festgelegt
  werden. Geratene Werte ausdrücklich als `TODO pruefen` markieren.
- Ist kein Pfad angegeben, den Ordner erfragen bzw. den zuletzt genannten
  verwenden.
- Am Ende die Werte für den Intune-Assistenten ausgeben (Install-/Uninstall-
  Befehl, Erkennungsregel, Anforderungen, Rückgabecodes) und sagen, was der
  User noch selbst tun muss.

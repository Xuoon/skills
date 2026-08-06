# Intune-Portal: Win32-App anlegen

Apps → Windows → Hinzufügen → **Windows-App (Win32)** → `.intunewin` aus `Output\` hochladen.

## Skript-Pakete (install.ps1 vorhanden)

Intune füllt hier **nichts** automatisch aus – alle Felder von Hand:

| Feld | Wert |
|---|---|
| Name / Verlag | Programmname, Hersteller |
| Installationsbefehl | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1` |
| Deinstallationsbefehl | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1` |
| Installationsverhalten | System |
| Geräteneustartverhalten | Ohne bestimmte Aktion fortsetzen |
| Rückgabecodes | 0 = Erfolg, 3010 = Soft-Reboot (Standard belassen) |
| Anforderungen | Architektur x64, min. Windows 10 1607 |
| Erkennungsregel | Regelformat = **Benutzerdefiniertes Erkennungsskript**, `App\detect-*.ps1` hochladen, „Skript mit 64-Bit-Prozess ausführen" = **Ja**, Signaturprüfung = **Nein** |

## Reine MSI-Pakete (kein Wrapper)

Beim Upload liest Intune das MSI aus und füllt Installations-/Deinstallationsbefehl
und die Erkennung (MSI-Produktcode) selbst. Nur Zuweisung und Anforderungen setzen.

## Erkennungsregeln – Fallstricke

- Fehler **0x87D1041C** = „Anwendung nach erfolgreicher Installation nicht erkannt":
  fast immer ein zu enges Suchmuster im Detect-Skript oder der Installer hat
  in Wahrheit nichts installiert. Erst Client-Log unter
  `C:\ProgramData\Intune-Logs\<Paket>-install.log` prüfen, dann das Muster
  gegen den echten Registry-Anzeigenamen abgleichen.
- Detect-Skript-Konvention: **Ausgabe auf STDOUT + Exit 0** = installiert;
  keine Ausgabe / Exit 1 = nicht installiert. Ein `Write-Output` bei Exit 1
  macht die Erkennung kaputt.
- Version im Suchmuster nur dann, wenn Updates als eigene App mit
  Supersedence ausgerollt werden sollen.

## Client-seitige Diagnose

```powershell
Get-Content C:\ProgramData\Intune-Logs\<Paket>-install.log
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Where-Object DisplayName -like '*<Suchbegriff>*' |
  Select-Object DisplayName, DisplayVersion, PSChildName
```

Agent-Logs: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`

## Silent-Parameter, gängige Setup-Typen

| Setup | Silent | Deinstallation |
|---|---|---|
| MSI | `msiexec /i x.msi /qn /norestart` | `msiexec /x {ProductCode} /qn /norestart` |
| InstallShield | `/s /v"/qn"` | über UninstallString |
| NSIS | `/S` | `Uninstall.exe /S` |
| Inno Setup | `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` | `unins000.exe /VERYSILENT` |
| WiX-Bundle/Burn | `/quiet /norestart` | `/uninstall /quiet` |

Unbekannte Setups: `setup.exe /?` oder Herstellerdoku. Silent-Parameter immer
auf einem Testgerät verifizieren, bevor zugewiesen wird.

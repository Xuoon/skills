---
name: windev
description: Nur bei ausdrücklichem Nutzerwunsch eine Windows-Entwicklungsumgebung interaktiv oder mit `--best-practice` einrichten.
compatibility: Benötigt Windows 11; PowerShell 7 kann mit vorhandenem winget eingerichtet werden.
argument-hint: "[--best-practice]"
---

# windev — Windows-Entwicklungsumgebung

Der Zielzustand und die Messmethodik stehen in `references/best-practice.md`. Den Skill-Root über den aktiven Skill-Kontext absolut auflösen und für `<skill-root>` einsetzen; niemals Bundle-Dateien relativ zum aktuellen Repo ausführen.

## Modus

Es gibt genau ein optionales Argument:

| Aufruf | Verhalten |
| --- | --- |
| ohne Argument | Inventarisieren, alle tatsächlichen Installations-, Konfigurations- und Bereinigungskandidaten gebündelt entscheiden lassen, danach das Gewählte anwenden und verifizieren |
| `--best-practice` | Belegte, reversible Standards direkt herstellen; nur persönliche, mehrdeutige oder potenziell destruktive Entscheidungen fragen |

Andere Argumente abbrechen und diese Verwendung zeigen. `--fix` und `--setup` nicht stillschweigend weiter unterstützen.

## Invarianten

- Vor der Inventur nichts verändern; Ausnahme ist das PowerShell-7-Bootstrap im ausdrücklich gewählten `--best-practice`-Modus.
- Ohne Argument nur konkret ausgewählte Änderungen ausführen.
- `--best-practice` erlaubt weder geratenes noch destruktives Aufräumen.
- Profil, Theme, PATH und Editor-Settings vor jeder Änderung sichern; fremde Marker-Blöcke und Einstellungen erhalten.
- Keine Identität, Editorvariante oder optionale Toolchain erfinden.
- Erfolg erst nach direkter Nachmessung behaupten.

## 1. Laufzeit vorprüfen

Mit dem vorhandenen `powershell.exe` nach `pwsh` und `winget` suchen:

```powershell
powershell.exe -NoProfile -Command "Get-Command pwsh,winget -ErrorAction SilentlyContinue | Select-Object Name,Source"
```

Fehlt `pwsh`, im interaktiven Modus die Installation über `winget` als erste Entscheidung anbieten. Mit `--best-practice` den folgenden Befehl im ursprünglichen Nutzerprozess ausführen, sofern `winget` vorhanden ist; der WIX-Installer fordert die nötige UAC-Freigabe selbst an:

```powershell
winget install --id Microsoft.PowerShell --exact --source winget --installer-type wix --accept-source-agreements --accept-package-agreements
```

Seit PowerShell 7.6 installiert `winget` ohne `--installer-type wix` standardmäßig das MSIX-Paket; das genügt nicht für die erhöhten Wrapper. Danach `C:\Program Files\PowerShell\7\pwsh.exe` direkt verifizieren und diesen absoluten Pfad verwenden. Fehlt das Binary trotz erfolgreichem Exitcode, nicht mit einer User-/MSIX-Version fortfahren. Fehlt auch `winget`, mit einem klaren Restschritt stoppen.

## 2. Inventur

```powershell
& "$env:ProgramFiles\PowerShell\7\pwsh.exe" -NoProfile -File "<skill-root>/scripts/measure-environment.ps1"
```

Kann der Bericht die aktive Oh-My-Posh-Konfiguration nicht sicher bestimmen, Profile nur lesen und mit `-OhMyPoshConfig <aufgelöster-pfad>` erneut messen. Der Befund enthält Messwert, Wirkung und Risiko für:

- Startzeit mit und ohne Profil,
- Prompt-Segmente und rohes `git status` als Untergrenze,
- Profile, PATH-Rohwerte und Modulversionen,
- tatsächlich installierte VS-Code-Variante und Settings,
- Fonts und vorhandene Toolchains.

## 3. Entscheidungen

Strukturierte Nutzereingabe verwenden, ersatzweise alle offenen Fragen gebündelt im Chat stellen.

Ohne Argument werden nur reale Kandidaten angeboten:

- zu installierende Komponenten,
- Prompt schnell oder mit Git-Änderungszahlen,
- Stable, Insiders oder kein VS Code,
- optionale Node-/Bun-Toolchains,
- zu behebende PATH-, Modul- und Altdatei-Befunde,
- Merge eines bestehenden Profils oder unverändert lassen.

Mit `--best-practice` automatisch:

- PowerShell 7 und Git sicherstellen,
- vorhandenes Oh My Posh ohne pro-Prompt-Prozessstarts konfigurieren,
- Documents-Pfade dynamisch auflösen und den Nicht-interaktiv-Guard setzen,
- `gpuAcceleration` bei der belegten VS-Code-Variante auf `auto` halten,
- tote und doppelte PATH-Einträge nur bei eindeutigem Nachweis entfernen,
- nur alte Versionen gewöhnlicher CurrentUser-Module bereinigen.

Auch mit `--best-practice` fragen bei Git-Identität, nicht ableitbarer Editorwahl, optionalen Toolchains, Git-Status-Detailgrad, fremden Profil-/Settings-Konflikten, Admin-Modulen und zweifelhaften PATH- oder Altdatei-Kandidaten.

## 4. Anwenden

Bereits getroffene Entscheidungen sind die Freigabe; keine zusätzliche Frage „Soll ich anfangen?“. Abhängige Schritte stoppen nach einem Fehler, unabhängige Kandidaten dürfen weiterlaufen.

- **Installationen:** `winget` nur für gewählte oder im Modus belegte Komponenten; danach die echte EXE beziehungsweise `Get-Command` prüfen. IDs: `Microsoft.PowerShell`, `Git.Git`, `JanDeDobbeleer.OhMyPosh`, `ajeetdsouza.zoxide`, `Microsoft.VisualStudioCode`, `Microsoft.VisualStudioCode.Insiders`, `CoreyButler.NVMforWindows`, `Oven-sh.Bun`. Nerd Font über `oh-my-posh font install CascadiaCode`, Terminal-Icons über `Install-Module Terminal-Icons -Scope CurrentUser`.
- **Theme:** `scripts/new-slim-theme.ps1` schreibt standardmäßig `windev.omp.json`; für den schnellen Modus `-NoGitStatusCounts` setzen. Ein bestehendes verwaltetes Theme nur mit `-UpdateManaged` nach Backup ersetzen.
- **Profil:** `scripts/update-profile.ps1` übernimmt ausschließlich den markierten Block aus `references/profile.template.ps1`, sichert die bestehende Datei und prüft die PowerShell-Syntax.
- **VS Code:** `scripts/update-vscode-settings.ps1` ändert nur `terminal.integrated.fontFamily` und `terminal.integrated.gpuAcceleration`, mit Backup und ohne fremde JSONC-Einstellungen zu ersetzen.
- **Machine-PATH:** Entferne nur bestätigte Werte über `scripts/invoke-clean-machine-path.ps1` mit JSON-Request. Das erhöhte Skript sichert den Registry-Rohwert selbst.
- **Module:** Admin-Module nie automatisch entfernen; bei normalen CurrentUser-Modulen bleibt die neueste Version.

Temporäre Requestdateien nach dem Lauf löschen. Keine persönliche Alias- oder Git-Kürzel-Sammlung in ein neues Profil schreiben.

## 5. Verifikation

- Profilstart mit und ohne `-NoProfile` je 2–3-mal messen.
- Theme vor dem Umschalten und danach mit `oh-my-posh debug --plain --config <pfad>` prüfen.
- PATH und Tool-Herkunft in einer neuen Shell verifizieren.
- Installierte Editorvariante über ihre EXE, nicht über übrig gebliebene Settings-Verzeichnisse bestätigen.
- Backups mit exaktem Pfad nennen; Löschung erst nach einem Arbeitstag ohne Befund empfehlen.

Der Abschluss enthält eine kompakte Vorher-/Nachher-Tabelle und nur echte manuelle Restschritte.

# Best Practice: Windows-PowerShell-Dev-Umgebung

Zielzustand für `/windev:setup` und Maßstab für `/windev:optimize`. Erarbeitet und vermessen am 18.07.2026; Zahlen sind Richtwerte einer realen Maschine.

## Komponenten

| Komponente | Zweck | Warum so |
| --- | --- | --- |
| PowerShell 7 (`pwsh`) | Standardshell | Windows PowerShell 5.1 nur noch für Alt-Module |
| Git | — | `init.defaultBranch main` |
| Oh My Posh + eigenes schlankes Theme | Prompt | Default-Theme führt `node --version` bei jedem Enter aus (~550 ms) — deshalb nie ungetuned lassen |
| „CaskaydiaCove NF" (Nerd Font) | Glyphen | Installieren reicht nicht — im Terminal-`fontFamily` **setzen**, sonst □-Kästchen |
| zoxide (`z`) | Verzeichnis-Sprünge | Init ~80 ms, laufender Hook praktisch kostenlos |
| Terminal-Icons | Datei-Icons | Rein kosmetisch, ~480 ms Import → nur lazy laden |
| PSReadLine | Vorschläge/History | ListView-Prediction, HistorySearch auf Pfeiltasten |

## Profil-Prinzipien

1. **Guard zuerst.** Nicht-interaktive Aufrufe (`-Command`, `-NonInteractive`, umgeleitete Ein-/Ausgabe) verlassen das Profil in Zeile 1. Warum: Automatisierung (Agenten, Skripte, CI) zahlt sonst die volle Profilzeit pro Aufruf, und `Set-PSReadLineOption` wirft ohne Konsolen-Handle Fehler. Muster: siehe `profile.template.ps1`.
2. **Kosmetik lazy.** Module, die nur die Ausgabe verschönern, per `Register-EngineEvent PowerShell.OnIdle -MaxTriggerCount 1` nachladen — der Prompt steht sofort.
3. **Kein Remote-Code im Profil.** Keine Funktionen, die per `irm | iex` fremden Code ausführen, und keine, die das Profil selbst aus dem Netz überschreiben — ein Tippfehler vernichtet sonst alle eigenen Anpassungen.
4. **Pfade dynamisch.** Documents immer via `[Environment]::GetFolderPath('MyDocuments')` bzw. `$PSScriptRoot` — OneDrive Known Folder Move verschiebt den Ordner.
5. **Fremd-Integrationen respektieren.** Auto-generierte Marker-Blöcke anderer Tools unverändert lassen.

## Prompt-Prinzipien

- **Kein Segment darf pro Enter einen Prozess starten**, dessen Ergebnis sich selten ändert (Sprachversionen!). Entfernen oder cachen.
- **Git-Status ist eine bewusste Entscheidung**: Änderungszahlen kosten je nach Repo 100–400 ms (Untergrenze = rohes `git status`), Upstream-/Origin-Abfrage bringt fast nie etwas → `fetch_upstream_icon: false`.
- Segmente ohne Messkosten (Uhrzeit, Shell-Name) sind Geschmack, keine Optimierungsmasse.
- Messen mit `oh-my-posh debug --plain [--config …]` — Segmentliste mit Millisekunden.

## Hygiene-Regeln

- **PATH**: Registry-Rohwerte mit `DoNotExpandEnvironmentNames` lesen, dann jeden Eintrag mit `ExpandEnvironmentVariables` prüfen. `%SystemRoot%\System32` und andere erfolgreich expandierende Einträge sind gültig; nur nicht aufgelöste Variablen oder fehlende expandierte Pfade melden. Tote Einträge und Duplikate raus; Machine-PATH-Änderungen brauchen Admin, immer mit Rohwert-Backup und `WM_SETTINGCHANGE`-Broadcast, `REG_EXPAND_SZ` erhalten.
- **Module**: pro Modul nur die neueste Version behalten; Admin-Module (Graph/M365) nur nach Rückfrage anfassen.
- **Backups datiert** (`.backup-yyyyMMdd`), genau eines pro Artefakt, Löschung erst nach bestandenem Praxistest.
- **Editor-Terminal**: installierte Variante per EXE prüfen — User-Installer unter `%LOCALAPPDATA%\Programs`, System-Installer unter `%ProgramFiles%`/`%ProgramFiles(x86)%` (Settings-Ordner überleben Deinstallationen); `gpuAcceleration` auf `auto` lassen — `off` erzwingt langsames DOM-Rendering.

## Messmethodik

- Start: `Measure-Command { pwsh [-NoProfile] -Command 1 }`, je 2–3×; die Differenz ist die Profilkosten. Absolutwerte schwanken mit Systemlast — Verhältnisse zählen.
- Prompt: `oh-my-posh debug --plain`; daneben rohes `git status` als Untergrenze im selben Repo.
- Erfolgskriterien: nicht-interaktiver Start ≈ No-Profile-Baseline und fehlerfrei; kein Prompt-Segment > ~100 ms außer bewusst gewähltem Git-Status; keine □-Kästchen.

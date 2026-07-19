---
description: Windows-Dev-Umgebung nach Best Practice einrichten — inventarisiert, fragt, installiert (PowerShell 7, Git, Oh My Posh + Nerd Font, zoxide, Profil, VS Code) und verifiziert; funktioniert auch auf frischem Windows.
disable-model-invocation: true
---

# windev:setup — Windows-Entwicklungsumgebung einrichten

Ziel ist der Zustand aus `${CLAUDE_SKILL_DIR}/../../references/best-practice.md` — lies die Datei zuerst, sie erklärt jedes Warum und die Messmethodik.

**Grundprinzip: kein Schreibzugriff ohne Freigabe.** Auch wenn die Session mit übersprungenen Permissions läuft: Jede Phase endet mit AskUserQuestion, umgesetzt wird nur, was der Nutzer gewählt hat. Bestehendes (Profil, Settings, Themes) wird nie ohne datiertes Backup und ohne Zustimmung überschrieben — der Nutzer weiß Dinge über seine Maschine, die die Inventur nicht sieht.

## Phase 0 — PowerShell 7 bootstrappen

Zuerst mit dem auf jedem unterstützten Windows vorhandenen `powershell.exe` prüfen, ob `pwsh` und `winget` verfügbar sind:

```
powershell.exe -NoProfile -Command "Get-Command pwsh,winget -ErrorAction SilentlyContinue | Select-Object Name,Source"
```

Fehlt `pwsh`, **vor jeder Inventur** erklären, dass die folgenden Skripte PowerShell 7 benötigen, und die Installation via AskUserQuestion freigeben lassen. Bei Zustimmung mit Windows PowerShell ausführen:

```
winget install --id Microsoft.PowerShell --exact --accept-source-agreements --accept-package-agreements
```

Danach `C:\Program Files\PowerShell\7\pwsh.exe` direkt verifizieren und diesen absoluten Pfad für die restliche Session verwenden; der PATH des laufenden Agent-Prozesses kennt die Neuinstallation eventuell noch nicht. Fehlt auch `winget`, App Installer (Store oder offizielles GitHub-Release) mit dem Nutzer klären. Ohne bestätigtes `pwsh` nicht mit der Inventur fortfahren.

## Phase 1 — Inventur (read-only)

```
pwsh -NoProfile -File "$CLAUDE_PLUGIN_ROOT/scripts/measure-environment.ps1"
```

Auf frischem Windows meldet vieles „fehlt" — das ist der Normalfall, kein Fehler. Existiert schon ein Profil oder eine Oh-My-Posh-Konfiguration, erst lesen und verstehen, was der Nutzer sich dort eingerichtet hat. Kann der Bericht die aktive OMP-Konfiguration nicht aus `POSH_CONFIG` oder einem literalen `--config`-Profilpfad ermitteln, den Pfad aus dem Profil auflösen und die Inventur explizit mit `-OhMyPoshConfig <pfad>` wiederholen; nie das eingebaute Default-Theme als Messwert ausgeben.

## Phase 2 — Rückfragen

Eine AskUserQuestion-Runde (max. 4 Fragen, Empfehlung als erste Option markieren):

1. **Komponenten** (multiSelect): PowerShell 7 · Git · Oh My Posh + Nerd Font · zoxide · Terminal-Icons · VS Code (Stable oder Insiders?) · Node via NVM for Windows · Bun
2. **Prompt-Detailgrad**: Git-Änderungszahlen anzeigen (informativ, kostet je nach Repo 100–400 ms) oder nur Branch (schnellstmöglich)?
3. **Git-Identität** (`user.name`/`user.email`), falls Git gewählt und noch nicht konfiguriert
4. **Profil**: Template übernehmen, oder — falls ein Profil existiert — Merge-Vorschlag zeigen?

Bei bestehendem Profil: Konflikte konkret benennen (welche Funktion/Einstellung kollidiert womit), Vorschlag zeigen, dann erst schreiben.

## Phase 3 — Installation (nur Genehmigtes)

winget-IDs: `Microsoft.PowerShell` · `Git.Git` · `JanDeDobbeleer.OhMyPosh` · `ajeetdsouza.zoxide` · `Microsoft.VisualStudioCode` / `Microsoft.VisualStudioCode.Insiders` · `CoreyButler.NVMforWindows` · `Oven-sh.Bun`

- Erster winget-Lauf auf frischer Maschine: `--accept-source-agreements --accept-package-agreements` mitgeben.
- Nerd Font ohne Adminrechte: `oh-my-posh font install CascadiaCode` (installiert „CaskaydiaCove NF" in den User-Scope).
- Terminal-Icons: `Install-Module Terminal-Icons -Scope CurrentUser -Force`.
- Nach jedem Install per `Get-Command` verifizieren (neue Shell nötig, wenn PATH sich geändert hat: `$env:Path` im laufenden Prozess aktualisiert sich nicht von selbst). Fehler sofort benennen statt weiterzumachen.

## Phase 4 — Konfiguration

1. **Theme**: `pwsh -NoProfile -File "$CLAUDE_PLUGIN_ROOT/scripts/new-slim-theme.ps1"` — verwendet die mitgelieferte `assets/base.omp.json` explizit als Quelle. Parameter entsprechend Phase-2-Antworten (`-GitStatusCounts`, `-RemoveRightPrompt`); eine andere genehmigte Quelle nur via `-SourceConfig <pfad>`.
2. **Profil**: `${CLAUDE_SKILL_DIR}/../../references/profile.template.ps1` nach `<Documents>\PowerShell\Microsoft.PowerShell_profile.ps1` bringen. Documents **immer** über `[Environment]::GetFolderPath('MyDocuments')` auflösen — OneDrive Known Folder Move verschiebt den Ordner, harte Pfade brechen. Bestehendes Profil vorher als `Microsoft.PowerShell_profile.ps1.backup-<yyyyMMdd>.ps1` sichern.
3. **VS Code**: `"terminal.integrated.fontFamily": "CaskaydiaCove NF"` in die settings.json der **tatsächlich installierten** Variante (Stable: `%APPDATA%\Code`, Insiders: `%APPDATA%\Code - Insiders`). User-Installer unter `%LOCALAPPDATA%\Programs`, System-Installer unter `%ProgramFiles%` (ggf. `%ProgramFiles(x86)%`) prüfen — Settings-Ordner überleben Deinstallationen und führen sonst in die Irre. `terminal.integrated.gpuAcceleration` auf Default (`auto`) lassen.
4. **Git**: `git config --global user.name/user.email` gemäß Antwort; `init.defaultBranch main` anbieten.

## Phase 5 — Verifikation & Abschluss

- `pwsh -Command 1`: fehlerfrei und nahe der No-Profile-Zeit (der Guard greift; 2–3× messen, Streuung ist normal).
- `oh-my-posh debug --plain --config <theme>`: kein Segment über ~100 ms, außer Git in großen/ungecommitteten Repos — dort rohes `git status` daneben messen, das ist die Untergrenze.
- Neues Terminal öffnen (lassen): Glyphen statt □-Kästchen, Icons erscheinen kurz nach dem ersten Prompt (Lazy-Load ist Absicht).

Abschlussbericht als Tabelle: installiert / übersprungen / Messwerte; manuelle Restschritte (Terminal neu öffnen, ggf. Editor-Neustart) explizit nennen.

## Fallstricke

- Der `oh-my-posh`-Alias unter `WindowsApps` kostet ~150 ms Prozessstart pro Prompt — bekannt und akzeptabel, nicht „reparieren".
- `pwsh -File skript.ps1` mit umgeleiteter Ausgabe lädt das Profil dank Guard nicht — gewollt. Skripte dürfen sich nie auf Profil-Funktionen verlassen.
- Exportierte OMP-Themes haben teils `properties: null` an Segmenten; Properties nur mit `Add-Member -Force` setzen (macht `new-slim-theme.ps1` bereits richtig).

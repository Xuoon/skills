---
name: windev
description: Windows-Dev-Umgebung vermessen, bereinigen oder neu einrichten (PowerShell, Prompt, PATH, Module, VS Code).
argument-hint: "[--fix | --setup]"
disable-model-invocation: true
allowed-tools: Bash(pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/measure-environment.ps1"*) Read AskUserQuestion
---

# windev — Windows-Entwicklungsumgebung

Der Zielzustand samt Warum und Messmethodik steht in `${CLAUDE_SKILL_DIR}/references/best-practice.md` — **zuerst lesen**.

## Argumente (`$ARGUMENTS`)

| Flag | Bedeutung |
| --- | --- |
| *(ohne Flag)* | Umgebung vollständig vermessen und berichten. **Read-only, keine Änderung** |
| `--fix` | Die gefundenen Befunde abarbeiten — mit Backup vor jeder Änderung |
| `--setup` | Umgebung nach Best Practice einrichten (auch auf frischem Windows) |

Jede Empfehlung nennt ihren Messwert — **ohne Zahl keine Behauptung**. Ehrlich einordnen, was wenig bringt (PATH-Bereinigung ist Hygiene, kein Speed).

## Analyse (Standard)

```
pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/measure-environment.ps1"
```

Kann der Bericht die aktive OMP-Konfiguration nicht aus `POSH_CONFIG` oder einem literalen `--config`-Profilpfad ermitteln, den Pfad beim Lesen der Profile auflösen und die Inventur mit `-OhMyPoshConfig <pfad>` wiederholen. Danach gezielt vertiefen — der Bericht zeigt, wo:

1. **Startzeit**: Differenz mit/ohne Profil = Profilkosten. Je 2–3× messen; Systemlast verzerrt Einzelwerte.
2. **Prompt**: Segmente über ~100 ms sind die Täter (typisch: Sprachversions-Segmente wie `node`, Git-Status). Zum Vergleich rohes `git status` im selben Repo messen — schneller als das kann kein Prompt-Segment sein.
3. **Profile lesen** (alle vier `$PROFILE`-Pfade + WindowsPowerShell): Risikomuster sind Remote-Code-Ausführung (`irm | iex`), Funktionen die das Profil selbst aus dem Netz überschreiben, blockierende `Import-Module` rein kosmetischer Module, Start-Banner, fehlender Nicht-interaktiv-Guard.
4. **PATH**: Prozess- vs. HKCU- vs. HKLM-**Rohwert** (`DoNotExpandEnvironmentNames` — sonst sieht man wörtliche `%VAR%`-Einträge nicht). Tote Einträge, Duplikate, fremde Benutzerpfade. Notieren, was in Machine liegt (braucht Admin) und was in User.
5. **Module**: Mehrfachversionen. Admin-Module (Graph/Exchange/SharePoint/PnP) nie ungefragt anfassen — ob sie gebraucht werden, weiß nur der Nutzer.
6. **Editor-Terminal**: Welche VS-Code-Variante ist **wirklich** installiert (EXE prüfen — Settings-Ordner überleben Deinstallationen und täuschen). `fontFamily` gesetzt? `gpuAcceleration` deaktiviert?
7. **Dateileichen**: alte `.bak`-Profile, verwaiste Skript-Versionen, ungenutzte Themes.
8. **Kein Handlungsbedarf** — gar nicht erst vorschlagen: PSReadLine-Historie unter ein paar MB, zoxide-Hooks, OSC-Shell-Integrationen, pauschale Defender-Ausnahmen, WSL-Wechsel für Windows-Target-Projekte.

Bericht als kompakte Tabelle: Befund · Messwert · Wirkung · Risiko. Was ein anderer Agent oder der Nutzer behauptet hat, vorher selbst nachmessen. **Ohne `--fix` endet der Lauf hier.**

## Beheben (`--fix`)

Die Befunde werden abgearbeitet, ohne vorher zu fragen — **aber nie ohne Backup**. Reihenfolge: Backups → sichtbare Fixes (Font) → Theme/Profil → Aufräumen (Dateien, PATH, Module) → Nachmessen.

- **Profil**: vorher als `.backup-<yyyyMMdd>.ps1` sichern; Umbau nach dem Muster aus `${CLAUDE_SKILL_DIR}/references/profile.template.ps1` (Guard zuerst, kosmetische Module lazy). Nutzerspezifische Blöcke (Fremd-Tool-Integrationen zwischen Markern) unverändert übernehmen.
- **Theme**: `pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/new-slim-theme.ps1" -SourceConfig <aktive-config> -OutPath <neue-config>`. Nie das aktive Theme überschreiben; erst nach dem Praxistest im Profil umschalten.
- **Machine-PATH**: die zu entfernenden Einträge als JSON-Array in eine temporäre Requestdatei schreiben, z. B. `{"remove":["C:\\Alt","C:\\Program Files\\Alt"]}`, dann `pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/invoke-clean-machine-path.ps1" -RequestFile <request.json>`. Der Wrapper rekonstruiert das Array, eleviert mit einem kodierten Befehl und prüft den Exitcode; `clean-machine-path.ps1` sichert den HKLM-Rohwert vorher selbst. Requestdatei anschließend löschen. Windows-`sudo` kann per Policy deaktiviert sein; **danach zusätzlich den Registry-Ist-Zustand verifizieren**.
- **Module**: `Uninstall-Module -RequiredVersion <alt>`; schlägt das fehl, den Versionsordner unter `<Documents>\PowerShell\Modules\<Name>\<Version>` löschen. Nur alte Versionen, die neueste bleibt.

**Trotzdem fragen** bei: Admin-Modulen (Graph/Exchange/SharePoint/PnP), einem UAC-Prompt für den Machine-PATH, und allem, wo die Analyse „brauchst du X noch?" nicht selbst beantworten kann. Das sind echte Nutzer-Entscheidungen, keine Freigaben — Faktenfragen dagegen durch Messen klären.

Abschluss: Vorher/Nachher-Tabelle (Startzeit, Prompt-Render, PATH-Einträge, entfernte Dateien/Module). Alle Backups auflisten mit dem Hinweis, sie erst nach bestandenem Praxistest (neues Terminal, ein Arbeitstag) zu löschen.

## Einrichten (`--setup`)

### Phase 0 — PowerShell 7 bootstrappen

Zuerst mit dem auf jedem unterstützten Windows vorhandenen `powershell.exe` prüfen, ob `pwsh` und `winget` da sind:

```
powershell.exe -NoProfile -Command "Get-Command pwsh,winget -ErrorAction SilentlyContinue | Select-Object Name,Source"
```

Fehlt `pwsh`, **vor jeder Inventur** erklären, dass die folgenden Skripte PowerShell 7 brauchen, und mit Windows PowerShell installieren:

```
winget install --id Microsoft.PowerShell --exact --accept-source-agreements --accept-package-agreements
```

Danach `C:\Program Files\PowerShell\7\pwsh.exe` direkt verifizieren und diesen absoluten Pfad für die restliche Session verwenden; der PATH des laufenden Agent-Prozesses kennt die Neuinstallation eventuell noch nicht. Fehlt auch `winget`, App Installer (Store oder offizielles GitHub-Release) mit dem Nutzer klären. Ohne bestätigtes `pwsh` nicht fortfahren.

### Phase 1 — Inventur

Analyse wie oben. Auf frischem Windows meldet vieles „fehlt" — das ist der Normalfall, kein Fehler. Existiert schon ein Profil oder eine Oh-My-Posh-Konfiguration, erst lesen und verstehen, was der Nutzer sich dort eingerichtet hat.

### Phase 2 — Rückfragen

Eine AskUserQuestion-Runde (max. 4 Fragen, Empfehlung als erste Option). Das sind Konfigurations-Entscheidungen, keine Freigaben — ohne sie wird ungefragt Software installiert:

1. **Komponenten** (multiSelect): PowerShell 7 · Git · Oh My Posh + Nerd Font · zoxide · Terminal-Icons · VS Code (Stable oder Insiders?) · Node via NVM for Windows · Bun
2. **Prompt-Detailgrad**: Git-Änderungszahlen anzeigen (informativ, kostet je nach Repo 100–400 ms) oder nur Branch (schnellstmöglich)?
3. **Git-Identität** (`user.name`/`user.email`), falls Git gewählt und noch nicht konfiguriert
4. **Profil**: Template übernehmen, oder — falls ein Profil existiert — Merge-Vorschlag zeigen?

Bei bestehendem Profil: Konflikte konkret benennen (welche Funktion/Einstellung kollidiert womit), Vorschlag zeigen, dann erst schreiben.

### Phase 3 — Installation (nur Gewähltes)

winget-IDs: `Microsoft.PowerShell` · `Git.Git` · `JanDeDobbeleer.OhMyPosh` · `ajeetdsouza.zoxide` · `Microsoft.VisualStudioCode` / `Microsoft.VisualStudioCode.Insiders` · `CoreyButler.NVMforWindows` · `Oven-sh.Bun`

- Erster winget-Lauf auf frischer Maschine: `--accept-source-agreements --accept-package-agreements` mitgeben.
- Nerd Font ohne Adminrechte: `oh-my-posh font install CascadiaCode` (installiert „CaskaydiaCove NF" in den User-Scope).
- Terminal-Icons: `Install-Module Terminal-Icons -Scope CurrentUser -Force`.
- Nach jedem Install per `Get-Command` verifizieren (neue Shell nötig, wenn PATH sich geändert hat: `$env:Path` im laufenden Prozess aktualisiert sich nicht von selbst). Fehler sofort benennen statt weiterzumachen.

### Phase 4 — Konfiguration

1. **Theme**: `pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/new-slim-theme.ps1"` — verwendet die mitgelieferte `assets/base.omp.json` als Quelle. Parameter entsprechend Phase 2 (`-GitStatusCounts`, `-RemoveRightPrompt`); eine andere Quelle nur via `-SourceConfig <pfad>`.
2. **Profil**: `${CLAUDE_SKILL_DIR}/references/profile.template.ps1` nach `<Documents>\PowerShell\Microsoft.PowerShell_profile.ps1` bringen. Documents **immer** über `[Environment]::GetFolderPath('MyDocuments')` auflösen — OneDrive Known Folder Move verschiebt den Ordner, harte Pfade brechen. Bestehendes Profil vorher als `Microsoft.PowerShell_profile.ps1.backup-<yyyyMMdd>.ps1` sichern.
3. **VS Code**: `"terminal.integrated.fontFamily": "CaskaydiaCove NF"` in die settings.json der **tatsächlich installierten** Variante (Stable: `%APPDATA%\Code`, Insiders: `%APPDATA%\Code - Insiders`). User-Installer unter `%LOCALAPPDATA%\Programs`, System-Installer unter `%ProgramFiles%` (ggf. `%ProgramFiles(x86)%`) prüfen — Settings-Ordner überleben Deinstallationen und führen sonst in die Irre. `terminal.integrated.gpuAcceleration` auf Default (`auto`) lassen.
4. **Git**: `git config --global user.name/user.email` gemäß Antwort; `init.defaultBranch main` anbieten.

### Phase 5 — Verifikation

- `pwsh -Command 1`: fehlerfrei und nahe der No-Profile-Zeit (der Guard greift; 2–3× messen, Streuung ist normal).
- `oh-my-posh debug --plain --config <theme>`: kein Segment über ~100 ms, außer Git in großen/ungecommitteten Repos — dort rohes `git status` daneben messen, das ist die Untergrenze.
- Neues Terminal öffnen (lassen): Glyphen statt □-Kästchen, Icons erscheinen kurz nach dem ersten Prompt (Lazy-Load ist Absicht).

Abschlussbericht als Tabelle: installiert / übersprungen / Messwerte; manuelle Restschritte (Terminal neu öffnen, ggf. Editor-Neustart) explizit nennen.

## Fallstricke

- Der `oh-my-posh`-Alias unter `WindowsApps` kostet ~150 ms Prozessstart pro Prompt — bekannt und akzeptabel, nicht „reparieren".
- `pwsh -File skript.ps1` mit umgeleiteter Ausgabe lädt das Profil dank Guard nicht — gewollt. Skripte dürfen sich nie auf Profil-Funktionen verlassen.
- Exportierte OMP-Themes haben teils `properties: null` an Segmenten; Properties nur mit `Add-Member -Force` setzen (macht `new-slim-theme.ps1` bereits richtig).

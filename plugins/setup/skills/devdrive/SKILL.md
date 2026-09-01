---
name: devdrive
description: Nur bei ausdrücklichem Nutzerwunsch ein Windows Dev Drive anlegen und ausgewählte Caches oder Repos dorthin umziehen.
compatibility: Benötigt Windows 11 ab Build 22621.2338 und PowerShell 7.
argument-hint: "[--fix]"
---

# devdrive — Dev Drive einrichten und befüllen

Zielzustand, Begründungen und die Umzugstabelle je Toolchain stehen in `references/best-practice.md`, **zuerst lesen**. Den Skill-Root über den aktiven Skill-Kontext absolut auflösen und für `<skill-root>` einsetzen; niemals Bundle-Dateien relativ zum aktuellen Repo ausführen.

## Argumente aus der Nutzeranfrage

| Flag | Bedeutung |
| --- | --- |
| _(ohne Flag)_ | Inventur und Befund mit konkretem Einrichtungsplan. **Read-only, keine Änderung** |
| `--fix` | Einrichtungsplan interaktiv abstimmen, ausführen und verifizieren |

Der Skill entscheidet nichts, was der Nutzer entscheiden kann: Form, Ort, Größe, Laufwerksbuchstabe, Label, jeder einzelne Umzugskandidat. Was nicht gefragt wurde, wird nicht gemacht.

## 0. PowerShell 7 vorprüfen

Mit dem auf Windows vorhandenen `powershell.exe` prüfen:

```powershell
powershell.exe -NoProfile -Command "Test-Path (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe')"
```

Fehlt die systemweit geschützte `C:\Program Files\PowerShell\7\pwsh.exe`, vor der Inventur abbrechen und den `windev`-Skill mit `--best-practice` oder im ursprünglichen Nutzerprozess `winget install --id Microsoft.PowerShell --exact --source winget --installer-type wix` anbieten; der WIX-Installer fordert die nötige UAC-Freigabe selbst an. Seit PowerShell 7.6 liefert der Standard ohne `--installer-type wix` MSIX statt MSI. Eine vorhandene User-/MSIX-Version nicht verwenden: Der UAC-Wrapper akzeptiert absichtlich nur das geschützte System-Binary. Keine Skripte mit Windows PowerShell 5.1 ausführen.

## 1. Inventur (read-only)

```
& "$env:ProgramFiles\PowerShell\7\pwsh.exe" -NoProfile -File "<skill-root>/scripts/measure-devdrive.ps1"
```

Kennt der Nutzer weitere Repo-Wurzeln, als JSON-Array in eine temporäre Datei schreiben und mit `-RepoRootsFile <roots.json>` wiederholen. Der Bericht liefert: Windows-Build, Datenträger samt größtem nicht zugeordnetem Bereich, vorhandene ReFS-Volumes und deren Trust, angehängte VHDX, Mount-Tasks, installierte Toolchains, gesetzte Cache-Variablen, Umzugskandidaten mit Größe, gefundene Repos. Die temporäre Datei danach löschen.

Ist Windows älter als Build 22621.2338: abbrechen und sagen warum. Existiert schon ein trusted Dev Drive: Anlage überspringen, aber bei einer VHDX zuerst Backing-Pfad und Neustart-Mount prüfen. Fehlt ein passender Mount-Task, vor jedem Umzug abfragen, ob der Task registriert wird oder der Nutzer das Laufwerk nach jedem Neustart manuell anhängt; die manuelle Wahl als offenen Restschritt ausgeben.

## 2. Befund

Kurze Liste: was da ist, was fehlt, was umziehen könnte (mit MB), was bewusst bleibt. Jede Zeile mit Wert aus dem Bericht, **ohne Messwert keine Behauptung**. Nachteile nennen (Mount-Task, Backup-Verhalten der VHDX, Fremd-AV-Filter, ReFS-Einschränkungen für WSL-Metadaten). Microsoft empfiehlt Dev Drives primär für Repos, Paket-Caches und Build-Ausgaben; Tool-Binaries nur nach ausdrücklicher Auswahl und Hinweis auf asynchrones Defender-Scanning verschieben. Was ein anderer Agent oder der Nutzer über den Zustand behauptet hat, vorher selbst nachmessen.

Ohne `--fix` hier mit einem konkreten Plan enden: empfohlene Form, Host, Größe und Laufwerksbuchstabe sowie mögliche Umzugskandidaten. Nichts fragen oder verändern.

## 3. Fragerunde Anlage

Strukturierte Nutzereingabe verwenden, ersatzweise die Fragen gebündelt im Chat stellen. Empfehlung als erste Option, nur Fragen mit echter Entscheidung:

1. **Form**: VHDX (Standard, rückbaubar) oder Partition in mindestens 50 GB nicht zugeordnetem Bereich (nur anbieten, wenn der Bericht einen unterstützten lokalen Datenträger mit genug zusammenhängendem Platz zeigt)
2. **Ort und Größe**: unterstütztes lokales Laufwerk mit dem meisten freien Platz vorschlagen, Größe als konkrete Zahl (Faustregel: Summe aller plausiblen Kandidaten plus Repos mal drei, mindestens 100 GB), dynamisch. Der Host muss zusätzlich mindestens 20 GB Reserve behalten; das Skript erlaubt auch bei dynamischen VHDX kein Overcommit.
3. **Laufwerksbuchstabe und Label**: freien Buchstaben vorschlagen
4. **Mount-Task** bei VHDX: ja (Standard) oder selbst kümmern

Eine belegte Antwort nicht nochmal fragen. Keine Freigabe-Fragen wie „darf ich anfangen?", die Fragerunde ist die Freigabe.

## 4. Anlegen (elevated)

Alles, was Datenträger anfasst, läuft über den Wrapper. Requestfile als JSON in ein Temp-Verzeichnis schreiben, dann:

```
& "$env:ProgramFiles\PowerShell\7\pwsh.exe" -NoProfile -File "<skill-root>/scripts/invoke-elevated.ps1" -RequestFile <request.json>
```

Anlage, Beispiel VHDX:

```json
{ "script": "new-devdrive.ps1", "parameters": { "ImagePath": "D:\\Coding\\Coding.vhdx", "SizeGB": 200, "DriveLetter": "V", "Label": "Coding" } }
```

Partition: statt `ImagePath` den `DiskNumber`, optional `SizeGB`, sonst der ganze freie Bereich. Feste Größe nur auf Wunsch (`"Fixed": true`).

Mount-Task danach, nur bei VHDX und nur wenn gewählt:

```json
{ "script": "register-mount-task.ps1", "parameters": { "ImagePath": "D:\\Coding\\Coding.vhdx" } }
```

Der Wrapper gibt die Ausgabe des erhöhten Skripts zurück, darin Trust-Status und die Filterliste. Requestfiles anschließend löschen. Schlägt die Elevation fehl (UAC abgelehnt, AdminByRequest ohne Freigabe, `sudo`-Policy): Fehler benennen, nichts wiederholen, den Nutzer entscheiden lassen. **Der erhöhte Schritt formatiert nie ein Volume, das bereits ein Dateisystem trägt.**

## 5. Fragerunden Umzug

Erst jetzt, mit dem fertigen Laufwerk als Fakt. Kandidaten in mehrere überschaubare Runden aufteilen; pro MultiSelect-Frage höchstens vier Optionen, bis jeder Kandidat explizit angeboten oder begründet ausgeschlossen wurde:

1. **Toolchains und Caches** (multiSelect): nur die Kandidaten, die im Bericht existieren, jeder mit Größe, vollständigem Quellpfad und dem Modus `Move` oder `Discard` aus der Referenz im Optionslabel. `Discard` nur für den dokumentierten Standardpfad anbieten; benutzerdefinierte Cachepfade werden mit `Move` erhalten. Die Auswahl eines `Discard`-Kandidaten ist die ausdrückliche Entscheidung, exakt diesen regenerierbaren Cache zu löschen. Empfehlung vorausgewählt: Paket-Caches und die von Microsoft dokumentierten Cache-Verzeichnisse. Tool-Binaries und SDKs nicht vorauswählen. Was laut Referenz bleibt (Node-Installation, Python, Docker), gar nicht erst als Option anbieten, nur im Befund erwähnen.
2. **Repos** (multiSelect): jedes gefundene Repo einzeln, Ziel `X:\<username>\repos\<ordnername>`. Repos, die WSL-POSIX-Rechte oder die WSL-Option `metadata` brauchen, nicht empfehlen. Verknüpfte Git-Worktrees und Haupt-Repos mit `.git/worktrees` nicht anbieten; sie brauchen einen eigenen gemeinsamen Umzugs- und `git worktree repair`-Plan.
3. **Zielstruktur** separat: `X:\<username>\.cache` und `X:\<username>\repos` (Standard, pro Nutzer getrennt) oder eigene Namen

Vor der ersten Repo-Frage alle vorgeschlagenen Zielpfade vergleichen. Haben mehrere Repos denselben Ordnernamen, eindeutige Zielnamen aus dem jeweiligen Elternordner vorschlagen und diese Namen mit abfragen; kein Ziel darf doppelt vorkommen.

Vor dem Umzug: Terminals, Editoren und laufende Builds schließen lassen, sonst scheitert die Kopie an offenen Handles. Nicht selbst beenden.

## 6. Umzug (User-Scope, kein Admin)

Pro Kandidat ein Aufruf, Parameter aus der Umzugstabelle der Referenz. Pfade immer als aufgelöste Literale aus dem Bericht übergeben — Ausdrücke wie `$env:USERPROFILE` würden vom umgebenden Bash falsch interpretiert. Variablen als JSON-Objekt in eine temporäre Datei schreiben und mit `-EnvFile` übergeben. `Discard` nur für regenerierbare Standard-Caches und immer mit `-ConfirmDiscardPath '<exakter Source-Pfad>'`:

```
& "$env:ProgramFiles\PowerShell\7\pwsh.exe" -NoProfile -File "<skill-root>/scripts/move-toolchain.ps1" -Name Cargo -Mode Move -Source '<Ist-Pfad aus Bericht>' -Target '<Zielpfad>' -EnvFile '<env-cargo.json>' -PathReplace '<alter-bin-Pfad>=><neuer-bin-Pfad>'
```

Das Skript sichert die betroffenen User-Variablen und den PATH vorher als JSON nach `<Documents>\PowerShell\`. Env-Requestdateien nach dem Aufruf löschen. Repos ebenfalls mit `-Mode Move`, ohne `-EnvFile`. Für Maven vorhandene `MAVEN_OPTS` erhalten und `-Dmaven.repo.local=<ziel>` anhängen oder nach Nutzerwahl `settings.xml` verwenden. Für pnpm nach dem Verwerfen des alten Stores `pnpm config set store-dir <ziel>` ausführen. Fehler eines Kandidaten stoppen die anderen nicht, werden aber im Abschluss gelistet.

## 7. Verifikation

Die User-Prüfung in einer **neuen, nicht erhöhten Shell des ursprünglichen Nutzers** ausführen; nur dort stimmen User-Variablen, PATH, Tool-Herkunft sowie pnpm-/Maven-Kontext:

```powershell
& "$env:ProgramFiles\PowerShell\7\pwsh.exe" -NoProfile -File "<skill-root>/scripts/test-devdrive.ps1" -DriveLetter V -ExpectedEnv 'BUN_INSTALL_CACHE_DIR,CARGO_HOME' -ExpectedTools 'cargo' -ExpectedPnpmStore '<pnpm-Ziel>' -ExpectedMavenRepository '<maven-Ziel>'
```

Trust und Mount-Task getrennt als JSON-Request über den abgesicherten Wrapper prüfen:

```json
{ "script": "test-devdrive-admin.ps1", "parameters": { "DriveLetter": "V", "ExpectedImagePath": "<VHDX-Pfad>" } }
```

```powershell
& "$env:ProgramFiles\PowerShell\7\pwsh.exe" -NoProfile -File "<skill-root>/scripts/invoke-elevated.ps1" -RequestFile <request.json>
```

Optionale Parameter nur für tatsächlich gewählte Kandidaten angeben. `-ExpectedEnv` ist eine kommaseparierte Liste der gesetzten, rein pfadwertigen Variablen. `-ExpectedTools` enthält kommasepariert nur Executables, deren Installationspfad tatsächlich umgezogen ist; bei reinen Caches bleibt es weg. `ExpectedImagePath` im Admin-Request nur setzen, wenn bei einer VHDX der Mount-Task gewählt wurde.

Abschluss: angelegt / umgezogen / übersprungen als kurze Liste, Backup-Dateien nennen, dann `---` und „Du machst:" mit den Restschritten (neues Terminal, Prüfskript, nach dem nächsten Neustart nochmal prüfen).

## Fallstricke

- Die Einstellungen-App (System → Speicher → Datenträger) scheitert mit `0x80070005`, wenn der Nutzer nicht dauerhaft Admin ist. Deshalb der Wrapper, nicht die Oberfläche.
- `New-VHD` wird genutzt, wenn das Hyper-V-Modul vorhanden ist. Sonst erzeugt `diskpart` die VHDX; dieser Fallback verlangt wegen der Skriptkodierung einen reinen ASCII-Pfad. Das Anhängen läuft immer über `Mount-DiskImage`.
- `fsutil devdrv query` antwortet lokalisiert. Deutsch und Englisch werden als `trusted`/`untrusted` ausgewertet; andere Sprachen bleiben ausdrücklich `unbekannt`, statt als untrusted zu gelten. Bei einem bestehenden Volume wirkt `fsutil devdrv trust` erst nach Remount oder Neustart; nur das frisch formatierte, noch leere Volume darf dafür `/f` verwenden.
- Mehrere Filter am Volume (`WdFilter, <Fremd-AV>`) sind kein Fehler, nur ein Hinweis: der Fremdfilter scannt weiter synchron.
- `setx` und `[Environment]::SetEnvironmentVariable` aktualisieren den Prozess-PATH der laufenden Session nicht. Nur Tool-Herkunft nach PATH-Änderungen in einer neuen Shell prüfen.

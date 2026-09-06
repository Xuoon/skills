---
name: cloud
description: >
  Bereitet ein Repo für Cloud-Agenten vor: ein gemeinsames Setup-Skript unter
  .github/scripts, Client-Dateien für Amp, Cursor, Codex, Claude Cloud,
  Devcontainer und Copilot nur als Verdrahtung, CI ohne Doppelarbeit. Ohne
  Argumente Analyse und Vorschläge; mit --fix lokale Korrekturen ohne Commit
  oder Push. Nicht für globale Client-Einstellungen oder den Betrieb von
  CI-Runnern.
---

# cloud — Repos für Cloud-Agenten vorbereiten

Zielbild und belegte Client-Verträge stehen in `references/layout.md`, die Skriptvorlage in `references/setup.sh`. Eine vorhandene gleichwertige Lösung bleibt; fehlende Client-Ordner sind kein Befund.

## Modus

- **Ohne Argumente:** nur lesen. Befund je Problem mit Datei, Auswirkung und kleinster Korrektur. Danach Umsetzung oder offene Entscheidungen erfragen; nichts schreiben, nichts installieren.
- **`--fix`** oder eine konkrete Auswahl nach der Analyse: genau diese Änderungen lokal umsetzen und prüfen. Unabhängige Korrekturen laufen weiter, während eine Rückfrage offen ist.
- **Immer:** kein Staging, Commit, Push, PR, Branch- oder Worktree-Cleanup, Deploy, keine Cloud-Konten, keine globalen Client-Einstellungen oder System-Toolchains des Nutzerrechners. Secrets und ganze Env-Dateien nie ausgeben.

Scope ist das aktuelle Repo oder der genannte Pfad; mehrere Repos einzeln. Bestehende Änderungen aufnehmen, nie überschreiben. Anweisungsdateien des Repos lesen und befolgen.

## 1. Bestand

1. Stack aus Manifests, Lockfiles, Versionspins (`packageManager`, `.node-version`, `rust-toolchain.toml`, `global.json`) und Workspace-Struktur ableiten, nicht aus Repo-Namen oder alten Kommentaren.
2. Alle Client-Dateien samt Aufrufketten lesen: `.github`, `.agents`, `.amp`, `.claude`, `.codex`, `.cursor`, `.devcontainer`, `.vscode`. Aufrufer auch außerhalb suchen: Tests, Doku, Workflows.
3. CI bis zum ausgeführten Befehl verfolgen: enthält `check` schon Tests? Welche Pfade lösen welche Jobs aus? Wo wird gebaut, signiert, veröffentlicht?
4. Client-Verträge bei Zweifel gegen die offizielle Doku prüfen; `references/layout.md` nennt den belegten Stand mit Datum. Snapshot-Installer, Session-Hook, lokales Worktree-Setup und betreuter Dev-Server sind vier verschiedene Vorgänge.

## 2. Zielbild anwenden

- `.github/scripts/setup.sh` ist der einzige Installer. Linux gilt als Cloud-Container und erhält fehlende Toolchains; andere Systeme werden nur geprüft und bekommen Abhängigkeiten. Versionsquellen bleiben die nativen Projektdateien, keine zweite Versionsliste im Skript.
- Client-Dateien rufen das Skript auf und kopieren es nicht. Wrapper nur, wo der Client einen festen Pfad vorschreibt (`.agents/setup`) oder die Datei vom Client erzeugt wird (`.codex/environments/environment.toml`). Sonst direkt `bash .github/scripts/setup.sh` eintragen.
- Alles ohne eigene Funktion entfernen: leere Resume-Skripte, Wrapper mit einem Aufrufer, Runtime-Dateien, die nur PATH setzen.
- PATH-Exports überleben Snapshots nicht: installierte Programme nach `/usr/local/bin` verlinken, für Claude zusätzlich `CLAUDE_ENV_FILE` beschreiben, für Codex Cloud `~/.bashrc`.
- Dev-Server nie im Installer, sondern in `.amp/services.yaml` oder Cursor-`terminals`; zugewiesenen `PORT` nutzen, `0.0.0.0` binden, `--strictPort`, nur den Host aus `PUBLIC_URL` freigeben.
- Backends, Codegen, Logins und Deploys nur mit bestehendem Vertrag. Kein `convex dev` ohne Key: legt anonyme Backends an oder überschreibt `.env.local`.
- `.claude/settings.json` zusammenführen, nie ersetzen. Hook auf `CLAUDE_CODE_REMOTE` begrenzen, Pfad über `$CLAUDE_PROJECT_DIR` quoten, `timeout` explizit setzen (Standard bei SessionStart: 30 s), Fehler als Warnung durchreichen.
- CI: offizielle Setup-Actions plus `install --frozen-lockfile`, nicht der Cloud-Installer. Cache-Keys aus Lockfile und Plattform. Schwere Builds nur bei reviewbereiten PRs; Required Checks dürfen durch Pfadfilter nicht ausfallen; eingebundene Markdown-Dateien sind Build-Eingaben.
- Nach Verschiebungen: Ausführungsbits, Aufrufer, Workflow-Filter, ShellCheck-Listen, Tests, Doku. Ein Skript ohne tatsächlichen Aufrufer ist tot.

## 3. Prüfen

Analysemodus: nur lesende Prüfungen. Bei `--fix`: `bash -n`, ShellCheck, `actionlint`, JSON/TOML parsen, vorhandene Tests des Repos ausführen. Den Installer in einem Wegwerf-Verzeichnis mit Attrappen für `node`, `bun` und `uname` prüfen: fremdes CWD mit Leerzeichen, falsche Version bricht vor der Installation ab, Exit-Code des Installers kommt durch, zweiter Lauf lädt nichts nach. Nie auf dem Nutzerrechner provisionieren. Ein lokaler Test ist kein Cloud-Lauf; das im Bericht sagen.

Abschluss: Diff auf beabsichtigte Änderungen ohne Artefakte oder Secrets. Bericht: was besser ist, was geprüft wurde, welche Cloud-Schritte der Nutzer selbst macht (UI-Setup-Skript eintragen, Snapshot löschen, Codex-App-Setup umstellen). Nicht committen.

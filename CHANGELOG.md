# Changelog

Alle nennenswerten Änderungen an diesem Claude-Code-Plugin-Marketplace werden in dieser Datei dokumentiert.

Das Format ist angelehnt an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/). Die einzelnen Plugins werden unabhängig voneinander nach [Semantic Versioning](https://semver.org/lang/de/) versioniert.

## windev

### [1.0.0] – 2026-07-19

#### Added

- `/windev:setup` (Einrichtung inklusive PowerShell-7-Bootstrap auf frischem Windows) und `/windev:optimize` (Vollanalyse und Bereinigung), beide approval-gated.
- Read-only-Inventur mit aktiver OMP-Konfiguration, expandiertem PATH-Audit sowie Erkennung von VS-Code-User- und System-Installationen.
- Schlankes OMP-Basistheme und deterministische Theme-Erzeugung mit expliziter Quellkonfiguration.
- HKLM-PATH-Bereinigung mit Rohwert-Backup, Deduplizierung und sicherer Array-Übergabe durch einen elevierten Wrapper.
- Best-Practice-Referenz und PowerShell-Profilvorlage mit Guard und Lazy-Loading.

## agent-docs

### [4.0.2] – 2026-07-16

#### Changed

- `audit`-Description deutsch und kurz — sie ist reine Picker-UI (`disable-model-invocation`). Die `sync`-Description bleibt englisch (Auto-Invoke-Trigger).

### [4.0.1] – 2026-07-09

#### Changed

- **Slash Autocomplete / `argument-hint`:**
  - `audit`: `[quick|prune] [pfad]` (vorher nur `[quick|prune]`)
  - `sync`: neu `[main|branch|prune] [pfad]`
- Beide Skills parsen **`$ARGUMENTS`** explizit (Mode, Git-Ref, Subtree, Freitext) mit Beispielen im Body — nicht nur Hint-Text ohne Verarbeitung.
- Descriptions kürzer/scannbarer für Skill-Picker.

### [4.0.0] – 2026-07-09

Sync/Audit neigten dazu, nach Feature-Arbeit **Implementation-Details und Inventare zu addieren** (Prefetch-Pads, UI-Chrome, Prop-Listen). Mehr Zeilen = mehr Drift. Agents brauchen **Verträge**, nicht Tutorials.

#### Changed

- **Breaking behavioral:** Asymmetrisches Edit-Gate in `references/shared.md`: DELETE leicht, ADD schwer (agent-blocking ∧ non-obvious ∧ single home ∧ ≤3 Zeilen ∧ Netto-Budget).
- **Sync** führt bei jedem Add-Kandidaten einen **Mini-Prune** mit; Deletes im Vorschlag **vor** Adds; valides Outcome `0 candidates`.
- **Audit-Scoring:** Conciseness **25**, Completeness **15** — Aufblasen kann Completeness nicht „retten“.
- Audit-Arg **`prune`**: nur Lösch-/Merge-Pass.
- **style.md:** „Code owns implementation detail“; Größenrichtwerte Root/App/Domain; explizite Anti-Inventar-Tabelle.
- **prune-sweep.md:** wann (Sync/Audit/User), Merge-Regel für kleine Rule-Dateien (≤~15 exklusive Zeilen), Netto-Ziel Δ&lt;0.
- Verify meldet **Δ lines**.
- Whole-file rewrite nur noch als **`rewrite-prune`** (Netto kürzer), nicht zum Erweitern.

#### Added

- Sync-Trigger-Phrasen: „weniger doku“, „prune“, „unnötig“.
- Claim-Kind `impl-detail` im Audit-Discovery.
- Anti-Pattern: Session-Changelog / frisches Feature 1:1 in Rules spezifizieren.

### [3.0.0] – 2026-06-30

#### Changed

- `/agent-docs:sync` ist smarter Alltags-Router (Init/Sync/Review).
- `sync` `allowed-tools` um `ls`/`find` erweitert.

#### Removed

- **Breaking:** `/agent-docs:init` als eigener Befehl — Init ist Sync-Modus (`references/init.md`).

### [2.0.0] – 2026-06-11

#### Changed

- Argumente vereinfacht; `quick` (audit) bleibt.

#### Removed

- **Breaking:** `/agent-docs:prune` — Prune in Sync-Gate + Audit-Sweep; Prozedur in `references/prune-sweep.md`.

### [1.0.0] – 2026-06-10

#### Added

- Plugin mit `sync`, `audit`, `prune`, `init`; zentrales Vorschlags-Format in `shared.md`.

## btw-checkout

### [0.2.0] – 2026-07-16

#### Fixed

- `name: btw-checkout` im Frontmatter — ohne das Feld leitete Claude Code den Befehlsnamen aus dem Versions-Verzeichnis im Plugin-Cache ab (`/btw-checkout:0-1-0` statt `/btw-checkout`).

#### Changed

- Description deutsch und kurz (reine Picker-UI, da `disable-model-invocation`); `argument-hint` für optionale inhaltliche Hinweise.

### [0.1.0] – 2026-07-16

#### Added

- `/btw-checkout` — destilliert den Side-Chat-Verlauf in einen Übergabe-Prompt für den Haupt-Chat (Entscheidungen, Fakten/Pfade, offene Fragen + nummerierte Aufgaben bzw. „Keine Aktion nötig"), eine Rückfrage, dann finale Fassung als Codeblock.

## claudex-install

### [2.0.0] – 2026-07-16

#### Changed

- **Breaking:** Plugin heißt jetzt `claudex-install`, der Befehl schlicht `/claudex-install` (Root-SKILL.md statt `skills/install/`; vorher `/claudex-installer:install`). Auf den Geräten einmalig `claudex-installer` deinstallieren und `claudex-install@labi` installieren.
- Description gestrafft. Die `claudex-installer`-Marker in `.zshrc`/Config bleiben unverändert — bestehende Installationen werden weiter erkannt (Update/Uninstall funktionieren).

#### Removed

- Plugin-README (Inhalte stehen kanonisch in der SKILL.md bzw. im Root-README).

### [1.0.0] – 2026-07-13

#### Added

- Skill `/claudex-installer:install` mit read-only Vorprüfung, Dry-Run und explizitem Freigabe-Gate.
- Architektur-Erkennung für Apple Silicon, Intel und Rosetta sowie SHA-256-Prüfung offizieller CLIProxyAPI-Releases.
- Sicheres Localhost-Setup mit zufälligem Client-Key, Codex/OAuth, Modellermittlung und End-to-End-Test.
- Idempotente `claudex()`-Funktion mit `.zshrc`-Backup, Syntaxprüfung und Auto-Start des Proxys.
- Deinstallationsskript und Troubleshooting für OAuth, Portkonflikte, Sandbox und Modellverfügbarkeit.

## deps

### [1.0.1] – 2026-07-16

#### Changed

- Descriptions von `bump` und `health` deutsch und kurz — reine Picker-UI (`disable-model-invocation`).
- `bump` verweist nicht mehr auf das entfernte git-work-Plugin (Committen bleibt beim Nutzer).

### [1.0.0] – 2026-06-30

#### Changed

- **Breaking:** `/deps:audit` → `/deps:health` umbenannt (klarere Abgrenzung zum Doku-`/agent-docs:audit`). Read-only-Workflow (CVEs, EOL, Lizenzen) unverändert; Fixes weiter über `/deps:bump`.

### [0.2.0] – 2026-06-11

#### Added

- `/deps:audit` — Read-only-Report: CVEs (bun/npm audit), EOL-Check via endoflife.date, Lizenz-Flags. Fixes laufen weiter über `/deps:bump`.

#### Changed

- `/deps:bump`: Subtree-Pfad-Argument entfernt; `[paket]` und `minor` bleiben.

#### Removed

- Plugin-README (Inhalte stehen kanonisch in den SKILL.mds bzw. im Root-README).

### [0.1.0] – 2026-06-10

#### Added

- `/deps:bump` — workspace-aware Update aller package.json auf das letzte offizielle stabile Release (bun-first), mit from→to-Plan, Breaking-Notizen für Majors, `minor`-Flag und typecheck/build/test-Verify.

## load-context

### [0.2.0] – 2026-06-30

#### Added

- `.github/instructions/*.instructions.md` (Copilot-Workspace-Instruktionsdateien) werden jetzt mitgeladen.

### [0.1.0] – 2026-06-25

#### Added

- Hook-Plugin ohne Befehle: lädt repo-spezifische Doku via `SessionStart`-Hook in den Kontext — bei jedem Session-Start und nach jedem Compact (`source=compact`). Geladen werden `CLAUDE.md`, `AGENTS.md`, `README.md`, `.claude/rules/**/*.md` sowie Instruktionsdateien anderer AI-Tools (`.cursorrules`, `.cursor/rules/**/*.mdc`, `.github/copilot-instructions.md`, `GEMINI.md`, `.windsurfrules`, `.clinerules`, `.junie/guidelines.md`). Git-tracked (überspringt `node_modules`/`.gitignore`), mit Pro-Datei- und Gesamt-Budget gegen Kontext-Flut.

## notify

### [0.2.0] – 2026-07-16

#### Added

- **Windows-Support:** `scripts/notify.ps1` — Toast via BurntToast (falls installiert) oder natives WinRT; `notify.sh` erkennt Git-Bash-Umgebungen und delegiert.
- **Standalone-Modus für andere Harnesses:** `notify.sh --agent "Codex" --message "…"` (auch `--title/--subtitle/--sound`, Agent-Name alternativ via `$NOTIFY_AGENT`) — das Script ist nicht mehr an Claude-Code-Hook-JSON gebunden.
- macOS: nutzt `terminal-notifier`, falls installiert — Klick fokussiert das Terminal (iTerm/Terminal/VS Code/Ghostty/WezTerm), Benachrichtigungen gruppieren pro Projekt.

#### Changed

- Anzeige-Layout: Titel = Projektname, Untertitel = Agent + Status (`fertig ✅` / `wartet ⏳`), Text = eigentliche Meldung — statt überall nur „Claude Code".
- Hooks rufen das Script explizit via `bash` auf (robust auch ohne Executable-Bit, Git Bash).
- Linux: `notify-send -a <agent>` setzt den App-Namen der Benachrichtigung.

### [0.1.0] – 2026-06-11

#### Added

- Hook-Plugin ohne Befehle: Desktop-Benachrichtigung bei `Stop` (Claude ist fertig) und `Notification` (Claude braucht Input/Permission). macOS via osascript (mit Projektname im Titel), Linux via notify-send, sonst still.

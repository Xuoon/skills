# Changelog

Alle nennenswerten Änderungen an diesem Claude-Code-Plugin-Marketplace werden in dieser Datei dokumentiert.

Das Format ist angelehnt an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/). Die einzelnen Plugins werden unabhängig voneinander nach [Semantic Versioning](https://semver.org/lang/de/) versioniert.

## agent-docs

### [5.0.0] – 2026-07-23

#### Geändert

- **Standard = nur Vorschlag.** `sync` und `audit` schreiben nichts mehr ungefragt — erst mit `--anwenden`. Auto-Invoke von `sync` schlägt also nur vor.
- **Deutsche Flag-Argumente:** `sync` `--kürzen`/`--prüfen`/`--anwenden`, `audit` `--schnell`/`--kürzen`/`--anwenden`. Pfad-Argument entfernt — Scope ist immer das aktuelle Verzeichnis, Subtree/Diff-Basis bei Bedarf im Fließtext.
- **Descriptions auf Deutsch** (auch die model-invocable `sync`-Description).
- `sync` wendet One Source of Truth auf sich selbst an: die Gate-Kurzform ist ein Pointer auf `shared.md` statt einer zweiten Kopie der Mechanik.
- Scope erweitert um `CLAUDE.local.md`/`.claude.local.md` (gitignorierte persönliche Overrides); Inhalte von dort werden nie in geteilte Docs gespiegelt.

### [4.0.2] – 2026-07-16

#### Geändert

- `audit`-Description deutsch und kurz — reine Picker-UI (`disable-model-invocation`).

### [4.0.1] – 2026-07-09

#### Geändert

- `argument-hint` + explizites `$ARGUMENTS`-Parsing (Mode, Git-Ref, Subtree, Freitext) für beide Skills, mit Beispielen im Body.
- Descriptions kürzer/scannbarer für den Skill-Picker.

### [4.0.0] – 2026-07-09

Sync/Audit neigten dazu, nach Feature-Arbeit **Implementation-Details und Inventare zu addieren** (Prefetch-Pads, UI-Chrome, Prop-Listen). Mehr Zeilen = mehr Drift. Agents brauchen **Verträge**, nicht Tutorials.

#### Geändert

- **Breaking behavioral:** Asymmetrisches Edit-Gate in `references/shared.md`: DELETE leicht, ADD schwer (agent-blocking ∧ non-obvious ∧ single home ∧ ≤3 Zeilen ∧ Netto-Budget).
- **Sync** führt bei jedem Add-Kandidaten einen **Mini-Prune** mit; Deletes im Vorschlag **vor** Adds; valides Outcome `0 candidates`.
- **Audit-Scoring:** Conciseness **25**, Completeness **15** — Aufblasen kann Completeness nicht „retten".
- Neuer Audit-Modus nur für Lösch-/Merge-Pass.
- **style.md:** „Code owns implementation detail"; Größenrichtwerte Root/App/Domain; explizite Anti-Inventar-Tabelle.
- **prune-sweep.md:** wann (Sync/Audit/User), Merge-Regel für kleine Rule-Dateien (≤~15 exklusive Zeilen), Netto-Ziel Δ<0.
- Verify meldet **Δ lines**.
- Whole-file rewrite nur noch als **`rewrite-prune`** (Netto kürzer), nicht zum Erweitern.

#### Hinzugefügt

- Sync-Trigger-Phrasen: „weniger doku", „prune", „unnötig".
- Claim-Kind `impl-detail` im Audit-Discovery.
- Anti-Pattern: Session-Changelog / frisches Feature 1:1 in Rules spezifizieren.

### [3.0.0] – 2026-06-30

#### Geändert

- `/agent-docs:sync` ist smarter Alltags-Router (Init/Sync/Review).
- `sync` `allowed-tools` um `ls`/`find` erweitert.

#### Entfernt

- **Breaking:** `/agent-docs:init` als eigener Befehl — Init ist Sync-Modus (`references/init.md`).

### [2.0.0] – 2026-06-11

#### Geändert

- Argumente vereinfacht; `quick` (audit) bleibt.

#### Entfernt

- **Breaking:** `/agent-docs:prune` — Prune in Sync-Gate + Audit-Sweep; Prozedur in `references/prune-sweep.md`.

### [1.0.0] – 2026-06-10

#### Hinzugefügt

- Plugin mit `sync`, `audit`, `prune`, `init`; zentrales Vorschlags-Format in `shared.md`.

## claudex-install

### [3.0.0] – 2026-07-23

#### Geändert

- SKILL.md gestrafft: die deterministischen Installer-Schritte werden nicht mehr einzeln nacherzählt (der Code trägt sie), die Sicherheitszusagen bleiben wörtlich stehen.
- `license`-Feld aus der `plugin.json` entfernt.

### [2.0.0] – 2026-07-16

#### Geändert

- **Breaking:** Plugin heißt jetzt `claudex-install`, der Befehl schlicht `/claudex-install` (Root-SKILL.md statt `skills/install/`; vorher `/claudex-installer:install`). Auf den Geräten einmalig `claudex-installer` deinstallieren und `claudex-install@labi` installieren.
- Description gestrafft. Die `claudex-installer`-Marker in `.zshrc`/Config bleiben unverändert — bestehende Installationen werden weiter erkannt (Update/Uninstall funktionieren).

#### Entfernt

- Plugin-README (Inhalte stehen kanonisch in der SKILL.md bzw. im Root-README).

### [1.0.0] – 2026-07-13

#### Hinzugefügt

- Skill `/claudex-installer:install` mit read-only Vorprüfung, Dry-Run und explizitem Freigabe-Gate.
- Architektur-Erkennung für Apple Silicon, Intel und Rosetta sowie SHA-256-Prüfung offizieller CLIProxyAPI-Releases.
- Sicheres Localhost-Setup mit zufälligem Client-Key, Codex/OAuth, Modellermittlung und End-to-End-Test.
- Idempotente `claudex()`-Funktion mit `.zshrc`-Backup, Syntaxprüfung und Auto-Start des Proxys.
- Deinstallationsskript und Troubleshooting für OAuth, Portkonflikte, Sandbox und Modellverfügbarkeit.

## btw-checkout

### [1.0.0] – 2026-07-23

#### Hinzugefügt

- Direkt-Modus (`--direkt`): überspringt die eine Rückfrage-Runde und gibt sofort den finalen Codeblock aus.

Erstes stabiles Release — Funktionsumfang ansonsten unverändert.

### [0.2.0] – 2026-07-16

#### Behoben

- `name: btw-checkout` im Frontmatter — ohne das Feld leitete Claude Code den Befehlsnamen aus dem Versions-Verzeichnis im Plugin-Cache ab (`/btw-checkout:0-1-0` statt `/btw-checkout`).

#### Geändert

- Description deutsch und kurz (reine Picker-UI, da `disable-model-invocation`); `argument-hint` für optionale inhaltliche Hinweise.

### [0.1.0] – 2026-07-16

#### Hinzugefügt

- `/btw-checkout` — destilliert den Side-Chat-Verlauf in einen Übergabe-Prompt für den Haupt-Chat (Entscheidungen, Fakten/Pfade, offene Fragen + nummerierte Aufgaben bzw. „Keine Aktion nötig"), eine Rückfrage, dann finale Fassung als Codeblock.

## load-context

### [1.0.0] – 2026-07-23

Erstes stabiles Release — Funktionsumfang unverändert.

### [0.2.0] – 2026-06-30

#### Hinzugefügt

- `.github/instructions/*.instructions.md` (Copilot-Workspace-Instruktionsdateien) werden jetzt mitgeladen.

### [0.1.0] – 2026-06-25

#### Hinzugefügt

- Hook-Plugin ohne Befehle: lädt repo-spezifische Doku via `SessionStart`-Hook in den Kontext — bei jedem Session-Start und nach jedem Compact (`source=compact`). Geladen werden `CLAUDE.md`, `AGENTS.md`, `README.md`, `.claude/rules/**/*.md` sowie Instruktionsdateien anderer AI-Tools (`.cursorrules`, `.cursor/rules/**/*.mdc`, `.github/copilot-instructions.md`, `GEMINI.md`, `.windsurfrules`, `.clinerules`, `.junie/guidelines.md`). Git-tracked (überspringt `node_modules`/`.gitignore`), mit Pro-Datei- und Gesamt-Budget gegen Kontext-Flut.

## windev

### [1.0.0] – 2026-07-19

#### Hinzugefügt

- `/windev:setup` (Einrichtung inklusive PowerShell-7-Bootstrap auf frischem Windows) und `/windev:optimize` (Vollanalyse und Bereinigung), beide approval-gated.
- Read-only-Inventur mit aktiver OMP-Konfiguration, expandiertem PATH-Audit sowie Erkennung von VS-Code-User- und System-Installationen.
- Schlankes OMP-Basistheme und deterministische Theme-Erzeugung mit expliziter Quellkonfiguration.
- HKLM-PATH-Bereinigung mit Rohwert-Backup, Deduplizierung und sicherer Array-Übergabe durch einen elevierten Wrapper.
- Best-Practice-Referenz und PowerShell-Profilvorlage mit Guard und Lazy-Loading.

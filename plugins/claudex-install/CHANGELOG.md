# Changelog — claudex-install

## [2.0.0] – 2026-07-16

### Changed

- **Breaking:** Plugin heißt jetzt `claudex-install`, der Befehl schlicht `/claudex-install`
  (Root-SKILL.md statt `skills/install/`; vorher `/claudex-installer:install`). Auf den Geräten
  einmalig `claudex-installer` deinstallieren und `claudex-install@labi` installieren.
- Description gestrafft. Die `claudex-installer`-Marker in `.zshrc`/Config bleiben unverändert —
  bestehende Installationen werden weiter erkannt (Update/Uninstall funktionieren).

### Removed

- Plugin-README (Inhalte stehen kanonisch in der SKILL.md bzw. im Root-README).

## [1.0.0] – 2026-07-13

### Added

- Skill `/claudex-installer:install` mit read-only Vorprüfung, Dry-Run und explizitem Freigabe-Gate.
- Architektur-Erkennung für Apple Silicon, Intel und Rosetta sowie SHA-256-Prüfung offizieller CLIProxyAPI-Releases.
- Sicheres Localhost-Setup mit zufälligem Client-Key, Codex/OAuth, Modellermittlung und End-to-End-Test.
- Idempotente `claudex()`-Funktion mit `.zshrc`-Backup, Syntaxprüfung und Auto-Start des Proxys.
- Deinstallationsskript und Troubleshooting für OAuth, Portkonflikte, Sandbox und Modellverfügbarkeit.

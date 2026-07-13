# Changelog — claudex-installer

## [1.0.0] – 2026-07-13

### Added

- Skill `/claudex-installer:install` mit read-only Vorprüfung, Dry-Run und explizitem Freigabe-Gate.
- Architektur-Erkennung für Apple Silicon, Intel und Rosetta sowie SHA-256-Prüfung offizieller CLIProxyAPI-Releases.
- Sicheres Localhost-Setup mit zufälligem Client-Key, Codex/OAuth, Modellermittlung und End-to-End-Test.
- Idempotente `claudex()`-Funktion mit `.zshrc`-Backup, Syntaxprüfung und Auto-Start des Proxys.
- Deinstallationsskript und Troubleshooting für OAuth, Portkonflikte, Sandbox und Modellverfügbarkeit.

# Changelog — load-context

## [0.1.0] – 2026-06-25

### Added

- Hook-Plugin ohne Befehle: lädt repo-spezifische Doku via `SessionStart`-Hook in den Kontext — bei jedem Session-Start und nach jedem Compact (`source=compact`). Geladen werden `CLAUDE.md`, `AGENTS.md`, `README.md`, `.claude/rules/**/*.md` sowie Instruktionsdateien anderer AI-Tools (`.cursorrules`, `.cursor/rules/**/*.mdc`, `.github/copilot-instructions.md`, `GEMINI.md`, `.windsurfrules`, `.clinerules`, `.junie/guidelines.md`). Git-tracked (überspringt `node_modules`/`.gitignore`), mit Pro-Datei- und Gesamt-Budget gegen Kontext-Flut.

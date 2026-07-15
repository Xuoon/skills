# Changelog — btw-checkout

## [0.2.0] – 2026-07-16

### Fixed

- `name: btw-checkout` im Frontmatter — ohne das Feld leitete Claude Code den Befehlsnamen
  aus dem Versions-Verzeichnis im Plugin-Cache ab (`/btw-checkout:0-1-0` statt `/btw-checkout`).

### Changed

- Description deutsch und kurz (reine Picker-UI, da `disable-model-invocation`); `argument-hint`
  für optionale inhaltliche Hinweise.

## [0.1.0] – 2026-07-16

### Added

- `/btw-checkout` — destilliert den Side-Chat-Verlauf in einen Übergabe-Prompt für den
  Haupt-Chat (Entscheidungen, Fakten/Pfade, offene Fragen + nummerierte Aufgaben bzw.
  „Keine Aktion nötig"), eine Rückfrage, dann finale Fassung als Codeblock.

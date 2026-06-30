# Changelog — deps

## [1.0.0] – 2026-06-30

### Changed

- **Breaking:** `/deps:audit` → `/deps:health` umbenannt (klarere Abgrenzung zum Doku-`/agent-docs:audit`). Read-only-Workflow (CVEs, EOL, Lizenzen) unverändert; Fixes weiter über `/deps:bump`.

## [0.2.0] – 2026-06-11

### Added

- `/deps:audit` — Read-only-Report: CVEs (bun/npm audit), EOL-Check via endoflife.date, Lizenz-Flags. Fixes laufen weiter über `/deps:bump`.

### Changed

- `/deps:bump`: Subtree-Pfad-Argument entfernt; `[paket]` und `minor` bleiben.

### Removed

- Plugin-README (Inhalte stehen kanonisch in den SKILL.mds bzw. im Root-README).

## [0.1.0] – 2026-06-10

### Added

- `/deps:bump` — workspace-aware Update aller package.json auf das letzte offizielle stabile Release (bun-first), mit from→to-Plan, Breaking-Notizen für Majors, `minor`-Flag und typecheck/build/test-Verify.

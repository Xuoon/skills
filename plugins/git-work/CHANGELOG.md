# Changelog — git-work

## [0.3.0] – 2026-07-15

### Added

- Plugin-CLAUDE.md mit dem verbindlichen PR-Beschreibungsformat (Was/Warum · `---` ·
  technischer Changelog · `---` · „Manuelle Schritte" nur bei Bedarf; kein
  Verifikations-Block) — wird nach der Installation in jede Session geladen und gilt
  damit geräteübergreifend.

### Changed

- `/git-work:pr` verweist für die Beschreibung auf das Format der Plugin-CLAUDE.md statt
  auf den früheren 1–3-Sätze-Stil.

## [0.2.0] – 2026-06-11

### Added

- `/git-work:pr` — Branch pushen + GitHub-PR via gh eröffnen, Titel/Beschreibung im Haus-Stil aus den tatsächlichen Commits, approval-gated.

### Removed

- Plugin-README (Inhalte stehen kanonisch in den SKILL.mds bzw. im Root-README).

## [0.1.0] – 2026-06-10

### Added

- `/git-work:commit` — logische Commit-Splits + Messages nach Haus-Stil, approval-gated.
- `/git-work:changelog` — CHANGELOG-Sektion aus Commits seit letztem Tag, mit Semver-Vorschlag.
- `references/commit-style.md` als gemeinsame Stil-Quelle beider Skills.

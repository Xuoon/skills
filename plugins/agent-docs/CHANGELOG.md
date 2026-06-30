# Changelog — agent-docs

## [3.0.0] – 2026-06-30

### Changed

- `/agent-docs:sync` ist jetzt der smarte Alltags-Einstieg (Router): Der Skill erkennt, ob Agent-Doku fehlt (Init), ein Code-Diff synchronisiert werden muss (Sync) oder ein Quick-/Full-Review passend ist.
- `sync` `allowed-tools` um `ls`/`find` erweitert — der Init-Modus braucht sie für den Recon, sonst Permission-Prompts beim Auto-Routing.

### Removed

- **Breaking:** `/agent-docs:init` als eigener Befehl entfernt — der Init-Workflow läuft jetzt als Modus des `sync`-Routers (Branch „keine Doku im Scope"); die Prozedur liegt in `references/init.md`. Bootstrap-Aufrufe („leg mir eine CLAUDE.md an" etc.) triggern `sync`.

## [2.0.0] – 2026-06-11

### Changed

- Argumente vereinfacht: Subtree-Pfad (alle Skills), `solo` (audit) und Base-Branch (sync) als formale Argumente entfernt — Scope-Wünsche nennt man direkt im Aufruf-Text; `quick` (audit) bleibt.

### Removed

- **Breaking:** `/agent-docs:prune` entfernt — der Lösch-Pass läuft ohnehin in `sync` (diff-getrieben, Trigger-Gate "redundant geworden → löschen") und `audit` (Prune-Sweep) mit; die Prozedur bleibt in `references/prune-sweep.md`.
- Plugin-README (Inhalte stehen kanonisch in den SKILL.mds bzw. im Root-README).

## [1.0.0] – 2026-06-10

### Added

- Plugin-Struktur mit vier Skills: `sync`, `audit`, `prune`, `init` (Namespace `/agent-docs:*`).
- `quick`- und `solo`-Flags für `audit`; freie Argumente (Base-Branch/Subtree) für `sync`.
- Zentrales Vorschlags-Format (Diff/Delete/Create) in `references/shared.md`.

### Changed

- Umbenannt von `docs-maintain` zu `agent-docs`.

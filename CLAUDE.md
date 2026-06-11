# CLAUDE.md

Claude-Code-Plugin-Marketplace ("labi"): Katalog in `.claude-plugin/marketplace.json`, ein Plugin pro Ordner unter `plugins/`. Die SKILL.md- und Hook-Dateien hier sind das **ausgelieferte Produkt** — wer sie editiert, ändert Laufzeit-Verhalten auf allen installierten Geräten, nicht "nur Doku".

## Befehle

- `python scripts/validate.py` — Pflicht vor jedem Commit (einmalig `pip install pyyaml`). CI führt dasselbe bei jedem Push aus (`.github/workflows/validate.yml`).

## Invarianten

- **Namen sind API.** Plugin-Ordnername = `name` in dessen `plugin.json` = Befehls-Namespace (`/agent-docs:sync`). Umbenennen von Plugin- oder Skill-Ordnern ist ein Breaking Change für alle Nutzer; der Validator erzwingt den Namens-Match (`scripts/validate.py:94`).
- **Zwei Skill-Muster, nicht mischen.** `SKILL.md` im Plugin-Root → Befehl `/<plugin>`; `skills/<sub>/SKILL.md` → `/<plugin>:<sub>` (so gebaut: alle aktuellen Skill-Plugins). Einem Root-SKILL.md-Plugin nachträglich ein `skills/`-Verzeichnis zu geben ändert den Befehlsnamen → Breaking. Hook-Plugins ohne Befehle (`notify`) haben stattdessen `hooks/hooks.json`; deren Scripts via `${CLAUDE_PLUGIN_ROOT}`-Pfaden referenzieren und ausführbar halten.
- **Referenzen bleiben im Plugin.** Geteilte Dateien liegen in `plugins/<name>/references/` und werden via `${CLAUDE_SKILL_DIR}/../../references/…` geladen. Pfade aus dem Plugin-Ordner heraus brechen nach der Installation (Plugins werden in einen Cache kopiert); der Validator blockt das (`scripts/validate.py:80`).
- **Frontmatter ist Verhalten, kein Stil.** `description` steuert Auto-Invoke — Formulierungen wie "Use ONLY when the user explicitly asks" sind Absicht. `disable-model-invocation: true` markiert teure/destruktive Skills (agent-docs:audit, alle git-work- und deps-Skills). `allowed-tools` erlaubt bewusst nur Read-only; schreibende Tools fehlen als zweites Sicherheitsnetz neben den Approval-Gates in den Skill-Texten. Keines dieser Felder "aufräumen" oder vereinheitlichen.
- **Release = Version + Changelog.** Jede inhaltliche Plugin-Änderung braucht Semver-Bump in dessen `plugin.json` plus Eintrag in dessen `CHANGELOG.md` — `/plugin update` auf den Geräten zieht nur bei Versionssprung. Faustregel zur Einstufung: `CONTRIBUTING.md`.
- **Sprachkonvention:** Skill-`description`s Englisch (Trigger-Robustheit), Skill-Bodies und alle Doku Deutsch.

## Verweise

- Neues Plugin anlegen, lokal testen (`/plugin marketplace add .`), Release-Faustregel, externe Plugins mit `ref`-Pinning: `CONTRIBUTING.md`.
- Katalog + Install-Zeilen: `README.md`.
- Qualitätsmaßstab für jeden Text in einer SKILL.md: `plugins/agent-docs/references/style.md` — die Hausphilosophie (Evidenz mit `file:line`, Vorschlag vor Edit, löschen bevorzugt) gilt auch beim Arbeiten an den Plugins selbst.

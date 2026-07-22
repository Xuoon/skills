# CLAUDE.md

Claude-Code-Plugin-Marketplace ("labi"): Katalog in `.claude-plugin/marketplace.json`, ein Plugin pro Ordner unter `plugins/`. Die SKILL.md- und Hook-Dateien hier sind das **ausgelieferte Produkt** — wer sie editiert, ändert Laufzeit-Verhalten auf allen installierten Geräten, nicht "nur Doku".

## Befehle

- `bun run fix` formatiert JSON/Markdown (Ultracite/Biome), `bun run check` prüft nur. Marktplatz-Struktur, `${CLAUDE_SKILL_DIR}`-Referenzen und Versions-Bumps sind **nicht** automatisiert geprüft — sie hängen an den Invarianten unten, hier zählt Sorgfalt beim Editieren.

## Invarianten

- **Namen sind API.** Plugin-Ordnername = `name` in dessen `plugin.json` = Befehls-Namespace (`/agent-docs:sync`). Ordnername und `name` müssen exakt übereinstimmen; Umbenennen von Plugin- oder Skill-Ordnern ist ein Breaking Change für alle Nutzer.
- **Zwei Skill-Muster, nicht mischen.** `SKILL.md` im Plugin-Root → Befehl `/<plugin>` (btw-checkout, claudex-install, ship); `skills/<sub>/SKILL.md` → `/<plugin>:<sub>` (agent-docs, cleanup) — Sub-Skills tragen **kein** `name:` im Frontmatter, der Unterordnername ist der Befehl. Root-SKILL.md braucht zwingend `name: <plugin>` im Frontmatter — ohne das Feld leitet Claude Code den Befehlsnamen aus dem Versions-Verzeichnis im Plugin-Cache ab (`/name:0-1-0`). Einem Root-SKILL.md-Plugin nachträglich ein `skills/`-Verzeichnis zu geben ändert den Befehlsnamen → Breaking. Hook-Plugins ohne Befehle (`load-context`) haben stattdessen `hooks/hooks.json`; deren Scripts via `${CLAUDE_PLUGIN_ROOT}`-Pfaden referenzieren und ausführbar halten.
- **Referenzen bleiben im Plugin.** Geteilte Dateien liegen in `plugins/<name>/references/` und werden via `${CLAUDE_SKILL_DIR}/../../references/…` geladen. Pfade aus dem Plugin-Ordner heraus brechen nach der Installation (Plugins werden in einen Cache kopiert) — nie aus dem Plugin herauszeigen.
- **Frontmatter ist Verhalten, kein Stil.** `description` steuert Auto-Invoke — Formulierungen wie "Use ONLY when the user explicitly asks" sind Absicht. `disable-model-invocation: true` markiert teure/destruktive oder Nur-auf-Zuruf-Skills (agent-docs:audit, btw-checkout). `allowed-tools` erlaubt bewusst nur Read-only; schreibende Tools fehlen als zweites Sicherheitsnetz neben den Approval-Gates in den Skill-Texten. Keines dieser Felder "aufräumen" oder vereinheitlichen.
- **Release = Version + Changelog.** Jede inhaltliche Plugin-Änderung braucht Semver-Bump in dessen `plugin.json` plus Eintrag im Root-`CHANGELOG.md` (pro-Plugin-Abschnitt) — `/plugin update` auf den Geräten zieht nur bei Versionssprung. Faustregel: Umbenennen/Entfernen = major, Befehls-/Argument-Änderung = minor, reine Instruktions-Verbesserung = patch.
- **Standard = nur Vorschlag.** Mutierende Skills schreiben/committen nichts ohne explizites Signal: `--anwenden` (bzw. `ship`: Freigabe-Gate + `--mergen`). Auto-Invoke darf nie ungefragt schreiben. Argumente sind deutsche `--flags` (`--anwenden`, `--kürzen`, `--prüfen`, `--schnell`, `--mergen`, `--nur-commit`, `--direkt`) — Pfade nicht als Argument, sondern immer cwd bzw. Subtree im Fließtext.
- **Sprachkonvention:** Alles Deutsch — `description`s, Bodies, Argument-Flags, Doku. Bei `disable-model-invocation: true` bleibt die Description kurz (reine Picker-UI). Die einzige model-invocable Description (`agent-docs:sync`) triggert auch auf Deutsch.

## Verweise

- Katalog + Install-Zeilen: `README.md`; Änderungshistorie: `CHANGELOG.md`.
- Neues Plugin lokal testen: `/plugin marketplace add .` → `/plugin install <name>@labi`; SKILL.md-Änderungen greifen live, alles andere braucht `/reload-plugins`.
- Qualitätsmaßstab für jeden Text in einer SKILL.md: `plugins/agent-docs/references/style.md` — die Hausphilosophie (Evidenz mit `file:line`, Vorschlag vor Edit, löschen bevorzugt) gilt auch beim Arbeiten an den Plugins selbst.

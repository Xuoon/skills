# CLAUDE.md

Claude-Code-Plugin-Marketplace ("labi"). Die SKILL.md-Dateien hier sind das **ausgelieferte Produkt** — wer sie editiert, ändert Laufzeit-Verhalten auf allen installierten Geräten, nicht "nur Doku".

## Befehle

- `bun run fix` formatiert JSON/Markdown, `bun run check` prüft nur.
- `bun run validate` prüft die Invarianten unten. Vor jedem Commit laufen lassen — die CI tut es ebenfalls, plus Release-Gate gegen den Basis-Branch.
- `claude plugin validate plugins/<plugin>` prüft dieselbe Struktur aus Claude-Code-Sicht. Das ist die einzige verlässliche Antwort auf „lädt das noch?" — die Doku beschreibt nicht jeden Fall.

## Invarianten

- **Layout nach [Agent Plugins 1.0.0](https://agent-plugins.org/).** Ein Plugin bündelt Skills nach Anlass:

  ```
  plugins/<plugin>/
  ├── plugin.json                  ← Agent-Plugins-Standard (geschlossenes Schema)
  ├── .claude-plugin/plugin.json   ← Claude Code liest ausschließlich diese
  └── skills/<skill>/SKILL.md      ← plus references/, scripts/, assets/
  ```

  **Zwei Manifeste, weil zwei Ökosysteme.** Claude Code findet ein `plugin.json` im Plugin-Root nicht („No manifest found. Expected `.claude-plugin/plugin.json`"), der Standard sucht ausschließlich dort. `name`, `version` und `description` müssen in beiden gleich sein. Das Standard-Manifest hat ein **geschlossenes** Schema (`additionalProperties: false`): Claude-Code-eigene Felder wie `displayName` gehören in die `.claude-plugin`-Datei, nicht dorthin.

- **Namen sind API.** Plugin-Ordnername = `name` in beiden Manifesten; Skill-Ordnername = `name:` in dessen `SKILL.md` = letztes Befehlssegment. Umbenennen ist ein Breaking Change — das Plugin muss auf allen Geräten neu installiert werden.

- **Ein Skill, ein Befehl, keine `commands/`-Dateien.** Kanonisch ist `/<plugin>:<skill>`, das bare `/<skill>` funktioniert zusätzlich — deshalb muss jeder Skillname **katalogweit eindeutig** sein, sonst verliert einer den baren Befehl. `bun run validate` prüft das. Zusatzmodi kommen als Flag, nicht als zweiter Skill.

- **Referenzen bleiben im Skill.** Bundle-Dateien liegen in `skills/<skill>/{references,scripts,assets}/` und werden via `${CLAUDE_SKILL_DIR}/references/…` geladen. **Jedes `../` in so einem Pfad verlässt den Skill** und bricht nach der Installation, weil Plugins in einen Cache kopiert werden.

- **Frontmatter ist Verhalten, kein Stil.** `description` steuert Auto-Invoke — sie ist die Auslösefläche, keine Deko. `disable-model-invocation: true` markiert Nur-auf-Zuruf-Skills; model-invocable sind nur `agent-docs`, `cleanup` und `kleinanzeigen`. Die beiden ersten nageln Auto-Invoke in ihrer Description ausdrücklich auf den analysierenden Standardmodus fest, der dritte schreibt ohnehin nichts. **`allowed-tools` beschränkt nichts** — es ist eine Vorab-Genehmigung für den einen Turn. Wer sperren will, braucht `disallowed-tools`; bei Skills mit `--fix` geht das nicht, dort ist das Flag selbst das Gate.

- **Release = Version + Changelog.** Jede inhaltliche Änderung braucht einen Semver-Bump im `plugin.json` des Plugins plus Eintrag in `CHANGELOG.md` — `/plugin update` zieht nur bei Versionssprung, und die CI blockt den PR sonst. Ein Plugin trägt eine Version für alle seine Skills. Faustregel: Umbenennen/Entfernen = major, Befehls- oder Argument-Änderung = minor, reine Instruktions-Verbesserung = patch.

- **Standard = nur Vorschlag.** Mutierende Skills schreiben nichts ohne `--fix`. Auto-Invoke darf nie ungefragt schreiben. Pfade sind kein Argument — Scope ist immer cwd, ein Subtree wird im Fließtext genannt.

- **Sprachkonvention:** Argumente englisch und kurz (`--fix`, `--merge`, `--clean`), **alle Texte deutsch**. Bei `disable-model-invocation: true` bleibt die Description ein kurzer Satz (reine Picker-UI); model-invocable Descriptions tragen die Trigger und dürfen dafür lang sein.

## Verweise

- Katalog und Install-Zeilen: `README.md`. Änderungshistorie: `CHANGELOG.md` — für Nutzer geschrieben, nicht für Entwickler.
- Neues Plugin lokal testen: `/plugin marketplace add .` → `/plugin install <plugin>@labi`; SKILL.md-Änderungen greifen live, alles andere braucht `/reload-plugins`.
- Qualitätsmaßstab für jeden Text in einer SKILL.md: `plugins/code/skills/agent-docs/references/style.md`. Die Hausphilosophie gilt auch beim Arbeiten an den Plugins selbst.

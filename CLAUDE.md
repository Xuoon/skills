# CLAUDE.md

Claude-Code-Plugin-Marketplace ("labi"): Katalog in `.claude-plugin/marketplace.json`, ein Plugin pro Ordner unter `plugins/`. Die SKILL.md-Dateien hier sind das **ausgelieferte Produkt** — wer sie editiert, ändert Laufzeit-Verhalten auf allen installierten Geräten, nicht "nur Doku".

## Befehle

- `bun run fix` formatiert JSON/Markdown (Ultracite/Biome), `bun run check` prüft nur.
- `bun run validate` prüft die Struktur-Invarianten unten (beide Manifeste, Namen, Katalog, `name:`, Pfade). Vor jedem Commit laufen lassen — die CI tut es ebenfalls, plus Release-Gate gegen den Basis-Branch.
- `claude plugin validate plugins/<name>` prüft dieselbe Struktur aus Claude-Code-Sicht. Das ist die einzige verlässliche Antwort auf „lädt das noch?" — die Doku beschreibt nicht jeden Fall.

## Invarianten

- **Namen sind API.** Plugin-Ordnername = `name` in **beiden** Manifesten = Skill-Ordnername = `name:` in dessen `SKILL.md` = Befehl (`/cleanup`). Alles muss exakt übereinstimmen; Umbenennen ist ein Breaking Change für alle Nutzer (Plugin muss neu installiert werden).
- **Layout nach [Agent Plugins 1.0.0](https://agent-plugins.org/).** Jedes Plugin sieht so aus:

  ```
  plugins/<name>/
  ├── plugin.json                  ← Agent-Plugins-Standard (geschlossenes Schema)
  ├── .claude-plugin/plugin.json   ← Claude Code liest ausschließlich diese
  └── skills/<name>/SKILL.md       ← plus references/, scripts/, assets/
  ```

  **Zwei Manifeste, weil zwei Ökosysteme.** Claude Code findet ein `plugin.json` im Plugin-Root nicht („No manifest found. Expected `.claude-plugin/plugin.json`"), der Standard sucht ausschließlich dort. `name`, `version` und `description` müssen in beiden gleich sein — `bun run validate` gleicht sie ab. Das Standard-Manifest hat ein **geschlossenes** Schema (`additionalProperties: false`): Claude-Code-eigene Felder wie `displayName` gehören nicht hinein, sondern in die `.claude-plugin`-Datei (oder, wenn sie portabel sein müssen, unter `extensions` mit Reverse-Domain-Namespace).
- **Ein Befehl pro Plugin.** Genau ein Skill, und der heißt wie das Plugin — `skills/<plugin>/SKILL.md` mit `name: <plugin>` im Frontmatter. Kanonisch heißt der Befehl `/<plugin>:<name>`, das bare `/<plugin>` funktioniert zusätzlich; der doppelte Eintrag im Picker ist erwartetes Verhalten. Zusatzmodi kommen als Flag, nicht als zweiter Skill. Keine `commands/`-Dateien — der Standard kennt sie nicht.
- **Referenzen bleiben im Skill.** Bundle-Dateien liegen in `plugins/<name>/skills/<name>/{references,scripts,assets}/` und werden via `${CLAUDE_SKILL_DIR}/references/…` geladen. `${CLAUDE_SKILL_DIR}` zeigt auf den Skill-Ordner: **jedes `../` in so einem Pfad verlässt ihn** und bricht nach der Installation, weil Plugins in einen Cache kopiert werden. `bun run validate` prüft das.
- **Frontmatter ist Verhalten, kein Stil.** `description` steuert Auto-Invoke — sie ist die Auslösefläche, keine Deko. `disable-model-invocation: true` markiert Nur-auf-Zuruf-Skills (windev, claudex, intune-win32); model-invocable sind nur `agent-docs` und `cleanup`, deren Descriptions Auto-Invoke ausdrücklich auf den analysierenden Standardmodus festnageln. **`allowed-tools` beschränkt nichts** — es ist eine Vorab-Genehmigung für den einen Turn, jedes andere Tool bleibt aufrufbar. Wer wirklich sperren will, braucht `disallowed-tools`; bei Skills mit `--fix`-Modus geht das nicht, dort ist das Flag selbst das Gate.
- **Release = Version + Changelog.** Jede inhaltliche Plugin-Änderung braucht Semver-Bump in dessen `plugin.json` plus Eintrag im Root-`CHANGELOG.md` (pro-Plugin-Abschnitt) — `/plugin update` auf den Geräten zieht nur bei Versionssprung, und die CI blockt den PR sonst. Faustregel: Umbenennen/Entfernen = major, Befehls-/Argument-Änderung = minor, reine Instruktions-Verbesserung = patch. Katalogweite Änderungen kommen zusätzlich in den `## Marketplace`-Abschnitt.
- **Standard = nur Vorschlag.** Mutierende Skills schreiben nichts ohne `--fix`. Auto-Invoke darf nie ungefragt schreiben. Pfade sind kein Argument — Scope ist immer cwd, ein Subtree wird im Fließtext genannt.
- **Sprachkonvention:** Argumente englisch und kurz (`--fix`, `--audit`, `--skills`, `--setup`), **alle Texte deutsch** — `description`s, `argument-hint`s, Bodies, Doku, Changelog. Bei `disable-model-invocation: true` bleibt die Description ein kurzer Satz (reine Picker-UI); model-invocable Descriptions tragen die Trigger und dürfen dafür lang sein.

## Verweise

- Katalog + Install-Zeilen: `README.md`; Änderungshistorie: `CHANGELOG.md`.
- Neues Plugin lokal testen: `/plugin marketplace add .` → `/plugin install <name>@labi`; SKILL.md-Änderungen greifen live, alles andere braucht `/reload-plugins`.
- Qualitätsmaßstab für jeden Text in einer SKILL.md: `plugins/agent-docs/references/style.md` — die Hausphilosophie (Evidenz mit `file:line`, Vorschlag vor Edit, löschen bevorzugt) gilt auch beim Arbeiten an den Plugins selbst.

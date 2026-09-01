# AGENTS.md

Portabler Plugin-Marketplace „labi" für ChatGPT, Codex, Claude Code und Agent-Plugins-Clients. `SKILL.md`-Dateien sind das ausgelieferte Produkt; Änderungen daran ändern Laufzeitverhalten.

## Befehle

- `bun run fix` formatiert JSON/Markdown, `bun run check` prüft nur.
- `bun run validate` prüft die Invarianten unten; vor jedem Commit ausführen.
- `claude plugin validate plugins/<plugin>` prüft den Claude-Adapter.

## Invarianten

- **Drei Manifeste, ein Plugin.** Jeder Ordner enthält:

  ```text
  plugins/<plugin>/
  ├── plugin.json                  # Agent Plugins 1.0.0
  ├── .codex-plugin/plugin.json    # ChatGPT und Codex
  ├── .claude-plugin/plugin.json   # Claude Code
  └── skills/<skill>/SKILL.md      # plus references/, scripts/, assets/
  ```

  `name`, `version`, `description` und `author` bleiben in allen drei Manifesten gleich. Der Codex-Adapter verweist mit `"skills": "./skills/"` auf den Skill-Ordner; das Standardmanifest hat ein geschlossenes Schema.

- **Namen sind API.** Plugin-Ordnername = Manifest-`name`; Skill-Ordnername = Frontmatter-`name`. Umbenennen ist Breaking Change.

- **Skill-Frontmatter bleibt portabel.** Erlaubt sind Agent-Skills-Felder plus das von OpenAI tolerierte Claude-UI-Feld `argument-hint`; dessen Inhalt darf für die Ausführung nie erforderlich sein. Verboten sind experimentelle `allowed-tools`, `disable-model-invocation` und `disallowed-tools`. Client-Policy gehört nach `agents/openai.yaml` oder in den jeweiligen Adapter.

- **Bundle-Pfade sind relativ zum Skill-Root.** Skilltexte verwenden `references/...`, `scripts/...`, `assets/...` oder `examples/...`; client-spezifische Pfadvariablen sind verboten. Jeder referenzierte Pfad muss existieren und im Skill bleiben.

- **Aufrufsyntax ist keine portable API.** Flags und Freitext stehen in der Nutzeranfrage. Client-spezifische Slash- oder Picker-Syntax gehört nur in die Installationsdoku des Clients.

- **Ein Skill, ein Name.** Skillnamen sind katalogweit eindeutig. Zusatzmodi kommen als Flag, nicht als zweiter Skill.

- **Mutation braucht eine aktuelle Nutzerentscheidung.** Ein Flag oder eine im laufenden Dialog konkret gewählte Änderung kann autorisieren; automatisch aktivierte Skills schreiben nie ohne ein solches Gate.

- **Neue Artefakte vollständig verdrahten.** Neuer Skill: `SKILL.md`, bei expliziter OpenAI-Aktivierung `agents/openai.yaml` und ein Eintrag im README-Katalog; neues Plugin zusätzlich mit allen drei Manifesten und in beiden Marketplaces. Jede Plugin-Änderung braucht denselben Semver-Bump in allen drei Manifesten und einen Eintrag im passenden Abschnitt der `CHANGELOG.md`.

- **Sprache:** Argumente englisch und kurz; alle Texte deutsch. Produktspezifische Skills dürfen ihr Zielprodukt nennen, müssen die Abhängigkeit aber klar ausweisen.

## Verweise

- Katalog und Installation: `README.md`; Nutzeränderungen: `CHANGELOG.md`.
- Agent Plugins: `plugin.json`; ChatGPT/Codex-Marketplace: `.agents/plugins/marketplace.json`; Claude-Marketplace: `.claude-plugin/marketplace.json`.
- Textmaßstab: `plugins/code/skills/agent-docs/references/style.md`.

# AGENTS.md

Plugin-Marketplace „labi" für Claude Code und Codex. `SKILL.md`-Dateien sind das ausgelieferte Produkt; Änderungen daran ändern Laufzeitverhalten.

## Befehle

- `bun run fix` formatiert JSON/Markdown, `bun run check` prüft nur.
- `bun run validate` prüft die Invarianten unten; vor jedem Commit ausführen.
- `claude plugin validate plugins/<plugin>` prüft den Claude-Adapter.

## Invarianten

- **Zwei Manifeste, ein Plugin.** Jeder Ordner enthält `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json` und `skills/<skill>/SKILL.md`. `name`, `version`, `description` und `author` bleiben in beiden Manifesten gleich. Der Codex-Adapter verweist mit `"skills": "./skills/"` auf den Skill-Ordner.

- **Namen sind API.** Plugin-Ordnername = Manifest-`name`; Skill-Ordnername = Frontmatter-`name`. Umbenennen ist Breaking Change.

- **Skill-Frontmatter bleibt portabel.** Erlaubt sind Agent-Skills-Felder plus das von OpenAI tolerierte Claude-UI-Feld `argument-hint`; dessen Inhalt darf für die Ausführung nie erforderlich sein. Verboten sind experimentelle `allowed-tools`, `disable-model-invocation` und `disallowed-tools`. Client-Policy gehört nach `agents/openai.yaml` oder in den jeweiligen Adapter. Eine `agents/openai.yaml` darf nur `interface`-Metadaten tragen; steht ein `policy`-Block darin, muss er `allow_implicit_invocation: false` setzen.

- **Bundle-Pfade bleiben im Skill.** Begleitdateien liegen unter `references/...`, `scripts/...`, `assets/...` oder `examples/...`. Client-spezifische Pfadvariablen sind verboten. Jeder Bundle-Pfad und jeder relative Link muss existieren und im Skill bleiben.

- **Aufrufsyntax ist keine portable API.** Flags und Freitext stehen in der Nutzeranfrage. Client-spezifische Slash- oder Picker-Syntax gehört nur in die Installationsdoku des Clients.

- **Ein Skill, ein Name.** Skillnamen sind katalogweit eindeutig. Zusatzmodi kommen als Flag, nicht als zweiter Skill.

- **Mutation braucht eine aktuelle Nutzerentscheidung.** Ein Flag oder eine im laufenden Dialog konkret gewählte Änderung kann autorisieren; automatisch aktivierte Skills schreiben nie ohne ein solches Gate.

- **Neue Artefakte vollständig verdrahten.** Neuer Skill: `SKILL.md`, bei expliziter OpenAI-Aktivierung `agents/openai.yaml` und ein Eintrag im README-Katalog; neues Plugin zusätzlich mit beiden Manifesten und in beiden Marketplaces. Jede Plugin-Änderung braucht denselben Semver-Bump in beiden Manifesten und einen Eintrag im passenden Abschnitt der `CHANGELOG.md`.

- **Sprache:** Argumente englisch und kurz; alle Texte deutsch. Produktspezifische Skills dürfen ihr Zielprodukt nennen, müssen die Abhängigkeit aber klar ausweisen.

## Verweise

- Katalog und Installation: `README.md`; Nutzeränderungen: `CHANGELOG.md`.
- Codex-Marketplace: `.agents/plugins/marketplace.json`; Claude-Marketplace: `.claude-plugin/marketplace.json`.
- Textmaßstab: `plugins/code/skills/agent-docs/references/style.md`.

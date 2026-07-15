# Neues Plugin anlegen (Spickzettel)

## 1. Muster wählen

- **Ein Befehl** → Single-Skill: `plugins/<name>/SKILL.md` im Plugin-Root → Befehl `/<name>`. Pflicht: `name: <name>` im Frontmatter — ohne das Feld leitet Claude Code den Befehlsnamen aus dem Versions-Verzeichnis im Plugin-Cache ab (`/name:0-1-0`).
- **Mehrere Befehle / gemeinsames Wissen** → Multi-Skill: `plugins/<name>/skills/<sub>/SKILL.md` → `/<name>:<sub>` (Beispiel: agent-docs). Geteilte Inhalte nach `plugins/<name>/references/` — Skills referenzieren sie mit `${CLAUDE_SKILL_DIR}/../../references/<datei>.md`. Referenzen dürfen nie aus dem Plugin-Ordner herauszeigen (Plugins werden in einen Cache kopiert).
- **Kein Befehl, nur Verhalten** → Hook-Plugin: `hooks/hooks.json` + Scripts, referenziert via `${CLAUDE_PLUGIN_ROOT}/…` (Beispiel: notify). Scripts brauchen `chmod +x`.

## 2. Pflichtdateien

```
plugins/<name>/
├── .claude-plugin/plugin.json   # name (= Ordnername!), version "0.1.0", description, author
├── CHANGELOG.md
└── SKILL.md, skills/… oder hooks/hooks.json
```

## 3. Frontmatter-Entscheidungen pro Skill

- `description`: bestimmt Auto-Invoke. Pushy formulieren, wenn Claude den Skill selbst ziehen soll (englisch, Trigger-Robustheit); "Use ONLY when the user explicitly asks…" für Nur-auf-Zuruf; `disable-model-invocation: true` für teure/destruktive Skills — die Description verschwindet dann komplett aus dem Kontext und ist reine Picker-UI: deutsch und kurz formulieren.
- `argument-hint: "[arg1] [arg2]"` — freeform, der Skill-Text erklärt Claude die Interpretation.
- `allowed-tools`: nur read-only vorab erlauben (z. B. `Bash(git status *)`); schreibende Tools bewusst weglassen = zweites Sicherheitsnetz neben dem Approval-Gate.

## 4. Eintragen + validieren

Eintrag in `.claude-plugin/marketplace.json` (`"source": "./plugins/<name>"`), dann `python scripts/validate.py`.

## 5. Lokal testen, dann releasen

Im Repo-Ordner: `/plugin marketplace add .` → `/plugin install <name>@labi` → Befehle testen. SKILL.md-Änderungen greifen live, alles andere braucht `/reload-plugins`. Beim Release: Version bumpen + CHANGELOG, pushen — Geräte ziehen es per `/plugin update`. Semver-Faustregel: Befehls-/Argument-Änderungen = minor, reine Instruktions-Verbesserungen = patch, Umbenennungen/Entfernungen = major.

## 6. Externe Plugins

Ein Marketplace-Eintrag kann statt auf einen lokalen Ordner auf ein fremdes Repo zeigen: `"source": { "source": "github", "repo": "owner/repo", "ref": "v1.2.0" }`. `ref` (Tag/Commit) pinnen ist Pflicht — fremder Code mit Hooks/MCP-Servern läuft lokal.

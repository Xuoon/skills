# Neues Plugin anlegen (Spickzettel)

## 1. Muster wählen

- **Ein Befehl** → Single-Skill: `plugins/<name>/SKILL.md` im Plugin-Root → Befehl `/<name>` (Beispiel: dead-code).
- **Mehrere Befehle / gemeinsames Wissen** → Multi-Skill: `plugins/<name>/skills/<sub>/SKILL.md` → `/<name>:<sub>` (Beispiel: agent-docs). Geteilte Inhalte nach `plugins/<name>/references/` — Skills referenzieren sie mit `${CLAUDE_SKILL_DIR}/../../references/<datei>.md`. Referenzen dürfen nie aus dem Plugin-Ordner herauszeigen (Plugins werden in einen Cache kopiert).

## 2. Pflichtdateien

```
plugins/<name>/
├── .claude-plugin/plugin.json   # name (= Ordnername!), version "0.1.0", description, author
├── CHANGELOG.md
└── SKILL.md oder skills/…
```

## 3. Frontmatter-Entscheidungen pro Skill

- `description`: bestimmt Auto-Invoke. Pushy formulieren, wenn Claude den Skill selbst ziehen soll; "Use ONLY when the user explicitly asks…" für Nur-auf-Zuruf; `disable-model-invocation: true` für teure/destruktive Skills (Description verschwindet dann komplett aus dem Kontext → nur noch /-Befehl).
- `argument-hint: "[arg1] [arg2]"` — freeform, der Skill-Text erklärt Claude die Interpretation.
- `allowed-tools`: nur read-only vorab erlauben (z. B. `Bash(git status *)`); schreibende Tools bewusst weglassen = zweites Sicherheitsnetz neben dem Approval-Gate.

## 4. Eintragen + validieren

Eintrag in `.claude-plugin/marketplace.json` (`"source": "./plugins/<name>"`), dann `python scripts/validate.py`.

## 5. Lokal testen, dann releasen

Im Repo-Ordner: `/plugin marketplace add .` → `/plugin install <name>@labi` → Befehle testen. SKILL.md-Änderungen greifen live, alles andere braucht `/reload-plugins`. Beim Release: Version bumpen + CHANGELOG (macht `/git-work:changelog plugins/<name>`), pushen — Geräte ziehen es per `/plugin update`.

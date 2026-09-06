# Zielbild: ein Installer, viele Clients

Belegter Stand der Client-Doku: 2026-09-06. Weicht die offizielle Doku ab, gilt sie; die Zeile hier dann korrigieren.

## Ablage

```text
.github/scripts/setup.sh                    Installer; Vorlage: setup.sh in diesem Ordner
.github/scripts/dev-web.sh                  nur bei betreutem Dev-Server (Amp-Portal, Cursor-Terminal)
.github/workflows/*.yml                     CI; Config-Lint (actionlint, ShellCheck) für Setup- und Client-Dateien
.github/tests/                              nur wenn CI-Skripte eigene Logik haben
.agents/setup                               exec bash .github/scripts/setup.sh (Amp verlangt den Pfad)
.amp/services.yaml                          Dev-Server für das Amp-Portal
.cursor/environment.json                    "install": "bash .github/scripts/setup.sh", terminals, ports
.codex/environments/environment.toml        von der Codex-App erzeugt; zeigt auf .codex/setup.sh (Wrapper)
.claude/settings.json                       SessionStart-Hook, nur remote
.devcontainer/devcontainer.json             "updateContentCommand": "bash .github/scripts/setup.sh"
.github/workflows/copilot-setup-steps.yml   nur bei GitHub Copilot Coding Agent
```

Der Installer liest Versionen aus `.node-version`, `packageManager`, `rust-toolchain.toml`, `global.json`. CI-Jobs nutzen dieselben Dateien über Setup-Actions (`node-version-file`, `bun-version-file`) und rufen den Installer nicht.

## Client-Verträge

| Client | Datei und Aufruf | Belegte Regeln |
| --- | --- | --- |
| Amp Orbs | `.agents/setup`, optional `.agents/resume`, `.amp/services.yaml` | Beide Skripte optional, ausführbar, im Repo. Setup idempotent, Timeout 20 min, keine Server oder Hintergrundprozesse (`&`, `nohup`, `setsid` enden mit dem Skript). Snapshot bis 72 h gecacht; Änderung an `.agents/setup` allein invalidiert ihn nicht. Resume läuft bei jedem Aufwachen, Amp wartet höchstens 10 s. Basis Debian 12. Services erhalten `PORT` und `PUBLIC_URL`. |
| Cursor Cloud Agents | `.cursor/environment.json` | Felder: `install` (Kommando, läuft beim Build und beim VM-Start nach dem Pull, muss idempotent sein), `start`, `terminals[{name,command,description}]` (tmux, `description` sieht der Agent), `ports[{name,port}]`, `build.dockerfile`/`context`, `image`, `snapshot`, `user`. Exports, Prozesse und In-Memory-Caches überleben den Build nicht. Ein Wrapper-Skript für `install` ist unnötig. |
| Codex Cloud | Setup-Skript im Web-UI der Umgebung | Setup läuft in eigener Bash-Session; Exports gelangen nicht in die Agent-Phase (`~/.bashrc` oder Umgebungsvariablen). Container-Cache bis 12 h, optionales Maintenance-Skript beim Wiederaufnehmen. Secrets nur während des Setups. Netz in der Agent-Phase standardmäßig aus. Image `universal`, Node-Version über „Set package versions“. `AGENTS.md` liefert Lint- und Testbefehle. Ob das UI-Setup das Repo-Skript aufrufen darf, ist in der Doku nicht ausdrücklich belegt. |
| Codex-App (lokal) | `.codex/environments/environment.toml` | Von der App erzeugt und verwaltet (`DO NOT EDIT`), versionierbar. `[setup] script` läuft beim Anlegen eines Worktrees zu Chat-Beginn, `[[actions]]` erscheinen in der App-Leiste. Der eingetragene Pfad bleibt ein kurzer Wrapper auf den Installer. |
| Claude Cloud | `.claude/settings.json` (Repo), Setup-Skript im UI der Umgebung | Ubuntu 24.04 x86_64, 4 vCPU, 16 GB. Vorinstalliert Node 20/21/22 (`/opt/node22` im PATH), Bun installiert, aber mit bekannten Proxy-Problemen beim Paketbezug. UI-Setup läuft als root, muss mit 0 enden, unter 5 min bleiben, wird etwa 7 Tage gecacht und bei Skript- oder Netzänderung neu gebaut. Repo-Hooks laufen in jeder Session, auch beim Resume; `CLAUDE_CODE_REMOTE=true` nur in der Cloud; `$CLAUDE_PROJECT_DIR` ist die Repo-Wurzel. SessionStart-Hooks haben 30 s Standard-Timeout und blockieren bei Fehler nicht. `CLAUDE_ENV_FILE` wird vor jedem Bash-Befehl als Präambel ausgeführt. Trusted-Allowlist enthält npm, nodejs.org, crates.io, rustup.rs, static.rust-lang.org, github.com und Ubuntu-Spiegel; `bun.sh` fehlt, ein Bun-Download braucht den Host zusätzlich in der Umgebung. |
| Devcontainer | `.devcontainer/devcontainer.json` | `updateContentCommand` ruft den Installer; Basisimage `mcr.microsoft.com/devcontainers/base:ubuntu-24.04` reicht, Toolchains kommen aus dem Installer. |
| Copilot Coding Agent | `.github/workflows/copilot-setup-steps.yml` | Job muss `copilot-setup-steps` heißen; änderbar sind nur `steps`, `permissions`, `runs-on`, `services`, `snapshot`, `timeout-minutes` (max. 59). Läuft als Actions-Job vor dem Agenten, nichts bleibt zwischen Aufgaben erhalten. Setup-Actions plus `install --frozen-lockfile` wie in der CI. |
| CI (GitHub Actions) | `.github/workflows/*.yml` | Setup-Actions mit Version aus den Projektdateien, Paket-Cache über Lockfile-Hash, dann `install --frozen-lockfile`. Config-Lint: `actionlint`, `shellcheck` über Wrapper und `.github/scripts/*.sh`, JSON/TOML parsen. |

## Claude-Hook

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "if [ \"${CLAUDE_CODE_REMOTE:-}\" = true ]; then bash \"${CLAUDE_PROJECT_DIR:-.}/.github/scripts/setup.sh\" || echo \"WARN: Projekt-Setup unvollständig; siehe Ausgabe oben.\" >&2; fi",
            "timeout": 240
          }
        ]
      }
    ]
  }
}
```

Erster Lauf mit Toolchain-Download kann das Hook-Timeout reißen. Dann denselben Aufruf `bash .github/scripts/setup.sh` als UI-Setup-Skript der Umgebung eintragen: der Snapshot enthält die Toolchains, der Hook prüft nur noch und installiert Abhängigkeiten. Diesen Schritt macht der Nutzer; nie als erledigt behaupten.

## Dev-Server

Amp und Cursor starten Server aus ihrer Service- oder Terminal-Konfiguration, nie aus dem Installer. Das Skript bindet `0.0.0.0`, nutzt `${PORT:-<Standard>}` mit `--strictPort` und gibt bei Vite nur den Host aus `PUBLIC_URL` zusätzlich frei:

```bash
if [[ -n "${PUBLIC_URL:-}" ]]; then
  __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS="$(node -p 'new URL(process.env.PUBLIC_URL).hostname')"
  export __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
fi
exec bun run dev:web --host 0.0.0.0 --port "${PORT:-3000}" --strictPort
```

## Prüfliste nach einer Umstellung

- Jeder Pfad in Client-Dateien, Workflows, Tests und Doku zeigt auf eine existierende Datei mit Ausführungsbit.
- ShellCheck-Aufrufe in der CI listen keine gelöschten Dateien und keine Globs ohne Treffer.
- Installer mit Attrappen aus fremdem CWD mit Leerzeichen: Exit-Code kommt durch, falsche Version bricht vor `install` ab, `uname` als `Darwin` hält den Test im Prüfpfad.
- Lockfile und Env-Dateien sind nach dem Lauf unverändert.
- Bericht nennt, was nur lokal geprüft wurde und welche UI-Schritte offen sind.

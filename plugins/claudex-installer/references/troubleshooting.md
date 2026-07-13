# Troubleshooting

## `bind: operation not permitted`

Der Start erfolgte wahrscheinlich in einer Sandbox, die das Öffnen eines Listen-Ports blockiert.
Starte CLIProxyAPI in einem normalen Terminal oder führe den betreffenden Bash-Aufruf mit der
vom Benutzer genehmigten Sandbox-Ausnahme aus. Der Server bleibt auf `127.0.0.1` beschränkt.

## Port 8318 ist bereits belegt

```bash
lsof -nP -iTCP:8318 -sTCP:LISTEN
```

Beende keinen fremden Prozess automatisch. Entweder dessen Zweck mit dem Benutzer klären oder
einen anderen Port über `--port` wählen. Config, Env-Datei und Tests müssen denselben Port nutzen.

## OAuth-Browser öffnet sich nicht

Verwende Device-Code-Flow:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/install.sh" --device-login
```

Oder lasse die URL nur ausgeben:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/install.sh" --no-browser
```

Der normale Codex-Callback verwendet standardmäßig Port 1455; auch dieser Port muss frei sein.

## `invalid_grant` oder abgelaufener Refresh-Token

Führe den Installer erneut mit OAuth aus. Lösche OAuth-Dateien nicht vorschnell; sie können
weitere Provider oder Accounts enthalten. Nur die erneute Anmeldung überschreibt bzw. ergänzt
die betroffene Codex-Authentifizierung.

## Modell ist nicht verfügbar

Modelle hängen von Account, Quota und CLIProxyAPI-Version ab:

```bash
source "$HOME/.config/claudex/env"
curl -fsS "http://127.0.0.1:${CLIPROXY_PORT}/v1/models" \
  -H "Authorization: Bearer $CLIPROXY_API_KEY"
```

Installer mit einem tatsächlich gelieferten Namen erneut ausführen:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/install.sh" --model '<modellname>'
```

## `claude.ai connectors are disabled`

Das ist im `claudex`-Prozess erwartbar: `ANTHROPIC_AUTH_TOKEN` leitet Claude Code zum lokalen
Proxy und hat Vorrang vor dem claude.ai-Login. Normales `claude` bleibt davon unberührt.

## Advisor ist deaktiviert

GPT-Modellnamen haben eventuell keinen Advisor-Rang im Claude-Code-Modellkatalog. Das betrifft
nicht den normalen Agent-, Tool-, MCP- oder Skill-Betrieb. Advisor kann experimentell aktiviert
werden, ist aber kein Bestandteil dieses Installers.

## Proxy-Log

```bash
tail -50 "$HOME/Library/Logs/CLIProxyAPI/cliproxyapi.log"
```

Niemals `~/.config/claudex/env` oder Dateien aus `~/.cli-proxy-api/` in Issues posten: Sie
enthalten lokale Client-Keys bzw. OAuth-Tokens.

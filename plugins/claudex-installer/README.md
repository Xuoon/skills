# claudex-installer

Claude-Code-Plugin für ein reproduzierbares **claudex**-Setup auf macOS: Dasselbe Claude-Code-
Harness und dieselben MCPs, Skills, Hooks und Projekte – aber GPT über einen ausschließlich lokal
gebundenen [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI).

## Installation

Marketplace registrieren:

```bash
claude plugin marketplace add Xuoon/skills
```

Plugin installieren:

```bash
claude plugin install claudex-installer@labi
```

Danach in Claude Code:

```text
/claudex-installer:install
```

Mit gewünschtem Modell oder Device-Code-Login:

```text
/claudex-installer:install --model gpt-5.6-sol --device-login
```

## Was der Skill einrichtet

- passendes offizielles CLIProxyAPI-Binary für Apple Silicon oder Intel, einschließlich Rosetta-
  Erkennung
- SHA-256-Prüfung gegen das offizielle `checksums.txt`
- Codex/OpenAI-OAuth-Login
- Localhost-only Proxy auf Port 8318 mit zufälligem Client-Key
- idempotente `claudex()`-Funktion in `~/.zshrc` mit Backup und Syntaxprüfung
- Modellermittlung über `/v1/models` und vollständiger Claude-Code-End-to-End-Test

Das Plugin selbst enthält **keine Zugangsdaten**. OAuth-Tokens und der lokale Client-Key werden
nur auf dem Zielrechner gespeichert. Das normale `claude` wird nicht verändert.

## Lokale Entwicklung

```bash
claude plugin validate ./plugins/claudex-installer --strict
claude --plugin-dir ./plugins/claudex-installer
```

## Hinweise

Die Nutzung eines ChatGPT-/Codex-Abos über einen Drittanbieter-Proxy kann von den
Nutzungsbedingungen des Anbieters abweichen. Der Installer exponiert den Proxy nicht im Netzwerk.

Lizenz: [MIT](../../LICENSE)

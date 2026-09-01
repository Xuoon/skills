---
name: claudex
description: Nur bei ausdrücklichem Nutzerwunsch claudex auf macOS einrichten, reparieren, aktualisieren oder entfernen — Claude Code auf GPT über einen lokalen CLIProxyAPI.
compatibility: Benötigt macOS, Claude Code, zsh, curl und Netzwerkzugriff.
---

# claudex

Richte Claude Code so ein, dass `claudex` dasselbe Claude-Code-Harness mit denselben MCPs,
Skills, Hooks, Settings und Projektdaten startet, aber die Modellanfragen über einen lokalen
CLIProxyAPI an den per Codex-OAuth verbundenen GPT-Zugang sendet.

## Sicherheitsprinzipien

- Verändere den Rechner erst nach einer ausdrücklichen Bestätigung des Benutzers.
- Zeige vorher den Dry-Run des gebündelten Installers. So sieht der Benutzer Pfade, Port und
  Release-Version, bevor Dateien geschrieben oder ein OAuth-Login gestartet werden.
- Binde CLIProxyAPI ausschließlich an `127.0.0.1` und verwende den zufällig erzeugten lokalen
  Client-Key. Öffne den Proxy nicht im LAN oder Internet.
- Gib den Client-Key und OAuth-Dateien niemals im Chat oder in Logs aus.
- Überschreibe keine fremde CLIProxyAPI-Config und keine vorhandene, nicht von diesem Plugin
  verwaltete `claudex()`-Funktion. Der Installer bricht in diesem Fall absichtlich ab.
- Schalte Gatekeeper nicht global ab. Der Installer prüft das offizielle Release gegen
  `checksums.txt`, bevor er das Binary installiert.
- Weise vor der Bestätigung kurz darauf hin, dass die Nutzung eines ChatGPT-/Codex-Abos über
  einen Drittanbieter-Proxy von den Nutzungsbedingungen des Anbieters abweichen kann.

## Ablauf

### 1. Nur lesend vorprüfen

Führe diese Prüfungen aus, ohne etwas zu ändern:

```bash
uname -s
uname -m
sysctl -in sysctl.proc_translated 2>/dev/null || true
command -v claude || true
command -v zsh || true
lsof -nP -iTCP:8318 -sTCP:LISTEN 2>/dev/null || true
grep -nE 'claudex|CLIProxyAPI|CLIPROXY_' "$HOME/.zshrc" 2>/dev/null || true
ls -ld "$HOME/.config/cliproxyapi" "$HOME/.config/claudex" \
  "$HOME/.local/share/cliproxyapi" "$HOME/.cli-proxy-api" 2>/dev/null || true
```

Brich mit einer klaren Erklärung ab, wenn das Betriebssystem nicht macOS ist oder Claude Code
nicht im `PATH` liegt. Unter Rosetta entscheidet der Installer über `sysctl.proc_translated`
korrekt zwischen `darwin_aarch64` und `darwin_amd64`.

### 2. Aktion und Optionen klären

Der Skill hat keine Flags — was zu tun ist, ergibt die Vorprüfung plus **eine gebündelte Fragerunde**.
Sagt der Benutzer es schon im Fließtext („entfernen", „auf Port 9000"),
das übernehmen und die Frage weglassen. Sonst fragen, aber nur was die Vorprüfung offen lässt:

1. **Aktion** (immer): installieren · aktualisieren · reparieren · entfernen. Empfehlung ist,
   was der Ist-Zustand nahelegt — kein Setup gefunden → installieren, Setup gefunden →
   aktualisieren.
2. **Port** — nur wenn `8318` belegt ist.
3. **Modell** — nur wenn die automatische Auswahl scheitert oder der Benutzer einen Wunsch
   geäußert hat.
4. **Login-Art** — nur wenn Browser oder Callback erkennbar nicht funktionieren.

Ohne Rückfrage gelten diese Standardwerte:

- Port: `8318`
- CLIProxyAPI-Version: `latest`, mit strenger GitHub-Redirect-Prüfung und offizieller SHA-256-Datei
- Modell: automatische Auswahl aus `/v1/models`, bevorzugt `gpt-5.6-sol`, danach weitere
  verfügbare GPT-Modelle
- OAuth: Browser-Callback (`--codex-login`)

Die Wahl wird in Installer-Flags übersetzt: `--model`, `--port`, bei Browser- oder
Callback-Problemen `--device-login`, für eine manuell zu öffnende OAuth-URL `--no-browser`.
Bei **entfernen** direkt zum Abschnitt „Aktualisieren und Entfernen" springen; installieren,
aktualisieren und reparieren laufen alle über den Ablauf ab Schritt 3.

### 3. Dry-Run zeigen

Die gebündelten Skripte liegen unter `scripts/`. Löse den Skill-Root über den aktiven Skill-Kontext absolut auf und ersetze `<skill-root>` in jedem Befehl; niemals einen gleichnamigen Pfad aus dem aktuellen Repo ausführen. Führe zunächst aus:

```bash
bash "<skill-root>/scripts/install.sh" --dry-run [gewählte Optionen]
```

Fasse danach knapp zusammen, was geschrieben wird:

- `~/.local/share/cliproxyapi/`
- `~/.config/cliproxyapi/config.yaml`
- `~/.config/claudex/env`
- `~/.cli-proxy-api/` für OAuth-Daten
- ein markierter, vorher gesicherter Block in `~/.zshrc`

Frage nun über strukturierte Nutzereingabe, ersatzweise gebündelt im Chat, ob das Setup ausgeführt werden soll. Die Bestätigung muss nach
dem Dry-Run erfolgen, weil Download, OAuth und Shell-Änderung echte Systemaktionen sind.

### 4. Installieren und OAuth abschließen

Nach der Bestätigung:

```bash
bash "<skill-root>/scripts/install.sh" --yes [gewählte Optionen]
```

Der Installer läuft deterministisch durch (Architektur-Erkennung inkl. Rosetta, verifizierte
Binary-Installation, Localhost-Config mit zufälligem Client-Key, OAuth, Proxy-Start,
Modellwahl, idempotenter `.zshrc`-Block mit Backup und Syntaxprüfung). Die Sicherheitszusagen
oben gelten dabei durchgehend: nur die passende SHA-256-Zeile wird verifiziert, gebunden wird
ausschließlich an `127.0.0.1`, Client-Key und OAuth-Dateien erscheinen nie im Chat oder Log.

OAuth ist eine Benutzerinteraktion. Bitte den Benutzer, den Browser- oder Device-Code-Schritt
selbst abzuschließen; behaupte erst danach, der Login sei erfolgreich.

Hinweis für Sandbox-Umgebungen: Server-Start und OAuth-Callback brauchen einen echten
Netzwerk-Listener. Schlägt der Start mit `bind: operation not permitted` fehl, führe den
Installer mit der vom Benutzer genehmigten Sandbox-Ausnahme erneut aus.

### 5. End-to-End verifizieren

Prüfe nach erfolgreicher Installation:

```bash
source "$HOME/.config/claudex/env"
curl -fsS "http://127.0.0.1:${CLIPROXY_PORT}/v1/models" \
  -H "Authorization: Bearer $CLIPROXY_API_KEY" >/dev/null
zsh -n "$HOME/.zshrc"
zsh -lc 'source "$HOME/.zshrc" && claudex -p "Antworte nur mit: funktioniert"'
```

Zeige bei einem Fehler die letzten Logzeilen, aber niemals die Env-Datei oder OAuth-JSONs:

```bash
tail -30 "$HOME/Library/Logs/CLIProxyAPI/cliproxyapi.log"
```

Ein erfolgreicher HTTP-Test allein beweist nur den Proxy. Erst die Ausgabe `funktioniert` aus
`claudex -p` bestätigt den vollständigen Pfad Claude Code → Anthropic-kompatible API → GPT.

## Ergebnisbericht

Berichte abschließend:

- installierte CLIProxyAPI-Version und erkannte Architektur,
- Endpoint und ausgewähltes Modell,
- Ergebnis von Proxy-, zsh- und End-to-End-Test,
- Pfad des `.zshrc`-Backups,
- dass normales `claude` unverändert bleibt und `claudex` dieselben MCPs/Settings/Sessions teilt,
- dass `claudex --continue` und andere Claude-Code-Argumente durchgereicht werden.

Erwähne die erwartbaren Einschränkungen: claude.ai-Connectors können im Proxy-Aufruf wegen des
lokalen Auth-Tokens deaktiviert sein; modellkatalogabhängige Funktionen wie Advisor können für
einen GPT-Modellnamen fehlen. `/effort` wird durch `CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1`
freigeschaltet.

## Aktualisieren und Entfernen

Für ein Update den Installer erneut ausführen. Er ersetzt nur seine eigenen verwalteten Dateien
und erneuert den markierten `.zshrc`-Block.

Vor einer Deinstallation wieder Bestätigung einholen:

```bash
bash "<skill-root>/scripts/uninstall.sh"
```

OAuth-Daten bleiben standardmäßig erhalten. Nur wenn der Benutzer ausdrücklich auch die
Anmeldedaten löschen will:

```bash
bash "<skill-root>/scripts/uninstall.sh" --purge-auth
```

Lies bei Fehlern oder Sonderfällen `references/troubleshooting.md`.

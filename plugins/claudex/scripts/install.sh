#!/usr/bin/env bash
set -euo pipefail

PORT="8318"
VERSION="latest"
MODEL=""
ASSUME_YES=0
DRY_RUN=0
SKIP_LOGIN=0
DEVICE_LOGIN=0
NO_BROWSER=0

usage() {
  cat <<'EOF'
Installiert CLIProxyAPI und richtet die zsh-Funktion "claudex" ein.

Verwendung:
  install.sh [Optionen]

Optionen:
  --version VERSION   CLIProxyAPI-Version, z. B. 7.2.72 (Standard: latest)
  --port PORT         lokaler Port (Standard: 8318)
  --model MODELL      gewünschtes GPT-Modell; sonst automatische Auswahl
  --skip-login        Codex/OAuth-Login überspringen
  --device-login      Codex Device-Code-Flow statt Browser-Callback
  --no-browser        Browser beim normalen OAuth-Flow nicht automatisch öffnen
  --yes               Sicherheitsabfrage bestätigen
  --dry-run           geplante Änderungen anzeigen, nichts verändern
  -h, --help          Hilfe anzeigen
EOF
}

fail() {
  printf 'FEHLER: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '› %s\n' "$*"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      [ "$#" -ge 2 ] || fail "--version benötigt einen Wert"
      VERSION="$2"
      shift 2
      ;;
    --port)
      [ "$#" -ge 2 ] || fail "--port benötigt einen Wert"
      PORT="$2"
      shift 2
      ;;
    --model)
      [ "$#" -ge 2 ] || fail "--model benötigt einen Wert"
      MODEL="$2"
      shift 2
      ;;
    --skip-login) SKIP_LOGIN=1; shift ;;
    --device-login) DEVICE_LOGIN=1; shift ;;
    --no-browser) NO_BROWSER=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unbekannte Option: $1" ;;
  esac
done

[ "$(uname -s)" = "Darwin" ] || fail "Dieses Setup unterstützt ausschließlich macOS."
case "$PORT" in
  ''|*[!0-9]*) fail "Ungültiger Port: $PORT" ;;
esac
[ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || fail "Port muss zwischen 1024 und 65535 liegen."
case "$VERSION" in
  latest|[0-9]*.[0-9]*.[0-9]*) ;;
  v[0-9]*.[0-9]*.[0-9]*) VERSION="${VERSION#v}" ;;
  *) fail "Ungültige Version: $VERSION" ;;
esac
if [ -n "$MODEL" ]; then
  printf '%s' "$MODEL" | grep -Eq '^[A-Za-z0-9._/():-]+$' || fail "Ungültiger Modellname: $MODEL"
fi

for dependency in curl tar shasum openssl awk grep cut head tail install mktemp lsof zsh; do
  command -v "$dependency" >/dev/null 2>&1 || fail "Benötigtes Programm fehlt: $dependency"
done
command -v claude >/dev/null 2>&1 || fail "Claude Code wurde nicht im PATH gefunden."

MACHINE="$(uname -m)"
TRANSLATED="$(sysctl -in sysctl.proc_translated 2>/dev/null || true)"
case "$MACHINE:$TRANSLATED" in
  arm64:*|x86_64:1) ARCH="aarch64" ;;
  x86_64:*) ARCH="amd64" ;;
  *) fail "Nicht unterstützte Architektur: $MACHINE" ;;
esac

if [ "$VERSION" = "latest" ]; then
  info "Ermittle aktuelles CLIProxyAPI-Release …"
  LATEST_URL="$(curl --proto '=https' --tlsv1.2 -fsSL -o /dev/null -w '%{url_effective}' \
    https://github.com/router-for-me/CLIProxyAPI/releases/latest)"
  case "$LATEST_URL" in
    https://github.com/router-for-me/CLIProxyAPI/releases/tag/v*) ;;
    *) fail "Unerwartete Release-URL: $LATEST_URL" ;;
  esac
  TAG="${LATEST_URL##*/}"
  VERSION="${TAG#v}"
else
  TAG="v$VERSION"
fi

ASSET="CLIProxyAPI_${VERSION}_darwin_${ARCH}.tar.gz"
BASE_URL="https://github.com/router-for-me/CLIProxyAPI/releases/download/${TAG}"
INSTALL_ROOT="$HOME/.local/share/cliproxyapi"
BIN_DIR="$INSTALL_ROOT/bin"
BIN_PATH="$BIN_DIR/cli-proxy-api"
CONFIG_DIR="$HOME/.config/cliproxyapi"
CONFIG_PATH="$CONFIG_DIR/config.yaml"
ENV_DIR="$HOME/.config/claudex"
ENV_PATH="$ENV_DIR/env"
AUTH_DIR="$HOME/.cli-proxy-api"
LOG_DIR="$HOME/Library/Logs/CLIProxyAPI"
LOG_PATH="$LOG_DIR/cliproxyapi.log"
PID_PATH="$INSTALL_ROOT/cliproxyapi.pid"
ZSHRC="$HOME/.zshrc"
MARKER_START="# >>> claudex-installer >>>"
MARKER_END="# <<< claudex-installer <<<"

printf '\nGeplantes Setup:\n'
printf '  CLIProxyAPI: v%s (%s)\n' "$VERSION" "$ARCH"
printf '  Binary:      %s\n' "$BIN_PATH"
printf '  Config:      %s\n' "$CONFIG_PATH"
printf '  OAuth-Daten: %s\n' "$AUTH_DIR"
printf '  Endpoint:    http://127.0.0.1:%s\n' "$PORT"
printf '  Shell:       %s\n' "$ZSHRC"
printf '\nHinweis: Die Verwendung eines ChatGPT-/Codex-Abos über einen Drittanbieter-Proxy kann\n'
printf 'von den Nutzungsbedingungen des Anbieters abweichen. Das Setup bindet ausschließlich\n'
printf 'an 127.0.0.1 und schützt den lokalen Endpoint mit einem zufälligen Client-Key.\n\n'

if [ "$DRY_RUN" -eq 1 ]; then
  info "Dry-Run: Es werden keine Dateien oder Logins verändert."
elif [ "$ASSUME_YES" -ne 1 ]; then
  printf 'Setup fortsetzen? [j/N] '
  read -r answer
  case "$answer" in
    j|J|ja|JA|Ja) ;;
    *) printf 'Abgebrochen.\n'; exit 0 ;;
  esac
fi

if [ -f "$CONFIG_PATH" ] && ! grep -q '^# Managed by claudex-installer$' "$CONFIG_PATH"; then
  fail "Vorhandene, fremde Config wird nicht überschrieben: $CONFIG_PATH"
fi
if [ -f "$ENV_PATH" ] && ! grep -q '^# Managed by claudex-installer$' "$ENV_PATH"; then
  fail "Vorhandene, fremde Env-Datei wird nicht überschrieben: $ENV_PATH"
fi
if [ -f "$ZSHRC" ] && grep -Eq '^[[:space:]]*(function[[:space:]]+)?claudex([[:space:]]*\(\))?[[:space:]]*\{' "$ZSHRC" \
  && ! grep -qF "$MARKER_START" "$ZSHRC"; then
  fail "In $ZSHRC existiert bereits eine nicht verwaltete claudex-Funktion. Bitte zuerst manuell prüfen."
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf '+ curl %s/%s\n' "$BASE_URL" "$ASSET"
  printf '+ curl %s/checksums.txt\n' "$BASE_URL"
  printf '+ shasum -a 256 -c <passende Zeile>\n'
  printf '+ install cli-proxy-api %s\n' "$BIN_PATH"
  printf '+ schreibe sichere lokale Config und Env-Datei\n'
  [ "$SKIP_LOGIN" -eq 1 ] || printf '+ %s --config %s --codex-login\n' "$BIN_PATH" "$CONFIG_PATH"
  printf '+ aktualisiere verwalteten Block in %s\n' "$ZSHRC"
  exit 0
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/claudex-installer.XXXXXX")"
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

info "Lade $ASSET …"
curl --proto '=https' --tlsv1.2 -fL "$BASE_URL/$ASSET" -o "$WORKDIR/$ASSET"
curl --proto '=https' --tlsv1.2 -fL "$BASE_URL/checksums.txt" -o "$WORKDIR/checksums.txt"
CHECKSUM_LINE="$(grep -F "  $ASSET" "$WORKDIR/checksums.txt" || true)"
[ -n "$CHECKSUM_LINE" ] || fail "Keine offizielle Prüfsumme für $ASSET gefunden."
(
  cd "$WORKDIR"
  printf '%s\n' "$CHECKSUM_LINE" | shasum -a 256 -c -
  tar -xzf "$ASSET"
)
[ -x "$WORKDIR/cli-proxy-api" ] || fail "Tarball enthält kein ausführbares cli-proxy-api-Binary."

# Einen zuvor von diesem Installer gestarteten Prozess vor Update oder Portwechsel sauber beenden.
if [ -f "$PID_PATH" ]; then
  OLD_PID="$(cat "$PID_PATH" 2>/dev/null || true)"
  case "$OLD_PID" in
    ''|*[!0-9]*) ;;
    *)
      OLD_COMMAND="$(ps -p "$OLD_PID" -o command= 2>/dev/null || true)"
      case "$OLD_COMMAND" in
        *"$BIN_PATH"*)
          kill "$OLD_PID" 2>/dev/null || true
          attempt=0
          while kill -0 "$OLD_PID" 2>/dev/null && [ "$attempt" -lt 20 ]; do
            sleep 0.1
            attempt=$((attempt + 1))
          done
          ;;
      esac
      ;;
  esac
  rm -f "$PID_PATH"
fi

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$ENV_DIR" "$AUTH_DIR" "$LOG_DIR"
install -m 0755 "$WORKDIR/cli-proxy-api" "$BIN_PATH"
printf '%s\n' "$VERSION" > "$INSTALL_ROOT/version"

if [ -f "$ENV_PATH" ]; then
  # Die Datei stammt laut Marker von diesem Installer. Nur einfache Zuweisungen laden.
  # shellcheck disable=SC1090
  . "$ENV_PATH"
  API_KEY="${CLIPROXY_API_KEY:-}"
else
  API_KEY=""
fi
[ -n "$API_KEY" ] || API_KEY="$(openssl rand -hex 32)"

cat > "$CONFIG_PATH" <<EOF
# Managed by claudex-installer
host: "127.0.0.1"
port: $PORT
auth-dir: "~/.cli-proxy-api"
api-keys:
  - "$API_KEY"
remote-management:
  allow-remote: false
  secret-key: ""
  disable-control-panel: true
debug: false
logging-to-file: false
usage-statistics-enabled: false
ws-auth: true
EOF
chmod 600 "$CONFIG_PATH"

if [ "$SKIP_LOGIN" -ne 1 ]; then
  info "Starte Codex/OpenAI-OAuth …"
  LOGIN_FLAG="--codex-login"
  [ "$DEVICE_LOGIN" -eq 1 ] && LOGIN_FLAG="--codex-device-login"
  LOGIN_ARGS=(--config "$CONFIG_PATH" "$LOGIN_FLAG")
  [ "$NO_BROWSER" -eq 1 ] && LOGIN_ARGS+=(--no-browser)
  "$BIN_PATH" "${LOGIN_ARGS[@]}"
fi

server_is_ready() {
  curl -fsS -o /dev/null "http://127.0.0.1:${PORT}/v1/models" \
    -H "Authorization: Bearer $API_KEY"
}

if ! server_is_ready 2>/dev/null; then
  if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    fail "Port $PORT wird von einem anderen Prozess verwendet."
  fi
  info "Starte CLIProxyAPI …"
  nohup "$BIN_PATH" --config "$CONFIG_PATH" >>"$LOG_PATH" 2>&1 &
  SERVER_PID=$!
  printf '%s\n' "$SERVER_PID" > "$PID_PATH"
  ready=0
  attempt=0
  while [ "$attempt" -lt 20 ]; do
    if server_is_ready 2>/dev/null; then
      ready=1
      break
    fi
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
      break
    fi
    sleep 0.5
    attempt=$((attempt + 1))
  done
  if [ "$ready" -ne 1 ]; then
    printf 'Letzte Logzeilen:\n' >&2
    tail -20 "$LOG_PATH" >&2 || true
    fail "CLIProxyAPI konnte nicht gestartet werden."
  fi
fi

MODELS_JSON="$(curl -fsS "http://127.0.0.1:${PORT}/v1/models" \
  -H "Authorization: Bearer $API_KEY")"
MODEL_IDS="$(printf '%s' "$MODELS_JSON" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 || true)"
[ -n "$MODEL_IDS" ] || fail "Der Proxy liefert keine Modelle. Ist der Codex-Login abgeschlossen?"

if [ -n "$MODEL" ]; then
  printf '%s\n' "$MODEL_IDS" | grep -Fxq "$MODEL" || {
    printf 'Verfügbare Modelle:\n%s\n' "$MODEL_IDS" >&2
    fail "Gewünschtes Modell ist nicht verfügbar: $MODEL"
  }
else
  for candidate in gpt-5.6-sol gpt-5.5 gpt-5.4 gpt-5-codex; do
    if printf '%s\n' "$MODEL_IDS" | grep -Fxq "$candidate"; then
      MODEL="$candidate"
      break
    fi
  done
  if [ -z "$MODEL" ]; then
    MODEL="$(printf '%s\n' "$MODEL_IDS" | grep '^gpt-' | grep -v 'image' | head -1 || true)"
  fi
fi
[ -n "$MODEL" ] || {
  printf 'Verfügbare Modelle:\n%s\n' "$MODEL_IDS" >&2
  fail "Kein geeignetes GPT-Modell gefunden."
}

{
  printf '# Managed by claudex-installer\n'
  printf 'export CLIPROXY_API_KEY=%q\n' "$API_KEY"
  printf 'export CLIPROXY_PORT=%q\n' "$PORT"
  printf 'export CLIPROXY_BIN=%q\n' "$BIN_PATH"
  printf 'export CLIPROXY_CONFIG=%q\n' "$CONFIG_PATH"
  printf 'export CLAUDEX_MODEL=%q\n' "$MODEL"
} > "$ENV_PATH"
chmod 600 "$ENV_PATH"

if [ -f "$ZSHRC" ]; then
  BACKUP="$ZSHRC.claudex-installer.$(date +%Y%m%d%H%M%S).bak"
  cp "$ZSHRC" "$BACKUP"
else
  : > "$ZSHRC"
  BACKUP="(neu angelegt)"
fi
ZSHRC_TMP="$(mktemp "${TMPDIR:-/tmp}/claudex-zshrc.XXXXXX")"
awk -v start="$MARKER_START" -v end="$MARKER_END" '
  $0 == start { skipping = 1; next }
  $0 == end   { skipping = 0; next }
  !skipping   { print }
' "$ZSHRC" > "$ZSHRC_TMP"

cat >> "$ZSHRC_TMP" <<'EOF'

# >>> claudex-installer >>>
# Claude Code mit GPT über den ausschließlich lokal gebundenen CLIProxyAPI.
claudex() {
  local claudex_env="$HOME/.config/claudex/env"
  if [[ ! -r "$claudex_env" ]]; then
    echo "claudex: Konfiguration fehlt: $claudex_env" >&2
    return 1
  fi
  source "$claudex_env"

  local claudex_url="http://127.0.0.1:${CLIPROXY_PORT}"
  if ! curl -fsS -o /dev/null "$claudex_url/v1/models" \
      -H "Authorization: Bearer $CLIPROXY_API_KEY" 2>/dev/null; then
    mkdir -p "$HOME/Library/Logs/CLIProxyAPI"
    nohup "$CLIPROXY_BIN" --config "$CLIPROXY_CONFIG" \
      >>"$HOME/Library/Logs/CLIProxyAPI/cliproxyapi.log" 2>&1 &
    local attempt
    for attempt in {1..20}; do
      curl -fsS -o /dev/null "$claudex_url/v1/models" \
        -H "Authorization: Bearer $CLIPROXY_API_KEY" 2>/dev/null && break
      sleep 0.5
    done
  fi

  if ! curl -fsS -o /dev/null "$claudex_url/v1/models" \
      -H "Authorization: Bearer $CLIPROXY_API_KEY" 2>/dev/null; then
    echo "claudex: CLIProxyAPI ist nicht erreichbar. Log: ~/Library/Logs/CLIProxyAPI/cliproxyapi.log" >&2
    return 1
  fi

  env \
    ANTHROPIC_BASE_URL="$claudex_url" \
    ANTHROPIC_AUTH_TOKEN="$CLIPROXY_API_KEY" \
    CLAUDE_CODE_SUBAGENT_MODEL="$CLAUDEX_MODEL" \
    CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
    CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 \
    ENABLE_TOOL_SEARCH=false \
    claude --model "$CLAUDEX_MODEL" "$@"
}
# <<< claudex-installer <<<
EOF
mv "$ZSHRC_TMP" "$ZSHRC"

zsh -n "$ZSHRC" || {
  [ "$BACKUP" = "(neu angelegt)" ] || cp "$BACKUP" "$ZSHRC"
  fail "zsh-Syntaxprüfung fehlgeschlagen; die Sicherung wurde wiederhergestellt."
}

printf '\n✓ claudex wurde eingerichtet.\n'
printf '  Modell:       %s\n' "$MODEL"
printf '  Endpoint:     http://127.0.0.1:%s\n' "$PORT"
printf '  Config:       %s\n' "$CONFIG_PATH"
printf '  Shell-Backup: %s\n' "$BACKUP"
printf '\nÖffne ein neues Terminal oder führe aus:\n'
printf '  source %s\n' "$ZSHRC"
printf '  claudex\n'
printf '\nSchnelltest ohne interaktive Sitzung:\n'
printf '  source %s && claudex -p "Antworte nur mit: funktioniert"\n' "$ZSHRC"

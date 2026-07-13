#!/usr/bin/env bash
set -euo pipefail

ASSUME_YES=0
PURGE_AUTH=0

usage() {
  cat <<'EOF'
Entfernt das vom claudex-installer verwaltete lokale Setup.

Optionen:
  --purge-auth   löscht zusätzlich ~/.cli-proxy-api mit den OAuth-Daten
  --yes          Sicherheitsabfrage bestätigen
  -h, --help     Hilfe anzeigen
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --purge-auth) PURGE_AUTH=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'FEHLER: Unbekannte Option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

INSTALL_ROOT="$HOME/.local/share/cliproxyapi"
BIN_PATH="$INSTALL_ROOT/bin/cli-proxy-api"
CONFIG_PATH="$HOME/.config/cliproxyapi/config.yaml"
ENV_PATH="$HOME/.config/claudex/env"
AUTH_DIR="$HOME/.cli-proxy-api"
PID_PATH="$INSTALL_ROOT/cliproxyapi.pid"
ZSHRC="$HOME/.zshrc"
MARKER_START="# >>> claudex-installer >>>"
MARKER_END="# <<< claudex-installer <<<"

printf 'Entfernt werden:\n'
printf '  - CLIProxyAPI-Binary und Installer-Metadaten\n'
printf '  - verwaltete Config und claudex-Env-Datei\n'
printf '  - verwalteter claudex-Block in ~/.zshrc\n'
if [ "$PURGE_AUTH" -eq 1 ]; then
  printf '  - OAuth-Daten in %s (nicht rückgängig zu machen)\n' "$AUTH_DIR"
else
  printf 'Beibehalten werden die OAuth-Daten in %s.\n' "$AUTH_DIR"
fi

if [ "$ASSUME_YES" -ne 1 ]; then
  printf 'Fortsetzen? [j/N] '
  read -r answer
  case "$answer" in
    j|J|ja|JA|Ja) ;;
    *) printf 'Abgebrochen.\n'; exit 0 ;;
  esac
fi

if [ -f "$PID_PATH" ]; then
  PID="$(cat "$PID_PATH" 2>/dev/null || true)"
  case "$PID" in
    ''|*[!0-9]*) ;;
    *)
      COMMAND="$(ps -p "$PID" -o command= 2>/dev/null || true)"
      case "$COMMAND" in
        *"$BIN_PATH"*) kill "$PID" 2>/dev/null || true ;;
      esac
      ;;
  esac
fi

if [ -f "$ZSHRC" ] && grep -qF "$MARKER_START" "$ZSHRC"; then
  BACKUP="$ZSHRC.claudex-uninstall.$(date +%Y%m%d%H%M%S).bak"
  cp "$ZSHRC" "$BACKUP"
  TMP="$(mktemp "${TMPDIR:-/tmp}/claudex-uninstall.XXXXXX")"
  awk -v start="$MARKER_START" -v end="$MARKER_END" '
    $0 == start { skipping = 1; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$ZSHRC" > "$TMP"
  mv "$TMP" "$ZSHRC"
  zsh -n "$ZSHRC" || {
    cp "$BACKUP" "$ZSHRC"
    printf 'FEHLER: zsh-Syntaxprüfung fehlgeschlagen; Sicherung wiederhergestellt.\n' >&2
    exit 1
  }
fi

if [ -f "$CONFIG_PATH" ] && ! grep -q '^# Managed by claudex-installer$' "$CONFIG_PATH"; then
  printf 'WARNUNG: Fremde Config bleibt erhalten: %s\n' "$CONFIG_PATH" >&2
else
  rm -f "$CONFIG_PATH"
fi
if [ -f "$ENV_PATH" ] && ! grep -q '^# Managed by claudex-installer$' "$ENV_PATH"; then
  printf 'WARNUNG: Fremde Env-Datei bleibt erhalten: %s\n' "$ENV_PATH" >&2
else
  rm -f "$ENV_PATH"
fi
rm -rf "$INSTALL_ROOT"
[ "$PURGE_AUTH" -eq 1 ] && rm -rf "$AUTH_DIR"

printf '✓ claudex-Setup entfernt. Öffne ein neues Terminal.\n'

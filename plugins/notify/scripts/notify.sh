#!/usr/bin/env bash
# Desktop-Benachrichtigung für Claude-Code-Hooks.
# Aufruf: notify.sh <stop|notification> — das Hook-JSON kommt via stdin.
# Darf nie fehlschlagen oder blockieren: im Zweifel still exit 0.
set -u

event="${1:-stop}"
input="$(cat 2>/dev/null || true)"

json_field() {
  # $1 = Feldname; jq wenn vorhanden, sonst sed-Heuristik (reicht für einfache Strings)
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null
  else
    printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
  fi
}

cwd="$(json_field cwd)"
title="Claude Code"
[ -n "$cwd" ] && title="Claude Code · $(basename "$cwd")"

case "$event" in
  notification)
    message="$(json_field message)"
    message="${message:-Braucht Input}"
    sound="Ping"
    ;;
  *)
    message="Fertig — wartet auf dich"
    sound="Glass"
    ;;
esac

if [ "$(uname)" = "Darwin" ]; then
  # Quotes/Backslashes für AppleScript escapen
  message="${message//\\/\\\\}"; message="${message//\"/\\\"}"
  title="${title//\\/\\\\}"; title="${title//\"/\\\"}"
  /usr/bin/osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\"" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "$title" "$message" >/dev/null 2>&1 || true
fi

exit 0

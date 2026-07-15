#!/usr/bin/env bash
# Desktop-Benachrichtigung — Claude-Code-Hook und Standalone-CLI für andere Harnesses.
#
# Hook-Modus (Claude Code):    notify.sh <stop|notification>   — Hook-JSON kommt via stdin.
# Standalone (andere Agents):  notify.sh --agent "Codex" --message "Build fertig" [--title …]
#                              [--subtitle …] [--sound Glass]; Agent-Name auch via $NOTIFY_AGENT.
#
# Anzeige: Titel = Projekt (basename cwd), Untertitel = Agent + Status, Text = Meldung.
# macOS: terminal-notifier falls installiert (Klick fokussiert das Terminal, gruppiert pro
# Projekt), sonst osascript. Linux: notify-send. Windows (Git Bash): scripts/notify.ps1.
# Darf nie fehlschlagen oder blockieren: im Zweifel still exit 0.
set -u

event=""
agent="${NOTIFY_AGENT:-Claude Code}"
title="" message="" subtitle="" sound=""

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)    agent="${2:-}"; shift 2 ;;
    --title)    title="${2:-}"; shift 2 ;;
    --message)  message="${2:-}"; shift 2 ;;
    --subtitle) subtitle="${2:-}"; shift 2 ;;
    --sound)    sound="${2:-}"; shift 2 ;;
    --*)        shift ;;
    *)          event="$1"; shift ;;
  esac
done

input=""
[ ! -t 0 ] && input="$(cat 2>/dev/null || true)"

json_field() {
  # $1 = Feldname; jq wenn vorhanden, sonst sed-Heuristik (reicht für einfache Strings)
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null
  else
    printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
  fi
}

cwd="$(json_field cwd)"
project="$(basename "${cwd:-$PWD}")"

case "$event" in
  notification)
    message="${message:-$(json_field message)}"
    message="${message:-Braucht deinen Input}"
    subtitle="${subtitle:-$agent · wartet ⏳}"
    sound="${sound:-Ping}"
    ;;
  stop)
    message="${message:-Wartet auf dich}"
    subtitle="${subtitle:-$agent · fertig ✅}"
    sound="${sound:-Glass}"
    ;;
  *)
    message="${message:-$(json_field message)}"
    message="${message:-Benachrichtigung}"
    subtitle="${subtitle:-$agent}"
    sound="${sound:-Glass}"
    ;;
esac
title="${title:-$project}"

os="$(uname 2>/dev/null || true)"
case "$os" in
  Darwin)
    if command -v terminal-notifier >/dev/null 2>&1; then
      args=(-title "$title" -subtitle "$subtitle" -message "$message" -sound "$sound" -group "notify-$title")
      case "${TERM_PROGRAM:-}" in
        iTerm.app)      args+=(-activate com.googlecode.iterm2) ;;
        Apple_Terminal) args+=(-activate com.apple.Terminal) ;;
        vscode)         args+=(-activate com.microsoft.VSCode) ;;
        ghostty)        args+=(-activate com.mitchellh.ghostty) ;;
        WezTerm)        args+=(-activate com.github.wez.wezterm) ;;
      esac
      terminal-notifier "${args[@]}" >/dev/null 2>&1 || true
    else
      # Quotes/Backslashes für AppleScript escapen
      message="${message//\\/\\\\}"; message="${message//\"/\\\"}"
      title="${title//\\/\\\\}"; title="${title//\"/\\\"}"
      subtitle="${subtitle//\\/\\\\}"; subtitle="${subtitle//\"/\\\"}"
      /usr/bin/osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\" sound name \"$sound\"" >/dev/null 2>&1 || true
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    ps1="$(dirname "$0")/notify.ps1"
    command -v cygpath >/dev/null 2>&1 && ps1="$(cygpath -w "$ps1" 2>/dev/null || printf '%s' "$ps1")"
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$ps1" \
      -Title "$title" -Subtitle "$subtitle" -Message "$message" >/dev/null 2>&1 || true
    ;;
  *)
    command -v notify-send >/dev/null 2>&1 && notify-send -a "$agent" "$title — $subtitle" "$message" >/dev/null 2>&1 || true
    ;;
esac

exit 0

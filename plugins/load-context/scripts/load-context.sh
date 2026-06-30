#!/usr/bin/env bash
# load-context — repo-spezifische Doku via SessionStart-Hook in den Kontext laden.
# Feuert bei jedem Session-Start UND nach jedem Compact (SessionStart source=compact);
# der stdout eines SessionStart-Hooks wird automatisch in den Kontext injiziert.
# Darf nie blockieren oder fehlschlagen: im Zweifel still exit 0.
set -u

# --- Konfiguration (hier pflegen) ------------------------------------------
# Pro-Datei-Limit in Bytes; größere Dateien werden truncated.
MAX_FILE_BYTES=32768
# Gesamt-Budget in Bytes über alle Dateien; danach wird gestoppt.
MAX_TOTAL_BYTES=131072

# Datei-Muster als erweiterte Regex (ERE), gematcht gegen den relativen Pfad.
# PRIMARY (hohes Signal) wird zuerst ausgegeben, README zuletzt — so trifft das
# Gesamt-Budget zuerst die READMEs (niedrigstes Signal), nicht die Rules.
PATTERNS_PRIMARY='(^|/)(CLAUDE|AGENTS|GEMINI)\.md$|(^|/)\.(cursorrules|windsurfrules|clinerules)$|(^|/)\.claude/rules/.+\.md$|(^|/)\.cursor/rules/.+\.mdc$|(^|/)\.github/copilot-instructions\.md$|(^|/)\.github/instructions/.+\.instructions\.md$|(^|/)\.junie/guidelines\.md$'
PATTERNS_LAST='(^|/)README\.md$'

# Root-CLAUDE.md lädt Claude Code teils selbst. Auf true setzen, um nur die
# Top-Level-CLAUDE.md zu überspringen und diese Redundanz zu sparen.
SKIP_ROOT_CLAUDE_MD=false
# ---------------------------------------------------------------------------

input="$(cat 2>/dev/null || true)"

json_field() {
  # $1 = Feldname; jq wenn vorhanden, sonst sed-Heuristik (reicht für einfache Strings).
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null
  else
    printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
  fi
}

# Projekt-Root: Env-Var bevorzugt, dann cwd aus dem Hook-JSON, dann pwd.
root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || root="$(json_field cwd)"
[ -n "$root" ] || root="$(pwd)"
[ -d "$root" ] || exit 0

list_files() {
  # Relative Pfade aller Kandidaten. In Git: nur getrackte Dateien (überspringt
  # node_modules/.gitignore automatisch). Sonst: find mit Exclude-Liste.
  if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$root" ls-files 2>/dev/null || true
  else
    ( cd "$root" 2>/dev/null && find . -type d \( \
        -name .git -o -name node_modules -o -name dist -o -name build \
        -o -name .next -o -name target -o -name vendor -o -name .venv \
        -o -name __pycache__ -o -name .cache \) -prune -o -type f -print 2>/dev/null ) \
      | sed 's|^\./||'
  fi
}

emitted_header=false
total=0
skipped=0

emit_file() {
  local rel="$1" abs size
  abs="$root/$rel"
  [ -f "$abs" ] && [ -r "$abs" ] || return 0
  [ "$SKIP_ROOT_CLAUDE_MD" = true ] && [ "$rel" = "CLAUDE.md" ] && return 0

  if [ "$total" -ge "$MAX_TOTAL_BYTES" ]; then
    skipped=$((skipped + 1))
    return 0
  fi

  size=$(wc -c < "$abs" 2>/dev/null | tr -d ' ')
  [ -n "$size" ] || size=0

  if [ "$emitted_header" = false ]; then
    printf 'load-context: folgende Repo-Dateien sind bereits im Kontext (kein erneutes Lesen nötig).\n'
    emitted_header=true
  fi

  printf '\n===== %s =====\n' "$rel"
  if [ "$size" -gt "$MAX_FILE_BYTES" ]; then
    head -c "$MAX_FILE_BYTES" "$abs" 2>/dev/null || true
    printf '\n…[truncated — Datei > %s Bytes]\n' "$MAX_FILE_BYTES"
    total=$((total + MAX_FILE_BYTES))
  else
    cat "$abs" 2>/dev/null || true
    printf '\n'
    total=$((total + size))
  fi
}

files="$(list_files)"
[ -n "$files" ] || exit 0

# Primär-Dateien (hohes Signal) zuerst, README zuletzt.
while IFS= read -r rel; do
  [ -n "$rel" ] && emit_file "$rel"
done < <(printf '%s\n' "$files" | grep -E "$PATTERNS_PRIMARY" 2>/dev/null || true)

while IFS= read -r rel; do
  [ -n "$rel" ] && emit_file "$rel"
done < <(printf '%s\n' "$files" | grep -E "$PATTERNS_LAST" 2>/dev/null || true)

if [ "$skipped" -gt 0 ]; then
  printf '\n…[load-context: %s weitere Datei(en) wegen Gesamt-Budget (%s Bytes) ausgelassen]\n' "$skipped" "$MAX_TOTAL_BYTES"
fi

exit 0

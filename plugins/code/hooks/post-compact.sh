#!/usr/bin/env sh
# Nach einem Compact erinnert der Hook an den Doku-Sync; der Hauptthread führt agent-docs dann selbst aus.
# Außerhalb eines Repos oder bei sauberem Working Tree gibt es nichts zu syncen — dann bleibt der Hook still.
git rev-parse --verify HEAD >/dev/null 2>&1 || exit 0
if git diff --quiet HEAD 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
  exit 0
fi
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PostCompact","additionalContext":"Der Kontext wurde gerade komprimiert und der Working Tree enthält Änderungen. Führe bei nächster Gelegenheit den Skill agent-docs im Vorschlagsmodus aus (ohne --fix), damit die Agent-Doku zum Code passt. Unterbrich dafür keinen laufenden Schritt."}}
JSON

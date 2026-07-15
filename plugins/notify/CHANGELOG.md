# Changelog — notify

## [0.2.0] – 2026-07-16

### Added

- **Windows-Support:** `scripts/notify.ps1` — Toast via BurntToast (falls installiert) oder
  natives WinRT; `notify.sh` erkennt Git-Bash-Umgebungen und delegiert.
- **Standalone-Modus für andere Harnesses:** `notify.sh --agent "Codex" --message "…"`
  (auch `--title/--subtitle/--sound`, Agent-Name alternativ via `$NOTIFY_AGENT`) — das Script
  ist nicht mehr an Claude-Code-Hook-JSON gebunden.
- macOS: nutzt `terminal-notifier`, falls installiert — Klick fokussiert das Terminal
  (iTerm/Terminal/VS Code/Ghostty/WezTerm), Benachrichtigungen gruppieren pro Projekt.

### Changed

- Anzeige-Layout: Titel = Projektname, Untertitel = Agent + Status (`fertig ✅` / `wartet ⏳`),
  Text = eigentliche Meldung — statt überall nur „Claude Code".
- Hooks rufen das Script explizit via `bash` auf (robust auch ohne Executable-Bit, Git Bash).
- Linux: `notify-send -a <agent>` setzt den App-Namen der Benachrichtigung.

## [0.1.0] – 2026-06-11

### Added

- Hook-Plugin ohne Befehle: Desktop-Benachrichtigung bei `Stop` (Claude ist fertig) und `Notification` (Claude braucht Input/Permission). macOS via osascript (mit Projektname im Titel), Linux via notify-send, sonst still.

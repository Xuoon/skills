---
description: Analyze staged and unstaged changes, propose logical commit splits with house-style messages, then execute the approved plan. Manual-only — invoke via /git-work:commit. Default scope is staged changes if any exist, otherwise all working-tree changes.
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *)
---

# Commit — logisch schneiden, sauber benennen

Macht aus einem Arbeitsstand wohlgeschnittene Commits. Schlägt vor, wartet auf Freigabe, führt dann aus.

**Zuerst lesen:** `${CLAUDE_SKILL_DIR}/../../references/commit-style.md` (Format-, Schnitt- und Tabu-Regeln).

## Workflow

1. **Bestandsaufnahme.** `git status --short`, dann `git diff --staged` und `git diff` getrennt lesen. `git log --oneline -5` für den Ton bestehender Messages (Stil-Konflikte zum Haus-Stil kurz benennen, Haus-Stil gewinnt).
2. **Scope festlegen.** Gibt es Staged-Änderungen → nur diese committen; Unstaged nur erwähnen. Working Tree komplett unstaged → alle Änderungen betrachten. Niemals ungefragt Dinge stagen, die der User bewusst draußen gelassen hat.
3. **Schneiden.** Änderungen in logische Einheiten clustern (Schnitt-Regeln laut commit-style.md). Pro Einheit: betroffene Dateien (hunk-genau via `git add -p` nur wenn eine Datei wirklich zwei Einheiten enthält) + fertige Message.
4. **Plan vorschlagen.** Nummerierte Liste: `#1 <message>` + Dateien. Bei nur einer sinnvollen Einheit: ein Commit, kein künstliches Splitten. **Stop, auf Freigabe warten** — User kann Einheiten mergen, umbenennen, rauswerfen.
5. **Ausführen.** Pro bestätigter Einheit `git add <dateien>` (bzw. die angekündigten `-p`-Schritte) + `git commit -m`. Multi-line Messages über mehrere `-m`-Flags oder Heredoc.
6. **Verify.** `git status --short` (Rest wie angekündigt) + `git log --oneline -<n>` (Commits wie geplant). Abweichung → melden, nicht still reparieren.

## Grenzen

Kein `push`, kein `--amend`, kein `--no-verify`, kein History-Rewrite — außer der User verlangt es ausdrücklich in dieser Session. Schlägt ein Commit-Hook fehl: Fehler zeigen, Fix vorschlagen, nie am Hook vorbei.

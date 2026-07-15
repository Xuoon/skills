---
description: Push the current branch and open a GitHub PR via gh, with a house-style title and a concise description generated from the actual commits. Shows the full plan (base, title, body) for approval before pushing anything. Manual-only — invoke via /git-work:pr.
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git log *) Bash(git diff *) Bash(git branch *) Bash(git merge-base *) Bash(gh pr list *) Bash(gh pr view *) Bash(gh repo view *)
---

# PR — pushen und eröffnen, im Haus-Stil

Aus den tatsächlichen Commits des Branches: Titel + concise Beschreibung, ein Plan, eine Freigabe — dann `git push` + `gh pr create`.

**Zuerst lesen:** `${CLAUDE_SKILL_DIR}/../../references/commit-style.md` (Ton und Format gelten auch für PR-Titel und -Beschreibung).

## Workflow

1. **Branch-Check.** `git status` + aktueller Branch. Auf main/master → Stop, erst Branch vorschlagen. Uncommitted Änderungen → benennen, aber nicht committen (dafür `/git-work:commit`).
2. **Basis bestimmen.** Default-Branch via `gh repo view` (Fallback: main). Commits seit `git merge-base <base> HEAD` lesen — sie sind die einzige Quelle für Titel und Beschreibung. Existiert für den Branch schon ein PR (`gh pr list --head`) → melden und stoppen; PR-Updates sind ein anderer Auftrag.
3. **Entwurf.** Titel im Haus-Stil: imperativ, lowercase, ≤ 60 Zeichen, `type:`-Präfix nur wenn der Branch genau eine Sache tut. Beschreibung nach dem Format aus `${CLAUDE_SKILL_DIR}/../../CLAUDE.md`: oben Was/Warum, `---`, technischer Changelog, `---`, „Manuelle Schritte" nur wenn nötig; kein Diff-Nacherzählen, keine Verifikations-/Test-Plan-Boilerplate, keine Emojis.
4. **Plan zeigen.** `<base> ← <head>`, Titel, Beschreibung, draft ja/nein (Default: nein). **Stop, auf Freigabe warten.**
5. **Ausführen.** `git push -u origin <branch>`, dann `gh pr create` mit bestätigtem Titel/Body. PR-URL ausgeben.
6. **Verify.** `gh pr view` — Titel und Base wie geplant; Abweichung melden, nicht still reparieren.

## Grenzen

Kein force-push, kein Push auf main/master, kein Merge/Auto-Merge, keine Reviewer/Labels ohne Auftrag. Schlägt ein Push-Hook fehl: Fehler zeigen, nie `--no-verify`.

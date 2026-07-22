---
name: ship
description: Arbeit abschließen — committen, PR auf main im Hausformat, optional direkt mergen; mit Public-Repo-Check vorab. `--mergen` mergt zusätzlich, `--nur-commit` lässt den PR weg.
argument-hint: "[--nur-commit | --mergen] [hinweise]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git branch *) Bash(git remote *) Bash(gh repo view *) Bash(gh pr list *) Bash(gh pr view *)
---

# ship — commit → PR → (mergen)

Schließt die aktuelle Arbeit ab: ein sauberer Commit, ein PR auf `main` im Hausformat, auf Wunsch direkt gemergt. Schreibende Schritte (commit/push/PR/merge) laufen **erst nach deiner Bestätigung am Freigabe-Gate** — dort greift auch der Public-Repo-Check.

## Argumente (`$ARGUMENTS`)

Alle optional, Reihenfolge egal:

| Flag | Bedeutung |
| --- | --- |
| *(ohne Flag)* | committen + PR (nur einen anlegen, falls noch keiner offen ist) — **kein** Merge |
| `--mergen` | zusätzlich zum PR direkt mergen |
| `--nur-commit` | nur committen (aktueller Branch), **kein** PR |
| Freitext | Hinweise für Commit-Message / PR-Beschreibung |

## Ablauf

1. **Recon (read-only).** `git status --short`, `git diff` (staged + unstaged), aktueller Branch + Default-Branch, `git log` (letzte Commits für Message-Stil), `git remote -v`. Offenen PR für den Branch prüfen: `gh pr list --head <branch> --state open`. Sichtbarkeit bestimmen: `gh repo view --json visibility,nameWithOwner` — schlägt das fehl oder bleibt unklar, **als öffentlich behandeln**.

2. **Public-Repo-Guard.** Ist das Repo öffentlich (oder unbekannt), den Diff auf Sensibles prüfen: Secrets/Keys/Tokens, `.env`-Werte, interne URLs/Hosts, personenbezogene Daten, versehentlich eingecheckte Build-/Log-Artefakte. Fund → **prominent melden und stoppen**, nicht selbst „wegcommitten". Sauber → in einem Satz bestätigen, dass der Inhalt öffentlich wird.

3. **Plan.**
   - Branch: Ein PR braucht einen Feature-Branch. Steht HEAD auf dem Default-Branch, einen Branch vorschlagen (`typ/kurz-beschreibung`); auf einem Feature-Branch diesen nutzen. Bei `--nur-commit` bleibt alles auf dem aktuellen Branch.
   - Commit-Message im Stil der letzten Commits (Sprache, Präfix-Konvention), Betreff prägnant. Mehrere logische Commits nur, wenn der Diff das klar trägt.
   - PR-Beschreibung im **Hausformat** (unten). Ist bereits ein PR offen, wird kein zweiter angelegt — der Push aktualisiert ihn; PR-Body auf Wunsch aktualisieren.

4. **Freigabe-Gate.** Zeigen: Dateien, Branch-Plan, Commit-Message(s), Guard-Ergebnis (öffentlich?), PR-Titel + -Body (bzw. „PR #N schon offen"), ob gemergt wird. **Stop, auf Freigabe warten.** Nur Bestätigtes ausführen.

5. **Ausführen.** Branch (falls nötig) → commit → push. Kein offener PR und kein `--nur-commit` → `gh pr create`; offener PR → nur pushen (aktualisiert ihn). Bei `--mergen`: nach erfolgreichem PR `gh pr merge`. Die Commit-Message endet mit dem `Co-Authored-By:`-Trailer laut Harness-Konvention; der PR-Body mit der „Generated with Claude Code"-Zeile.

6. **Bericht.** PR-URL, Commit-SHA(s), Merge-Status. Bei Konflikten/Fehlern: Ursache + nächster Schritt, nichts still schlucken.

## PR-Hausformat

- **Oben:** kurzer Fließtext oder Punkte — was umgesetzt wurde und warum.
- Danach mit `---` abgetrennt: technischer Changelog (was alles angepasst wurde).
- **Kein** „Verifikation"-Block o. Ä.
- Ganz unten, mit `---` abgetrennt: „Manuelle Schritte" — **nur** wenn nach dem Merge wirklich etwas manuell zu tun ist; sonst weglassen.

## Grenzen

Keine `--force`-Pushes, kein Rebase/History-Rewrite ohne ausdrücklichen Wunsch. Bei unklarem Branch-Zustand oder Konflikten fragen statt raten. `ship` erfindet keine Änderungen — es committet nur, was da ist.

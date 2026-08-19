---
name: ship
description: Arbeit abschließen — committen, PR auf den Default-Branch, auf Wunsch mergen und aufräumen.
argument-hint: "[--merge] [--clean] [hinweise]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git branch --show-current) Bash(git branch --merged *) Bash(git worktree list*) Bash(git tag --list*) Bash(git remote -v) Bash(gh repo view *) Bash(gh pr list *) Bash(gh pr view *)
---

# ship — commit → PR → (merge, aufräumen)

Schließt die aktuelle Arbeit ab. Alles Schreibende — commit, push, PR, merge, löschen — läuft **erst nach der Freigabe am Gate**.

## Argumente (`$ARGUMENTS`)

| Flag | Bedeutung |
| --- | --- |
| *(ohne Flag)* | Committen + PR anlegen, falls für den Branch noch keiner offen ist. **Kein Merge** |
| `--merge` | Zusätzlich mergen, danach auf den Default-Branch wechseln und pullen |
| `--clean` | **Allein: nur aufräumen, nichts committen.** Mit `--merge`: direkt nach dem Merge aufräumen |
| Freitext | Hinweise für Commit-Message und PR-Beschreibung |

Scope ist immer das aktuelle Verzeichnis.

## Ablauf

1. **Recon, read-only.** `git status --short`, `git diff` staged und unstaged, aktueller Branch, Default-Branch, `git log` für den Commit-Stil des Repos, `git remote -v`, offener PR via `gh pr list --head <branch> --state open`. Sichtbarkeit über `gh repo view --json visibility,nameWithOwner` — schlägt das fehl oder bleibt unklar, **als öffentlich behandeln**.

2. **Öffentlich-Check.** Bei öffentlichem oder unklarem Repo den Diff prüfen auf: Secrets, Keys, Tokens, `.env`-Werte, interne URLs und Hosts, personenbezogene Daten, versehentliche Build-/Log-Artefakte. Fund → melden und **stoppen**, nicht selbst wegcommitten. Sauber → in einem Satz bestätigen, dass der Inhalt öffentlich wird.

3. **Doku-Abgleich, nur melden.** Passt `CHANGELOG.md` oder README nicht zum Diff, das am Gate in einem Satz sagen. **ship pflegt sie nicht selbst und ruft keine anderen Skills auf** — das entscheidet der Nutzer.

4. **Freigabe-Gate.** Zeigen: Dateien, Branch-Plan, Commit-Message(s), Ergebnis des Öffentlich-Checks, PR-Titel und -Body, was gemergt und was aufgeräumt wird. **Stop, auf Freigabe warten.** Nur Bestätigtes ausführen.

5. **Ausführen** in dieser Reihenfolge, dann durchziehen ohne weitere Zwischenfragen:

   Branch anlegen (nur wenn HEAD auf dem Default-Branch steht, Name `typ/kurz-beschreibung`) → commit → push → `gh pr create`, nur wenn kein PR offen ist; sonst aktualisiert der Push den bestehenden → bei `--merge`: `gh pr merge` → Wechsel auf den Default-Branch + `git pull` → bei `--clean`: aufräumen. Der Wechsel kommt **vor** dem Aufräumen, weil der Branch, auf dem man steht, nicht löschbar ist.

6. **Bericht.** PR-URL, Commit-SHAs, Merge-Status, was aufgeräumt wurde. Fehler mit Ursache und nächstem Schritt, nichts still schlucken.

Bei `--clean` allein gibt es keinen Diff: Schritt 2 und 3 entfallen, und das Gate zeigt nur, was gelöscht wird.

## Aufräumen (`--clean`)

Gelöscht wird nur, was **nachweislich** gemergt oder verwaist ist:

- Branches, die im Default-Branch enthalten sind (`git branch --merged <default>`) — lokal und, wenn dort vorhanden, remote.
- Worktrees, deren Branch weg ist oder deren Verzeichnis nicht mehr existiert (`git worktree list`, dann `git worktree prune`).
- Tags, die auf nichts Erreichbares mehr zeigen.

**Nie** der aktuelle Branch, **nie** der Default-Branch, **nie** ungemergte Arbeit ohne Rückfrage. Ist der Zustand eines Branches unklar, geht er als Frage an den Nutzer statt in die Löschliste.

## Commit- und PR-Format

Verbindlich ist Svens globale `~/.claude/CLAUDE.md`, Abschnitt „Pull request descriptions" — Aufbau, Sektionen und Ton stehen dort und werden hier **nicht** wiederholt. ship ergänzt nur:

- Conventional Commits mit deutschem Betreff, im Stil der letzten Commits des Repos.
- Commit-Message endet mit dem `Co-Authored-By:`-Trailer laut Harness-Konvention.
- PR-Body endet mit der „Generated with Claude Code"-Zeile.

Widerspricht eine Repo-Konvention (PR-Template, Changelog-Pflicht, Sprache) der globalen Vorgabe, hat das Repo Vorrang.

## Grenzen

Kein `--force`-Push, kein Rebase und kein History-Rewrite ohne ausdrücklichen Wunsch. Bei unklarem Branch-Zustand oder Konflikten fragen statt raten. ship erfindet keine Änderungen — es committet nur, was da ist.

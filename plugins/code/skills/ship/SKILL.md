---
name: ship
description: Nur bei ausdrücklichem Nutzerwunsch Arbeit abschließen — committen, PR anlegen, auf Wunsch mergen und aufräumen.
compatibility: Benötigt Git, ein Remote und authentifizierten Schreibzugriff auf dessen Forge.
argument-hint: "[--merge] [--clean] [hinweise]"
---

# ship — commit → PR → (merge, aufräumen)

Schließt die aktuelle Arbeit ab. Alles Schreibende — commit, push, PR, merge, löschen — läuft **erst nach der Freigabe am Gate**.

Voraussetzung sind `git`, ein Remote und authentifizierter Schreibzugriff auf dessen Forge. Eine vorhandene Forge-API oder Integration ist bevorzugt; bei GitHub ist ein authentifiziertes `gh` der CLI-Fallback.

## Argumente aus der Nutzeranfrage

| Flag | Bedeutung |
| --- | --- |
| *(ohne Flag)* | Committen + PR anlegen, falls für den Branch noch keiner offen ist. **Kein Merge** |
| `--merge` | Zusätzlich mergen, danach auf den Default-Branch wechseln und pullen |
| `--clean` | **Allein: nur aufräumen, nichts committen.** Mit `--merge`: direkt nach dem Merge aufräumen |
| Freitext | Hinweise für Commit-Message und PR-Beschreibung |

Scope ist immer das aktuelle Verzeichnis.

## Ablauf

1. **Recon, read-only.** `git status --short`, staged und unstaged Diff, aktueller Branch, Default-Branch, Commit-Stil und Remotes prüfen. Offenen PR und Sichtbarkeit über die verfügbare Forge-Integration ermitteln; bei GitHub ohne Integration `gh pr list` und `gh repo view` verwenden. Bleibt die Sichtbarkeit unklar, **als öffentlich behandeln**.

2. **Öffentlich-Check.** Bei öffentlichem oder unklarem Repo den Diff prüfen auf: Secrets, Keys, Tokens, `.env`-Werte, interne URLs und Hosts, personenbezogene Daten, versehentliche Build-/Log-Artefakte. Fund → melden und **stoppen**, nicht selbst wegcommitten. Sauber → in einem Satz bestätigen, dass der Inhalt öffentlich wird.

3. **Doku-Abgleich, nur melden.** Passt `CHANGELOG.md` oder README nicht zum Diff, das am Gate in einem Satz sagen. **ship pflegt sie nicht selbst und ruft keine anderen Skills auf** — das entscheidet der Nutzer.

4. **Freigabe-Gate.** Zeigen: Dateien, Branch-Plan, Commit-Message(s), Ergebnis des Öffentlich-Checks, PR-Titel und -Body, was gemergt und was aufgeräumt wird. **Stop, auf Freigabe warten.** Nur Bestätigtes ausführen.

5. **Ausführen** in dieser Reihenfolge, dann durchziehen ohne weitere Zwischenfragen:

   Branch anlegen, wenn HEAD auf dem Default-Branch steht: zuerst die Repo-Konvention verwenden, ohne Vorgabe `typ/kurz-beschreibung`. Dann commit → push → PR über die verfügbare Forge-Integration anlegen, nur wenn keiner offen ist; sonst aktualisiert der Push den bestehenden → bei `--merge` über dieselbe Forge mergen → Default-Branch aktualisieren → bei `--clean` aufräumen. Bei GitHub ohne Integration sind `gh pr create` und `gh pr merge` der Fallback.

   Läuft ship in einem Worktree, ist der Default-Branch oft schon im Hauptrepo ausgecheckt. Dort nicht wechseln, sondern `git -C <hauptrepo> pull --ff-only` benutzen und den Merge-Status über die Forge prüfen statt über den lokalen Checkout.

6. **Bericht.** PR-URL, Commit-SHAs, Merge-Status, was aufgeräumt wurde. Fehler mit Ursache und nächstem Schritt, nichts still schlucken.

Bei `--clean` allein gibt es keinen Diff: Schritt 2 und 3 entfallen, und das Gate zeigt nur, was gelöscht wird.

## Aufräumen (`--clean`)

Gelöscht wird nur, was **nachweislich** gemergt oder verwaist ist:

- Branches, deren Arbeit im Default-Branch angekommen ist — lokal und, wenn dort vorhanden, remote. `git branch --merged <default>` allein reicht nach einem Squash-Merge nicht; deshalb zusätzlich den gemergten PR über die Forge belegen. Nur mit diesem Nachweis darf `git branch -D` sein.
- Worktrees, deren Branch weg ist oder deren Verzeichnis nicht mehr existiert (`git worktree list`, dann `git worktree prune`).
**Nie** der aktuelle Branch, **nie** der Default-Branch, **nie** ungemergte Arbeit ohne Rückfrage. Ist der Zustand eines Branches unklar, geht er als Frage an den Nutzer statt in die Löschliste.

## Commit- und PR-Format

- **Commit und PR-Titel:** Conventional Commit mit deutschem Betreff, im Stil der letzten Commits des Repos.
- **Kopf ohne Überschrift:** 2–4 Sätze oder Punkte zu Umsetzung und Anlass, keine Diff-Nacherzählung.
- **`## Changelog`:** Jeder Punkt beginnt mit einem fetten Anker, Gedankenstrich und einem Satz (`**fix(rmm): Neustart-Gate** — …`). Mehr als zwei Einzeländerungen werden Unterpunkte; maximal zwei Ebenen. Bezeichner, Pfade und Befehle stehen in Backticks. Keine Tabellen, Klappblöcke oder Checkboxen.
- **`## Prüfung`:** Nur Evidenz, die nicht aus dem Diff folgt, etwa Geräteprüfung, reproduzierter Fehler oder geprobte Migration. Bewusst Ungeprüftes gehört ebenfalls hierher; kein „Tests grün“ und kein CI-Status.
- **`## Manuelle Schritte`:** Nur wenn nach dem Merge wirklich etwas zu tun ist; nummeriert in Ausführungsreihenfolge mit exakten Befehlen.
- Abschnitte ohne echten Inhalt entfallen vollständig; nie „keine“ schreiben.
- Widerspricht eine Repo-Konvention (PR-Template, Changelog-Pflicht, Sprache) diesen Vorgaben, hat das Repo Vorrang.

## Grenzen

Kein `--force`-Push, kein Rebase und kein History-Rewrite ohne ausdrücklichen Wunsch. Bei unklarem Branch-Zustand oder Konflikten fragen statt raten. ship erfindet keine Änderungen — es committet nur, was da ist.

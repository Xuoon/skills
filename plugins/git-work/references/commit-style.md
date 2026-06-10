# Commit-Stil (Haus-Stil)

Genutzt von `/git-work:commit` (Messages) und `/git-work:changelog` (Clustering). Weniger ist mehr: übersichtlich, concise, clean.

## Format

```
<type>: <summary>

<body — nur wenn nötig>
```

- **Sprache:** Englisch.
- **type:** `feat` `fix` `refactor` `perf` `docs` `test` `build` `ci` `chore`. Kein anderer.
- **Scope:** nur im Monorepo und nur wenn es Klarheit bringt: `feat(admin): …` — Package-/Workspace-Name, nichts Erfundenes.
- **summary:** Imperativ, lowercase, ≤ 60 Zeichen, kein Punkt am Ende. Sagt *was sich ändert*, nicht *was getan wurde* ("add retry to webhook delivery", nicht "added retries").
- **body:** Nur wenn das *Warum* aus Summary + Diff nicht offensichtlich ist. Maximal 3 Zeilen Prosa. Keine Bullet-Listen außer bei echten Mehrfach-Punkten. Kein "This commit…", keine Emojis, kein Diff-Nacherzählen.
- **Breaking Change:** `!` nach dem type (`feat!: …`) + eine Body-Zeile, die das Breaking benennt.

## Schnitt-Regeln

- **Ein Commit = eine logische Änderung.** Refactor und Feature trennen; Formatierungs-Rauschen vom Inhalt trennen.
- Abhängige Commits in Reihenfolge (erst die Basis, dann der Nutzer der Basis).
- Lockfile-/Generated-Änderungen gehören zum verursachenden Commit, nicht in einen eigenen.

## Tabu

- `git push`, `git commit --amend`, `--no-verify`, History-Rewrites — nie ohne expliziten User-Auftrag.
- Co-Authored-By/Generated-with-Trailer nur, wenn das Repo das bereits so macht.

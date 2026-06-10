# git-work

Git-Workflow im Haus-Stil (siehe `references/commit-style.md`): weniger ist mehr, übersichtlich, concise, clean.

| Befehl | Zweck |
| --- | --- |
| `/git-work:commit` | Staged/Unstaged analysieren, logische Commit-Splits + Messages vorschlagen, nach Freigabe committen |
| `/git-work:changelog [ref] [version] [pfad]` | CHANGELOG-Sektion aus Commits seit letztem Tag (oder `ref`), Keep-a-Changelog-light, Semver-Vorschlag |

Beide Skills sind manual-only (`disable-model-invocation`). Tabu ohne expliziten Auftrag: push, amend, `--no-verify`, History-Rewrites.

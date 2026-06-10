---
description: Generate a concise CHANGELOG entry from commits since the last tag (or a given ref), clustered Keep-a-Changelog-style, with a semver version suggestion. Manual-only — invoke via /git-work:changelog. Optional args — ref, version, target path.
argument-hint: "[ref] [version] [pfad]"
disable-model-invocation: true
allowed-tools: Bash(git log *) Bash(git describe *) Bash(git tag *) Bash(git diff *) Bash(git status *)
---

# Changelog — aus Commits, nicht aus Erinnerung

Schreibt den nächsten CHANGELOG-Abschnitt aus der tatsächlichen Commit-Historie. Concise: ein Satz pro Eintrag, User-Wirkung statt Commit-Wortlaut.

**Zuerst lesen:** `${CLAUDE_SKILL_DIR}/../../references/commit-style.md` (die types steuern das Clustering).

## Argumente

`$ARGUMENTS` — alle optional, frei kombinierbar, Claude interpretiert: Token existiert als Pfad → Ziel-Ordner der CHANGELOG.md (z. B. ein Plugin-/Package-Ordner im Monorepo; dann auch `git log -- <pfad>` filtern). Token matcht `v?X.Y.Z` → gewünschte Version. Sonst → Ref/Tag als Startpunkt.

## Workflow

1. **Range bestimmen.** Ref-Argument, sonst `git describe --tags --abbrev=0` als letzter Tag. Kein Tag vorhanden → gesamten Log nehmen und das explizit sagen. Dann `git log <ref>..HEAD --oneline` (ggf. `-- <pfad>`).
2. **Clustern.** Nach Wirkung gruppieren: **Added** (feat) / **Changed** (refactor, perf, Verhaltensänderungen) / **Fixed** (fix) / **Removed** / **Breaking** (`!`-Commits, immer zuoberst). Rauschen fliegt: chore, ci, Merge-Commits, reine Lockfile-Bumps — außer sie haben User-Wirkung.
3. **Version vorschlagen.** Argument gewinnt; sonst Semver-Logik aus dem Cluster: Breaking → major, feat → minor, sonst patch. Aktuelle Version aus letztem Tag bzw. Manifest (`package.json`, `plugin.json`) ableiten.
4. **Ziel-Datei.** `CHANGELOG.md` im Pfad-Argument, sonst Repo-Root. Fehlt sie → als `**Create:**` mit Kopfzeile vorschlagen.
5. **Entwurf zeigen.** Neue Sektion `## [X.Y.Z] – YYYY-MM-DD` zuoberst, als Diff. Einträge umformulieren statt Commit-Messages kopieren: was merkt der Nutzer/Agent davon. **Stop, auf Freigabe warten.**
6. **Apply + Verify.** Nur Bestätigtes einfügen; Markdown-Struktur intakt (genau eine neue Sektion, Reihenfolge absteigend). Hinweis geben, falls Manifest-Version (`plugin.json`/`package.json`) noch nicht zur neuen Sektion passt — aber nicht ungefragt mit-editieren.

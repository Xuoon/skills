---
description: Repo-lokale Skills/Commands prüfen — Standard nur analysieren (löschen/hochziehen/behalten), mit --anwenden die Löschungen direkt ausführen. Für den Umstieg von repo-lokalen Skills auf feste Plugins.
argument-hint: "[--anwenden]"
disable-model-invocation: true
allowed-tools: Bash(git ls-files *) Bash(find *) Bash(ls *) Bash(cat *) Grep Glob Read
---

# cleanup:skills — repo-lokale Skills aufräumen

Prüft die im Repo liegenden Skills/Commands und sortiert jeden in: **löschen** (ein Plugin oder Built-in deckt das schon ab), **hochziehen** (gehört als Plugin in den Marketplace), **behalten** (wirklich projektspezifisch). Ziel: repo-lokale Skills loswerden, wo ein fester Plugin-Weg existiert — delete-first. **Standard: nur analysieren.** Mit `--anwenden` werden die als „löschen" bestätigten Skills direkt entfernt.

## Argumente (`$ARGUMENTS`)

| Flag | Bedeutung |
| --- | --- |
| *(ohne Flag)* | Nur analysieren + Urteil je Skill, **kein Edit** |
| `--anwenden` | Vorschlag zeigen **und** die „löschen"-Kandidaten direkt entfernen + verifizieren |

Scope ist immer das aktuelle Verzeichnis. Einen Subtree bei Bedarf im **Fließtext** nennen.

## Ablauf

1. **Inventar.** Lokale Skills/Commands finden: `.claude/skills/**/SKILL.md`, `.claude/commands/**`, `commands/**`. Je Fund: Zweck in einem Satz (aus Frontmatter-`description` + Body).

2. **Verfügbares erheben.** Installierte Plugins/Skills und Built-ins sammeln, gegen die verglichen wird: Marketplace-Katalog(e) und Plugin-Config unter `~/.claude/plugins/` bzw. die im Kontext gelisteten verfügbaren Skills. So wird „deckt schon ab" belegbar statt geraten.

3. **Klassifizieren.** Pro lokalem Skill ein Urteil mit Evidence:
   - **löschen** — welches Plugin/Built-in überlappt und warum redundant.
   - **hochziehen** — warum projektübergreifend nützlich; grobe Ziel-Form im Marketplace.
   - **behalten** — was den Skill an dieses Repo bindet (eigene Pfade/Domäne).

4. **Vorschlag.** Delete-first, je Skill ein Urteil + Evidence. Bei „löschen": bestätigen, dass das abdeckende Plugin wirklich installiert/verfügbar ist. „Hochziehen" ist ein **Folge-Vorschlag** (Plugin anlegen), nie Teil dieses Laufs. **Ohne `--anwenden` endet der Lauf hier.**

5. **Anwenden + Verify (nur mit `--anwenden`).** Nur die „löschen"-Kandidaten entfernen. Danach Rest-Erwähnungen der gelöschten Skills greppen (`settings.json`, Doku) → 0 Reste. Hochzieh-Kandidaten als Plan übergeben.

## Grenzen

Read-only-Analyse; Löschungen nur mit `--anwenden` und nur lokal. Keine Plugins bauen, keine Änderungen unter `~/.claude`. Nichts löschen, was nicht klar abgedeckt ist — unklar → behalten und benennen.

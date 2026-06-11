---
description: Update every dependency across all package.json files (workspace-aware) to the latest official stable release, bun-first. Shows a full from→to plan with breaking-change notes for majors before touching anything. Manual-only — invoke via /deps:bump. Optional args — package name(s), `minor` (hold back majors).
argument-hint: "[paket] [minor]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(bun outdated *) Bash(cat *) Bash(find *)
---

# Bump — alles auf die letzte offizielle Version

Edge-Living mit Sicherheitsnetz: ein Lauf, ein Plan, eine Freigabe — dann sind alle Dependencies auf dem letzten **stabilen** Release.

## Argumente

`$ARGUMENTS` — alle optional, frei kombinierbar: `minor` → Majors nur auflisten, nicht updaten. Sonst → Paketname(n), nur diese bumpen.

## Was "latest" heißt

Der `latest`-Dist-Tag der Registry = letztes offizielles stabiles Release. **Keine** Pre-Releases (alpha/beta/rc/canary/next/nightly) — einzige Ausnahme: die installierte Version ist bereits eine Pre-Release derselben Linie, dann auf deren neuesten Stand.

## Workflow

1. **Manifeste finden.** Root-`package.json` lesen (`workspaces`-Feld!), alle package.json sammeln (node_modules & Build-Output excludieren). Lockfile-Typ feststellen — erwartet wird bun (`bun.lock`/`bun.lockb`); anderes Lockfile → benennen und fragen statt raten.
2. **Outdated-Discovery.** Bevorzugt `bun outdated` (im Root; bei Workspaces zusätzlich `--filter '*'` bzw. je Workspace-Verzeichnis). Liefert das Tool nichts Brauchbares → Fallback: aktuelle Versionen aus dem Lockfile + `latest` je Paket via Registry abfragen.
3. **Plan bauen.** Eine Tabelle: Paket · von → zu · major? · betroffene Manifeste. Für jeden **Major**: Release Notes/Changelog kurz prüfen (WebFetch) und das Risiko in **einer** Zeile benennen ("v9: config format changed", "drops node <20"). Nicht pro Minor recherchieren — nur Majors. Bei `minor`-Flag: Majors in eine separate "zurückgehalten"-Liste.
4. **Approval-Gate.** Plan zeigen, **Stop, auf Freigabe warten.** User kann einzelne Pakete rauswerfen ("alles außer #4").
5. **Apply.** Versionsbereiche direkt in den package.json editieren — **Range-Stil pro Eintrag erhalten** (`^` bleibt `^`, `~` bleibt `~`, exakt bleibt exakt; `latest`/`workspace:`/`catalog:`/`git:`-Specifier nie anfassen, nur melden). Danach einmal `bun install`.
6. **Verify.** Install fehlerfrei, dann vorhandene Scripts aus package.json in dieser Reihenfolge, soweit definiert: typecheck → build → test. Schlägt etwas fehl → verursachendes Paket identifizieren (Fehlermeldung, notfalls bisecten), dessen Bump zurückdrehen, erneut verifizieren, im Abschlussbericht als "blockiert: <paket> <grund>" listen.
7. **Bericht.** Gebumpt / zurückgehalten (`minor`) / blockiert / übersprungene Specifier — plus Hinweis, welche Majors der User manuell nacharbeiten wollte.

## Grenzen

Kein `git commit` (dafür `/git-work:commit`), keine Engine-/Runtime-Felder ändern, keine peerDependency-Konflikte "wegforcen" (`--force`/Resolutions nur auf expliziten Wunsch, als eigener Vorschlag).

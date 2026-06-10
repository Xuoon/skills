---
description: Find and remove dead code in one pass — unused files, exports, dependencies, env vars and stale feature flags. Scans (knip-first for JS/TS, grep heuristics otherwise), verifies every candidate against dynamic usage, lists findings grouped with confidence, then purges only what the user approves. Manual-only — invoke via /dead-code. Optional arg — subtree path.
argument-hint: "[pfad]"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(grep *) Bash(rg *) Bash(find *) Bash(cat *)
---

# Dead Code — finden, belegen, löschen

Ein Befehl, ein Durchlauf: scannen → verifizieren → auflisten → Freigabe → purgen → beweisen, dass nichts kaputt ist. Die Demut zuerst: **jeder Dead-Code-Detektor lügt manchmal.** Deshalb ist der Verifikations-Pass Pflicht und "unsicher" wird niemals gelöscht.

## Argumente

`$ARGUMENTS` — optional: existiert das Token als Pfad → nur diesen Subtree scannen (Referenzen von außerhalb in den Subtree zählen trotzdem als Nutzung).

## Workflow

1. **Ökosystem erkennen.** package.json vorhanden → JS/TS-Pfad (bun erwartet). Sonst generischer Grep-Pfad. Generierte Verzeichnisse immer excludieren (node_modules, dist, build, .next, coverage, Codegen-Output laut Config).
2. **Tool-Pass (JS/TS).** `bunx knip --reporter json` versuchen (ohne Config läuft knip mit Auto-Detection; bei Monorepos im Root). Schlägt knip fehl oder passt nicht → sauber auf den manuellen Pass ausweichen und das sagen — nicht an der Tool-Config verkünsteln.
3. **Manueller Pass (immer, ergänzend).** Kandidaten, die Tools schlecht sehen:
   - **Env-Variablen:** definiert in `.env*`, compose, CI — aber nirgends gelesen (`process.env.X`, `import.meta.env.X`, `Bun.env.X`).
   - **Feature-Flags:** Flag-Definitionen, deren Auswertung nur noch einen Zweig hat oder die nirgends mehr abgefragt werden.
   - **Dateien ohne eingehende Imports** außerhalb von Entry-Points/Konventionspfaden (routes/pages/app, CLI-bins, Worker, Migrations).
   - **Dependencies** in package.json ohne Import/Require/Config-Nutzung (Plugins in Tool-Configs zählen als Nutzung!).
4. **Verifikations-Pass (Pflicht, pro Kandidat).** Gegen dynamische Nutzung prüfen: String-Referenzen auf den Namen (Reflection, `import()`-Pfade, Template-Strings), package.json `exports`/`main`/`bin` (public API einer Library!), Nutzung in CI/Dockerfiles/Scripts, Re-Export-Ketten, Test-Fixtures. Ergebnis je Kandidat: **sicher** (keinerlei Referenz, kein public-API-Pfad) / **wahrscheinlich** (nur tote oder zirkuläre Referenzen) / **unsicher** (dynamische Muster im Spiel) — Evidence mit `pfad:zeile`.
5. **Report + Freigabe.** Gruppiert (Dateien / Exporte / Dependencies / Env-Vars / Flags), nummeriert, je Eintrag: Fundort, Begründung, Confidence. "Unsicher" steht dabei, ist aber **nicht löschbar markiert**. **Stop, auf Freigabe warten** — User wählt per Nummern ("alles", "1–4, 7", "alles außer deps").
6. **Purge.** Nur Bestätigtes: Dateien löschen, Exporte entfernen (samt nun toter lokaler Helfer), Dependencies aus package.json + `bun install`, Env-Zeilen raus. Flag-Purge heißt: Auswertung auf den verbleibenden Zweig vereinfachen, nicht nur die Definition löschen.
7. **Verify.** Verfügbare Scripts in Reihenfolge: typecheck → build → test. Fehler → verursachende Löschung zurückdrehen, erneut verifizieren, im Abschlussbericht als "zurückgerollt: <eintrag> <grund>" listen. Abschluss: gelöscht / zurückgerollt / bewusst behalten (unsicher).

## Grenzen

Niemals "unsicher" löschen. Niemals public-API-Exporte (package.json `exports`) ohne expliziten Extra-Hinweis im Report. Kein `git commit` (dafür `/git-work:commit`) — die Löschungen bleiben als Working-Tree-Änderung sichtbar und revertierbar.

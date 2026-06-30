---
description: Read-only dependency health report — known CVEs (bun/npm audit), end-of-life runtimes and major versions (endoflife.date), plus a license summary. Never changes anything; fixes go through /deps:bump. Manual-only — invoke via /deps:health.
disable-model-invocation: true
allowed-tools: Bash(bun audit *) Bash(bun pm *) Bash(npm audit *) Bash(cat *) Bash(find *) Bash(git status *) WebFetch
---

# Health Check — CVEs, EOL, Lizenzen (nur Report)

Reiner Lese-Befehl: ein Bericht, keine Edits. Jede Empfehlung verweist auf `/deps:bump` oder einen manuellen Schritt — angewendet wird hier nichts.

## Workflow

1. **Manifeste + Lockfile.** Root-`package.json` lesen (`workspaces`-Feld!), alle package.json sammeln (node_modules & Build-Output excludieren). Lockfile-Typ feststellen — erwartet wird bun.
2. **CVE-Scan.** `bun audit` (bei Workspaces im Root). Liefert das nichts Brauchbares → `npm audit --json` als Fallback; geht beides nicht → direkte Dependencies gegen die OSV-API prüfen (WebFetch) und das sagen.
3. **EOL-Check.** Runtime (node/bun laut `engines`/`.nvmrc`/CI) und die großen Frameworks unter den direkten Dependencies (die Top-Handvoll, nicht alles) gegen `https://endoflife.date/api/<produkt>.json` prüfen. Nur melden, was EOL ist oder es in ~6 Monaten wird.
4. **Lizenz-Kurzcheck.** Lizenzen der direkten Dependencies einsammeln (package.json der installierten Pakete). Geflaggt werden: Copyleft (GPL/AGPL/SSPL), unbekannt/fehlend. Permissive (MIT/Apache/BSD/ISC) nur als Summenzeile.
5. **Report.** Drei Gruppen, je Fund eine Zeile:
   - **CVEs** (nach Severity absteigend): Paket · installiert · gefixt ab · ein Satz Impact. Transitive-only-Findings als solche kennzeichnen (oft reicht ein Lockfile-Refresh).
   - **EOL**: was · EOL seit/ab · Upgrade-Ziel.
   - **Lizenzen**: nur die Flags.

   Abschluss: empfohlene nächste Schritte — typisch `/deps:bump <paket>` für gepatchte Versionen; Majors als bewusste Einzelentscheidung markieren.

## Grenzen

Keine Edits, kein `bun install`, kein Fix-Apply — read-only. Severity der Quelle übernehmen, nicht dramatisieren. Keine Findings erfinden: kein Treffer → "sauber" sagen und fertig.

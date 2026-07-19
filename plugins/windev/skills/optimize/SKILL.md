---
description: Bestehende PowerShell-/Terminal-Umgebung ausführlich vermessen (Startzeit, Prompt-Segmente, Profil, PATH, Module, Editor) und nur nach Freigabe bereinigen — mit Backups vor jeder Änderung.
disable-model-invocation: true
---

# windev:optimize — Umgebung analysieren & bereinigen

Erst vollständig messen, dann berichten, dann fragen, dann umsetzen. Der Zielzustand samt Warum steht in `${CLAUDE_SKILL_DIR}/../../references/best-practice.md` — zuerst lesen.

**Grundprinzip: Die Analyse ist read-only; jede Änderung braucht eine explizite Freigabe via AskUserQuestion und ein datiertes Backup.** Jede Empfehlung nennt ihren Messwert — ohne Zahl keine Behauptung. Ehrlich einordnen, was wenig bringt (PATH-Bereinigung ist Hygiene, kein Speed).

## Phase 1 — Vollanalyse (read-only)

```
pwsh -NoProfile -File "$CLAUDE_PLUGIN_ROOT/scripts/measure-environment.ps1"
```

Kann der Bericht die aktive OMP-Konfiguration nicht aus `POSH_CONFIG` oder einem literalen `--config`-Profilpfad ermitteln, den Pfad beim Lesen der Profile auflösen und die Inventur mit `-OhMyPoshConfig <pfad>` wiederholen. Danach gezielt vertiefen — der Bericht zeigt, wo:

1. **Startzeit**: Differenz mit/ohne Profil = Profilkosten. Je 2–3× messen; Systemlast verzerrt Einzelwerte.
2. **Prompt**: Segmente über ~100 ms sind die Täter (typisch: Sprachversions-Segmente wie `node`, Git-Status). Zum Vergleich rohes `git status` im selben Repo messen — schneller als das kann kein Prompt-Segment sein.
3. **Profile lesen** (alle vier `$PROFILE`-Pfade + WindowsPowerShell): Risikomuster sind Remote-Code-Ausführung (`irm | iex`), Funktionen, die das Profil selbst aus dem Netz überschreiben, blockierende `Import-Module` rein kosmetischer Module, Start-Banner, fehlender Nicht-interaktiv-Guard.
4. **PATH**: Prozess- vs. HKCU- vs. HKLM-**Rohwert** (`DoNotExpandEnvironmentNames` — sonst sieht man wörtliche `%VAR%`-Einträge nicht). Tote Einträge, Duplikate, fremde Benutzerpfade. Notieren, was in Machine liegt (braucht Admin) und was in User.
5. **Module**: Mehrfachversionen. Admin-Module (Graph/Exchange/SharePoint/PnP) nie ungefragt anfassen — ob sie gebraucht werden, weiß nur der Nutzer.
6. **Editor-Terminal**: Welche VS-Code-Variante ist **wirklich** installiert (EXE prüfen — Settings-Ordner überleben Deinstallationen und täuschen). `fontFamily` gesetzt? `gpuAcceleration` deaktiviert?
7. **Dateileichen**: alte `.bak`-Profile, verwaiste Skript-Versionen, ungenutzte Themes.
8. **Kein Handlungsbedarf** — gar nicht erst vorschlagen: PSReadLine-Historie unter ein paar MB, zoxide-Hooks, OSC-Shell-Integrationen, pauschale Defender-Ausnahmen, WSL-Wechsel für Windows-Target-Projekte.

## Phase 2 — Befundbericht

Kompakte Tabelle: Befund · Messwert · Wirkung · Risiko. Noch keine Änderung. Was ein anderer Agent oder der Nutzer behauptet hat, vorher selbst nachmessen.

## Phase 3 — Rückfragen

AskUserQuestion in Themenrunden (max. 4 Fragen pro Runde), Empfehlung als erste Option:

- Runde 1 — Prompt & Profil: teure Segmente entfernen/cachen? Git-Detailgrad? Guard + Lazy-Loading einbauen? Banner weg?
- Runde 2 — Aufräumen: riskante Funktionen entfernen? Dateileichen? Machine-PATH bereinigen (**explizit fragen, ob ein UAC-Prompt okay ist**)? Modul-Duplikate?

Nur fragen, was echte Nutzer-Entscheidung ist (Geschmack, Risiko, „brauchst du X noch?"); Faktenfragen selbst durch Messen klären.

## Phase 4 — Umsetzung (nur Genehmigtes)

Reihenfolge: Backups → sichtbare Fixes (Font) → Theme/Profil → Aufräumen (Dateien, PATH, Module) → Nachmessen.

- **Profil**: vorher als `.backup-<yyyyMMdd>.ps1` sichern; Umbau nach `references/profile.template.ps1`-Muster (Guard zuerst, kosmetische Module lazy). Nutzerspezifische Blöcke (Fremd-Tool-Integrationen zwischen Markern) unverändert übernehmen.
- **Theme**: `pwsh -NoProfile -File "$CLAUDE_PLUGIN_ROOT/scripts/new-slim-theme.ps1" -SourceConfig <aktive-config> -OutPath <neue-config>` mit Parametern gemäß Freigaben. Nie das aktive Theme überschreiben; erst nach dem Praxistest im Profil umschalten.
- **Machine-PATH**: Die genehmigten Einträge als JSON-Array in eine temporäre Requestdatei schreiben, z. B. `{"remove":["C:\\Alt","C:\\Program Files\\Alt"]}`, dann `pwsh -NoProfile -File "$CLAUDE_PLUGIN_ROOT/scripts/invoke-clean-machine-path.ps1" -RequestFile <request.json>` ausführen. Der Wrapper rekonstruiert das Array, eleviert mit einem kodierten Befehl und prüft den Exitcode; `clean-machine-path.ps1` sichert den HKLM-Rohwert vorher selbst. Requestdatei anschließend löschen. Windows-`sudo` kann per Policy deaktiviert sein; **danach zusätzlich den Registry-Ist-Zustand verifizieren**.
- **Module**: `Uninstall-Module -RequiredVersion <alt>`; wenn das fehlschlägt, Versionsordner unter `<Documents>\PowerShell\Modules\<Name>\<Version>` löschen. Nur die alten Versionen, die neueste bleibt.

## Phase 5 — Abschluss

Vorher/Nachher-Tabelle (Startzeit, Prompt-Render, PATH-Einträge, entfernte Dateien/Module). Alle angelegten Backups auflisten mit dem Hinweis, sie erst nach bestandenem Praxistest (neues Terminal, ein Arbeitstag) zu löschen. Abgelehnte oder aufgeschobene Punkte mit fertigem Befehl für später dokumentieren.

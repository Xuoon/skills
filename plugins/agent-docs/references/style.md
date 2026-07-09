# Style: Was gute Agent-Doku ausmacht

Maßstab für alle Modi. Gilt für `CLAUDE.md`/`AGENTS.md` und Rules gleichermaßen.

**Leitidee:** Desto weniger Zeilen, desto weniger mögliche Fehler — **so viel wie nötig, nicht so viel wie möglich.** Token-effizient und agent-blocking.

## Architektur der Doku

- **Overview (CLAUDE.md/AGENTS.md)** = Was ist das, Commands, wenige Invarianten, **Verweise**. Keine Domain-Novellen.
- **Rules** = Tiefe pro Domäne (Security, Lifecycle, non-obvious Business-Regeln).
- **Hierarchie:** Root → App/Package → Rules-Unterordner. Die Datei, die der Arbeit am nächsten ist, gewinnt.
- **One Source of Truth:** Eine Mechanik/Zahl = eine kanonische Stelle. Woanders: max. ein Pointer-Satz + Link. Frage vor jedem Write: „Wo ist der kanonische Ort?“
- **Frontmatter-`paths:`:** Auto-Injection. Tests, Lib-Helfer, Consumer mit aufnehmen — nicht nur das Feature-Verzeichnis. Nicht so broad, dass die Rule bei jedem Edit im Repo lädt (außer bewusst always-on wie Security/Architecture).

## Was reingehört (Agent-blocking)

- Copy-paste-fähige Build-/Test-/Lint-Befehle, wenn sie **nicht** trivial aus `package.json` folgen (Aggregate, Traps).
- Security: Auth, Tenant-Isolation, Secrets, Rate-Limits, Public-Surface-Minimierung.
- Lifecycle-Achsen und Naming, die Code allein nicht „falsch macht“-sicher machen (`nummer` vs `status`, German domain fields).
- Kanonische Helper: „nutze X, baue kein Y“.
- Gotchas: non-obvious Formate, Side-Effect-Imports, Drift-Schutz, „warum so“.
- Env/CI/Deploy nur wo Agents sonst brechen (manuelles Convex-Deploy, dual CSP headers, …).

## Was NICHT reingehört

| Kategorie | Beispiel | Stattdessen |
| --- | --- | --- |
| Code-Paraphrase | Ordnerbäume, „es gibt create/update/remove“ | weglassen |
| Inventar | alle Exports, alle Props, alle Placeholder-Keys | `package.json` / Code / eine SSOT-Zeile |
| Implementation-Detail | Prefetch ±N Wochen, Debounce 250 ms Pfad, Sidebar-IntersectionObserver | Code; Doku nur „Kalender cached clientseitig“ falls überhaupt |
| UI-Chrome-Nacherzählung | welche Slots wo, welche Button-Labels | design-Rule einmal; Domain-Rules nicht wiederholen |
| Generics | „schreibe Tests“, „halte Code sauber“ | weglassen |
| Historie | „früher war…“, „infoSlot entfernt“ | aktuelle Invariante („gibt es nicht“) oder weg |
| Mensch-Tutorials | Onboarding-Prosa | README |
| Doppel-Pointer | drei Key-Reference-Listen | Root-Index + `paths:` |
| Session-Changelog | „wir haben gerade Prefetch gebaut, hier die Spec“ | Sync updated nur **Verträge**, nicht die Implementierung |

**Negativ-Inventare** („X gibt es nicht“) nur als bewusste Abgrenzung (z.B. kein `infoSlot`), nicht als Feature-Liste.

## Form

| Art | Zielgröße (Richtwert, kein Hard-Fail) |
| --- | --- |
| Root Overview | ≤ ~50 Zeilen |
| App/Package Overview | ≤ ~40 Zeilen |
| Domain Rule | ≤ ~60 Zeilen typisch; Security darf länger sein |
| Overview hard cap | ~150 Zeilen max |

- Flach: `#`/`##`, Bullets, Tabellen nur für enumerierbare Fakten (Statusfarben, Commands).
- **Eine Zeile pro Konzept.** Test: „Würde ein Agent ohne diese Zeile etwas **Falsches** tun?“ — nein → streichen.
- Relative Markdown-Links müssen resolven.
- Pointer-Satz: `… kanonisch in [foo.md](./foo.md)` — Mechanik nicht nochmal ausführen.

## Wartung

- Doku wie Code: Lifecycle/Schema/Security-Änderung → Doku im selben PR (Sync).
- Beweis vor Behauptung (`file:line`).
- Nach **jedem** Sync, der Zeilen **addiert**, sofort Mini-Prune (siehe Sync-Skill + [prune-sweep.md](prune-sweep.md)).
- Nach großem Audit mit Adds: voller Prune-Sweep Pflicht.

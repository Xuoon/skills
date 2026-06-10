# Style: Was gute Agent-Doku ausmacht

Maßstab für alle Modi. Gilt für `CLAUDE.md`/`AGENTS.md` und Rules-Dateien gleichermaßen.

## Architektur der Doku

- **Overview-Dateien (CLAUDE.md/AGENTS.md) = Bereichs-Überblick + Verweise; Rules = Detail.** Eine Overview-Datei beantwortet: Was ist das hier, welche Commands, welche Invarianten, wo steht der Rest. Rules tragen die Tiefe pro Domäne.
- **Hierarchie nutzen**: Root-Datei für Repo-weites, eine pro App/Package für Lokales, Rules-Verzeichnis mit Domänen-Unterordnern (z.B. `rules/{security,admin,dash}/`). Die Datei, die der Arbeit am nächsten ist, gewinnt.
- **One Source of Truth**: Jede Mechanik/Zahl/Invariante hat genau eine kanonische Stelle. Andere Dateien: maximal ein Pointer-Satz mit Link. Beim Schreiben immer fragen: "Wo ist der kanonische Ort dafür?"
- **Frontmatter-`paths:`** in Rules pflegen — sie steuern Auto-Injection. Tests, Lib-Helfer und Consumer-Dateien des Themas mit aufnehmen, nicht nur das Feature-Verzeichnis.

## Was reingehört

- Exakte Build-/Test-/Lint-Befehle in Backticks (copy-paste-fähig).
- Architektur-Überblick: Module, Datenfluss, App-Beziehungen.
- Security-Invarianten: Auth-Flows, Tenant-Isolation, Rate-Limits, Secrets-Handling.
- Konventionen, die der Code nicht selbst zeigt: Naming-Regeln, Lifecycle-Achsen, kanonische Helper ("nutze X, baue kein Y").
- Gotchas & learned lessons: non-obvious Datenformate, Side-Effect-Imports, Drift-Schutz-Mechaniken, "warum so und nicht anders".
- Externe Services + Env-Variablen mit ihren Eigenheiten.
- CI/Deploy-Realität: was läuft wann, was ist manuell.

## Was NICHT reingehört

- Redundantes aus README/anderen Docs → verlinken.
- Generische Best Practices ("schreibe Tests", "halte Code sauber") — null Repo-Mehrwert.
- Code-Paraphrasen: Was der Code trivial selbst zeigt (Verzeichnisnamen, simple CRUD), nicht nacherzählen.
- Features, die (noch) nicht existieren; Pläne; Historien-Sprache ("früher war…", "nicht mehr…").
- Lange Mensch-Anleitungen (gehören in README).
- Negativ-Inventare ("X gibt es nicht") außer als bewusste Abgrenzungs-Invariante.

## Form

- Zielgröße pro Overview-Datei: **~150 Zeilen max**. Signal über Umfang.
- Flache Struktur: `#`/`##`-Sections, Bullets, Tabellen nur für enumerierbare Fakten.
- Inline-Code für Commands, Dateinamen, Env-Variablen, Feldnamen.
- Eine Zeile pro Konzept; jedes Bullet muss einen Edit verändern können ("würde ein Agent ohne diese Zeile etwas falsch machen?").
- Relative Markdown-Links zwischen Doku-Dateien — sie müssen resolven.

## Wartung

- **Doku wie Code behandeln**: Ändert ein PR Build-Schritte, Schema, Lifecycle oder kanonische Helper, wird die Doku im selben PR aktualisiert (Sync-Modus).
- Beweis vor Behauptung: Doku-Aussagen brauchen Code-Evidence (`file:line`), keine Erinnerung.
- Nach jedem größeren Audit, das Inhalte ergänzt hat, einen Prune-Sweep als Gegen-Check fahren.

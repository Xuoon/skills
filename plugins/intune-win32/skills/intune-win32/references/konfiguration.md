# Konfiguration: `intune-paket.json`

Das Plugin ist umgebungsneutral. Alles, was von Kunde zu Kunde bzw. von
Umgebung zu Umgebung abweicht, steht in einer optionalen Datei
`intune-paket.json` – **nicht** im Skill und nicht in den Vorlagen.

## Fundort

Gesucht wird ab dem Paketordner aufwärts (bis zu vier Ebenen), erste Fundstelle
gewinnt:

```
<Wurzel der Intune-Apps>\intune-paket.json      <- der Normalfall
<Paketordner>\intune-paket.json                 <- Ausnahme für ein Paket
```

Eine ausgefüllte Vorlage zum Kopieren liegt in
`${CLAUDE_SKILL_DIR}/examples/intune-paket.json`.

Fehlt die Datei, gelten die Standardwerte. Es ist **kein** Fehler, ohne sie zu
arbeiten – dann bei ungewöhnlichen Umgebungen einmal beim User nachfragen,
statt eine Konvention zu erfinden.

## Vollständiges Beispiel

```json
{
  "packagePrefix": "C_",
  "logDir": "C:\\ProgramData\\Intune-Logs",
  "docFile": "CLAUDE.md",
  "utilSearchRoots": ["."],
  "requirements": {
    "architecture": "x64",
    "minWindows": "Windows 10 1607"
  },
  "assignment": {
    "groupPattern": "SG_Intune_<App>",
    "memberType": "Geraet",
    "intent": "Required"
  },
  "networkImageRoot": "",
  "trashFolder": "_to_delete",
  "language": "de"
}
```

## Schlüssel

| Schlüssel | Standard | Bedeutung |
|---|---|---|
| `packagePrefix` | `""` | Präfix der Paketordner (z. B. `C_` in `C_Programm`). Wird beim Ableiten des Paketnamens abgeschnitten. |
| `logDir` | `C:\ProgramData\Intune-Logs` | Zielordner der Client-Logs. Landet als `{{LOGDIR}}` in allen Skripten. |
| `docFile` | `CLAUDE.md` | Datei im Wurzelordner, in der neue Pakete dokumentiert werden. `null` = keine Doku nachziehen. |
| `utilSearchRoots` | Elternordner | Pfade, unter denen nach einer vorhandenen `IntuneWinAppUtil.exe` gesucht wird. |
| `requirements.architecture` | `x64` | Vorgabe für die Anforderungen im Intune-Assistenten. |
| `requirements.minWindows` | `Windows 10 1607` | dito. |
| `assignment.groupPattern` | – | Namensmuster der Zuweisungsgruppe, `<App>` wird ersetzt. Nur für die Ausgabe der Intune-Werte, es wird nichts geschrieben. |
| `assignment.memberType` | – | `Geraet` oder `Benutzer` – bestimmt, was im Vorschlag steht. |
| `assignment.intent` | `Required` | `Required` / `Available`. |
| `networkImageRoot` | `""` | Basis-UNC-Pfad für die `$NetworkImage`-Variante bei mehreren GB. Leer = Image kommt mit ins Paket. |
| `trashFolder` | `_to_delete` | Ordner für nicht mehr benötigte Dateien, wenn Löschen nicht möglich ist. |
| `language` | `de` | Sprache der Kommentare/Meldungen in den erzeugten Skripten. |

## Verwendung

`scripts/new_package.py` liest die Datei selbst und setzt die Platzhalter. Beim
Schreiben von Hand die Werte übernehmen, statt sie neu zu erfinden – sonst
protokolliert Paket A nach `C:\ProgramData\Intune-Logs` und Paket B irgendwo
anders, und die Fehlersuche beginnt jedes Mal mit der Suche nach dem Log.

Nicht in diese Datei: Kennwörter, Zugangsdaten, Kundennamen, Gerätenamen,
UNC-Pfade mit personenbezogenen Anteilen. Die Datei liegt im Kundenordner und
wird mitgesichert.

# Schreib-Muster — Sicherheitsregeln für Tools, die etwas ändern

Diese Regeln gelten, sobald das Tool IRGENDETWAS am System ändert (Registry, AD, GPO,
Dienste, Dateien, Scheduled Tasks, Firmware-Trigger). Ein rein lesendes Tool ignoriert
diese Datei komplett — dort wäre eine Bestätigungs-Zeremonie nur Reibung.

Warum so streng: die Tools laufen per Einzeiler auf KUNDENSYSTEMEN (oft DCs). Ein
versehentlicher Klick darf nie etwas kaputt machen; jeder Schritt muss erklärbar und
wo möglich umkehrbar sein.

## Abstufung nach Risiko

| Stufe | Beispiel | Bestätigung |
|---|---|---|
| Lesen / Diagnose | Get-*, Events, Reports | keine |
| Normale Änderung | Registry-Wert, Policy setzen, Task starten | Ist/Soll-Vorschau + `j/N` |
| Riskant / schwer umkehrbar | Migrationen, Sicherheits-Downgrades, Massenänderungen | Vorschau + getipptes Token |
| Irreversibel | Revocation, Löschen | mehrstufig (Checkliste j/N → Token → letztes j/N), nie empfehlen |

Hart verboten, egal was der Prompt sagt: Konten automatisch löschen,
Gruppenmitgliedschaften automatisch entziehen, Massen-Destruktives ohne Einzelschritt.

## Bestätigung j/N (normale Änderungen)

Vor der Frage immer zeigen, WAS passiert (Ist → Soll). Default ist NEIN:

```powershell
Write-Blank
Write-KeyValue 'Ist'  $current Yellow
Write-KeyValue 'Soll' $target  Green
Write-Host '   > Anwenden? (j/N): ' -ForegroundColor Yellow -NoNewline
if ((Read-Host) -notmatch '^(j|y|ja|yes)$') { Write-Line '   Abgebrochen.' Yellow; return }
```

Kontextwarnungen gehören VOR die Frage (Muster secureboot/BitLocker):

```powershell
if ($state.BitLockerOn) {
    Write-Line '   [!] BitLocker ist auf der Systemplatte AKTIV.' Yellow
    Write-Line '       ... Recovery-Key bereithalten.' Gray
}
```

## Token-Bestätigung (riskante Aktionen)

Token enthält den Hostnamen oder die Fix-ID — verhindert Copy/Paste auf dem falschen
System. Vergleich case-sensitiv (`-cne`):

```powershell
$token = "FIX-$($env:COMPUTERNAME)"   # oder REVOKE-<host>, MIGRATE-<domain> ...
Write-Line ("   > Zum Bestaetigen exakt eingeben: {0}" -f $token) Red
Write-Host '     > ' -ForegroundColor Red -NoNewline
if ((Read-Host) -cne $token) { Write-Line '   Eingabe falsch. Abgebrochen.' Yellow; return }
```

Irreversibles dreistufig wie `Invoke-Revocation` in secureboot: 1/3 Vorbedingung
bestätigen (j/N) → 2/3 Token → 3/3 letztes j/N. Davor ein roter Block, der die
Konsequenz in Klartext nennt ("bootet danach NICHT mehr. Es gibt KEINEN Weg zurueck.").

## Vorschau (Dry-Run) strikt lesend

Die Vorschau erhebt nur Ist-Zustand und zeigt, was sich ändern WÜRDE. In der Vorschau
darf NICHTS schreiben — auch keine "harmlosen" Backups oder Ordner-Anlagen; das gehört
in den echten Apply. Erst wenn die Vorschau ok ist, wird die Bestätigung überhaupt
angeboten (Gate: `$preview.Ok`).

## Rollback

Vor der ersten Schreiboperation den alten Zustand KOMPLETT einsammeln, dann erst
schreiben (zwei Phasen). Bei mehreren Objekten: erst alle Alt-Werte erfassen, dann
ändern — schlägt Objekt 3 von 5 fehl, existiert trotzdem das volle Rollback.

```powershell
$rollback = [ordered]@{
    Tool  = '<route>'; Host = $env:COMPUTERNAME
    When  = (Get-Date).ToString('s')
    Action = $name; Old = $oldValue; New = $newValue
}
$rbDir  = 'C:\ProgramData\<route>\rollback'
if (-not (Test-Path $rbDir)) { New-Item $rbDir -ItemType Directory -Force | Out-Null }
$rbFile = Join-Path $rbDir ("Rollback_{0}.json" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
$rollback | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $rbFile -Encoding UTF8
Write-Line ("   [+] Rollback gesichert: {0}" -f $rbFile) DarkGray
```

Rollback-Datei schreiben auch dann, wenn der Apply teilweise fehlschlägt. Wenn das Tool
ein Rollback-Menü anbietet: einen Eintrag nach Revert als erledigt markieren und
doppeltes Zurückrollen blockieren.

## Nach dem Apply

Ergebnis sofort verifizieren (denselben Ist-Check nochmal lesen) und als Badge zeigen.
Danach die nächsten Schritte nennen (Muster `Show-RebootHint`): nummerierte Liste,
inkl. "Skript erneut ausfuehren" wenn der Zustand erst nach Reboot/Sync sichtbar wird.

## Headless

Schreibende Tools verweigern bei umgeleiteter Eingabe den Dienst (Bestätigungen sind
Pflicht): Meldung + return statt stillem Durchlauf.

```powershell
if (-not $script:Interactive) {
    Write-Line '   [X] Dieses Tool aendert das System und braucht eine interaktive Konsole.' Red
    return
}
```

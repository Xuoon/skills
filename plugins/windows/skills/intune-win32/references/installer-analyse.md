# Installer analysieren – bevor das Paket gebaut wird

Ziel: Setup-Typ, Silent-Schalter, Standard-Zielordner und Registry-Anzeigename
aus dem Installer selbst ermitteln, statt sie zu raten oder aus dem Gedächtnis
zu rekonstruieren.

Die Kommandos brauchen `file`, `strings`, `7z` und `python3`. Fehlt eins davon,
das nachinstallieren statt den Schalter zu raten — die Analyse ist der Teil, der
den Rollout rettet.

## 1. Grundtyp

```bash
file installer.exe
# PE32 executable (GUI) Intel 80386   -> 32-Bit
# PE32+ executable (GUI) x86-64       -> 64-Bit
```

## 2. Setup-Framework erkennen

```bash
strings -n 5 installer.exe | grep -Eio \
  "nullsoft install system[^\"]{0,20}|inno setup|installshield|WiX|Burn|RunProgram=" \
  | sort | uniq -c
```

| Fund | Framework | Silent-Schalter |
|---|---|---|
| `Nullsoft Install System` | NSIS | `/S` (großes S!), Ziel `/D=C:\Pfad` als **letztes** Argument, unquotiert |
| `Inno Setup` / `SetupLdr` | Inno | `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` |
| `InstallShield` | InstallShield | `/s /v"/qn"` bzw. `/s /f1"response.iss"` |
| `WiX` + `Burn` | WiX-Bundle | `/quiet /norestart` |
| `RunProgram="setup.exe"` | **7-Zip-SFX** | siehe unten |
| nichts davon, Datei ist MSI | Windows Installer | `/qn /norestart` |

## 3. 7-Zip-SFX auspacken

Erkennungszeichen ist der Konfigblock am Ende des PE-Headers:

```
;!@Install@!UTF-8!
RunProgram="setup.exe"
;!@InstallEnd@!
```

Das eigentliche Setup steckt im Archiv – auspacken und *dieses* analysieren:

```bash
mkdir sfx && cd sfx && 7z x ../installer.exe -y
ls -la          # Setup.exe, Setup.ini, Msi\, files\ ...
cat Setup.ini   # Produktname, Version, Standard-Zielordner im Klartext
```

Zur Laufzeit gilt: der SFX reicht **zusätzliche Kommandozeilenparameter an
`RunProgram` durch**, `-y` unterdrückt den Entpackdialog. Ein stiller Aufruf
sieht also so aus:

```
installer.exe -y /silent /nofinishwnd /notip
```

Damit bleibt der 130-MB-Selbstentpacker als **eine** Datei im Paket, statt das
Archiv entpackt mitzuschleppen.

Autodesk-Selbstentpacker verstehen zusätzlich `-suppresslaunch -d <Zielordner>`.
7-Zip ist dort der zuverlässigere Weg.

### Sonderfall: Downloader statt Setup (Autodesk „Create Installer")

Manche Hersteller-EXEs enthalten **kein** Setup, sondern nur einen
Bootstrapper. Erkennungszeichen im Konfigblock:

```
RunProgram="db-bootstrap.exe"     statt   RunProgram="setup.exe"
```

Entpackt man so eine Datei, liegen im Ergebnis `db-bootstrap.exe`,
`db-bootstrap.json`, `DownloadManager.exe`, `ImageBuilder.dll`, `7za.exe`,
Qt6-DLLs – und **ein inneres Archiv** mit dem eigentlichen Produkt. Die
`db-bootstrap.json` benennt es samt Größe und Prüfsumme:

```json
{"ImageName":"Autodesk Desktop Connector",
 "FileInfo":[{"File":"Autodesk_Desktop_Connector_002_002.7z",
              "UnpackedSize":2229742045,"PackedSize":2041424492,"Checksum":"…"}]}
```

Das Vorbereitungsskript muss dann **zweistufig** entpacken (Downloader nach
`_extract\`, dann das gefundene `*.7z` nach `App\Image\`). Wer nur einstufig
entpackt und danach auf `Setup.exe` prüft, bekommt „7-Zip: Everything is Ok"
und trotzdem FEHLGESCHLAGEN – auf der ersten Ebene kann `Setup.exe` gar nicht
liegen. Platzbedarf einplanen: Quelldatei + Zwischenstand + Ergebnis, bei
2-GB-Produkten also rund 7 GB.

### Dateiliste eines .7z lesen, ohne es zu entpacken

Nützlich, wenn das Archiv mehrere GB groß ist und nur die Struktur
interessiert (und wenn auf dem Gerät kein 7-Zip verfügbar ist):

```python
import lzma, struct, re
f = open('archiv.7z','rb'); sh = f.read(32)
no, ns, _ = struct.unpack_from('<QQI', sh, 12)      # NextHeaderOffset/Size
f.seek(32+no); h = f.read(ns)
# h[0] == 0x17 -> kEncodedHeader: PackInfo/UnPackInfo aus h von Hand lesen
# (7z-Zahlenformat: Bitmaske im ersten Byte), dann:
dec = lzma.LZMADecompressor(format=lzma.FORMAT_RAW,
        filters=[{'id':lzma.FILTER_LZMA1,'dict_size':0x400000,'lc':3,'lp':0,'pb':2}])
hdr = dec.decompress(open('archiv.7z','rb').read()[…], unpackSize)
print(re.findall(r'[ -~\\]{3,}', hdr.decode('utf-16-le','ignore')))
```

Ist `h[0] == 0x01`, liegt der Header unkomprimiert vor und die Namen lassen
sich direkt als UTF-16 herauslesen.

## 4. Die tatsächlich unterstützten Schalter auslesen

Moderne Setups legen ihre Kommandozeilenschalter als UTF-16-Strings ab –
deshalb `-e l`:

```bash
strings -e l -n 3 Setup.exe | grep -E "^/[a-zA-Z]" | sort -u
```

Beispielausbeute eines NSIS-artigen Setups:

```
/dir        Zielordner
/nofailtip  keine Fehlerdialoge
/nofinishwnd kein Abschlussfenster
/nomaintain kein Wartungsmodus
/notip      keine Hinweisfenster
/novc       VC-Redist NICHT mitinstallieren
/silent     stille Installation
/uninstall  Deinstallation
```

Das schlägt jede Herstellerdoku, weil es die reale Version beschreibt. Ergibt
die Suche nichts, ist die EXE gepackt – dann Herstellerdoku suchen und den Wert
als `TODO pruefen` markieren.

## 5. Registry-Anzeigename und Zielordner vorab bestimmen

```bash
strings -e l -n 5 Setup.exe | grep -Ei "<Produktname>|Uninstall\\\\|Program Files" | sort -u
grep -Ei "PRODUCTNAME|VERSION|PATH|SETUP_DEST" Setup.ini
```

Daraus entsteht das Muster für `detect-*.ps1` (z. B. `*Produkt*2027*`). Der
endgültige Anzeigename steht erst nach der Testinstallation fest – im Zweifel
mit `*` an beiden Enden arbeiten und den User bitten, ihn zu bestätigen:

```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Select-Object DisplayName, DisplayVersion, UninstallString |
  Where-Object DisplayName | Sort-Object DisplayName
```

## 6. Bitness von .NET-Anwendungen (CorFlags)

Relevant, wenn ein Programm eine Abhängigkeit **über die Registry** sucht:
eine AnyCPU-Anwendung läuft auf x64 als 64-Bit-Prozess und sieht
`HKLM\SOFTWARE\WOW6432Node` **nicht**. Eine 32-Bit-Abhängigkeit ist für sie
dann unsichtbar, obwohl sie installiert ist.

```bash
python3 - <<'PY'
import struct
d=open('Programm.exe','rb').read()
pe=struct.unpack_from('<I',d,0x3c)[0]
machine=struct.unpack_from('<H',d,pe+4)[0]
magic=struct.unpack_from('<H',d,pe+24)[0]
print(f'machine={machine:04x} magic={magic:03x}')   # 014c/10b = 32-Bit-Header
PY
```

Steht dort `machine=014c magic=10b` und ist es eine .NET-Assembly mit
`ILONLY=1, 32BITREQUIRED=0`, dann ist es **AnyCPU** → 64-Bit-Prozess auf x64 →
die Abhängigkeit muss als **64-Bit** installiert werden.

Welche Registry-Schlüssel und Aufrufparameter das Programm erwartet, verrät
ebenfalls `strings -e l`:

```bash
strings -e l Programm.exe | grep -Ei "SOFTWARE\\\\|\.exe|-sDEVICE|-d[A-Z]"
# z.B. SOFTWARE\GPL GhostScript , GSWin??c.exe , -sDEVICE=bbox -dSAFER -dNOPAUSE
```

Das ist der Beleg dafür, welche Fremdkomponente in welcher Bitness und
Mindestversion ins Paket gehört.

## 7. Ergebnis dokumentieren

Was hier gefunden wurde, gehört in den Kopfkommentar von `install.ps1` **und**
in die `CLAUDE.md` – inklusive der Herkunft („aus der EXE ausgelesen" vs. „laut
Herstellerdoku" vs. „geraten, noch zu testen"). Sonst rät der nächste Durchgang
wieder.

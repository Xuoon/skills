# Dev Drive: Zielzustand und Begründung

## Was ein Dev Drive ist

Ein ReFS-Volume, das Windows als Entwicklervolume kennzeichnet. Voraussetzung: Windows 11 Build 22621.2338 oder neuer, mindestens 50 GB. Zwei Formen: VHDX-Datei auf einer unterstützten lokalen Platte oder eigene Partition in nicht zugeordnetem Bereich. Formatieren geht nur über `Format-Volume -DevDrive` oder `format X: /DevDrv`; ein vorhandenes Volume lässt sich nicht verlustfrei umwandeln.

Wo der Gewinn herkommt, damit Empfehlungen begründbar bleiben:

- **ReFS-Metadaten**: Builds und Paketinstallationen erzeugen zehntausende kleine Dateien. Der Engpass ist Metadaten-Durchsatz, nicht Bandbreite. NTFS-Altlasten (8.3-Namen, Last-Access, Kompression, EFS) fallen weg.
- **Defender Performance Mode**: Auf einem *trusted* Dev Drive scannt Defender asynchron statt jeden Zugriff zu blockieren. Ohne Trust ist der Hauptvorteil weg. Fremd-AV (Sophos, CrowdStrike u. a.) hängt weiterhin als synchroner Filter am Volume; das ist eine Policy-Entscheidung des Nutzers, keine Empfehlung des Skills.
- **Kopieroptimierungen**: Block Cloning steht auf Dev Drives ab Windows 11 24H2 zur Verfügung. Bun verwendet unter Windows Hardlinks, wenn Cache und Projekt auf demselben Volume liegen.
- **Isolation**: Caches und Repos liegen nicht mehr in `C:\Users`, Backups von C: bleiben schlank, eine VHDX ist als Ganzes kopier- oder wegwerfbar.

Nachteile, die im Befund stehen müssen: nicht bootfähig und ReFS unterstützt die WSL-Mount-Option `metadata` nicht. Liegt die VHDX auf einem BitLocker-Volume, ist ihre Datei darüber verschlüsselt; für eine konsistente manuelle Kopie die VHDX vorher aushängen.

## VHDX oder Partition

| | VHDX | Partition |
| --- | --- | --- |
| Voraussetzung | freier Platz auf einer Platte | nicht zugeordneter Bereich (Verkleinern ist nicht Aufgabe dieses Skills) |
| Nach Neustart | erneut anhängen, per Mount-Task oder manuell | automatisch da |
| Verschieben/Sichern | eine Datei | Partition klonen |
| Empfehlung | Standard, weil rückbaubar | wenn ohnehin Bereich frei ist |

Für die VHDX: **dynamisch** statt feste Größe, sonst belegt sie sofort den vollen Platz. Microsoft empfiehlt die dynamisch wachsende Variante. Die konfigurierte Maximalgröße darf den aktuellen freien Host-Speicher abzüglich 20 GB Reserve nicht überschreiten. Wechselmedien und hot-plug-fähige Datenträger sind als Host oder Partitionsziel nicht unterstützt.

## Was umzieht und was nicht

Regel: **Was ständig geschrieben wird, zieht um. Was einmal installiert und dann nur gelesen wird, bleibt.**

### Umzugskandidaten

| Kandidat | Ist-Pfad (Standard) | Zielpfad | Modus | Variablen | PATH |
| --- | --- | --- | --- | --- | --- |
| Bun-Cache | `~\.bun\install\cache` | `X:\<user>\.cache\bun` | Discard | `BUN_INSTALL_CACHE_DIR` | |
| Cargo | `~\.cargo` | `X:\<user>\.cache\cargo` | Move | `CARGO_HOME` | `~\.cargo\bin` → `X:\<user>\.cache\cargo\bin` |
| Rustup | `~\.rustup` | `X:\<user>\.cache\rustup` | Move | `RUSTUP_HOME` | |
| npm-Cache | `%LOCALAPPDATA%\npm-cache` | `X:\<user>\.cache\npm` | Discard | `npm_config_cache` | |
| pnpm-Store | Ausgabe von `pnpm store path` | `X:\<user>\.cache\pnpm` | Discard | danach `pnpm config set store-dir X:\<user>\.cache\pnpm` | |
| pip-Cache | `%LOCALAPPDATA%\pip\cache` | `X:\<user>\.cache\pip` | Discard | `PIP_CACHE_DIR` | |
| uv-Cache | `%LOCALAPPDATA%\uv\cache` | `X:\<user>\.cache\uv` | Discard | `UV_CACHE_DIR` | |
| NuGet-Pakete | `~\.nuget\packages` | `X:\<user>\.cache\nuget` | Move | `NUGET_PACKAGES` | |
| Go-Modulcache | Ausgabe von `go env GOMODCACHE` | `X:\<user>\.cache\go-mod` | Discard | `GOMODCACHE` | |
| Go-Buildcache | Ausgabe von `go env GOCACHE` | `X:\<user>\.cache\go-build` | Discard | `GOCACHE` | |
| Gradle | `~\.gradle` | `X:\<user>\.cache\gradle` | Move | `GRADLE_USER_HOME` | |
| Maven-Repository | `~\.m2\repository` | `X:\<user>\.cache\maven` | Move | `MAVEN_OPTS` um `-Dmaven.repo.local=X:\<user>\.cache\maven` ergänzen oder `<localRepository>` in `settings.xml` | |
| Repos | wo gefunden | `X:\<user>\repos\<name>` | Move | | |

Move = Inhalt vollständig kopieren und erst nach erfolgreichem `robocopy` an der Quelle löschen. Discard = regenerierbaren Cache nach ausdrücklicher Auswahl löschen. Bei Rust nach einem optionalen Umzug `rustup show` prüfen; bei reinen Cache-Umzügen bleibt das Tool selbst auf `C:`.

### Bleibt auf C:, mit Begründung

- **Bun-, Node- und pnpm-Installationen samt globalen Binaries**: Anwendungen und SDKs bleiben standardmäßig auf `C:`; nur ihre Paket-Caches ziehen um. nvm4w reagiert zudem empfindlich auf verschobene Pfade.
- **Python-Interpreter**: gleiches Argument. Nur pip/uv-Caches ziehen um.
- **Go-Installation und `GOPATH\bin`**: Anwendungen bleiben auf `C:`. Repos unter `GOPATH\src` werden einzeln angeboten; nur `GOMODCACHE` und `GOCACHE` gelten als regenerierbare Caches.
- **Docker Desktop**: eigene VHDX unter `%LOCALAPPDATA%\Docker`. Umzug ist Platzersparnis, kein Dev-Drive-Gewinn, und geht nur über die Docker-Oberfläche (Settings → Resources → Disk image location). Erwähnen, nicht ausführen.
- **Agent-Client-Konfigurationen sowie `.ssh`, `.gnupg` und `.config`**: Konfiguration, kein Cache.
- **WSL-Repos mit POSIX-Rechten**: ReFS unterstützt die WSL-Option `metadata` nicht; solche Repos bleiben im WSL-Dateisystem oder auf NTFS.

## Verifikation

`test-devdrive.ps1` prüft in einer neuen, nicht erhöhten Shell des ursprünglichen Nutzers ReFS, pfadwertige Variablen, Tool-Herkunft, pnpm-/Maven-Kontext und Altlasten. `test-devdrive-admin.ps1` prüft getrennt über den UAC-Wrapper Mount, Trust, Filter und bei VHDX den SYSTEM-Mount-Task. Beide Läufe gehören ans Ende jeder Einrichtung und nach dem ersten Neustart.

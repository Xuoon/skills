# deps

Dependency-Pflege, bun-first. Bewusst als Namespace angelegt — `/deps:audit` (CVEs/EOL/Lizenzen) kann später ergänzt werden, ohne dass sich bestehende Befehle ändern.

| Befehl | Zweck |
| --- | --- |
| `/deps:bump [pfad] [paket] [minor]` | Alle Dependencies auf das letzte offizielle stabile Release; Plan → Freigabe → Apply → Verify. `minor` hält Majors zurück |

"Latest" = `latest`-Dist-Tag der Registry, niemals Pre-Releases (außer man ist bereits auf einer Pre-Release-Linie).

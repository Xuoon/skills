#!/usr/bin/env python3
"""Scaffolding fuer ein in sich geschlossenes Intune-Win32-Paket.

Erzeugt in einem Ordner, in dem bereits eine MSI/EXE liegt:

    <Ordner>\\
      App\\                 Installer + install/uninstall/detect-Skripte
      Output\\              Ziel fuer die .intunewin
      IntuneWinAppUtil.exe  eigene Kopie (kein ..\\-Bezug auf andere Ordner)
      Pack.cmd              packt App\\ -> Output\\, Log in pack.log

Umgebungsabhaengige Konventionen (Praefix der Paketordner, Log-Verzeichnis,
Suchpfade fuer IntuneWinAppUtil.exe) stehen NICHT in diesem Skript, sondern in
einer optionalen intune-paket.json - siehe references/konfiguration.md.
Gesucht wird ab dem Paketordner aufwaerts, bis zu vier Ebenen.

Aufruf (dort, wo der Paketordner liegt):

    python3 new_package.py "<Pfad zum Paketordner>" \
        --mode auto|exe|msi|msi-wrapper \
        --display-name "Programm*2026*" \
        --silent-args "'/s'"

Gibt am Ende eine JSON-Zusammenfassung aus.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"
INSTALLER_EXT = {".msi", ".exe"}
IGNORE_NAMES = {"intunewinapputil.exe"}
CONFIG_NAME = "intune-paket.json"

DEFAULTS = {
    "packagePrefix": "",
    "logDir": r"C:\ProgramData\Intune-Logs",
    "docFile": "CLAUDE.md",
    "utilSearchRoots": [],
    "trashFolder": "_to_delete",
}


def die(msg: str) -> None:
    print(json.dumps({"ok": False, "error": msg}, ensure_ascii=False, indent=2))
    sys.exit(1)


def load_config(folder: Path, explicit: str | None) -> tuple[dict, str]:
    cfg = dict(DEFAULTS)
    if explicit:
        path = Path(explicit).expanduser()
        if not path.is_file():
            die(f"--config nicht gefunden: {path}")
        cfg.update(json.loads(path.read_text(encoding="utf-8-sig")))
        return cfg, str(path)
    here = folder.resolve()
    for _ in range(5):
        cand = here / CONFIG_NAME
        if cand.is_file():
            cfg.update(json.loads(cand.read_text(encoding="utf-8-sig")))
            return cfg, str(cand)
        if here.parent == here:
            break
        here = here.parent
    return cfg, "(keine, Standardwerte)"


def write_crlf(path: Path, text: str) -> None:
    text = text.replace("\r\n", "\n").replace("\n", "\r\n")
    path.write_bytes(text.encode("utf-8-sig" if path.suffix == ".ps1" else "cp1252",
                                 errors="replace"))


def render(template: str, mapping: dict) -> str:
    out = (ASSETS / template).read_text(encoding="utf-8")
    for key, val in mapping.items():
        out = out.replace("{{%s}}" % key, val)
    return out


def find_util(folder: Path, search_roots: list[Path]) -> Path | None:
    local = folder / "IntuneWinAppUtil.exe"
    if local.is_file():
        return local
    for root in search_roots:
        if not root or not root.is_dir():
            continue
        for cand in root.rglob("IntuneWinAppUtil.exe"):
            if cand.is_file():
                return cand
    return None


def guess_display_name(stem: str) -> str:
    token = re.split(r"[-_ ]", stem)[0]
    return f"{token}*"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("folder")
    ap.add_argument("--mode", default="auto", choices=["auto", "exe", "msi", "msi-wrapper"])
    ap.add_argument("--name", default=None, help="Paketname fuer Logs/Meldungen")
    ap.add_argument("--display-name", default=None, help="Registry-Suchmuster, z.B. 'Programm*2026*'")
    ap.add_argument("--silent-args", default="'/S'",
                    help="PowerShell-Argumentliste, z.B. \"'/s','/norestart'\"")
    ap.add_argument("--uninstall-args", default="/S")
    ap.add_argument("--util-search", action="append", default=[])
    ap.add_argument("--config", default=None, help="Pfad zu intune-paket.json (sonst Autosuche)")
    ap.add_argument("--prefix", default=None, help="ueberschreibt packagePrefix aus der Konfiguration")
    ap.add_argument("--log-dir", default=None, help="ueberschreibt logDir aus der Konfiguration")
    ap.add_argument("--force", action="store_true", help="vorhandene Skripte ueberschreiben")
    args = ap.parse_args()

    folder = Path(args.folder).expanduser()
    if not folder.is_dir():
        die(f"Ordner nicht gefunden: {folder}")

    cfg, cfg_src = load_config(folder, args.config)
    prefix = args.prefix if args.prefix is not None else cfg.get("packagePrefix", "")
    log_dir = args.log_dir or cfg.get("logDir") or DEFAULTS["logDir"]

    app = folder / "App"
    out = folder / "Output"
    app.mkdir(exist_ok=True)
    out.mkdir(exist_ok=True)

    # Installer einsammeln: lose im Ordner liegende Dateien nach App\ verschieben
    moved = []
    for f in sorted(folder.iterdir()):
        if f.is_file() and f.suffix.lower() in INSTALLER_EXT and f.name.lower() not in IGNORE_NAMES:
            shutil.move(str(f), str(app / f.name))
            moved.append(f.name)

    installers = [f for f in sorted(app.iterdir())
                  if f.is_file() and f.suffix.lower() in INSTALLER_EXT
                  and f.name.lower() not in IGNORE_NAMES]
    if not installers:
        die(f"Kein Installer (*.msi/*.exe) in {folder} oder {app} gefunden.")

    # Hauptinstaller = groesste Datei (Setup-Launcher sind meist die grossen)
    main_installer = max(installers, key=lambda p: p.stat().st_size)
    pkg = args.name
    if not pkg:
        pkg = folder.name
        if prefix and pkg.startswith(prefix):
            pkg = pkg[len(prefix):]
        pkg = pkg.replace(" ", "")
    display = args.display_name or guess_display_name(main_installer.stem)

    mode = args.mode
    if mode == "auto":
        mode = "msi" if main_installer.suffix.lower() == ".msi" else "exe"

    # IntuneWinAppUtil.exe sicherstellen
    # Relative Suchpfade aus der Konfiguration gelten relativ zu deren Ordner.
    cfg_dir = Path(cfg_src).parent if Path(cfg_src).is_file() else folder
    roots = []
    for p in (args.util_search or cfg.get("utilSearchRoots") or []):
        cand = Path(p).expanduser()
        roots.append(cand if cand.is_absolute() else (cfg_dir / cand))
    roots = roots or [folder.parent, folder.parent.parent]
    util = find_util(folder, roots)
    util_note = "vorhanden"
    if util is None:
        die("IntuneWinAppUtil.exe nicht gefunden. Bitte eine Kopie in einen der "
            "Suchpfade legen oder von https://github.com/microsoft/"
            "Microsoft-Win32-Content-Prep-Tool herunterladen.")
    if util.parent != folder:
        shutil.copy2(util, folder / "IntuneWinAppUtil.exe")
        util_note = f"kopiert von {util}"

    created = []

    def emit(name: str, template: str, target: Path, mapping: dict) -> None:
        if target.exists() and not args.force:
            created.append(f"{name} (uebersprungen, existiert)")
            return
        write_crlf(target, render(template, mapping))
        created.append(name)

    common = {
        "PKGNAME": pkg,
        "SETUPFILE": main_installer.name,
        "DISPLAYNAME": display,
        "SILENTARGS": args.silent_args,
        "UNINSTALLARGS": args.uninstall_args,
        "LOGDIR": log_dir,
    }

    if mode == "exe":
        setup_for_pack = "install.ps1"
        emit("App/install.ps1", "install-exe.ps1.tmpl", app / "install.ps1", common)
        emit("App/uninstall.ps1", "uninstall.ps1.tmpl", app / "uninstall.ps1", common)
    elif mode == "msi-wrapper":
        setup_for_pack = "install.ps1"
        emit("App/install.ps1", "install-msi.ps1.tmpl", app / "install.ps1", common)
        emit("App/uninstall.ps1", "uninstall.ps1.tmpl", app / "uninstall.ps1", common)
    else:  # reines MSI
        setup_for_pack = main_installer.name

    detect_name = f"detect-{pkg}.ps1"
    emit(f"App/{detect_name}", "detect.ps1.tmpl", app / detect_name, common)

    pack_map = dict(common)
    pack_target = folder / "Pack.cmd"
    if not pack_target.exists() or args.force:
        text = render("Pack.cmd.tmpl", pack_map)
        text = text.replace('-s "%s"' % main_installer.name, '-s "%s"' % setup_for_pack)
        write_crlf(pack_target, text)
        created.append("Pack.cmd")
    else:
        created.append("Pack.cmd (uebersprungen, existiert)")

    print(json.dumps({
        "ok": True,
        "folder": str(folder),
        "config": cfg_src,
        "package": pkg,
        "mode": mode,
        "log_dir": log_dir,
        "installer": main_installer.name,
        "installer_size_mb": round(main_installer.stat().st_size / 1048576, 1),
        "other_files_in_app": [f.name for f in installers if f != main_installer],
        "moved_into_app": moved,
        "detection_pattern": display,
        "pack_source": setup_for_pack,
        "intunewinapputil": util_note,
        "doc_file": cfg.get("docFile"),
        "created": created,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

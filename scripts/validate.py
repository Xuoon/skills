#!/usr/bin/env python3
"""Validiert das Marketplace-Repo: marketplace.json, plugin.json, SKILL.md-Frontmatter,
${CLAUDE_SKILL_DIR}-Referenzen und relative Markdown-Links.

Lokal:  pip install pyyaml && python scripts/validate.py
CI:     läuft via .github/workflows/validate.yml bei jedem Push.
"""

import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")
NAME_RE = re.compile(r"^[a-z0-9-]+$")
DESC_BUDGET = 1024  # weiche Grenze pro Skill-Description

errors: list[str] = []
warnings: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        err(f"{path.relative_to(ROOT)}: kein valides JSON ({e})")
        return None


def frontmatter(path: Path):
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        err(f"{path.relative_to(ROOT)}: kein YAML-Frontmatter")
        return None, text
    try:
        return yaml.safe_load(m.group(1)) or {}, text
    except yaml.YAMLError as e:
        err(f"{path.relative_to(ROOT)}: Frontmatter-YAML kaputt ({e})")
        return None, text


def check_md_links(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for link in re.findall(r"\]\((?!https?://)([^)#\s]+)\)", text):
        target = (path.parent / link).resolve()
        if not target.exists():
            err(f"{path.relative_to(ROOT)}: broken link -> {link}")


def check_skill(path: Path, plugin_dir: Path) -> None:
    fm, text = frontmatter(path)
    rel = path.relative_to(ROOT)
    if fm is None:
        return
    desc = fm.get("description", "")
    if not desc:
        err(f"{rel}: description fehlt")
    elif len(desc) > DESC_BUDGET:
        warn(f"{rel}: description {len(desc)} Zeichen (> {DESC_BUDGET})")
    if "name" in fm and not NAME_RE.match(str(fm["name"])):
        err(f"{rel}: name '{fm['name']}' verletzt [a-z0-9-]")
    # ${CLAUDE_SKILL_DIR}-Referenzen auflösen (Basis = Verzeichnis der SKILL.md)
    for ref in re.findall(r"\$\{CLAUDE_SKILL_DIR\}([^\s`)\"']+)", text):
        target = (path.parent / ref.lstrip("/")).resolve()
        if not target.exists():
            err(f"{rel}: ${{CLAUDE_SKILL_DIR}}-Referenz löst nicht auf -> {ref}")
        elif plugin_dir.resolve() not in target.parents and target != plugin_dir.resolve():
            err(f"{rel}: Referenz zeigt aus dem Plugin heraus -> {ref}")
    check_md_links(path)


def check_plugin(entry_name: str, plugin_dir: Path) -> None:
    rel = plugin_dir.relative_to(ROOT)
    manifest = plugin_dir / ".claude-plugin" / "plugin.json"
    if not manifest.exists():
        err(f"{rel}: .claude-plugin/plugin.json fehlt")
        return
    data = load_json(manifest)
    if data is None:
        return
    if data.get("name") != entry_name:
        err(f"{rel}: plugin.json name '{data.get('name')}' != Marketplace-Eintrag '{entry_name}'")
    version = data.get("version", "")
    if not SEMVER.match(version):
        err(f"{rel}: version '{version}' ist kein Semver (X.Y.Z)")
    if not (plugin_dir / "CHANGELOG.md").exists():
        warn(f"{rel}: CHANGELOG.md fehlt")

    hooks_file = plugin_dir / "hooks" / "hooks.json"
    if hooks_file.exists():
        hooks_data = load_json(hooks_file)
        if hooks_data is not None:
            for ref in re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}([^\s\"'\\]+)", json.dumps(hooks_data)):
                target = plugin_dir / ref.lstrip("/")
                if not target.exists():
                    err(f"{rel}: hooks.json referenziert fehlende Datei -> {ref}")
                elif not target.stat().st_mode & 0o111:
                    warn(f"{rel}: Hook-Script nicht ausführbar (chmod +x) -> {ref}")

    skills = sorted((plugin_dir / "skills").glob("*/SKILL.md")) if (plugin_dir / "skills").is_dir() else []
    root_skill = plugin_dir / "SKILL.md"
    if skills and root_skill.exists():
        warn(f"{rel}: skills/-Verzeichnis UND Root-SKILL.md — Root wird ignoriert")
    if not skills and not root_skill.exists() and not hooks_file.exists():
        warn(f"{rel}: kein Skill/Hook gefunden (weder skills/*/SKILL.md noch SKILL.md noch hooks/hooks.json)")
    for skill in skills or ([root_skill] if root_skill.exists() else []):
        check_skill(skill, plugin_dir)
    for md in plugin_dir.rglob("*.md"):
        if md.name != "SKILL.md":
            check_md_links(md)


def main() -> int:
    mp_path = ROOT / ".claude-plugin" / "marketplace.json"
    if not mp_path.exists():
        err(".claude-plugin/marketplace.json fehlt")
    else:
        mp = load_json(mp_path)
        if mp is not None:
            for key in ("name", "owner", "plugins"):
                if key not in mp:
                    err(f"marketplace.json: Feld '{key}' fehlt")
            seen: set[str] = set()
            for entry in mp.get("plugins", []):
                name = entry.get("name", "")
                if not NAME_RE.match(name):
                    err(f"marketplace.json: Plugin-Name '{name}' verletzt [a-z0-9-]")
                if name in seen:
                    err(f"marketplace.json: Plugin-Name '{name}' doppelt")
                seen.add(name)
                source = entry.get("source")
                if isinstance(source, str):
                    plugin_dir = (ROOT / source).resolve()
                    if not plugin_dir.is_dir():
                        err(f"marketplace.json: source '{source}' existiert nicht")
                    else:
                        check_plugin(name, plugin_dir)
                elif isinstance(source, dict):
                    if source.get("source") == "github" and not entry.get("ref") and not source.get("ref"):
                        warn(f"marketplace.json: externes Plugin '{name}' ohne ref-Pinning")
                else:
                    err(f"marketplace.json: Plugin '{name}' ohne source")

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"FEHLER {e}")
    print(f"\n{len(errors)} Fehler, {len(warnings)} Warnungen")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

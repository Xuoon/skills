#!/usr/bin/env python3
"""Validiert das Marketplace-Repo: marketplace.json, plugin.json, Root-Changelog,
SKILL.md-Frontmatter, ${CLAUDE_SKILL_DIR}-Referenzen und relative Markdown-Links.

Lokal:  pip install pyyaml && python scripts/validate.py
CI:     läuft via .github/workflows/validate.yml bei jedem Push.
"""

import json
import os
import re
import subprocess
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
    # Code-Blöcke/-Spans enthalten Beispiel-Links, keine echten Referenzen
    text = re.sub(r"```.*?```", "", text, flags=re.S)
    text = re.sub(r"`[^`\n]*`", "", text)
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


def _git(*args):
    """git am Repo-Root ausführen; stdout (str) oder None bei Fehler/fehlendem git."""
    try:
        return subprocess.run(
            ["git", "-C", str(ROOT), *args],
            capture_output=True, text=True, check=True,
        ).stdout
    except Exception:  # noqa: BLE001
        return None


def _is_executable(path: Path) -> bool:
    """Executable-Bit portabel prüfen; Windows-``stat`` bildet ihn nicht ab."""
    if os.name != "nt":
        return bool(path.stat().st_mode & 0o111)
    rel = path.relative_to(ROOT).as_posix()
    staged = _git("ls-files", "--stage", "--", rel)
    if not staged:
        return False
    mode = staged.split(maxsplit=1)[0]
    return mode == "100755"


def _release_baseline():
    """Vergleichs-Ref je Kontext (PR/Push/lokal). None -> Release-Regel überspringen."""
    if _git("rev-parse", "--git-dir") is None:
        return None
    base_ref = os.environ.get("GITHUB_BASE_REF")
    if base_ref:  # PR-Build
        mb = _git("merge-base", f"origin/{base_ref}", "HEAD")
        return mb.strip() if mb else None
    if os.environ.get("GITHUB_EVENT_NAME") == "push":
        parent = _git("rev-parse", "--verify", "HEAD^")
        return parent.strip() if parent else None
    return "HEAD" if _git("rev-parse", "--verify", "HEAD") else None


def _changelog_top_version(plugin_name: str):
    """Neueste Version aus dem Abschnitt ``## <plugin>`` im Root-Changelog."""
    cl = ROOT / "CHANGELOG.md"
    if not cl.exists():
        return None
    text = cl.read_text(encoding="utf-8")
    plugin = re.search(rf"^##\s+{re.escape(plugin_name)}\s*$", text, re.M)
    if not plugin:
        return None
    rest = text[plugin.end():]
    next_plugin = re.search(r"^##\s+", rest, re.M)
    section = rest[:next_plugin.start()] if next_plugin else rest
    m = re.search(r"^###\s*\[(\d+\.\d+\.\d+)\]", section, re.M)
    return m.group(1) if m else None


def check_release(rel: Path, plugin_dir: Path, version: str) -> None:
    """Materielle Plugin-Änderungen verlangen einen SemVer-Bump.

    Der passende Root-Changelog-Eintrag wird unabhängig davon in ``check_plugin``
    geprüft. Ohne git/Baseline wird der Bump-Check übersprungen.
    """
    baseline = _release_baseline()
    if baseline is None:
        return
    plugin_path = plugin_dir.relative_to(ROOT).as_posix()
    if baseline == "HEAD":  # lokal: Working Tree gegen HEAD (inkl. untracked)
        changed = ((_git("diff", "--name-only", "HEAD", "--", plugin_path) or "").splitlines()
                   + (_git("ls-files", "--others", "--exclude-standard", "--", plugin_path) or "").splitlines())
    else:  # CI: Commit-Bereich Baseline..HEAD
        changed = (_git("diff", "--name-only", baseline, "HEAD", "--", plugin_path) or "").splitlines()
    # Das Entfernen historischer Plugin-CHANGELOGs bei der Root-Konsolidierung
    # verändert kein ausgeliefertes Laufzeitverhalten.
    if not any(f and not f.endswith("CHANGELOG.md") for f in changed):
        return
    base_manifest = _git("show", f"{baseline}:{plugin_path}/.claude-plugin/plugin.json")
    if base_manifest:  # fehlt -> neues Plugin, Bump-Check überspringen
        try:
            base_version = json.loads(base_manifest).get("version")
        except Exception:  # noqa: BLE001
            base_version = None
        if base_version and base_version == version:
            err(f"{rel}: geändert, aber version nicht gebumpt (noch {version}) — SemVer-Bump + Root-CHANGELOG nötig")


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
        err(f"{rel}: version '{version}' ist kein SemVer (X.Y.Z)")
    else:
        check_release(rel, plugin_dir, version)
        top = _changelog_top_version(entry_name)
        if top is None:
            err(f"{rel}: Abschnitt '## {entry_name}' mit Version fehlt in Root-CHANGELOG.md")
        elif top != version:
            err(f"{rel}: Root-CHANGELOG-Top [{top}] != plugin.json version {version}")

    hooks_file = plugin_dir / "hooks" / "hooks.json"
    if hooks_file.exists():
        hooks_data = load_json(hooks_file)
        if hooks_data is not None:
            for ref in re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}([^\s\"'\\]+)", json.dumps(hooks_data)):
                target = plugin_dir / ref.lstrip("/")
                if not target.exists():
                    err(f"{rel}: hooks.json referenziert fehlende Datei -> {ref}")
                elif not _is_executable(target):
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
    if not (ROOT / "CHANGELOG.md").exists():
        err("CHANGELOG.md im Repo-Root fehlt")
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

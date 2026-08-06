#!/usr/bin/env python3
"""Prüft die Marktplatz-Invarianten aus CLAUDE.md.

Lokal: uv run --with pyyaml scripts/validate.py
CI:    uv run --with pyyaml scripts/validate.py --release-gate origin/main
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
PLUGINS_DIR = REPO_ROOT / "plugins"
MARKETPLACE_FILE = REPO_ROOT / ".claude-plugin" / "marketplace.json"
CHANGELOG_FILE = REPO_ROOT / "CHANGELOG.md"
PLUGIN_MANIFEST = Path(".claude-plugin") / "plugin.json"

# Pfade in SKILL.md-Bodies. ${CLAUDE_SKILL_DIR} zeigt auf das Verzeichnis der
# SKILL.md — ein ../ darin verlässt das Plugin und bricht nach der Installation,
# weil Plugins in einen Cache kopiert werden.
SKILL_DIR_PATH = re.compile(r"\$\{CLAUDE_SKILL_DIR\}(/[^\s`)]*)")
FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.DOTALL)
SEMVER = re.compile(r"\A\d+\.\d+\.\d+\Z")


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []

    def check(self, condition: bool, message: str) -> bool:
        if not condition:
            self.errors.append(message)
        return condition

    def fail(self, message: str) -> None:
        self.errors.append(message)


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def read_frontmatter(path: Path) -> dict | None:
    match = FRONTMATTER.match(path.read_text(encoding="utf-8"))
    if match is None:
        return None
    data = yaml.safe_load(match.group(1))
    return data if isinstance(data, dict) else None


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def check_skill_paths(report: Report, skill_file: Path) -> None:
    for path in SKILL_DIR_PATH.findall(skill_file.read_text(encoding="utf-8")):
        report.check(
            "../" not in path,
            f"{rel(skill_file)}: ${{CLAUDE_SKILL_DIR}}{path} zeigt aus dem Plugin heraus",
        )


def check_plugin(report: Report, plugin_dir: Path) -> None:
    name = plugin_dir.name
    manifest_file = plugin_dir / PLUGIN_MANIFEST

    if not report.check(manifest_file.is_file(), f"{name}: {PLUGIN_MANIFEST} fehlt"):
        return

    manifest = read_json(manifest_file)
    report.check(
        manifest.get("name") == name,
        f"{name}: plugin.json name ist {manifest.get('name')!r}, muss dem Ordnernamen entsprechen",
    )
    report.check(
        bool(SEMVER.match(str(manifest.get("version", "")))),
        f"{name}: version {manifest.get('version')!r} ist kein Semver",
    )
    report.check(bool(manifest.get("description")), f"{name}: plugin.json ohne description")

    root_skill = plugin_dir / "SKILL.md"
    sub_skills = sorted((plugin_dir / "skills").glob("*/SKILL.md"))

    if not report.check(
        not (root_skill.is_file() and sub_skills),
        f"{name}: Root-SKILL.md und skills/ gleichzeitig — die beiden Muster nicht mischen",
    ):
        return

    if root_skill.is_file():
        frontmatter = read_frontmatter(root_skill)
        if report.check(frontmatter is not None, f"{name}: SKILL.md ohne Frontmatter"):
            # Ohne name: leitet Claude Code den Befehl aus dem Cache-Versionsverzeichnis
            # ab und der Skill heißt /name:1-0-0 statt /name.
            report.check(
                frontmatter.get("name") == name,
                f"{name}: Root-SKILL.md braucht name: {name} (ist {frontmatter.get('name')!r})",
            )
            report.check(bool(frontmatter.get("description")), f"{name}: SKILL.md ohne description")
        check_skill_paths(report, root_skill)
        return

    for skill_file in sub_skills:
        frontmatter = read_frontmatter(skill_file)
        if report.check(frontmatter is not None, f"{rel(skill_file)}: ohne Frontmatter"):
            # Der Unterordnername ist der Befehl; ein name: würde ihn still ersetzen.
            report.check("name" not in frontmatter, f"{rel(skill_file)}: Sub-Skill trägt name:")
            report.check(bool(frontmatter.get("description")), f"{rel(skill_file)}: ohne description")
        check_skill_paths(report, skill_file)

    hooks = plugin_dir / "hooks" / "hooks.json"
    report.check(
        bool(sub_skills) or hooks.is_file(),
        f"{name}: weder SKILL.md noch skills/ noch hooks/hooks.json",
    )


def check_marketplace(report: Report, plugin_dirs: list[Path]) -> None:
    catalog = read_json(MARKETPLACE_FILE)
    entries = catalog.get("plugins", [])
    listed = {entry.get("name") for entry in entries}
    on_disk = {p.name for p in plugin_dirs}

    for missing in sorted(on_disk - listed):
        report.fail(f"{missing}: liegt unter plugins/, fehlt aber in marketplace.json")
    for stale in sorted(listed - on_disk):
        report.fail(f"{stale}: steht in marketplace.json, hat aber keinen Ordner unter plugins/")

    for entry in entries:
        source = entry.get("source", "")
        report.check(
            source == f"./plugins/{entry.get('name')}",
            f"{entry.get('name')}: source {source!r} passt nicht zum Plugin-Ordner",
        )
        report.check(bool(entry.get("description")), f"{entry.get('name')}: Katalogeintrag ohne description")


def git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=REPO_ROOT, capture_output=True, text=True, check=True
    ).stdout.strip()


def check_release_gate(report: Report, base_ref: str) -> None:
    """Geänderte Plugins brauchen Versions-Bump und CHANGELOG-Eintrag.

    Neue und gelöschte Plugins sind ausgenommen — dort gibt es keine Vorversion,
    gegen die sich ein Bump prüfen ließe.
    """
    changed = git("diff", "--name-only", f"{base_ref}...HEAD").splitlines()
    touched = {
        Path(line).parts[1]
        for line in changed
        if line.startswith("plugins/") and len(Path(line).parts) > 1
    }
    changelog = CHANGELOG_FILE.read_text(encoding="utf-8")

    for name in sorted(touched):
        manifest_file = PLUGINS_DIR / name / PLUGIN_MANIFEST
        if not manifest_file.is_file():
            continue  # gelöscht

        try:
            base_manifest = json.loads(git("show", f"{base_ref}:plugins/{name}/{PLUGIN_MANIFEST}"))
        except subprocess.CalledProcessError:
            continue  # neu

        version = read_json(manifest_file).get("version")
        if not report.check(
            version != base_manifest.get("version"),
            f"{name}: geändert, aber version steht weiter auf {version} — /plugin update zieht das nicht",
        ):
            continue
        report.check(
            f"[{version}]" in changelog,
            f"{name}: version {version} hat keinen Eintrag in CHANGELOG.md",
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--release-gate",
        metavar="BASE_REF",
        help="zusätzlich prüfen, ob geänderte Plugins gebumpt und im Changelog vermerkt sind",
    )
    args = parser.parse_args()

    report = Report()
    plugin_dirs = sorted(p for p in PLUGINS_DIR.iterdir() if p.is_dir())

    for plugin_dir in plugin_dirs:
        check_plugin(report, plugin_dir)
    check_marketplace(report, plugin_dirs)
    if args.release_gate:
        check_release_gate(report, args.release_gate)

    if report.errors:
        for error in report.errors:
            print(f"FEHLER  {error}", file=sys.stderr)
        print(f"\n{len(report.errors)} Problem(e) gefunden.", file=sys.stderr)
        return 1

    print(f"OK — {len(plugin_dirs)} Plugins geprüft.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

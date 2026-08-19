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

# Zwei Manifeste, weil zwei Ökosysteme: Claude Code liest ausschließlich
# .claude-plugin/plugin.json, der Agent-Plugins-Standard ausschließlich das im
# Plugin-Root. Sie müssen inhaltlich übereinstimmen — siehe check_manifests.
STANDARD_MANIFEST = Path("plugin.json")
CLAUDE_MANIFEST = Path(".claude-plugin") / "plugin.json"

AGENT_PLUGINS_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
# Schema 1.0.0 ist geschlossen (additionalProperties: false); alles
# Client-Spezifische gehört unter "extensions".
STANDARD_FIELDS = {
    "$schema", "name", "version", "description", "author",
    "homepage", "repository", "license", "keywords", "extensions",
}
STANDARD_NAME = re.compile(r"^(?!.*(?:--|\.\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$")
SHARED_FIELDS = ("name", "version", "description")

# ${CLAUDE_SKILL_DIR} zeigt auf das Verzeichnis der SKILL.md. Ein ../ darin
# verlässt das Plugin und bricht nach der Installation, weil Plugins in einen
# Cache kopiert werden.
SKILL_DIR_PATH = re.compile(r"\$\{CLAUDE_SKILL_DIR\}(/[^\s`)\"]*)")
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


def check_manifests(report: Report, plugin_dir: Path) -> dict | None:
    """Beide Manifeste vorhanden, standardkonform und untereinander gleich."""
    name = plugin_dir.name
    standard_file = plugin_dir / STANDARD_MANIFEST
    claude_file = plugin_dir / CLAUDE_MANIFEST

    ok = report.check(standard_file.is_file(), f"{name}: {STANDARD_MANIFEST} fehlt (Agent-Plugins-Standard)")
    ok &= report.check(claude_file.is_file(), f"{name}: {CLAUDE_MANIFEST} fehlt (Claude Code lädt sonst nicht)")
    if not ok:
        return None

    standard = read_json(standard_file)
    claude = read_json(claude_file)

    report.check(
        standard.get("$schema") == AGENT_PLUGINS_SCHEMA,
        f"{name}: plugin.json $schema muss {AGENT_PLUGINS_SCHEMA} sein",
    )
    for field in sorted(set(standard) - STANDARD_FIELDS):
        report.fail(f"{name}: plugin.json Feld {field!r} ist im Schema 1.0.0 nicht erlaubt (gehört unter extensions)")
    report.check(
        bool(STANDARD_NAME.match(str(standard.get("name", "")))),
        f"{name}: plugin.json name {standard.get('name')!r} verletzt das Namensmuster des Standards",
    )

    for field in SHARED_FIELDS:
        report.check(
            standard.get(field) == claude.get(field),
            f"{name}: {field} läuft zwischen den beiden Manifesten auseinander "
            f"({standard.get(field)!r} vs. {claude.get(field)!r})",
        )

    report.check(claude.get("name") == name, f"{name}: plugin.json name muss dem Ordnernamen entsprechen")
    report.check(bool(SEMVER.match(str(claude.get("version", "")))), f"{name}: version {claude.get('version')!r} ist kein Semver")
    report.check(bool(claude.get("description")), f"{name}: plugin.json ohne description")
    return claude


def check_skills(report: Report, plugin_dir: Path) -> set[str]:
    """Jeder Skill trägt seinen Ordnernamen — daraus entsteht sein Befehl."""
    name = plugin_dir.name
    skills = sorted(p for p in (plugin_dir / "skills").glob("*/SKILL.md"))

    if not report.check(skills, f"{name}: kein skills/<skill>/SKILL.md gefunden"):
        return set()
    report.check(
        not (plugin_dir / "SKILL.md").is_file(),
        f"{name}: SKILL.md im Plugin-Root — der Standard entdeckt nur skills/<skill>/SKILL.md",
    )

    for skill_file in skills:
        frontmatter = read_frontmatter(skill_file)
        if report.check(frontmatter is not None, f"{rel(skill_file)}: ohne Frontmatter"):
            # name: bestimmt das letzte Segment des Befehls. Weicht es vom
            # Ordnernamen ab, heißt der Skill anders, als sein Pfad verspricht.
            report.check(
                frontmatter.get("name") == skill_file.parent.name,
                f"{rel(skill_file)}: name: muss {skill_file.parent.name} sein (ist {frontmatter.get('name')!r})",
            )
            report.check(bool(frontmatter.get("description")), f"{rel(skill_file)}: ohne description")

        for path in SKILL_DIR_PATH.findall(skill_file.read_text(encoding="utf-8")):
            report.check(
                "../" not in path,
                f"{rel(skill_file)}: ${{CLAUDE_SKILL_DIR}}{path} zeigt aus dem Skill heraus",
            )

    return {s.parent.name for s in skills}


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


def changelog_section(changelog: str, name: str) -> str:
    """Der `## <plugin>`-Abschnitt allein.

    Global zu suchen würde den Eintrag eines anderen Plugins mit derselben
    Versionsnummer akzeptieren — seit alle Plugins bei 1.0.0 starten, bumpen sie
    häufig im Gleichschritt.
    """
    match = re.search(
        rf"^## {re.escape(name)}$(.*?)(?=^## |\Z)", changelog, re.MULTILINE | re.DOTALL
    )
    return match.group(1) if match else ""


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
        manifest_file = PLUGINS_DIR / name / CLAUDE_MANIFEST
        if not manifest_file.is_file():
            continue  # gelöscht

        try:
            base_manifest = json.loads(git("show", f"{base_ref}:plugins/{name}/{CLAUDE_MANIFEST}"))
        except subprocess.CalledProcessError:
            continue  # neu

        version = read_json(manifest_file).get("version")
        if not report.check(
            version != base_manifest.get("version"),
            f"{name}: geändert, aber version steht weiter auf {version} — /plugin update zieht das nicht",
        ):
            continue
        report.check(
            f"[{version}]" in changelog_section(changelog, name),
            f"{name}: version {version} hat keinen Eintrag im Abschnitt ## {name} der CHANGELOG.md",
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

    # Jeder Skill ist zusätzlich bar erreichbar (/ship neben /code:ship). Zwei
    # gleichnamige Skills teilen sich diesen baren Befehl — einer verliert.
    seen: dict[str, str] = {}
    for plugin_dir in plugin_dirs:
        if check_manifests(report, plugin_dir) is None:
            continue
        for skill in sorted(check_skills(report, plugin_dir)):
            if skill in seen:
                report.fail(f"{plugin_dir.name}: Skill {skill!r} heißt wie der in {seen[skill]!r} — der bare /{skill} wird mehrdeutig")
            seen[skill] = plugin_dir.name
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

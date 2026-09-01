#!/usr/bin/env python3
"""Prüft die Marktplatz-Invarianten aus AGENTS.md.

Lokal: uv run --with pyyaml scripts/validate.py
CI:    uv run --with pyyaml scripts/validate.py --release-gate origin/main
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
PLUGINS_DIR = REPO_ROOT / "plugins"
CLAUDE_MARKETPLACE_FILE = REPO_ROOT / ".claude-plugin" / "marketplace.json"
CODEX_MARKETPLACE_FILE = REPO_ROOT / ".agents" / "plugins" / "marketplace.json"
CHANGELOG_FILE = REPO_ROOT / "CHANGELOG.md"
README_FILE = REPO_ROOT / "README.md"

# Drei Manifeste verbinden denselben Skillbestand mit Agent Plugins, Claude Code
# sowie ChatGPT/Codex. Gemeinsame Identitätsfelder müssen übereinstimmen.
STANDARD_MANIFEST = Path("plugin.json")
CLAUDE_MANIFEST = Path(".claude-plugin") / "plugin.json"
CODEX_MANIFEST = Path(".codex-plugin") / "plugin.json"

AGENT_PLUGINS_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
# Schema 1.0.0 ist geschlossen (additionalProperties: false); alles
# Client-Spezifische gehört unter "extensions".
STANDARD_FIELDS = {
    "$schema", "name", "version", "description", "author",
    "homepage", "repository", "license", "keywords", "extensions",
}
STANDARD_NAME = re.compile(r"^(?!.*(?:--|\.\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$")
SHARED_FIELDS = ("name", "version", "description")
AGENT_SKILLS_FIELDS = {"name", "description", "license", "compatibility", "metadata", "argument-hint"}
CODEX_INTERFACE_FIELDS = {
    "displayName", "shortDescription", "longDescription", "developerName", "category",
}
CODEX_FIELDS = {
    "name", "version", "description", "author", "homepage", "repository", "license",
    "keywords", "skills", "mcpServers", "apps", "hooks", "interface", "bundledContentVariant",
}
CODEX_INTERFACE_ALLOWED = {
    *CODEX_INTERFACE_FIELDS, "capabilities", "defaultPrompt", "brandColor", "brandColorDark", "websiteURL",
    "privacyPolicyURL", "termsOfServiceURL", "supportURL", "composerIcon", "logo", "logoDark", "screenshots",
}
CLIENT_SPECIFIC_TEXT = ("${CLAUDE_SKILL_DIR}", "$ARGUMENTS", "AskUserQuestion")

# Agent Skills referenzieren gebündelte Dateien relativ zum Skill-Root.
BUNDLED_PATH = re.compile(
    r"(?<![A-Za-z0-9_./-])((?:references|scripts|assets|examples)/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]*)"
)
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
    """Alle drei Manifeste vorhanden, valide und in Identitätsfeldern gleich."""
    name = plugin_dir.name
    standard_file = plugin_dir / STANDARD_MANIFEST
    claude_file = plugin_dir / CLAUDE_MANIFEST
    codex_file = plugin_dir / CODEX_MANIFEST

    ok = report.check(standard_file.is_file(), f"{name}: {STANDARD_MANIFEST} fehlt (Agent-Plugins-Standard)")
    ok &= report.check(claude_file.is_file(), f"{name}: {CLAUDE_MANIFEST} fehlt (Claude Code lädt sonst nicht)")
    ok &= report.check(codex_file.is_file(), f"{name}: {CODEX_MANIFEST} fehlt (ChatGPT/Codex lädt sonst nicht)")
    if not ok:
        return None

    standard = read_json(standard_file)
    claude = read_json(claude_file)
    codex = read_json(codex_file)
    if not report.check(
        all(isinstance(manifest, dict) for manifest in (standard, claude, codex)),
        f"{name}: jedes Manifest muss ein JSON-Objekt enthalten",
    ):
        return None
    for field in sorted(set(codex) - CODEX_FIELDS):
        report.fail(f"{name}: Codex-Manifestfeld {field!r} ist nicht erlaubt")

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

    for field in (*SHARED_FIELDS, "author"):
        values = (standard.get(field), claude.get(field), codex.get(field))
        report.check(
            values[0] == values[1] == values[2],
            f"{name}: {field} läuft zwischen Standard-, Claude- und Codex-Manifest auseinander",
        )
    for field in ("homepage", "repository", "keywords"):
        report.check(
            standard.get(field) == codex.get(field),
            f"{name}: {field} läuft zwischen Standard- und Codex-Manifest auseinander",
        )

    for manifest_name, manifest in (("Claude", claude), ("Codex", codex)):
        report.check(manifest.get("name") == name, f"{name}: {manifest_name}-Manifestname passt nicht zum Ordner")
        report.check(
            bool(SEMVER.match(str(manifest.get("version", "")))),
            f"{name}: {manifest_name}-Version {manifest.get('version')!r} ist kein Semver",
        )
        report.check(bool(manifest.get("description")), f"{name}: {manifest_name}-Manifest ohne description")

    report.check(codex.get("skills") == "./skills/", f"{name}: Codex-Manifest skills muss './skills/' sein")
    report.check((plugin_dir / "skills").is_dir(), f"{name}: skills-Verzeichnis fehlt")
    for field in ("skills", "mcpServers", "apps", "hooks"):
        value = codex.get(field)
        paths = [value] if isinstance(value, str) else value if isinstance(value, list) and all(isinstance(item, str) for item in value) else []
        for path in paths:
            if not report.check(path.startswith("./"), f"{name}: Codex-{field}-Pfad muss mit './' beginnen"):
                continue
            resolved = (plugin_dir / path.removeprefix("./")).resolve()
            try:
                resolved.relative_to(plugin_dir.resolve())
                contained = True
            except ValueError:
                contained = False
            report.check(contained and resolved.exists(), f"{name}: Codex-{field}-Pfad {path!r} fehlt oder verlässt das Plugin")
    interface = codex.get("interface")
    if report.check(isinstance(interface, dict), f"{name}: Codex-Manifest ohne interface-Objekt"):
        for field in sorted(set(interface) - CODEX_INTERFACE_ALLOWED):
            report.fail(f"{name}: Codex-interface-Feld {field!r} ist nicht erlaubt")
        for field in sorted(CODEX_INTERFACE_FIELDS):
            report.check(bool(interface.get(field)), f"{name}: Codex-interface.{field} fehlt")
        capabilities = interface.get("capabilities")
        report.check(
            isinstance(capabilities, list) and all(isinstance(value, str) for value in capabilities),
            f"{name}: Codex-interface.capabilities muss ein String-Array sein",
        )
        prompts = interface.get("defaultPrompt")
        report.check(
            isinstance(prompts, list)
            and 1 <= len(prompts) <= 3
            and all(isinstance(prompt, str) and 0 < len(prompt) <= 128 for prompt in prompts),
            f"{name}: Codex-interface.defaultPrompt braucht 1-3 Strings mit höchstens 128 Zeichen",
        )
    return standard


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
            for field in sorted(set(frontmatter) - AGENT_SKILLS_FIELDS):
                report.fail(f"{rel(skill_file)}: nicht-portables Frontmatter-Feld {field!r}")
            # name: bestimmt das letzte Segment des Befehls. Weicht es vom
            # Ordnernamen ab, heißt der Skill anders, als sein Pfad verspricht.
            report.check(
                frontmatter.get("name") == skill_file.parent.name,
                f"{rel(skill_file)}: name: muss {skill_file.parent.name} sein (ist {frontmatter.get('name')!r})",
            )
            report.check(bool(frontmatter.get("description")), f"{rel(skill_file)}: ohne description")
            policy_file = skill_file.parent / "agents" / "openai.yaml"
            explicit_only = str(frontmatter.get("description", "")).startswith("Nur bei ausdrücklichem Nutzerwunsch")
            if explicit_only:
                report.check(policy_file.is_file(), f"{rel(skill_file)}: expliziter Skill ohne agents/openai.yaml")
            if policy_file.is_file():
                policy_data = yaml.safe_load(policy_file.read_text(encoding="utf-8"))
                policy = policy_data.get("policy") if isinstance(policy_data, dict) else None
                report.check(
                    isinstance(policy, dict) and policy.get("allow_implicit_invocation") is False,
                    f"{rel(policy_file)}: allow_implicit_invocation muss false sein",
                )

        for markdown_file in sorted(skill_file.parent.rglob("*.md")):
            text = markdown_file.read_text(encoding="utf-8")
            for token in CLIENT_SPECIFIC_TEXT:
                report.check(token not in text, f"{rel(markdown_file)}: client-spezifischer Text {token!r}")
            for relative_path in sorted(set(BUNDLED_PATH.findall(text))):
                if not report.check(
                    ".." not in PurePosixPath(relative_path).parts,
                    f"{rel(markdown_file)}: Bundle-Pfad {relative_path!r} zeigt aus dem Skill heraus",
                ):
                    continue
                bundled_path = skill_file.parent / relative_path
                try:
                    bundled_path.resolve().relative_to(skill_file.parent.resolve())
                except ValueError:
                    report.fail(f"{rel(markdown_file)}: Bundle-Pfad {relative_path!r} löst außerhalb des Skills auf")
                    continue
                if relative_path.endswith("/"):
                    exists = bundled_path.is_dir()
                    expected = "Verzeichnis"
                elif bundled_path.suffix:
                    exists = bundled_path.is_file()
                    expected = "Datei"
                else:
                    exists = bundled_path.exists()
                    expected = "Pfad"
                report.check(
                    exists,
                    f"{rel(markdown_file)}: Bundle-Pfad {relative_path!r} existiert nicht oder ist nicht vom Typ {expected}",
                )

    return {s.parent.name for s in skills}


def check_marketplaces(report: Report, plugin_dirs: list[Path]) -> None:
    """Prüft beide Marketplace-Kataloge gegen die Pluginordner."""
    claude_catalog = read_json(CLAUDE_MARKETPLACE_FILE)
    codex_catalog = read_json(CODEX_MARKETPLACE_FILE)
    if not report.check(
        isinstance(claude_catalog, dict) and isinstance(codex_catalog, dict),
        "Beide Marketplaces müssen JSON-Objekte enthalten",
    ):
        return
    claude_entries = claude_catalog.get("plugins", [])
    codex_entries = codex_catalog.get("plugins", [])
    if not report.check(
        isinstance(claude_entries, list) and isinstance(codex_entries, list),
        "Beide Marketplaces brauchen ein plugins-Array",
    ):
        return
    if not report.check(
        all(isinstance(entry, dict) for entry in (*claude_entries, *codex_entries)),
        "Jeder Marketplace-Eintrag muss ein Objekt sein",
    ):
        return
    claude_names = [entry.get("name") for entry in claude_entries]
    codex_names = [entry.get("name") for entry in codex_entries]
    listed = set(claude_names)
    on_disk = {p.name for p in plugin_dirs}

    report.check(claude_catalog.get("name") == codex_catalog.get("name") == "labi", "Marketplace-Name muss in beiden Katalogen 'labi' sein")
    report.check(claude_names == codex_names, "Claude- und Codex-Marketplace haben unterschiedliche Reihenfolge oder Einträge")
    report.check(len(claude_names) == len(set(claude_names)), "Marketplace enthält doppelte Plugin-Namen")
    for missing in sorted(on_disk - listed):
        report.fail(f"{missing}: liegt unter plugins/, fehlt aber in den Marketplaces")
    for stale in sorted(listed - on_disk):
        report.fail(f"{stale}: steht im Marketplace, hat aber keinen Ordner unter plugins/")

    for entry in claude_entries:
        name = entry.get("name")
        source = entry.get("source", "")
        report.check(
            source == f"./plugins/{name}",
            f"{name}: Claude-source {source!r} passt nicht zum Plugin-Ordner",
        )
        report.check(bool(entry.get("description")), f"{name}: Claude-Katalogeintrag ohne description")
        manifest_file = PLUGINS_DIR / str(name) / STANDARD_MANIFEST
        if name in on_disk and manifest_file.is_file():
            manifest_description = read_json(manifest_file).get("description")
            report.check(entry.get("description") == manifest_description, f"{name}: Katalog- und Manifestbeschreibung laufen auseinander")

    installations = {"NOT_AVAILABLE", "AVAILABLE", "INSTALLED_BY_DEFAULT"}
    authentications = {"ON_INSTALL", "ON_USE"}
    catalog_interface = codex_catalog.get("interface")
    report.check(isinstance(catalog_interface, dict), "Codex-Marketplace ohne interface-Objekt")
    if isinstance(catalog_interface, dict):
        report.check(bool(catalog_interface.get("displayName")), "Codex-Marketplace ohne interface.displayName")
    for entry in codex_entries:
        name = entry.get("name")
        source = entry.get("source")
        expected_path = f"./plugins/{name}"
        report.check(
            isinstance(source, dict) and source.get("source") == "local" and source.get("path") == expected_path,
            f"{name}: Codex-source muss local mit path {expected_path!r} sein",
        )
        if isinstance(source, dict) and isinstance(source.get("path"), str):
            source_path = (REPO_ROOT / source["path"].removeprefix("./")).resolve()
            try:
                source_path.relative_to(REPO_ROOT.resolve())
                contained = source_path == (PLUGINS_DIR / str(name)).resolve()
            except ValueError:
                contained = False
            report.check(contained, f"{name}: Codex-source.path verlässt den erwarteten Plugin-Ordner")
        policy = entry.get("policy")
        report.check(isinstance(policy, dict), f"{name}: Codex-Marketplace ohne policy")
        if isinstance(policy, dict):
            report.check(policy.get("installation") in installations, f"{name}: ungültige installation-Policy")
            report.check(policy.get("authentication") in authentications, f"{name}: ungültige authentication-Policy")
        report.check(bool(entry.get("category")), f"{name}: Codex-Marketplace ohne category")


def check_readme(report: Report, skill_names: set[str]) -> None:
    """Stellt sicher, dass der Nutzerkatalog jeden Skill nennt."""
    readme = README_FILE.read_text(encoding="utf-8")
    for skill_name in sorted(skill_names):
        report.check(skill_name in readme, f"README.md erwähnt Skill {skill_name!r} nicht")


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
        manifest_file = PLUGINS_DIR / name / STANDARD_MANIFEST
        if not manifest_file.is_file():
            try:
                git("show", f"{base_ref}:plugins/{name}/{STANDARD_MANIFEST}")
            except subprocess.CalledProcessError:
                continue
            marketplace_notes = changelog_section(changelog, "Marketplace")
            report.check(
                re.search(rf"\b{re.escape(name)}\b.*\b(entfernt|gelöscht)\b", marketplace_notes, re.IGNORECASE) is not None,
                f"{name}: gelöscht, aber ohne Entfernungseintrag im Abschnitt ## Marketplace",
            )
            continue

        try:
            base_manifest = json.loads(git("show", f"{base_ref}:plugins/{name}/{STANDARD_MANIFEST}"))
        except subprocess.CalledProcessError:
            version = read_json(manifest_file).get("version")
            report.check(
                bool(SEMVER.match(str(version))) and f"[{version}]" in changelog_section(changelog, name),
                f"{name}: neues Plugin ohne initiale Semver und Changelog-Eintrag",
            )
            continue

        version = read_json(manifest_file).get("version")
        base_version = base_manifest.get("version")
        version_tuple = tuple(map(int, str(version).split("."))) if SEMVER.match(str(version)) else None
        base_tuple = tuple(map(int, str(base_version).split("."))) if SEMVER.match(str(base_version)) else None
        if not report.check(
            version_tuple is not None and base_tuple is not None and version_tuple > base_tuple,
            f"{name}: geändert, aber version {version!r} ist nicht höher als {base_version!r}",
        ):
            continue
        report.check(
            f"[{version}]" in changelog_section(changelog, name),
            f"{name}: version {version} hat keinen Eintrag im Abschnitt ## {name} der CHANGELOG.md",
        )


def main() -> int:
    """Führt Repo- und optionale Release-Prüfungen aus."""
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
    skill_names: set[str] = set()
    for plugin_dir in plugin_dirs:
        check_manifests(report, plugin_dir)
        for skill in sorted(check_skills(report, plugin_dir)):
            skill_names.add(skill)
            if skill in seen:
                report.fail(f"{plugin_dir.name}: Skill {skill!r} heißt wie der in {seen[skill]!r} — der bare /{skill} wird mehrdeutig")
            seen[skill] = plugin_dir.name
    check_marketplaces(report, plugin_dirs)
    check_readme(report, skill_names)
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

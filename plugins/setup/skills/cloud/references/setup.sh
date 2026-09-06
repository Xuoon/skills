#!/usr/bin/env bash
# Vorlage für .github/scripts/setup.sh. Ein Einstieg für alle Clients.
# Linux gilt als Cloud-Container und erhält fehlende Toolchains; andere Systeme
# werden nur geprüft. Keine Server, keine Deploys, keine Backend-Codegen.
# Projektspezifische Stellen sind mit "Projekt:" markiert.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
node_major="$(tr -d '[:space:]' < .node-version)"
[[ "$node_major" =~ ^[0-9]+$ ]] || { echo "Ungültige .node-version" >&2; exit 1; }
cloud=false
[[ "$(uname -s)" == Linux ]] && cloud=true
node_dir="$HOME/.local/toolchains/node-$node_major"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
if $cloud; then
  # Projekt: weitere Toolchain-Pfade wie $HOME/.cargo/bin ergänzen.
  export PATH="$node_dir/bin:$BUN_INSTALL/bin:$PATH"
fi

as_root() { if [[ "$(id -u)" == 0 ]]; then "$@"; else sudo "$@"; fi; }
fetch() { curl --fail --silent --show-error --location --retry 3 --connect-timeout 10 "$@"; }
tmp=""
trap '[[ -n "$tmp" ]] && rm -rf -- "$tmp"' EXIT
download_dir() { [[ -n "$tmp" ]] || tmp="$(mktemp -d)"; }

# Systempakete: Cloud-Basisimages bringen nicht immer Entpacker und CA-Zertifikate mit.
if $cloud; then
  # Projekt: native Build-Abhängigkeiten ergänzen, etwa build-essential libssl-dev pkg-config.
  packages=(ca-certificates curl unzip xz-utils)
  missing=()
  for package in "${packages[@]}"; do
    [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" == 'install ok installed' ]] || missing+=("$package")
  done
  if ((${#missing[@]})); then
    as_root apt-get update -qq
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
  fi
fi

# Node aus .node-version
if [[ "$(node --version 2>/dev/null || true)" != "v$node_major."* ]]; then
  $cloud || { printf 'Node.js %s wird benötigt (siehe .node-version).\n' "$node_major" >&2; exit 1; }
  case "$(uname -m)" in
    x86_64) arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Nicht unterstützte Architektur." >&2; exit 1 ;;
  esac
  download_dir
  base="https://nodejs.org/dist/latest-v$node_major.x"
  fetch "$base/SHASUMS256.txt" -o "$tmp/SHASUMS256.txt"
  archive="$(awk -v arch="$arch" '$2 ~ ("^node-v[0-9.]+-linux-" arch "[.]tar[.]xz$") {print $2}' "$tmp/SHASUMS256.txt")"
  [[ -n "$archive" && "$archive" != *$'\n'* ]] || { echo "Node-Download nicht eindeutig." >&2; exit 1; }
  fetch "$base/$archive" -o "$tmp/$archive"
  (cd "$tmp" && awk -v archive="$archive" '$2 == archive' SHASUMS256.txt | sha256sum --check --strict)
  mkdir -p "$tmp/node" "$(dirname "$node_dir")"
  tar -xJf "$tmp/$archive" --strip-components=1 -C "$tmp/node"
  rm -rf "$node_dir"
  mv "$tmp/node" "$node_dir"
fi

# Bun aus packageManager
manager="$(node -p 'require("./package.json").packageManager')"
[[ "$manager" =~ ^bun@[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "packageManager muss eine exakte Bun-Version nennen." >&2; exit 1; }
bun_version="${manager#bun@}"
if [[ "$(bun --version 2>/dev/null || true)" != "$bun_version" ]]; then
  $cloud || { printf 'Bun %s wird benötigt (siehe package.json).\n' "$bun_version" >&2; exit 1; }
  download_dir
  fetch https://bun.sh/install -o "$tmp/install-bun.sh"
  bash "$tmp/install-bun.sh" "bun-v$bun_version"
  hash -r
  [[ "$(bun --version)" == "$bun_version" ]] || { echo "Falsche Bun-Version nach Installation." >&2; exit 1; }
fi

# Projekt: weitere Toolchains nur in der Cloud, Version aus der Projektdatei.
# if $cloud; then
#   if ! command -v rustup >/dev/null; then
#     download_dir
#     fetch https://sh.rustup.rs -o "$tmp/rustup-init.sh"
#     sh "$tmp/rustup-init.sh" -y --profile minimal --default-toolchain none --no-modify-path
#   fi
#   (cd packages/agent && rustup toolchain install --no-self-update)
# fi

# Exports überleben Snapshots nicht; neue nicht-interaktive Shells finden die
# Programme über /usr/local/bin, Claude-Sessions über CLAUDE_ENV_FILE.
if $cloud; then
  as_root mkdir -p /usr/local/bin
  # Projekt: weitere Programme wie rustup cargo rustc anhängen.
  for program in node npm npx bun; do
    program_path="$(command -v "$program" || true)"
    if [[ -n "$program_path" && "$program_path" != "/usr/local/bin/$program" ]]; then
      as_root ln -sfn "$program_path" "/usr/local/bin/$program"
    fi
  done
fi
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  printf 'export PATH=%q\nexport BUN_INSTALL=%q\n' "$PATH" "$BUN_INSTALL" >> "$CLAUDE_ENV_FILE"
fi

NODE_ENV=development bun install --frozen-lockfile
# Projekt: weitere gecachte Downloads, etwa (cd packages/agent && cargo fetch --locked).
printf 'Setup abgeschlossen: Node %s, Bun %s.\n' "$(node --version)" "$bun_version"

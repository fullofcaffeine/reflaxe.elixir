#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HAXERC_PATH="${ROOT_DIR}/.haxerc"

HAXE5_VERSION="${HAXE5_VERSION:-nightly}"

say() { echo "[haxe5-smoke] $*"; }

restore_haxerc() {
  if [[ -n "${HAXERC_BACKUP_PATH:-}" && -f "${HAXERC_BACKUP_PATH}" ]]; then
    cp "${HAXERC_BACKUP_PATH}" "${HAXERC_PATH}"
    rm -f "${HAXERC_BACKUP_PATH}"
  fi
}

trap restore_haxerc EXIT INT TERM

say "Repo: ${ROOT_DIR}"
say "Using Haxe 5 version: ${HAXE5_VERSION}"

HAXERC_BACKUP_PATH="$(mktemp -t reflaxe-elixir-haxerc.XXXXXX)"
cp "${HAXERC_PATH}" "${HAXERC_BACKUP_PATH}"

pushd "${ROOT_DIR}" >/dev/null

say "Downloading Haxe (${HAXE5_VERSION}) via lix..."
npx lix download haxe "${HAXE5_VERSION}"

say "Switching .haxerc to Haxe (${HAXE5_VERSION}) via lix (will restore after run)..."
npx lix use haxe "${HAXE5_VERSION}"

say "Haxe version:"
haxe -version

say "Running bounded smoke suite (syntax-only snapshots + Mix fast tests)..."
COMPARE_INTENDED=0 npm run test:quick
npm run test:mix-fast

say "OK"

popd >/dev/null

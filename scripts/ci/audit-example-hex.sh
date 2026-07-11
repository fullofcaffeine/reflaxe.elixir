#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

audit_deps_dir="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-hex-audit.XXXXXX")"
trap 'rm -rf "$audit_deps_dir"' EXIT

status=0
count=0
while IFS= read -r lockfile; do
  example_dir="${lockfile%/mix.lock}"
  count=$((count + 1))
  echo "[hex-audit] ${example_dir}"
  if ! (
    cd "$example_dir"
    export MIX_DEPS_PATH="$audit_deps_dir"
    mix deps.get --check-locked </dev/null >/dev/null
    mix hex.audit </dev/null
  ); then
    status=1
  fi
done < <(git ls-files 'examples/**/mix.lock' | sort)

if [[ "$count" -eq 0 ]]; then
  echo "[hex-audit] ERROR: no example mix.lock files found" >&2
  exit 1
fi

if [[ "$status" -ne 0 ]]; then
  echo "[hex-audit] ERROR: one or more example lockfiles have unacknowledged advisories" >&2
  exit "$status"
fi

echo "[hex-audit] OK: ${count} example lockfiles audited"

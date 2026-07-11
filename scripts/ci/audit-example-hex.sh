#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

status=0
count=0
while IFS= read -r lockfile; do
  example_dir="${lockfile%/mix.lock}"
  count=$((count + 1))
  echo "[hex-audit] ${example_dir}"
  if ! (cd "$example_dir" && mix hex.audit </dev/null); then
    status=1
  fi
done < <(rg --files examples -g 'mix.lock' | sort)

if [[ "$count" -eq 0 ]]; then
  echo "[hex-audit] ERROR: no example mix.lock files found" >&2
  exit 1
fi

if [[ "$status" -ne 0 ]]; then
  echo "[hex-audit] ERROR: one or more example lockfiles have unacknowledged advisories" >&2
  exit "$status"
fi

echo "[hex-audit] OK: ${count} example lockfiles audited"

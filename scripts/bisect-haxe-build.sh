#!/usr/bin/env bash
set -euo pipefail

# Purpose: git-bisect test for cold Haxe→Elixir server build speed
# Good = completes under 10s (likely healthy); Bad = exceeds 10s (regression)

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/examples/todo-app"

cd "$APP_DIR"

# Clean server output to avoid cached artifacts affecting timings
rm -rf lib >/dev/null 2>&1 || true

# Always measure a cold direct compiler run (no compile-server) for bisect
export HAXE_USE_SERVER=0

# Use system timeout for cross-commit stability (exists on this machine)
if timeout 10s bash -lc 'haxe build-server.hxml >/dev/null 2>&1'; then
  # Finished within 10s → good
  exit 0
else
  # Timed out or failed → bad
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

with_timeout() {
  local seconds="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "${seconds}s" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "${seconds}s" "$@"
  else
    # Fallback: run in background and kill after N seconds
    ( "$@" & echo $! > /tmp/_bisect_cmd.pid ) || true
    local pid
    pid="$(cat /tmp/_bisect_cmd.pid 2>/dev/null || true)"
    ( sleep "${seconds}"; kill -TERM "${pid}" 2>/dev/null || true ) &
    wait "${pid}" 2>/dev/null || true
  fi
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${repo_root}/examples/todo-app" || exit 125

# Basic sanity: mix exists?
if ! command -v mix >/dev/null 2>&1; then
  echo "mix not found" >&2
  exit 125
fi

# Install deps quickly (bounded) on first run of this worktree state
if [ ! -d deps ]; then
  with_timeout 120 mix deps.get >/dev/null 2>&1 || exit 125
fi

# Clean previous build artifacts to force Haxe recompilation
rm -rf lib _build tmp || true
mkdir -p tmp || true

# Start server with outer timeout; classify GOOD if Haxe outputs lib/*.ex within 10s
# Use a background run to allow polling lib
( with_timeout 20 mix phx.server > tmp/bisect-phx.log 2>&1 & echo $! > tmp/bisect-phx.pid ) || true
pid="$(cat tmp/bisect-phx.pid 2>/dev/null || true)"

# Poll for generated .ex files up to 10 seconds
threshold=10
ok=0
for _ in $(seq 1 "$threshold"); do
  cnt=$(find lib -type f -name '*.ex' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${cnt:-0}" -ge 5 ]; then
    ok=1
    break
  fi
  sleep 1
done

# Cleanup background server
if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
  kill -TERM "$pid" 2>/dev/null || true
  sleep 1
  kill -KILL "$pid" 2>/dev/null || true
fi

# Decide
if [ "$ok" -eq 1 ]; then
  # GOOD: compiled >=5 .ex within 10s
  exit 0
else
  # BAD: did not compile quickly
  echo "[bisect] Haxe did not generate lib/*.ex within 10s" >&2
  tail -n 120 tmp/bisect-phx.log >&2 || true
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

# Classify a commit as GOOD (0), BAD (1: hangs/slow), or SKIP (125: unrelated failure)
# by timing mix compile (which includes the Haxe→Elixir server build).
#
# Why compile and not phx.server?
# - mix compile triggers the exact Haxe compile step without starting the server,
#   so it’s deterministic and won’t block the terminal. It’s the same bottleneck
#   you see before Phoenix boots. We confirm with phx.server after locating the culprit.
#
# Config (override via env):
#   APP_DIR   – Phoenix app dir (default: examples/todo-app)
#   LIMIT     – timeout for compilation (default: 45s)
#   MIX_ENV   – mix env (default: dev)
#
# Exit codes expected by `git bisect run`:
#   0   good (no hang)
#   1   bad  (timeout/hang)
#   125 skip (compile error or unrelated failure)

APP_DIR=${APP_DIR:-examples/todo-app}
LIMIT=${LIMIT:-45s}
export MIX_ENV=${MIX_ENV:-dev}

is_timeout() { test "$1" = "124"; }

# Ensure a clean tree for each step, but keep caches and node_modules for speed.
git reset --hard -q || true
git clean -fdq -- $APP_DIR/lib $APP_DIR/tmp 2>/dev/null || true

if [ ! -f "$APP_DIR/mix.exs" ]; then
  exit 125
fi

pushd "$APP_DIR" >/dev/null

# Try a bounded compile; avoid deps churn across commits.
if timeout "$LIMIT" mix compile --force --no-deps-check > /tmp/bisect-mix-compile.out 2>&1; then
  popd >/dev/null
  exit 0
else
  code=$?
  popd >/dev/null
  if is_timeout "$code"; then
    # BAD: compile exceeded limit (hang/very slow)
    exit 1
  fi
  # Non-timeout failure: skip (could be deps shape drift or transient)
  exit 125
fi


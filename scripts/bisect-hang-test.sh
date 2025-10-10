#!/usr/bin/env bash
set -euo pipefail

# Bisect test: detect hang/idle during todo-app Haxe build.
# Returns:
#  - 1 (bad) if build times out (hang/idle)
#  - 0 (good) if build exits before timeout (success or fast failure)
#  - 125 (skip) if test cannot run on this commit (missing dirs)

ROOT_DIR=$(git rev-parse --show-toplevel)
APP_DIR="$ROOT_DIR/examples/todo-app"
LOG_FILE="/tmp/bisect_haxe_todo.log"
TIMEOUT_SEC=${TIMEOUT_SEC:-90}

if [[ ! -d "$APP_DIR" ]]; then
  echo "[bisect] examples/todo-app missing; skipping commit" >&2
  exit 125
fi

cd "$APP_DIR"

# Choose build target: prefer build-server.hxml, else try Router-only compile.
if [[ -f build-server.hxml ]]; then
  CMD=(npx haxe build-server.hxml -D no-traces --times)
else
  # Fallback: attempt a minimal compile of Router only with typical flags
  if [[ -d src_haxe ]]; then
    CMD=(npx haxe -cp ../../src -cp ../../std -lib reflaxe -cp src_haxe -cp src_haxe/server -cp src_haxe/shared -D elixir_output=lib -D reflaxe_runtime -D no-utf16 -D app_name=TodoApp -dce full --macro "exclude('client')" -D reflaxe.elixir=0.1.0 --macro "reflaxe.elixir.CompilerInit.Start()" TodoAppRouter)
  else
    echo "[bisect] No build-server.hxml and no src_haxe; skipping commit" >&2
    exit 125
  fi
fi

# Run with timeout; classify 124 as hang/bad, anything else as good.
echo "[bisect] Running: timeout ${TIMEOUT_SEC}s ${CMD[*]}" >&2
set +e
timeout "$TIMEOUT_SEC" "${CMD[@]}" > "$LOG_FILE" 2>&1
EC=$?
set -e

if [[ $EC -eq 124 ]]; then
  echo "[bisect] TIMEOUT (hang) detected" >&2
  tail -n 50 "$LOG_FILE" >&2 || true
  exit 1
fi

echo "[bisect] Completed without timeout (good). Exit code=$EC" >&2
exit 0


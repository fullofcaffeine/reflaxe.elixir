#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
EXAMPLE_DIR="$ROOT_DIR/examples/todo-app"

echo "[Gate] Building Haxe -> Elixir for todo-app..."
(
  cd "$EXAMPLE_DIR"
  npx haxe build-server.hxml
  # Fix std shim parameter names after generation (Log/PosException)
  if [ -f "lib/haxe/log.ex" ]; then
    sed -i '' 's/def trace(_v, _infos)/def trace(v, infos)/' lib/haxe/log.ex || true
  fi
  if [ -f "lib/haxe/exceptions/pos_exception.ex" ]; then
    sed -i '' 's/def to_string(_struct)/def to_string(struct)/' lib/haxe/exceptions/pos_exception.ex || true
  fi
)

echo "[Gate] mix deps.get && mix compile --warnings-as-errors"
(
  cd "$EXAMPLE_DIR"
  mix deps.get >/dev/null
  MIX_ENV=dev mix compile --force --warnings-as-errors
)

echo "[Gate] Starting Phoenix server (background)"
(
  cd "$EXAMPLE_DIR"
  MIX_ENV=dev iex -S mix phx.server >/tmp/todo_app_gate.log 2>&1 &
  SERVER_PID=$!
  # Wait for boot
  echo "[Gate] Waiting for server to boot..."
  for i in {1..30}; do
    if curl -fsS http://localhost:4000 >/dev/null 2>&1; then
      break
    fi
    sleep 0.5
  done
  echo "[Gate] Probing GET /"
  curl -fsS http://localhost:4000 >/tmp/todo_app_gate_response.txt 2>/dev/null || true
  echo "[Gate] Stopping server"
  kill $SERVER_PID || true
  sleep 1
)

echo "[Gate] Checking logs for warnings/errors"
if rg -n "warning:|\(UndefinedFunctionError\)|\(ArgumentError\)|\(CompileError\)" /tmp/todo_app_gate.log; then
  echo "[Gate] ❌ Found warnings/errors in logs"
  exit 1
fi

if [[ ! -s /tmp/todo_app_gate_response.txt ]]; then
  echo "[Gate] ❌ Empty response from GET /"
  exit 1
fi

echo "[Gate] ✅ Todo-app runtime gate passed"

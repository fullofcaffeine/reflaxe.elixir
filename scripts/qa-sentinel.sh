#!/usr/bin/env bash
set -euo pipefail

# QA Sentinel: Compile, run, curl /, assert zero warnings/errors
# Usage: scripts/qa-sentinel.sh [--app examples/todo-app] [--port 4001] [--keep-alive]
#
# --keep-alive: Do not kill the Phoenix server on exit. Prints PHX_PID and PORT so
#               external tools (e2e runners) can reuse the same background server.

APP_DIR="examples/todo-app"
PORT=4001
KEEP_ALIVE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APP_DIR="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --keep-alive) KEEP_ALIVE=1; shift 1 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

echo "[QA] Building Haxe → Elixir in $APP_DIR"
pushd "$APP_DIR" >/dev/null

# Generate .ex files (full server build to ensure all modules are regenerated)
npx -y haxe build-server.hxml

echo "[QA] Fetching deps and compiling with WAE"
MIX_ENV=dev mix deps.get
MIX_ENV=dev mix compile --warnings-as-errors

# Ensure no stale Phoenix server is occupying the target port (or default :4000)
for P in "$PORT" 4000; do
  if command -v lsof >/dev/null 2>&1; then
    PIDLIST=$(lsof -ti tcp:"$P" -sTCP:LISTEN || true)
    if [ -n "$PIDLIST" ]; then
      echo "[QA] Detected process on :$P → killing: $PIDLIST"
      kill -9 $PIDLIST >/dev/null 2>&1 || true
      sleep 0.5
    fi
  elif command -v ss >/dev/null 2>&1; then
    PIDS=$(ss -ltnp 2>/dev/null | awk -v p=":$P" '$4 ~ p {print $6}' | sed -E 's/.*pid=([0-9]+),.*/\1/' | sort -u)
    if [ -n "$PIDS" ]; then
      echo "[QA] Detected process on :$P → killing: $PIDS"
      kill -9 $PIDS >/dev/null 2>&1 || true
      sleep 0.5
    fi
  fi
done

echo "[QA] Starting server on :$PORT"
export PORT="$PORT"
MIX_ENV=dev mix phx.server >/tmp/qa-phx.log 2>&1 &
PHX_PID=$!
if [[ "$KEEP_ALIVE" -eq 0 ]]; then
  trap 'kill $PHX_PID >/dev/null 2>&1 || true' EXIT
fi

echo "[QA] Waiting for server..."
READY=0
for i in $(seq 1 60); do
  if curl -fsS "http://localhost:$PORT" >/dev/null 2>&1; then
    READY=1; break
  fi
  # If not ready, see if endpoint reported a different port
  DETECTED_PORT=$(grep -Eo 'http://localhost:[0-9]+' /tmp/qa-phx.log 2>/dev/null | tail -n1 | sed -E 's/.*:([0-9]+)/\1/' || true)
  if [[ -z "$DETECTED_PORT" ]]; then
    DETECTED_PORT=$(grep -Eo '127\.0\.0\.1:[0-9]+' /tmp/qa-phx.log 2>/dev/null | tail -n1 | sed -E 's/.*:([0-9]+)/\1/' || true)
  fi
  if [[ -n "$DETECTED_PORT" ]] && curl -fsS "http://localhost:$DETECTED_PORT" >/dev/null 2>&1; then
    PORT="$DETECTED_PORT"; READY=1; break
  fi
  sleep 0.5
done

if [[ "$READY" -ne 1 ]]; then
  echo "[QA] ❌ Server did not become ready"
  tail -n 100 /tmp/qa-phx.log || true
  exit 1
fi

echo "[QA] GET / (strict 2xx)"
if ! curl -fsS "http://localhost:$PORT/" >/tmp/qa-index.html 2>/dev/null; then
  echo "[QA] ❌ GET / did not return 2xx"
  tail -n 100 /tmp/qa-phx.log || true
  exit 1
fi

# Optional: probe /todos if route exists
curl -fsS "http://localhost:$PORT/todos" >/dev/null 2>&1 || true

# Scan logs for runtime errors
if command -v rg >/dev/null 2>&1; then
  if rg -n "(CompileError|UndefinedFunctionError|ArgumentError|FunctionClauseError|KeyError|RuntimeError|\(EXIT\)|\bError\b)" /tmp/qa-phx.log >/dev/null 2>&1; then
    echo "[QA] ❌ Runtime errors detected in logs"
    rg -n "(CompileError|UndefinedFunctionError|ArgumentError|FunctionClauseError|KeyError|RuntimeError|\(EXIT\)|\bError\b)" /tmp/qa-phx.log | tail -n 50
    exit 1
  fi
else
  if grep -E "CompileError|UndefinedFunctionError|ArgumentError|FunctionClauseError|KeyError|RuntimeError|\(EXIT\)|\bError\b" /tmp/qa-phx.log >/dev/null 2>&1; then
    echo "[QA] ❌ Runtime errors detected in logs"
    tail -n 50 /tmp/qa-phx.log
    exit 1
  fi
fi

echo "[QA] OK: build + runtime smoke passed with zero warnings (WAE)"

if [[ "$KEEP_ALIVE" -eq 1 ]]; then
  echo "[QA] KEEP-ALIVE enabled. Phoenix continues running."
  echo "PHX_PID=$PHX_PID"
  echo "PORT=$PORT"
fi
popd >/dev/null

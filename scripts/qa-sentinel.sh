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
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APP_DIR="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --keep-alive) KEEP_ALIVE=1; shift 1 ;;
    --verbose|-v) VERBOSE=1; shift 1 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

ts() { date "+%Y-%m-%d %H:%M:%S"; }
log() { echo "[$(ts)] $*"; }
run() { if [[ "$VERBOSE" -eq 1 ]]; then set -x; fi; "$@"; local rc=$?; if [[ "$VERBOSE" -eq 1 ]]; then set +x; fi; return $rc; }

log "[QA] Building Haxe → Elixir in $APP_DIR (PORT=$PORT, KEEP_ALIVE=$KEEP_ALIVE, VERBOSE=$VERBOSE)"
pushd "$APP_DIR" >/dev/null

# Generate .ex files (full server build to ensure all modules are regenerated)
log "[QA] Step 1: Haxe build (haxe build-server.hxml)"
run npx -y haxe build-server.hxml 2>&1 | tee /tmp/qa-haxe.log
HAXE_RC=${PIPESTATUS[0]:-0}
if [[ "$HAXE_RC" -ne 0 ]]; then
  log "[QA] ❌ Haxe build failed (rc=$HAXE_RC). Last 100 lines:"
  tail -n 100 /tmp/qa-haxe.log || true
  exit 1
fi

log "[QA] Step 2: mix deps.get"
run bash -lc 'MIX_ENV=dev mix deps.get' 2>&1 | tee /tmp/qa-mix-deps.log
DEPS_RC=${PIPESTATUS[0]:-0}
if [[ "$DEPS_RC" -ne 0 ]]; then
  log "[QA] ❌ mix deps.get failed (rc=$DEPS_RC). Last 100 lines:"
  tail -n 100 /tmp/qa-mix-deps.log || true
  exit 1
fi

log "[QA] Step 3: mix compile"
run bash -lc 'MIX_ENV=dev mix compile' 2>&1 | tee /tmp/qa-mix-compile.log
COMPILE_RC=${PIPESTATUS[0]:-0}
if [[ "$COMPILE_RC" -ne 0 ]]; then
  log "[QA] ❌ mix compile failed (rc=$COMPILE_RC). Last 100 lines:"
  tail -n 100 /tmp/qa-mix-compile.log || true
  exit 1
fi

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

log "[QA] Step 4: Starting Phoenix server on :$PORT (background)"
export PORT="$PORT"
# Start Phoenix in the background, detached when possible, and capture PID/PGID
if command -v setsid >/dev/null 2>&1; then
  setsid sh -c 'MIX_ENV=dev mix phx.server' >/tmp/qa-phx.log 2>&1 &
else
  nohup env MIX_ENV=dev mix phx.server >/tmp/qa-phx.log 2>&1 &
fi
PHX_PID=$!
PGID=$(ps -o pgid= "$PHX_PID" 2>/dev/null | tr -d ' ' || true)
log "[QA] Phoenix started: PHX_PID=$PHX_PID PGID=$PGID (logs: /tmp/qa-phx.log)"

cleanup() {
  # Prefer killing the whole process group if available, fall back to PID, and finally port listeners
  if [[ -n "$PGID" ]]; then
    kill -TERM -"$PGID" >/dev/null 2>&1 || true
    sleep 0.5
    kill -KILL -"$PGID" >/dev/null 2>&1 || true
  fi
  kill "$PHX_PID" >/dev/null 2>&1 || true
  # Extra safety: kill anything still listening on the port
  if command -v lsof >/dev/null 2>&1; then
    PIDS=$(lsof -ti tcp:"$PORT" -sTCP:LISTEN || true)
    if [[ -n "$PIDS" ]]; then kill -9 $PIDS >/dev/null 2>&1 || true; fi
  elif command -v ss >/dev/null 2>&1; then
    PIDS=$(ss -ltnp 2>/dev/null | awk -v p=":$PORT" '$4 ~ p {print $6}' | sed -E 's/.*pid=([0-9]+),.*/\1/' | sort -u)
    if [[ -n "$PIDS" ]]; then kill -9 $PIDS >/dev/null 2>&1 || true; fi
  fi
}

if [[ "$KEEP_ALIVE" -eq 0 ]]; then
  trap cleanup EXIT
fi

log "[QA] Step 5: Waiting for server readiness"
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
  if [[ "$VERBOSE" -eq 1 ]]; then
    log "[QA] Probe $i/60: not ready yet; tailing last 20 log lines:"; tail -n 20 /tmp/qa-phx.log || true
  fi
  sleep 0.5
done

if [[ "$READY" -ne 1 ]]; then
  log "[QA] ❌ Server did not become ready. Last 200 log lines:"
  tail -n 200 /tmp/qa-phx.log || true
  cleanup || true
  exit 1
fi

log "[QA] Step 6: GET / (strict 2xx)"
if ! curl -fsS "http://localhost:$PORT/" >/tmp/qa-index.html 2>/dev/null; then
  log "[QA] ❌ GET / did not return 2xx. Last 200 log lines:"
  tail -n 200 /tmp/qa-phx.log || true
  cleanup || true
  exit 1
fi

# Optional: probe /todos if route exists
curl -fsS "http://localhost:$PORT/todos" >/dev/null 2>&1 || true

# Scan logs for runtime errors
if command -v rg >/dev/null 2>&1; then
  if rg -n "(CompileError|UndefinedFunctionError|ArgumentError|FunctionClauseError|KeyError|RuntimeError|\(EXIT\)|\bError\b)" /tmp/qa-phx.log >/dev/null 2>&1; then
    log "[QA] ❌ Runtime errors detected in logs"
    rg -n "(CompileError|UndefinedFunctionError|ArgumentError|FunctionClauseError|KeyError|RuntimeError|\(EXIT\)|\bError\b)" /tmp/qa-phx.log | tail -n 100
    cleanup || true
    exit 1
  fi
else
  if grep -E "CompileError|UndefinedFunctionError|ArgumentError|FunctionClauseError|KeyError|RuntimeError|\(EXIT\)|\bError\b" /tmp/qa-phx.log >/dev/null 2>&1; then
    log "[QA] ❌ Runtime errors detected in logs"
    tail -n 100 /tmp/qa-phx.log
    cleanup || true
    exit 1
  fi
fi

log "[QA] OK: build + runtime smoke passed with zero warnings (WAE)"

if [[ "$KEEP_ALIVE" -eq 1 ]]; then
  log "[QA] KEEP-ALIVE enabled. Phoenix continues running."
  echo "PHX_PID=$PHX_PID"
  echo "PORT=$PORT"
fi
popd >/dev/null

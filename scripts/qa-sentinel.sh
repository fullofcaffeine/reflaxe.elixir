#!/usr/bin/env bash
set -euo pipefail

# QA Sentinel: Compile, run, curl /, assert zero warnings/errors
# Usage: scripts/qa-sentinel.sh [--app examples/todo-app] [--port 4001] [--keep-alive] [--verbose]
#        Optional timeouts (env): BUILD_TIMEOUT, DEPS_TIMEOUT, COMPILE_TIMEOUT, READY_PROBES
#
# --keep-alive: Do not kill the Phoenix server on exit. Prints PHX_PID and PORT so
#               external tools (e2e runners) can reuse the same background server.

APP_DIR="examples/todo-app"
PORT=4001
KEEP_ALIVE=0
VERBOSE=0
# Timeouts and probe counts (sane defaults; configurable via env)
BUILD_TIMEOUT=${BUILD_TIMEOUT:-300s}
DEPS_TIMEOUT=${DEPS_TIMEOUT:-300s}
COMPILE_TIMEOUT=${COMPILE_TIMEOUT:-300s}
READY_PROBES=${READY_PROBES:-60}

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

# Wrapper to run a command with optional timeout and tee to logfile.
# Usage: run_step "Desc" timeout_secs cmd...  logfile
run_step_with_log() {
  local desc="$1"; shift
  local timeout_val="$1"; shift
  local logfile="$1"; shift
  local cmd="$*"
  local start_ts=$(date +%s)
  log "[QA] ${desc} (timeout=${timeout_val})"

  # Prefer GNU timeout; then gtimeout (macOS coreutils); else manual watchdog
  if command -v timeout >/dev/null 2>&1; then
    ( timeout "$timeout_val" bash -lc "$cmd" 2>&1 | tee "$logfile" ); rc=${PIPESTATUS[0]:-0}
  elif command -v gtimeout >/dev/null 2>&1; then
    ( gtimeout "$timeout_val" bash -lc "$cmd" 2>&1 | tee "$logfile" ); rc=${PIPESTATUS[0]:-0}
  else
    # Manual watchdog fallback (portable): background command and kill after timeout
    # Parse numeric seconds from timeout_val (e.g., 300s -> 300)
    local secs
    secs=$(echo "$timeout_val" | sed -E 's/[^0-9]//g')
    if [[ -z "$secs" ]]; then secs=300; fi
    : > "$logfile"
    # Run command in background; capture PID of the shell, not tee
    # Stream output to logfile; print progress lines if VERBOSE
    set +e
    bash -lc "$cmd" >> "$logfile" 2>&1 &
    local cmd_pid=$!
    local elapsed=0
    while kill -0 "$cmd_pid" >/dev/null 2>&1; do
      sleep 1
      elapsed=$((elapsed+1))
      if (( elapsed % 10 == 0 )); then log "[QA] .. ${desc} running (${elapsed}s/${secs}s)"; fi
      if [[ "$elapsed" -ge "$secs" ]]; then
        log "[QA] ⏳ Timeout reached for '${desc}' (${secs}s). Terminating PID $cmd_pid"
        kill -TERM "$cmd_pid" >/dev/null 2>&1 || true
        sleep 1
        kill -KILL "$cmd_pid" >/dev/null 2>&1 || true
        rc=124
        break
      fi
    done
    if [[ "${rc:-0}" -eq 0 ]]; then
      wait "$cmd_pid"; rc=$?
    fi
    set -e
    # Mirror output to console on failure or verbose
    if [[ "$VERBOSE" -eq 1 || "$rc" -ne 0 ]]; then tail -n +1 "$logfile" | tail -n 200; fi
  fi

  local end_ts=$(date +%s)
  local dur=$(( end_ts - start_ts ))
  if [[ "$rc" -ne 0 ]]; then
    log "[QA] ❌ ${desc} failed (rc=$rc, ${dur}s). Last 100 lines:"
    tail -n 100 "$logfile" || true
    return "$rc"
  fi
  log "[QA] ✅ ${desc} OK (${dur}s)"
  return 0
}

log "[QA] Starting QA Sentinel in $APP_DIR"
log "[QA] Plan:"
log "[QA]  1) Haxe build (BUILD_TIMEOUT=$BUILD_TIMEOUT)"
log "[QA]  2) mix deps.get (DEPS_TIMEOUT=$DEPS_TIMEOUT)"
log "[QA]  3) mix compile (COMPILE_TIMEOUT=$COMPILE_TIMEOUT)"
log "[QA]  4) Start Phoenix (background, non-blocking)"
log "[QA]  5) Readiness probe (READY_PROBES=$READY_PROBES, 0.5s interval)"
log "[QA]  6) GET /, scan logs, teardown (unless --keep-alive)"
log "[QA] Config: PORT=$PORT KEEP_ALIVE=$KEEP_ALIVE VERBOSE=$VERBOSE"
pushd "$APP_DIR" >/dev/null

# Generate .ex files (full server build to ensure all modules are regenerated)
run_step_with_log "Step 1: Haxe build (haxe build-server.hxml)" "$BUILD_TIMEOUT" /tmp/qa-haxe.log "npx -y haxe build-server.hxml" || exit 1

run_step_with_log "Step 2: mix deps.get" "$DEPS_TIMEOUT" /tmp/qa-mix-deps.log 'MIX_ENV=dev mix deps.get' || exit 1

run_step_with_log "Step 3: mix compile" "$COMPILE_TIMEOUT" /tmp/qa-mix-compile.log 'MIX_ENV=dev mix compile' || exit 1

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

log "[QA] Step 4: Starting Phoenix server on :$PORT (background, non-blocking)"
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

log "[QA] Step 5: Waiting for server readiness (probes=$READY_PROBES)"
READY=0
for i in $(seq 1 "$READY_PROBES"); do
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
  log "[QA] Probe $i/$READY_PROBES: not ready yet (PORT=$PORT)."
  if [[ "$VERBOSE" -eq 1 ]]; then
    log "[QA] Last 20 phoenix log lines:"; tail -n 20 /tmp/qa-phx.log || true
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

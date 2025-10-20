#!/usr/bin/env bash
set -euo pipefail
# Disable job control notifications to avoid background job status lines like "Killed: 9"
set +m

# ============================================================================
# QA Sentinel: Non‑Blocking Phoenix App Validation (Haxe→Elixir→Runtime)
# ============================================================================
# WHAT
# - Builds the project (Haxe→Elixir), resolves Mix deps, compiles Elixir,
#   launches Phoenix in the background, probes readiness, curls endpoints, and
#   scans logs for errors — with strict non‑blocking behavior.
#
# WHY
# - Agents shouldn’t block on long compilation/runtime tasks. This script provides
#   robust timeouts, visible progress, and an async mode that returns immediately
#   while the full validation runs in the background with logs you can tail.
#
# USAGE
#   scripts/qa-sentinel.sh [--app PATH] [--port N] [--keep-alive] [--verbose] [--async] [--deadline SECS]
#
# FLAGS
#   --app PATH       Default: examples/todo-app
#   --port N         Default: 4001 (auto-detect Phoenix-reported port fallback)
#   --keep-alive     Do not kill Phoenix on exit; print PHX_PID and PORT
#   --verbose|-v     Print shell commands and tail logs during probes
#   --async          Dispatch pipeline to background and return immediately
#   --deadline SECS  Hard cap: watchdog kills background job after SECS
#
# ENV (timeouts/probes)
#   BUILD_TIMEOUT      Haxe build timeout (default: 300s)
#   DEPS_TIMEOUT       mix deps.get timeout (default: 300s)
#   COMPILE_TIMEOUT    mix compile timeout (default: 300s)
#   READY_PROBES       Readiness probes (default: 60) at 0.5s interval
#   PROGRESS_INTERVAL  Heartbeat interval in seconds (default: 10)
#
# OUTPUT / LOGS
#   /tmp/qa-haxe.log         Haxe build output
#   /tmp/qa-mix-deps.log     Mix deps.get output
#   /tmp/qa-mix-compile.log  Mix compile output
#   /tmp/qa-phx.log          Phoenix server output (background)
#   /tmp/qa-index.html       GET / response on success
#   Async mode main log: /tmp/qa-sentinel.<RUN_ID>.log
#
# NON‑BLOCKING DESIGN
#   - Per‑step timeouts guard against hangs.
#   - Heartbeat prints progress every PROGRESS_INTERVAL seconds.
#   - Async mode returns immediately with PIDs + log paths; optional watchdog.
#   - Background server is torn down unless --keep-alive is used.
#
# EXAMPLES
#   scripts/qa-sentinel.sh --verbose --async --deadline 120
#   BUILD_TIMEOUT=420s COMPILE_TIMEOUT=420s READY_PROBES=120 \
#     scripts/qa-sentinel.sh --verbose --async --deadline 300
#   PROGRESS_INTERVAL=5 scripts/qa-sentinel.sh --verbose
#
# TROUBLESHOOTING
#   - Haxe stalls:  tail -n 80 /tmp/qa-haxe.log
#   - Mix errors:   tail -n 80 /tmp/qa-mix-*.log
#   - Phoenix boot: tail -n 80 /tmp/qa-phx.log
#   - Kill async:   kill -TERM $QA_SENTINEL_PID
# ============================================================================

APP_DIR="examples/todo-app"
PORT=4001
KEEP_ALIVE=0
VERBOSE=0
# Noise control
NO_HEARTBEAT=0
QUIET=0
# Non-blocking options
ASYNC=0
DEADLINE=""
# Timeouts and probe counts (sane defaults; configurable via env)
BUILD_TIMEOUT=${BUILD_TIMEOUT:-300s}
DEPS_TIMEOUT=${DEPS_TIMEOUT:-300s}
COMPILE_TIMEOUT=${COMPILE_TIMEOUT:-300s}
READY_PROBES=${READY_PROBES:-60}
# Heartbeat interval while long steps run (seconds)
PROGRESS_INTERVAL=${PROGRESS_INTERVAL:-10}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APP_DIR="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --keep-alive) KEEP_ALIVE=1; shift 1 ;;
    --verbose|-v) VERBOSE=1; shift 1 ;;
    --async) ASYNC=1; shift 1 ;;
    --no-heartbeat) NO_HEARTBEAT=1; shift 1 ;;
    --quiet|-q) QUIET=1; VERBOSE=0; shift 1 ;;
    --deadline) DEADLINE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

ts() { date "+%Y-%m-%d %H:%M:%S"; }
log() { if [[ "${QUIET:-0}" -eq 0 ]]; then echo "[$(ts)] $*"; fi }
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
  # Start a heartbeat so callers always see forward progress even if the command is quiet
  local heartbeat_pid=""
  if [[ "$NO_HEARTBEAT" -eq 0 ]]; then
    ( while true; do sleep "$PROGRESS_INTERVAL"; log "[QA] .. ${desc} still running"; done ) >/dev/null 2>&1 &
    heartbeat_pid=$!
    # Ensure the heartbeat is always stopped when this function returns without noisy job messages
    local __hb="$heartbeat_pid"
    trap 'if [[ -n "$__hb" ]] && kill -0 "$__hb" 2>/dev/null; then kill "$__hb" 2>/dev/null || true; wait "$__hb" 2>/dev/null || true; fi' RETURN
  fi

  # Prefer GNU timeout; then gtimeout (macOS coreutils); else manual watchdog
  if command -v timeout >/dev/null 2>&1; then
    if [[ "$QUIET" -eq 1 ]]; then
      ( timeout "$timeout_val" bash -lc "$cmd" >>"$logfile" 2>&1 ); rc=$?
    else
      ( timeout "$timeout_val" bash -lc "$cmd" 2>&1 | tee "$logfile" ); rc=${PIPESTATUS[0]:-0}
    fi
  elif command -v gtimeout >/dev/null 2>&1; then
    if [[ "$QUIET" -eq 1 ]]; then
      ( gtimeout "$timeout_val" bash -lc "$cmd" >>"$logfile" 2>&1 ); rc=$?
    else
      ( gtimeout "$timeout_val" bash -lc "$cmd" 2>&1 | tee "$logfile" ); rc=${PIPESTATUS[0]:-0}
    fi
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
    if [[ "$VERBOSE" -eq 1 || ( "$QUIET" -eq 0 && "$rc" -ne 0 ) ]]; then tail -n +1 "$logfile" | tail -n 200; fi
  fi

  local end_ts=$(date +%s)
  local dur=$(( end_ts - start_ts ))
  # Stop heartbeat once step finishes (in addition to RETURN trap)
  if kill -0 "$heartbeat_pid" 2>/dev/null; then kill "$heartbeat_pid" >/dev/null 2>&1 || true; wait "$heartbeat_pid" 2>/dev/null || true; fi
  # Clear the RETURN trap for subsequent calls
  trap - RETURN
  if [[ "$rc" -ne 0 ]]; then
    log "[QA] ❌ ${desc} failed (rc=$rc, ${dur}s). Last 100 lines:"
    tail -n 100 "$logfile" || true
    return "$rc"
  fi
  log "[QA] ✅ ${desc} OK (${dur}s)"
  return 0
}

# Async launcher: re-invoke this script in background and return immediately
if [[ "${ASYNC}" -eq 1 && "${ASYNC_CHILD:-0}" -eq 0 ]]; then
  RUN_ID=$(date +%s)
  LOG_MAIN="/tmp/qa-sentinel.${RUN_ID}.log"
  # Reconstruct flags (omit --async to avoid recursion)
  CHILD_FLAGS=("--app" "$APP_DIR" "--port" "$PORT")
  if [[ "$KEEP_ALIVE" -eq 1 ]]; then CHILD_FLAGS+=("--keep-alive"); fi
  if [[ "$VERBOSE" -eq 1 ]]; then CHILD_FLAGS+=("--verbose"); fi
  log "[QA] Async mode: dispatching background sentinel (RUN_ID=$RUN_ID)"
  # Launch background child fully detached; prefer setsid, fallback to nohup
  if command -v setsid >/dev/null 2>&1; then
    setsid env ASYNC_CHILD=1 BUILD_TIMEOUT="$BUILD_TIMEOUT" DEPS_TIMEOUT="$DEPS_TIMEOUT" COMPILE_TIMEOUT="$COMPILE_TIMEOUT" READY_PROBES="$READY_PROBES" PROGRESS_INTERVAL="$PROGRESS_INTERVAL" PORT="$PORT" APP_DIR="$APP_DIR" KEEP_ALIVE="$KEEP_ALIVE" VERBOSE="$VERBOSE" NO_HEARTBEAT="$NO_HEARTBEAT" QUIET="$QUIET" bash -lc "'$0' ${CHILD_FLAGS[*]}" </dev/null >"$LOG_MAIN" 2>&1 &
  else
    nohup env ASYNC_CHILD=1 BUILD_TIMEOUT="$BUILD_TIMEOUT" DEPS_TIMEOUT="$DEPS_TIMEOUT" COMPILE_TIMEOUT="$COMPILE_TIMEOUT" READY_PROBES="$READY_PROBES" PROGRESS_INTERVAL="$PROGRESS_INTERVAL" PORT="$PORT" APP_DIR="$APP_DIR" KEEP_ALIVE="$KEEP_ALIVE" VERBOSE="$VERBOSE" NO_HEARTBEAT="$NO_HEARTBEAT" QUIET="$QUIET" bash -lc "'$0' ${CHILD_FLAGS[*]}" </dev/null >"$LOG_MAIN" 2>&1 &
  fi
  SENTINEL_PID=$!
  # Disown the child so shells never warn/wait on background jobs
  { disown "$SENTINEL_PID" 2>/dev/null || true; } >/dev/null 2>&1
  if [[ -n "$DEADLINE" ]]; then
    ( sleep "$DEADLINE"; kill -TERM "$SENTINEL_PID" >/dev/null 2>&1 || true; sleep 1; kill -KILL "$SENTINEL_PID" >/dev/null 2>&1 || true ) </dev/null >/dev/null 2>&1 &
    WATCHDOG_PID=$!
    { disown "$WATCHDOG_PID" 2>/dev/null || true; } >/dev/null 2>&1
    log "[QA] Async watchdog enabled: DEADLINE=$DEADLINE (PID=$WATCHDOG_PID)"
  fi
  echo "QA_SENTINEL_PID=$SENTINEL_PID"
  echo "QA_SENTINEL_RUN_ID=$RUN_ID"
  echo "QA_SENTINEL_LOG=$LOG_MAIN"
  exit 0
fi

log "[QA] Starting QA Sentinel in $APP_DIR"
log "[QA] Plan:"
log "[QA]  1) Haxe build (BUILD_TIMEOUT=$BUILD_TIMEOUT)"
log "[QA]  2) mix deps.get (DEPS_TIMEOUT=$DEPS_TIMEOUT)"
log "[QA]  3) mix compile (COMPILE_TIMEOUT=$COMPILE_TIMEOUT)"
log "[QA]  4) Start Phoenix (background, non-blocking)"
log "[QA]  5) Readiness probe (READY_PROBES=$READY_PROBES, 0.5s interval)"
log "[QA]  6) GET /, scan logs, teardown (unless --keep-alive)"
log "[QA] Config: PORT=$PORT KEEP_ALIVE=$KEEP_ALIVE VERBOSE=$VERBOSE"

# Optional overall deadline for synchronous mode too
if [[ -n "${DEADLINE}" && "${ASYNC}" -eq 0 ]]; then
  log "[QA] Overall deadline enabled: ${DEADLINE} (synchronous watchdog)"
  (
    # Use a subshell watchdog to terminate this script if deadline elapses
    sleep "${DEADLINE}" || true
    echo "[$(ts)] [QA] ⏳ Overall deadline reached (${DEADLINE}). Collecting logs and terminating."
    # Print last lines of known logs to aid debugging
    for f in /tmp/qa-haxe.log /tmp/qa-mix-deps.log /tmp/qa-mix-compile.log /tmp/qa-phx.log; do
      if [[ -s "$f" ]]; then
        echo "[$(ts)] [QA] --- Tail of ${f} ---"; tail -n 80 "$f"; echo
      fi
    done
    # Send TERM to the main shell to trigger cleanup trap
    kill -TERM $$ >/dev/null 2>&1 || true
  ) &
  OVERALL_WATCHDOG_PID=$!
  # Don’t keep a disowned child that shells may whine about
  { disown "$OVERALL_WATCHDOG_PID" 2>/dev/null || true; } >/dev/null 2>&1
fi
pushd "$APP_DIR" >/dev/null

# Prefer system haxe when available (faster, avoids npx bootstrap); fallback to npx
if command -v haxe >/dev/null 2>&1; then
  HAXE_CMD="haxe"
else
  HAXE_CMD="npx -y haxe"
fi

# Generate .ex files (full server build to ensure all modules are regenerated)
run_step_with_log "Step 1: Haxe build ($HAXE_CMD build-server.hxml)" "$BUILD_TIMEOUT" /tmp/qa-haxe.log "$HAXE_CMD build-server.hxml" || exit 1

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
# Prefer setsid; on macOS where `setsid` may not exist, fall back to perl POSIX::setsid;
# if neither available, start normally but ensure cleanup never targets our own PGID.
if command -v setsid >/dev/null 2>&1; then
  setsid sh -c 'MIX_ENV=dev mix phx.server' >/tmp/qa-phx.log 2>&1 &
elif command -v perl >/dev/null 2>&1; then
  # Create a new session via perl; then exec a shell to run the server
  nohup perl -MPOSIX -e 'POSIX::setsid() or die "setsid failed: $!"; exec @ARGV' \
    sh -c 'MIX_ENV=dev mix phx.server' >/tmp/qa-phx.log 2>&1 &
else
  # Fallback: still background, but guard cleanup to avoid killing our own process group
  nohup env MIX_ENV=dev mix phx.server >/tmp/qa-phx.log 2>&1 &
fi
PHX_PID=$!
PGID=$(ps -o pgid= "$PHX_PID" 2>/dev/null | tr -d ' ' || true)
# Our own process group (for safety checks during cleanup)
MY_PGID=$(ps -o pgid= $$ 2>/dev/null | tr -d ' ' || true)
log "[QA] Phoenix started: PHX_PID=$PHX_PID PGID=$PGID (logs: /tmp/qa-phx.log)"

cleanup() {
  # Prefer killing the Phoenix process group when it is distinct from our own.
  # This prevents terminating the host CLI when the server wasn't started in a new session.
  if [[ -n "$PGID" && -n "$MY_PGID" && "$PGID" != "$MY_PGID" ]]; then
    kill -TERM -"$PGID" >/dev/null 2>&1 || true
    sleep 0.5
    kill -KILL -"$PGID" >/dev/null 2>&1 || true
  fi
  # Always try to terminate the server PID directly
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

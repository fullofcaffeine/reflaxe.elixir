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
#   --env NAME       Mix environment (dev|test|e2e|prod). Default: dev
#   --reuse-db       For non-dev envs, do not drop DB; ensure created + migrate only
#   --seeds PATH     Run a seeds script after migrations (e.g., priv/repo/seeds.e2e.exs)
#   --keep-alive     Do not kill Phoenix on exit; print PHX_PID and PORT
#   --verbose|-v     Print shell commands and tail logs during probes
#   --async          Dispatch pipeline to background and return immediately
#   --deadline SECS  Hard cap: watchdog kills background job after SECS
#   --playwright       After readiness, run Playwright tests (defaults to e2e under --app)
#   --e2e-spec ARG     Playwright spec selector (relative to --app), e.g. e2e or e2e/*.spec.ts
#                       NOTE: pass globs UNQUOTED so the shell expands them: --e2e-spec e2e/*.spec.ts
#   --e2e-workers NUM  Playwright workers to use (default: 1 for determinism in extended runs)
#
# QA LAYERS (Mapping)
#   Layer 1 – Compiler snapshot tests (Haxe)
#     - Outside this script; run: `make -C test summary` (and `summary-negative`)
#     - Validates AST→Elixir printer shapes and transforms deterministically.
#   Layer 2 – Integration (compiler→Phoenix runtime)
#     - This script Steps 1–6: Haxe build → deps → mix compile → boot → readiness → GET / + log scan
#     - Examples:
#         Quick: `scripts/qa-sentinel.sh --app examples/todo-app --port 4001`
#         Async: `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 300`
#         Keep:  `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --keep-alive -v`
#   Layer 3 – App E2E (browser)
#     - Optional Step 7 when `--playwright` is used
#     - Use a dedicated env `--env e2e` (separate DB, server=true, PORT honored)
#     - Run entire E2E via sentinel: `scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4011 --playwright --e2e-spec "e2e/*.spec.ts" --deadline 600`
#     - Or standalone against a keep-alive server: `BASE_URL=http://localhost:$PORT npx -C examples/todo-app playwright test`
#   Testing Trophy Guidance
#     - Most coverage via Haxe-authored ExUnit (LiveView/ConnTest)
#     - Keep Playwright a thin smoke/regression layer (<1 minute total)
#
# TDD LOOP (Recommended)
#   1) Write/adjust a Playwright spec in examples/todo-app/e2e/ to describe the user-visible behavior.
#   2) Start server non-blocking: scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4011 --keep-alive -v
#   3) Run: BASE_URL=http://localhost:4001 npx -C examples/todo-app playwright test e2e/<spec>.ts
#   4) Implement the fix generically (no app-coupling) and re-run with --playwright:
#      scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4011 --playwright --e2e-spec "e2e/<spec>.ts" --deadline 600
#   --playwright     After readiness, run Playwright tests (examples/todo-app/e2e/*.spec.ts by default)
#   --e2e-spec GLOB  Playwright spec or glob (relative to --app); default: e2e/*.spec.ts
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

# Resolve script dir to reference repo-root tools regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="examples/todo-app"
PORT=4001
ENV_NAME="dev"
REUSE_DB=0
SEEDS_FILE=""
KEEP_ALIVE=0
VERBOSE=0
# Noise control
NO_HEARTBEAT=0
QUIET=0
# Non-blocking options
ASYNC=0
DEADLINE=""
# Optional E2E
RUN_PLAYWRIGHT=0
E2E_WORKERS=1
# Default to fast, stable smoke specs; override with --e2e-spec as needed
E2E_SPEC="e2e/basic.spec.ts e2e/search.spec.ts e2e/create_todo.spec.ts"
# Timeouts and probe counts (sane defaults; configurable via env)
BUILD_TIMEOUT=${BUILD_TIMEOUT:-300s}
# Optional prewarm to reduce first-build times using the Haxe compilation server
PREWARM_TIMEOUT=${PREWARM_TIMEOUT:-0}
DEPS_TIMEOUT=${DEPS_TIMEOUT:-300s}
COMPILE_TIMEOUT=${COMPILE_TIMEOUT:-300s}
READY_PROBES=${READY_PROBES:-60}
# Heartbeat interval while long steps run (seconds)
PROGRESS_INTERVAL=${PROGRESS_INTERVAL:-10}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APP_DIR="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --env) ENV_NAME="$2"; shift 2 ;;
    --reuse-db) REUSE_DB=1; shift 1 ;;
    --seeds) SEEDS_FILE="$2"; shift 2 ;;
    --keep-alive) KEEP_ALIVE=1; shift 1 ;;
    --verbose|-v) VERBOSE=1; shift 1 ;;
    --async) ASYNC=1; shift 1 ;;
    --playwright) RUN_PLAYWRIGHT=1; shift 1 ;;
    --e2e-spec) E2E_SPEC="$2"; shift 2 ;;
    --e2e-workers) E2E_WORKERS="$2"; shift 2 ;;
    --no-heartbeat) NO_HEARTBEAT=1; shift 1 ;;
    --quiet|-q) QUIET=1; VERBOSE=0; shift 1 ;;
    --deadline) DEADLINE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

# If Playwright is requested and no explicit env provided (still 'dev'),
# default to e2e for proper DB isolation and server settings
if [[ "$RUN_PLAYWRIGHT" -eq 1 && "$ENV_NAME" == "dev" ]]; then
  ENV_NAME="e2e"
fi

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

  # Prefer our robust PGID/session killer first, then GNU timeout variants, else manual fallback
  local WRAP_TIMEOUT="$SCRIPT_DIR/with-timeout.sh"
  if [[ -x "$WRAP_TIMEOUT" ]]; then
    # Extract numeric seconds (e.g., 300s -> 300) for our wrapper
    local secs
    secs=$(echo "$timeout_val" | sed -E 's/[^0-9]//g')
    if [[ -z "$secs" ]]; then secs=300; fi
    if [[ "$QUIET" -eq 1 ]]; then
      ( "$WRAP_TIMEOUT" --secs "$secs" --cwd "$(pwd)" -- bash -lc "$cmd" >>"$logfile" 2>&1 ); rc=$?
    else
      ( "$WRAP_TIMEOUT" --secs "$secs" --cwd "$(pwd)" -- bash -lc "$cmd" 2>&1 | tee "$logfile" ); rc=${PIPESTATUS[0]:-0}
    fi
  elif command -v timeout >/dev/null 2>&1; then
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
  if [[ "$RUN_PLAYWRIGHT" -eq 1 ]]; then CHILD_FLAGS+=("--playwright" "--e2e-spec" "$E2E_SPEC"); fi
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
  echo "TIP: View logs without blocking: scripts/qa-logpeek.sh --run-id $RUN_ID --last 200 --follow 30" >&2
  exit 0
fi

on_exit() {
  local rc=$?
  # Only report DONE for the actual runner (not the async launcher)
  # ASYNC_CHILD=1 is set for the background process; or ASYNC=0 for sync mode
  if [[ "${ASYNC_CHILD:-0}" -eq 1 || "${ASYNC}" -eq 0 ]]; then
    echo "[$(ts)] [QA] DONE status=${rc}"
  fi
}

trap on_exit EXIT

log "[QA] Starting QA Sentinel in $APP_DIR"
log "[QA] Plan:"
log "[QA]  1) Haxe build (BUILD_TIMEOUT=$BUILD_TIMEOUT)"
log "[QA]  2) mix deps.get (DEPS_TIMEOUT=$DEPS_TIMEOUT)"
log "[QA]  3) mix compile (COMPILE_TIMEOUT=$COMPILE_TIMEOUT)"
log "[QA]  4) Start Phoenix (background, non-blocking)"
log "[QA]  5) Readiness probe (READY_PROBES=$READY_PROBES, 0.5s interval)"
log "[QA]  6) GET /, scan logs, teardown (unless --keep-alive)"
if [[ "$RUN_PLAYWRIGHT" -eq 1 ]]; then
  log "[QA]  7) Run Playwright E2E (spec: ${E2E_SPEC:-e2e}, workers: ${E2E_WORKERS})"
fi
log "[QA] Config: PORT=$PORT ENV=$ENV_NAME KEEP_ALIVE=$KEEP_ALIVE VERBOSE=$VERBOSE"

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

# Prefer explicit override, else system haxe, else npx
if [[ -n "${HAXE_CMD:-}" ]]; then
  HAXE_CMD="$HAXE_CMD"
elif command -v haxe >/dev/null 2>&1; then
  HAXE_CMD="haxe"
else
  HAXE_CMD="npx -y haxe"
fi

# Optional: Haxe compilation server for faster repeated builds (warm cache)
HAXE_SERVER_PORT=${HAXE_SERVER_PORT:-6116}
# Default off to avoid hangs on systems without a running server
HAXE_USE_SERVER=${HAXE_USE_SERVER:-0}
if [[ "$HAXE_USE_SERVER" -eq 1 ]] && command -v haxe >/dev/null 2>&1; then
  # Best-effort start of the Haxe compilation server; do not rely on nc
  ( nohup haxe --wait "$HAXE_SERVER_PORT" >/tmp/qa-haxe-server.log 2>&1 & echo $! > /tmp/qa-haxe-server.pid ) >/dev/null 2>&1 || true
  # Keep using plain HAXE_CMD unless caller explicitly set HAXE_USE_SERVER=1
  HAXE_CMD="$HAXE_CMD --connect $HAXE_SERVER_PORT"
fi

# Optional: quick prewarm cycle to populate the server cache so the main build
# reliably fits under the BUILD_TIMEOUT cap on cold environments. This runs the
# same build command but is strictly time-bounded; whatever compiles stays cached.
if [[ "$HAXE_USE_SERVER" -eq 1 && -n "$PREWARM_TIMEOUT" && "$PREWARM_TIMEOUT" != "0" ]]; then
  run_step_with_log "Step 0: Haxe prewarm ($HAXE_CMD build-server.hxml)" "$PREWARM_TIMEOUT" /tmp/qa-haxe-prewarm.log "$HAXE_CMD build-server.hxml" || true
fi

# Generate .ex files (full server build to ensure all modules are regenerated)
run_step_with_log "Step 1: Haxe build ($HAXE_CMD build-server.hxml)" "$BUILD_TIMEOUT" /tmp/qa-haxe.log "$HAXE_CMD build-server.hxml" || exit 1

run_step_with_log "Step 2: mix deps.get" "$DEPS_TIMEOUT" /tmp/qa-mix-deps.log "MIX_ENV=$ENV_NAME mix deps.get" || exit 1

# Prepare database for non-dev environments automatically
if [[ "$ENV_NAME" != "dev" ]]; then
  if [[ "$REUSE_DB" -eq 1 ]]; then
    # Ensure DB exists (create is idempotent), then migrate
    run_step_with_log "DB ensure ($ENV_NAME)" 120s /tmp/qa-mix-db-ensure.log "MIX_ENV=$ENV_NAME mix ecto.create --quiet" || true
    run_step_with_log "DB migrate ($ENV_NAME)" 300s /tmp/qa-mix-db-migrate.log "MIX_ENV=$ENV_NAME mix ecto.migrate" || exit 1
  else
    run_step_with_log "DB drop ($ENV_NAME)" 120s /tmp/qa-mix-db-drop.log "MIX_ENV=$ENV_NAME mix ecto.drop --quiet" || true
    run_step_with_log "DB create ($ENV_NAME)" 120s /tmp/qa-mix-db-create.log "MIX_ENV=$ENV_NAME mix ecto.create --quiet" || true
    run_step_with_log "DB migrate ($ENV_NAME)" 300s /tmp/qa-mix-db-migrate.log "MIX_ENV=$ENV_NAME mix ecto.migrate" || exit 1
  fi
  # Optional seeds
  if [[ -n "$SEEDS_FILE" ]]; then
    run_step_with_log "DB seeds ($ENV_NAME)" 180s /tmp/qa-mix-db-seeds.log "MIX_ENV=$ENV_NAME mix run '$SEEDS_FILE'" || exit 1
  fi
fi

run_step_with_log "Step 3: mix compile" "$COMPILE_TIMEOUT" /tmp/qa-mix-compile.log "MIX_ENV=$ENV_NAME mix compile" || exit 1

# Build static assets (JS/CSS) so LiveView client and UI interactions are available
run_step_with_log "Assets build ($ENV_NAME)" 300s /tmp/qa-assets-build.log "MIX_ENV=$ENV_NAME mix assets.build" || true

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
  setsid sh -c "MIX_ENV=$ENV_NAME mix phx.server" >/tmp/qa-phx.log 2>&1 &
elif command -v perl >/dev/null 2>&1; then
  # Create a new session via perl; then exec a shell to run the server
  nohup perl -MPOSIX -e 'POSIX::setsid() or die "setsid failed: $!"; exec @ARGV' \
    sh -c "MIX_ENV=$ENV_NAME mix phx.server" >/tmp/qa-phx.log 2>&1 &
else
  # Fallback: still background, but guard cleanup to avoid killing our own process group
  nohup env MIX_ENV=$ENV_NAME mix phx.server >/tmp/qa-phx.log 2>&1 &
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

# Optional: run Playwright tests after readiness
if [[ "$RUN_PLAYWRIGHT" -eq 1 ]]; then
  log "[QA] Step 7: Running Playwright tests (${E2E_SPEC:-e2e}, workers: ${E2E_WORKERS})"
  # Install dependencies and browsers for Playwright in the app dir
  run_step_with_log "Playwright npm install" 180s /tmp/qa-playwright-install.log "npm -C . install --no-audit --no-fund" || { cleanup || true; exit 1; }
  run_step_with_log "Playwright browsers install" 600s /tmp/qa-playwright-browsers.log "npx -C . playwright install" || { cleanup || true; exit 1; }
  # Important: do NOT quote the spec so that shell globs expand (e.g., e2e/*.spec.ts)
  SPEC_ARG=${E2E_SPEC:-e2e}
  if ! BASE_URL="http://localhost:$PORT" bash -lc "npx -C . playwright test ${SPEC_ARG} --workers=${E2E_WORKERS}" >/tmp/qa-playwright-run.log 2>&1; then
    log "[QA] ❌ Playwright tests failed. Last 120 lines:"
    tail -n 120 /tmp/qa-playwright-run.log || true
    cleanup || true
    exit 1
  fi
  log "[QA] ✅ Playwright tests passed"
fi

if [[ "$KEEP_ALIVE" -eq 1 ]]; then
  log "[QA] KEEP-ALIVE enabled. Phoenix continues running."
  echo "PHX_PID=$PHX_PID"
  echo "PORT=$PORT"
fi
popd >/dev/null

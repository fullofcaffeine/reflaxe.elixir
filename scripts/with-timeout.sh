#!/usr/bin/env bash
set -euo pipefail
# Portable timeout wrapper in pure bash. Kills the full process group.
# Usage: with-timeout.sh --secs N [--grace S] [--cwd DIR] [--quiet] [--echo] [--env KEY=VAL ...] -- <cmd> [args...]

SECS=""
GRACE="1"
QUIET=0
ECHO=0
CWD=""
ENV_KV=()

usage() { echo "Usage: $0 --secs N [--grace S] [--cwd DIR] [--quiet] [--echo] [--env KEY=VAL ...] -- <cmd> [args...]" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --secs) SECS="$2"; shift 2;;
    --grace) GRACE="$2"; shift 2;;
    --cwd) CWD="$2"; shift 2;;
    --quiet) QUIET=1; shift;;
    --echo) ECHO=1; shift;;
    --env) ENV_KV+=("$2"); shift 2;;
    --) shift; break;;
    *) usage;;
  esac
done
[[ -n "${SECS}" ]] || usage
[[ $# -ge 1 ]] || usage

CMD=("$@")
MARKER_FILE="${TMPDIR:-/tmp}/.with-timeout.${$}.marker"
rm -f "$MARKER_FILE" 2>/dev/null || true
cleanup() { rm -f "$MARKER_FILE" 2>/dev/null || true; }
trap cleanup EXIT
if [[ "$ECHO" -eq 1 ]]; then
  echo "[timeout] secs=${SECS} grace=${GRACE} cwd=${CWD:-$(pwd)} cmd=${CMD[*]}" >&2
fi

# Apply environment variables
for kv in "${ENV_KV[@]:-}"; do
  [[ -n "$kv" ]] || continue
  if [[ "$kv" == *=* ]]; then export "$kv"; fi
done

# Change dir if requested
if [[ -n "$CWD" ]]; then cd "$CWD"; fi

# Start command in a new process group when possible
start_cmd() {
  if command -v setsid >/dev/null 2>&1; then
    # Start in a new session so we can later reap all descendants reliably
    if [[ "$QUIET" -eq 1 ]]; then
      setsid "${CMD[@]}" >/dev/null 2>&1 &
    else
      setsid "${CMD[@]}" &
    fi
  else
    # Fallback: background in current group
    if [[ "$QUIET" -eq 1 ]]; then
      "${CMD[@]}" >/dev/null 2>&1 &
    else
      "${CMD[@]}" &
    fi
  fi
}

start_cmd
CMD_PID=$!
# Determine process group id of child and our own
PGID_CHILD="$(ps -o pgid= "$CMD_PID" 2>/dev/null | tr -d ' ')" || PGID_CHILD=""
PGID_SELF="$(ps -o pgid= $$ 2>/dev/null | tr -d ' ')" || PGID_SELF=""
# Session id of child (BSD/macOS uses 'sess')
SESS_CHILD="$(ps -o sess= "$CMD_PID" 2>/dev/null | tr -d ' ')" || SESS_CHILD=""
if [[ "$ECHO" -eq 1 ]]; then
  echo "[timeout] pids: cmd_pid=${CMD_PID} pgid_child=${PGID_CHILD:-?} pgid_self=${PGID_SELF:-?} sess_child=${SESS_CHILD:-?}" >&2
fi

# Best-effort helper: recursively kill children by PPID (fallback when PGID/SESS are unusable)
kill_children_tree() {
  local p="$1"; local sig="$2"; local kids
  if command -v pgrep >/dev/null 2>&1; then
    kids=$(pgrep -P "$p" 2>/dev/null || true)
    for k in $kids; do
      kill_children_tree "$k" "$sig"
      kill -s "$sig" "$k" 2>/dev/null || true
    done
  else
    kids=$(ps -Ao pid,ppid | awk -v ppid="$p" '$2==ppid {print $1}')
    for k in $kids; do
      kill_children_tree "$k" "$sig"
      kill -s "$sig" "$k" 2>/dev/null || true
    done
  fi
}

# Return a space-separated list of current descendants of PID
list_descendants() {
  local p="$1"; local acc=""; local queue="$p"; local next kids
  if command -v pgrep >/dev/null 2>&1; then
    while [[ -n "$queue" ]]; do
      next=""
      for q in $queue; do
        kids=$(pgrep -P "$q" 2>/dev/null || true)
        acc+=" $kids"
        next+=" $kids"
      done
      queue="$next"
    done
  else
    while [[ -n "$queue" ]]; do
      next=""
      for q in $queue; do
        kids=$(ps -Ao pid,ppid | awk -v ppid="$q" '$2==ppid {print $1}')
        acc+=" $kids"
        next+=" $kids"
      done
      queue="$next"
    done
  fi
  echo "$acc" | xargs -n1 echo | awk 'NF' | sort -u | xargs echo 2>/dev/null || true
}

# Watchdog
(
  sleep "$SECS" || true
  if kill -0 "$CMD_PID" 2>/dev/null; then
    # Prefer killing the entire session if available (handles grandchildren in separate PGIDs)
    if command -v pkill >/dev/null 2>&1 && [[ -n "$SESS_CHILD" && "$SESS_CHILD" != "0" ]]; then
      pkill -TERM -s "$SESS_CHILD" 2>/dev/null || true
    elif [[ -n "$PGID_CHILD" && -n "$PGID_SELF" && "$PGID_CHILD" != "$PGID_SELF" && "$PGID_CHILD" != "0" ]]; then
      kill -TERM -"$PGID_CHILD" 2>/dev/null || true
    else
      # Capture descendants first to avoid orphans then terminate all
      DESC=$(list_descendants "$CMD_PID")
      kill -TERM "$CMD_PID" 2>/dev/null || true
      for d in $DESC; do kill -TERM "$d" 2>/dev/null || true; done
    fi
    sleep "$GRACE" || true
    if kill -0 "$CMD_PID" 2>/dev/null; then
      if command -v pkill >/dev/null 2>&1 && [[ -n "$SESS_CHILD" && "$SESS_CHILD" != "0" ]]; then
        pkill -KILL -s "$SESS_CHILD" 2>/dev/null || true
      elif [[ -n "$PGID_CHILD" && -n "$PGID_SELF" && "$PGID_CHILD" != "$PGID_SELF" && "$PGID_CHILD" != "0" ]]; then
        kill -KILL -"$PGID_CHILD" 2>/dev/null || true
      else
        # Recompute and force kill everyone left
        DESC2=$(list_descendants "$CMD_PID")
        kill -KILL "$CMD_PID" 2>/dev/null || true
        for d in $DESC2; do kill -KILL "$d" 2>/dev/null || true; done
      fi
      echo "[timeout] command force-killed after ${SECS}s+${GRACE}s" >&2
      echo 137 >"$MARKER_FILE" 2>/dev/null || true
      exit 137
    else
      echo "[timeout] command timed out after ${SECS}s (terminated)" >&2
      echo 124 >"$MARKER_FILE" 2>/dev/null || true
      exit 124
    fi
  fi
  exit 0
) &
WATCH_PID=$!

# Wait for the command and propagate exit code; kill watchdog if still running
# Do not mask non-zero exits from `wait` — we want to surface timeout/kill statuses.
set +e
wait "$CMD_PID"
RC=$?
set -e

# Stop watchdog if still running
kill "$WATCH_PID" 2>/dev/null || true
wait "$WATCH_PID" 2>/dev/null || true

# If the watchdog fired, override RC with the conventional timeout exit codes (124/137).
if [[ -f "$MARKER_FILE" ]]; then
  RC="$(cat "$MARKER_FILE" 2>/dev/null || echo "$RC")"
fi

exit "$RC"

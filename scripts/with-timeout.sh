#!/usr/bin/env bash
set -euo pipefail
# Ensure background watchdog termination doesn't emit job-control noise like:
#   "Terminated: 15 ( sleep ... )"
# Some environments enable `monitor` via inherited shell options.
set +m 2>/dev/null || true
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
ISOLATION_MODE="none"
start_cmd() {
  if command -v python3 >/dev/null 2>&1 && command -v setsid >/dev/null 2>&1; then
    ISOLATION_MODE="session"
    # On setsid-capable hosts, own a full session so descendants cannot escape
    # the deadline merely by creating another process group.
    if [[ "$QUIET" -eq 1 ]]; then
      python3 -c 'import os,signal,sys; signal.signal(signal.SIGINT, signal.SIG_DFL); signal.signal(signal.SIGQUIT, signal.SIG_DFL); os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])' "${CMD[@]}" >/dev/null 2>&1 &
    else
      python3 -c 'import os,signal,sys; signal.signal(signal.SIGINT, signal.SIG_DFL); signal.signal(signal.SIGQUIT, signal.SIG_DFL); os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])' "${CMD[@]}" &
    fi
  elif command -v python3 >/dev/null 2>&1; then
    ISOLATION_MODE="process_group"
    # Reset signals that shells commonly ignore for asynchronous children, then
    # create the process group used for timeout and interactive-signal cleanup.
    if [[ "$QUIET" -eq 1 ]]; then
      python3 -c 'import os,signal,sys; signal.signal(signal.SIGINT, signal.SIG_DFL); signal.signal(signal.SIGQUIT, signal.SIG_DFL); os.setpgrp(); os.execvp(sys.argv[1], sys.argv[1:])' "${CMD[@]}" >/dev/null 2>&1 &
    else
      python3 -c 'import os,signal,sys; signal.signal(signal.SIGINT, signal.SIG_DFL); signal.signal(signal.SIGQUIT, signal.SIG_DFL); os.setpgrp(); os.execvp(sys.argv[1], sys.argv[1:])' "${CMD[@]}" &
    fi
  elif command -v setsid >/dev/null 2>&1; then
    ISOLATION_MODE="session"
    # Fallback for minimal systems without Python.
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
# Determine our identity first, then wait briefly for the launcher to isolate
# the child. Reading immediately can capture this wrapper's process group
# before Python calls setsid() or setpgrp().
PGID_SELF="$(ps -o pgid= $$ 2>/dev/null | tr -d ' ')" || PGID_SELF=""
SESS_SELF="$(ps -o sess= $$ 2>/dev/null | tr -d ' ')" || SESS_SELF=""
PGID_CHILD=""
SESS_CHILD=""
identity_deadline=$((SECONDS + 2))
while true; do
  PGID_CHILD="$(ps -o pgid= "$CMD_PID" 2>/dev/null | tr -d ' ')" || PGID_CHILD=""
  # Session id of child (BSD/macOS uses 'sess').
  SESS_CHILD="$(ps -o sess= "$CMD_PID" 2>/dev/null | tr -d ' ')" || SESS_CHILD=""
  isolation_ready=0
  case "$ISOLATION_MODE" in
    none)
      isolation_ready=1
      ;;
    session)
      # Read PGID and session in separate ps calls, so one value can still be
      # stale while setsid() runs. Accept only the final, self-owned pair.
      if [[ "$PGID_CHILD" == "$CMD_PID" && "$SESS_CHILD" == "$CMD_PID" ]]; then
        isolation_ready=1
      fi
      ;;
    process_group)
      if [[ "$PGID_CHILD" == "$CMD_PID" && "$PGID_CHILD" != "$PGID_SELF" ]]; then
        isolation_ready=1
      fi
      ;;
  esac
  if (( isolation_ready == 1 )) \
    || ! kill -0 "$CMD_PID" 2>/dev/null \
    || (( SECONDS >= identity_deadline )); then
    break
  fi
  sleep 0.02 || true
done
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

process_identity() {
  ps -o lstart= -p "$1" 2>/dev/null | awk '{$1=$1; print}' || true
}

record_process_identities() {
  local p identity
  for p in $1; do
    identity=$(process_identity "$p")
    if [[ -n "$identity" ]]; then
      printf '%s|%s\n' "$p" "$identity"
    fi
  done
}

kill_recorded_processes() {
  local sig="$1"
  local records="$2"
  local record p expected current
  while IFS= read -r record; do
    [[ -n "$record" ]] || continue
    p=${record%%|*}
    expected=${record#*|}
    current=$(process_identity "$p")
    if [[ -n "$current" && "$current" == "$expected" ]]; then
      kill -s "$sig" "$p" 2>/dev/null || true
    fi
  done <<<"$records"
}

# Forward an interactive interrupt to the command we own, then keep waiting so
# its cleanup traps receive their configured grace period.
FORWARDED_STATUS=""
forward_external_signal() {
  local sig="$1"
  local status="$2"
  local descendants
  FORWARDED_STATUS="$status"

  descendants=$(list_descendants "$CMD_PID")
  if command -v pkill >/dev/null 2>&1 \
    && [[ -n "$SESS_CHILD" && "$SESS_CHILD" != "0" && "$SESS_CHILD" != "$SESS_SELF" ]]; then
    pkill -"$sig" -s "$SESS_CHILD" 2>/dev/null || true
  elif [[ -n "$PGID_CHILD" && -n "$PGID_SELF" && "$PGID_CHILD" != "$PGID_SELF" && "$PGID_CHILD" != "0" ]]; then
    kill -s "$sig" -"$PGID_CHILD" 2>/dev/null || true
  else
    kill -s "$sig" "$CMD_PID" 2>/dev/null || true
  fi
  for descendant in $descendants; do
    kill -s "$sig" "$descendant" 2>/dev/null || true
  done
}
trap 'forward_external_signal INT 130' INT
trap 'forward_external_signal TERM 143' TERM

# Watchdog
#
# Instead of a single long sleep (which we then have to interrupt with signals), we poll the
# command PID until it exits or the timeout elapses. This avoids noisy "Terminated: 15" messages
# from bash when the watchdog is signaled in non-interactive environments.
(
  interval="0.2"
  deadline="$(( SECONDS + SECS ))"

  while (( SECONDS < deadline )); do
    if ! kill -0 "$CMD_PID" 2>/dev/null; then
      exit 0
    fi
    sleep "$interval" || true
  done

  if kill -0 "$CMD_PID" 2>/dev/null; then
    # Mark timeout early to avoid a race where the parent reaps the command and
    # kills this watchdog before we can write the marker.
    echo 124 >"$MARKER_FILE" 2>/dev/null || true

    # Snapshot descendants before TERM so an orphan that changes process group
    # can still be force-killed after the grace period on non-session platforms.
    DESC=""
    DESC_IDENTITIES=""
    ROOT_IDENTITY=$(process_identity "$CMD_PID")
    if command -v pkill >/dev/null 2>&1 \
      && [[ -n "$SESS_CHILD" && "$SESS_CHILD" != "0" && "$SESS_CHILD" != "$SESS_SELF" ]]; then
      pkill -TERM -s "$SESS_CHILD" 2>/dev/null || true
    else
      DESC=$(list_descendants "$CMD_PID")
      DESC_IDENTITIES=$(record_process_identities "$DESC")
      if [[ -n "$PGID_CHILD" && -n "$PGID_SELF" && "$PGID_CHILD" != "$PGID_SELF" && "$PGID_CHILD" != "0" ]]; then
        kill -TERM -"$PGID_CHILD" 2>/dev/null || true
      else
        kill -TERM "$CMD_PID" 2>/dev/null || true
      fi
      kill_recorded_processes TERM "$DESC_IDENTITIES"
    fi
    sleep "$GRACE" || true
    root_survived=0
    if kill -0 "$CMD_PID" 2>/dev/null; then root_survived=1; fi
    DESC2=$(list_descendants "$CMD_PID")
    if command -v pkill >/dev/null 2>&1 \
      && [[ -n "$SESS_CHILD" && "$SESS_CHILD" != "0" && "$SESS_CHILD" != "$SESS_SELF" ]]; then
      pkill -KILL -s "$SESS_CHILD" 2>/dev/null || true
    else
      DESC2_IDENTITIES=$(record_process_identities "$DESC2")
      CURRENT_ROOT_IDENTITY=$(process_identity "$CMD_PID")
      if [[ -n "$CURRENT_ROOT_IDENTITY" && "$CURRENT_ROOT_IDENTITY" == "$ROOT_IDENTITY" ]]; then
        if [[ -n "$PGID_CHILD" && -n "$PGID_SELF" && "$PGID_CHILD" != "$PGID_SELF" && "$PGID_CHILD" != "0" ]]; then
          kill -KILL -"$PGID_CHILD" 2>/dev/null || true
        else
          kill -KILL "$CMD_PID" 2>/dev/null || true
        fi
      fi
      kill_recorded_processes KILL "$DESC_IDENTITIES"
      kill_recorded_processes KILL "$DESC2_IDENTITIES"
    fi

    if (( root_survived == 1 )); then
      echo "[timeout] command force-killed after ${SECS}s+${GRACE}s" >&2
      echo 137 >"$MARKER_FILE" 2>/dev/null || true
      exit 137
    else
      echo "[timeout] command timed out after ${SECS}s (terminated)" >&2
      exit 124
    fi
  fi

  exit 0
) &
WATCH_PID=$!

# Wait for the command and propagate exit code; kill watchdog if still running
# Do not mask non-zero exits from `wait` — we want to surface timeout/kill statuses.
set +e
while true; do
  wait "$CMD_PID"
  RC=$?
  if [[ -n "$FORWARDED_STATUS" ]] && kill -0 "$CMD_PID" 2>/dev/null; then
    continue
  fi
  break
done
set -e

# Wait for watchdog to exit (should be quick if the command finished before timeout)
wait "$WATCH_PID" 2>/dev/null || true

# If the watchdog fired, override RC with the conventional timeout exit codes (124/137).
if [[ -f "$MARKER_FILE" ]]; then
  RC="$(cat "$MARKER_FILE" 2>/dev/null || echo "$RC")"
elif [[ -n "$FORWARDED_STATUS" ]] && (( RC == 0 )); then
  RC="$FORWARDED_STATUS"
fi

exit "$RC"

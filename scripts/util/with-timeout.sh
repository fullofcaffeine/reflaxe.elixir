#!/usr/bin/env bash
# with-timeout.sh — cross-platform timeout wrapper with graceful kill
# Usage: with-timeout.sh <seconds> <command...>
#
# Tries: gtimeout (GNU coreutils on macOS) → timeout (GNU) → portable bash fallback.
# Ensures the whole process tree is terminated on timeout.

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <seconds> <command...>" >&2
  exit 2
fi

DEADLINE="$1"; shift

have() { command -v "$1" >/dev/null 2>&1; }

if have gtimeout; then
  exec gtimeout "${DEADLINE}s" "$@"
elif have timeout; then
  exec timeout "${DEADLINE}s" "$@"
else
  # Portable fallback using a background watchdog.
  # Creates a new process group and kills it on timeout.
  SECONDS_TOTAL="$DEADLINE"
  # Start command in its own process group
  ( set -m; "$@" & echo $! >"${TMPDIR:-/tmp}/.with-timeout.$$"; wait ) &
  CMD_WRAPPER_PID=$!
  CHILD_PID=$(cat "${TMPDIR:-/tmp}/.with-timeout.$$")
  rm -f "${TMPDIR:-/tmp}/.with-timeout.$$" || true

  # Watchdog
  (
    sleep "$SECONDS_TOTAL"
    # Kill entire process group of the child if still running
    if ps -p "$CHILD_PID" >/dev/null 2>&1; then
      echo "[with-timeout] killing process group for PID $CHILD_PID after ${SECONDS_TOTAL}s" >&2
      pkill -TERM -g "$CHILD_PID" 2>/dev/null || kill -TERM -$CHILD_PID 2>/dev/null || kill -TERM "$CHILD_PID" 2>/dev/null || true
      sleep 3
      pkill -KILL -g "$CHILD_PID" 2>/dev/null || kill -KILL -$CHILD_PID 2>/dev/null || kill -KILL "$CHILD_PID" 2>/dev/null || true
    fi
  ) & WD_PID=$!

  # Wait for command or watchdog
  wait "$CMD_WRAPPER_PID" 2>/dev/null || true
  STATUS=$?
  # Cancel watchdog if command finished
  kill "$WD_PID" 2>/dev/null || true
  wait "$WD_PID" 2>/dev/null || true
  exit "$STATUS"
fi


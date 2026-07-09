#!/usr/bin/env bash
set -euo pipefail

# qa-logpeek.sh — bounded log viewing for QA Sentinel runs
# Usage:
#   scripts/qa-logpeek.sh --run-id <RUN_ID> [--last 200] [--follow 60]
#   scripts/qa-logpeek.sh --file /tmp/qa-sentinel.<RUN_ID>.log [--last 200] [--follow 60]

LAST=200
FOLLOW=0
LOGFILE=""
RUN_ID=""
# Follow until a DONE line appears or until a max number of seconds
UNTIL_DONE=0
UNTIL_SECS=60

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2;;
    --file) LOGFILE="$2"; shift 2;;
    --last) LAST="$2"; shift 2;;
    --follow) FOLLOW="$2"; shift 2;;
    --until-done)
      UNTIL_DONE=1
      # Optional numeric argument: --until-done 90
      if [[ ${2-} =~ ^[0-9]+$ ]]; then UNTIL_SECS="$2"; shift 2; else shift; fi;;
    -h|--help)
      echo "Usage: $0 --run-id <RUN_ID> | --file <LOG> [--last N] [--follow SECS] [--until-done [SECS]]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ -n "$RUN_ID" && -z "$LOGFILE" ]]; then
  LOGFILE="/tmp/qa-sentinel.${RUN_ID}.log"
fi

if [[ -z "$LOGFILE" ]]; then
  echo "Provide --run-id or --file" >&2; exit 1
fi

if [[ ! -f "$LOGFILE" ]]; then
  echo "Log not found: $LOGFILE" >&2; exit 1
fi

# Always print a bounded tail first (safe for large files)
tail -n "$LAST" "$LOGFILE" || true

# Optionally follow until DONE (bounded), else follow for a fixed duration
if [[ "$UNTIL_DONE" -eq 1 ]]; then
  echo "[qa-logpeek] Following ${LOGFILE} until '[QA] DONE status=' or ${UNTIL_SECS}s (bounded)" >&2
  if ! grep -F '[QA] DONE status=' "$LOGFILE" >/dev/null 2>&1; then
    printed_lines="$(wc -l < "$LOGFILE" | tr -d ' ')"
    deadline=$((SECONDS + UNTIL_SECS))

    while (( SECONDS < deadline )); do
      current_lines="$(wc -l < "$LOGFILE" | tr -d ' ')"
      if (( current_lines < printed_lines )); then
        printed_lines=0
      fi

      if (( current_lines > printed_lines )); then
        start_line=$((printed_lines + 1))
        sed -n "${start_line},${current_lines}p" "$LOGFILE"
        if sed -n "${start_line},${current_lines}p" "$LOGFILE" | grep -F '[QA] DONE status=' >/dev/null 2>&1; then
          break
        fi
        printed_lines="$current_lines"
      fi

      sleep 1
    done
  fi
  echo "[qa-logpeek] Follow finished (until-done)" >&2
elif [[ "${FOLLOW}" != "0" ]]; then
  echo "[qa-logpeek] Following ${LOGFILE} for ${FOLLOW}s (bounded)" >&2
  if command -v timeout >/dev/null 2>&1; then
    timeout "${FOLLOW}s" tail -f "$LOGFILE" || true
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "${FOLLOW}s" tail -f "$LOGFILE" || true
  else
    # Portable watchdog: start tail, stop it after FOLLOW seconds, then clean up timer
    secs=$FOLLOW
    tail -f "$LOGFILE" &
    tpid=$!
    (
      sleep "$secs" || true
      kill -TERM "$tpid" >/dev/null 2>&1 || true
    ) &
    timer=$!
    # Ensure timer is stopped if tail exits early
    wait "$tpid" 2>/dev/null || true
    kill -TERM "$timer" >/dev/null 2>&1 || true
  fi
  echo "[qa-logpeek] Follow finished after ${FOLLOW}s" >&2
fi

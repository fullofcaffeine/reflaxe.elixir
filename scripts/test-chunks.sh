#!/usr/bin/env bash
# test-chunks.sh — run snapshot tests in bounded chunks with per-chunk deadlines
# Usage examples:
#   scripts/test-chunks.sh                     # defaults (8-way, 600s per chunk)
#   scripts/test-chunks.sh --parallel 12 --chunk-deadline 900
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

PARALLEL=${PARALLEL:-8}
CHUNK_DEADLINE=${CHUNK_DEADLINE:-600}
TIMEOUT_PER_TEST=${TIMEOUT_PER_TEST:-120}
CATEGORIES=(core stdlib regression phoenix ecto otp)

while [[ $# -gt 0 ]]; do
  case $1 in
    --parallel) PARALLEL="$2"; shift 2;;
    --chunk-deadline) CHUNK_DEADLINE="$2"; shift 2;;
    --timeout) TIMEOUT_PER_TEST="$2"; shift 2;;
    --categories) shift; IFS=',' read -r -a CATEGORIES <<<"$1"; shift;;
    --help)
      echo "Usage: $0 [--parallel N] [--chunk-deadline SEC] [--timeout SEC] [--categories core,stdlib,...]"; exit 0;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

echo "[test-chunks] parallel=$PARALLEL timeout=${TIMEOUT_PER_TEST}s chunk-deadline=${CHUNK_DEADLINE}s categories=${CATEGORIES[*]}"

export TIMEOUT="$TIMEOUT_PER_TEST" # picked up by test/Makefile

for cat in "${CATEGORIES[@]}"; do
  echo "[test-chunks] Running category: $cat (deadline ${CHUNK_DEADLINE}s)"
  if ! "$ROOT_DIR/scripts/with-timeout.sh" --secs "$CHUNK_DEADLINE" --cwd "$ROOT_DIR" -- \
       "$ROOT_DIR/scripts/test-runner.sh" --category "$cat" --parallel "$PARALLEL" --timeout "$TIMEOUT_PER_TEST" --deadline "$CHUNK_DEADLINE"; then
    echo "[test-chunks] Category failed or timed out: $cat" >&2
    exit 1
  fi
done

echo "[test-chunks] All chunks passed ✅"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
LOGPEEK="$ROOT_DIR/scripts/qa-logpeek.sh"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/qa-logpeek-smoke.XXXXXX")"
writer_pid=""

cleanup() {
  if [[ -n "$writer_pid" ]]; then
    kill -TERM "$writer_pid" 2>/dev/null || true
    wait "$writer_pid" 2>/dev/null || true
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

completed_log="$tmp_dir/completed.log"
printf '%s\n' '[QA] start' '[QA] DONE status=0' > "$completed_log"
"$TIMEOUT" --secs 3 -- "$LOGPEEK" --file "$completed_log" --last 2 --until-done 2 > "$tmp_dir/completed.out" 2>&1
grep -F '[QA] DONE status=0' "$tmp_dir/completed.out" >/dev/null

pending_log="$tmp_dir/pending.log"
printf '%s\n' '[QA] start' > "$pending_log"
(
  sleep 1
  printf '%s\n' '[QA] DONE status=0' >> "$pending_log"
) &
writer_pid=$!

"$TIMEOUT" --secs 5 -- "$LOGPEEK" --file "$pending_log" --last 1 --until-done 4 > "$tmp_dir/pending.out" 2>&1
wait "$writer_pid"
writer_pid=""
grep -F '[QA] DONE status=0' "$tmp_dir/pending.out" >/dev/null

echo "[qa-logpeek-smoke] OK: completed and newly-completed logs return promptly"

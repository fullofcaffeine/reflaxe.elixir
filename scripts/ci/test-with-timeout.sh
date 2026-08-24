#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/with-timeout-contract.XXXXXX")
child_pid_file="$tmp_dir/escaped-child.pid"
timeout_log="$tmp_dir/timeout.log"

cleanup() {
  if [[ -f "$child_pid_file" ]]; then
    child_pid=$(<"$child_pid_file")
    kill -KILL "$child_pid" 2>/dev/null || true
  fi
  rm -rf -- "$tmp_dir"
}
trap cleanup EXIT INT TERM

set +e
started_at=$SECONDS
"$repo_root/scripts/with-timeout.sh" --secs 1 --grace 1 --echo -- \
  python3 -c '
import subprocess, sys, time

child_code = """
import os, signal, sys, time
os.setpgrp()
signal.signal(signal.SIGTERM, signal.SIG_IGN)
signal.signal(signal.SIGHUP, signal.SIG_IGN)
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    handle.write(str(os.getpid()))
time.sleep(30)
"""
subprocess.Popen([sys.executable, "-c", child_code, sys.argv[1]])
time.sleep(30)
' "$child_pid_file" >"$timeout_log" 2>&1
timeout_status=$?
elapsed=$((SECONDS - started_at))
set -e

if (( timeout_status != 124 )); then
  cat "$timeout_log" >&2
  echo "Expected timeout status 124, got $timeout_status" >&2
  exit 1
fi
if (( elapsed > 6 )); then
  cat "$timeout_log" >&2
  echo "One-second timeout took ${elapsed}s" >&2
  exit 1
fi

pids_line=$(grep -F '[timeout] pids:' "$timeout_log" || true)
if [[ ! "$pids_line" =~ cmd_pid=([0-9]+).*pgid_child=([0-9]+) ]]; then
  cat "$timeout_log" >&2
  echo "Timeout diagnostics did not contain child process identities" >&2
  exit 1
fi
if [[ "${BASH_REMATCH[1]}" != "${BASH_REMATCH[2]}" ]]; then
  cat "$timeout_log" >&2
  echo "Child process group was sampled before isolation completed" >&2
  exit 1
fi
if [[ ! -s "$child_pid_file" ]]; then
  echo "Separate-process-group fixture did not record its PID" >&2
  exit 1
fi

child_pid=$(<"$child_pid_file")
for _ in $(seq 1 40); do
  if ! kill -0 "$child_pid" 2>/dev/null; then
    echo "with-timeout terminated the full owned process tree."
    exit 0
  fi
  sleep 0.05
done

echo "Separate-process-group child $child_pid survived the timeout" >&2
exit 1

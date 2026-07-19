#!/usr/bin/env bash
set -euo pipefail

# This is a deliberately native host boundary: it must observe the BEAM port's
# stdin closing and reap the compiler after the VM itself no longer exists, so
# Haxe-generated Elixir cannot own this final lifecycle step.

if [ "$#" -lt 1 ]; then
  echo "haxe-server-owner: missing compiler command" >&2
  exit 64
fi

# Bash connects an unredirected background job to /dev/null in a
# non-interactive shell. Preserve the BEAM port's stdin explicitly before
# starting the guard so it observes the real owner connection instead.
exec 3<&0

compiler_pid=""
stdin_guard_pid=""

process_running() {
  local pid="$1"
  local state=""
  kill -0 "$pid" >/dev/null 2>&1 || return 1
  state="$(ps -o state= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
  [ -n "$state" ] && [[ "$state" != Z* ]]
}

signal_tree() {
  local pid="$1"
  local signal="$2"
  local child=""
  local children=""

  if command -v pgrep >/dev/null 2>&1; then
    children="$(pgrep -P "$pid" 2>/dev/null || true)"
    for child in $children; do
      signal_tree "$child" "$signal"
    done
  fi
  kill -"$signal" "$pid" >/dev/null 2>&1 || true
}

stop_compiler() {
  if [ -z "$compiler_pid" ] || ! process_running "$compiler_pid"; then
    return
  fi

  signal_tree "$compiler_pid" TERM
  for _attempt in 1 2 3 4 5 6 7 8 9 10; do
    process_running "$compiler_pid" || return
    sleep 0.05
  done
  signal_tree "$compiler_pid" KILL
}

cleanup() {
  local status=$?
  trap - EXIT HUP INT TERM

  if [ -n "$stdin_guard_pid" ] && process_running "$stdin_guard_pid"; then
    kill -TERM "$stdin_guard_pid" >/dev/null 2>&1 || true
  fi
  stop_compiler
  if [ -n "$compiler_pid" ]; then
    wait "$compiler_pid" >/dev/null 2>&1 || true
  fi
  if [ -n "$stdin_guard_pid" ]; then
    wait "$stdin_guard_pid" >/dev/null 2>&1 || true
  fi
  exec 3<&-
  exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

"$@" </dev/null &
compiler_pid="$!"

# This reader owns the BEAM port's stdin. It remains blocked while the owning
# VM is alive and exits on EOF even when GenServer terminate callbacks cannot
# run. The compiler receives /dev/null because `haxe --wait` needs no stdin.
(
  while IFS= read -r _line; do
    :
  done
) <&3 &
stdin_guard_pid="$!"

while process_running "$compiler_pid" && process_running "$stdin_guard_pid"; do
  sleep 0.05
done

if ! process_running "$compiler_pid"; then
  set +e
  wait "$compiler_pid"
  compiler_status="$?"
  set -e
  compiler_pid=""
  exit "$compiler_status"
fi

# The stdin guard ended first, which means the BEAM owner closed its port or
# exited. Normal EXIT cleanup now terminates exactly this compiler tree.
exit 0

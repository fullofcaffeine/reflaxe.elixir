#!/usr/bin/env bash
# with-timeout.sh — cross-platform timeout wrapper with graceful kill
# Usage: with-timeout.sh <seconds> <command...>
#
# Tries: gtimeout (GNU coreutils on macOS) → timeout (GNU coreutils) → repo portable wrapper.
#
# Notes:
# - On Windows runners, `timeout` may resolve to `timeout.exe` (not GNU). We must not invoke it.
# - The portable wrapper kills full process trees without relying on GNU coreutils.

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <seconds> <command...>" >&2
  exit 2
fi

DEADLINE="$1"; shift

have() { command -v "$1" >/dev/null 2>&1; }

is_gnu_timeout() {
  # GNU timeout prints "timeout (GNU coreutils) <ver>" as its first line.
  timeout --version 2>/dev/null | head -n 1 | grep -qi "GNU coreutils"
}

if have gtimeout; then
  exec gtimeout "${DEADLINE}s" "$@"
elif have timeout && is_gnu_timeout; then
  exec timeout "${DEADLINE}s" "$@"
else
  # Fall back to the repo's portable wrapper.
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
  exec "${ROOT_DIR}/scripts/with-timeout.sh" --secs "$DEADLINE" -- "$@"
fi

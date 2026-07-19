#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURE_SCRIPT="$ROOT_DIR/scripts/ci/haxe-server-owner-exit-fixture.exs"
FIXTURE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/haxe-server-owner-exit.XXXXXX")"
PID_FILE="$FIXTURE_ROOT/fake-haxe.pid"
FAKE_HAXE="$FIXTURE_ROOT/fake-haxe"

cleanup() {
  local status=$?
  trap - EXIT
  local child_pid=""
  if [ -s "$PID_FILE" ]; then
    child_pid="$(cat "$PID_FILE")"
    if [[ "$child_pid" =~ ^[0-9]+$ ]] && kill -0 "$child_pid" >/dev/null 2>&1; then
      kill -TERM "$child_pid" >/dev/null 2>&1 || true
    fi
  fi
  rm -rf "$FIXTURE_ROOT"
  exit "$status"
}
trap cleanup EXIT

cat >"$FAKE_HAXE" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$$" >"${HAXE_SERVER_OWNER_FIXTURE_PID_FILE:?missing PID file}"
trap 'exit 0' TERM INT HUP
while :; do
  sleep 0.1
done
FAKE
chmod +x "$FAKE_HAXE"

set +e
HAXE_SERVER_OWNER_FIXTURE_ROOT="$FIXTURE_ROOT" \
  HAXE_SERVER_OWNER_FIXTURE_HAXE="$FAKE_HAXE" \
  HAXE_SERVER_OWNER_FIXTURE_PID_FILE="$PID_FILE" \
  HAXE_NO_COMPILE=1 \
  "$ROOT_DIR/scripts/with-timeout.sh" --secs 30 \
  -- mix run --no-start "$FIXTURE_SCRIPT" >"$FIXTURE_ROOT/child.log" 2>&1
mix_status="$?"
set -e
if [ "$mix_status" -ne 0 ]; then
  cat "$FIXTURE_ROOT/child.log" >&2
  exit "$mix_status"
fi

grep -F "HAXE_SERVER_OWNER_CHILD_LIVE" "$FIXTURE_ROOT/child.log" >/dev/null \
  || { cat "$FIXTURE_ROOT/child.log" >&2; exit 1; }
[ -s "$PID_FILE" ] || { echo "owner-exit fixture did not retain the exact child PID" >&2; exit 1; }

child_pid="$(cat "$PID_FILE")"
[[ "$child_pid" =~ ^[0-9]+$ ]] || { echo "invalid fake Haxe PID: $child_pid" >&2; exit 1; }

for _attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  if ! kill -0 "$child_pid" >/dev/null 2>&1; then
    echo "HAXE_SERVER_OWNER_EXIT_FIXTURE:PASS"
    exit 0
  fi
  sleep 0.05
done

echo "HAXE_SERVER_OWNER_EXIT_FIXTURE:FAIL native child $child_pid survived its owning Mix VM" >&2
exit 1

#!/usr/bin/env bash
set -euo pipefail

# Reproduces the process shape left after a Node/Lix launcher disappears: the
# native Haxe command no longer contains the project path, but its working
# directory still identifies the repository that owns it.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLEANUP_SCRIPT="$ROOT_DIR/scripts/haxe-server-cleanup.sh"
FIXTURE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/haxe-server-cleanup.XXXXXX")"
PROJECT_ROOT="$FIXTURE_ROOT/project with spaces"
OTHER_ROOT="$FIXTURE_ROOT/other"
TOOLCHAIN_ROOT="$FIXTURE_ROOT/toolchain"
REPO_PID=""
OTHER_PID=""

fail() {
  echo "HAXE_SERVER_CLEANUP_FIXTURE:FAIL $*" >&2
  exit 1
}

cleanup() {
  for pid in "$REPO_PID" "$OTHER_PID"; do
    if [[ -n "$pid" ]]; then
      kill -TERM "$pid" >/dev/null 2>&1 || true
      kill -KILL "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
    fi
  done
  rm -rf "$FIXTURE_ROOT"
}
trap cleanup EXIT

mkdir -p "$PROJECT_ROOT" "$OTHER_ROOT" "$TOOLCHAIN_ROOT"
cat >"$TOOLCHAIN_ROOT/haxe" <<'FAKE_HAXE'
#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' TERM INT
while true; do
  sleep 1
done
FAKE_HAXE
chmod +x "$TOOLCHAIN_ROOT/haxe"

(
  cd "$PROJECT_ROOT"
  exec "$TOOLCHAIN_ROOT/haxe" --wait 39111
) >"$FIXTURE_ROOT/repo-server.log" 2>&1 &
REPO_PID="$!"
(
  cd "$OTHER_ROOT"
  exec "$TOOLCHAIN_ROOT/haxe" --wait 39112
) >"$FIXTURE_ROOT/other-server.log" 2>&1 &
OTHER_PID="$!"

sleep 0.2
kill -0 "$REPO_PID" >/dev/null 2>&1 || fail "repo-local fixture server did not start"
kill -0 "$OTHER_PID" >/dev/null 2>&1 || fail "unrelated fixture server did not start"

HAXE_SERVER_CLEANUP_ROOT="$PROJECT_ROOT" bash "$CLEANUP_SCRIPT" >"$FIXTURE_ROOT/cleanup.log" 2>&1
wait "$REPO_PID" >/dev/null 2>&1 || true

for _attempt in 1 2 3 4 5 6 7 8 9 10; do
  if ! kill -0 "$REPO_PID" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
if kill -0 "$REPO_PID" >/dev/null 2>&1; then
  fail "repo-local native Haxe child survived cleanup"
fi
kill -0 "$OTHER_PID" >/dev/null 2>&1 || fail "cleanup killed a server owned by another working directory"
grep -Fq "Found repo-local Haxe servers" "$FIXTURE_ROOT/cleanup.log" \
  || fail "cleanup did not report the server it owned"

HAXE_SERVER_CLEANUP_ROOT="$PROJECT_ROOT" bash "$CLEANUP_SCRIPT" >"$FIXTURE_ROOT/second-cleanup.log" 2>&1
grep -Fq "OK: no repo-local haxe --wait servers found" "$FIXTURE_ROOT/second-cleanup.log" \
  || fail "repeated cleanup was not idempotent"

echo "HAXE_SERVER_CLEANUP_FIXTURE:PASS"

#!/usr/bin/env bash
set -euo pipefail

# Reproduces the process shape left after a Node/Lix launcher disappears: the
# native Haxe command no longer contains the project path, but its working
# directory still identifies the repository that owns it.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLEANUP_SCRIPT="$ROOT_DIR/scripts/haxe-server-cleanup.sh"
PROCESS_CLASSIFIER="$ROOT_DIR/scripts/haxe-server-processes.awk"
FIXTURE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/haxe-server-cleanup.XXXXXX")"
PROJECT_ROOT="$FIXTURE_ROOT/project with spaces"
OTHER_ROOT="$FIXTURE_ROOT/other"
TOOLCHAIN_ROOT="$FIXTURE_ROOT/toolchain"
PROCESS_SNAPSHOT="$FIXTURE_ROOT/process-snapshot.txt"
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

classifier_output="$(printf '%s\n' \
  '101 haxe /tool/haxe --wait 39111' \
  '102 node node /tool/haxeshim.js --wait 39112' \
  '103 bash bash -lc echo haxe --wait 39113' \
  '104 node node diagnostic.js haxe --wait 39114' \
  '105 haxe /tool/haxe build.hxml' \
  | awk -f "$PROCESS_CLASSIFIER")"
printf '%s\n' "$classifier_output" | grep -F $'101\t/tool/haxe --wait 39111' >/dev/null \
  || fail "native Haxe server was not classified"
printf '%s\n' "$classifier_output" | grep -F $'102\tnode /tool/haxeshim.js --wait 39112' >/dev/null \
  || fail "Node/Haxeshim server was not classified"
if printf '%s\n' "$classifier_output" | grep -E '^(103|104|105)[[:space:]]' >/dev/null; then
  fail "diagnostic shell, unrelated Node process, or ordinary compiler was misclassified"
fi

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
) >/dev/null 2>&1 &
REPO_PID="$!"
(
  cd "$OTHER_ROOT"
  exec "$TOOLCHAIN_ROOT/haxe" --wait 39112
) >/dev/null 2>&1 &
OTHER_PID="$!"

sleep 0.2
kill -0 "$REPO_PID" >/dev/null 2>&1 || fail "repo-local fixture server did not start"
kill -0 "$OTHER_PID" >/dev/null 2>&1 || fail "unrelated fixture server did not start"
printf '%s haxe %s --wait 39111\n%s haxe %s --wait 39112\n' \
  "$REPO_PID" "$TOOLCHAIN_ROOT/haxe" "$OTHER_PID" "$TOOLCHAIN_ROOT/haxe" >"$PROCESS_SNAPSHOT"

HAXE_SERVER_CLEANUP_ROOT="$PROJECT_ROOT" \
  HAXE_SERVER_CLEANUP_PROCESS_SNAPSHOT="$PROCESS_SNAPSHOT" \
  bash "$CLEANUP_SCRIPT" >"$FIXTURE_ROOT/cleanup.log" 2>&1
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

printf '%s haxe %s --wait 39112\n' "$OTHER_PID" "$TOOLCHAIN_ROOT/haxe" >"$PROCESS_SNAPSHOT"
HAXE_SERVER_CLEANUP_ROOT="$PROJECT_ROOT" \
  HAXE_SERVER_CLEANUP_PROCESS_SNAPSHOT="$PROCESS_SNAPSHOT" \
  bash "$CLEANUP_SCRIPT" >"$FIXTURE_ROOT/second-cleanup.log" 2>&1
grep -Fq "OK: no repo-local haxe --wait servers found" "$FIXTURE_ROOT/second-cleanup.log" \
  || fail "repeated cleanup was not idempotent"

echo "HAXE_SERVER_CLEANUP_FIXTURE:PASS"

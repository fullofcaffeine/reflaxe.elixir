#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/qa-sentinel-port-ownership.XXXXXX)"
PORT_FILE="$TMP_DIR/port"
SERVER_LOG="$TMP_DIR/server.log"
SENTINEL_LOG="$TMP_DIR/sentinel.log"
DUMMY_PID=""

cleanup() {
  if [[ -n "$DUMMY_PID" ]] && kill -0 "$DUMMY_PID" 2>/dev/null; then
    kill -TERM "$DUMMY_PID" 2>/dev/null || true
    wait "$DUMMY_PID" 2>/dev/null || true
  fi
  find "$TMP_DIR" -type f -delete 2>/dev/null || true
  rmdir "$TMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

python3 -u -c '
import http.server

server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), http.server.SimpleHTTPRequestHandler)
print(server.server_address[1], flush=True)
server.serve_forever()
' >"$PORT_FILE" 2>"$SERVER_LOG" &
DUMMY_PID=$!

for _ in $(seq 1 50); do
  if [[ -s "$PORT_FILE" ]]; then
    break
  fi
  sleep 0.1
done

if [[ ! -s "$PORT_FILE" ]]; then
  echo "Dummy listener did not report its port" >&2
  exit 1
fi

PORT="$(head -n 1 "$PORT_FILE")"
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

if ! curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
  echo "Dummy listener never became ready on :$PORT" >&2
  exit 1
fi

set +e
"$REPO_ROOT/scripts/qa-sentinel.sh" \
  --app "$REPO_ROOT/examples/03-phoenix-app" \
  --hxml build.hxml \
  --port "$PORT" \
  --async \
  --deadline 30 >"$SENTINEL_LOG" 2>&1
sentinel_rc=$?
set -e

if [[ "$sentinel_rc" -eq 0 ]]; then
  echo "Sentinel unexpectedly accepted an occupied target port" >&2
  exit 1
fi

if ! rg -q "already in use; refusing to terminate an unowned process" "$SENTINEL_LOG"; then
  echo "Sentinel did not explain the occupied-port refusal" >&2
  tail -n 50 "$SENTINEL_LOG" >&2 || true
  exit 1
fi

if rg -q "QA_SENTINEL_PID=" "$SENTINEL_LOG"; then
  echo "Sentinel dispatched background work despite the occupied port" >&2
  exit 1
fi

if ! kill -0 "$DUMMY_PID" 2>/dev/null || ! curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
  echo "Sentinel terminated or disrupted the unrelated listener" >&2
  exit 1
fi

echo "QA sentinel port-ownership smoke passed"

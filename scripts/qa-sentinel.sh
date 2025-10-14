#!/usr/bin/env bash
set -euo pipefail

# QA Sentinel: Compile, run, curl /, assert zero warnings/errors
# Usage: scripts/qa-sentinel.sh [--app examples/todo-app] [--port 4001]

APP_DIR="examples/todo-app"
PORT=4001

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APP_DIR="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

echo "[QA] Building Haxe → Elixir in $APP_DIR"
pushd "$APP_DIR" >/dev/null

# Generate .ex files (full server build to ensure all modules are regenerated)
npx -y haxe build-server.hxml

echo "[QA] Fetching deps and compiling with WAE"
MIX_ENV=dev mix deps.get
MIX_ENV=dev mix compile --warnings-as-errors

echo "[QA] Starting server on :$PORT"
export PORT="$PORT"
MIX_ENV=dev mix phx.server >/tmp/qa-phx.log 2>&1 &
PHX_PID=$!
trap 'kill $PHX_PID >/dev/null 2>&1 || true' EXIT

echo "[QA] Waiting for server..."
for i in {1..30}; do
  if curl -fsS "http://localhost:$PORT" >/dev/null 2>&1; then
    READY=1; break
  fi
  sleep 0.3
done

if [[ "${READY:-0}" -ne 1 ]]; then
  echo "[QA] Server not responding on port $PORT; attempting fallback detection from logs..."
  tail -n 100 /tmp/qa-phx.log || true
  # Try to detect from "Access ... http://localhost:PORT" first, else from "at 127.0.0.1:PORT"
  DETECTED_PORT=$(grep -Eo 'http://localhost:[0-9]+' /tmp/qa-phx.log | tail -n1 | sed -E 's/.*:([0-9]+)/\1/' || true)
  if [[ -z "$DETECTED_PORT" ]]; then
    DETECTED_PORT=$(grep -Eo '127\.0\.0\.1:[0-9]+' /tmp/qa-phx.log | tail -n1 | sed -E 's/.*:([0-9]+)/\1/' || true)
  fi
  if [[ -n "$DETECTED_PORT" ]]; then
    echo "[QA] Detected endpoint port: $DETECTED_PORT. Waiting for readiness..."
    for i in {1..30}; do
      if curl -fsS "http://localhost:$DETECTED_PORT" >/dev/null 2>&1; then
        echo "[QA] GET / on detected port $DETECTED_PORT succeeded"
        echo "[QA] OK: build + runtime smoke passed (fallback port)"
        popd >/dev/null
        exit 0
      fi
      sleep 0.3
    done
  fi
  echo "[QA] Fallback failed."
  exit 1
fi

echo "[QA] GET /"
curl -fsS "http://localhost:$PORT" >/dev/null

echo "[QA] OK: build + runtime smoke passed with zero warnings (WAE)"
popd >/dev/null

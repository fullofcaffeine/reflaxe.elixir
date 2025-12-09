#!/usr/bin/env bash
set -uo pipefail

# Bisect test for create_todo functionality
# Exit 0 if test passes (good commit), 1 if fails (bad commit), 125 if skip

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/examples/todo-app"
PORT="${PORT:-4099}"

# Cleanup any existing processes
pkill -f "beam.smp" 2>/dev/null || true
pkill -f "mix phx.server" 2>/dev/null || true
sleep 2

# Clean generated files
rm -rf "$APP_DIR/lib"/*.ex "$APP_DIR/lib"/**/*.ex 2>/dev/null || true

cd "$APP_DIR"

echo "=== Step 1: Haxe build ==="
timeout 180 npx haxe build-server.hxml 2>&1 || { echo "SKIP: Haxe build failed"; exit 125; }

echo "=== Step 2: Mix deps.get ==="
timeout 120 mix deps.get 2>&1 || { echo "SKIP: deps.get failed"; exit 125; }

echo "=== Step 3: Mix compile ==="
timeout 180 mix compile --force 2>&1 || { echo "SKIP: Mix compile failed"; exit 125; }

echo "=== Step 4: Start Phoenix ==="
PORT=$PORT MIX_ENV=dev mix phx.server > /tmp/qa-bisect-phx.log 2>&1 &
PHX_PID=$!
trap "kill $PHX_PID 2>/dev/null; pkill -f 'beam.smp' 2>/dev/null" EXIT

# Wait for server
echo "Waiting for server on port $PORT..."
for i in $(seq 1 60); do
    if curl -sf "http://localhost:$PORT/" >/dev/null 2>&1; then
        echo "Server ready!"
        break
    fi
    sleep 1
done

if ! curl -sf "http://localhost:$PORT/" >/dev/null 2>&1; then
    echo "SKIP: Server failed to start"
    cat /tmp/qa-bisect-phx.log | tail -50
    exit 125
fi

echo "=== Step 5: Run create_todo Playwright test ==="
cd "$APP_DIR"
BASE_URL="http://localhost:$PORT" timeout 60 npx playwright test e2e/create_todo.spec.ts --reporter=line 2>&1
TEST_EXIT=$?

if [ $TEST_EXIT -eq 0 ]; then
    echo "TEST PASSED - good commit"
    exit 0
else
    echo "TEST FAILED - bad commit"
    exit 1
fi

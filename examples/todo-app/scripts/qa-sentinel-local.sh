#!/usr/bin/env bash
set -euo pipefail

# Robust local QA sentinel for the todo-app.
# - Kills anything listening on 4000
# - Builds Haxe → Elixir
# - mix compile with WAE
# - Boots Phoenix in the background with log capture
# - Waits (bounded) for readiness and curls /
# - Shuts down and prints a concise log excerpt

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

mkdir -p tmp

TIMEOUT="${ROOT_DIR}/../../scripts/with-timeout.sh"
if [[ ! -x "$TIMEOUT" ]]; then
  echo "[qa][FAIL] Missing timeout helper: $TIMEOUT"
  exit 1
fi

pick_available_port() {
  local base="${1:-25000}"
  local port
  for port in $(seq "$base" $((base + 200))); do
    if ! lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      echo "$port"
      return 0
    fi
  done
  return 1
}

HAXE_CMD=""
if [[ -x "${ROOT_DIR}/../../node_modules/.bin/haxe" ]]; then
  HAXE_CMD="${ROOT_DIR}/../../node_modules/.bin/haxe"
elif command -v haxe >/dev/null 2>&1; then
  HAXE_CMD="haxe"
else
  HAXE_CMD="npx -y haxe"
fi

# Avoid haxeshim's noisy default internal port (often 6001) when using the Node shim.
if [[ -z "${HAXESHIM_SERVER_PORT:-}" ]]; then
  base=$((25000 + (RANDOM % 15000)))
  if port="$(pick_available_port "$base")"; then
    export HAXESHIM_SERVER_PORT="$port"
  fi
fi

echo "[qa] Killing any process on :4000 and stray mix phx.server…"
(lsof -ti tcp:4000 || true) | xargs -I{} kill -9 {} 2>/dev/null || true
ps -A -o pid,command | rg "mix phx.server" | awk '{print $1}' | xargs -I{} kill -9 {} 2>/dev/null || true

echo "[qa] Building Haxe → Elixir…"
if ! "$TIMEOUT" --secs 480 -- bash -lc "$HAXE_CMD build-server.hxml" > tmp/haxe_build.log 2>&1; then
  echo "[qa][FAIL] Haxe build failed"; head -n 160 tmp/haxe_build.log; exit 2;
fi

# Compile Elixir with warnings-as-errors, but skip re-running Haxe (we just built it).
echo "[qa] mix compile --warnings-as-errors (WAE)…"
if ! "$TIMEOUT" --secs 420 -- env HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix compile --warnings-as-errors --force > tmp/mix_compile.log 2>&1; then
  echo "[qa][FAIL] Mix compile failed"; head -n 160 tmp/mix_compile.log; exit 3;
fi

echo "[qa] Ensuring DB exists + migrated…"
if ! "$TIMEOUT" --secs 120 -- env HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix ecto.create --quiet > tmp/mix_ecto_create.log 2>&1; then
  echo "[qa][FAIL] mix ecto.create failed"; head -n 160 tmp/mix_ecto_create.log; exit 4;
fi
if ! "$TIMEOUT" --secs 300 -- env HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix ecto.migrate > tmp/mix_ecto_migrate.log 2>&1; then
  echo "[qa][FAIL] mix ecto.migrate failed"; head -n 160 tmp/mix_ecto_migrate.log; exit 5;
fi

echo "[qa] Booting Phoenix in background…"
rm -f tmp/server_4000.pid tmp/server_4000.log
# Keep this a bounded smoke check; do not run endpoint watchers here.
DISABLE_WATCHERS=1 HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix phx.server > tmp/server_4000.log 2>&1 & echo $! > tmp/server_4000.pid

PID=$(cat tmp/server_4000.pid)
echo "[qa] Server pid=$PID"

echo "[qa] Waiting for readiness (max 20s)…"
READY=0
for i in $(seq 1 40); do
  if curl -sS -m 2 -o /dev/null http://localhost:4000/ >/dev/null 2>&1; then READY=1; break; fi
  sleep 0.5
done

if [ "$READY" != "1" ]; then
  echo "[qa][FAIL] Server did not become ready in time. Showing log excerpt:"
  kill $PID 2>/dev/null || true
  sleep 1
  sed -n '1,160p' tmp/server_4000.log
  exit 6
fi

STATUS=$(curl -sS -m 3 -o /dev/null -w "%{http_code}\n" http://localhost:4000/ || true)
echo "[qa] HTTP status: $STATUS"

kill $PID 2>/dev/null || true
sleep 1

echo "[qa] --- Server log (first 160 lines) ---"
sed -n '1,160p' tmp/server_4000.log
echo "[qa] --- end ---"

if [ "$STATUS" != "200" ] && [ "$STATUS" != "302" ]; then
  echo "[qa][WARN] Non-200/302 response; investigate above log."
  exit 7
fi

echo "[qa][OK] Build+boot+curl flow succeeded."

#!/usr/bin/env bash
set -euo pipefail
cd examples/todo-app || exit 125
# Ensure deps are present quickly
if [ ! -d deps ]; then mix deps.get >/dev/null 2>&1 || exit 125; fi
# Clean outputs to force haxe
rm -rf lib _build tmp || true
mkdir -p tmp || true
# Launch mix phx.server bounded
( HAXE_TIMEOUT_SECS=20 PORT=4010 MIX_ENV=dev mix phx.server > tmp/bisect-fast.log 2>&1 & echo $! > tmp/bisect-fast.pid ) || true
pid="$(cat tmp/bisect-fast.pid 2>/dev/null || true)"
# poll for generated ex files
ok=0
for _ in $(seq 1 10); do
  cnt=$(find lib -type f -name '*.ex' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${cnt:-0}" -ge 5 ]; then ok=1; break; fi
  sleep 1
done
# cleanup
if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
  kill -TERM "$pid" 2>/dev/null || true
  sleep 1
  kill -KILL "$pid" 2>/dev/null || true
fi
if [ "$ok" -eq 1 ]; then exit 0; else tail -n 120 tmp/bisect-fast.log >&2 || true; exit 1; fi

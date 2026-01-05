#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Performance + determinism budgets (reference apps)
#
# WHAT
# - Enforces two non-flaky guardrails on reference apps:
#   1) Determinism: two consecutive Haxe builds produce identical outputs.
#   2) Performance: builds must complete within generous time budgets (timeouts).
#
# WHY
# - Prevent regressions where output order becomes non-deterministic or builds hang.
# - Keep budgets stable in CI by avoiding “tight” wall-time assertions.
#
# HOW
# - Build todo-app server and client twice into a temp workspace.
# - Diff output directories between runs.
# - Use scripts/with-timeout.sh for bounded execution.
# -----------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
HAXE_BIN="${HAXE_BIN:-haxe}"

TODO_APP_DIR="$ROOT_DIR/examples/todo-app"

SERVER_TIMEOUT_SECS="${SERVER_TIMEOUT_SECS:-240}"
CLIENT_TIMEOUT_SECS="${CLIENT_TIMEOUT_SECS:-180}"

if [[ ! -x "$TIMEOUT" ]]; then
  echo "[budgets] ERROR: missing timeout wrapper: $TIMEOUT" >&2
  exit 2
fi

tmp_base="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-budgets.XXXXXX")"
trap 'rm -rf "$tmp_base" 2>/dev/null || true' EXIT

log() { echo "[budgets] $*"; }

rewrite_hxml_define() {
  local src="$1"; shift
  local out="$1"; shift
  local key="$1"; shift
  local value="$1"; shift

  python3 - "$src" "$out" "$key" "$value" <<'PY'
import io
import os
import sys

src, out, key, value = sys.argv[1:5]
lines = open(src, "r", encoding="utf-8").read().splitlines(True)
replaced = False
prefix = f"-D {key}="

for i, line in enumerate(lines):
    if line.startswith(prefix):
        lines[i] = f"{prefix}{value}\n"
        replaced = True
        break

if not replaced:
    raise SystemExit(f"missing define in {src}: {prefix}...")

os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w", encoding="utf-8").write("".join(lines))
PY
}

rewrite_hxml_js_output() {
  local src="$1"; shift
  local out="$1"; shift
  local js_path="$1"; shift

  python3 - "$src" "$out" "$js_path" <<'PY'
import os
import sys

src, out, js_path = sys.argv[1:4]
lines = open(src, "r", encoding="utf-8").read().splitlines(True)
replaced = False

for i, line in enumerate(lines):
    if line.startswith("-js "):
        lines[i] = f"-js {js_path}\n"
        replaced = True
        break

if not replaced:
    raise SystemExit(f"missing -js directive in {src}")

os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w", encoding="utf-8").write("".join(lines))
PY
}

run_haxe() {
  local desc="$1"; shift
  local secs="$1"; shift
  local cwd="$1"; shift
  local hxml="$1"; shift

  log "$desc (timeout=${secs}s)"
  local start end
  start="$(date +%s)"
  "$TIMEOUT" --secs "$secs" --cwd "$cwd" -- "$HAXE_BIN" "$hxml"
  end="$(date +%s)"
  log "✅ $desc done in $((end-start))s"
}

diff_dirs() {
  local a="$1"; shift
  local b="$1"; shift
  local label="$1"; shift

  if diff -ru "$a" "$b" >"$tmp_base/${label}.diff" 2>&1; then
    log "✅ determinism OK: $label"
    return 0
  fi

  log "❌ determinism FAILED: $label"
  log "Showing first 200 lines of diff:"
  sed -n '1,200p' "$tmp_base/${label}.diff" >&2
  return 1
}

log "Workspace: $tmp_base"

# -----------------------------------------------------------------------------
# Todo-app (server)
# -----------------------------------------------------------------------------

server_out="$tmp_base/todo_server/out"
server_snap="$tmp_base/todo_server/snap"
mkdir -p "$server_out"

server_hxml="$tmp_base/todo_server/build-server.budget.hxml"
rewrite_hxml_define "$TODO_APP_DIR/build-server.hxml" "$server_hxml" "elixir_output" "$server_out"

rm -rf "$server_out" "$server_snap"
mkdir -p "$server_out"
run_haxe "todo-app server build (run 1)" "$SERVER_TIMEOUT_SECS" "$TODO_APP_DIR" "$server_hxml"
cp -R "$server_out" "$server_snap"

rm -rf "$server_out"
mkdir -p "$server_out"
run_haxe "todo-app server build (run 2)" "$SERVER_TIMEOUT_SECS" "$TODO_APP_DIR" "$server_hxml"
diff_dirs "$server_snap" "$server_out" "todo_server"

# -----------------------------------------------------------------------------
# Todo-app (client)
# -----------------------------------------------------------------------------

client_out="$tmp_base/todo_client/out"
client_snap="$tmp_base/todo_client/snap"
mkdir -p "$client_out"

client_hxml="$tmp_base/todo_client/build-client.budget.hxml"
rewrite_hxml_js_output "$TODO_APP_DIR/build-client.hxml" "$client_hxml" "$client_out/hx_app.js"

rm -rf "$client_out" "$client_snap"
mkdir -p "$client_out"
run_haxe "todo-app client build (run 1)" "$CLIENT_TIMEOUT_SECS" "$TODO_APP_DIR" "$client_hxml"
cp -R "$client_out" "$client_snap"

rm -rf "$client_out"
mkdir -p "$client_out"
run_haxe "todo-app client build (run 2)" "$CLIENT_TIMEOUT_SECS" "$TODO_APP_DIR" "$client_hxml"
diff_dirs "$client_snap" "$client_out" "todo_client"

log "✅ budgets OK"

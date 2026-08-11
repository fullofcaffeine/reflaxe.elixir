#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
SERVER_PID=""
TMP_ROOT=""

cleanup() {
	if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
		kill -TERM "$SERVER_PID" 2>/dev/null || true
		wait "$SERVER_PID" 2>/dev/null || true
	fi
	if [[ -n "$TMP_ROOT" && -d "$TMP_ROOT" ]]; then
		find "$TMP_ROOT" -depth -delete 2>/dev/null || true
	fi
}
trap cleanup EXIT INT TERM

resolve_haxe_server_binary() {
	if [[ -n "${HAXE_SERVER_BIN:-}" ]]; then
		printf '%s\n' "$HAXE_SERVER_BIN"
		return
	fi

	local version user_home candidate
	version="$(python3 - "$ROOT_DIR/.haxerc" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    print(json.load(source)["version"])
PY
)"
	user_home="$(python3 - <<'PY'
from pathlib import Path
print(Path.home())
PY
)"

	for candidate in \
		"$user_home/haxe/versions/$version/haxe" \
		"$user_home/.haxe/versions/$version/haxe" \
		"$(command -v haxe 2>/dev/null || true)"
	do
		if [[ -x "$candidate" ]] && ! head -n 1 "$candidate" 2>/dev/null | grep -q '/usr/bin/env node'; then
			printf '%s\n' "$candidate"
			return
		fi
	done

	echo "[reference-diagnostic-server] native Haxe $version was not found" >&2
	return 1
}

write_hxml() {
	local project="$1"
	local main_type="$2"
	cat >"$project/compile.hxml" <<HXML
-cp src
-cp $ROOT_DIR/src
-cp $ROOT_DIR/std
-cp $ROOT_DIR/std/elixir/_std
-lib reflaxe
-D reflaxe_runtime
-D elixir_output=out
--macro reflaxe.elixir.CompilerInit.Start()
$main_type
HXML
}

write_safe_source() {
	local project="$1"
	cat >"$project/src/Main.hx" <<'HAXE'
class Main {
	static function main():Void {
		var values = [1];
		var alias = values;
		values.push(2);
		trace(values.length);
	}
}
HAXE
}

write_bad_source() {
	local project="$1"
	local main_type="$2"
	cat >"$project/src/$main_type.hx" <<HAXE
class $main_type {
	static function main():Void {
		var values = [1];
		var alias = values;
		values.push(2);
		trace(alias.length);
	}
}
HAXE
}

compile_success() {
	local project="$1"
	local label="$2"
	if ! "$TIMEOUT" --secs 120 --cwd "$project" -- "$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml >"$TMP_ROOT/$label.log" 2>&1; then
		echo "[reference-diagnostic-server] expected success for $label" >&2
		sed -n '1,120p' "$TMP_ROOT/$label.log" >&2
		exit 1
	fi
}

compile_diagnostic() {
	local project="$1"
	local label="$2"
	local log="$TMP_ROOT/$label.log"
	if "$TIMEOUT" --secs 120 --cwd "$project" -- "$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml >"$log" 2>&1; then
		echo "[reference-diagnostic-server] expected the diagnostic for $label" >&2
		exit 1
	fi

	local count
	count="$(grep -Fc 'Reflaxe.Elixir cannot preserve this shared Array mutation.' "$log" || true)"
	if [[ "$count" -ne 1 ]]; then
		echo "[reference-diagnostic-server] expected one diagnostic for $label, found $count" >&2
		sed -n '1,120p' "$log" >&2
		exit 1
	fi
}

HAXE_BIN="$(resolve_haxe_server_binary)"
mkdir -p "$ROOT_DIR/tmp"
TMP_ROOT="$(mktemp -d "$ROOT_DIR/tmp/reference-diagnostic-server.XXXXXX")"
PROJECT_A="$TMP_ROOT/project-a"
PROJECT_B="$TMP_ROOT/project-b"
mkdir -p "$PROJECT_A/src" "$PROJECT_B/src"
write_hxml "$PROJECT_A" "Main"
write_hxml "$PROJECT_B" "OtherMain"
write_safe_source "$PROJECT_A"
write_bad_source "$PROJECT_B" "OtherMain"

export HAXELIB_PATH="$ROOT_DIR${HAXELIB_PATH:+:$HAXELIB_PATH}"
SERVER_PORT="$(python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"

"$HAXE_BIN" --wait "$SERVER_PORT" </dev/null >"$TMP_ROOT/server.log" 2>&1 &
SERVER_PID="$!"

# Haxe exposes no server-ready event. This bounded protocol request is the
# authoritative readiness check; elapsed time is not treated as success.
ready=0
for _attempt in $(seq 1 100); do
	if "$HAXE_BIN" --connect "$SERVER_PORT" -version >/dev/null 2>&1; then
		ready=1
		break
	fi
	if ! kill -0 "$SERVER_PID" 2>/dev/null; then
		break
	fi
	sleep 0.1
done
if [[ "$ready" != 1 ]]; then
	echo "[reference-diagnostic-server] Haxe server did not become ready" >&2
	sed -n '1,120p' "$TMP_ROOT/server.log" >&2
	exit 1
fi

compile_success "$PROJECT_A" "project-a-safe-1"
write_bad_source "$PROJECT_A" "Main"
compile_diagnostic "$PROJECT_A" "project-a-bad"
write_safe_source "$PROJECT_A"
compile_success "$PROJECT_A" "project-a-safe-2"
compile_diagnostic "$PROJECT_B" "project-b-bad"

echo "[reference-diagnostic-server] safe -> bad -> safe and cross-root checks passed on one Haxe server"

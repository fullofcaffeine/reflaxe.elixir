#!/usr/bin/env bash
set -euo pipefail

# A normal snapshot proves the baseline generated shape. This companion check
# keeps one real Haxe compilation server alive while non-class type definitions
# change. After every edit, its output must equal a clean one-shot compilation.

FIXTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$FIXTURE_DIR/../../../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
SERVER_PID=""
TMP_ROOT=""

cleanup() {
	local exit_code="$?"
	if [[ "$exit_code" != "0" && -n "$TMP_ROOT" && -f "$TMP_ROOT/server.log" ]]; then
		echo "--- Haxe server log after fixture failure ---" >&2
		sed -n '1,240p' "$TMP_ROOT/server.log" >&2
		echo "--- end Haxe server log ---" >&2
	fi

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

	echo "server-cache fixture could not find the real Haxe $version binary" >&2
	echo "set HAXE_SERVER_BIN to the native haxe executable, not the Node haxeshim" >&2
	return 1
}

compare_generated_output() {
	local expected="$1"
	local actual="$2"
	local label="$3"

	python3 - "$expected" "$actual" "$label" <<'PY'
import json
from pathlib import Path
import sys

expected_root = Path(sys.argv[1])
actual_root = Path(sys.argv[2])
label = sys.argv[3]

def generated_files(root: Path):
    manifest = json.loads((root / "_GeneratedFiles.json").read_text(encoding="utf-8"))
    result = {}
    for relative in manifest["filesGenerated"]:
        path = Path(relative)
        if path.is_absolute() or ".." in path.parts:
            raise SystemExit(f"{label}: unsafe generated path {relative!r}")
        result[path.as_posix()] = (root / path).read_bytes()
    return result

expected = generated_files(expected_root)
actual = generated_files(actual_root)
if expected == actual:
    print(f"SERVER_CACHE_PARITY:{label}:PASS files={len(expected)}")
    raise SystemExit(0)

all_paths = sorted(set(expected) | set(actual))
for path in all_paths:
    if expected.get(path) != actual.get(path):
        print(f"SERVER_CACHE_PARITY:{label}:MISMATCH {path}", file=sys.stderr)
raise SystemExit(1)
PY
}

open_fd_count() {
	local pid="$1"
	if [[ -d "/proc/$pid/fd" ]]; then
		python3 - "$pid" <<'PY'
import os
import sys
print(len(os.listdir(f"/proc/{sys.argv[1]}/fd")))
PY
	elif command -v lsof >/dev/null 2>&1; then
		lsof -p "$pid" -Fn 2>/dev/null | awk '/^f[0-9]+$/ { count += 1 } END { print count + 0 }'
	else
		printf '\n'
	fi
}

compile_direct() {
	local output="$1"
	"$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$output"
}

compile_server() {
	local output="$1"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$output"
	then
		return
	fi

	local server_process="stopped"
	local server_protocol="unavailable"
	if kill -0 "$SERVER_PID" 2>/dev/null; then
		server_process="alive"
		if "$HAXE_BIN" --connect "$SERVER_PORT" -version >/dev/null 2>&1; then
			server_protocol="responsive"
		fi
	fi
	echo "SERVER_CACHE_PARITY:compile-failed process=$server_process protocol=$server_protocol" >&2
	return 1
}

restore_baseline_sources() {
	cp "$FIXTURE_DIR/CacheStatus.hx" "$PROJECT_DIR/src/CacheStatus.hx"
	cp "$FIXTURE_DIR/CachePayload.hx" "$PROJECT_DIR/src/CachePayload.hx"
	cp "$FIXTURE_DIR/CacheCode.hx" "$PROJECT_DIR/src/CacheCode.hx"
}

run_variant() {
	local name="$1"
	local source_name="$2"
	local variant_source="$3"
	local generated_file="$4"
	local required_text="$5"
	local direct_output="$TMP_ROOT/direct-$name"

	cp "$variant_source" "$PROJECT_DIR/src/$source_name"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_output"
	compare_generated_output "$direct_output" "$SERVER_OUTPUT" "$name-B"
	grep -Fq "$required_text" "$SERVER_OUTPUT/$generated_file" || {
		echo "SERVER_CACHE_PARITY:$name-B did not make the edited type visible in $generated_file" >&2
		return 1
	}

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "$name-A-restored"
}

HAXE_BIN="$(resolve_haxe_server_binary)"
HAXE_VERSION="$($HAXE_BIN -version)"
EXPECTED_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT_DIR/.haxerc")"
if [[ "$HAXE_VERSION" != "$EXPECTED_VERSION" ]]; then
	echo "server-cache fixture expected Haxe $EXPECTED_VERSION, got $HAXE_VERSION" >&2
	exit 1
fi

TMP_ROOT="$(mktemp -d "$ROOT_DIR/tmp/server-cache-non-class.XXXXXX")"
PROJECT_DIR="$TMP_ROOT/project"
SERVER_OUTPUT="$TMP_ROOT/server-output"
DIRECT_BASELINE="$TMP_ROOT/direct-baseline"
mkdir -p "$PROJECT_DIR/src"
cp "$FIXTURE_DIR/Main.hx" "$PROJECT_DIR/src/Main.hx"
restore_baseline_sources

cat >"$PROJECT_DIR/compile.hxml" <<'HXML'
-cp src
-lib reflaxe
-lib reflaxe.elixir
-D reflaxe_runtime
--no-output
Main
HXML

# The native Haxe server still resolves this repository's Lix-scoped libraries
# through HAXELIB_PATH. It must not be replaced by the Node haxeshim because the
# shim does not speak Haxe's --wait/--connect protocol directly.
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

server_ready=0
for _attempt in $(seq 1 100); do
	if "$HAXE_BIN" --connect "$SERVER_PORT" -version >/dev/null 2>&1; then
		server_ready=1
		break
	fi
	if ! kill -0 "$SERVER_PID" 2>/dev/null; then
		break
	fi
	sleep 0.1
done

if [[ "$server_ready" != "1" ]]; then
	echo "server-cache fixture could not start Haxe on port $SERVER_PORT" >&2
	sed -n '1,160p' "$TMP_ROOT/server.log" >&2
	exit 1
fi

compile_server "$SERVER_OUTPUT"
compile_direct "$DIRECT_BASELINE"
compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "baseline-A"
BASELINE_FD_COUNT="$(open_fd_count "$SERVER_PID")"

run_variant \
	"enum" \
	"CacheStatus.hx" \
	"$FIXTURE_DIR/variants/enum/CacheStatus.hx" \
	"cache_status.ex" \
	"def archived()"

run_variant \
	"typedef" \
	"CachePayload.hx" \
	"$FIXTURE_DIR/variants/typedef/CachePayload.hx" \
	"main.ex" \
	"payload.value + payload.value"

run_variant \
	"abstract" \
	"CacheCode.hx" \
	"$FIXTURE_DIR/variants/abstract/CacheCode.hx" \
	"main.ex" \
	"code * 2"

FINAL_FD_COUNT="$(open_fd_count "$SERVER_PID")"
if [[ -n "$BASELINE_FD_COUNT" && -n "$FINAL_FD_COUNT" ]]; then
	FD_GROWTH=$((FINAL_FD_COUNT - BASELINE_FD_COUNT))
	if ((FD_GROWTH > 32)); then
		echo "SERVER_CACHE_FD_LEAK: baseline=$BASELINE_FD_COUNT final=$FINAL_FD_COUNT growth=$FD_GROWTH" >&2
		exit 1
	fi
	echo "SERVER_CACHE_FDS:PASS baseline=$BASELINE_FD_COUNT final=$FINAL_FD_COUNT"
fi

echo "SERVER_CACHE_NON_CLASS_INVALIDATION:PASS"

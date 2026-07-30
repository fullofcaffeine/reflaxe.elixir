#!/usr/bin/env bash
set -euo pipefail

# A normal snapshot proves the baseline generated shape. This companion check
# keeps one real Haxe compilation server alive while types and configuration
# change, then verifies a second project through its own isolated server. After
# every edit, output and source maps must equal a clean one-shot compilation.

FIXTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$FIXTURE_DIR/../../../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
SERVER_PID=""
SECONDARY_SERVER_PID=""
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
	if [[ -n "$SECONDARY_SERVER_PID" ]] && kill -0 "$SECONDARY_SERVER_PID" 2>/dev/null; then
		kill -TERM "$SECONDARY_SERVER_PID" 2>/dev/null || true
		wait "$SECONDARY_SERVER_PID" 2>/dev/null || true
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
import difflib
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
    for source_map in root.rglob("*.ex.map"):
        relative = source_map.relative_to(root).as_posix()
        result[relative] = source_map.read_bytes()
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
        if path.endswith(".map") and expected.get(path) is not None and actual.get(path) is not None:
            expected_text = expected[path].decode("utf-8", errors="replace").splitlines()
            actual_text = actual[path].decode("utf-8", errors="replace").splitlines()
            for line in difflib.unified_diff(expected_text, actual_text, fromfile="direct", tofile="server", lineterm=""):
                print(line, file=sys.stderr)
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
	shift
	"$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$output" "$@"
}

compile_server() {
	local output="$1"
	shift
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$output" "$@"
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

write_project_hxml() {
	local project="$1"
	local extra_define="${2:-}"

	{
		cat <<'HXML'
-cp src
-lib reflaxe
-lib reflaxe.elixir
-D reflaxe_runtime
-D source-map
--no-output
HXML
		if [[ -n "$extra_define" ]]; then
			printf '%s\n' "-D $extra_define"
		fi
		printf '%s\n' "Main"
	} >"$project/compile.hxml"
}

compile_project_direct() {
	local project="$1"
	local output="$2"
	"$TIMEOUT" --secs 120 --cwd "$project" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$output"
}

compile_project_server() {
	local project="$1"
	local output="$2"
	local port="${3:-$SERVER_PORT}"
	"$TIMEOUT" --secs 120 --cwd "$project" -- \
		"$HAXE_BIN" --connect "$port" compile.hxml -D "elixir_output=$output"
}

start_secondary_server() {
	SECONDARY_SERVER_PORT="$(python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"
	"$HAXE_BIN" --wait "$SECONDARY_SERVER_PORT" </dev/null >"$TMP_ROOT/server-secondary.log" 2>&1 &
	SECONDARY_SERVER_PID="$!"

	local ready=0
	for _attempt in $(seq 1 100); do
		if "$HAXE_BIN" --connect "$SECONDARY_SERVER_PORT" -version >/dev/null 2>&1; then
			ready=1
			break
		fi
		if ! kill -0 "$SECONDARY_SERVER_PID" 2>/dev/null; then
			break
		fi
		sleep 0.1
	done
	if [[ "$ready" != "1" ]]; then
		echo "SERVER_CACHE_PARITY:could not start the project-B Haxe server" >&2
		sed -n '1,160p' "$TMP_ROOT/server-secondary.log" >&2
		return 1
	fi
}

restore_baseline_sources() {
	cp "$FIXTURE_DIR/Main.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/CacheStatus.hx" "$PROJECT_DIR/src/CacheStatus.hx"
	cp "$FIXTURE_DIR/CachePayload.hx" "$PROJECT_DIR/src/CachePayload.hx"
	cp "$FIXTURE_DIR/CacheCode.hx" "$PROJECT_DIR/src/CacheCode.hx"
	rm -f \
		"$PROJECT_DIR/src/CacheLegacy.hx" \
		"$PROJECT_DIR/src/CacheRenamed.hx" \
		"$PROJECT_DIR/src/CacheTemplate.hx" \
		"$PROJECT_DIR/src/HookName.hx" \
		"$PROJECT_DIR/src/ExternalValueMacro.hx"
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

run_module_rename_variant() {
	local direct_legacy="$TMP_ROOT/direct-module-legacy"
	local direct_renamed="$TMP_ROOT/direct-module-renamed"

	cp "$FIXTURE_DIR/variants/module-rename/MainLegacy.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/variants/module-rename/CacheLegacy.hx" "$PROJECT_DIR/src/CacheLegacy.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_legacy"
	compare_generated_output "$direct_legacy" "$SERVER_OUTPUT" "module-add-legacy"

	rm "$PROJECT_DIR/src/CacheLegacy.hx"
	cp "$FIXTURE_DIR/variants/module-rename/MainRenamed.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/variants/module-rename/CacheRenamed.hx" "$PROJECT_DIR/src/CacheRenamed.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_renamed"
	compare_generated_output "$direct_renamed" "$SERVER_OUTPUT" "module-rename"
	if [[ -e "$SERVER_OUTPUT/cache_legacy.ex" ]]; then
		echo "SERVER_CACHE_PARITY:module-rename left deleted cache_legacy.ex on disk" >&2
		return 1
	fi
	grep -Fq '"renamed"' "$SERVER_OUTPUT/cache_renamed.ex" || {
		echo "SERVER_CACHE_PARITY:module-rename did not generate cache_renamed.ex" >&2
		return 1
	}

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "module-delete-restored"
	if [[ -e "$SERVER_OUTPUT/cache_renamed.ex" ]]; then
		echo "SERVER_CACHE_PARITY:module-delete-restored left deleted cache_renamed.ex on disk" >&2
		return 1
	fi
}

run_hxx_registry_variant() {
	local direct_known="$TMP_ROOT/direct-hxx-registry-known"
	local direct_restored="$TMP_ROOT/direct-hxx-registry-restored"
	local direct_failure_log="$TMP_ROOT/direct-hxx-registry-renamed.log"
	local server_failure_log="$TMP_ROOT/server-hxx-registry-renamed.log"

	cp "$FIXTURE_DIR/variants/hxx-registry/MainHxx.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/variants/hxx-registry/CacheTemplate.hx" "$PROJECT_DIR/src/CacheTemplate.hx"
	cp "$FIXTURE_DIR/variants/hxx-registry/HookNameKnown.hx" "$PROJECT_DIR/src/HookName.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_known"
	compare_generated_output "$direct_known" "$SERVER_OUTPUT" "hxx-registry-known"

	# CacheTemplate is unchanged and does not reference HookName directly. Only
	# the global registry changes, so a warm build must still revalidate the
	# template and reject the name that is no longer registered.
	cp "$FIXTURE_DIR/variants/hxx-registry/HookNameRenamed.hx" "$PROJECT_DIR/src/HookName.hx"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$TMP_ROOT/direct-hxx-registry-renamed" \
		>"$direct_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:hxx-registry-renamed direct build unexpectedly succeeded" >&2
		return 1
	fi
	grep -Fq 'unknown hook "Known"' "$direct_failure_log" || {
		echo "SERVER_CACHE_PARITY:hxx-registry-renamed direct build failed for the wrong reason" >&2
		sed -n '1,160p' "$direct_failure_log" >&2
		return 1
	}

	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$server_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:hxx-registry-renamed warm build accepted a stale global registry" >&2
		return 1
	fi
	grep -Fq 'unknown hook "Known"' "$server_failure_log" || {
		echo "SERVER_CACHE_PARITY:hxx-registry-renamed warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$server_failure_log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:hxx-registry-renamed:PASS"

	cp "$FIXTURE_DIR/variants/hxx-registry/HookNameKnown.hx" "$PROJECT_DIR/src/HookName.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_restored"
	compare_generated_output "$direct_restored" "$SERVER_OUTPUT" "hxx-registry-restored"

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "hxx-registry-removed"
}

run_external_macro_input_variant() {
	local direct_a="$TMP_ROOT/direct-external-input-a"
	local direct_b="$TMP_ROOT/direct-external-input-b"
	local direct_restored="$TMP_ROOT/direct-external-input-restored"

	mkdir -p "$PROJECT_DIR/config"
	cp "$FIXTURE_DIR/variants/external-input/MainExternal.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/variants/external-input/ExternalValueMacro.hx" "$PROJECT_DIR/src/ExternalValueMacro.hx"
	cp "$FIXTURE_DIR/variants/external-input/value-a.txt" "$PROJECT_DIR/config/external-value.txt"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_a"
	compare_generated_output "$direct_a" "$SERVER_OUTPUT" "external-input-A"
	grep -Fq '"alpha"' "$SERVER_OUTPUT/main.ex" || {
		echo "SERVER_CACHE_PARITY:external-input-A did not embed the external value" >&2
		return 1
	}

	# The .txt file is not a Haxe source module. registerModuleDependency tells
	# Haxe which caller must be retyped when this external macro input changes.
	cp "$FIXTURE_DIR/variants/external-input/value-b.txt" "$PROJECT_DIR/config/external-value.txt"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_b"
	compare_generated_output "$direct_b" "$SERVER_OUTPUT" "external-input-B"
	grep -Fq '"beta"' "$SERVER_OUTPUT/main.ex" || {
		echo "SERVER_CACHE_PARITY:external-input-B kept the stale external value" >&2
		return 1
	}

	cp "$FIXTURE_DIR/variants/external-input/value-a.txt" "$PROJECT_DIR/config/external-value.txt"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_restored"
	compare_generated_output "$direct_restored" "$SERVER_OUTPUT" "external-input-A-restored"

	restore_baseline_sources
	rm -rf "$PROJECT_DIR/config"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "external-input-removed"
}

run_hxml_define_variant() {
	local direct_a="$TMP_ROOT/direct-hxml-define-a"
	local direct_b="$TMP_ROOT/direct-hxml-define-b"
	local direct_restored="$TMP_ROOT/direct-hxml-define-restored"

	cp "$FIXTURE_DIR/variants/configuration/MainConfiguration.hx" "$PROJECT_DIR/src/Main.hx"
	write_project_hxml "$PROJECT_DIR"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_a"
	compare_generated_output "$direct_a" "$SERVER_OUTPUT" "hxml-define-A"
	grep -Fq '"disabled"' "$SERVER_OUTPUT/main.ex" || {
		echo "SERVER_CACHE_PARITY:hxml-define-A did not use the default branch" >&2
		return 1
	}

	# Only the HXML define changes. Haxe must select the matching cached typing
	# context, and Reflaxe must publish output from that request rather than from
	# the previous configuration.
	write_project_hxml "$PROJECT_DIR" "server_cache_feature"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_b"
	compare_generated_output "$direct_b" "$SERVER_OUTPUT" "hxml-define-B"
	grep -Fq '"enabled"' "$SERVER_OUTPUT/main.ex" || {
		echo "SERVER_CACHE_PARITY:hxml-define-B reused the previous define context" >&2
		return 1
	}

	write_project_hxml "$PROJECT_DIR"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_restored"
	compare_generated_output "$direct_restored" "$SERVER_OUTPUT" "hxml-define-A-restored"

	restore_baseline_sources
	write_project_hxml "$PROJECT_DIR"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "hxml-define-removed"
}

run_module_routes_variant() {
	local direct_a="$TMP_ROOT/direct-module-routes-a"
	local direct_b="$TMP_ROOT/direct-module-routes-b"
	local include_status='include("CacheStatus")'

	cp "$FIXTURE_DIR/variants/module-routes/MainModuleRoutes.hx" "$PROJECT_DIR/src/Main.hx"
	compile_server "$SERVER_OUTPUT" --macro "$include_status"
	compile_direct "$direct_a" --macro "$include_status"
	compare_generated_output "$direct_a" "$SERVER_OUTPUT" "module-routes-A"
	rg -Fq 'get("/status", CacheController, :index)' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:module-routes-A omitted the typed route" >&2
		return 1
	}

	# CacheStatus is a separately included root module. Editing it starts a new
	# server request without invalidating the cached module-level router.
	cp "$FIXTURE_DIR/variants/enum/CacheStatus.hx" "$PROJECT_DIR/src/CacheStatus.hx"
	compile_server "$SERVER_OUTPUT" --macro "$include_status"
	compile_direct "$direct_b" --macro "$include_status"
	compare_generated_output "$direct_b" "$SERVER_OUTPUT" "module-routes-B"
	rg -Fq 'get("/status", CacheController, :index)' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:module-routes-B lost the typed route on a warm request" >&2
		return 1
	}

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "module-routes-removed"
}

run_cross_project_variant() {
	local project_b="$TMP_ROOT/cross-project-b"
	local server_b="$TMP_ROOT/server-cross-project-b"
	local direct_b="$TMP_ROOT/direct-cross-project-b"

	mkdir -p "$project_b/src"
	cp "$FIXTURE_DIR/variants/cross-project/MainProjectB.hx" "$project_b/src/Main.hx"
	write_project_hxml "$project_b"

	compile_project_direct "$project_b" "$direct_b"
	grep -Fq '"project-b"' "$direct_b/main.ex" || {
		echo "SERVER_CACHE_PARITY:cross-project-B direct baseline generated the wrong project" >&2
		return 1
	}

	# A compiler server is one project's in-memory compiler context, like one
	# `tsc --watch` process. The managed Mix integration keys ownership by project
	# root; this regression mirrors that contract with a second native server and
	# verifies both projects' Elixir and source maps against clean builds.
	start_secondary_server
	compile_project_server "$project_b" "$server_b" "$SECONDARY_SERVER_PORT"
	compare_generated_output "$direct_b" "$server_b" "cross-project-B-isolated"
	echo "SERVER_CACHE_PROJECT_ISOLATION:cross-project-B:PASS"

	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "cross-project-A-after-project-B"
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

write_project_hxml "$PROJECT_DIR"

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

run_module_rename_variant
run_hxx_registry_variant
run_external_macro_input_variant
run_hxml_define_variant
run_module_routes_variant
run_cross_project_variant

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

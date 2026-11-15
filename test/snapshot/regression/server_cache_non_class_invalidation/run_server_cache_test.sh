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

# Replaces one text in a source file and gives the file its old file time
# back. For Haxe this is the same as a second save within one second: Haxe
# reads file times in whole seconds, so it cannot see this change by itself.
edit_keeping_file_time() {
	python3 - "$1" "$2" "$3" <<'PY'
import os
import sys

path, old, new = sys.argv[1], sys.argv[2].encode(), sys.argv[3].encode()
before = os.stat(path)
data = open(path, "rb").read()
changed = data.replace(old, new, 1)
if changed == data:
    raise SystemExit(f"same-second fixture could not find {sys.argv[2]!r} in {path}")
open(path, "wb").write(changed)
os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
PY
}

run_same_second_edit_variant() {
	local variants="$FIXTURE_DIR/variants/native-class"

	# One more request without an edit. After it, the server has compared every
	# source file of the baseline with its content at the start of a request.
	compile_server "$SERVER_OUTPUT"

	# A class body changes and the file time stays the same.
	edit_keeping_file_time "$PROJECT_DIR/src/Main.hx" "return Ready;" "return Waiting;"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-same-second-class"
	compare_generated_output "$TMP_ROOT/direct-same-second-class" "$SERVER_OUTPUT" "same-second-class"
	grep -Fq '{:waiting}' "$SERVER_OUTPUT/main.ex" || {
		echo "SERVER_CACHE_PARITY:same-second-class kept the stale class body" >&2
		return 1
	}

	# An enum gets a constructor and the file time stays the same.
	edit_keeping_file_time "$PROJECT_DIR/src/CacheStatus.hx" "Waiting;" "Waiting; Archived;"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-same-second-enum"
	compare_generated_output "$TMP_ROOT/direct-same-second-enum" "$SERVER_OUTPUT" "same-second-enum"
	grep -Fq 'def archived()' "$SERVER_OUTPUT/cache_status.ex" || {
		echo "SERVER_CACHE_PARITY:same-second-enum kept the stale enum" >&2
		return 1
	}

	# A file that the server reads for the first time right after it was
	# written, and that changes again with the same file time.
	cp "$variants/MainNative.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheNativeBefore.hx" "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	edit_keeping_file_time "$PROJECT_DIR/src/CacheNative.hx" "native-before" "native-after"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-same-second-new-file"
	compare_generated_output "$TMP_ROOT/direct-same-second-new-file" "$SERVER_OUTPUT" "same-second-new-file"
	grep -RFq '"native-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:same-second-new-file kept the stale class body" >&2
		return 1
	}
	echo "SERVER_CACHE_SAME_SECOND_EDIT:PASS"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "same-second-removed"
}

# A "first-time file" is a source file that no build on this server has
# recorded yet. The server has no earlier copy of it to compare with, so it
# has its own two rules. Both cases below wait three seconds, which is longer
# than the two-second margin of those rules.
run_same_second_first_time_file_variant() {
	local variants="$FIXTURE_DIR/variants/native-class"
	local log="$TMP_ROOT/same-second-first-time.log"
	local display_log="$TMP_ROOT/same-second-display.log"
	local display_position unchanged_count

	# Rule 1: a file that was last written well before the first build that
	# reads it is trusted. The next build without an edit must build no class
	# module again, and a later change with the same file time must be found.
	cp "$variants/MainNative.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheNativeBefore.hx" "$PROJECT_DIR/src/CacheNative.hx"
	sleep 3
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT" >"$log"
	unchanged_count="$(built_class_count "$log")"
	if ((unchanged_count != 0)); then
		echo "SERVER_CACHE_REUSE:same-second-settled-file built $unchanged_count class modules again without an edit" >&2
		return 1
	fi
	echo "SERVER_CACHE_REUSE:same-second-settled-file:PASS"
	edit_keeping_file_time "$PROJECT_DIR/src/CacheNative.hx" "native-before" "native-after"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-same-second-settled-file"
	compare_generated_output "$TMP_ROOT/direct-same-second-settled-file" "$SERVER_OUTPUT" "same-second-settled-file"
	grep -RFq '"native-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:same-second-settled-file kept the stale class body" >&2
		return 1
	}

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "same-second-settled-file-removed"

	# Rule 2: an editor (display) request reads a new file before any build
	# does, and Haxe keeps what it parsed. The file then changes with the same
	# file time. The first build may still use the old text, because the server
	# learns about the file only in that build. The second build must not.
	cp "$variants/MainNative.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheNativeBefore.hx" "$PROJECT_DIR/src/CacheNative.hx"
	display_position="$(python3 - "$PROJECT_DIR/src/Main.hx" <<'PY'
import sys

text = open(sys.argv[1], "rb").read()
print(text.index(b"CacheNative.label") + len(b"CacheNative.") + 2)
PY
)"
	"$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		--display "src/Main.hx@$display_position@type" >"$display_log" 2>&1 || true
	grep -Fq 'String' "$display_log" || {
		echo "SERVER_CACHE_PARITY:same-second-after-display: the display request did not type CacheNative.label" >&2
		sed -n '1,40p' "$display_log" >&2
		return 1
	}
	edit_keeping_file_time "$PROJECT_DIR/src/CacheNative.hx" "native-before" "native-after"
	sleep 3
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-same-second-after-display"
	compare_generated_output "$TMP_ROOT/direct-same-second-after-display" "$SERVER_OUTPUT" "same-second-after-display"
	grep -RFq '"native-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:same-second-after-display kept the stale class body" >&2
		return 1
	}

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "same-second-after-display-removed"
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
	grep -RFq 'get("/status", CacheController, :index)' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:module-routes-A omitted the typed route" >&2
		return 1
	}

	# CacheStatus is a separately included root module. Editing it starts a new
	# server request without invalidating the cached module-level router.
	cp "$FIXTURE_DIR/variants/enum/CacheStatus.hx" "$PROJECT_DIR/src/CacheStatus.hx"
	compile_server "$SERVER_OUTPUT" --macro "$include_status"
	compile_direct "$direct_b" --macro "$include_status"
	compare_generated_output "$direct_b" "$SERVER_OUTPUT" "module-routes-B"
	grep -RFq 'get("/status", CacheController, :index)' "$SERVER_OUTPUT" || {
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

run_native_class_variant() {
	local variants="$FIXTURE_DIR/variants/native-class"
	local direct_before="$TMP_ROOT/direct-native-class-before"
	local direct_after="$TMP_ROOT/direct-native-class-after"

	cp "$variants/MainNative.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheNativeBefore.hx" "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_before"
	compare_generated_output "$direct_before" "$SERVER_OUTPUT" "native-class-before"

	# Only the body of the @:native class changes. Haxe renames such a class to
	# its native path after typing, so the warm build must still recognize it as
	# the edited class and write its new target file.
	cp "$variants/CacheNativeAfter.hx" "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT" >"$TMP_ROOT/native-class-after.log"
	compile_direct "$direct_after"
	compare_generated_output "$direct_after" "$SERVER_OUTPUT" "native-class-after"

	# The baseline enum CacheStatus did not change and nothing made Haxe type it
	# again, so this one-class edit must not build any enum module again. The
	# server reports its phases because it runs with REFLAXE_ELIXIR_TIMINGS=1.
	grep -Fq 'REFLAXE_ELIXIR_TIMINGS' "$TMP_ROOT/native-class-after.log" || {
		echo "SERVER_CACHE_REUSE:native-class-after printed no phase report" >&2
		return 1
	}
	if grep -Fq '"enum_ast_construction"' "$TMP_ROOT/native-class-after.log"; then
		echo "SERVER_CACHE_REUSE:native-class-after built an unchanged enum again" >&2
		return 1
	fi
	echo "SERVER_CACHE_REUSE:unchanged-enum-skipped:PASS"
	grep -RFq '"native-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:native-class-after kept the stale @:native class body" >&2
		return 1
	}

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "native-class-removed"
}

run_tampered_output_variant() {
	local variants="$FIXTURE_DIR/variants/native-class"
	local direct_after="$TMP_ROOT/direct-tampered-output-after"
	local failure_log="$TMP_ROOT/tampered-output.log"
	local owned="$SERVER_OUTPUT/main.ex"
	local original="$TMP_ROOT/tampered-output-original.ex"
	local tampered="$TMP_ROOT/tampered-output-tampered.ex"

	# Two server requests first. After them the server remembers the digest of
	# each generated file, so the next request takes the fast ownership check.
	cp "$variants/MainNative.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheNativeBefore.hx" "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"

	# Change one generated file by hand, the way an editor would. The size and
	# the file time stay the same, so only a comparison of the bytes can see it.
	cp "$owned" "$original"
	python3 - "$owned" <<'PY'
import os
import sys

path = sys.argv[1]
before = os.stat(path)
data = open(path, "rb").read()
changed = data.replace(b"defmodule Main", b"defmodule Maim", 1)
if changed == data or len(changed) != len(data):
    raise SystemExit("tampered-output fixture could not change main.ex")
open(path, "wb").write(changed)
os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
PY
	cp "$owned" "$tampered"

	# The source edit below changes a different generated file. The warm request
	# must still read every owned file, find the hand edit, and publish nothing.
	cp "$variants/CacheNativeAfter.hx" "$PROJECT_DIR/src/CacheNative.hx"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$failure_log" 2>&1
	then
		echo "SERVER_CACHE_OWNERSHIP:tampered-output warm build accepted a hand-edited generated file" >&2
		return 1
	fi
	grep -Fq 'Owned generated output was modified outside the compiler' "$failure_log" || {
		echo "SERVER_CACHE_OWNERSHIP:tampered-output warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$failure_log" >&2
		return 1
	}
	cmp -s "$owned" "$tampered" || {
		echo "SERVER_CACHE_OWNERSHIP:tampered-output warm build overwrote the hand-edited file" >&2
		return 1
	}
	if grep -RFq '"native-after"' "$SERVER_OUTPUT"; then
		echo "SERVER_CACHE_OWNERSHIP:tampered-output warm build published other files after the refusal" >&2
		return 1
	fi
	echo "SERVER_CACHE_OWNERSHIP:tampered-output-refused:PASS"

	# When the generated file has its compiler bytes again, the same server
	# publishes the pending source edit.
	cp "$original" "$owned"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_after"
	compare_generated_output "$direct_after" "$SERVER_OUTPUT" "tampered-output-restored"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "tampered-output-removed"
}

run_missing_output_variant() {
	local variants="$FIXTURE_DIR/variants/mixed-file"
	local direct_restored="$TMP_ROOT/direct-missing-output-restored"
	local direct_after="$TMP_ROOT/direct-missing-output-after"
	local failure_log="$TMP_ROOT/missing-output.log"
	local main_output="$SERVER_OUTPUT/main.ex"
	local bystander_output="$SERVER_OUTPUT/cache_mixed_bystander.ex"
	local bystander_copy="$TMP_ROOT/missing-output-bystander.ex"

	# Two server requests first, so that the next request is a warm one: the
	# compiler builds only the modules that Haxe typed again, and keeps the
	# other generated files as they are on disk.
	cp "$variants/MainMixed.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheMixedBefore.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	cp "$variants/CacheMixedFunctionsBefore.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx"
	cp "$variants/CacheMixedBystander.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx"
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"
	if [[ ! -f "$main_output" || ! -f "$bystander_output" ]]; then
		echo "SERVER_CACHE_OWNERSHIP:missing-output fixture did not generate main.ex and cache_mixed_bystander.ex" >&2
		return 1
	fi

	# Somebody deletes one generated file. The source edit changes a class that
	# Main uses, so Haxe types Main again and the compiler builds main.ex again,
	# with the same bytes as before. The request has all it needs to write the
	# file, so it must write it, the same as a fresh build. It must not report
	# success while the output folder has no main.ex.
	rm "$main_output"
	cp "$variants/CacheMixedClassEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	compile_server "$SERVER_OUTPUT"
	if [[ ! -f "$main_output" ]]; then
		echo "SERVER_CACHE_OWNERSHIP:missing-output warm build reported success but left the deleted main.ex missing" >&2
		return 1
	fi
	compile_direct "$direct_restored"
	compare_generated_output "$direct_restored" "$SERVER_OUTPUT" "missing-output-restored"
	echo "SERVER_CACHE_OWNERSHIP:missing-output-restored:PASS"

	# Now the deleted file belongs to a class that the edit does not touch.
	# Haxe does not type CacheMixedBystander again, so this request has no
	# content for the file. It must stop and publish nothing.
	cp "$bystander_output" "$bystander_copy"
	rm "$bystander_output"
	cp "$variants/CacheMixedBefore.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$failure_log" 2>&1
	then
		echo "SERVER_CACHE_OWNERSHIP:missing-output warm build reported success without the deleted cache_mixed_bystander.ex" >&2
		return 1
	fi
	grep -Fq 'Cached rebuild cannot preserve missing owned output' "$failure_log" || {
		echo "SERVER_CACHE_OWNERSHIP:missing-output warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$failure_log" >&2
		return 1
	}
	if [[ -e "$bystander_output" ]]; then
		echo "SERVER_CACHE_OWNERSHIP:missing-output refused build still wrote cache_mixed_bystander.ex" >&2
		return 1
	fi
	if grep -RFq '"mixed-before"' "$SERVER_OUTPUT"; then
		echo "SERVER_CACHE_OWNERSHIP:missing-output warm build published other files after the refusal" >&2
		return 1
	fi
	echo "SERVER_CACHE_OWNERSHIP:missing-output-refused:PASS"

	# When the file has its compiler bytes again, the same server publishes the
	# pending source edit.
	cp "$bystander_copy" "$bystander_output"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$direct_after"
	compare_generated_output "$direct_after" "$SERVER_OUTPUT" "missing-output-after-refusal"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheMixed.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "missing-output-removed"
}

# Reads the phase report of one warm request and prints how many class modules
# that request built. The server prints the report because it runs with
# REFLAXE_ELIXIR_TIMINGS=1.
built_class_count() {
	python3 - "$1" <<'PY'
import json
import sys

count = None
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("REFLAXE_ELIXIR_TIMINGS "):
        phases = json.loads(line.split(" ", 1)[1])["phases"]
        count = sum(phase["count"] for phase in phases if phase["name"] == "class_ast_including_dependency_discovery")
if count is None:
    raise SystemExit("no phase report in " + sys.argv[1])
print(count)
PY
}

run_mixed_file_variant() {
	local variants="$FIXTURE_DIR/variants/mixed-file"
	local log="$TMP_ROOT/mixed-file.log"
	local full_count partial_count

	# A "mixed file" declares a class or module-level functions beside an enum,
	# a typedef or an abstract. CacheMixed.hx and CacheMixedFunctions.hx are
	# both mixed files.
	cp "$variants/MainMixed.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheMixedBefore.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	cp "$variants/CacheMixedFunctionsBefore.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx"
	cp "$variants/CacheMixedBystander.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-before"
	compare_generated_output "$TMP_ROOT/direct-mixed-before" "$SERVER_OUTPUT" "mixed-file-before"
	full_count="$(built_class_count "$log")"

	# Only a class body changes, and it grows by two lines, so the enum, the
	# typedef and the abstract move down in the file. The warm request must
	# build the edited class and its users, not every module, and the output
	# and source maps must still equal a fresh build.
	cp "$variants/CacheMixedClassEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-class-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-class-edit" "$SERVER_OUTPUT" "mixed-file-class-edit"
	grep -RFq '"mixed-class-edit"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:mixed-file-class-edit kept the stale class body" >&2
		return 1
	}
	partial_count="$(built_class_count "$log")"
	if ((partial_count >= full_count)); then
		echo "SERVER_CACHE_REUSE:mixed-file-class-edit built $partial_count class modules, the same as a full build ($full_count)" >&2
		return 1
	fi
	echo "SERVER_CACHE_REUSE:mixed-file-class-edit:PASS built=$partial_count full=$full_count"

	# Only the body of a module-level function changes, in a file that also
	# declares a typedef.
	cp "$variants/CacheMixedFunctionsBodyEdit.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-function-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-function-edit" "$SERVER_OUTPUT" "mixed-file-function-edit"
	grep -RFq 'functions-after-' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:mixed-file-function-edit kept the stale function body" >&2
		return 1
	}
	partial_count="$(built_class_count "$log")"
	if ((partial_count >= full_count)); then
		echo "SERVER_CACHE_REUSE:mixed-file-function-edit built $partial_count class modules, the same as a full build ($full_count)" >&2
		return 1
	fi
	echo "SERVER_CACHE_REUSE:mixed-file-function-edit:PASS built=$partial_count full=$full_count"

	# The typedef beside the functions changes. This is a non-class edit, so the
	# request must build every module, as before.
	cp "$variants/CacheMixedFunctionsTypedefEdit.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-typedef-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-typedef-edit" "$SERVER_OUTPUT" "mixed-file-typedef-edit"
	partial_count="$(built_class_count "$log")"
	if ((partial_count < full_count)); then
		echo "SERVER_CACHE_REUSE:mixed-file-typedef-edit built only $partial_count of $full_count class modules after a typedef edit" >&2
		return 1
	fi

	# The abstract beside the class changes: also a full build.
	cp "$variants/CacheMixedAbstractEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-abstract-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-abstract-edit" "$SERVER_OUTPUT" "mixed-file-abstract-edit"
	partial_count="$(built_class_count "$log")"
	if ((partial_count < full_count)); then
		echo "SERVER_CACHE_REUSE:mixed-file-abstract-edit built only $partial_count of $full_count class modules after an abstract edit" >&2
		return 1
	fi
	echo "SERVER_CACHE_REUSE:mixed-file-non-class-edits-build-everything:PASS"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheMixed.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "mixed-file-removed"
}

run_mixed_file_registry_variant() {
	local variants="$FIXTURE_DIR/variants/mixed-file"
	local direct_failure_log="$TMP_ROOT/direct-mixed-registry-renamed.log"
	local server_failure_log="$TMP_ROOT/server-mixed-registry-renamed.log"

	# HookName.hx holds the global hook-name registry and a class. CacheTemplate
	# is checked against the registry but does not refer to HookName.hx.
	cp "$variants/MainHxxMixed.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/variants/hxx-registry/CacheTemplate.hx" "$PROJECT_DIR/src/CacheTemplate.hx"
	cp "$variants/HookNameMixedKnown.hx" "$PROJECT_DIR/src/HookName.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-mixed-registry-known"
	compare_generated_output "$TMP_ROOT/direct-mixed-registry-known" "$SERVER_OUTPUT" "mixed-registry-known"

	# First only the class in that file changes.
	cp "$variants/HookNameMixedClassEdit.hx" "$PROJECT_DIR/src/HookName.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-mixed-registry-class-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-registry-class-edit" "$SERVER_OUTPUT" "mixed-registry-class-edit"

	# Then only the registry changes. The class text is the same as in the
	# request before, so the rest of the file alone must make the warm request
	# check the unchanged template again and reject the removed hook name.
	cp "$variants/HookNameMixedRenamed.hx" "$PROJECT_DIR/src/HookName.hx"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$TMP_ROOT/direct-mixed-registry-renamed" \
		>"$direct_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:mixed-registry-renamed direct build unexpectedly succeeded" >&2
		return 1
	fi
	grep -Fq 'unknown hook "Known"' "$direct_failure_log" || {
		echo "SERVER_CACHE_PARITY:mixed-registry-renamed direct build failed for the wrong reason" >&2
		sed -n '1,160p' "$direct_failure_log" >&2
		return 1
	}
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$server_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:mixed-registry-renamed warm build accepted a stale global registry" >&2
		return 1
	fi
	grep -Fq 'unknown hook "Known"' "$server_failure_log" || {
		echo "SERVER_CACHE_PARITY:mixed-registry-renamed warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$server_failure_log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:mixed-registry-renamed:PASS"

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "mixed-registry-removed"
}

# Writes a copy of a mixed-file fixture with non-ASCII text in front of it.
# A Haxe position counts characters, and each of these prefixes has more bytes
# than characters, so byte offsets and character offsets differ in the result.
write_with_non_ascii_prefix() {
	python3 - "$1" "$2" "$3" <<'PY'
import sys

kind, source, target = sys.argv[1], sys.argv[2], sys.argv[3]
prefixes = {
    "byte-order-mark": b"\xef\xbb\xbf",
    "e-acute": "// caf\u00e9 \u00e9t\u00e9\n".encode(),
    "emoji": "// \U0001F600 note \U0001F600\n".encode(),
}
with open(target, "wb") as out:
    out.write(prefixes[kind] + open(source, "rb").read())
PY
}

run_mixed_file_non_ascii_variant() {
	local variants="$FIXTURE_DIR/variants/mixed-file"
	local log="$TMP_ROOT/mixed-file-non-ascii.log"
	local kind full_count partial_count

	cp "$variants/MainMixed.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheMixedFunctionsBefore.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx"
	cp "$variants/CacheMixedBystander.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx"

	for kind in byte-order-mark e-acute emoji; do
		write_with_non_ascii_prefix "$kind" "$variants/CacheMixedBefore.hx" "$PROJECT_DIR/src/CacheMixed.hx"
		compile_server "$SERVER_OUTPUT" >"$log"
		compile_direct "$TMP_ROOT/direct-mixed-$kind-before"
		compare_generated_output "$TMP_ROOT/direct-mixed-$kind-before" "$SERVER_OUTPUT" "mixed-file-$kind-before"
		full_count="$(built_class_count "$log")"

		# Only the class body changes. The class-only path must still apply when
		# non-ASCII text stands in front of the class.
		write_with_non_ascii_prefix "$kind" "$variants/CacheMixedClassEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
		compile_server "$SERVER_OUTPUT" >"$log"
		compile_direct "$TMP_ROOT/direct-mixed-$kind-class-edit"
		compare_generated_output "$TMP_ROOT/direct-mixed-$kind-class-edit" "$SERVER_OUTPUT" "mixed-file-$kind-class-edit"
		grep -RFq '"mixed-class-edit"' "$SERVER_OUTPUT" || {
			echo "SERVER_CACHE_PARITY:mixed-file-$kind-class-edit kept the stale class body" >&2
			return 1
		}
		partial_count="$(built_class_count "$log")"
		if ((partial_count >= full_count)); then
			echo "SERVER_CACHE_REUSE:mixed-file-$kind-class-edit built $partial_count class modules, the same as a full build ($full_count)" >&2
			return 1
		fi
		echo "SERVER_CACHE_REUSE:mixed-file-$kind-class-edit:PASS built=$partial_count full=$full_count"

		# The abstract behind the class changes: every module must be built.
		write_with_non_ascii_prefix "$kind" "$variants/CacheMixedAbstractEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
		compile_server "$SERVER_OUTPUT" >"$log"
		compile_direct "$TMP_ROOT/direct-mixed-$kind-abstract-edit"
		compare_generated_output "$TMP_ROOT/direct-mixed-$kind-abstract-edit" "$SERVER_OUTPUT" "mixed-file-$kind-abstract-edit"
		partial_count="$(built_class_count "$log")"
		if ((partial_count < full_count)); then
			echo "SERVER_CACHE_REUSE:mixed-file-$kind-abstract-edit built only $partial_count of $full_count class modules after an abstract edit" >&2
			return 1
		fi
	done

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheMixed.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "mixed-file-non-ascii-removed"
}

run_decoy_registry_variant() {
	local variants="$FIXTURE_DIR/variants/mixed-file"
	local direct_failure_log="$TMP_ROOT/direct-decoy-registry-renamed.log"
	local server_failure_log="$TMP_ROOT/server-decoy-registry-renamed.log"

	# make_decoy_registry.py explains the file. Read as byte offsets, the
	# position of its class covers the hook registry in front of the class.
	cp "$variants/MainHxxMixed.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/variants/hxx-registry/CacheTemplate.hx" "$PROJECT_DIR/src/CacheTemplate.hx"
	python3 "$variants/make_decoy_registry.py" "decoy-note" "Known" "$PROJECT_DIR/src/HookName.hx"
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-decoy-registry-known"
	compare_generated_output "$TMP_ROOT/direct-decoy-registry-known" "$SERVER_OUTPUT" "decoy-registry-known"

	# Only the registry entry changes, to a name of the same length. The class
	# is the same. The warm request must reject the removed hook name.
	python3 "$variants/make_decoy_registry.py" "decoy-note" "Knowx" "$PROJECT_DIR/src/HookName.hx"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$TMP_ROOT/direct-decoy-registry-renamed" \
		>"$direct_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:decoy-registry-renamed direct build unexpectedly succeeded" >&2
		return 1
	fi
	grep -Fq 'unknown hook "Known"' "$direct_failure_log" || {
		echo "SERVER_CACHE_PARITY:decoy-registry-renamed direct build failed for the wrong reason" >&2
		sed -n '1,160p' "$direct_failure_log" >&2
		return 1
	}
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$server_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:decoy-registry-renamed warm build accepted a stale global registry" >&2
		return 1
	fi
	grep -Fq 'unknown hook "Known"' "$server_failure_log" || {
		echo "SERVER_CACHE_PARITY:decoy-registry-renamed warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$server_failure_log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:decoy-registry-renamed:PASS"

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "decoy-registry-removed"
}

run_discovery_variant() {
	local variants="$FIXTURE_DIR/variants/discovery"
	local phase source expected

	# Module discovery keeps its scan results on the server. Each phase changes
	# only the metadata of a class that nothing refers to, so the server must
	# scan that file again: the module appears, then disappears.
	for phase in plain-before annotated plain-after; do
		if [[ "$phase" == annotated ]]; then
			source=CacheDiscoveredAnnotated.hx
			expected=present
		else
			source=CacheDiscoveredPlain.hx
			expected=absent
		fi
		cp "$variants/$source" "$PROJECT_DIR/src/CacheDiscovered.hx"
		compile_server "$SERVER_OUTPUT"
		compile_direct "$TMP_ROOT/direct-discovery-$phase"
		compare_generated_output "$TMP_ROOT/direct-discovery-$phase" "$SERVER_OUTPUT" "discovery-$phase"
		if [[ "$expected" == present && ! -f "$SERVER_OUTPUT/cache_discovered.ex" ]]; then
			echo "SERVER_CACHE_PARITY:discovery-$phase did not generate the annotated module" >&2
			return 1
		fi
		if [[ "$expected" == absent && -e "$SERVER_OUTPUT/cache_discovered.ex" ]]; then
			echo "SERVER_CACHE_PARITY:discovery-$phase kept a module that is no longer annotated" >&2
			return 1
		fi
	done

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheDiscovered.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "discovery-removed"
}

run_private_exports_variant() {
	local variants="$FIXTURE_DIR/variants/private-exports"
	cp "$variants/PrivateCacheScope.hx" "$PROJECT_DIR/src/PrivateCacheScope.hx"
	local phase source expected_visibility expected_stdout
	for phase in local-before remote local-after; do
		if [[ "$phase" == remote ]]; then
			source=MainRemote.hx
			expected_visibility='  def secret() do'
			expected_stdout=14
		else
			source=MainLocal.hx
			expected_visibility='  defp secret() do'
			expected_stdout=7
		fi
		# Only the caller changes. anchor() keeps secret() and its owning module
		# alive in every phase, so ordinary DCE cannot hide missing invalidation.
		cp "$variants/$source" "$PROJECT_DIR/src/Main.hx"
		compile_server "$SERVER_OUTPUT"
		compile_direct "$TMP_ROOT/direct-private-$phase"
		compare_generated_output "$TMP_ROOT/direct-private-$phase" "$SERVER_OUTPUT" "private-exports-$phase"
		grep -Fxq "$expected_visibility" "$SERVER_OUTPUT/private_cache_scope.ex"
		"$TIMEOUT" --secs 60 --cwd "$PROJECT_DIR" -- elixir -e '
          [root, expected] = System.argv()
          {:ok, _, []} = Kernel.ParallelCompiler.compile(Path.wildcard(Path.join(root, "**/*.ex")))
          ExUnit.start(autorun: false)
          actual = ExUnit.CaptureIO.capture_io(fn -> Main.main() end)
          if actual != expected <> "\n", do: raise("private export runtime mismatch: #{inspect(actual)}")
        ' "$SERVER_OUTPUT" "$expected_stdout"
	done
	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/PrivateCacheScope.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "private-exports-baseline-restored"
}

HAXE_BIN="$(resolve_haxe_server_binary)"
HAXE_VERSION="$($HAXE_BIN -version)"
EXPECTED_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT_DIR/.haxerc")"
if [[ "$HAXE_VERSION" != "$EXPECTED_VERSION" ]]; then
	echo "server-cache fixture expected Haxe $EXPECTED_VERSION, got $HAXE_VERSION" >&2
	exit 1
fi

# This fixture is also a standalone CI owner. Create the ignored parent here
# instead of relying on an earlier snapshot lane to have created it. Keep the
# project below the repository so Lix resolves this checkout's vendored Reflaxe.
mkdir -p "$ROOT_DIR/tmp"
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

# The phase report lets the native-class variant check what a warm request built.
REFLAXE_ELIXIR_TIMINGS=1 "$HAXE_BIN" --wait "$SERVER_PORT" </dev/null >"$TMP_ROOT/server.log" 2>&1 &
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

# First, because every later variant relies on the server seeing each edit.
run_same_second_edit_variant
run_same_second_first_time_file_variant

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
run_private_exports_variant
run_native_class_variant
run_tampered_output_variant
run_missing_output_variant
run_mixed_file_variant
run_mixed_file_registry_variant
run_mixed_file_non_ascii_variant
run_decoy_registry_variant
run_discovery_variant
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

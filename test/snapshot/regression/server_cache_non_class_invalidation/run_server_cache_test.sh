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
    # Also read every module and source map on disk. A stale file that the
    # manifest no longer lists must still fail the comparison.
    for pattern in ("*.ex", "*.ex.map"):
        for generated in root.rglob(pattern):
            relative = generated.relative_to(root).as_posix()
            result[relative] = generated.read_bytes()
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
	# Main.hx gets a new file time: a display request skips the freshness
	# check, so a new Main.hx with the same whole-second time as the one the
	# server typed would keep the old module, and the display position would
	# point at nothing.
	copy_with_new_file_time "$variants/MainNative.hx" "$PROJECT_DIR/src/Main.hx"
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

# Writes the project HXML with one `--macro` line for each argument, in front
# of `-lib reflaxe.elixir`. Haxe runs initialization macros in HXML order, so
# such a line can ask Haxe for a project type before Reflaxe.Elixir starts.
write_early_macro_project_hxml() {
	{
		printf '%s\n' "-cp src"
		local early_macro
		for early_macro in "$@"; do
			printf '%s\n' "--macro $early_macro"
		done
		cat <<'HXML'
-lib reflaxe
-lib reflaxe.elixir
-D reflaxe_runtime
-D source-map
--no-output
Main
HXML
	} >"$PROJECT_DIR/compile.hxml"
}

# Copies a source over a project file and makes sure that the file time moves
# forward by at least two seconds: an ordinary save, which Haxe sees by itself.
copy_with_new_file_time() {
	python3 - "$1" "$2" <<'PY'
import os
import shutil
import sys
import time

source, target = sys.argv[1], sys.argv[2]
old = os.stat(target).st_mtime
shutil.copyfile(source, target)
stamp = max(time.time(), old + 2)
os.utime(target, (stamp, stamp))
PY
}

# Replaces one text in a source file and moves its file time forward by at
# least two seconds: an ordinary save, which Haxe sees by itself.
edit_with_new_file_time() {
	python3 - "$1" "$2" "$3" <<'PY'
import os
import sys
import time

path, old, new = sys.argv[1], sys.argv[2].encode(), sys.argv[3].encode()
before = os.stat(path).st_mtime
data = open(path, "rb").read()
changed = data.replace(old, new, 1)
if changed == data:
    raise SystemExit(f"edit fixture could not find {sys.argv[2]!r} in {path}")
open(path, "wb").write(changed)
stamp = max(time.time(), before + 2)
os.utime(path, (stamp, stamp))
PY
}

# Prints one digest of every file below a directory: paths, bytes and file
# times. Two equal digests mean that nothing was written there.
output_tree_digest() {
	python3 - "$1" <<'PY'
import hashlib
import os
import sys

root = sys.argv[1]
digest = hashlib.sha256()
for directory, _dirs, files in sorted(os.walk(root)):
    for name in sorted(files):
        path = os.path.join(directory, name)
        digest.update(os.path.relpath(path, root).encode() + b"\0")
        digest.update(str(os.stat(path).st_mtime_ns).encode() + b"\0")
        digest.update(open(path, "rb").read() + b"\0")
print(digest.hexdigest())
PY
}

# Runs one warm build that must refuse because Haxe holds an old copy of
# `module`. The refusal must name the module once and write nothing.
expect_stale_copy_refusal() {
	local module="$1"
	local label="$2"
	local log="$TMP_ROOT/$label.log"
	local before_digest after_digest mentions

	before_digest="$(output_tree_digest "$SERVER_OUTPUT")"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:$label accepted an old copy of $module" >&2
		return 1
	fi
	grep -Fq "used an old copy of $module (" "$log" || {
		echo "SERVER_CACHE_PARITY:$label failed for the wrong reason" >&2
		sed -n '1,80p' "$log" >&2
		return 1
	}
	mentions="$(grep -o "$module (src/$module.hx)" "$log" | wc -l | tr -d ' ')"
	if [[ "$mentions" != "1" ]]; then
		echo "SERVER_CACHE_PARITY:$label named $module $mentions times" >&2
		sed -n '1,20p' "$log" >&2
		return 1
	fi
	after_digest="$(output_tree_digest "$SERVER_OUTPUT")"
	if [[ "$before_digest" != "$after_digest" ]]; then
		echo "SERVER_CACHE_PARITY:$label wrote output although it refused" >&2
		return 1
	fi
	echo "SERVER_CACHE_REFUSAL:$label:PASS"
}

# An "early-typed" module is one that Haxe types before Reflaxe.Elixir starts,
# here because a project `--macro` line asks for it in front of
# `-lib reflaxe.elixir`. Reflaxe once found the types that Haxe typed again
# with a build macro that it registers when it starts, so it missed these
# modules: an edited class kept its old Elixir and the build exited 0.
run_early_typed_variant() {
	local variants="$FIXTURE_DIR/variants"
	local log="$TMP_ROOT/early-typed.log"
	local unchanged_count

	write_early_macro_project_hxml \
		'haxe.macro.Context.getType("CacheStatus")' \
		'haxe.macro.Context.getType("CacheNative")' \
		'haxe.macro.Context.getModule("EarlyMulti")' \
		'haxe.macro.Context.getModule("EarlyBox")'
	cp "$variants/early-typed/MainEarly.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/native-class/CacheNativeBefore.hx" "$PROJECT_DIR/src/CacheNative.hx"
	cp "$variants/early-typed/EarlyMulti.hx" "$PROJECT_DIR/src/EarlyMulti.hx"
	cp "$variants/early-typed/EarlyBox.hx" "$PROJECT_DIR/src/EarlyBox.hx"
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-early-before"
	compare_generated_output "$TMP_ROOT/direct-early-before" "$SERVER_OUTPUT" "early-typed-before"

	# An ordinary edit of an early-typed class.
	copy_with_new_file_time "$variants/native-class/CacheNativeAfter.hx" "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-early-class"
	compare_generated_output "$TMP_ROOT/direct-early-class" "$SERVER_OUTPUT" "early-typed-class"
	grep -RFq '"native-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:early-typed-class kept the stale class body" >&2
		return 1
	}

	# Without an edit, the early-typed modules are reused, not built again.
	compile_server "$SERVER_OUTPUT" >"$log"
	unchanged_count="$(built_class_count "$log")"
	if ((unchanged_count != 0)); then
		echo "SERVER_CACHE_REUSE:early-typed-unchanged built $unchanged_count class modules again without an edit" >&2
		return 1
	fi
	echo "SERVER_CACHE_REUSE:early-typed-unchanged:PASS"

	# An ordinary edit of an early-typed enum.
	copy_with_new_file_time "$variants/enum/CacheStatus.hx" "$PROJECT_DIR/src/CacheStatus.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-early-enum"
	compare_generated_output "$TMP_ROOT/direct-early-enum" "$SERVER_OUTPUT" "early-typed-enum"

	# Ordinary edits in an early-typed module with several types: first the
	# class body (the class-only path), then the abstract (a full build).
	edit_with_new_file_time "$PROJECT_DIR/src/EarlyMulti.hx" '"multi-before"' '"multi-after"'
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-early-multi-class"
	compare_generated_output "$TMP_ROOT/direct-early-multi-class" "$SERVER_OUTPUT" "early-typed-multi-class"
	grep -RFq '"multi-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:early-typed-multi-class kept the stale class body" >&2
		return 1
	}
	edit_with_new_file_time "$PROJECT_DIR/src/EarlyMulti.hx" 'this + 1' 'this * 2'
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-early-multi-abstract"
	compare_generated_output "$TMP_ROOT/direct-early-multi-abstract" "$SERVER_OUTPUT" "early-typed-multi-abstract"

	# An ordinary edit of an early-typed generic class.
	edit_with_new_file_time "$PROJECT_DIR/src/EarlyBox.hx" '"box-before"' '"box-after"'
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-early-generic"
	compare_generated_output "$TMP_ROOT/direct-early-generic" "$SERVER_OUTPUT" "early-typed-generic"
	grep -RFq '"box-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:early-typed-generic kept the stale generic class" >&2
		return 1
	}

	# A same-second edit of an early-typed enum. Haxe loads the old enum before
	# Reflaxe.Elixir can tell it to read the file again, so the first build must
	# refuse instead of writing old Elixir. Haxe types the enum again in the
	# next build, and that build must write the new enum.
	edit_keeping_file_time "$PROJECT_DIR/src/CacheStatus.hx" "Archived;" "Archived; Paused;"
	expect_stale_copy_refusal "CacheStatus" "early-typed-same-second-enum"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-early-same-second"
	compare_generated_output "$TMP_ROOT/direct-early-same-second" "$SERVER_OUTPUT" "early-typed-same-second-enum"
	grep -Fq 'def paused()' "$SERVER_OUTPUT/cache_status.ex" || {
		echo "SERVER_CACHE_PARITY:early-typed-same-second-enum kept the stale enum" >&2
		return 1
	}

	# The same for the module with several types. The abstract and its hidden
	# implementation class are both old, and the module is named once.
	edit_keeping_file_time "$PROJECT_DIR/src/EarlyMulti.hx" 'this * 2' 'this * 3'
	expect_stale_copy_refusal "EarlyMulti" "early-typed-same-second-multi"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-early-same-second-multi"
	compare_generated_output "$TMP_ROOT/direct-early-same-second-multi" "$SERVER_OUTPUT" "early-typed-same-second-multi"

	write_project_hxml "$PROJECT_DIR"
	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheNative.hx" "$PROJECT_DIR/src/EarlyMulti.hx" "$PROJECT_DIR/src/EarlyBox.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "early-typed-removed"
}

# Haxe makes one class for each type argument of a `@:generic` class, here
# `EarlyBox_String`, and runs no global build macro for it. Reflaxe once found
# the types that Haxe typed again with such a build macro, so an edit of the
# generic class kept the old `early_box_string.ex`.
run_generic_variant() {
	cp "$FIXTURE_DIR/variants/generic/MainGeneric.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/variants/early-typed/EarlyBox.hx" "$PROJECT_DIR/src/EarlyBox.hx"
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"
	edit_with_new_file_time "$PROJECT_DIR/src/EarlyBox.hx" '"box-before"' '"box-after"'
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-generic"
	compare_generated_output "$TMP_ROOT/direct-generic" "$SERVER_OUTPUT" "generic-edit"
	grep -RFq '"box-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:generic-edit kept the stale generic class" >&2
		return 1
	}

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/EarlyBox.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "generic-removed"
}

# A build macro of `Host` defines `HostCompanion` with the metadata of `Base`.
# When `Base` is reused from the server cache, that metadata includes the
# `@:reflaxe.typedIn` mark of `Base`. The new companion must still count as
# typed again, so an edit of `Host` must write the new companion.
run_copied_metadata_variant() {
	local variants="$FIXTURE_DIR/variants/copied-metadata"

	cp "$variants/MainCopied.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/Base.hx" "$PROJECT_DIR/src/Base.hx"
	cp "$variants/Host.hx" "$PROJECT_DIR/src/Host.hx"
	cp "$variants/Gen.hx" "$PROJECT_DIR/src/Gen.hx"
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"
	edit_with_new_file_time "$PROJECT_DIR/src/Host.hx" '"host-before"' '"host-after"'
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-copied-metadata"
	compare_generated_output "$TMP_ROOT/direct-copied-metadata" "$SERVER_OUTPUT" "copied-metadata"
	grep -RFq 'host-after' "$SERVER_OUTPUT/host_companion.ex" || {
		echo "SERVER_CACHE_PARITY:copied-metadata kept the stale companion class" >&2
		return 1
	}

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/Base.hx" "$PROJECT_DIR/src/Host.hx" "$PROJECT_DIR/src/Gen.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "copied-metadata-removed"
}

# An editor's JSON-RPC `display/diagnostics` request types every module on the
# same server, has no `display` define, runs Reflaxe's typing hooks, and
# generates nothing. Haxe keeps the modules that it typed. The next build must
# still build the class that the diagnostics request typed again.
run_diagnostics_request_variant() {
	local variants="$FIXTURE_DIR/variants/native-class"
	local log="$TMP_ROOT/diagnostics.log"
	local request

	cp "$variants/MainNative.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheNativeBefore.hx" "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"
	copy_with_new_file_time "$variants/CacheNativeAfter.hx" "$PROJECT_DIR/src/CacheNative.hx"
	request="$(python3 - "$PROJECT_DIR/src/CacheNative.hx" <<'PY'
import json
import os
import sys

print(json.dumps({"jsonrpc": "2.0", "id": 1, "method": "display/diagnostics",
                  "params": {"file": os.path.realpath(sys.argv[1])}}))
PY
)"
	"$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		--display "$request" >"$log" 2>&1 || {
		echo "SERVER_CACHE_PARITY:diagnostics request failed" >&2
		sed -n '1,40p' "$log" >&2
		return 1
	}
	grep -Fq '"result"' "$log" || {
		echo "SERVER_CACHE_PARITY:diagnostics request gave no JSON-RPC result" >&2
		sed -n '1,40p' "$log" >&2
		return 1
	}
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-diagnostics"
	compare_generated_output "$TMP_ROOT/direct-diagnostics" "$SERVER_OUTPUT" "diagnostics-then-build"
	grep -RFq '"native-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:diagnostics-then-build kept the stale class body" >&2
		return 1
	}

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "diagnostics-removed"
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

	# The source edit below changes CacheNative. Main uses CacheNative, so Haxe
	# types Main again and the warm request builds main.ex again. The request
	# checks each owned file that it builds, finds the hand edit, and publishes
	# nothing.
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

	# Now a hand edit of a generated file that the next warm request does not
	# build again: std.ex. That request does not read, write, or delete the
	# file, so it does not check it. It publishes the source edit and keeps the
	# hand edit. The manifest keeps the compiler's digest, so a fresh build, or
	# a later request that builds std.ex again, still refuses.
	local bystander="$SERVER_OUTPUT/std.ex"
	local bystander_original="$TMP_ROOT/tampered-bystander-original.ex"
	local bystander_tampered="$TMP_ROOT/tampered-bystander-tampered.ex"
	local direct_before="$TMP_ROOT/direct-tampered-bystander-before"
	local fresh_log="$TMP_ROOT/tampered-bystander-fresh.log"
	cp "$variants/CacheNativeBefore.hx" "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	if [[ ! -f "$bystander" ]]; then
		echo "SERVER_CACHE_OWNERSHIP:tampered-bystander fixture generated no std.ex" >&2
		return 1
	fi
	cp "$bystander" "$bystander_original"
	python3 - "$bystander" <<'PY'
import os
import sys

path = sys.argv[1]
before = os.stat(path)
data = open(path, "rb").read()
changed = data.replace(b"defmodule", b"defmodulf", 1)
if changed == data or len(changed) != len(data):
    raise SystemExit("tampered-bystander fixture could not change std.ex")
open(path, "wb").write(changed)
os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
PY
	cp "$bystander" "$bystander_tampered"
	cp "$variants/CacheNativeAfter.hx" "$PROJECT_DIR/src/CacheNative.hx"
	compile_server "$SERVER_OUTPUT"
	cmp -s "$bystander" "$bystander_tampered" || {
		echo "SERVER_CACHE_OWNERSHIP:tampered-bystander warm build changed a file that it did not build" >&2
		return 1
	}
	grep -RFq '"native-after"' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_OWNERSHIP:tampered-bystander warm build did not publish the source edit" >&2
		return 1
	}
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$SERVER_OUTPUT" >"$fresh_log" 2>&1
	then
		echo "SERVER_CACHE_OWNERSHIP:tampered-bystander fresh build accepted a hand-edited generated file" >&2
		return 1
	fi
	grep -Fq 'Owned generated output was modified outside the compiler' "$fresh_log" || {
		echo "SERVER_CACHE_OWNERSHIP:tampered-bystander fresh build failed for the wrong reason" >&2
		sed -n '1,160p' "$fresh_log" >&2
		return 1
	}
	cmp -s "$bystander" "$bystander_tampered" || {
		echo "SERVER_CACHE_OWNERSHIP:tampered-bystander fresh build overwrote the hand-edited file" >&2
		return 1
	}
	echo "SERVER_CACHE_OWNERSHIP:tampered-bystander-kept-and-fresh-refused:PASS"
	cp "$bystander_original" "$bystander"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$direct_after" "$SERVER_OUTPUT" "tampered-bystander-restored"

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
	cp "$variants/CacheMixedPayloadUser.hx" "$PROJECT_DIR/src/CacheMixedPayloadUser.hx"
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
	rm -f "$PROJECT_DIR/src/CacheMixed.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx" \
		"$PROJECT_DIR/src/CacheMixedPayloadUser.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "missing-output-removed"
}

# Runs one warm request without an edit that must refuse with `message` and
# leave the output folder exactly as it was.
expect_warm_refusal() {
	local label="$1"
	local message="$2"
	local log="$TMP_ROOT/$label.log"
	local before_digest after_digest

	before_digest="$(output_tree_digest "$SERVER_OUTPUT")"
	if compile_server "$SERVER_OUTPUT" >"$log" 2>&1; then
		echo "SERVER_CACHE_OWNERSHIP:$label warm build reported success" >&2
		sed -n '1,40p' "$log" >&2
		return 1
	fi
	grep -Fq "$message" "$log" || {
		echo "SERVER_CACHE_OWNERSHIP:$label warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$log" >&2
		return 1
	}
	after_digest="$(output_tree_digest "$SERVER_OUTPUT")"
	if [[ "$before_digest" != "$after_digest" ]]; then
		echo "SERVER_CACHE_OWNERSHIP:$label warm build changed the output folder although it refused" >&2
		return 1
	fi
	echo "SERVER_CACHE_OWNERSHIP:$label-refused:PASS"
}

# Somebody deletes generated output while the compile server runs, for example
# with `mix clean`, which removes each owned file and `_GeneratedFiles.json`.
# The next warm request has no edit, so the cache filter builds no type. The
# compiler once kept "the owned files of the types that it did not build", read
# that list from the missing manifest, found none, printed "No files updated.",
# and wrote a manifest with 0 files, where a fresh build writes every module.
# Now a warm request without a manifest builds every type, as a fresh build.
#
# `deletion` names what is deleted: `folder` (the whole output folder),
# `files-and-manifest` (each owned file and the manifest, the shape that
# `mix clean` leaves), `manifest` (only the manifest), `one-file`, or
# `folder-and-edit` (the whole folder, and a source edit in the same request).
run_deleted_output_root_variant() {
	local deletion="$1"
	local label="deleted-output-root-$deletion"
	local log="$TMP_ROOT/$label.log"
	local manifest="$SERVER_OUTPUT/_GeneratedFiles.json"
	local manifest_copy="$TMP_ROOT/$label-manifest.json"
	local main_copy="$TMP_ROOT/$label-main.ex"
	local fresh_copy="$TMP_ROOT/$label-fresh"
	local fresh_log="$TMP_ROOT/$label-fresh.log"

	# Two requests, so that the next one is warm and remembers this manifest.
	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "$label-baseline"

	case "$deletion" in
		folder)
			find "$SERVER_OUTPUT" -depth -delete
			compile_server "$SERVER_OUTPUT" >"$log"
			;;
		files-and-manifest)
			python3 - "$SERVER_OUTPUT" <<'PY2'
import json
import os
import sys

root = sys.argv[1]
manifest = os.path.join(root, "_GeneratedFiles.json")
for relative in json.load(open(manifest, encoding="utf-8"))["filesGenerated"]:
    os.remove(os.path.join(root, relative))
os.remove(manifest)
PY2
			compile_server "$SERVER_OUTPUT" >"$log"
			;;
		manifest)
			# The generated files stay, but no record says that the compiler
			# owns them. A fresh build refuses to overwrite them; the warm build
			# must refuse the same way and write no manifest.
			command cp "$manifest" "$manifest_copy"
			rm "$manifest"
			expect_warm_refusal "$label" "Refusing to overwrite unowned file"
			grep -Fq "manifest missing" "$log" || {
				echo "SERVER_CACHE_OWNERSHIP:$label warm refusal did not say that the manifest is missing" >&2
				return 1
			}
			if [[ -e "$manifest" ]]; then
				echo "SERVER_CACHE_OWNERSHIP:$label refused build wrote a manifest" >&2
				return 1
			fi
			command cp -R "$SERVER_OUTPUT" "$fresh_copy"
			if compile_direct "$fresh_copy" >"$fresh_log" 2>&1; then
				echo "SERVER_CACHE_OWNERSHIP:$label fresh build accepted unowned files" >&2
				return 1
			fi
			grep -Fq "Refusing to overwrite unowned file" "$fresh_log" && grep -Fq "manifest missing" "$fresh_log" || {
				echo "SERVER_CACHE_OWNERSHIP:$label fresh build failed for another reason" >&2
				sed -n '1,160p' "$fresh_log" >&2
				return 1
			}
			command cp "$manifest_copy" "$manifest"
			compile_server "$SERVER_OUTPUT" >"$log"
			;;
		folder-and-edit)
			# The folder goes, and the same request also has an edit. The
			# request must build every type, not only the edited one.
			find "$SERVER_OUTPUT" -depth -delete
			cp "$FIXTURE_DIR/variants/enum/CacheStatus.hx" "$PROJECT_DIR/src/CacheStatus.hx"
			compile_server "$SERVER_OUTPUT" >"$log"
			compile_direct "$fresh_copy" >/dev/null
			compare_generated_output "$fresh_copy" "$SERVER_OUTPUT" "$label-edited"
			grep -Fq "def archived()" "$SERVER_OUTPUT/cache_status.ex" || {
				echo "SERVER_CACHE_OWNERSHIP:$label warm build did not write the edited enum" >&2
				return 1
			}
			restore_baseline_sources
			compile_server "$SERVER_OUTPUT" >/dev/null
			;;
		one-file)
			# A file of a type that a request without an edit does not build. The
			# request has no content for the file, so it refuses and names the
			# fix, as in `run_missing_output_variant`.
			command cp "$SERVER_OUTPUT/main.ex" "$main_copy"
			rm "$SERVER_OUTPUT/main.ex"
			expect_warm_refusal "$label" "Cached rebuild cannot preserve missing owned output"
			command cp "$main_copy" "$SERVER_OUTPUT/main.ex"
			compile_server "$SERVER_OUTPUT" >"$log"
			;;
		*)
			echo "SERVER_CACHE_OWNERSHIP:unknown deletion $deletion" >&2
			return 1
			;;
	esac
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "$label"
	if [[ "$deletion" == "folder" || "$deletion" == "files-and-manifest" || "$deletion" == "folder-and-edit" ]] \
		&& [[ "$(phase_count "$log" cache_filter_missing_output_manifest)" != "1" ]]; then
		echo "SERVER_CACHE_OWNERSHIP:$label warm build did not see the missing manifest" >&2
		return 1
	fi
	echo "SERVER_CACHE_OWNERSHIP:$label:PASS"
}

# Another process writes the output folder while the compile server runs, and
# leaves a valid manifest that the server did not write. The next warm request
# has no edit, so the cache filter builds no type, and the server once kept
# every file that this other manifest listed: it printed "No files updated.",
# exited 0, and the output stayed the other build's output. A warm request now
# builds every type when the manifest bytes are not the bytes that this server
# published last, so the result equals a fresh build of the server's own
# configuration.
#
# `writer` names the other process: `direct-define` (a direct build with
# `-D server_cache_feature`, so main.ex holds "enabled" where the server's
# configuration gives "disabled"), or `empty` (each generated file removed,
# and a valid manifest that lists no file).
run_foreign_manifest_variant() {
	local writer="$1"
	local label="foreign-manifest-$writer"
	local log="$TMP_ROOT/$label.log"
	local fresh="$TMP_ROOT/$label-fresh"

	# Two requests, so that the next one is warm and remembers this manifest.
	cp "$FIXTURE_DIR/variants/configuration/MainConfiguration.hx" "$PROJECT_DIR/src/Main.hx"
	write_project_hxml "$PROJECT_DIR"
	compile_server "$SERVER_OUTPUT"
	compile_server "$SERVER_OUTPUT"

	case "$writer" in
		direct-define)
			compile_direct "$SERVER_OUTPUT" -D server_cache_feature >/dev/null
			grep -Fq '"enabled"' "$SERVER_OUTPUT/main.ex" || {
				echo "SERVER_CACHE_OWNERSHIP:$label direct build did not write the other configuration" >&2
				return 1
			}
			;;
		empty)
			python3 - "$SERVER_OUTPUT" <<'PY2'
import hashlib
import json
import os
import sys

root = sys.argv[1]
manifest = os.path.join(root, "_GeneratedFiles.json")
previous = json.load(open(manifest, encoding="utf-8"))
for relative in previous["filesGenerated"]:
    os.remove(os.path.join(root, relative))
empty = {
    "version": 2,
    "protocol": "reflaxe-elixir/generated-output",
    "id": previous["id"] + 1,
    "filesGenerated": [],
    "ownedFiles": [],
    "generation": hashlib.sha256(b"").hexdigest(),
}
with open(manifest, "w", encoding="utf-8") as target:
    json.dump(empty, target)
PY2
			;;
		*)
			echo "SERVER_CACHE_OWNERSHIP:unknown writer $writer" >&2
			return 1
			;;
	esac

	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$fresh" >/dev/null
	compare_generated_output "$fresh" "$SERVER_OUTPUT" "$label"
	grep -Fq '"disabled"' "$SERVER_OUTPUT/main.ex" || {
		echo "SERVER_CACHE_OWNERSHIP:$label warm build kept the other build's main.ex" >&2
		return 1
	}
	if [[ "$(phase_count "$log" cache_filter_foreign_output_manifest)" != "1" ]]; then
		echo "SERVER_CACHE_OWNERSHIP:$label warm build did not see the foreign manifest" >&2
		return 1
	fi

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "$label-removed"
	echo "SERVER_CACHE_OWNERSHIP:$label:PASS"
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

# Fails when the warm request in `log` built as many class modules as a full
# build (`full_count`), and prints the counts otherwise.
expect_partial_build() {
	local log="$1"
	local label="$2"
	local full_count="$3"
	local partial_count
	partial_count="$(built_class_count "$log")"
	if ((partial_count >= full_count)); then
		echo "SERVER_CACHE_REUSE:$label built $partial_count class modules, the same as a full build ($full_count)" >&2
		return 1
	fi
	echo "SERVER_CACHE_REUSE:$label:PASS built=$partial_count full=$full_count"
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
	cp "$variants/CacheMixedPayloadUser.hx" "$PROJECT_DIR/src/CacheMixedPayloadUser.hx"
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

	# Only comments change, between the class and the enum and after the last
	# declaration. No declaration changes, so this must build the same
	# classes as a class edit, not every module.
	cp "$variants/CacheMixedCommentEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-comment-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-comment-edit" "$SERVER_OUTPUT" "mixed-file-comment-edit"
	expect_partial_build "$log" "mixed-file-comment-edit" "$full_count"

	# Only the body of a module-level function changes, in a file that also
	# declares typedefs.
	cp "$variants/CacheMixedFunctionsBodyEdit.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-function-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-function-edit" "$SERVER_OUTPUT" "mixed-file-function-edit"
	grep -RFq 'functions-after-' "$SERVER_OUTPUT" || {
		echo "SERVER_CACHE_PARITY:mixed-file-function-edit kept the stale function body" >&2
		return 1
	}
	expect_partial_build "$log" "mixed-file-function-edit" "$full_count"

	# A typedef beside the functions changes its field from String to Int.
	# CacheMixedPayloadUser in another file reads the field, so Haxe types it
	# again and it must be built again, but the bystander must not.
	cp "$variants/CacheMixedFunctionsTypedefEdit.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-typedef-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-typedef-edit" "$SERVER_OUTPUT" "mixed-file-typedef-edit"
	grep -Fq 'payload.value + payload.value' "$SERVER_OUTPUT/cache_mixed_payload_user.ex" || {
		echo "SERVER_CACHE_PARITY:mixed-file-typedef-edit did not build the typedef's user again" >&2
		return 1
	}
	expect_partial_build "$log" "mixed-file-typedef-edit" "$full_count"

	# The abstract beside the class changes. Main calls its method, so Haxe
	# types Main again too.
	cp "$variants/CacheMixedAbstractEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-abstract-edit"
	compare_generated_output "$TMP_ROOT/direct-mixed-abstract-edit" "$SERVER_OUTPUT" "mixed-file-abstract-edit"
	expect_partial_build "$log" "mixed-file-abstract-edit" "$full_count"

	# A typedef is added to the file, and then removed again. A typedef writes
	# no Elixir file of its own, so neither request needs every module.
	cp "$variants/CacheMixedTypedefAdded.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-typedef-added"
	compare_generated_output "$TMP_ROOT/direct-mixed-typedef-added" "$SERVER_OUTPUT" "mixed-file-typedef-added"
	expect_partial_build "$log" "mixed-file-typedef-added" "$full_count"

	cp "$variants/CacheMixedAbstractEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-mixed-typedef-removed"
	compare_generated_output "$TMP_ROOT/direct-mixed-typedef-removed" "$SERVER_OUTPUT" "mixed-file-typedef-removed"
	expect_partial_build "$log" "mixed-file-typedef-removed" "$full_count"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheMixed.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx" \
		"$PROJECT_DIR/src/CacheMixedPayloadUser.hx"
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
	local kind partial_count
	local full_count=""

	cp "$variants/MainMixed.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheMixedFunctionsBefore.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx"
	cp "$variants/CacheMixedBystander.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx"
	cp "$variants/CacheMixedPayloadUser.hx" "$PROJECT_DIR/src/CacheMixedPayloadUser.hx"

	for kind in byte-order-mark e-acute emoji; do
		write_with_non_ascii_prefix "$kind" "$variants/CacheMixedBefore.hx" "$PROJECT_DIR/src/CacheMixed.hx"
		compile_server "$SERVER_OUTPUT" >"$log"
		compile_direct "$TMP_ROOT/direct-mixed-$kind-before"
		compare_generated_output "$TMP_ROOT/direct-mixed-$kind-before" "$SERVER_OUTPUT" "mixed-file-$kind-before"
		# Only the first request of this loop adds new files and builds every
		# class. A later one follows an abstract edit, which no longer builds
		# everything, so it is not a full build to compare with.
		if [[ -z "$full_count" ]]; then
			full_count="$(built_class_count "$log")"
		fi

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

		# The abstract behind the class changes. No template check reads this
		# file, so its text is not compared, and the output must still equal a
		# fresh build. The decoy-registry case checks the character positions
		# in a file whose text is compared.
		write_with_non_ascii_prefix "$kind" "$variants/CacheMixedAbstractEdit.hx" "$PROJECT_DIR/src/CacheMixed.hx"
		compile_server "$SERVER_OUTPUT" >"$log"
		compile_direct "$TMP_ROOT/direct-mixed-$kind-abstract-edit"
		compare_generated_output "$TMP_ROOT/direct-mixed-$kind-abstract-edit" "$SERVER_OUTPUT" "mixed-file-$kind-abstract-edit"
	done

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheMixed.hx" "$PROJECT_DIR/src/CacheMixedFunctions.hx" "$PROJECT_DIR/src/CacheMixedBystander.hx" \
		"$PROJECT_DIR/src/CacheMixedPayloadUser.hx"
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

run_component_props_variant() {
	local variants="$FIXTURE_DIR/variants/component-props"
	local direct_failure_log="$TMP_ROOT/direct-component-props-required.log"
	local server_failure_log="$TMP_ROOT/server-component-props-required.log"

	# CacheCardPage uses <.cache_card> by tag name only. The component's props
	# typedef is in CacheCardProps.hx, a file without any metadata.
	cp "$variants/MainCard.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/CacheCardPage.hx" "$PROJECT_DIR/src/CacheCardPage.hx"
	cp "$variants/CacheCardComponents.hx" "$PROJECT_DIR/src/CacheCardComponents.hx"
	cp "$variants/CacheCardPropsKnown.hx" "$PROJECT_DIR/src/CacheCardProps.hx"
	# Files that the server sees for the first time are read once more when
	# they are younger than two seconds (ServerSourceFreshness), and that
	# second read types the page again by itself. Old file times make the
	# props edit below an ordinary edit of a known file, as in a real project.
	python3 - "$PROJECT_DIR/src" <<'PY'
import os
import sys
import time

stamp = time.time() - 30
for name in ("Main.hx", "CacheCardPage.hx", "CacheCardComponents.hx", "CacheCardProps.hx"):
    os.utime(os.path.join(sys.argv[1], name), (stamp, stamp))
PY
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-component-props-known"
	compare_generated_output "$TMP_ROOT/direct-component-props-known" "$SERVER_OUTPUT" "component-props-known"
	# One request without an edit, as on a server that waits for the next save.
	compile_server "$SERVER_OUTPUT"

	# The props get a required field. Haxe types the component again but not
	# the page, so the warm request must still check the page again.
	copy_with_new_file_time "$variants/CacheCardPropsRequired.hx" "$PROJECT_DIR/src/CacheCardProps.hx"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$TMP_ROOT/direct-component-props-required" \
		>"$direct_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:component-props-required direct build unexpectedly succeeded" >&2
		return 1
	fi
	grep -Fq 'is missing required attribute "subtitle"' "$direct_failure_log" || {
		echo "SERVER_CACHE_PARITY:component-props-required direct build failed for the wrong reason" >&2
		sed -n '1,160p' "$direct_failure_log" >&2
		return 1
	}
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$server_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:component-props-required warm build accepted a template against stale component props" >&2
		return 1
	fi
	grep -Fq 'is missing required attribute "subtitle"' "$server_failure_log" || {
		echo "SERVER_CACHE_PARITY:component-props-required warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$server_failure_log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:component-props-required:PASS"

	copy_with_new_file_time "$variants/CacheCardPropsKnown.hx" "$PROJECT_DIR/src/CacheCardProps.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-component-props-restored"
	compare_generated_output "$TMP_ROOT/direct-component-props-restored" "$SERVER_OUTPUT" "component-props-restored"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheCardPage.hx" "$PROJECT_DIR/src/CacheCardComponents.hx" "$PROJECT_DIR/src/CacheCardProps.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "component-props-removed"
}

# Fails unless the warm request in `log` built fewer class modules than a full
# build (`full_count`) and added exactly `expected` template readers: classes
# that Haxe did not type again, built only because a template check in them
# reads a changed template fact.
expect_template_readers() {
	local log="$1"
	local label="$2"
	local full_count="$3"
	local expected="$4"
	local built readers
	built="$(built_class_count "$log")"
	readers="$(phase_count "$log" cache_filter_template_fact_readers)"
	if ((built >= full_count)); then
		echo "SERVER_CACHE_REUSE:$label built $built class modules, the same as a full build ($full_count)" >&2
		return 1
	fi
	if ((readers != expected)); then
		echo "SERVER_CACHE_REUSE:$label built $readers template readers again, expected $expected" >&2
		return 1
	fi
	echo "SERVER_CACHE_REUSE:$label:PASS built=$built readers=$readers full=$full_count"
}

# A shared types file, like the todo-app's `TodoTypes.hx`: typedefs and an
# enum that classes read through Haxe references, beside the props of a
# component that a template reads by tag name only. Before, any edit outside
# the class of such a file built every module again. Now a warm request builds
# the types that Haxe typed again, and a class that Haxe did not type again
# only when one of its template checks read a template fact that changed. Each
# warm output must equal a fresh build.
run_shared_type_variant() {
	local variants="$FIXTURE_DIR/variants/shared-type"
	local shared="$PROJECT_DIR/src/CacheShared.hx"
	local log="$TMP_ROOT/shared-type.log"
	local direct_failure_log="$TMP_ROOT/direct-shared-type-prop-kind.log"
	local server_failure_log="$TMP_ROOT/server-shared-type-prop-kind.log"
	local full_count

	cp "$variants/MainShared.hx" "$PROJECT_DIR/src/Main.hx"
	local name
	for name in CacheShared CacheSharedComponents CacheSharedPage CacheSharedQuiet CacheSharedRowUser CacheSharedInline CacheSharedInlinePage CacheSharedPanelBase; do
		cp "$variants/$name.hx" "$PROJECT_DIR/src/$name.hx"
	done
	# Old file times: every edit below is an ordinary save of a known file
	# (see the component-props case).
	python3 - "$PROJECT_DIR/src" <<'PY'
import os
import sys
import time

stamp = time.time() - 30
for name in os.listdir(sys.argv[1]):
    os.utime(os.path.join(sys.argv[1], name), (stamp, stamp))
PY
	compile_server "$SERVER_OUTPUT" >"$log"
	full_count="$(built_class_count "$log")"
	compile_direct "$TMP_ROOT/direct-shared-type-before"
	compare_generated_output "$TMP_ROOT/direct-shared-type-before" "$SERVER_OUTPUT" "shared-type-before"
	compile_server "$SERVER_OUTPUT"

	# 1. A field of a typedef that no class reads.
	edit_with_new_file_time "$shared" "	var note:String;" "	var note:String;
	var extra:Int;"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-shared-type-unread-field"
	compare_generated_output "$TMP_ROOT/direct-shared-type-unread-field" "$SERVER_OUTPUT" "shared-type-unread-field"
	expect_template_readers "$log" "shared-type-unread-field" "$full_count" 0

	# 2. A field that one class reads through a Haxe reference changes its type.
	edit_with_new_file_time "$shared" "	var id:Int;" "	var id:Float;"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-shared-type-read-field"
	compare_generated_output "$TMP_ROOT/direct-shared-type-read-field" "$SERVER_OUTPUT" "shared-type-read-field"
	expect_template_readers "$log" "shared-type-read-field" "$full_count" 0

	# 3. The component props get a field. Only the template that uses the
	# component reads the props; the quiet template does not.
	edit_with_new_file_time "$shared" "	@:optional var tone:CacheSharedTone;" "	@:optional var tone:CacheSharedTone;
	@:optional var size:String;"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-shared-type-prop-added"
	compare_generated_output "$TMP_ROOT/direct-shared-type-prop-added" "$SERVER_OUTPUT" "shared-type-prop-added"
	expect_template_readers "$log" "shared-type-prop-added" "$full_count" 1

	# 4. A prop changes its type. A fresh build rejects the unchanged template,
	# so the warm build must reject it too.
	edit_with_new_file_time "$shared" "	var label:String;
	@:optional" "	var label:Int;
	@:optional"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$TMP_ROOT/direct-shared-type-prop-kind" \
		>"$direct_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:shared-type-prop-kind direct build unexpectedly succeeded" >&2
		return 1
	fi
	grep -Fq '"label" expects int but got string' "$direct_failure_log" || {
		echo "SERVER_CACHE_PARITY:shared-type-prop-kind direct build failed for the wrong reason" >&2
		sed -n '1,160p' "$direct_failure_log" >&2
		return 1
	}
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$server_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:shared-type-prop-kind warm build accepted a template against stale component props" >&2
		return 1
	fi
	grep -Fq '"label" expects int but got string' "$server_failure_log" || {
		echo "SERVER_CACHE_PARITY:shared-type-prop-kind warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$server_failure_log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:shared-type-prop-kind:PASS"
	edit_with_new_file_time "$shared" "	var label:Int;
	@:optional" "	var label:String;
	@:optional"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-shared-type-prop-kind-restored"
	compare_generated_output "$TMP_ROOT/direct-shared-type-prop-kind-restored" "$SERVER_OUTPUT" "shared-type-prop-kind-restored"

	# 5. The enum that the props reach gets a constructor.
	edit_with_new_file_time "$shared" "	Loud;" "	Loud;
	Bright;"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-shared-type-enum-constructor"
	compare_generated_output "$TMP_ROOT/direct-shared-type-enum-constructor" "$SERVER_OUTPUT" "shared-type-enum-constructor"
	grep -Fq 'def bright()' "$SERVER_OUTPUT/cache_shared_tone.ex" || {
		echo "SERVER_CACHE_PARITY:shared-type-enum-constructor kept the stale enum" >&2
		return 1
	}
	expect_template_readers "$log" "shared-type-enum-constructor" "$full_count" 1

	# 6. The body of an inline function changes. This is class text, so it
	# takes the class path; the class that inlines the call is built again.
	edit_with_new_file_time "$shared" "return n * 2;" "return n * 3;"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-shared-type-inline-body"
	compare_generated_output "$TMP_ROOT/direct-shared-type-inline-body" "$SERVER_OUTPUT" "shared-type-inline-body"
	grep -Fq 'n * 3' "$SERVER_OUTPUT/cache_shared_row_user.ex" || {
		echo "SERVER_CACHE_PARITY:shared-type-inline-body kept the stale inlined body" >&2
		return 1
	}
	expect_template_readers "$log" "shared-type-inline-body" "$full_count" 0

	# 7. Metadata on the enum that the props reach.
	edit_with_new_file_time "$shared" "enum CacheSharedTone {" "@:elixirIdiomatic
enum CacheSharedTone {"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-shared-type-metadata"
	compare_generated_output "$TMP_ROOT/direct-shared-type-metadata" "$SERVER_OUTPUT" "shared-type-metadata"
	expect_template_readers "$log" "shared-type-metadata" "$full_count" 1

	# 8. Only a comment changes. The template facts are the same.
	edit_with_new_file_time "$shared" "/** No class reads this typedef. **/" "/** No class reads this typedef, still. **/"
	compile_server "$SERVER_OUTPUT" >"$log"
	compile_direct "$TMP_ROOT/direct-shared-type-comment"
	compare_generated_output "$TMP_ROOT/direct-shared-type-comment" "$SERVER_OUTPUT" "shared-type-comment"
	expect_template_readers "$log" "shared-type-comment" "$full_count" 0

	# 9. Back to the first shared file in one save.
	copy_with_new_file_time "$variants/CacheShared.hx" "$shared"
	compile_server "$SERVER_OUTPUT" >"$log"
	compare_generated_output "$TMP_ROOT/direct-shared-type-before" "$SERVER_OUTPUT" "shared-type-restored"
	expect_template_readers "$log" "shared-type-restored" "$full_count" 1

	# 10. A prop changes its kind inside the component class. This is class
	# text, so no compared file text changes, but the component's fingerprint
	# does: the warm build must check the page again and reject it, as a fresh
	# build does. The next edit outside a class of the shared file must not
	# lose that state (the comparison must not publish a fingerprint that it
	# did not check): the warm build must still reject the page.
	local inline_component="$PROJECT_DIR/src/CacheSharedInline.hx"
	local direct_class_edit_log="$TMP_ROOT/direct-shared-type-class-edit-then-comment.log"
	local server_class_edit_log="$TMP_ROOT/server-shared-type-class-edit-then-comment.log"
	edit_with_new_file_time "$inline_component" "{title:String, ?count:Int}" "{title:Int, ?count:Int}"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$TMP_ROOT/server-shared-type-class-edit.log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:shared-type-class-edit warm build accepted a template against props changed in a class edit" >&2
		return 1
	fi
	grep -Fq '"title" expects int but got string' "$TMP_ROOT/server-shared-type-class-edit.log" || {
		echo "SERVER_CACHE_PARITY:shared-type-class-edit warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$TMP_ROOT/server-shared-type-class-edit.log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:shared-type-class-edit:PASS"
	edit_with_new_file_time "$shared" "/** No class reads this typedef. **/" "/** No class reads this typedef, again. **/"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$TMP_ROOT/direct-shared-type-class-edit-then-comment" \
		>"$direct_class_edit_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:shared-type-class-edit-then-comment direct build unexpectedly succeeded" >&2
		return 1
	fi
	grep -Fq '"title" expects int but got string' "$direct_class_edit_log" || {
		echo "SERVER_CACHE_PARITY:shared-type-class-edit-then-comment direct build failed for the wrong reason" >&2
		sed -n '1,160p' "$direct_class_edit_log" >&2
		return 1
	}
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$server_class_edit_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:shared-type-class-edit-then-comment warm build kept a template check against stale component props after an edit of the shared file" >&2
		return 1
	fi
	grep -Fq '"title" expects int but got string' "$server_class_edit_log" || {
		echo "SERVER_CACHE_PARITY:shared-type-class-edit-then-comment warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$server_class_edit_log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:shared-type-class-edit-then-comment:PASS"
	edit_with_new_file_time "$inline_component" "{title:Int, ?count:Int}" "{title:String, ?count:Int}"
	copy_with_new_file_time "$variants/CacheShared.hx" "$shared"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$TMP_ROOT/direct-shared-type-before" "$SERVER_OUTPUT" "shared-type-class-edit-restored"

	# 11. The base of an extended props typedef gets a required field, in a
	# file that holds no template fact of its own. The page that uses
	# `<.shared_panel>` does not set it, so a fresh build rejects the page.
	# Haxe types CacheShared.hx again, and the fingerprint of the extended
	# typedef holds the merged fields, so the check on every warm request
	# already catches this change. Following the extended type into the
	# base's file (the AExtend walk in TemplateFactSources) is a second layer.
	local panel_base="$PROJECT_DIR/src/CacheSharedPanelBase.hx"
	local direct_base_log="$TMP_ROOT/direct-shared-type-extended-base.log"
	local server_base_log="$TMP_ROOT/server-shared-type-extended-base.log"
	edit_with_new_file_time "$panel_base" "	var title:String;" "	var title:String;
	var subtitle:String;"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$TMP_ROOT/direct-shared-type-extended-base" \
		>"$direct_base_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:shared-type-extended-base direct build unexpectedly succeeded" >&2
		return 1
	fi
	grep -Fq 'is missing required attribute "subtitle"' "$direct_base_log" || {
		echo "SERVER_CACHE_PARITY:shared-type-extended-base direct build failed for the wrong reason" >&2
		sed -n '1,160p' "$direct_base_log" >&2
		return 1
	}
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$server_base_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:shared-type-extended-base warm build accepted a template against a stale extended base" >&2
		return 1
	fi
	grep -Fq 'is missing required attribute "subtitle"' "$server_base_log" || {
		echo "SERVER_CACHE_PARITY:shared-type-extended-base warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$server_base_log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:shared-type-extended-base:PASS"
	copy_with_new_file_time "$variants/CacheSharedPanelBase.hx" "$panel_base"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$TMP_ROOT/direct-shared-type-before" "$SERVER_OUTPUT" "shared-type-extended-base-restored"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/CacheShared.hx" "$PROJECT_DIR/src/CacheSharedComponents.hx" "$PROJECT_DIR/src/CacheSharedPage.hx" \
		"$PROJECT_DIR/src/CacheSharedQuiet.hx" "$PROJECT_DIR/src/CacheSharedRowUser.hx" \
		"$PROJECT_DIR/src/CacheSharedInline.hx" "$PROJECT_DIR/src/CacheSharedInlinePage.hx" "$PROJECT_DIR/src/CacheSharedPanelBase.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "shared-type-removed"
}

run_router_contract_variant() {
	local variants="$FIXTURE_DIR/variants/router-contract"
	local direct_failure_log="$TMP_ROOT/direct-router-contract-renamed.log"
	local server_failure_log="$TMP_ROOT/server-router-contract-renamed.log"

	# The router names Contracts.UserIdPathParams by full path, without an
	# import, and its routes are never typed. Old file times and one request
	# without an edit make the contract edit below an ordinary edit of a
	# known file (see run_component_props_variant).
	cp "$variants/MainRouter.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/ContractsKnown.hx" "$PROJECT_DIR/src/Contracts.hx"
	python3 - "$PROJECT_DIR/src" <<'PY'
import os
import sys
import time

stamp = time.time() - 30
for name in ("Main.hx", "Contracts.hx"):
    os.utime(os.path.join(sys.argv[1], name), (stamp, stamp))
PY
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-router-contract-known"
	compare_generated_output "$TMP_ROOT/direct-router-contract-known" "$SERVER_OUTPUT" "router-contract-known"
	compile_server "$SERVER_OUTPUT"

	# The contract loses the field `id`. Haxe must type the router again, so
	# the warm request checks the route again and fails as a fresh build.
	copy_with_new_file_time "$variants/ContractsRenamed.hx" "$PROJECT_DIR/src/Contracts.hx"
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" compile.hxml -D "elixir_output=$TMP_ROOT/direct-router-contract-renamed" \
		>"$direct_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:router-contract-renamed direct build unexpectedly succeeded" >&2
		return 1
	fi
	grep -Fq 'is missing field for path param "id"' "$direct_failure_log" || {
		echo "SERVER_CACHE_PARITY:router-contract-renamed direct build failed for the wrong reason" >&2
		sed -n '1,160p' "$direct_failure_log" >&2
		return 1
	}
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" \
		>"$server_failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:router-contract-renamed warm build accepted a route against a stale params contract" >&2
		return 1
	fi
	grep -Fq 'is missing field for path param "id"' "$server_failure_log" || {
		echo "SERVER_CACHE_PARITY:router-contract-renamed warm build failed for the wrong reason" >&2
		sed -n '1,160p' "$server_failure_log" >&2
		return 1
	}
	echo "SERVER_CACHE_DIAGNOSTIC_PARITY:router-contract-renamed:PASS"

	copy_with_new_file_time "$variants/ContractsKnown.hx" "$PROJECT_DIR/src/Contracts.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-router-contract-restored"
	compare_generated_output "$TMP_ROOT/direct-router-contract-restored" "$SERVER_OUTPUT" "router-contract-restored"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/Contracts.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "router-contract-removed"
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

# Reads the phase report of one request and prints how many classes it
# scanned for one per-class phase, or 0 when the phase did not run.
scanned_class_count() {
	python3 - "$1" "$2" <<'PY'
import json
import sys

count = None
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("REFLAXE_ELIXIR_TIMINGS "):
        phases = json.loads(line.split(" ", 1)[1])["phases"]
        count = sum(phase["count"] for phase in phases if phase["name"] == sys.argv[2])
if count is None:
    raise SystemExit("no phase report in " + sys.argv[1])
print(count)
PY
}

run_private_exports_variant() {
	local variants="$FIXTURE_DIR/variants/private-exports"
	cp "$variants/PrivateCacheScope.hx" "$PROJECT_DIR/src/PrivateCacheScope.hx"
	local phase source expected_visibility expected_stdout

	# How many classes a request scans when it keeps no per-class result. The
	# define starts a new macro context; the next request starts another one.
	cp "$variants/MainLocal.hx" "$PROJECT_DIR/src/Main.hx"
	compile_server "$TMP_ROOT/private-full-scan-output" -D reflaxe_elixir_no_kept_class_results >"$TMP_ROOT/private-full-scan.log"
	local full_exports full_references
	full_exports="$(scanned_class_count "$TMP_ROOT/private-full-scan.log" private_method_exports_class_scan)"
	full_references="$(scanned_class_count "$TMP_ROOT/private-full-scan.log" reference_semantics_class_scan)"

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
		compile_server "$SERVER_OUTPUT" >"$TMP_ROOT/private-$phase.log"
		compile_direct "$TMP_ROOT/direct-private-$phase"
		compare_generated_output "$TMP_ROOT/direct-private-$phase" "$SERVER_OUTPUT" "private-exports-$phase"
		grep -Fxq "$expected_visibility" "$SERVER_OUTPUT/private_cache_scope.ex"
		if [[ "$phase" == remote ]]; then
			# Only Main changed, so Haxe typed Main again and nothing else. The
			# request must scan Main again (its new remote use made `secret` a
			# `def`, checked above), and keep the results of the other classes.
			local warm_exports warm_references
			warm_exports="$(scanned_class_count "$TMP_ROOT/private-$phase.log" private_method_exports_class_scan)"
			warm_references="$(scanned_class_count "$TMP_ROOT/private-$phase.log" reference_semantics_class_scan)"
			if ((warm_exports < 1 || warm_exports >= full_exports || warm_references < 1 || warm_references >= full_references)); then
				echo "SERVER_CACHE_REUSE:private-exports-remote scanned exports=$warm_exports/$full_exports references=$warm_references/$full_references classes" >&2
				return 1
			fi
			echo "SERVER_CACHE_REUSE:kept-class-results exports=$warm_exports/$full_exports references=$warm_references/$full_references:PASS"
		fi
		"$TIMEOUT" --secs 60 --cwd "$PROJECT_DIR" -- elixir -e '
          [root, expected] = System.argv()
          {:ok, _, []} = Kernel.ParallelCompiler.compile(Path.wildcard(Path.join(root, "**/*.ex")))
          ExUnit.start(autorun: false)
          actual = ExUnit.CaptureIO.capture_io(fn -> Main.main() end)
          if actual != expected <> "\n", do: raise("private export runtime mismatch: #{inspect(actual)}")
        ' "$SERVER_OUTPUT" "$expected_stdout"
	done

	# Dead-code elimination can change the members of a class that Haxe did not
	# type again. Under `-dce full`, PrivateDceCaller.relay() is private and
	# unused, so DCE removes it, and with it the only use of the private
	# PrivateDceOwner.secret(). The edit of PrivateDceUser then calls relay().
	# Haxe types only PrivateDceUser and Main again, but relay() is back, so
	# secret() must be generated as `def`. A kept scan result of
	# PrivateDceCaller from before the edit must not be reused.
	local dce_args=(-dce full -main Main)
	rm -f "$PROJECT_DIR/src/PrivateCacheScope.hx"
	cp "$variants/MainDce.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/PrivateDceCaller.hx" "$PROJECT_DIR/src/PrivateDceCaller.hx"
	cp "$variants/PrivateDceOwner.hx" "$PROJECT_DIR/src/PrivateDceOwner.hx"
	cp "$variants/PrivateDceUserBefore.hx" "$PROJECT_DIR/src/PrivateDceUser.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_direct "$TMP_ROOT/direct-private-dce-before" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-private-dce-before" "$SERVER_OUTPUT" "private-exports-dce-before"
	cp "$variants/PrivateDceUserAfter.hx" "$PROJECT_DIR/src/PrivateDceUser.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_direct "$TMP_ROOT/direct-private-dce-after" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-private-dce-after" "$SERVER_OUTPUT" "private-exports-dce-made-live"
	grep -Fxq '  def secret() do' "$SERVER_OUTPUT/private_dce_owner.ex" || {
		echo "SERVER_CACHE_PARITY:private-exports-dce-made-live did not export secret()" >&2
		return 1
	}
	rm -f "$PROJECT_DIR/src/PrivateDceCaller.hx" "$PROJECT_DIR/src/PrivateDceOwner.hx" "$PROJECT_DIR/src/PrivateDceUser.hx"

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "private-exports-baseline-restored"
}

# Under `-dce full`, Haxe keeps only the members that the whole program uses.
# An edit in one class can therefore add members to, or remove members from,
# another class that Haxe does not type again. Each step below edits only a
# user class, and the warm output must equal a fresh build:
# - public: DceMemberCaller.relay() becomes live. It is public, so no private
#   export changes for DceMemberCaller, and only its member list shows the edit.
# - all: the private constructor and total() become live too.
# - none: all of them become dead again, and so do the private
#   DceMemberOwner methods that only they called.
# - fields-named and fields-none: a module-level function with `@:native`
#   becomes live and dead again. That `@:native` names the module, and the
#   module name must not depend on whether the function is live.
# - inherited-hello and inherited-none: an inherited method of DceKid's parent
#   becomes live and dead again. DceKid's own members do not change, but its
#   module has a `hello` delegator only while the parent's `hello` is live.
# Prints the count of one phase in the phase report of `log`, or 0 when the
# report has no such phase.
phase_count() {
	python3 - "$1" "$2" <<'PY'
import json
import sys

count = None
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("REFLAXE_ELIXIR_TIMINGS "):
        phases = json.loads(line.split(" ", 1)[1])["phases"]
        count = sum(phase["count"] for phase in phases if phase["name"] == sys.argv[2])
if count is None:
    raise SystemExit("no phase report in " + sys.argv[1])
print(count)
PY
}

# Prints the bytes digest and the nanosecond file time of the output manifest.
manifest_stamp() {
	python3 - "$1/_GeneratedFiles.json" <<'PY'
import hashlib
import os
import sys

path = sys.argv[1]
print(hashlib.sha256(open(path, "rb").read()).hexdigest(), os.stat(path).st_mtime_ns)
PY
}

# Replaces the first `old` in `path` with `new`.
replace_once() {
	python3 - "$1" "$2" "$3" <<'PY'
import sys

path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path, encoding="utf-8").read()
if old not in text:
    raise SystemExit(f"fixture could not find {old!r} in {path}")
open(path, "w", encoding="utf-8").write(text.replace(old, new, 1))
PY
}

# A warm request whose output equals the published output must not touch the
# output folder: no prepare or transaction folder, and no new manifest. The
# manifest keeps its bytes and its file time. A request that changes a file
# still runs the whole transaction.
run_unchanged_output_variant() {
	local direct_comment="$TMP_ROOT/direct-unchanged-comment"
	local direct_body="$TMP_ROOT/direct-unchanged-body"
	local log="$TMP_ROOT/unchanged-output.log"
	local before after

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "unchanged-output-baseline"

	# 1. No edit.
	before="$(manifest_stamp "$SERVER_OUTPUT")"
	compile_server "$SERVER_OUTPUT" >"$log"
	after="$(manifest_stamp "$SERVER_OUTPUT")"
	if [[ "$before" != "$after" ]]; then
		echo "SERVER_CACHE_REUSE:unchanged-output-no-edit wrote a new manifest ($before -> $after)" >&2
		return 1
	fi
	grep -Fq 'No files updated.' "$log" || {
		echo "SERVER_CACHE_REUSE:unchanged-output-no-edit did not report that no file changed" >&2
		return 1
	}
	if [[ "$(phase_count "$log" output_transaction_skipped)" != "1" ]] \
		|| [[ "$(phase_count "$log" output_transaction_journal_preparation)" != "0" ]]; then
		echo "SERVER_CACHE_REUSE:unchanged-output-no-edit ran the output transaction" >&2
		return 1
	fi
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "unchanged-output-no-edit"

	# 2. A comment at the end of a line in a class body. Haxe types Main again
	# and Reflaxe builds it again, but the Elixir and its source map stay the same.
	replace_once "$PROJECT_DIR/src/Main.hx" "return Ready;" "return Ready; // same output"
	before="$(manifest_stamp "$SERVER_OUTPUT")"
	compile_server "$SERVER_OUTPUT" >"$log"
	after="$(manifest_stamp "$SERVER_OUTPUT")"
	compile_direct "$direct_comment"
	compare_generated_output "$direct_comment" "$SERVER_OUTPUT" "unchanged-output-comment"
	if [[ "$(built_class_count "$log")" == "0" ]]; then
		echo "SERVER_CACHE_REUSE:unchanged-output-comment built no class; the edit did not reach Haxe" >&2
		return 1
	fi
	if [[ "$before" != "$after" ]] || [[ "$(phase_count "$log" output_transaction_skipped)" != "1" ]]; then
		echo "SERVER_CACHE_REUSE:unchanged-output-comment ran the output transaction for identical output" >&2
		return 1
	fi

	# 2a. A hand edit of a file that the request builds again. The Elixir of
	# the request equals the published file, but the live file does not: the
	# ownership check must refuse before the skip, as it refuses a publication.
	local main_copy="$TMP_ROOT/unchanged-main.ex"
	local failure_log="$TMP_ROOT/unchanged-output-hand-edit.log"
	command cp "$SERVER_OUTPUT/main.ex" "$main_copy"
	replace_once "$PROJECT_DIR/src/Main.hx" "// same output" "// same output, hand edit"
	printf '# hand edit\n' >>"$SERVER_OUTPUT/main.ex"
	if compile_server "$SERVER_OUTPUT" >"$failure_log" 2>&1; then
		echo "SERVER_CACHE_REUSE:unchanged-output-hand-edit accepted a hand-edited built file" >&2
		return 1
	fi
	grep -Fq 'Owned generated output was modified outside the compiler' "$failure_log" || {
		echo "SERVER_CACHE_REUSE:unchanged-output-hand-edit failed for the wrong reason" >&2
		sed -n '1,160p' "$failure_log" >&2
		return 1
	}
	command cp "$main_copy" "$SERVER_OUTPUT/main.ex"
	compile_server "$SERVER_OUTPUT" >"$log"
	compare_generated_output "$direct_comment" "$SERVER_OUTPUT" "unchanged-output-hand-edit-restored"

	# 2b. A deleted file that the request builds again. The Elixir equals the
	# manifest digest, but the file is missing, so the transaction runs and
	# writes it again, as a fresh build does.
	replace_once "$PROJECT_DIR/src/Main.hx" "// same output, hand edit" "// same output, deleted file"
	rm -f "$SERVER_OUTPUT/main.ex"
	compile_server "$SERVER_OUTPUT" >"$log"
	if [[ ! -f "$SERVER_OUTPUT/main.ex" ]] || [[ "$(phase_count "$log" output_transaction_skipped)" != "0" ]]; then
		echo "SERVER_CACHE_REUSE:unchanged-output-deleted-file skipped the transaction of a missing built file" >&2
		return 1
	fi
	compare_generated_output "$direct_comment" "$SERVER_OUTPUT" "unchanged-output-deleted-file"
	before="$(manifest_stamp "$SERVER_OUTPUT")"

	# 3. A real class-body edit changes main.ex, so the transaction runs.
	replace_once "$PROJECT_DIR/src/Main.hx" "return payload.value + payload.value;" \
		"return payload.value + payload.value + payload.value;"
	compile_server "$SERVER_OUTPUT" >"$log"
	after="$(manifest_stamp "$SERVER_OUTPUT")"
	compile_direct "$direct_body"
	compare_generated_output "$direct_body" "$SERVER_OUTPUT" "unchanged-output-body-edit"
	if [[ "$before" == "$after" ]] || [[ "$(phase_count "$log" output_transaction_skipped)" != "0" ]]; then
		echo "SERVER_CACHE_REUSE:unchanged-output-body-edit skipped the transaction of a changed file" >&2
		return 1
	fi

	# 4. Back to the baseline: main.ex changes again.
	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "unchanged-output-restored"
	echo "SERVER_CACHE_REUSE:unchanged-output-skips-transaction:PASS"
}

run_dce_members_variant() {
	local variants="$FIXTURE_DIR/variants/dce-members"
	local dce_args=(-dce full -main Main)
	local step user expected
	cp "$variants/MainMembers.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/DceMemberCaller.hx" "$PROJECT_DIR/src/DceMemberCaller.hx"
	cp "$variants/DceMemberOwner.hx" "$PROJECT_DIR/src/DceMemberOwner.hx"
	cp "$variants/DceMemberUserNone.hx" "$PROJECT_DIR/src/DceMemberUser.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_direct "$TMP_ROOT/direct-dce-members-start" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-dce-members-start" "$SERVER_OUTPUT" "dce-members-start"
	for step in public all none; do
		case "$step" in
			public) user=DceMemberUserPublic.hx expected='  def relay() do' ;;
			all) user=DceMemberUserAll.hx expected='  def total(struct) do' ;;
			none) user=DceMemberUserNone.hx expected='' ;;
		esac
		cp "$variants/$user" "$PROJECT_DIR/src/DceMemberUser.hx"
		compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
		compile_direct "$TMP_ROOT/direct-dce-members-$step" "${dce_args[@]}"
		compare_generated_output "$TMP_ROOT/direct-dce-members-$step" "$SERVER_OUTPUT" "dce-members-$step"
		# Guard the fixture: each step must change the caller's members.
		if [[ -n "$expected" ]]; then
			grep -Fxq "$expected" "$SERVER_OUTPUT/dce_member_caller.ex"
		elif grep -Fq 'def relay()' "$SERVER_OUTPUT/dce_member_caller.ex"; then
			echo "SERVER_CACHE_PARITY:dce-members-none kept relay()" >&2
			return 1
		fi
	done
	rm -f "$PROJECT_DIR/src/DceMemberCaller.hx" "$PROJECT_DIR/src/DceMemberOwner.hx" "$PROJECT_DIR/src/DceMemberUser.hx"

	cp "$variants/MainFields.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/DceFields.hx" "$PROJECT_DIR/src/DceFields.hx"
	cp "$variants/DceFieldsUserNone.hx" "$PROJECT_DIR/src/DceFieldsUser.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_direct "$TMP_ROOT/direct-dce-fields-start" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-dce-fields-start" "$SERVER_OUTPUT" "dce-fields-start"
	for step in named none; do
		if [[ "$step" == named ]]; then user=DceFieldsUserNamed.hx; else user=DceFieldsUserNone.hx; fi
		cp "$variants/$user" "$PROJECT_DIR/src/DceFieldsUser.hx"
		compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
		compile_direct "$TMP_ROOT/direct-dce-fields-$step" "${dce_args[@]}"
		compare_generated_output "$TMP_ROOT/direct-dce-fields-$step" "$SERVER_OUTPUT" "dce-fields-$step"
		grep -Fq 'DceNamedFields.plain()' "$SERVER_OUTPUT/main.ex"
	done
	rm -f "$PROJECT_DIR/src/DceFields.hx" "$PROJECT_DIR/src/DceFieldsUser.hx"

	cp "$variants/MainKid.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/DceBase.hx" "$PROJECT_DIR/src/DceBase.hx"
	cp "$variants/DceKid.hx" "$PROJECT_DIR/src/DceKid.hx"
	cp "$variants/DceKidUserNone.hx" "$PROJECT_DIR/src/DceKidUser.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_direct "$TMP_ROOT/direct-dce-inherited-start" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-dce-inherited-start" "$SERVER_OUTPUT" "dce-inherited-start"
	for step in hello none; do
		if [[ "$step" == hello ]]; then user=DceKidUserHello.hx; else user=DceKidUserNone.hx; fi
		cp "$variants/$user" "$PROJECT_DIR/src/DceKidUser.hx"
		compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
		compile_direct "$TMP_ROOT/direct-dce-inherited-$step" "${dce_args[@]}"
		compare_generated_output "$TMP_ROOT/direct-dce-inherited-$step" "$SERVER_OUTPUT" "dce-inherited-$step"
		# Guard the fixture: the step must add or remove the delegator.
		if [[ "$step" == hello ]]; then
			grep -Fxq '  def hello(struct) do' "$SERVER_OUTPUT/dce_kid.ex"
		elif grep -Fq 'def hello(' "$SERVER_OUTPUT/dce_kid.ex"; then
			echo "SERVER_CACHE_PARITY:dce-inherited-none kept the hello delegator" >&2
			return 1
		fi
	done
	rm -f "$PROJECT_DIR/src/DceBase.hx" "$PROJECT_DIR/src/DceKid.hx" "$PROJECT_DIR/src/DceKidUser.hx"

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "dce-members-baseline-restored"
}

# When a class stops producing output in a warm build, its old module, source
# map, and manifest entry must go, as in a fresh build. Two ways are checked:
# - dead: under `-dce full`, DeadTarget.m becomes live through an edit of
#   DeadUser and dead again through a second edit. The unused
#   DeadLive.viaDead() still calls it, so DeadTarget stays in the module list
#   that Reflaxe gets before dead-code elimination, with no members and an
#   empty module. Haxe does not type DeadTarget again for either edit.
# - extern: DceBase, which DceKid extends, becomes an `extern` class. Haxe
#   types it again, but an extern class has no module of its own.
# - application: Starter gets `@:application`, so its file moves from
#   `starter.ex` to `my_app/application.ex`, and back when the edit is undone.
# A request without an edit after each step must build no class and keep the
# output as it is.
run_dropped_output_variant() {
	local variants="$FIXTURE_DIR/variants/dropped-output"
	local dce_args=(-dce full -main Main)
	local log="$TMP_ROOT/dropped-output-unchanged.log"
	local step user count
	cp "$variants/MainDead.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/DeadLive.hx" "$PROJECT_DIR/src/DeadLive.hx"
	cp "$variants/DeadTarget.hx" "$PROJECT_DIR/src/DeadTarget.hx"
	cp "$variants/DeadUserNone.hx" "$PROJECT_DIR/src/DeadUser.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_direct "$TMP_ROOT/direct-dropped-dead-start" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-dropped-dead-start" "$SERVER_OUTPUT" "dropped-dead-start"
	for step in calls none; do
		if [[ "$step" == calls ]]; then user=DeadUserCalls.hx; else user=DeadUserNone.hx; fi
		cp "$variants/$user" "$PROJECT_DIR/src/DeadUser.hx"
		compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
		compile_direct "$TMP_ROOT/direct-dropped-dead-$step" "${dce_args[@]}"
		compare_generated_output "$TMP_ROOT/direct-dropped-dead-$step" "$SERVER_OUTPUT" "dropped-dead-$step"
		# Guard the fixture: the step must add or remove the module.
		if [[ "$step" == calls ]]; then
			[[ -f "$SERVER_OUTPUT/dead_target.ex" ]]
		elif [[ -e "$SERVER_OUTPUT/dead_target.ex" || -e "$SERVER_OUTPUT/dead_target.ex.map" ]]; then
			echo "SERVER_CACHE_PARITY:dropped-dead-none kept dead_target.ex" >&2
			return 1
		fi
	done
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}" >"$log"
	compare_generated_output "$TMP_ROOT/direct-dropped-dead-none" "$SERVER_OUTPUT" "dropped-dead-unchanged"
	count="$(built_class_count "$log")"
	if ((count != 0)); then
		echo "SERVER_CACHE_REUSE:dropped-dead-unchanged built $count class modules again without an edit" >&2
		return 1
	fi
	rm -f "$PROJECT_DIR/src/DeadLive.hx" "$PROJECT_DIR/src/DeadTarget.hx" "$PROJECT_DIR/src/DeadUser.hx"

	cp "$FIXTURE_DIR/variants/dce-members/MainKid.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$FIXTURE_DIR/variants/dce-members/DceBase.hx" "$PROJECT_DIR/src/DceBase.hx"
	cp "$FIXTURE_DIR/variants/dce-members/DceKid.hx" "$PROJECT_DIR/src/DceKid.hx"
	cp "$FIXTURE_DIR/variants/dce-members/DceKidUserNone.hx" "$PROJECT_DIR/src/DceKidUser.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_direct "$TMP_ROOT/direct-dropped-extern-start" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-dropped-extern-start" "$SERVER_OUTPUT" "dropped-extern-start"
	[[ -f "$SERVER_OUTPUT/dce_base.ex" && -f "$SERVER_OUTPUT/dce_base.ex.map" ]]
	cp "$variants/DceBaseExtern.hx" "$PROJECT_DIR/src/DceBase.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compile_direct "$TMP_ROOT/direct-dropped-extern" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-dropped-extern" "$SERVER_OUTPUT" "dropped-extern"
	if [[ -e "$SERVER_OUTPUT/dce_base.ex" || -e "$SERVER_OUTPUT/dce_base.ex.map" ]]; then
		echo "SERVER_CACHE_PARITY:dropped-extern kept dce_base.ex or its source map" >&2
		return 1
	fi
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}" >"$log"
	compare_generated_output "$TMP_ROOT/direct-dropped-extern" "$SERVER_OUTPUT" "dropped-extern-unchanged"
	count="$(built_class_count "$log")"
	if ((count != 0)); then
		echo "SERVER_CACHE_REUSE:dropped-extern-unchanged built $count class modules again without an edit" >&2
		return 1
	fi
	cp "$FIXTURE_DIR/variants/dce-members/DceBase.hx" "$PROJECT_DIR/src/DceBase.hx"
	compile_server "$SERVER_OUTPUT" "${dce_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-dropped-extern-start" "$SERVER_OUTPUT" "dropped-extern-restored"
	rm -f "$PROJECT_DIR/src/DceBase.hx" "$PROJECT_DIR/src/DceKid.hx" "$PROJECT_DIR/src/DceKidUser.hx"

	cp "$variants/MainStarter.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/StarterPlain.hx" "$PROJECT_DIR/src/Starter.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-dropped-application-start"
	compare_generated_output "$TMP_ROOT/direct-dropped-application-start" "$SERVER_OUTPUT" "dropped-application-start"
	[[ -f "$SERVER_OUTPUT/starter.ex" ]]
	cp "$variants/StarterApplication.hx" "$PROJECT_DIR/src/Starter.hx"
	compile_server "$SERVER_OUTPUT"
	compile_direct "$TMP_ROOT/direct-dropped-application"
	compare_generated_output "$TMP_ROOT/direct-dropped-application" "$SERVER_OUTPUT" "dropped-application"
	# Guard the fixture: the module must move to its application path.
	[[ -f "$SERVER_OUTPUT/my_app/application.ex" ]]
	if [[ -e "$SERVER_OUTPUT/starter.ex" || -e "$SERVER_OUTPUT/starter.ex.map" ]]; then
		echo "SERVER_CACHE_PARITY:dropped-application kept starter.ex or its source map" >&2
		return 1
	fi
	cp "$variants/StarterPlain.hx" "$PROJECT_DIR/src/Starter.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$TMP_ROOT/direct-dropped-application-start" "$SERVER_OUTPUT" "dropped-application-restored"
	if [[ -e "$SERVER_OUTPUT/my_app/application.ex" ]]; then
		echo "SERVER_CACHE_PARITY:dropped-application-restored kept my_app/application.ex" >&2
		return 1
	fi
	rm -f "$PROJECT_DIR/src/Starter.hx"

	restore_baseline_sources
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "dropped-output-baseline-restored"
}

# A request that fails after Reflaxe started must not lose what the next warm
# request needs. With `-D app_name=Cache`, the printer writes a bare
# `RegistryTools.run()` in the Web module `CacheWeb.RegistryPage` as
# `Cache.RegistryTools.run()` only while the module registry knows
# `Cache.RegistryTools`. Only the class support.RegistryTools registers that
# name, when it is built. The request fails on a hand-edited output file; the
# retry builds RegistryPage again, but not RegistryTools, so the registry needs
# the module name kept from before the failed request.
run_failed_request_registry_variant() {
	local variants="$FIXTURE_DIR/variants/registry-failure"
	local app_args=(-D app_name=Cache)
	local failure_log="$TMP_ROOT/registry-failure.log"
	mkdir -p "$PROJECT_DIR/src/support"
	cp "$variants/MainRegistry.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/RegistryToolsNative.hx" "$PROJECT_DIR/src/RegistryToolsNative.hx"
	cp "$variants/support/RegistryTools.hx" "$PROJECT_DIR/src/support/RegistryTools.hx"
	cp "$variants/RegistryPage1.hx" "$PROJECT_DIR/src/RegistryPage.hx"
	compile_server "$SERVER_OUTPUT" "${app_args[@]}"
	compile_server "$SERVER_OUTPUT" "${app_args[@]}"
	compile_direct "$TMP_ROOT/direct-registry-before" "${app_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-registry-before" "$SERVER_OUTPUT" "registry-failure-before"
	local page="$SERVER_OUTPUT/cache_web/registry_page.ex"
	grep -Fq 'Cache.RegistryTools.run()' "$page" || {
		echo "SERVER_CACHE_PARITY:registry-failure fixture did not qualify RegistryTools" >&2
		return 1
	}

	local page_copy="$TMP_ROOT/registry-page-original.ex"
	cp "$page" "$page_copy"
	cp "$variants/RegistryPage2.hx" "$PROJECT_DIR/src/RegistryPage.hx"
	python3 - "$page" <<'PY'
import sys

path = sys.argv[1]
data = open(path, "rb").read()
changed = data.replace(b"defmodule", b"defmodulf", 1)
if changed == data:
    raise SystemExit("registry-failure fixture could not change registry_page.ex")
open(path, "wb").write(changed)
PY
	if "$TIMEOUT" --secs 120 --cwd "$PROJECT_DIR" -- \
		"$HAXE_BIN" --connect "$SERVER_PORT" compile.hxml -D "elixir_output=$SERVER_OUTPUT" "${app_args[@]}" \
		>"$failure_log" 2>&1
	then
		echo "SERVER_CACHE_PARITY:registry-failure request accepted a hand-edited generated file" >&2
		return 1
	fi
	grep -Fq 'Owned generated output was modified outside the compiler' "$failure_log" || {
		echo "SERVER_CACHE_PARITY:registry-failure request failed for the wrong reason" >&2
		sed -n '1,160p' "$failure_log" >&2
		return 1
	}
	cp "$page_copy" "$page"
	compile_server "$SERVER_OUTPUT" "${app_args[@]}"
	compile_direct "$TMP_ROOT/direct-registry-after" "${app_args[@]}"
	compare_generated_output "$TMP_ROOT/direct-registry-after" "$SERVER_OUTPUT" "registry-failure-retry"
	echo "SERVER_CACHE_REUSE:module-names-kept-after-failed-request:PASS"

	restore_baseline_sources
	rm -rf "$PROJECT_DIR/src/support"
	rm -f "$PROJECT_DIR/src/RegistryToolsNative.hx" "$PROJECT_DIR/src/RegistryPage.hx"
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "registry-failure-removed"
}

# A "late-typed" module is one that Haxe first types during generation,
# because code asks Haxe for a type by name after typing ended. Haxe records
# that lookup as a dependency of an unrelated module that the next warm
# request reuses, so that request types the late module as part of the
# program, and builds and writes modules that a fresh build never writes.
# Each case below makes several requests without an edit. Every warm output
# must equal one fresh build, and a request without an edit builds nothing.
# - typed: the assigns name `phoenix.Phoenix.Form`. Reflaxe needed
#   `StringTools` for its helpers and asked Haxe for it during generation;
#   the second request added three iterator modules, and under `-dce full`
#   it wrote a smaller `string_tools.ex` than a fresh build.
# - let: a `<.form :let={f}>` template is the only use of Phoenix. The
#   template linter asked Haxe for `phoenix.Phoenix.Form`; the module set grew
#   over four requests and added `phoenix/*.ex` and `ecto/*.ex`.
run_late_typed_case() {
	local name="$1"
	local source="$2"
	shift 2
	local variants="$FIXTURE_DIR/variants/late-typed"
	local direct_output="$TMP_ROOT/direct-late-typed-$name"
	local log="$TMP_ROOT/late-typed-$name.log"
	local request built

	cp "$variants/MainLateForm.hx" "$PROJECT_DIR/src/Main.hx"
	cp "$variants/$source" "$PROJECT_DIR/src/LateForm.hx"
	# Old file times make these ordinary known files, so that a request
	# without an edit does not read them again (see ServerSourceFreshness).
	python3 - "$PROJECT_DIR/src" <<'PY'
import os
import sys
import time

stamp = time.time() - 30
for name in ("Main.hx", "LateForm.hx"):
    os.utime(os.path.join(sys.argv[1], name), (stamp, stamp))
PY
	compile_direct "$direct_output" "$@"
	for request in 1 2 3 4; do
		compile_server "$SERVER_OUTPUT" "$@" >"$log"
		compare_generated_output "$direct_output" "$SERVER_OUTPUT" "late-typed-$name-request-$request"
		built="$(built_class_count "$log")"
		if ((request > 1 && built != 0)); then
			echo "SERVER_CACHE_REUSE:late-typed-$name request $request built $built class modules without an edit" >&2
			return 1
		fi
	done
	echo "SERVER_CACHE_REUSE:late-typed-$name:PASS"

	restore_baseline_sources
	rm -f "$PROJECT_DIR/src/LateForm.hx"
}

run_late_typed_variant() {
	run_late_typed_case "typed" "LateFormTyped.hx"
	run_late_typed_case "let" "LateFormLet.hx"
	run_late_typed_case "typed-dce-full" "LateFormTyped.hx" -dce full
	compile_server "$SERVER_OUTPUT"
	compare_generated_output "$DIRECT_BASELINE" "$SERVER_OUTPUT" "late-typed-removed"
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
run_early_typed_variant
run_generic_variant
run_copied_metadata_variant
run_diagnostics_request_variant

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
run_dce_members_variant
run_dropped_output_variant
run_unchanged_output_variant
run_failed_request_registry_variant
run_native_class_variant
run_tampered_output_variant
run_missing_output_variant
run_deleted_output_root_variant folder
run_deleted_output_root_variant files-and-manifest
run_deleted_output_root_variant manifest
run_deleted_output_root_variant one-file
run_deleted_output_root_variant folder-and-edit
run_foreign_manifest_variant direct-define
run_foreign_manifest_variant empty
run_mixed_file_variant
run_mixed_file_registry_variant
run_mixed_file_non_ascii_variant
run_decoy_registry_variant
run_component_props_variant
run_shared_type_variant
run_router_contract_variant
run_discovery_variant
run_late_typed_variant
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

#!/usr/bin/env bash
set -euo pipefail

# Bounded todo-app compile benchmark.
#
# Produces a JSON artifact with cold, warm fresh-process, and edited
# full-program fresh-process compile timings. It does not call the latter
# "incremental" because this harness does not retain compiler process state.
# Runs in an isolated git worktree by default so cold cleanup can remove deps,
# _build, and generated lib outputs without mutating the caller's workspace.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"

APP_REL="examples/todo-app"
REF="HEAD"
ARTIFACT_DIR_REL="tmp/perf/todo-compile"
OUT_REL="tmp/perf/compile-times.json"
BUILD_FILE="build-server.hxml"
EDITED_SOURCE_REL="src_shared/shared/TodoTypes.hx"
HAXE_BIN="${HAXE_BIN:-haxe}"
PHASE_TIMERS="${PHASE_TIMERS:-off}"
MACHINE_STATE="${BENCHMARK_MACHINE_STATE:-unknown}"

DEPS_GET_TIMEOUT="${DEPS_GET_TIMEOUT:-300}"
DEPS_COMPILE_TIMEOUT="${DEPS_COMPILE_TIMEOUT:-420}"
HAXE_BUILD_TIMEOUT="${HAXE_BUILD_TIMEOUT:-300}"
MIX_COMPILE_TIMEOUT="${MIX_COMPILE_TIMEOUT:-300}"

KEEP_WORKTREE=0

usage() {
  cat >&2 <<EOF
Usage: $0 [options]

Options:
  --app PATH            App path relative to repo root (default: $APP_REL)
  --ref REF             Git ref to benchmark in isolated worktree (default: $REF)
  --artifact-dir PATH   Artifact dir relative to repo root (default: $ARTIFACT_DIR_REL)
  --out PATH            JSON output path relative to repo root (default: $OUT_REL)
  --build-file PATH     HXML build file relative to app root (default: $BUILD_FILE)
  --edited-source PATH  Source file for the deterministic A→B content edit
                        (default: $EDITED_SOURCE_REL)
  --incremental-source PATH
                        Deprecated alias for --edited-source
  --phase-timers MODE   off or coarse (default: $PHASE_TIMERS)
  --machine-state STATE unknown, idle, or contended (default: $MACHINE_STATE)
  --keep-worktree       Do not remove the benchmark worktree on exit
  -h, --help            Show this help

Environment timeouts, in seconds:
  DEPS_GET_TIMEOUT=$DEPS_GET_TIMEOUT
  DEPS_COMPILE_TIMEOUT=$DEPS_COMPILE_TIMEOUT
  HAXE_BUILD_TIMEOUT=$HAXE_BUILD_TIMEOUT
  MIX_COMPILE_TIMEOUT=$MIX_COMPILE_TIMEOUT
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APP_REL="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    --artifact-dir) ARTIFACT_DIR_REL="$2"; shift 2 ;;
    --out) OUT_REL="$2"; shift 2 ;;
    --build-file) BUILD_FILE="$2"; shift 2 ;;
    --edited-source) EDITED_SOURCE_REL="$2"; shift 2 ;;
    --incremental-source)
      echo "[bench] WARNING: --incremental-source is deprecated; use --edited-source" >&2
      EDITED_SOURCE_REL="$2"
      shift 2
      ;;
    --phase-timers) PHASE_TIMERS="$2"; shift 2 ;;
    --machine-state) MACHINE_STATE="$2"; shift 2 ;;
    --keep-worktree) KEEP_WORKTREE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

require_safe_relative_path() {
  local label="$1"
  local path="$2"
  if [[ "$path" = /* || "$path" == *".."* ]]; then
    echo "[bench] ERROR: $label must be a workspace-relative path without '..': $path" >&2
    exit 2
  fi
}

require_safe_relative_path "--app" "$APP_REL"
require_safe_relative_path "--artifact-dir" "$ARTIFACT_DIR_REL"
require_safe_relative_path "--out" "$OUT_REL"
require_safe_relative_path "--build-file" "$BUILD_FILE"
require_safe_relative_path "--edited-source" "$EDITED_SOURCE_REL"

if [[ "$PHASE_TIMERS" != "off" && "$PHASE_TIMERS" != "coarse" ]]; then
  echo "[bench] ERROR: --phase-timers must be 'off' or 'coarse': $PHASE_TIMERS" >&2
  exit 2
fi
if [[ "$MACHINE_STATE" != "unknown" && "$MACHINE_STATE" != "idle" && "$MACHINE_STATE" != "contended" ]]; then
  echo "[bench] ERROR: --machine-state must be unknown, idle, or contended: $MACHINE_STATE" >&2
  exit 2
fi

if [[ ! -x "$TIMEOUT" ]]; then
  echo "[bench] ERROR: missing timeout wrapper: $TIMEOUT" >&2
  exit 2
fi

if ! command -v "$HAXE_BIN" >/dev/null 2>&1; then
  echo "[bench] ERROR: Haxe binary not found: $HAXE_BIN" >&2
  exit 2
fi

if ! command -v mix >/dev/null 2>&1; then
  echo "[bench] ERROR: mix is required" >&2
  exit 2
fi

ARTIFACT_DIR="$ROOT_DIR/$ARTIFACT_DIR_REL"
OUT_PATH="$ROOT_DIR/$OUT_REL"
WORKTREE="$ARTIFACT_DIR/worktree"
LOG_DIR="$ARTIFACT_DIR/logs"
RESULTS_NDJSON="$ARTIFACT_DIR/results.ndjson"
META_JSON="$ARTIFACT_DIR/meta.json"
OUTPUT_STATES_NDJSON="$ARTIFACT_DIR/output-states.ndjson"

mkdir -p "$ARTIFACT_DIR" "$LOG_DIR" "$(dirname "$OUT_PATH")"
rm -f "$RESULTS_NDJSON" "$META_JSON" "$OUTPUT_STATES_NDJSON"

log() { echo "[bench] $*"; }

now_ms() {
  python3 - <<'PY'
import time
print(int(time.time() * 1000))
PY
}

cleanup() {
  if [[ "$KEEP_WORKTREE" -eq 0 && -e "$WORKTREE/.git" ]]; then
    git -C "$ROOT_DIR" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

write_meta() {
  local dirty="false"
  if ! git -C "$ROOT_DIR" diff --quiet || ! git -C "$ROOT_DIR" diff --cached --quiet; then
    dirty="true"
  fi

  python3 - "$META_JSON" "$ROOT_DIR" "$WORKTREE" "$APP_REL" "$REF" "$ARTIFACT_DIR_REL" "$OUT_REL" "$BUILD_FILE" "$EDITED_SOURCE_REL" "$dirty" "$PHASE_TIMERS" "$MACHINE_STATE" <<'PY'
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
from datetime import datetime, timezone

out, root, benchmark_root, app_rel, ref, artifact_dir, out_rel, build_file, edited_source, dirty, phase_timers, machine_state = sys.argv[1:13]

def run(cmd):
    try:
        return subprocess.check_output(cmd, cwd=root, stderr=subprocess.STDOUT, text=True).strip()
    except Exception as exc:
        return f"<unavailable: {exc}>"

def run_benchmark(cmd):
    try:
        return subprocess.check_output(cmd, cwd=benchmark_root, stderr=subprocess.STDOUT, text=True).strip()
    except Exception as exc:
        return f"<unavailable: {exc}>"

def input_digests():
    benchmark = Path(benchmark_root)
    candidates = [benchmark / ".haxerc", benchmark / "package-lock.json", benchmark / app_rel / "mix.lock"]
    candidates.extend(sorted((benchmark / "haxe_libraries").glob("*.hxml")))
    candidates.extend(sorted((benchmark / app_rel).rglob("*.hxml")))
    digests = {}
    for path in candidates:
        if path.is_file():
            digests[str(path.relative_to(benchmark))] = hashlib.sha256(path.read_bytes()).hexdigest()
    combined = hashlib.sha256()
    for path, digest in sorted(digests.items()):
        combined.update(path.encode("utf-8"))
        combined.update(b"\0")
        combined.update(digest.encode("ascii"))
        combined.update(b"\n")
    return {"combined_sha256": combined.hexdigest(), "files": digests}

meta = {
    "schema_version": 2,
    "schema_classification": "current",
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "repo": {
        "harness_head": run(["git", "rev-parse", "HEAD"]),
        "benchmark_head": run_benchmark(["git", "rev-parse", "HEAD"]),
        "ref": ref,
        "dirty": dirty == "true",
    },
    "config": {
        "app": app_rel,
        "artifact_dir": artifact_dir,
        "build_file": build_file,
        "edited_source": edited_source,
        "output": out_rel,
        "phase_timer_mode": phase_timers,
        "build_input_digests": input_digests(),
        "timeouts_seconds": {
            "deps_get": int(os.environ.get("DEPS_GET_TIMEOUT", "300")),
            "deps_compile": int(os.environ.get("DEPS_COMPILE_TIMEOUT", "420")),
            "haxe_build": int(os.environ.get("HAXE_BUILD_TIMEOUT", "300")),
            "mix_compile": int(os.environ.get("MIX_COMPILE_TIMEOUT", "300")),
        },
    },
    "environment": {
        "machine_state": machine_state,
        "machine_state_source": "explicit_benchmark_label",
        "cpu_count": os.cpu_count(),
        "load_average": list(os.getloadavg()) if hasattr(os, "getloadavg") else None,
        "os": platform.platform(),
        "uname": run(["uname", "-a"]),
        "haxe": run([os.environ.get("HAXE_BIN", "haxe"), "-version"]),
        "elixir": run(["elixir", "--version"]),
        "mix": run(["mix", "--version"]),
        "otp_release": run(["erl", "-noshell", "-eval", "io:format(\"~s\", [erlang:system_info(otp_release)]), halt()."]),
    },
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(meta, f, indent=2, sort_keys=True)
    f.write("\n")
PY
}

record_phase() {
  local run_name="$1"; shift
  local phase_name="$1"; shift
  local status="$1"; shift
  local exit_code="$1"; shift
  local duration_ms="$1"; shift
  local log_rel="$1"; shift
  local timeout_secs="$1"; shift
  local command_text="$1"; shift
  local log_path="$ROOT_DIR/$log_rel"

  python3 - "$RESULTS_NDJSON" "$run_name" "$phase_name" "$status" "$exit_code" "$duration_ms" "$log_rel" "$timeout_secs" "$command_text" "$log_path" <<'PY'
import json
import sys

out, run_name, phase_name, status, exit_code, duration_ms, log_rel, timeout_secs, command_text, log_path = sys.argv[1:11]

tail = ""
try:
    with open(log_path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    tail = "".join(lines[-80:])
except FileNotFoundError:
    pass

entry = {
    "run": run_name,
    "phase": phase_name,
    "status": status,
    "exit_code": int(exit_code),
    "duration_ms": int(duration_ms),
    "timeout_seconds": int(timeout_secs),
    "command": command_text,
    "log": log_rel,
}
if status != "success":
    entry["log_tail"] = tail

with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(entry, sort_keys=True))
    f.write("\n")
PY
}

run_phase() {
  local run_name="$1"; shift
  local phase_name="$1"; shift
  local timeout_secs="$1"; shift
  local cwd="$1"; shift
  local log_rel="$ARTIFACT_DIR_REL/logs/${run_name}-${phase_name}.log"
  local log_path="$ROOT_DIR/$log_rel"
  local command_text="$*"

  log "$run_name/$phase_name (timeout=${timeout_secs}s)"
  local start end code duration status
  start="$(now_ms)"
  set +e
  "$TIMEOUT" --secs "$timeout_secs" --cwd "$cwd" -- "$@" >"$log_path" 2>&1
  code="$?"
  set -e
  end="$(now_ms)"
  duration="$((end - start))"
  status="success"
  if [[ "$code" -ne 0 ]]; then
    status="failure"
  fi
  record_phase "$run_name" "$phase_name" "$status" "$code" "$duration" "$log_rel" "$timeout_secs" "$command_text"
  if [[ "$code" -ne 0 ]]; then
    log "❌ $run_name/$phase_name failed after ${duration}ms (exit=$code)"
    tail -80 "$log_path" >&2 || true
    return "$code"
  fi
  log "✅ $run_name/$phase_name ${duration}ms"
}

record_marker_phase() {
  local run_name="$1"; shift
  local phase_name="$1"; shift
  local start="$1"; shift
  local command_text="$1"; shift
  local end duration log_rel
  end="$(now_ms)"
  duration="$((end - start))"
  log_rel="$ARTIFACT_DIR_REL/logs/${run_name}-${phase_name}.log"
  printf '%s\n' "$command_text" >"$ROOT_DIR/$log_rel"
  record_phase "$run_name" "$phase_name" "success" 0 "$duration" "$log_rel" 0 "$command_text"
  log "✅ $run_name/$phase_name ${duration}ms"
}

record_output_state() {
  local run_name="$1"
  local app_dir="$2"
  python3 - "$OUTPUT_STATES_NDJSON" "$run_name" "$app_dir/lib" "$ROOT_DIR/scripts/perf" <<'PY'
import json
from pathlib import Path
import sys

states_path, run_name, output_root_value, helper_dir = sys.argv[1:5]
output_root = Path(output_root_value)
sys.path.insert(0, helper_dir)
from benchmark_contract import generated_output_state

previous_digests = {}
try:
    previous_lines = Path(states_path).read_text(encoding="utf-8").splitlines()
    if previous_lines:
        previous_digests = json.loads(previous_lines[-1]).get("_file_digests", {})
except FileNotFoundError:
    pass

state, file_digests = generated_output_state(output_root, previous_digests)
state["run"] = run_name
state["_file_digests"] = file_digests
with Path(states_path).open("a", encoding="utf-8") as output:
    output.write(json.dumps(state, sort_keys=True) + "\n")
PY
}

finalize_json() {
  local overall_status="$1"
  python3 - "$META_JSON" "$RESULTS_NDJSON" "$OUTPUT_STATES_NDJSON" "$OUT_PATH" "$overall_status" "$ROOT_DIR/scripts/perf" <<'PY'
import collections
import json
from pathlib import Path
import re
import sys

meta_path, results_path, states_path, out_path, overall_status, helper_dir = sys.argv[1:7]
sys.path.insert(0, helper_dir)
from benchmark_contract import compile_scenario

root = Path(helper_dir).parents[1]

def target_timing_report(log_rel):
    prefix = "REFLAXE_ELIXIR_TIMINGS "
    try:
        lines = (root / log_rel).read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return None
    reports = []
    for line in lines:
        marker = line.find(prefix)
        if marker >= 0:
            try:
                reports.append(json.loads(line[marker + len(prefix):]))
            except json.JSONDecodeError:
                continue
    return reports[-1] if reports else None

def haxe_reported_total_ms(log_rel):
    pattern = re.compile(r"^total\s+\|\s*([0-9]+(?:\.[0-9]+)?)\s*\|", re.IGNORECASE)
    try:
        lines = (root / log_rel).read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return None
    matches = []
    for line in lines:
        match = pattern.match(line.strip())
        if match:
            matches.append(float(match.group(1)) * 1000.0)
    return matches[-1] if matches else None

def mix_recompiled_modules(log_rel):
    pattern = re.compile(r"Compiling\s+([0-9]+)\s+files?\s+\(\.ex\)")
    try:
        text = (root / log_rel).read_text(encoding="utf-8", errors="replace")
    except FileNotFoundError:
        return None
    matches = [int(value) for value in pattern.findall(text)]
    return sum(matches) if matches else 0

with open(meta_path, "r", encoding="utf-8") as f:
    data = json.load(f)

runs = collections.OrderedDict()
try:
    with open(results_path, "r", encoding="utf-8") as f:
        for line in f:
            if not line.strip():
                continue
            phase = json.loads(line)
            run_name = phase.pop("run")
            run = runs.setdefault(run_name, {
                "name": run_name,
                "status": "success",
                "duration_ms": 0,
                "phases": [],
                **compile_scenario(run_name),
            })
            if phase["status"] != "success":
                run["status"] = "failure"
            run["duration_ms"] += phase["duration_ms"]
            if phase["phase"] == "haxe_build":
                timing = target_timing_report(phase["log"])
                haxe_total = haxe_reported_total_ms(phase["log"])
                if haxe_total is not None:
                    phase["haxe_reported_total_ms"] = haxe_total
                    run["haxe_reported_total_ms"] = haxe_total
                if timing is not None:
                    phase["reflaxe_target_timing"] = timing
                    run["reflaxe_target_timing"] = timing
                    target_wall = timing.get("total_wall_ms")
                    if isinstance(target_wall, (int, float)):
                        known = target_wall + (haxe_total if haxe_total is not None else 0.0)
                        unattributed = phase["duration_ms"] - known
                        run["phase_reconciliation"] = {
                            "external_haxe_build_ms": phase["duration_ms"],
                            "haxe_reported_total_ms": haxe_total,
                            "reflaxe_target_total_ms": target_wall,
                            "unattributed_process_and_measurement_ms": round(unattributed, 3),
                            "reconciled_total_ms": round(known + unattributed, 3),
                        }
            if phase["phase"] == "mix_compile":
                run["mix_recompiled_module_count"] = mix_recompiled_modules(phase["log"])
            run["phases"].append(phase)
except FileNotFoundError:
    pass

try:
    with open(states_path, "r", encoding="utf-8") as f:
        for line in f:
            if not line.strip():
                continue
            state = json.loads(line)
            run_name = state.pop("run")
            state.pop("_file_digests", None)
            if run_name in runs:
                runs[run_name]["generated_output"] = state
except FileNotFoundError:
    pass

data["runs"] = list(runs.values())
data["status"] = (
    "failure"
    if overall_status != "success" or any(run["status"] != "success" for run in data["runs"])
    else "success"
)

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=True)
    f.write("\n")
PY
  log "Wrote $OUT_REL"
}

prepare_worktree() {
  if [[ -e "$WORKTREE/.git" ]]; then
    git -C "$ROOT_DIR" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || true
  else
    rm -rf "$WORKTREE"
  fi
  git -C "$ROOT_DIR" worktree prune >/dev/null 2>&1 || true
  log "Creating isolated worktree at $ARTIFACT_DIR_REL/worktree (ref=$REF)"
  git -C "$ROOT_DIR" worktree add --detach "$WORKTREE" "$REF" >/dev/null
}

clean_cold_outputs() {
  local app_dir="$1"
  local start
  start="$(now_ms)"
  rm -rf "$app_dir/_build" "$app_dir/deps"
  python3 - "$app_dir/lib/_GeneratedFiles.json" <<'PY'
import json
import os
import sys

manifest = sys.argv[1]
lib_dir = os.path.dirname(manifest)
try:
    with open(manifest, "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    data = {}

for rel_path in data.get("filesGenerated", []):
    path = os.path.normpath(os.path.join(lib_dir, rel_path))
    if not path.startswith(lib_dir + os.sep):
        raise SystemExit(f"refusing generated path outside lib/: {rel_path}")
    try:
        os.remove(path)
    except FileNotFoundError:
        pass

try:
    os.remove(manifest)
except FileNotFoundError:
    pass
PY
  record_marker_phase "cold" "clean" "$start" "rm -rf _build deps && remove lib/_GeneratedFiles.json entries"
}

apply_edited_source_variant() {
  local app_dir="$1"
  local source_rel="$EDITED_SOURCE_REL"
  local source_path="$app_dir/$source_rel"
  if [[ ! -f "$source_path" ]]; then
    echo "[bench] ERROR: edited source not found: $source_rel" >&2
    return 2
  fi
  local start
  start="$(now_ms)"
  python3 "$ROOT_DIR/scripts/perf/benchmark_contract.py" apply-source-variant --path "$source_path" --variant B
  record_marker_phase "edited_full_fresh_process" "apply_source_variant_b" "$start" "apply deterministic source variant B to $source_rel"
}

run_compile_sequence() {
  local run_name="$1"; shift
  local app_dir="$1"; shift
  local include_deps="$1"; shift

  if [[ "$include_deps" -eq 1 ]]; then
    run_phase "$run_name" "deps_get" "$DEPS_GET_TIMEOUT" "$app_dir" env HAXE_NO_SERVER=1 MIX_ENV=test mix deps.get || return $?
    run_phase "$run_name" "deps_compile" "$DEPS_COMPILE_TIMEOUT" "$app_dir" env HAXE_NO_SERVER=1 MIX_ENV=test mix deps.compile || return $?
  fi

  local -a haxe_args=("$BUILD_FILE")
  if [[ "$PHASE_TIMERS" == "coarse" ]]; then
    haxe_args+=("--times")
    run_phase "$run_name" "haxe_build" "$HAXE_BUILD_TIMEOUT" "$app_dir" env HAXE_NO_SERVER=1 HAXELIB_PATH="$WORKTREE/haxe_libraries" REFLAXE_ELIXIR_TIMINGS=1 "$HAXE_BIN" "${haxe_args[@]}" || return $?
  else
    run_phase "$run_name" "haxe_build" "$HAXE_BUILD_TIMEOUT" "$app_dir" env HAXE_NO_SERVER=1 HAXELIB_PATH="$WORKTREE/haxe_libraries" "$HAXE_BIN" "${haxe_args[@]}" || return $?
  fi
  run_phase "$run_name" "mix_compile" "$MIX_COMPILE_TIMEOUT" "$app_dir" env HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 MIX_ENV=test mix compile --warnings-as-errors --no-deps-check || return $?
}

main() {
  prepare_worktree
  write_meta

  local app_dir="$WORKTREE/$APP_REL"
  if [[ ! -d "$app_dir" ]]; then
    echo "[bench] ERROR: app not found in worktree: $APP_REL" >&2
    finalize_json "failure"
    exit 2
  fi
  if [[ ! -f "$app_dir/$BUILD_FILE" ]]; then
    echo "[bench] ERROR: build file not found in app: $BUILD_FILE" >&2
    finalize_json "failure"
    exit 2
  fi

  local status="success"
  if ! clean_cold_outputs "$app_dir"; then
    status="failure"
  elif ! run_compile_sequence "cold" "$app_dir" 1; then
    status="failure"
  elif ! record_output_state "cold" "$app_dir"; then
    status="failure"
  elif ! run_compile_sequence "warm_fresh_process" "$app_dir" 0; then
    status="failure"
  elif ! record_output_state "warm_fresh_process" "$app_dir"; then
    status="failure"
  elif ! apply_edited_source_variant "$app_dir"; then
    status="failure"
  elif ! run_compile_sequence "edited_full_fresh_process" "$app_dir" 0; then
    status="failure"
  elif ! record_output_state "edited_full_fresh_process" "$app_dir"; then
    status="failure"
  fi

  finalize_json "$status"
  [[ "$status" == "success" ]]
}

main "$@"

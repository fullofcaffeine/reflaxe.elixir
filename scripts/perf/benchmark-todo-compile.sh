#!/usr/bin/env bash
set -euo pipefail

# Bounded todo-app compile benchmark.
#
# Produces a JSON artifact with cold, warm, and incremental compile timings.
# Runs in an isolated git worktree by default so cold cleanup can remove deps,
# _build, and generated lib outputs without mutating the caller's workspace.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"

APP_REL="examples/todo-app"
REF="HEAD"
ARTIFACT_DIR_REL="tmp/perf/todo-compile"
OUT_REL="tmp/perf/compile-times.json"
HAXE_BIN="${HAXE_BIN:-haxe}"

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

mkdir -p "$ARTIFACT_DIR" "$LOG_DIR" "$(dirname "$OUT_PATH")"
rm -f "$RESULTS_NDJSON" "$META_JSON"

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

  python3 - "$META_JSON" "$ROOT_DIR" "$APP_REL" "$REF" "$ARTIFACT_DIR_REL" "$OUT_REL" "$dirty" <<'PY'
import json
import os
import platform
import subprocess
import sys
from datetime import datetime, timezone

out, root, app_rel, ref, artifact_dir, out_rel, dirty = sys.argv[1:8]

def run(cmd):
    try:
        return subprocess.check_output(cmd, cwd=root, stderr=subprocess.STDOUT, text=True).strip()
    except Exception as exc:
        return f"<unavailable: {exc}>"

meta = {
    "schema_version": 1,
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "repo": {
        "head": run(["git", "rev-parse", "HEAD"]),
        "ref": ref,
        "dirty": dirty == "true",
    },
    "config": {
        "app": app_rel,
        "artifact_dir": artifact_dir,
        "output": out_rel,
        "timeouts_seconds": {
            "deps_get": int(os.environ.get("DEPS_GET_TIMEOUT", "300")),
            "deps_compile": int(os.environ.get("DEPS_COMPILE_TIMEOUT", "420")),
            "haxe_build": int(os.environ.get("HAXE_BUILD_TIMEOUT", "300")),
            "mix_compile": int(os.environ.get("MIX_COMPILE_TIMEOUT", "300")),
        },
    },
    "environment": {
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

finalize_json() {
  local overall_status="$1"
  python3 - "$META_JSON" "$RESULTS_NDJSON" "$OUT_PATH" "$overall_status" <<'PY'
import collections
import json
import sys

meta_path, results_path, out_path, overall_status = sys.argv[1:5]
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
            run = runs.setdefault(run_name, {"name": run_name, "status": "success", "duration_ms": 0, "phases": []})
            if phase["status"] != "success":
                run["status"] = "failure"
            run["duration_ms"] += phase["duration_ms"]
            run["phases"].append(phase)
except FileNotFoundError:
    pass

data["status"] = overall_status
data["runs"] = list(runs.values())

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

touch_incremental_source() {
  local app_dir="$1"
  local source_rel="src_haxe/shared/TodoTypes.hx"
  local source_path="$app_dir/$source_rel"
  if [[ ! -f "$source_path" ]]; then
    echo "[bench] ERROR: incremental source not found: $source_rel" >&2
    return 2
  fi
  local start
  start="$(now_ms)"
  python3 - "$source_path" <<'PY'
import os
import sys
path = sys.argv[1]
now = None
os.utime(path, times=now)
PY
  record_marker_phase "incremental" "touch_source" "$start" "touch $source_rel"
}

run_compile_sequence() {
  local run_name="$1"; shift
  local app_dir="$1"; shift
  local include_deps="$1"; shift

  if [[ "$include_deps" -eq 1 ]]; then
    run_phase "$run_name" "deps_get" "$DEPS_GET_TIMEOUT" "$app_dir" env HAXE_NO_SERVER=1 MIX_ENV=test mix deps.get
    run_phase "$run_name" "deps_compile" "$DEPS_COMPILE_TIMEOUT" "$app_dir" env HAXE_NO_SERVER=1 MIX_ENV=test mix deps.compile
  fi

  run_phase "$run_name" "haxe_build" "$HAXE_BUILD_TIMEOUT" "$app_dir" "$HAXE_BIN" build-server.hxml
  run_phase "$run_name" "mix_compile" "$MIX_COMPILE_TIMEOUT" "$app_dir" env HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 MIX_ENV=test mix compile --warnings-as-errors --no-deps-check
}

main() {
  write_meta
  prepare_worktree

  local app_dir="$WORKTREE/$APP_REL"
  if [[ ! -d "$app_dir" ]]; then
    echo "[bench] ERROR: app not found in worktree: $APP_REL" >&2
    finalize_json "failure"
    exit 2
  fi

  local status="success"
  if ! clean_cold_outputs "$app_dir"; then
    status="failure"
  elif ! run_compile_sequence "cold" "$app_dir" 1; then
    status="failure"
  elif ! run_compile_sequence "warm" "$app_dir" 0; then
    status="failure"
  elif ! touch_incremental_source "$app_dir"; then
    status="failure"
  elif ! run_compile_sequence "incremental" "$app_dir" 0; then
    status="failure"
  fi

  finalize_json "$status"
  [[ "$status" == "success" ]]
}

main "$@"

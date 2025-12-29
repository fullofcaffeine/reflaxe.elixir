#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# Dogfood: Generator + Phoenix upgrade path
#
# WHAT
# - Creates a fresh Phoenix project via `reflaxe.elixir create --type phoenix`,
#   boots it through the QA sentinel, then upgrades reflaxe.elixir across tags
#   and validates again.
#
# WHY
# - Production readiness requires at least one "external" Phoenix app workflow
#   that exercises the documented install + upgrade story end-to-end.
#
# HOW
# - Uses a temporary workspace under $TMPDIR.
# - Runs the repo QA sentinel with `--hxml build.hxml` (generated apps use build.hxml).
# - Uses async sentinel runs with bounded log follow and explicit DONE status checks.
# ----------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
SENTINEL="$ROOT_DIR/scripts/qa-sentinel.sh"
LOGPEEK="$ROOT_DIR/scripts/qa-logpeek.sh"

if [[ ! -x "$TIMEOUT" ]]; then
  echo "[dogfood] ERROR: missing timeout wrapper: $TIMEOUT" >&2
  exit 2
fi

APP_NAME="dogfood_phoenix"
KEEP_DIR=0
PORT=4011
VERBOSE=1
MODE="local"

TO_TAG="v$(node -p "require('${ROOT_DIR}/package.json').version")"
FROM_TAG="v1.0.7"

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --mode local|github  Install/upgrade mode (default: ${MODE})
  --from-tag vX.Y.Z   Starting tag to generate/validate (default: ${FROM_TAG})
  --to-tag vX.Y.Z     Upgrade target tag (default: ${TO_TAG})
  --name NAME         Project directory name (default: ${APP_NAME})
  --port N            Sentinel port (default: ${PORT})
  --keep-dir          Keep the temp workspace (prints path)
  --quiet             Less verbose output
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --from-tag) FROM_TAG="$2"; shift 2 ;;
    --to-tag) TO_TAG="$2"; shift 2 ;;
    --name) APP_NAME="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --keep-dir) KEEP_DIR=1; shift 1 ;;
    --quiet) VERBOSE=0; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[dogfood] Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

normalize_tag() {
  local tag="$1"
  if [[ "$tag" =~ ^[0-9]+\\.[0-9]+\\.[0-9]+$ ]]; then
    echo "v$tag"
  else
    echo "$tag"
  fi
}

FROM_TAG="$(normalize_tag "$FROM_TAG")"
TO_TAG="$(normalize_tag "$TO_TAG")"

if [[ "$MODE" != "local" && "$MODE" != "github" ]]; then
  echo "[dogfood] Unknown --mode: $MODE (expected: local|github)" >&2
  exit 2
fi

log() {
  if [[ "${VERBOSE:-0}" -eq 1 ]]; then
    echo "$@"
  fi
}

run_step() {
  local desc="$1"; shift
  local secs="$1"; shift
  local cwd="$1"; shift
  log ""
  log "[dogfood] ${desc}"
  "$TIMEOUT" --secs "$secs" --cwd "$cwd" -- bash -lc "$*"
}

update_mix_exs_tag() {
  local cwd="$1"; shift
  local to_tag="$1"; shift

  run_step "update mix.exs tag to ${to_tag}" 30 "$cwd" \
    "python3 -c 'import re,sys; p=\"mix.exs\"; to=sys.argv[1]; t=open(p,\"r\",encoding=\"utf-8\").read(); n=re.sub(r\"tag: \\\"v\\\\d+\\\\.\\\\d+\\\\.\\\\d+\\\"\", \"tag: \\\"%s\\\"\" % to, t, count=1);  (n!=t) or sys.exit(\"No reflaxe_elixir tag found to update in mix.exs\"); open(p,\"w\",encoding=\"utf-8\").write(n)' \"$to_tag\""
}

update_mix_exs_path() {
  local cwd="$1"; shift
  local repo_path="$1"; shift

  run_step "update mix.exs dep to path: ${repo_path}" 30 "$cwd" \
    "python3 -c 'import re,sys; p=\"mix.exs\"; repo=sys.argv[1]; t=open(p,\"r\",encoding=\"utf-8\").read(); pat=r\"\\{:reflaxe_elixir,[^}]*runtime:\\s*false[^}]*\\}\"; rep=\"{:reflaxe_elixir, path: \\\"%s\\\", runtime: false}\" % repo; n=re.sub(pat, rep, t, count=1, flags=re.S);  (n!=t) or sys.exit(\"No reflaxe_elixir dependency found to rewrite in mix.exs\"); open(p,\"w\",encoding=\"utf-8\").write(n)' \"$repo_path\""
}

extract_library_tag() {
  local tag="$1"; shift
  local dest="$1"; shift

  mkdir -p "$dest"
  run_step "extract reflaxe.elixir ${tag} (local)" 120 "$ROOT_DIR" "git archive '${tag}' | tar -x -C '${dest}'"
  if [[ ! -f "$dest/mix.exs" || ! -f "$dest/haxelib.json" ]]; then
    echo "[dogfood] ERROR: extracted ${tag} missing expected files (mix.exs/haxelib.json)" >&2
    ls -la "$dest" >&2 || true
    exit 1
  fi

  # Historical tags carried an `extraParams.hxml` that included relative classpaths
  # (`-cp src`, `-cp std`). When installed via `lix dev`, those resolve relative to
  # the *consumer project* and break compilation. Patch them in the temp extract
  # to use absolute paths so we can validate upgrade flows locally.
  if [[ -f "$dest/extraParams.hxml" ]]; then
    run_step "patch extraParams.hxml classpaths (local, ${tag})" 30 "$dest" \
      "python3 -c 'import pathlib,re; root=pathlib.Path(\".\").resolve(); p=root/\"extraParams.hxml\"; t=p.read_text(encoding=\"utf-8\"); t=re.sub(r\"(?m)^-cp\\s+src\\s*$\", \"-cp %s\" % (root/\"src\"), t); t=re.sub(r\"(?m)^-cp\\s+std\\s*$\", \"-cp %s\" % (root/\"std\"), t); p.write_text(t, encoding=\"utf-8\")'"
  fi
}

ensure_phx_new() {
  if mix help phx.new >/dev/null 2>&1; then
    return 0
  fi
  echo "[dogfood] Installing Phoenix generator (phx_new)..." >&2
  run_step "mix archive.install hex phx_new --force" 300 "$ROOT_DIR" "mix archive.install hex phx_new --force"
}

sentinel_run() {
  local app_dir="$1"; shift
  local hxml_file="$1"; shift
  local label="$1"; shift

  log ""
  log "[dogfood] QA sentinel: ${label}"

  local out
  out="$("$SENTINEL" --app "$app_dir" --hxml "$hxml_file" --env dev --port "$PORT" --async --deadline 900 --verbose)"
  echo "$out"

  local run_id
  run_id="$(echo "$out" | awk -F= '/^QA_SENTINEL_RUN_ID=/{print $2}' | tail -n 1)"
  local logfile
  logfile="$(echo "$out" | awk -F= '/^QA_SENTINEL_LOG=/{print $2}' | tail -n 1)"

  if [[ -z "$run_id" || -z "$logfile" ]]; then
    echo "[dogfood] ERROR: failed to parse QA sentinel run metadata" >&2
    exit 1
  fi

  "$LOGPEEK" --run-id "$run_id" --until-done 900 >/dev/null 2>&1 || true

  local status
  status="$(grep -Eo "\\[QA\\] DONE status=[0-9]+" "$logfile" | tail -n 1 | sed -E 's/.*status=//')"
  if [[ -z "$status" ]]; then
    echo "[dogfood] ERROR: sentinel did not emit DONE status (log: $logfile)" >&2
    tail -n 120 "$logfile" >&2 || true
    exit 1
  fi
  if [[ "$status" != "0" ]]; then
    echo "[dogfood] ERROR: sentinel failed (status=$status, log: $logfile)" >&2
    tail -n 200 "$logfile" >&2 || true
    exit 1
  fi

  log "[dogfood] ✅ sentinel OK (${label})"
}

tmp_base="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-dogfood.XXXXXX")"
work_dir="$tmp_base/work"
mkdir -p "$work_dir"

cleanup() {
  if [[ "${KEEP_DIR:-0}" -eq 1 ]]; then
    echo "[dogfood] Kept workspace: $tmp_base" >&2
    return 0
  fi
  rm -rf "$tmp_base" 2>/dev/null || true
}
trap cleanup EXIT

echo "[dogfood] Workspace: $tmp_base"
echo "[dogfood] Mode: ${MODE}"
echo "[dogfood] Upgrade: ${FROM_TAG} -> ${TO_TAG}"

ensure_phx_new

# Local mode: extract the FROM_TAG library sources so Mix/Lix can use a path dep without GitHub access.
from_src="$tmp_base/reflaxe_elixir_from"
to_src="$ROOT_DIR"
if [[ "$MODE" == "local" ]]; then
  extract_library_tag "$FROM_TAG" "$from_src"
fi

# 1) Create a local lix scope used to run the generator.
run_step "npm init (workspace)" 60 "$work_dir" "npm init -y >/dev/null"
run_step "npm install lix (workspace)" 300 "$work_dir" "npm install --save-dev lix@^15.12.4 --no-audit --no-fund"
run_step "lix scope create (workspace)" 30 "$work_dir" "npx lix scope create"

# 2) Install reflaxe.elixir (from-tag) and generate a Phoenix project.
#
# - github mode: install via lix and run the library as a normal consumer would.
# - local mode: compile + run the CLI entrypoint from the extracted tag source (no GitHub access required).
if [[ "$MODE" == "github" ]]; then
  run_step "lix install reflaxe.elixir (${FROM_TAG})" 600 "$work_dir" "npx lix install github:fullofcaffeine/reflaxe.elixir#${FROM_TAG}"
  run_step "generate phoenix project (${FROM_TAG})" 600 "$work_dir" "npx lix run reflaxe.elixir create ${APP_NAME} --type phoenix --no-interactive --skip-install --verbose"
else
  run_step "lix install generator deps (reflaxe)" 300 "$work_dir" "npx lix install haxelib:reflaxe"
  run_step "lix install generator deps (tink_macro)" 300 "$work_dir" "npx lix install haxelib:tink_macro"
  run_step "lix install generator deps (tink_parse)" 300 "$work_dir" "npx lix install haxelib:tink_parse"
  run_step "lix download (workspace, generator deps)" 600 "$work_dir" "npx lix download"
  # Note: historical tags may not compile under newer Haxe strictness. In local mode,
  # always scaffold using the target (to-tag) generator, then validate upgrading the
  # app's Mix + Haxe deps across FROM_TAG -> TO_TAG.
  run_step "generate phoenix project (${TO_TAG} generator, local)" 900 "$work_dir" "haxe -cp '${to_src}/src' -lib reflaxe -lib tink_macro -lib tink_parse --run Run create ${APP_NAME} --type phoenix --no-interactive --skip-install --verbose"
fi

app_dir="$work_dir/$APP_NAME"
if [[ ! -f "$app_dir/mix.exs" || ! -f "$app_dir/build.hxml" ]]; then
  echo "[dogfood] ERROR: generated project missing expected files (mix.exs/build.hxml)" >&2
  ls -la "$app_dir" >&2 || true
  exit 1
fi

# 3) Install JS deps + Haxe libs in the generated project.
run_step "npm install (project)" 600 "$app_dir" "npm install --no-audit --no-fund"
run_step "lix scope create (project)" 30 "$app_dir" "npx lix scope create"

if [[ "$MODE" == "local" ]]; then
  # `lix dev` does not reliably pull transitive haxelib deps; install the
  # compiler/runtime deps explicitly so `-lib reflaxe.elixir` can resolve them.
  run_step "lix dev haxe deps (reflaxe, vendored)" 60 "$app_dir" "npx lix dev reflaxe '${from_src}/vendor/reflaxe'"
  run_step "lix install haxe deps (tink_macro)" 300 "$app_dir" "npx lix install haxelib:tink_macro"
  run_step "lix install haxe deps (tink_parse)" 300 "$app_dir" "npx lix install haxelib:tink_parse"

  update_mix_exs_path "$app_dir" "$from_src"
  run_step "verify mix.exs uses path dep (baseline, local)" 10 "$app_dir" "if rg -q 'github: \"fullofcaffeine/reflaxe.elixir\"' mix.exs; then echo '[dogfood] ERROR: mix.exs still uses github dep'; rg -n 'reflaxe_elixir' mix.exs; exit 1; fi"
  run_step "lix dev reflaxe.elixir (${FROM_TAG}) (project, local)" 60 "$app_dir" "npx lix dev reflaxe.elixir '${from_src}'"
else
  run_step "lix install reflaxe.elixir (${FROM_TAG}) (project)" 600 "$app_dir" "npx lix install github:fullofcaffeine/reflaxe.elixir#${FROM_TAG}"
fi
run_step "lix download (project)" 900 "$app_dir" "npx lix download"
# Avoid starting the Haxe compilation server during DB setup; the sentinel will
# run a clean, bounded compile later.
run_step "mix deps.get (project)" 900 "$app_dir" "HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix deps.get"
run_step "mix ecto.create (project)" 300 "$app_dir" "HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix ecto.create --quiet || true"
run_step "mix ecto.migrate (project)" 300 "$app_dir" "HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix ecto.migrate"

# 4) Validate boot + compile via QA sentinel.
sentinel_run "$app_dir" "build.hxml" "baseline (${FROM_TAG})"

# 5) Upgrade: update lix + mix dependency tag, then validate again.
if [[ "$MODE" == "local" ]]; then
  update_mix_exs_path "$app_dir" "$to_src"
  run_step "verify mix.exs uses path dep (upgrade, local)" 10 "$app_dir" "if rg -q 'github: \"fullofcaffeine/reflaxe.elixir\"' mix.exs; then echo '[dogfood] ERROR: mix.exs still uses github dep'; rg -n 'reflaxe_elixir' mix.exs; exit 1; fi"
  run_step "lix dev haxe deps (reflaxe, upgraded vendored)" 60 "$app_dir" "npx lix dev reflaxe '${to_src}/vendor/reflaxe'"
  run_step "lix dev reflaxe.elixir (${TO_TAG}) (project, local)" 60 "$app_dir" "npx lix dev reflaxe.elixir '${to_src}'"
  run_step "lix download (project, upgraded)" 900 "$app_dir" "npx lix download"
  run_step "mix deps.clean reflaxe_elixir (project)" 300 "$app_dir" "HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix deps.clean reflaxe_elixir"
  run_step "mix deps.get (project, upgraded)" 900 "$app_dir" "HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix deps.get"
  run_step "mix ecto.create (project, upgraded)" 300 "$app_dir" "HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix ecto.create --quiet || true"
  run_step "mix ecto.migrate (project, upgraded)" 300 "$app_dir" "HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix ecto.migrate"
else
  run_step "lix install reflaxe.elixir (${TO_TAG}) (project)" 600 "$app_dir" "npx lix install github:fullofcaffeine/reflaxe.elixir#${TO_TAG}"
  run_step "lix download (project, upgraded)" 900 "$app_dir" "npx lix download"
  update_mix_exs_tag "$app_dir" "$TO_TAG"
  run_step "mix deps.update reflaxe_elixir (project)" 900 "$app_dir" "HAXE_NO_COMPILE=1 HAXE_NO_SERVER=1 mix deps.update reflaxe_elixir"
fi

sentinel_run "$app_dir" "build.hxml" "upgraded (${TO_TAG})"

echo "[dogfood] ✅ Dogfood complete: ${FROM_TAG} -> ${TO_TAG}"

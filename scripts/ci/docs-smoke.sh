#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# Docs Smoke (Phoenix)
#
# WHAT
# - Generates a Phoenix project via `reflaxe.elixir create --type phoenix`,
#   installs deps and compiles (including the Haxe compiler step).
#
# WHY
# - Ensures README/docs "new user" commands stay runnable and don't drift.
#
# HOW
# - Uses a temporary workspace under $TMPDIR (auto-cleaned).
# - Uses `scripts/with-timeout.sh` for every potentially slow step.
# - Does not start any foreground servers; compile-only.
# ----------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"

APP_NAME="docs_smoke_phoenix"
PORT="${PORT:-4021}"
KEEP_DIR=0
VERBOSE=0

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --name NAME       App directory name (default: ${APP_NAME})
  --port N          Reserved port (not used; kept for parity) (default: ${PORT})
  --keep-dir        Keep temp workspace (prints path)
  --verbose         Verbose generator output
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) APP_NAME="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --keep-dir) KEEP_DIR=1; shift 1 ;;
    --verbose) VERBOSE=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[docs-smoke] Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ ! -x "$TIMEOUT" ]]; then
  echo "[docs-smoke] ERROR: missing timeout wrapper: $TIMEOUT" >&2
  exit 2
fi

run_step() {
  local desc="$1"; shift
  local secs="$1"; shift
  local cwd="$1"; shift
  echo ""
  echo "[docs-smoke] ${desc}"
  "$TIMEOUT" --secs "$secs" --cwd "$cwd" -- bash -lc "$*"
}

tmp_base="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-docs-smoke.XXXXXX")"
work_dir="$tmp_base/work"
mkdir -p "$work_dir"

cleanup() {
  if [[ "${KEEP_DIR:-0}" -eq 1 ]]; then
    echo "[docs-smoke] Kept workspace: $tmp_base" >&2
    return 0
  fi
  rm -rf "$tmp_base" 2>/dev/null || true
}
trap cleanup EXIT

echo "[docs-smoke] Workspace: $tmp_base"

# Ensure Mix tooling is available in clean environments.
run_step "mix local.hex --force" 120 "$ROOT_DIR" "mix local.hex --force"
run_step "mix local.rebar --force" 120 "$ROOT_DIR" "mix local.rebar --force"
run_step "mix archive.install hex phx_new --force" 300 "$ROOT_DIR" "mix archive.install hex phx_new --force"

# Ensure the Haxe toolchain + generator deps are present in clean environments.
# (CI runs this already, but keep it self-contained for local runs.)
run_step "lix download (repo scope)" 600 "$ROOT_DIR" "npx lix download"

# Generate a Phoenix project (skip installs so we can control + bound the steps).
generator_flags="--type phoenix --no-interactive --skip-install"
if [[ "${VERBOSE:-0}" -eq 1 ]]; then
  generator_flags="${generator_flags} --verbose"
fi
run_step "generate phoenix project" 900 "$ROOT_DIR" \
  "haxe -cp '${ROOT_DIR}/src' -lib reflaxe -lib tink_macro -lib tink_parse --run Run create '${APP_NAME}' ${generator_flags} '${work_dir}'"

app_dir="$work_dir/$APP_NAME"
if [[ ! -f "$app_dir/mix.exs" || ! -f "$app_dir/build.hxml" ]]; then
  echo "[docs-smoke] ERROR: generated project missing expected files (mix.exs/build.hxml)" >&2
  ls -la "$app_dir" >&2 || true
  exit 1
fi

# Install JS deps + set up a lix scope (using local compiler sources for this CI run).
run_step "npm install (project)" 600 "$app_dir" "npm install --no-audit --no-fund"
run_step "lix scope create (project)" 60 "$app_dir" "npx lix scope create"
run_step "lix dev reflaxe.elixir (project)" 60 "$app_dir" "npx lix dev reflaxe.elixir '${ROOT_DIR}'"
run_step "lix install haxe deps (tink_macro)" 300 "$app_dir" "npx lix install haxelib:tink_macro"
run_step "lix install haxe deps (tink_parse)" 300 "$app_dir" "npx lix install haxelib:tink_parse"
run_step "lix download (project)" 600 "$app_dir" "npx lix download"

# Use the local repo as the Mix dependency too (avoids needing a published tag during CI).
run_step "rewrite mix.exs reflaxe_elixir dep to path" 60 "$app_dir" \
  "python3 -c 'import re,sys; p=\"mix.exs\"; repo=sys.argv[1]; t=open(p,\"r\",encoding=\"utf-8\").read(); pat=r\"\\{:reflaxe_elixir,[^}]*runtime:\\s*false[^}]*\\}\"; rep=\"{:reflaxe_elixir, path: \\\"%s\\\", runtime: false}\" % repo; n=re.sub(pat, rep, t, count=1, flags=re.S);  (n!=t) or sys.exit(\"No reflaxe_elixir dependency found to rewrite in mix.exs\"); open(p,\"w\",encoding=\"utf-8\").write(n)' '${ROOT_DIR}'"

# Compile-only smoke (no servers). DB boot/runtime is covered by the QA sentinel / dogfood lanes.
run_step "mix deps.get" 600 "$app_dir" "mix deps.get"
run_step "mix compile" 900 "$app_dir" "mix compile"

echo ""
echo "[docs-smoke] ✅ OK"

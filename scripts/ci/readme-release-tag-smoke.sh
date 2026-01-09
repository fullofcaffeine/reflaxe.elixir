#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# README Release-Tag Smoke (Phoenix)
#
# WHAT
# - Validates the "install from GitHub release tag" path stays working by:
#   1) creating a fresh npm+lix workspace,
#   2) installing reflaxe.elixir from the latest GitHub Release tag,
#   3) generating a Phoenix project via `reflaxe.elixir create --type phoenix`,
#   4) compiling the generated project (compile-only; no servers).
#
# WHY
# - Docs smoke uses `lix dev` (local checkout) and is intentionally stable for PR CI.
#   This scheduled smoke validates that published Releases remain usable for new users.
#
# HOW
# - Uses a temp workspace under $TMPDIR (auto-cleaned).
# - Wraps all steps with scripts/with-timeout.sh.
# - Does not start any long-running processes (no `mix phx.server`).
# ----------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"

REPO="${REPO:-${GITHUB_REPOSITORY:-fullofcaffeine/reflaxe.elixir}}"
REF="${REF:-}"
HAXE_VERSION="${HAXE_VERSION:-4.3.7}"
APP_NAME="${APP_NAME:-hello_haxir}"
KEEP_DIR=0
VERBOSE=0

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --repo OWNER/REPO  GitHub repo (default: ${REPO})
  --ref REF          Git ref to install (tag/sha/branch). If omitted, uses latest GitHub Release tag.
  --haxe VERSION     Haxe version to pin via lix (default: ${HAXE_VERSION})
  --app NAME         Generated app directory name (default: ${APP_NAME})
  --keep-dir         Keep temp workspace (prints path)
  --verbose          Verbose generator output
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    --haxe) HAXE_VERSION="$2"; shift 2 ;;
    --app) APP_NAME="$2"; shift 2 ;;
    --keep-dir) KEEP_DIR=1; shift 1 ;;
    --verbose) VERBOSE=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[readme-release-smoke] Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ ! -x "$TIMEOUT" ]]; then
  echo "[readme-release-smoke] ERROR: missing timeout wrapper: $TIMEOUT" >&2
  exit 2
fi

run_step() {
  local desc="$1"; shift
  local secs="$1"; shift
  local cwd="$1"; shift
  echo ""
  echo "[readme-release-smoke] ${desc}"
  "$TIMEOUT" --secs "$secs" --cwd "$cwd" -- bash -lc "$*"
}

github_latest_tag() {
  local repo="$1"
  local api="https://api.github.com/repos/${repo}/releases/latest"
  local payload
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    payload="$(curl -fsSL \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$api")"
  else
    payload="$(curl -fsSL "$api")"
  fi

  local tag
  tag="$(python3 -c 'import json,sys; print((json.load(sys.stdin) or {}).get("tag_name",""))' <<<"$payload")"
  if [[ -z "$tag" ]]; then
    echo "[readme-release-smoke] ERROR: failed to discover latest release tag for ${repo}" >&2
    echo "[readme-release-smoke] Hint: set REPO=owner/name or ensure GITHUB_TOKEN is available." >&2
    return 1
  fi
  echo "$tag"
}

tmp_base="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-readme-release-smoke.XXXXXX")"
work_dir="$tmp_base/work"
mkdir -p "$work_dir"

cleanup() {
  if [[ "${KEEP_DIR:-0}" -eq 1 ]]; then
    echo "[readme-release-smoke] Kept workspace: $tmp_base" >&2
    return 0
  fi
  rm -rf "$tmp_base" 2>/dev/null || true
}
trap cleanup EXIT

echo "[readme-release-smoke] Workspace: $tmp_base"
echo "[readme-release-smoke] Repo: ${REPO}"
echo "[readme-release-smoke] Haxe: ${HAXE_VERSION}"

tag="$REF"
if [[ -z "$tag" ]]; then
  tag="$(github_latest_tag "$REPO")"
fi
echo "[readme-release-smoke] Ref: ${tag}"

# Step 0: Ensure Mix tooling is available (required because the generator uses phx_new).
run_step "mix local.hex --force" 120 "$work_dir" "mix local.hex --force"
run_step "mix local.rebar --force" 120 "$work_dir" "mix local.rebar --force"
run_step "mix archive.install hex phx_new --force" 300 "$work_dir" "mix archive.install hex phx_new --force"

# Step 1: New user workspace (npm + lix)
run_step "npm init -y" 60 "$work_dir" "npm init -y"
run_step "npm install --save-dev lix" 300 "$work_dir" "npm install --save-dev lix --no-audit --no-fund"
run_step "lix scope create" 60 "$work_dir" "npx lix scope create"

# Pin a known-good Haxe toolchain (avoid relying on global installs).
run_step "lix download haxe ${HAXE_VERSION}" 600 "$work_dir" "npx lix download haxe '${HAXE_VERSION}'"
run_step "lix use haxe ${HAXE_VERSION}" 60 "$work_dir" "npx lix use haxe '${HAXE_VERSION}'"
run_step "haxe --version (lix shim)" 60 "$work_dir" "./node_modules/.bin/haxe -version"

# Step 2: Install library from the latest release tag and download its pinned deps.
run_step "lix install reflaxe.elixir @ ${tag}" 300 "$work_dir" "npx lix install 'github:${REPO}#${tag}'"
run_step "lix download (workspace libs)" 600 "$work_dir" "npx lix download"

# Step 3: Generate a Phoenix app (skip installs so we can keep bounded steps).
generator_flags="--type phoenix --no-interactive --skip-install"
if [[ "${VERBOSE:-0}" -eq 1 ]]; then
  generator_flags="${generator_flags} --verbose"
fi
run_step "generate phoenix app" 900 "$work_dir" \
  "npx lix run reflaxe.elixir create '${APP_NAME}' ${generator_flags}"

app_dir="$work_dir/$APP_NAME"
if [[ ! -f "$app_dir/mix.exs" || ! -f "$app_dir/build.hxml" ]]; then
  echo "[readme-release-smoke] ERROR: generated project missing expected files (mix.exs/build.hxml)" >&2
  ls -la "$app_dir" >&2 || true
  exit 1
fi

# Step 4: Install deps in the generated app and compile (compile-only; no servers).
run_step "npm install (generated app)" 600 "$app_dir" "npm install --no-audit --no-fund"
run_step "lix scope create (generated app)" 60 "$app_dir" "npx lix scope create"
run_step "lix install reflaxe.elixir (generated app)" 300 "$app_dir" "npx lix install 'github:${REPO}#${tag}'"
run_step "lix download (generated app)" 600 "$app_dir" "npx lix download"
run_step "mix deps.get" 600 "$app_dir" "mix deps.get"
run_step "mix compile" 900 "$app_dir" "mix compile"

echo ""
echo "[readme-release-smoke] ✅ OK (release-tag install + generate + compile)"

#!/usr/bin/env bash
set -euo pipefail

# Validate that each example's generated Elixir compiles cleanly under --warnings-as-errors.
#
# Mix projects:
#   - deps.get + deps.compile (no WAE for deps)
#   - mix compile --force --warnings-as-errors --no-deps-check (WAE for app only)
#
# Haxe-only examples:
#   - haxe build.hxml
#   - elixirc --warnings-as-errors over generated lib/**/*.ex (into a temp output dir)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLES_DIR="${ROOT_DIR}/examples"

TIMEOUT_DEPS_GET="${TIMEOUT_DEPS_GET:-300}"
TIMEOUT_DEPS_COMPILE="${TIMEOUT_DEPS_COMPILE:-300}"
TIMEOUT_MIX_COMPILE="${TIMEOUT_MIX_COMPILE:-300}"
TIMEOUT_HAXE_BUILD="${TIMEOUT_HAXE_BUILD:-180}"
TIMEOUT_ELIXIRC="${TIMEOUT_ELIXIRC:-180}"

HAXE_BIN="${HAXE_BIN:-haxe}"

msg() { printf "\n[examples-elixir] %s\n" "$*"; }
fail() { echo "[examples-elixir] ❌ $*" >&2; exit 1; }

run_step() {
  local secs="$1"
  local cwd="$2"
  shift 2
  "${ROOT_DIR}/scripts/with-timeout.sh" --secs "$secs" --cwd "$cwd" --echo -- "$@"
}

make_tmp_out_dir() {
  local base="$1"
  local out="${base}/_build/elixirc_validate"
  rm -rf "$out" 2>/dev/null || true
  mkdir -p "$out"
  echo "$out"
}

list_elixir_sources() {
  local base="$1"
  local out_file="$2"
  : > "$out_file"

  if [ ! -d "${base}/lib" ]; then
    return 0
  fi

  # Use NUL-safe traversal (portable across macOS and Linux).
  find "${base}/lib" -type f -name "*.ex" -print0 2>/dev/null | \
    while IFS= read -r -d '' f; do
      printf "%s\n" "$f" >> "$out_file"
    done
}

validate_mix_example() {
  local dir="$1"
  local name="$2"

  msg "== $name (mix compile --warnings-as-errors) =="

  run_step "$TIMEOUT_DEPS_GET" "$dir" env MIX_ENV=test mix deps.get
  run_step "$TIMEOUT_DEPS_COMPILE" "$dir" env MIX_ENV=test mix deps.compile

  # Compile the app under WAE, but do not recompile deps (deps may have warnings we do not control).
  # Force recompilation so warnings can't hide behind cached artifacts.
  run_step "$TIMEOUT_MIX_COMPILE" "$dir" env MIX_ENV=test HAXE_NO_SERVER=1 mix compile --force --warnings-as-errors --no-deps-check
}

validate_haxe_only_example() {
  local dir="$1"
  local name="$2"

  msg "== $name (elixirc --warnings-as-errors) =="

  # Generate Elixir outputs
  if [ -f "${dir}/compile-all.hxml" ]; then
    run_step "$TIMEOUT_HAXE_BUILD" "$dir" "$HAXE_BIN" compile-all.hxml
  elif [ -f "${dir}/build.hxml" ]; then
    run_step "$TIMEOUT_HAXE_BUILD" "$dir" "$HAXE_BIN" build.hxml
  else
    fail "No build.hxml or compile-all.hxml found for ${name}"
  fi

  local out_dir
  out_dir="$(make_tmp_out_dir "$dir")"

  local sources_file sources
  sources_file="$(mktemp "${TMPDIR:-/tmp}/reflaxe-elixir-example-exs.XXXXXX")"
  list_elixir_sources "$dir" "$sources_file"
  if [ ! -s "$sources_file" ]; then
    msg "No .ex files under ${name}/lib; skipping elixirc"
    rm -f "$sources_file" 2>/dev/null || true
    return 0
  fi

  sources=()
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    sources+=("$line")
  done < "$sources_file"
  rm -f "$sources_file" 2>/dev/null || true

  # Compile into a temp dir to avoid polluting the repo with .beam files.
  # Note: elixirc writes beams even when only checking warnings.
  run_step "$TIMEOUT_ELIXIRC" "$dir" env elixirc --warnings-as-errors -o "$out_dir" "${sources[@]}"
  rm -rf "$out_dir" 2>/dev/null || true
}

main() {
  [ -d "$EXAMPLES_DIR" ] || fail "examples/ directory not found at $EXAMPLES_DIR"

  local dir name
  for dir in "$EXAMPLES_DIR"/*; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"

    # Skip repo-level docs file placeholders, if any.
    if [ "$name" = "README.md" ]; then
      continue
    fi

    if [ -f "${dir}/mix.exs" ]; then
      validate_mix_example "$dir" "$name"
    elif [ -f "${dir}/build.hxml" ] || [ -f "${dir}/compile-all.hxml" ]; then
      validate_haxe_only_example "$dir" "$name"
    else
      msg "== $name (skipped: no mix.exs or build.hxml) =="
    fi
  done

  msg "✅ All examples compile cleanly under --warnings-as-errors"
}

main "$@"

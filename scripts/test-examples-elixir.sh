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

# Hex (deps.get) occasionally flakes in CI due to transient network/TLS issues.
# Keep these conservative defaults but allow override by environment.
export HEX_HTTP_TIMEOUT="${HEX_HTTP_TIMEOUT:-120}"
export HEX_HTTP_CONCURRENCY="${HEX_HTTP_CONCURRENCY:-1}"

msg() { printf "\n[examples-elixir] %s\n" "$*"; }

LOG_DIR_DEFAULT="${ROOT_DIR}/_tmp/examples-elixir-wae"
LOG_DIR="${LOG_DIR:-$LOG_DIR_DEFAULT}"

CURRENT_EXAMPLE=""
CURRENT_PHASE=""
LAST_LOG_FILE=""
LAST_CMD=""

append_step_summary() {
  local title="$1"
  local body="$2"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      echo "### ${title}"
      echo
      echo '```'
      echo "$body"
      echo '```'
      echo
    } >>"$GITHUB_STEP_SUMMARY"
  fi
}

emit_github_error() {
  local title="$1"
  local body="$2"
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    # GitHub annotation body must be a single line; keep it short and actionable.
    local one_line
    one_line="$(printf '%s' "$body" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g' | cut -c1-2000)"
    echo "::error title=${title}::${one_line}"
  fi
}

fail() {
  local message="$1"
  echo "[examples-elixir] ❌ ${message}" >&2

  if [[ -n "${LAST_LOG_FILE:-}" && -f "$LAST_LOG_FILE" ]]; then
    echo "[examples-elixir] Last log: $LAST_LOG_FILE" >&2
    echo "[examples-elixir] ---- tail (200) ----" >&2
    tail -n 200 "$LAST_LOG_FILE" >&2 || true
    echo "[examples-elixir] --------------------" >&2

    local summary
    summary="$(
      printf 'Example: %s\nPhase: %s\nCommand: %s\nLog: %s\n\n' \
        "${CURRENT_EXAMPLE:-unknown}" \
        "${CURRENT_PHASE:-unknown}" \
        "${LAST_CMD:-unknown}" \
        "${LAST_LOG_FILE}"
      tail -n 200 "$LAST_LOG_FILE" 2>/dev/null || true
    )"
    append_step_summary "Examples (Elixir WAE) failure" "$summary"
	    emit_github_error "Examples (Elixir WAE) failed" "Example=${CURRENT_EXAMPLE:-unknown} Phase=${CURRENT_PHASE:-unknown} Command=${LAST_CMD:-unknown} Log=${LAST_LOG_FILE} :: $(tail -n 40 "$LAST_LOG_FILE" 2>/dev/null || true)"
	  else
	    append_step_summary "Examples (Elixir WAE) failure" "$(
	      printf 'Example: %s\nPhase: %s\nCommand: %s\n\n%s\n' \
	        "${CURRENT_EXAMPLE:-unknown}" \
        "${CURRENT_PHASE:-unknown}" \
        "${LAST_CMD:-unknown}" \
        "${message}"
    )"
    emit_github_error "Examples (Elixir WAE) failed" "Example=${CURRENT_EXAMPLE:-unknown} Phase=${CURRENT_PHASE:-unknown} Command=${LAST_CMD:-unknown} :: ${message}"
  fi

  exit 1
}

run_step() {
  local secs="$1"
  local cwd="$2"
  shift 2

  mkdir -p "$LOG_DIR"
  local safe_example="${CURRENT_EXAMPLE:-root}"
  safe_example="${safe_example//\//_}"
  local safe_phase="${CURRENT_PHASE:-step}"
  safe_phase="${safe_phase// /_}"
  local log_file
  log_file="$(mktemp "${LOG_DIR}/${safe_example}.${safe_phase}.XXXXXX.log")"
  LAST_LOG_FILE="$log_file"
  LAST_CMD="$(printf '%q ' "$@")"

  # Don't stream via `tee`. If a child process leaks and keeps the stdout pipe open, `tee`
  # will block indefinitely and CI will hit the job-level timeout (90m) instead of failing fast.
  #
  # We always capture full logs to disk, and we print tails on failure in `fail()`.
  set +e
  "${ROOT_DIR}/scripts/with-timeout.sh" --secs "$secs" --cwd "$cwd" --echo -- "$@" >>"$log_file" 2>&1
  local rc=$?
  set -e

  # Optional: show a small tail when verbose so local dev has quick context without opening the log.
  if [[ "${VERBOSE:-0}" == "1" ]]; then
    tail -n 40 "$log_file" 2>/dev/null || true
  fi

  # Best-effort cleanup in CI: avoid leaked background processes (e.g. `haxe --wait`) from
  # keeping later steps alive or interfering across shards.
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    "${ROOT_DIR}/scripts/haxe-server-cleanup.sh" >/dev/null 2>&1 || true
  fi

  return "$rc"
}

run_step_retry() {
  local attempts="$1"
  local secs="$2"
  local cwd="$3"
  shift 3

  local n=1
  while true; do
    if run_step "$secs" "$cwd" "$@"; then
      return 0
    fi

    if [[ "$n" -ge "$attempts" ]]; then
      return 1
    fi

    local backoff="$(( n * 2 ))"
    msg "Retrying (attempt $((n + 1))/$attempts) after ${backoff}s: $*"
    sleep "$backoff"
    n="$((n + 1))"
  done
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

  CURRENT_EXAMPLE="$name"

  msg "== $name (mix compile --warnings-as-errors) =="

  # deps.get is the most network-sensitive part (Hex), so allow a couple retries to
  # reduce CI flakiness without hiding real compile failures.
  CURRENT_PHASE="deps.get"
  run_step_retry 5 "$TIMEOUT_DEPS_GET" "$dir" env MIX_ENV=test HAXE_NO_SERVER=1 mix deps.get || fail "mix deps.get failed for $name"

  CURRENT_PHASE="deps.compile"
  run_step "$TIMEOUT_DEPS_COMPILE" "$dir" env MIX_ENV=test HAXE_NO_SERVER=1 mix deps.compile || fail "mix deps.compile failed for $name"

  # Compile the app under WAE, but do not recompile deps (deps may have warnings we do not control).
  #
  # Important: `mix compile --force` can trigger dependency recompilation. Under WAE that can
  # fail the job due to upstream warnings (e.g. Elixir 1.18 introduced stricter type warnings
  # that some older deps still emit). To keep the gate focused on *our* code:
  # - clean only the current project build artifacts
  # - compile under WAE with deps checking disabled
  CURRENT_PHASE="mix.clean"
  run_step "$TIMEOUT_MIX_COMPILE" "$dir" env MIX_ENV=test HAXE_NO_SERVER=1 mix clean || fail "mix clean failed for $name"

  CURRENT_PHASE="mix.compile"
  run_step "$TIMEOUT_MIX_COMPILE" "$dir" env MIX_ENV=test HAXE_NO_SERVER=1 mix compile --warnings-as-errors --no-deps-check || fail "mix compile --warnings-as-errors failed for $name"
}

validate_haxe_only_example() {
  local dir="$1"
  local name="$2"

  CURRENT_EXAMPLE="$name"

  msg "== $name (elixirc --warnings-as-errors) =="

  # Generate Elixir outputs
  if [ -f "${dir}/compile-all.hxml" ]; then
    CURRENT_PHASE="haxe.build"
    run_step "$TIMEOUT_HAXE_BUILD" "$dir" "$HAXE_BIN" compile-all.hxml || fail "haxe compile-all.hxml failed for $name"
  elif [ -f "${dir}/build.hxml" ]; then
    CURRENT_PHASE="haxe.build"
    run_step "$TIMEOUT_HAXE_BUILD" "$dir" "$HAXE_BIN" build.hxml || fail "haxe build.hxml failed for $name"
  else
    fail "No build.hxml or compile-all.hxml found for ${name}"
  fi

  local out_dir
  out_dir="$(make_tmp_out_dir "$dir")"

  # Compile `.ex` files in a deterministic, dependency-friendly order.
  #
  # NOTE: `find` traversal order differs across platforms/filesystems. `elixirc` compilation
  # order can matter for structs/macros, so we enforce an order here to avoid “passes locally
  # but fails on CI (linux)” drift.
  local ex_files
  ex_files="$(cd "$dir" && find lib -type f -name "*.ex" -print 2>/dev/null | sed 's|^\\./||' | LC_ALL=C sort || true)"
  if [ -z "${ex_files}" ]; then
    msg "No .ex files under ${name}/lib; skipping elixirc"
    return 0
  fi

  local ordered=()

  # Known runtime/bridge modules that other generated modules commonly depend on.
  local prefer=(
    "lib/reflaxe/exception.ex"
    "lib/reflaxe/elixir/haxe_throw.ex"
    "lib/type.ex"
    "lib/reflect.ex"
    "lib/std.ex"
    "lib/string_tools.ex"
    "lib/string_buf.ex"
    "lib/sys.ex"
  )

  remove_one() {
    local needle="$1"
    ex_files="$(printf '%s\n' "$ex_files" | grep -Fxv "$needle" || true)"
  }

  for p in "${prefer[@]}"; do
    if printf '%s\n' "$ex_files" | grep -Fxq "$p"; then
      ordered+=("$p")
      remove_one "$p"
    fi
  done

  # Compile Reflaxe + Haxe runtime modules early (they often define structs/macros used elsewhere).
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      lib/reflaxe/*)
        ordered+=("$f")
        ;;
    esac
  done <<< "$(printf '%s\n' "$ex_files" | grep '^lib/reflaxe/' || true)"
  ex_files="$(printf '%s\n' "$ex_files" | grep -v '^lib/reflaxe/' || true)"

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      lib/haxe/*)
        ordered+=("$f")
        ;;
    esac
  done <<< "$(printf '%s\n' "$ex_files" | grep '^lib/haxe/' || true)"
  ex_files="$(printf '%s\n' "$ex_files" | grep -v '^lib/haxe/' || true)"

  # Remaining app modules (stable sorted order).
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    ordered+=("$f")
  done <<< "$ex_files"

  # Compile into a temp dir to avoid polluting the repo with .beam files.
  # Note: elixirc writes beams even when only checking warnings.
  CURRENT_PHASE="elixirc"
  run_step "$TIMEOUT_ELIXIRC" "$dir" env elixirc --warnings-as-errors -o "$out_dir" "${ordered[@]}" || fail "elixirc --warnings-as-errors failed for $name"
  rm -rf "$out_dir" 2>/dev/null || true
}

main() {
  [ -d "$EXAMPLES_DIR" ] || fail "examples/ directory not found at $EXAMPLES_DIR"

  rm -rf "$LOG_DIR" 2>/dev/null || true
  mkdir -p "$LOG_DIR"

  # Allow CI (or local dev) to skip heavy/duplicate examples by directory name.
  # Space-separated list, e.g.: EXAMPLES_ELIXIR_WAE_SKIP="todo-app test-integration"
  local skip_examples="${EXAMPLES_ELIXIR_WAE_SKIP:-}"
  # Allow CI (or local dev) to run a subset (shard) of examples by directory name.
  # Space-separated list, e.g.: EXAMPLES_ELIXIR_WAE_ONLY="01-simple-modules 02-mix-project"
  local only_examples="${EXAMPLES_ELIXIR_WAE_ONLY:-}"

  # Ensure Hex/Rebar are present in non-interactive CI environments.
  # Some Mix versions prompt to install these, which can hang CI until timeout.
  msg "Bootstrapping Hex/Rebar"
  # Note: Avoid `mix help hex` here. When Hex is missing, Mix may prompt for installation
  # even for help output, which breaks non-interactive CI. `mix archive` is safe and does
  # not require Hex to be installed.
  archives="$(mix archive 2>/dev/null || true)"
  if printf '%s' "$archives" | grep -qE '^[*][[:space:]]+hex-'; then
    msg "Hex already available; skipping mix local.hex"
  else
    CURRENT_EXAMPLE="bootstrap"
    CURRENT_PHASE="mix.local.hex"
    run_step_retry 5 60 "$ROOT_DIR" mix local.hex --force || fail "mix local.hex --force failed"
  fi

  CURRENT_EXAMPLE="bootstrap"
  CURRENT_PHASE="mix.local.rebar"
  run_step_retry 5 60 "$ROOT_DIR" mix local.rebar --force || fail "mix local.rebar --force failed"

  local dir name
  for dir in "$EXAMPLES_DIR"/*; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"

    # Skip repo-level docs file placeholders, if any.
    if [ "$name" = "README.md" ]; then
      continue
    fi

    if [[ -n "$skip_examples" ]] && printf ' %s ' "$skip_examples" | grep -Fq " ${name} "; then
      msg "== $name (skipped: EXAMPLES_ELIXIR_WAE_SKIP) =="
      continue
    fi

    if [[ -n "$only_examples" ]] && ! printf ' %s ' "$only_examples" | grep -Fq " ${name} "; then
      msg "== $name (skipped: EXAMPLES_ELIXIR_WAE_ONLY) =="
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

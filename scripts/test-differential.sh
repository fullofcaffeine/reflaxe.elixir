#!/usr/bin/env bash
# test-differential.sh - run each fixture program on the Haxe interpreter and on
# the BEAM, and report every difference in stdout or exit status.
#
# Why: a compiler bug can produce Elixir that compiles without a warning and
# still computes the wrong value. Snapshot tests only compare generated text,
# so they accept such code. This command uses `haxe --interp` as the reference:
# the same Main.hx must print the same bytes and exit the same way on the BEAM.
#
# What it proves: for each fixture, the observed stdout bytes and the exit
# status match the interpreter. What it does not prove: effects that the
# program does not print (files, messages, process state), stderr text,
# timing, or code that the fixtures do not run. See
# docs/03-compiler-development/TESTING_INFRASTRUCTURE.md, "Interpreter-versus-
# BEAM differential check".
#
# Fixture layout (FIXTURE_DIR, default test/differential):
#   <id>/Main.hx                 required; `class Main` with `static function main()`
#   <id>/compile.hxml            optional extra flags for both runs; paths in it
#                                resolve against the scope directory, so keep it
#                                to flags such as -D defines
#   known-differences.txt        known bugs, one line each:
#                                <id> <DIFF|COMPILE-FAIL:STAGE|TIMEOUT:STAGE> <beads-id> <reason>
#                                where STAGE is haxe, elixir, interp or beam
#   known/<id>.out               for a DIFF entry: the exact BEAM observation
#                                (stdout plus exit-status line) that is known
#                                to be wrong today
#
# Per fixture it prints one line: MATCH, DIFF, COMPILE-FAIL, INTERP-FAIL or
# TIMEOUT, with a note when the fixture is on the known list. Then it prints a
# unified diff for each unexpected DIFF. Exit status: 0 when every fixture
# matches or fails exactly as listed; 1 when anything else happens, including a
# listed fixture that now matches (remove it from the list) or whose known
# output changed; 2 for a usage or setup error.
set -euo pipefail
set +o noclobber

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
WITH_TIMEOUT="$ROOT_DIR/scripts/util/with-timeout.sh"
VALIDATOR="$ROOT_DIR/scripts/ci/validate-generated-elixir-warnings.exs"
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

usage() {
  cat >&2 <<'EOF'
Usage: scripts/test-differential.sh [options] [FIXTURE_DIR]

Runs every <id>/Main.hx under FIXTURE_DIR (default: test/differential) with
`haxe --interp` and compiled to Elixir on the BEAM, and compares stdout and
exit status.

Options:
  -j, --jobs N           run N fixtures at a time (default 1)
  --fixture ID           run only this fixture (repeatable)
  --known FILE           known-differences list
                         (default: FIXTURE_DIR/known-differences.txt)
  --scope DIR            directory that haxe runs in; its haxe_libraries decide
                         which reflaxe.elixir `-lib reflaxe.elixir` uses
                         (default: this checkout, so the source tree)
  --work DIR             output directory (default: _tmp/differential/<name>)
  --timeout SECS         limit for each program run, interpreter and BEAM
                         (default 30)
  --compile-timeout SECS limit for each compile step (default 600)
  --update-known         write known/<id>.out for listed DIFF fixtures from
                         this run (review the diff first)
  --reclassify           run nothing; classify the results of the last run in
                         the work directory again (after editing the list)
  -v, --verbose          also print the diff of known differences
  -h, --help             show this help

Environment: HAXE_BIN (default haxe), ELIXIR_BIN (default elixir).
EOF
}

die() { echo "[differential] $*" >&2; exit 2; }

# ---------------------------------------------------------------------------
# Worker: run one fixture. Configuration comes from DIFF_* variables that the
# parent exports, so a serial run and a parallel run use the same code.
# Writes $DIFF_WORK/<id>/result as "STATUS STAGE WARNINGS".
# ---------------------------------------------------------------------------

# Append a stable exit-status line so stdout and status compare as one file.
# A missing final newline is made visible instead of joining the marker line.
make_observation() {
  local stdout_file="$1" rc="$2" out_file="$3"
  cat "$stdout_file" >"$out_file"
  if [[ -s "$stdout_file" && -n "$(tail -c 1 "$stdout_file")" ]]; then
    printf '\n[no newline at end of stdout]\n' >>"$out_file"
  fi
  printf '[exit status %s]\n' "$rc" >>"$out_file"
}

is_timeout_rc() { [[ "$1" == 124 || "$1" == 137 ]]; }

sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; }

# Digest of a fixture's sources (Main.hx and the optional compile.hxml).
fixture_digest() {
  { cat "$1/Main.hx"; echo; [[ -f "$1/compile.hxml" ]] && cat "$1/compile.hxml"; true; } \
    | sha256 | awk '{print $1}'
}

# The compiler state results depend on: the scope's git HEAD plus a digest of
# its uncommitted tracked changes. "none" outside a git checkout.
scope_state() {
  local head dirty
  head="$(git -C "$1" rev-parse HEAD 2>/dev/null || echo none)"
  dirty="$(git -C "$1" diff HEAD 2>/dev/null | sha256 | awk '{print substr($1, 1, 12)}')"
  echo "$head+$dirty"
}

run_fixture() (
  local id="$1"
  local src="$DIFF_FIXTURE_DIR/$id"
  local w="$DIFF_WORK/$id"
  rm -rf -- "$w"
  mkdir -p "$w"
  # Record what this result was computed from, so --reclassify can refuse
  # results from another compiler revision or an edited fixture.
  echo "$DIFF_SCOPE_STATE $(fixture_digest "$src")" >"$w/stamp"
  local result="$w/result"
  local extra=()
  if [[ -f "$src/compile.hxml" ]]; then extra=("$src/compile.hxml"); fi

  # 1. Reference: the Haxe interpreter. A non-zero exit means the reference
  # itself failed (a type error or an uncaught exception); fix the fixture.
  local rc=0
  (cd "$DIFF_SCOPE" && "$WITH_TIMEOUT" "$DIFF_RUN_TIMEOUT" \
    "$DIFF_HAXE" -cp "$src" -main Main ${extra[@]+"${extra[@]}"} --interp) \
    >"$w/interp.stdout" 2>"$w/interp.stderr" || rc=$?
  if is_timeout_rc "$rc"; then echo "TIMEOUT interp 0" >"$result"; return 0; fi
  if [[ "$rc" != 0 ]]; then echo "INTERP-FAIL interp 0" >"$result"; return 0; fi
  make_observation "$w/interp.stdout" 0 "$w/interp.out"

  # 2. Haxe to Elixir, with the flags a generated consumer project uses.
  rc=0
  (cd "$DIFF_SCOPE" && "$WITH_TIMEOUT" "$DIFF_COMPILE_TIMEOUT" \
    "$DIFF_HAXE" -cp "$src" -main Main -lib reflaxe.elixir \
    -D elixir_output="$w/out" -D reflaxe.dont_output_metadata_id -D no-utf16 \
    -dce full ${extra[@]+"${extra[@]}"}) >"$w/haxe.log" 2>&1 || rc=$?
  if is_timeout_rc "$rc"; then echo "TIMEOUT haxe 0" >"$result"; return 0; fi
  if [[ "$rc" != 0 ]]; then echo "COMPILE-FAIL haxe 0" >"$result"; return 0; fi

  # 3. Elixir to BEAM through the repository's strict validator. Warnings do
  # not fail the comparison (other gates own them), but they are counted:
  # an unused-variable warning often marks a dropped value.
  local files=()
  while IFS= read -r f; do files+=("$f"); done \
    < <(cd "$w/out" && find . -type f -name '*.ex' -print | LC_ALL=C sort)
  if [[ ${#files[@]} == 0 ]]; then echo "COMPILE-FAIL haxe 0" >"$result"; return 0; fi
  mkdir -p "$w/beam"
  rc=0
  (cd "$w/out" && "$WITH_TIMEOUT" "$DIFF_COMPILE_TIMEOUT" \
    "$DIFF_ELIXIR" "$VALIDATOR" "$w/beam" "${files[@]}") >"$w/elixir.log" 2>&1 || rc=$?
  if is_timeout_rc "$rc"; then echo "TIMEOUT elixir 0" >"$result"; return 0; fi
  local warnings=0
  if [[ "$rc" != 0 ]]; then
    local summary
    summary="$(grep -E '^generated warning validation failed: [0-9]+ warning\(s\)$' "$w/elixir.log" || true)"
    if [[ -z "$summary" ]]; then echo "COMPILE-FAIL elixir 0" >"$result"; return 0; fi
    warnings="$(echo "$summary" | sed -E 's/.*: ([0-9]+) warning.*/\1/')"
  fi

  # 4. Run Main.main/0 on the BEAM.
  rc=0
  (cd "$w/out" && "$WITH_TIMEOUT" "$DIFF_RUN_TIMEOUT" "$DIFF_ELIXIR" -pa "$w/beam" -e '
      Code.ensure_loaded!(Main)
      unless function_exported?(Main, :main, 0), do: raise("Missing Main.main/0")
      Main.main()
    ') >"$w/beam.stdout" 2>"$w/beam.stderr" || rc=$?
  if is_timeout_rc "$rc"; then echo "TIMEOUT beam $warnings" >"$result"; return 0; fi
  make_observation "$w/beam.stdout" "$rc" "$w/beam.out"

  # 5. Compare the two observations byte for byte.
  if cmp -s "$w/interp.out" "$w/beam.out"; then
    echo "MATCH - $warnings" >"$result"
  else
    diff -u -L interp -L beam "$w/interp.out" "$w/beam.out" >"$w/diff" || true
    echo "DIFF beam $warnings" >"$result"
  fi
)

if [[ "${1:-}" == "--worker" ]]; then
  run_fixture "${2:?--worker needs a fixture id}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Parent: parse options, list fixtures, run them, classify, report.
# ---------------------------------------------------------------------------
jobs=1
fixture_dir=""
known_file=""
scope="$ROOT_DIR"
work=""
run_timeout=30
compile_timeout=600
update_known=0
reclassify=0
verbose=0
selected=()

# Options that take a value: a missing or empty value is a usage error (2).
value_of() { [[ $# -ge 2 && -n "$2" ]] || die "$1 needs a value"; echo "$2"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -j|--jobs|--fixture|--known|--scope|--work|--timeout|--compile-timeout)
      v="$(value_of "$@")" || exit 2
      case "$1" in
        -j|--jobs) jobs="$v" ;;
        --fixture) selected+=("$v") ;;
        --known) known_file="$v" ;;
        --scope) scope="$v" ;;
        --work) work="$v" ;;
        --timeout) run_timeout="$v" ;;
        --compile-timeout) compile_timeout="$v" ;;
      esac
      shift 2 ;;
    --update-known) update_known=1; shift ;;
    --reclassify) reclassify=1; shift ;;
    -v|--verbose) verbose=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) usage; exit 2 ;;
    *) [[ -z "$fixture_dir" ]] || { usage; exit 2; }; fixture_dir="$1"; shift ;;
  esac
done

for n in "$jobs" "$run_timeout" "$compile_timeout"; do
  [[ "$n" =~ ^[1-9][0-9]*$ ]] || die "expected a positive integer, got '$n'"
done

fixture_dir="${fixture_dir:-$ROOT_DIR/test/differential}"
[[ -d "$fixture_dir" ]] || die "fixture directory not found: $fixture_dir"
fixture_dir="$(cd "$fixture_dir" && pwd)"
[[ -d "$scope" ]] || die "scope directory not found: $scope"
scope="$(cd "$scope" && pwd)"
known_file="${known_file:-$fixture_dir/known-differences.txt}"
known_dir="$(dirname "$known_file")/known"
work="${work:-$ROOT_DIR/_tmp/differential/$(basename "$fixture_dir")}"
mkdir -p "$work"
work="$(cd "$work" && pwd)"

# Every subdirectory except known/ is a fixture and must hold Main.hx, so a
# misnamed file cannot silently drop a fixture from the gate.
all_ids=()
while IFS= read -r d; do
  id="$(basename "$d")"
  [[ "$id" == known ]] && continue
  [[ -f "$d/Main.hx" ]] || die "fixture $id has no Main.hx: $d"
  all_ids+=("$id")
done < <(find "$fixture_dir" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort)
[[ ${#all_ids[@]} -gt 0 ]] || die "no fixtures under $fixture_dir"

ids=()
if [[ ${#selected[@]} -gt 0 ]]; then
  for s in "${selected[@]}"; do
    found=0
    for id in "${all_ids[@]}"; do [[ "$id" == "$s" ]] && found=1; done
    [[ "$found" == 1 ]] || die "unknown fixture: $s"
  done
  for id in "${all_ids[@]}"; do
    for s in "${selected[@]}"; do [[ "$id" == "$s" ]] && { ids+=("$id"); break; }; done
  done
else
  ids=("${all_ids[@]}")
fi

is_selected() {
  local x
  for x in "${ids[@]}"; do [[ "$x" == "$1" ]] && return 0; done
  return 1
}

# Known-differences list: validate every line before running anything.
known_lines=""
if [[ -f "$known_file" ]]; then
  known_lines="$(grep -vE '^[[:space:]]*(#|$)' "$known_file" || true)"
fi
seen_known=" "
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  read -r k_id k_status k_bead k_reason <<<"$line"
  case "$k_status" in
    DIFF|COMPILE-FAIL:haxe|COMPILE-FAIL:elixir|TIMEOUT:interp|TIMEOUT:haxe|TIMEOUT:elixir|TIMEOUT:beam) ;;
    *) die "known-differences: '$k_id' has status '$k_status'; use DIFF, COMPILE-FAIL:<haxe|elixir> or TIMEOUT:<interp|haxe|elixir|beam>" ;;
  esac
  [[ "$k_bead" =~ ^[a-z][a-z0-9.]*-[a-z0-9.]+$ ]] \
    || die "known-differences: '$k_id' needs a Beads id, got '$k_bead'"
  [[ -n "${k_reason:-}" ]] || die "known-differences: '$k_id' needs a reason"
  [[ "$seen_known" != *" $k_id "* ]] || die "known-differences: '$k_id' is listed twice"
  seen_known+="$k_id "
  found=0
  for id in "${all_ids[@]}"; do [[ "$id" == "$k_id" ]] && found=1; done
  [[ "$found" == 1 ]] || die "known-differences: no fixture named '$k_id'; remove the line"
  if [[ "$k_status" == DIFF && "$update_known" == 0 ]] && is_selected "$k_id" \
    && [[ ! -f "$known_dir/$k_id.out" ]]; then
    die "known-differences: '$k_id' is a DIFF entry without $known_dir/$k_id.out; run with --update-known after review"
  fi
done <<<"$known_lines"

# Every recorded output must belong to a DIFF entry, so a removed entry
# cannot leave a stale file behind.
if [[ -d "$known_dir" ]]; then
  while IFS= read -r f; do
    name="$(basename "$f")"
    k_id="${name%.out}"
    [[ "$name" == *.out ]] || die "known/: unexpected file $name; only <fixture-id>.out files belong there"
    entry_status="$(echo "$known_lines" | awk -v id="$k_id" '$1 == id {print $2}')"
    [[ "$entry_status" == DIFF ]] \
      || die "known/: $name has no DIFF entry in $(basename "$known_file"); delete the file or add the entry"
  done < <(find "$known_dir" -mindepth 1 -maxdepth 1 -print | LC_ALL=C sort)
fi

known_entry() { # prints "STATUS BEAD" for a listed fixture, nothing otherwise
  local line k_id rest
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    read -r k_id rest <<<"$line"
    if [[ "$k_id" == "$1" ]]; then
      echo "$rest" | awk '{print $1, $2}'
      return 0
    fi
  done <<<"$known_lines"
}

export DIFF_FIXTURE_DIR="$fixture_dir" DIFF_WORK="$work" DIFF_SCOPE="$scope"
export DIFF_RUN_TIMEOUT="$run_timeout" DIFF_COMPILE_TIMEOUT="$compile_timeout"
export DIFF_HAXE="${HAXE_BIN:-haxe}" DIFF_ELIXIR="${ELIXIR_BIN:-elixir}"
export HAXE_NO_SERVER="${HAXE_NO_SERVER:-1}"
DIFF_SCOPE_STATE="$(scope_state "$scope")"
export DIFF_SCOPE_STATE

rel() { # shorten a path under the checkout for display
  case "$1" in "$ROOT_DIR") echo . ;; "$ROOT_DIR"/*) echo "${1#"$ROOT_DIR"/}" ;; *) echo "$1" ;; esac
}

start_secs=$SECONDS
if [[ "$reclassify" == 1 ]]; then
  echo "[differential] RECLASSIFY: nothing is run; classifying the stored results of ${#ids[@]} fixture(s) in $(rel "$work")"
else
  echo "[differential] ${#ids[@]} fixture(s) from $(rel "$fixture_dir"); scope $(rel "$scope"); jobs $jobs; run timeout ${run_timeout}s"
fi

n_match=0; n_known=0; n_bad=0
report_details=()

# Read $work/<id>/result into status, stage and warnings. A missing, empty
# or malformed file becomes RUNNER-ERROR with a reason in `problem`.
read_result() {
  local f="$work/$1/result" line=""
  status=RUNNER-ERROR; stage=-; warnings=0; problem=""
  if [[ ! -f "$f" ]]; then problem="the worker left no result"; return 0; fi
  IFS= read -r line <"$f" || true
  local s g n extra
  read -r s g n extra <<<"$line" || true
  case "$s" in MATCH|DIFF|COMPILE-FAIL|INTERP-FAIL|TIMEOUT) ;; *) s="" ;; esac
  if [[ -z "$s" || -z "$g" || ! "$n" =~ ^[0-9]+$ || -n "$extra" ]]; then
    problem="the result file is empty or corrupt: '$line'"
    return 0
  fi
  status="$s"; stage="$g"; warnings="$n"
}

# Classify one finished fixture, print its line, and record what to detail.
classify() {
  local id="$1" w="$work/$1"
  local status stage warnings problem=""
  read_result "$id"
  local entry k_status="" k_bead="" note=""
  entry="$(known_entry "$id")"
  if [[ -n "$entry" ]]; then read -r k_status k_bead <<<"$entry"; fi
  # A listed COMPILE-FAIL or TIMEOUT also names its stage.
  local actual="$status"
  case "$status" in COMPILE-FAIL|TIMEOUT) actual="$status:$stage" ;; esac
  if [[ "$reclassify" == 1 && "$status" != RUNNER-ERROR ]]; then
    local now
    now="$DIFF_SCOPE_STATE $(fixture_digest "$DIFF_FIXTURE_DIR/$id")"
    if [[ ! -f "$w/stamp" || "$(cat "$w/stamp")" != "$now" ]]; then
      status=RUNNER-ERROR
      problem="stale result: the scope commit, its uncommitted changes or the fixture changed since the run; run it again"
    fi
  fi

  if [[ "$status" == RUNNER-ERROR ]]; then
    # A stale result is explained on its line; its old details would mislead.
    n_bad=$((n_bad + 1)); note="${problem:-the worker left no result}"
    [[ "$problem" == stale* ]] || report_details+=("$id")
  elif [[ -z "$k_status" ]]; then
    if [[ "$status" == MATCH ]]; then
      n_match=$((n_match + 1))
    else
      n_bad=$((n_bad + 1)); note="unexpected"; report_details+=("$id")
    fi
  elif [[ "$status" == MATCH ]]; then
    n_bad=$((n_bad + 1))
    note="FIXED: remove it from $(basename "$known_file") and known/ ($k_bead)"
  elif [[ "$actual" != "$k_status" ]]; then
    n_bad=$((n_bad + 1)); note="unexpected; listed as $k_status ($k_bead)"; report_details+=("$id")
  elif [[ "$status" == DIFF ]] && ! cmp -s "$w/beam.out" "$known_dir/$id.out" 2>/dev/null; then
    if [[ "$update_known" == 1 ]]; then
      mkdir -p "$known_dir"
      cp "$w/beam.out" "$known_dir/$id.out"
      n_known=$((n_known + 1)); note="known ($k_bead); known/$id.out updated"
    else
      n_bad=$((n_bad + 1)); note="known output CHANGED ($k_bead)"; report_details+=("$id")
    fi
  else
    n_known=$((n_known + 1)); note="known ($k_bead)"
    [[ "$verbose" == 1 ]] && report_details+=("$id")
  fi
  [[ "$warnings" != 0 ]] && note="${note:+$note; }warnings=$warnings"
  if [[ -n "$note" ]]; then
    printf '%-12s %-28s %s\n' "$status" "$id" "$note"
  else
    printf '%-12s %s\n' "$status" "$id"
  fi
}

if [[ "$reclassify" != 1 ]]; then
  # Never classify a result from an earlier run: if a worker cannot start
  # or dies, its fixture must show RUNNER-ERROR, not the old status.
  for id in "${ids[@]}"; do rm -f -- "$work/$id/result" "$work/$id/stamp"; done
fi
if [[ "$reclassify" == 1 ]]; then
  for id in "${ids[@]}"; do classify "$id"; done
elif [[ "$jobs" == 1 ]]; then
  for id in "${ids[@]}"; do
    bash "$SELF" --worker "$id" || true
    classify "$id"
  done
else
  printf '%s\n' "${ids[@]}" | xargs -P "$jobs" -I{} bash "$SELF" --worker {} || true
  for id in "${ids[@]}"; do classify "$id"; done
fi

for id in ${report_details[@]+"${report_details[@]}"}; do
  w="$work/$id"
  read_result "$id"
  echo
  echo "=== $status $id (stage: $stage; files: $(rel "$w"))"
  case "$status" in
    DIFF)
      cat "$w/diff"
      if [[ -f "$known_dir/$id.out" ]] && ! cmp -s "$w/beam.out" "$known_dir/$id.out"; then
        echo "--- change against the recorded known output:"
        diff -u -L known -L beam "$known_dir/$id.out" "$w/beam.out" || true
      fi
      if [[ -s "$w/beam.stderr" ]]; then
        echo "--- last lines of BEAM stderr:"
        tail -n 15 "$w/beam.stderr"
      fi
      ;;
    INTERP-FAIL) tail -n 20 "$w/interp.stderr" ;;
    COMPILE-FAIL)
      if [[ "$stage" == haxe ]]; then tail -n 20 "$w/haxe.log"; else tail -n 20 "$w/elixir.log"; fi ;;
    TIMEOUT) echo "a step ran longer than its limit (stage: $stage)" ;;
    *) echo "${problem:-stale or missing result}; run with --fixture $id to see the worker's error" ;;
  esac
done

echo
echo "[differential] ${#ids[@]} fixture(s): $n_match match, $n_known known difference(s), $n_bad need attention"
echo "[differential] elapsed $((SECONDS - start_secs))s" >&2
suffix=""
[[ "$reclassify" == 1 ]] && suffix=" (reclassified, nothing was run)"
if [[ "$n_bad" == 0 ]]; then
  echo "[differential] PASS$suffix"
  exit 0
fi
echo "[differential] FAIL$suffix"
exit 1

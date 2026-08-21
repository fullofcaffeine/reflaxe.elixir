#!/usr/bin/env bash
set -euo pipefail

# Run selected official Haxe tests through an installed Reflaxe.Elixir package.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
WORKSPACE="${1:-}"
HAXE_BIN="${HAXE_BIN:-}"
HAXELIB_WRAPPER_DIR="${HAXELIB_WRAPPER_DIR:-}"
CLASSIFIER="$ROOT_DIR/scripts/ci/classify-official-haxe-smoke-failure.py"

fail() {
  echo "[official-haxe-beam-smoke] ERROR: $*" >&2
  exit 1
}

[[ -n "$WORKSPACE" ]] || fail "usage: $0 <empty-workspace>"
[[ -x "$TIMEOUT" ]] || fail "missing timeout wrapper: $TIMEOUT"
[[ -x "$HAXE_BIN" ]] || fail "HAXE_BIN must name the installed-package Haxe binary"
[[ -x "$HAXELIB_WRAPPER_DIR/haxelib" ]] || fail "HAXELIB_WRAPPER_DIR must contain the reviewed package wrapper"
[[ ! -e "$WORKSPACE" ]] || fail "workspace already exists: $WORKSPACE"

mkdir -p "$WORKSPACE/src" "$WORKSPACE/generated" "$WORKSPACE/test/upstream_unitstd/upstream" "$WORKSPACE/artifacts"

record_failure() {
  local stage="$1"
  local status="$2"
  local log="$3"
  python3 "$CLASSIFIER" "$stage" "$status" "$log" "$WORKSPACE/artifacts/result.json"
}

if ! python3 "$ROOT_DIR/scripts/ci/check-upstream-haxe-smoke.py" >"$WORKSPACE/artifacts/provenance.log" 2>&1; then
  record_failure provenance 1 "$WORKSPACE/artifacts/provenance.log"
  cat "$WORKSPACE/artifacts/provenance.log" >&2
  fail "official source records failed"
fi
cp -R "$ROOT_DIR/test/upstream_haxe_smoke/support/." "$WORKSPACE/src/"
cp -R "$ROOT_DIR/test/upstream_haxe_smoke/upstream/." "$WORKSPACE/src/"
mkdir -p "$WORKSPACE/src/stdlib_parity/upstream"
cp "$ROOT_DIR/test/haxe_exunit/stdlib_parity/src_haxe/stdlib_parity/upstream/UpstreamUnitStdMacro.hx" \
  "$WORKSPACE/src/stdlib_parity/upstream/UpstreamUnitStdMacro.hx"
cp "$ROOT_DIR/test/upstream_unitstd/upstream/Date.unit.hx" "$WORKSPACE/test/upstream_unitstd/upstream/Date.unit.hx"

cat > "$WORKSPACE/build.hxml" <<'HXML'
-lib reflaxe.elixir
-cp src
-dce full
-D elixir_output=generated
unit.TestNumericSeparator
unit.issues.Issue10455
upstream_haxe_smoke.OfficialUnitStdTest
HXML

cat > "$WORKSPACE/mix.exs" <<'EX'
defmodule OfficialHaxeBeamSmoke.MixProject do
  use Mix.Project

  def project do
    [app: :official_haxe_beam_smoke, version: "0.0.0", elixir: "~> 1.14", deps: []]
  end
end
EX

cat > "$WORKSPACE/test/test_helper.exs" <<'EX'
ExUnit.start()

generated_root = Path.expand("../generated", __DIR__)
files = Path.wildcard(Path.join(generated_root, "**/*.ex"))

preferred = [
  "reflaxe/exception.ex",
  "reflaxe/elixir/haxe_throw.ex",
  "reflaxe/elixir/haxe_float.ex",
  "type.ex",
  "reflect.ex",
  "std.ex",
  "string_tools.ex"
]

relative = Enum.map(files, &Path.relative_to(&1, generated_root))
ordered =
  Enum.filter(preferred, &(&1 in relative)) ++
    Enum.sort(relative -- preferred)

Enum.each(ordered, &Code.require_file(Path.join(generated_root, &1)))
EX

cat > "$WORKSPACE/test/official_haxe_beam_smoke_test.exs" <<'EX'
expected = [TestNumericSeparator, Issue10455, OfficialUnitStdTest]
missing = Enum.reject(expected, &Code.ensure_loaded?/1)

if missing != [] do
  raise "missing generated official test modules: #{inspect(missing)}"
end
EX

echo "[official-haxe-beam-smoke] compile official tests with the installed package"
set +e
"$TIMEOUT" --secs 300 --cwd "$WORKSPACE" -- \
  bash -lc 'PATH="$HAXELIB_WRAPPER_DIR:$(dirname "$HAXE_BIN"):$PATH" "$HAXE_BIN" build.hxml' \
  >"$WORKSPACE/artifacts/haxe-compile.log" 2>&1
haxe_status=$?
set -e
if [[ "$haxe_status" -ne 0 ]]; then
  record_failure haxe-compile "$haxe_status" "$WORKSPACE/artifacts/haxe-compile.log"
  tail -200 "$WORKSPACE/artifacts/haxe-compile.log" >&2
  fail "Haxe compilation failed; see artifacts/haxe-compile.log"
fi

for generated_test in \
  unit/test_numeric_separator.ex \
  unit/issues/issue10455.ex \
  upstream_haxe_smoke/official_unit_std_test.ex
do
  if [[ ! -f "$WORKSPACE/generated/$generated_test" ]]; then
    printf 'missing generated test: %s\n' "$generated_test" >"$WORKSPACE/artifacts/missing-test.log"
    record_failure generated-tests 1 "$WORKSPACE/artifacts/missing-test.log"
    fail "missing generated test: $generated_test"
  fi
done

echo "[official-haxe-beam-smoke] compile generated Elixir strictly and run it on BEAM"
set +e
"$TIMEOUT" --secs 180 --cwd "$WORKSPACE" -- \
  mix test --warnings-as-errors --max-cases 1 --timeout 60000 --trace \
  >"$WORKSPACE/artifacts/mix-test.log" 2>&1
mix_status=$?
set -e
if [[ "$mix_status" -ne 0 ]]; then
  record_failure mix-test "$mix_status" "$WORKSPACE/artifacts/mix-test.log"
  tail -200 "$WORKSPACE/artifacts/mix-test.log" >&2
  fail "strict Mix or BEAM execution failed; see artifacts/mix-test.log"
fi

grep -F "0 failures" "$WORKSPACE/artifacts/mix-test.log" >/dev/null || \
  fail "ExUnit did not report a clean result"
printf '%s\n' '{"category":"passed","exitCode":0,"status":"passed"}' >"$WORKSPACE/artifacts/result.json"
echo "[official-haxe-beam-smoke] OK: shared-language, unitstd, and issue tests passed"

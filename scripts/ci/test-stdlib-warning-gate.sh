#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="${ROOT_DIR}/scripts/with-timeout.sh"
REAL_ELIXIR="$(command -v elixir)"
FIXTURE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/stdlib-warning-gate.XXXXXX")"
FAKE_BIN="${FIXTURE_ROOT}/bin"
MIX_CALLS_LOG="${FIXTURE_ROOT}/mix-calls.log"
ELIXIR_CALLS_LOG="${FIXTURE_ROOT}/elixir-calls.log"
STRICT_LOG="${FIXTURE_ROOT}/strict.log"

cleanup() {
  rm -rf "${FIXTURE_ROOT}"
}
trap cleanup EXIT

mkdir -p "${FAKE_BIN}" "${FIXTURE_ROOT}/generated"

cat >"${FAKE_BIN}/mix" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${MIX_CALLS_LOG:?}"
EOF
chmod +x "${FAKE_BIN}/mix"

cat >"${FAKE_BIN}/elixir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${ELIXIR_CALLS_LOG:?}"
EOF
chmod +x "${FAKE_BIN}/elixir"

cat >"${FIXTURE_ROOT}/generated/clean.ex" <<'EOF'
defmodule CleanGeneratedFixture do
  def value, do: :ok
end
EOF

PATH="${FAKE_BIN}:${PATH}" \
  MIX_CALLS_LOG="${MIX_CALLS_LOG}" \
  ELIXIR_CALLS_LOG="${ELIXIR_CALLS_LOG}" \
  HAXE_EXUNIT_GENERATED_DIR="${FIXTURE_ROOT}/generated" \
  HEX_TIMEOUT_SECS=10 \
  DEPS_TIMEOUT_SECS=10 \
  COMPILE_TIMEOUT_SECS=10 \
  TEST_TIMEOUT_SECS=10 \
  bash "${ROOT_DIR}/scripts/test-haxe-exunit-stdlib.sh"

PATH="${FAKE_BIN}:${PATH}" \
  MIX_CALLS_LOG="${MIX_CALLS_LOG}" \
  ELIXIR_CALLS_LOG="${ELIXIR_CALLS_LOG}" \
  HAXE_EXUNIT_GENERATED_DIR="${FIXTURE_ROOT}/generated" \
  bash "${ROOT_DIR}/scripts/test-mix-fast.sh" --test-only

if [[ "$(grep -Fxc -- 'compile --force --warnings-as-errors --no-deps-check' "${MIX_CALLS_LOG}")" -ne 1 ]]; then
  echo "stdlib warning gate failed: the focused runner must force a strict Mix compile" >&2
  cat "${MIX_CALLS_LOG}" >&2
  exit 1
fi
grep -Fq 'test test/exunit/haxe_exunit_stdlib_runtime_test.exs --warnings-as-errors' "${MIX_CALLS_LOG}"
grep -Fqx 'test --warnings-as-errors --max-cases 1 --timeout 60000' "${MIX_CALLS_LOG}"
if [[ "$(grep -Fc -- 'validate-generated-elixir-warnings.exs' "${ELIXIR_CALLS_LOG}")" -ne 2 ]]; then
  echo "stdlib warning gate failed: both runners must validate generated Elixir warnings" >&2
  cat "${ELIXIR_CALLS_LOG}" >&2
  exit 1
fi

cat >"${FIXTURE_ROOT}/generated/generated_warning.ex" <<'EOF'
defmodule GeneratedWarningFixture do
  def value do
    unused = :warning
    :ok
  end
end
EOF

if ELIXIR_BIN="${REAL_ELIXIR}" \
  GENERATED_WARNING_TIMEOUT_SECS=60 \
  bash "${ROOT_DIR}/scripts/ci/validate-generated-elixir-warnings.sh" \
    "${FIXTURE_ROOT}/generated" >"${STRICT_LOG}" 2>&1; then
  echo "stdlib warning gate failed: the compiler accepted an intentional generated-file warning" >&2
  cat "${STRICT_LOG}" >&2
  exit 1
fi

if ! grep -Fq 'variable "unused" is unused' "${STRICT_LOG}"; then
  echo "stdlib warning gate failed: the expected generated-file warning was not reported" >&2
  cat "${STRICT_LOG}" >&2
  exit 1
fi

echo "stdlib warning gate passed"

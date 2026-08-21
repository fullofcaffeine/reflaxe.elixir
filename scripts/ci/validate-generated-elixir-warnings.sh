#!/usr/bin/env bash
set -euo pipefail

if (( $# != 1 )); then
  echo "Usage: scripts/ci/validate-generated-elixir-warnings.sh <generated-dir>" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="${ROOT_DIR}/scripts/with-timeout.sh"
GENERATED_DIR="$1"
MIX_ENV="${MIX_ENV:-test}"
BUILD_ROOT="${MIX_BUILD_ROOT:-${ROOT_DIR}/_build}"
ELIXIR_BIN="${ELIXIR_BIN:-$(command -v elixir)}"
VALIDATE_TIMEOUT_SECS="${GENERATED_WARNING_TIMEOUT_SECS:-120}"
BEAM_DIR="$(mktemp -d "${TMPDIR:-/tmp}/generated-warning-beam.XXXXXX")"

cleanup() {
  rm -rf "${BEAM_DIR}"
}
trap cleanup EXIT

if [[ ! -d "${GENERATED_DIR}" ]]; then
  echo "generated warning validation failed: missing directory: ${GENERATED_DIR}" >&2
  exit 1
fi

generated_files=()
while IFS= read -r generated_file; do
  generated_files+=("${generated_file}")
done < <(find "${GENERATED_DIR}" -type f -name '*.ex' -print | sort)

if (( ${#generated_files[@]} == 0 )); then
  echo "generated warning validation failed: no Elixir files in ${GENERATED_DIR}" >&2
  exit 1
fi

code_path_args=()
for ebin_dir in "${BUILD_ROOT}/${MIX_ENV}/lib/"*/ebin; do
  if [[ -d "${ebin_dir}" ]]; then
    code_path_args+=(-pa "${ebin_dir}")
  fi
done

"${TIMEOUT}" --secs "${VALIDATE_TIMEOUT_SECS}" --cwd "${ROOT_DIR}" -- \
  "${ELIXIR_BIN}" \
  "${code_path_args[@]}" \
  "${ROOT_DIR}/scripts/ci/validate-generated-elixir-warnings.exs" \
  "${BEAM_DIR}" \
  "${generated_files[@]}"

echo "generated Elixir warning validation passed (${#generated_files[@]} files)"

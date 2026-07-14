#!/usr/bin/env bash
set -euo pipefail

# Compile and execute the Haxe-authored local OTP contract on the active
# Elixir/Erlang toolchain. This lane is intentionally small enough to run on
# both the primary and minimum supported CI toolchains.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURE_DIR="${ROOT_DIR}/test/snapshot/otp/otp_core_runtime_contract"
OUT_DIR="${FIXTURE_DIR}/out"
WITH_TIMEOUT="${ROOT_DIR}/scripts/with-timeout.sh"
HAXE_BIN="${HAXE_BIN:-haxe}"
COMPILE_TIMEOUT_SECS="${COMPILE_TIMEOUT_SECS:-180}"
ELIXIR_COMPILE_TIMEOUT_SECS="${ELIXIR_COMPILE_TIMEOUT_SECS:-60}"
RUNTIME_TIMEOUT_SECS="${RUNTIME_TIMEOUT_SECS:-30}"

export HAXE_NO_SERVER="${HAXE_NO_SERVER:-1}"

beam_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${beam_dir}"
}
trap cleanup EXIT

echo "[otp-runtime] Compile Haxe contract"
"${WITH_TIMEOUT}" --secs "${COMPILE_TIMEOUT_SECS}" --cwd "${FIXTURE_DIR}" -- \
  "${HAXE_BIN}" -D no-traces -D reflaxe.dont_output_metadata_id compile.hxml

generated_files=()
while IFS= read -r file; do
  generated_files+=("${file}")
done < <(cd "${OUT_DIR}" && find . -type f -name '*.ex' -print | sed 's|^./||' | LC_ALL=C sort)

if [[ ! -f "${OUT_DIR}/main.ex" ]]; then
  echo "[otp-runtime] ERROR: compiler did not generate main.ex" >&2
  exit 1
fi

echo "[otp-runtime] Compile generated Elixir with warnings as errors"
"${WITH_TIMEOUT}" --secs "${ELIXIR_COMPILE_TIMEOUT_SECS}" --cwd "${OUT_DIR}" -- \
  elixirc --warnings-as-errors --ignore-module-conflict -o "${beam_dir}" "${generated_files[@]}"

echo "[otp-runtime] Execute local Process, Task, and Agent lifecycle checks"
"${WITH_TIMEOUT}" --secs "${RUNTIME_TIMEOUT_SECS}" --cwd "${OUT_DIR}" -- \
  elixir -pa "${beam_dir}" -e 'Main.main()'

echo "[otp-runtime] Local OTP contract passed"

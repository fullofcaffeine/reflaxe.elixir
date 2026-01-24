#!/usr/bin/env bash
set -euo pipefail

# Runtime smoke for a small, high-signal stdlib surface.
#
# WHY
# - Snapshot tests validate output shape, but some stdlib fixes (IO + exceptions) need
#   runtime validation on BEAM to ensure semantics match expectations.
#
# WHAT
# - Compiles a single snapshot (stdlib/haxe_io_bytes_streams)
# - Executes its `Main.main/0` in Elixir (fails fast on assertion throws)
#
# NOTE
# - This is intentionally tiny and bounded; it must never hang CI.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="${ROOT_DIR}/scripts/with-timeout.sh"
TEST_DIR="${ROOT_DIR}/test/snapshot/stdlib/haxe_io_bytes_streams"

if [[ ! -x "${TIMEOUT}" ]]; then
  echo "[runtime-smoke] ERROR: missing timeout wrapper: ${TIMEOUT}" >&2
  exit 2
fi

echo "[runtime-smoke] Compile snapshot: stdlib/haxe_io_bytes_streams"
"${TIMEOUT}" --secs 180 --cwd "${ROOT_DIR}" --echo -- make -C test test-stdlib__haxe_io_bytes_streams

echo "[runtime-smoke] Execute: Main.main/0"
"${TIMEOUT}" --secs 60 --cwd "${TEST_DIR}/out" --echo -- elixir -e '
  json = File.read!("_GeneratedFiles.json")

  # Load in the compiler-emitted order to avoid transient compile-time warnings from
  # requiring modules before their dependencies exist. Ensure `main.ex` is loaded
  # last so `Main` sees its dependencies (reduces noise in CI logs).
  files =
    Regex.scan(~r/"([^"]+\.ex)"/, json)
    |> Enum.map(fn [_, f] -> f end)

  files = Enum.reject(files, &(&1 == "main.ex")) ++ ["main.ex"]

  Enum.each(files, &Code.require_file/1)

  if function_exported?(Main, :main, 0) do
    Main.main()
  else
    raise "Main.main/0 not found"
  end
'

echo "[runtime-smoke] OK"

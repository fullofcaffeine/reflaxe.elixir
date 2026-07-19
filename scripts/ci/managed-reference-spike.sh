#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SPIKE_DIR="$ROOT_DIR/tools/managed_reference_spike"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
NODE_NAME="managed_ref_spike_${$}_$(date +%s)"

cleanup() {
  make -C "$SPIKE_DIR" clean >/dev/null 2>&1 || true
}
trap cleanup EXIT

log() {
  echo "[managed-reference-spike] $*"
}

log "platform=$(uname -s)-$(uname -m)"
elixir --version
erl -noshell -eval 'io:format("ERTS NIF ~p.~p~n", [erlang:system_info(nif_version), erlang:system_info(driver_version)]), halt().'
"${CC:-cc}" --version | sed -n '1,2p'

log "checking the explicit release-package boundary"
if grep -Eq 'copy_(dir|file)_to_(work|build)[[:space:]]+tools' \
  "$ROOT_DIR/scripts/release/package-haxelib.sh"; then
  echo "[managed-reference-spike] ERROR: tools/ entered the Haxelib package roots" >&2
  exit 1
fi
grep -F 'files: ~w(lib priv mix.exs README* LICENSE*)' "$ROOT_DIR/mix.exs" >/dev/null

log "checking scheduler and hot-takeover invariants"
grep -F '{"collect", 0, collect_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND}' \
  "$SPIKE_DIR/native/managed_reference_spike.c" >/dev/null
grep -F 'ErlNifResourceFlags flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;' \
  "$SPIKE_DIR/native/managed_reference_spike.c" >/dev/null

log "building the NIF from source"
"$TIMEOUT" --secs 60 -- make -C "$SPIKE_DIR" clean all

log "checking Elixir formatting"
"$TIMEOUT" --secs 60 -- bash -lc 'cd "$1" && mix format --check-formatted' _ "$SPIKE_DIR"

log "running lifecycle, graph, process, upgrade, and remote-node evidence"
"$TIMEOUT" --secs 120 -- bash -lc \
  'cd "$1" && MIX_ENV=test elixir --sname "$2" -S mix test --seed 0 --max-cases 1' \
  _ "$SPIKE_DIR" "$NODE_NAME"

log "PASS: experimental candidates compiled and passed without entering release packages"

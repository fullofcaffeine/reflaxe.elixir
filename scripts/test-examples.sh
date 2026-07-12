#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

HAXE_BIN="${HAXE_BIN:-haxe}"
LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/reflaxe-elixir-examples.XXXXXX")"
trap 'rm -f "$LOG_FILE"' EXIT

for dir in examples/*/; do
	echo "Testing $dir"
	build_file=""
	if [[ -f "${dir}compile-all.hxml" ]]; then
		build_file="compile-all.hxml"
	elif [[ -f "${dir}build.hxml" ]]; then
		build_file="build.hxml"
	else
		continue
	fi

	: > "$LOG_FILE"
	if ! (cd "$dir" && "$HAXE_BIN" "$build_file") 2>&1 | tee "$LOG_FILE"; then
		exit 1
	fi

	if rg -q --fixed-strings "Function information not found." "$LOG_FILE"; then
		echo "[examples] ERROR: Reflaxe could not extract typed function data while compiling $dir" >&2
		echo "[examples] Lazy field types added through filterTypes must be resolved before matching TFun." >&2
		exit 1
	fi
done

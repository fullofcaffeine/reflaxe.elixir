#!/usr/bin/env bash
set -euo pipefail

LOG_PATH="/tmp/passF-macro.log"

# Remove any prior log so each run is clearly separated.
rm -f "$LOG_PATH"

echo "[profile-passF] Running pass-F with hxx_pass_timing; log -> $LOG_PATH"
npx haxe -D hxx_pass_timing examples/todo-app/build-server-passF.hxml || true

if [ -f "$LOG_PATH" ]; then
  echo "[profile-passF] --- begin macro timing log ---"
  cat "$LOG_PATH"
  echo "[profile-passF] --- end macro timing log ---"
else
  echo "[profile-passF] No log file generated at $LOG_PATH"
fi

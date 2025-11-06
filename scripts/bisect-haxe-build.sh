#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../examples/todo-app"
# Clean minimal server output to avoid false positives
rm -rf lib >/dev/null 2>&1 || true
# Quiet build (bounded)
if timeout 60s haxe build-server.hxml >/dev/null 2>&1; then
  exit 0  # good
else
  exit 1  # bad
fi

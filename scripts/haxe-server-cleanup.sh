#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v pgrep >/dev/null 2>&1; then
  echo "[haxe-server-cleanup] error: pgrep not found" >&2
  exit 1
fi

if ! command -v kill >/dev/null 2>&1; then
  echo "[haxe-server-cleanup] error: kill not found" >&2
  exit 1
fi

have_rg=0
if command -v rg >/dev/null 2>&1; then
  have_rg=1
fi

ps_out="$(ps -axo pid= -o command=)"
matches="$(
  echo "${ps_out}" \
    | { if [[ "${have_rg}" == "1" ]]; then rg "haxe.*--wait"; else grep -E "haxe.*--wait"; fi; } \
    || true
)"
if [[ -z "${matches}" ]]; then
  echo "[haxe-server-cleanup] OK: no haxe --wait processes found"
  exit 0
fi

# Only consider repo-local Haxe servers (the node shim path contains ROOT_DIR).
# Exclude the todo-app client watcher (it runs: haxe build-client.hxml --wait <port>).
repo_pids="$(
  echo "${matches}" \
    | { if [[ "${have_rg}" == "1" ]]; then rg -F "${ROOT_DIR}"; else grep -F "${ROOT_DIR}"; fi; } \
    | { if [[ "${have_rg}" == "1" ]]; then rg -v "build-client\\.hxml"; else grep -v "build-client\\.hxml"; fi; } \
    | awk '{print $1}' \
    | tr '\n' ' '
)"

repo_pids="$(echo "${repo_pids}" | xargs echo -n || true)"
if [[ -z "${repo_pids}" ]]; then
  echo "[haxe-server-cleanup] OK: no repo-local haxe --wait servers found"
  exit 0
fi

echo "[haxe-server-cleanup] Found repo-local Haxe servers:"
echo "${matches}" \
  | { if [[ "${have_rg}" == "1" ]]; then rg -F "${ROOT_DIR}"; else grep -F "${ROOT_DIR}"; fi; } \
  | { if [[ "${have_rg}" == "1" ]]; then rg -v "build-client\\.hxml"; else grep -v "build-client\\.hxml"; fi; } \
  || true

kill_tree() {
  local pid="$1"
  if [[ -z "${pid}" ]]; then
    return 0
  fi

  # Depth-first: kill children before parent to reduce re-parenting races.
  local children
  children="$(pgrep -P "${pid}" || true)"
  if [[ -n "${children}" ]]; then
    local child
    for child in ${children}; do
      kill_tree "${child}"
    done
  fi

  kill -TERM "${pid}" 2>/dev/null || true
}

for pid in ${repo_pids}; do
  kill_tree "${pid}"
done

sleep 0.2

remaining=""
for pid in ${repo_pids}; do
  if kill -0 "${pid}" 2>/dev/null; then
    remaining="${remaining} ${pid}"
  fi
done

remaining="$(echo "${remaining}" | xargs echo -n || true)"
if [[ -n "${remaining}" ]]; then
  echo "[haxe-server-cleanup] Forcing remaining PIDs: ${remaining}"
  kill -KILL ${remaining} 2>/dev/null || true
fi

echo "[haxe-server-cleanup] DONE"

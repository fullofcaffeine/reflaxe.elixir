#!/usr/bin/env bash
set -euo pipefail

# Stops Haxe compilation servers owned by one repository. Ownership is derived
# from either the launcher command or the process working directory, because a
# surviving native child no longer contains the Node/Lix launcher path that
# originally tied it to the project.
ROOT_DIR_RAW="${HAXE_SERVER_CLEANUP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT_DIR="$(cd "$ROOT_DIR_RAW" && pwd -P)"

if ! command -v pgrep >/dev/null 2>&1; then
  echo "[haxe-server-cleanup] error: pgrep not found" >&2
  exit 1
fi

collect_candidates() {
  local snapshot=""
  snapshot="$(ps -axo pid=,command=)"
  printf '%s\n' "$snapshot" | awk '
    {
      pid = $1
      $1 = ""
      command = substr($0, 2)
      if (index(tolower(command), "haxe") == 0)
        next
      for (i = 1; i < NF; i++) {
        if ($i == "--wait") {
          printf "%s\t%s\n", pid, command
          break
        }
      }
    }
  '
}

collect_cwd_map() {
  local candidate_pids="$1"
  local pid=""
  if [[ -z "$candidate_pids" ]]; then
    return 0
  fi

  if [[ -d /proc ]]; then
    while IFS= read -r pid; do
      [[ -n "$pid" ]] || continue
      if [[ -e "/proc/$pid/cwd" ]]; then
        printf '%s\t%s\n' "$pid" "$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
      fi
    done <<<"$candidate_pids"
    return 0
  fi

  if command -v lsof >/dev/null 2>&1; then
    local csv=""
    csv="$(printf '%s\n' "$candidate_pids" | paste -sd, -)"
    lsof -a -d cwd -p "$csv" -Fn 2>/dev/null | awk '
      /^p[0-9]+$/ { pid = substr($0, 2); next }
      /^n/ && pid != "" { printf "%s\t%s\n", pid, substr($0, 2) }
    ' || true
  fi
}

select_repo_processes() {
  local candidates="$1"
  local candidate_pids=""
  local cwd_map=""
  candidate_pids="$(printf '%s\n' "$candidates" | awk -F '\t' 'NF { print $1 }')"
  cwd_map="$(collect_cwd_map "$candidate_pids")"

  {
    printf '%s\n' "$cwd_map" | awk 'NF { print "C\t" $0 }'
    printf '%s\n' "$candidates" | awk 'NF { print "P\t" $0 }'
  } | awk -F '\t' -v root="$ROOT_DIR" '
    $1 == "C" {
      cwd[$2] = $3
      next
    }
    $1 == "P" {
      pid = $2
      command = $3
      if (command ~ /build-client[.]hxml/)
        next
      owned_by_command = index(command, root) > 0
      owned_by_cwd = cwd[pid] == root || index(cwd[pid], root "/") == 1
      if (owned_by_command || owned_by_cwd)
        printf "%s\t%s\t%s\n", pid, cwd[pid], command
    }
  '
}

process_running() {
  local pid="$1"
  local state=""
  if ! kill -0 "$pid" >/dev/null 2>&1; then
    return 1
  fi
  state="$(ps -o state= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
  [[ "$state" != Z* ]]
}

kill_tree() {
  local pid="$1"
  local child=""
  local children=""
  children="$(pgrep -P "$pid" 2>/dev/null || true)"
  for child in $children; do
    kill_tree "$child"
  done
  kill -TERM "$pid" 2>/dev/null || true
}

candidates="$(collect_candidates)"
repo_rows="$(select_repo_processes "$candidates")"
if [[ -z "$repo_rows" ]]; then
  echo "[haxe-server-cleanup] OK: no repo-local haxe --wait servers found"
  exit 0
fi

repo_pids=()
while IFS=$'\t' read -r pid _cwd _command; do
  [[ -n "$pid" ]] || continue
  repo_pids+=("$pid")
done <<<"$repo_rows"

echo "[haxe-server-cleanup] Found repo-local Haxe servers:"
printf '%s\n' "$repo_rows" | awk -F '\t' '{ printf "  pid=%s cwd=%s command=%s\n", $1, ($2 == "" ? "unknown" : $2), $3 }'

for pid in "${repo_pids[@]}"; do
  kill_tree "$pid"
done

for _attempt in 1 2 3 4 5 6 7 8 9 10; do
  remaining=()
  for pid in "${repo_pids[@]}"; do
    if process_running "$pid"; then
      remaining+=("$pid")
    fi
  done
  if [[ "${#remaining[@]}" -eq 0 ]]; then
    break
  fi
  repo_pids=("${remaining[@]}")
  sleep 0.1
done

remaining=()
for pid in "${repo_pids[@]}"; do
  if process_running "$pid"; then
    remaining+=("$pid")
  fi
done
if [[ "${#remaining[@]}" -gt 0 ]]; then
  echo "[haxe-server-cleanup] Forcing remaining PIDs: ${remaining[*]}"
  kill -KILL "${remaining[@]}" 2>/dev/null || true

  for _attempt in 1 2 3 4 5; do
    survivors=()
    for pid in "${remaining[@]}"; do
      if process_running "$pid"; then
        survivors+=("$pid")
      fi
    done
    if [[ "${#survivors[@]}" -eq 0 ]]; then
      break
    fi
    remaining=("${survivors[@]}")
    sleep 0.1
  done

  survivors=()
  for pid in "${remaining[@]}"; do
    if process_running "$pid"; then
      survivors+=("$pid")
    fi
  done
  if [[ "${#survivors[@]}" -gt 0 ]]; then
    echo "[haxe-server-cleanup] ERROR: server PIDs survived cleanup: ${survivors[*]}" >&2
    exit 1
  fi
fi

echo "[haxe-server-cleanup] DONE"

#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run-required-semantic-test.sh --name NAME --log FILE --metadata FILE -- COMMAND [ARG ...]

Run one required semantic test attempt. A failed attempt stays failed. If an
operator suspects infrastructure noise, rerun the CI job so the diagnostic
attempt has a separate run result, log, and GITHUB_RUN_ATTEMPT value.
EOF
}

name=""
log_file=""
metadata_file=""

while (( $# > 0 )); do
  case "$1" in
    --name)
      name="${2:-}"
      shift 2
      ;;
    --log)
      log_file="${2:-}"
      shift 2
      ;;
    --metadata)
      metadata_file="${2:-}"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$name" || -z "$log_file" || -z "$metadata_file" || $# -eq 0 ]]; then
  usage >&2
  exit 2
fi

mkdir -p "$(dirname "$log_file")" "$(dirname "$metadata_file")"
: >"$log_file"

started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat >"$metadata_file" <<EOF
name=$name
classification=semantic
attempt_count=1
ci_run_id=${GITHUB_RUN_ID:-local}
ci_run_attempt=${GITHUB_RUN_ATTEMPT:-1}
runner_os=${RUNNER_OS:-$(uname -s)}
runner_arch=${RUNNER_ARCH:-$(uname -m)}
started_at=$started_at
EOF

echo "[required-test] $name: semantic attempt 1/1"
set +e
"$@" 2>&1 | tee "$log_file"
pipeline_status=("${PIPESTATUS[@]}")
command_status=${pipeline_status[0]}
tee_status=${pipeline_status[1]}
set -e

status="$command_status"
if (( tee_status != 0 )); then
  echo "[required-test] Could not preserve the test log (tee status $tee_status)." >&2
  status=70
fi

cat >>"$metadata_file" <<EOF
finished_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
command_status=$command_status
evidence_status=$tee_status
result_status=$status
EOF

if (( status != 0 )); then
  echo "[required-test] $name failed (status $status). Automatic semantic retries are disabled." >&2
  echo "[required-test] Rerun the failed CI job only for diagnosis; the original run remains failed." >&2
fi

exit "$status"

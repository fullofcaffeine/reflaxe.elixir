#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
runner="$repo_root/scripts/ci/run-required-semantic-test.sh"
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/required-semantic-test.XXXXXX")

cleanup() {
  rm -rf -- "$tmp_dir"
}
trap cleanup EXIT INT TERM

success_counter="$tmp_dir/success-counter"
"$runner" \
  --name "success fixture" \
  --log "$tmp_dir/success.log" \
  --metadata "$tmp_dir/success.meta" \
  -- bash -c 'echo success-output; echo run >>"$1"' _ "$success_counter"

[[ "$(wc -l <"$success_counter" | tr -d ' ')" == "1" ]]
grep -Fq "success-output" "$tmp_dir/success.log"
grep -Fq "attempt_count=1" "$tmp_dir/success.meta"
grep -Fq "result_status=0" "$tmp_dir/success.meta"

failure_counter="$tmp_dir/failure-counter"
set +e
"$runner" \
  --name "failure fixture" \
  --log "$tmp_dir/failure.log" \
  --metadata "$tmp_dir/failure.meta" \
  -- bash -c 'echo failure-output; echo run >>"$1"; exit 7' _ "$failure_counter"
failure_status=$?
set -e

[[ "$failure_status" == "7" ]]
[[ "$(wc -l <"$failure_counter" | tr -d ' ')" == "1" ]]
grep -Fq "failure-output" "$tmp_dir/failure.log"
grep -Fq "command_status=7" "$tmp_dir/failure.meta"
grep -Fq "result_status=7" "$tmp_dir/failure.meta"

# A diagnostic retry is a separate invocation. Its success cannot modify the
# first invocation's status or evidence.
GITHUB_RUN_ID=fixture GITHUB_RUN_ATTEMPT=2 \
  "$runner" \
    --name "diagnostic fixture" \
    --log "$tmp_dir/diagnostic.log" \
    --metadata "$tmp_dir/diagnostic.meta" \
    -- bash -c 'echo diagnostic-output'

grep -Fq "result_status=7" "$tmp_dir/failure.meta"
grep -Fq "ci_run_attempt=2" "$tmp_dir/diagnostic.meta"
grep -Fq "result_status=0" "$tmp_dir/diagnostic.meta"

echo "Required semantic test policy passed"

#!/usr/bin/env python3
"""Produce a bounded, deterministic-shape pass count/timing report."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
BASELINE_PATH = ROOT / "docs/05-architecture/PASS_REGISTRY_BASELINE.json"
PASS_LINE = re.compile(
    r"^\[PassTiming\] module=(?P<module>\S+) index=(?P<index>\d+) "
    r"registry_index=(?P<registry_index>\d+) name=(?P<name>\S+) "
    r"ms=(?P<ms>\d+(?:\.\d+)?)$"
)
SUMMARY_LINE = re.compile(
    r"^\[PassTimingSummary\] module=(?P<module>\S+) "
    r"passes=(?P<passes>\d+) skipped=(?P<skipped>\d+) "
    r"registry_passes=(?P<registry_passes>\d+) "
    r"total_ms=(?P<ms>\d+(?:\.\d+)?)$"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--write-baseline",
        action="store_true",
        help="Record current reference timings and slowest passes in the checked-in baseline.",
    )
    parser.add_argument(
        "--scenario",
        action="append",
        default=[],
        help="Run only the named scope (repeatable).",
    )
    parser.add_argument("--json-output", help="Write the current report to this path.")
    return parser.parse_args()


def command_output(command: list[str]) -> str:
    result = subprocess.run(
        command,
        cwd=ROOT,
        env={**os.environ, "HAXE_NO_SERVER": "1"},
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if result.returncode != 0:
        tail = "\n".join(result.stdout.splitlines()[-80:])
        raise RuntimeError(f"command failed ({result.returncode}): {' '.join(command)}\n{tail}")
    return result.stdout


def profile_scenario(
    profile: dict,
    effective_pass_count: int,
    max_records: int,
    update_counts: bool,
) -> dict:
    with tempfile.TemporaryDirectory(prefix="reflaxe-pass-inventory-") as temp_dir:
        log_path = Path(temp_dir) / "passes.log"
        command = [
            str(ROOT / "scripts/with-timeout.sh"),
            "--secs",
            "240",
            "--cwd",
            profile["fixture"],
            "--",
            os.environ.get("HAXE_BIN", "haxe"),
            "compile.hxml",
            "-D",
            "hxx_granular_pass_registry",
            "-D",
            "profile_passes",
            "-D",
            f"hxx_pass_timing_module_filter={profile['module']}",
            "-D",
            f"hxx_pass_timing_output={log_path}",
        ]
        command_output(command)
        if not log_path.exists():
            raise RuntimeError(f"profile log was not created for {profile['scope']}")
        lines = log_path.read_text(encoding="utf-8").splitlines()

    if len(lines) > max_records:
        raise RuntimeError(
            f"{profile['scope']} emitted {len(lines)} records; bounded maximum is {max_records}"
        )

    pass_rows: list[dict] = []
    summary: dict | None = None
    for line in lines:
        pass_match = PASS_LINE.match(line)
        if pass_match:
            pass_rows.append(
                {
                    "index": int(pass_match.group("index")),
                    "registryIndex": int(pass_match.group("registry_index")),
                    "name": pass_match.group("name"),
                    "ms": float(pass_match.group("ms")),
                }
            )
            continue
        summary_match = SUMMARY_LINE.match(line)
        if summary_match:
            if summary is not None:
                raise RuntimeError(f"multiple timing summaries for {profile['scope']}")
            summary = {
                "module": summary_match.group("module"),
                "passCount": int(summary_match.group("passes")),
                "skippedCount": int(summary_match.group("skipped")),
                "registryPassCount": int(summary_match.group("registry_passes")),
                "totalMs": float(summary_match.group("ms")),
            }
            continue
        raise RuntimeError(f"unrecognized timing record for {profile['scope']}: {line}")

    if summary is None:
        raise RuntimeError(f"missing timing summary for {profile['scope']}")
    if summary["module"] != profile["module"]:
        raise RuntimeError(
            f"{profile['scope']} expected module {profile['module']}, got {summary['module']}"
        )
    if summary["registryPassCount"] != effective_pass_count:
        raise RuntimeError(
            f"{profile['scope']} expected {effective_pass_count} registry passes, got "
            f"{summary['registryPassCount']}"
        )
    if summary["passCount"] + summary["skippedCount"] != summary["registryPassCount"]:
        raise RuntimeError(
            f"{profile['scope']} executed + skipped does not equal the registry count"
        )
    if len(pass_rows) != summary["passCount"]:
        raise RuntimeError(
            f"{profile['scope']} summary reports {summary['passCount']} executed passes, "
            f"but the log contains {len(pass_rows)} pass records"
        )

    expected_indexes = list(range(1, summary["passCount"] + 1))
    actual_indexes = [row["index"] for row in pass_rows]
    if actual_indexes != expected_indexes:
        raise RuntimeError(f"{profile['scope']} pass indexes are not deterministic and contiguous")
    registry_indexes = [row["registryIndex"] for row in pass_rows]
    if registry_indexes != sorted(set(registry_indexes)):
        raise RuntimeError(f"{profile['scope']} registry indexes are not unique and ascending")
    if registry_indexes and (
        registry_indexes[0] < 1 or registry_indexes[-1] > summary["registryPassCount"]
    ):
        raise RuntimeError(f"{profile['scope']} registry index is outside the registry bounds")

    if not update_counts:
        expected_passes = profile.get("expectedPassCount", effective_pass_count)
        expected_skipped = profile.get(
            "expectedSkippedCount", effective_pass_count - expected_passes
        )
        if (
            summary["passCount"] != expected_passes
            or summary["skippedCount"] != expected_skipped
        ):
            raise RuntimeError(
                f"{profile['scope']} expected executed/skipped "
                f"{expected_passes}/{expected_skipped}, got "
                f"{summary['passCount']}/{summary['skippedCount']}"
            )

    slowest = sorted(pass_rows, key=lambda row: (-row["ms"], row["name"]))[:5]
    return {
        "scope": profile["scope"],
        "fixture": profile["fixture"],
        "module": profile["module"],
        "passCount": summary["passCount"],
        "skippedCount": summary["skippedCount"],
        "registryPassCount": summary["registryPassCount"],
        "recordCount": len(lines),
        "totalMs": summary["totalMs"],
        "slowestPasses": [{"name": row["name"], "ms": row["ms"]} for row in slowest],
    }


def main() -> int:
    args = parse_args()
    baseline = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    requested = set(args.scenario)
    profiles = [
        profile
        for profile in baseline["profiles"]
        if not requested or profile["scope"] in requested
    ]
    unknown = requested - {profile["scope"] for profile in baseline["profiles"]}
    if unknown:
        raise RuntimeError(f"unknown scenarios: {', '.join(sorted(unknown))}")

    results = [
        profile_scenario(
            profile,
            baseline["effectivePassCount"],
            baseline["maxRecordsPerModule"],
            args.write_baseline,
        )
        for profile in profiles
    ]
    report = {
        "schemaVersion": 2,
        "mode": baseline["mode"],
        "toolchain": command_output([os.environ.get("HAXE_BIN", "haxe"), "--version"]).strip(),
        "profiles": results,
    }

    print("scope\tmodule\texecuted\tskipped\tregistry\trecords\ttotal_ms")
    for result in results:
        print(
            f"{result['scope']}\t{result['module']}\t{result['passCount']}\t"
            f"{result['skippedCount']}\t{result['registryPassCount']}\t"
            f"{result['recordCount']}\t{result['totalMs']:.2f}"
        )

    if args.json_output:
        output_path = Path(args.json_output)
        if not output_path.is_absolute():
            output_path = ROOT / output_path
        output_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    if args.write_baseline:
        by_scope = {result["scope"]: result for result in results}
        baseline["schemaVersion"] = 2
        baseline["mode"] = "granular-scoped"
        baseline["toolchain"] = f"Haxe {report['toolchain']}"
        for profile in baseline["profiles"]:
            result = by_scope.get(profile["scope"])
            if result is None:
                continue
            profile["expectedPassCount"] = result["passCount"]
            profile["expectedSkippedCount"] = result["skippedCount"]
            profile["referenceTotalMs"] = result["totalMs"]
            profile["referenceSlowestPasses"] = result["slowestPasses"]
        BASELINE_PATH.write_text(json.dumps(baseline, indent=2) + "\n", encoding="utf-8")
        print(f"[pass-inventory] wrote {BASELINE_PATH.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

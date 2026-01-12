#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate repo hygiene JSON report for CI.")
    parser.add_argument("--in", dest="input_path", required=True, help="Path to dead-code-audit.json")
    parser.add_argument("--out", dest="output_path", required=True, help="Path to write hygiene-summary.md")
    args = parser.parse_args()

    report = json.loads(Path(args.input_path).read_text(encoding="utf-8"))
    counts = report.get("counts", {})

    debug_only = int(counts.get("debug_only_markers", 0) or 0)
    commented = int(counts.get("commented_out_trace", 0) or 0)
    unused = int(counts.get("unused_haxe_types", 0) or 0)

    print(
        f"[repo-hygiene] counts: debug_only={debug_only} commented_out_trace={commented} unused_haxe_types={unused}"
    )

    summary = "\n".join(
        [
            "### Repo Hygiene (dead-code audit)",
            f"- `DEBUG ONLY` markers: **{debug_only}**",
            f"- Commented-out trace/log lines: {commented}",
            f"- Unused Haxe type candidates: {unused}",
            "",
        ]
    )
    Path(args.output_path).write_text(summary, encoding="utf-8")

    if debug_only > 0:
        print("[repo-hygiene] ERROR: Found DEBUG ONLY markers; please remove before merging.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


#!/usr/bin/env python3
"""Compare transparent groups, direct granular execution, and all-pass output."""

from __future__ import annotations

import argparse
import difflib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
BASELINE_PATH = ROOT / "docs/05-architecture/PASS_REGISTRY_BASELINE.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--scenario",
        action="append",
        default=[],
        help="Compare only the named scope (repeatable).",
    )
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


def compile_fixture(profile: dict, *, granular: bool, all_passes: bool) -> None:
    command = [
        str(ROOT / "scripts/with-timeout.sh"),
        "--secs",
        "240",
        "--cwd",
        profile["fixture"],
        "--",
        os.environ.get("HAXE_BIN", "haxe"),
        "compile.hxml",
    ]
    if granular:
        command.extend(["-D", "hxx_granular_pass_registry"])
    if all_passes:
        command.extend(["-D", "reflaxe_elixir_disable_pass_scopes"])
    command_output(command)


def output_files(root: Path) -> list[Path]:
    return sorted(path.relative_to(root) for path in root.rglob("*") if path.is_file())


def text_diff(
    relative: Path,
    left_label: str,
    left_bytes: bytes,
    right_label: str,
    right_bytes: bytes,
) -> str:
    try:
        left = left_bytes.decode("utf-8").splitlines()
        right = right_bytes.decode("utf-8").splitlines()
    except UnicodeDecodeError:
        return "binary content differs"
    lines = list(
        difflib.unified_diff(
            left,
            right,
            fromfile=f"{left_label}/{relative}",
            tofile=f"{right_label}/{relative}",
            lineterm="",
        )
    )
    return "\n".join(lines[:80])


def compare_trees(
    profile: dict,
    left_label: str,
    left: Path,
    right_label: str,
    right: Path,
) -> None:
    left_files = output_files(left)
    right_files = output_files(right)
    if left_files != right_files:
        left_only = sorted(set(left_files) - set(right_files))
        right_only = sorted(set(right_files) - set(left_files))
        raise RuntimeError(
            f"{profile['scope']} generated a different file set\n"
            f"{left_label} only: {', '.join(map(str, left_only)) or '(none)'}\n"
            f"{right_label} only: {', '.join(map(str, right_only)) or '(none)'}"
        )

    for relative in left_files:
        left_bytes = (left / relative).read_bytes()
        right_bytes = (right / relative).read_bytes()
        if left_bytes != right_bytes:
            detail = text_diff(
                relative,
                left_label,
                left_bytes,
                right_label,
                right_bytes,
            )
            raise RuntimeError(
                f"{profile['scope']} differs between {left_label} and "
                f"{right_label} at {relative}\n{detail}"
            )


def compare_profile(profile: dict) -> int:
    fixture = (ROOT / profile["fixture"]).resolve()
    if ROOT not in fixture.parents:
        raise RuntimeError(f"fixture is outside the repository: {fixture}")
    output = fixture / profile.get("output", "out")

    with tempfile.TemporaryDirectory(prefix="reflaxe-pass-scope-parity-") as temp_dir:
        temp = Path(temp_dir)
        original = temp / "original"
        grouped_scoped = temp / "grouped-scoped"
        granular_scoped = temp / "granular-scoped"
        granular_all = temp / "granular-all"
        had_original = output.exists()
        if had_original:
            shutil.copytree(output, original)

        try:
            shutil.rmtree(output, ignore_errors=True)
            compile_fixture(profile, granular=False, all_passes=False)
            if not output.is_dir():
                raise RuntimeError(f"transparent-group compile did not create {output}")
            shutil.copytree(output, grouped_scoped)

            shutil.rmtree(output)
            compile_fixture(profile, granular=True, all_passes=False)
            if not output.is_dir():
                raise RuntimeError(f"direct granular compile did not create {output}")
            shutil.copytree(output, granular_scoped)
            compare_trees(
                profile,
                "grouped-scoped",
                grouped_scoped,
                "granular-scoped",
                granular_scoped,
            )

            shutil.rmtree(output)
            compile_fixture(profile, granular=True, all_passes=True)
            if not output.is_dir():
                raise RuntimeError(f"all-pass compile did not create {output}")
            shutil.copytree(output, granular_all)
            compare_trees(
                profile,
                "granular-scoped",
                granular_scoped,
                "granular-all",
                granular_all,
            )
            return len(output_files(grouped_scoped))
        finally:
            shutil.rmtree(output, ignore_errors=True)
            if had_original:
                shutil.copytree(original, output)


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

    print("scope\tmodule\tgenerated_files\tgrouped/granular\tscoped/all-pass")
    for profile in profiles:
        file_count = compare_profile(profile)
        print(
            f"{profile['scope']}\t{profile['module']}\t{file_count}\t"
            "byte-identical\tbyte-identical"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

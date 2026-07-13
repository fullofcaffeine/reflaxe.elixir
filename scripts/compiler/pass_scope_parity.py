#!/usr/bin/env python3
"""Compare scoped pass execution with the legacy all-pass pipeline byte-for-byte."""

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


def compile_fixture(profile: dict, legacy_all_passes: bool) -> None:
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
    ]
    if legacy_all_passes:
        command.extend(["-D", "reflaxe_elixir_disable_pass_scopes"])
    command_output(command)


def output_files(root: Path) -> list[Path]:
    return sorted(path.relative_to(root) for path in root.rglob("*") if path.is_file())


def text_diff(relative: Path, legacy_bytes: bytes, scoped_bytes: bytes) -> str:
    try:
        legacy = legacy_bytes.decode("utf-8").splitlines()
        scoped = scoped_bytes.decode("utf-8").splitlines()
    except UnicodeDecodeError:
        return "binary content differs"
    lines = list(
        difflib.unified_diff(
            legacy,
            scoped,
            fromfile=f"legacy/{relative}",
            tofile=f"scoped/{relative}",
            lineterm="",
        )
    )
    return "\n".join(lines[:80])


def compare_trees(profile: dict, legacy: Path, scoped: Path) -> None:
    legacy_files = output_files(legacy)
    scoped_files = output_files(scoped)
    if legacy_files != scoped_files:
        legacy_only = sorted(set(legacy_files) - set(scoped_files))
        scoped_only = sorted(set(scoped_files) - set(legacy_files))
        raise RuntimeError(
            f"{profile['scope']} generated a different file set\n"
            f"legacy only: {', '.join(map(str, legacy_only)) or '(none)'}\n"
            f"scoped only: {', '.join(map(str, scoped_only)) or '(none)'}"
        )

    for relative in legacy_files:
        legacy_bytes = (legacy / relative).read_bytes()
        scoped_bytes = (scoped / relative).read_bytes()
        if legacy_bytes != scoped_bytes:
            detail = text_diff(relative, legacy_bytes, scoped_bytes)
            raise RuntimeError(
                f"{profile['scope']} differs at {relative}\n{detail}"
            )


def compare_profile(profile: dict) -> int:
    fixture = (ROOT / profile["fixture"]).resolve()
    if ROOT not in fixture.parents:
        raise RuntimeError(f"fixture is outside the repository: {fixture}")
    output = fixture / profile.get("output", "out")

    with tempfile.TemporaryDirectory(prefix="reflaxe-pass-scope-parity-") as temp_dir:
        temp = Path(temp_dir)
        original = temp / "original"
        legacy = temp / "legacy"
        scoped = temp / "scoped"
        had_original = output.exists()
        if had_original:
            shutil.copytree(output, original)

        try:
            shutil.rmtree(output, ignore_errors=True)
            compile_fixture(profile, legacy_all_passes=True)
            if not output.is_dir():
                raise RuntimeError(f"legacy compile did not create {output}")
            shutil.copytree(output, legacy)

            shutil.rmtree(output)
            compile_fixture(profile, legacy_all_passes=False)
            if not output.is_dir():
                raise RuntimeError(f"scoped compile did not create {output}")
            shutil.copytree(output, scoped)
            compare_trees(profile, legacy, scoped)
            return len(output_files(scoped))
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

    print("scope\tmodule\tgenerated_files\tparity")
    for profile in profiles:
        file_count = compare_profile(profile)
        print(f"{profile['scope']}\t{profile['module']}\t{file_count}\tbyte-identical")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

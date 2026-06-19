#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EXAMPLES_DIR = ROOT / "examples"
MANIFEST_PATH = EXAMPLES_DIR / "qa-manifest.json"

STRICT_ELIXIR_MODES = {"ci", "dedicated", "skipped"}
RUNTIME_MODES = {"compile-only", "mix-test", "sentinel", "sentinel-playwright", "manual"}


def fail(message: str) -> None:
    print(f"[examples-qa] ERROR: {message}", file=sys.stderr)
    sys.exit(1)


def load_manifest() -> dict:
    try:
        return json.loads(MANIFEST_PATH.read_text())
    except FileNotFoundError:
        fail(f"Missing manifest: {MANIFEST_PATH.relative_to(ROOT)}")
    except json.JSONDecodeError as error:
        fail(f"Invalid JSON in {MANIFEST_PATH.relative_to(ROOT)}: {error}")


def discover_examples() -> set[str]:
    examples = set()
    for path in EXAMPLES_DIR.iterdir():
        if not path.is_dir():
            continue
        if path.name.startswith("."):
            continue
        has_build = (path / "build.hxml").exists() or (path / "compile-all.hxml").exists()
        has_mix = (path / "mix.exs").exists()
        if has_build or has_mix:
            examples.add(path.name)
    return examples


def require_non_empty_text(example: str, section: str, field: str, value: object) -> None:
    if not isinstance(value, str) or not value.strip():
        fail(f"{example}.{section}.{field} must be a non-empty string")


def validate_evidence_paths(example: str, section_name: str, section: dict) -> None:
    evidence = section.get("evidence", [])
    if evidence is None:
        evidence = []
    if not isinstance(evidence, list):
        fail(f"{example}.{section_name}.evidence must be a list")

    for relative_path in evidence:
        require_non_empty_text(example, section_name, "evidence[]", relative_path)
        evidence_path = EXAMPLES_DIR / example / relative_path
        if not evidence_path.exists():
            fail(f"{example}.{section_name}.evidence path does not exist: {relative_path}")


def validate_manifest() -> dict:
    manifest = load_manifest()
    entries = manifest.get("examples")
    if not isinstance(entries, dict):
        fail("Manifest must contain an object field named examples")

    discovered = discover_examples()
    manifest_names = set(entries)
    missing = sorted(discovered - manifest_names)
    extra = sorted(manifest_names - discovered)

    if missing:
        fail("Missing examples in qa-manifest.json: " + ", ".join(missing))
    if extra:
        fail("qa-manifest.json contains unknown examples: " + ", ".join(extra))

    for example in sorted(manifest_names):
        entry = entries[example]
        if not isinstance(entry, dict):
            fail(f"{example} entry must be an object")

        compile_section = entry.get("compile")
        if not isinstance(compile_section, dict) or compile_section.get("required") is not True:
            fail(f"{example}.compile.required must be true")

        strict_elixir = entry.get("strictElixir")
        if not isinstance(strict_elixir, dict):
            fail(f"{example}.strictElixir must be an object")
        strict_mode = strict_elixir.get("mode")
        if strict_mode not in STRICT_ELIXIR_MODES:
            fail(f"{example}.strictElixir.mode must be one of {sorted(STRICT_ELIXIR_MODES)}")
        if strict_mode != "ci":
            require_non_empty_text(example, "strictElixir", "reason", strict_elixir.get("reason"))

        runtime = entry.get("runtime")
        if not isinstance(runtime, dict):
            fail(f"{example}.runtime must be an object")
        runtime_mode = runtime.get("mode")
        if runtime_mode not in RUNTIME_MODES:
            fail(f"{example}.runtime.mode must be one of {sorted(RUNTIME_MODES)}")

        if runtime_mode == "compile-only":
            require_non_empty_text(example, "runtime", "reason", runtime.get("reason"))
        else:
            require_non_empty_text(example, "runtime", "command", runtime.get("command"))
            if runtime.get("ci") is False:
                require_non_empty_text(example, "runtime", "reason", runtime.get("reason"))
            validate_evidence_paths(example, "runtime", runtime)

        e2e = entry.get("e2e")
        if e2e is not None:
            if not isinstance(e2e, dict):
                fail(f"{example}.e2e must be an object")
            e2e_mode = e2e.get("mode")
            if e2e_mode not in RUNTIME_MODES:
                fail(f"{example}.e2e.mode must be one of {sorted(RUNTIME_MODES)}")
            require_non_empty_text(example, "e2e", "command", e2e.get("command"))
            if e2e.get("ci") is False:
                require_non_empty_text(example, "e2e", "reason", e2e.get("reason"))
            validate_evidence_paths(example, "e2e", e2e)

    return manifest


def run_command(example: str, command: str, timeout_seconds: int) -> None:
    print(f"\n[examples-qa] == {example}: {command} ==")
    env = os.environ.copy()
    env["HAXE_NO_SERVER"] = env.get("HAXE_NO_SERVER", "1")

    # Run through with-timeout so a stuck Mix test fails quickly instead of holding CI.
    wrapped = [
        str(ROOT / "scripts" / "with-timeout.sh"),
        "--secs",
        str(timeout_seconds),
        "--cwd",
        str(EXAMPLES_DIR / example),
        "--",
        "bash",
        "-lc",
        command,
    ]
    subprocess.run(wrapped, cwd=ROOT, env=env, check=True)


def run_runtime_tests(manifest: dict) -> None:
    entries = manifest["examples"]
    selected = os.environ.get("EXAMPLES_QA_ONLY", "").split()
    skipped = set(os.environ.get("EXAMPLES_QA_SKIP", "").split())

    for example in sorted(entries):
        if selected and example not in selected:
            continue
        if example in skipped:
            print(f"[examples-qa] == {example}: skipped by EXAMPLES_QA_SKIP ==")
            continue

        runtime = entries[example]["runtime"]
        if runtime.get("ci") is not True:
            continue
        if runtime.get("mode") != "mix-test":
            continue

        timeout_seconds = int(runtime.get("timeoutSeconds", 600))
        run_command(example, runtime["command"], timeout_seconds)


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate and run example QA coverage.")
    parser.add_argument("command", choices=["guard", "run-runtime"])
    args = parser.parse_args()

    manifest = validate_manifest()
    if args.command == "guard":
        print("[examples-qa] Manifest covers all examples and test decisions.")
    elif args.command == "run-runtime":
        run_runtime_tests(manifest)
        print("\n[examples-qa] Runtime example tests passed.")


if __name__ == "__main__":
    main()

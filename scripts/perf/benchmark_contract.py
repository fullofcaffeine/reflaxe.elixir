#!/usr/bin/env python3
"""Shared, behavior-focused contracts for the compile and watch benchmarks.

The benchmark scripts deliberately use the word ``incremental`` only when they
can prove prior compiler work was reused.  This module keeps the scenario names
and deterministic A/B source edit identical across both harnesses.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
from typing import Any


SCHEMA_VERSION = 2
EDIT_MARKER = "// reflaxe-elixir benchmark variant B"


def source_variant(original: str, variant: str) -> str:
    """Return exact source variant A (original) or B (one added comment line).

    The added line changes real source bytes and positions while preserving the
    program's runtime behavior.  Reapplying either variant is idempotent, which
    makes alternating warm-server samples comparable and recoverable.
    """

    if variant not in {"A", "B"}:
        raise ValueError(f"unsupported benchmark source variant: {variant}")

    marker_suffix = f"\n{EDIT_MARKER}\n"
    base = original
    if base.endswith(marker_suffix):
        base = base[: -len(marker_suffix)]
    elif base.rstrip("\n").endswith(EDIT_MARKER):
        lines = base.splitlines(keepends=True)
        while lines and lines[-1].strip() == "":
            lines.pop()
        if lines and lines[-1].strip() == EDIT_MARKER:
            lines.pop()
        base = "".join(lines)

    if variant == "A":
        return base
    return base + marker_suffix


def write_source_variant(path: Path, variant: str) -> None:
    """Atomically apply a deterministic benchmark variant to ``path``."""

    updated = source_variant(path.read_text(encoding="utf-8"), variant)
    temporary = path.with_name(f"{path.name}.benchmark.tmp")
    temporary.write_text(updated, encoding="utf-8")
    temporary.replace(path)


def compile_scenario(name: str) -> dict[str, Any]:
    """Return explicit process/cache semantics for one compile scenario."""

    scenarios: dict[str, dict[str, Any]] = {
        "cold": {
            "process_model": "fresh_process_per_compile",
            "compiler_cache_state": "no_persistent_compiler_state",
            "artifact_cache_state": "generated_outputs_removed",
            "dependency_state": "dependency_cold",
            "edit_kind": "none",
            "public_api_changed": False,
            "demonstrated_incremental_reuse": False,
        },
        "warm_fresh_process": {
            "process_model": "fresh_process_per_compile",
            "compiler_cache_state": "no_persistent_compiler_state",
            "artifact_cache_state": "prior_outputs_and_build_artifacts_retained",
            "dependency_state": "dependencies_warm",
            "edit_kind": "none",
            "public_api_changed": False,
            "demonstrated_incremental_reuse": False,
        },
        "edited_full_fresh_process": {
            "process_model": "fresh_process_per_compile",
            "compiler_cache_state": "no_persistent_compiler_state",
            "artifact_cache_state": "prior_outputs_and_build_artifacts_retained",
            "dependency_state": "dependencies_warm",
            "edit_kind": "source_position_only_a_to_b",
            "public_api_changed": False,
            "demonstrated_incremental_reuse": False,
        },
    }
    if name not in scenarios:
        raise ValueError(f"unknown compile benchmark scenario: {name}")
    return dict(scenarios[name])


def watch_process_model(use_haxe_server: bool) -> dict[str, Any]:
    """Describe what remains alive between watch edit samples."""

    return {
        "process_model": "persistent_watch_with_haxe_server" if use_haxe_server else "persistent_watch_with_fresh_haxe_child",
        "compiler_cache_state": "haxe_server_process_retained" if use_haxe_server else "no_persistent_compiler_state",
        "artifact_cache_state": "prior_outputs_and_build_artifacts_retained",
        "dependency_state": "dependencies_warm",
        "demonstrated_incremental_reuse": False,
    }


def parse_server_identity(text: str) -> dict[str, Any]:
    """Read the server owner identity emitted by the lifecycle manager."""

    pattern = re.compile(r"Haxe server (?:relocated and )?started on port ([0-9]+) \(owner_os_pid=([0-9]+)\)")
    matches = pattern.findall(text)
    if not matches:
        return {
            "haxe_server_identity_observed": False,
            "haxe_server_port": None,
            "haxe_server_owner_os_pid": None,
        }
    port, owner_os_pid = matches[-1]
    return {
        "haxe_server_identity_observed": True,
        "haxe_server_port": int(port),
        "haxe_server_owner_os_pid": int(owner_os_pid),
    }


def generated_output_state(output_root: Path, previous_digests: dict[str, str]) -> tuple[dict[str, Any], dict[str, str]]:
    """Observe manifest-owned output without changing generated-file mtimes."""

    manifest = output_root / "_GeneratedFiles.json"
    try:
        manifest_data = json.loads(manifest.read_text(encoding="utf-8"))
    except FileNotFoundError:
        manifest_data = {}

    owned_digests = {
        record.get("path"): record.get("sha256")
        for record in manifest_data.get("ownedFiles", [])
        if isinstance(record, dict) and record.get("path") and record.get("sha256")
    }
    digests: dict[str, str] = {}
    sizes: dict[str, int] = {}
    for relative in sorted(manifest_data.get("filesGenerated", [])):
        path = Path(relative)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"unsafe generated path in benchmark manifest: {relative}")
        absolute = output_root / path
        if not absolute.is_file():
            continue
        content = absolute.read_bytes()
        digests[relative] = owned_digests.get(relative) or hashlib.sha256(content).hexdigest()
        sizes[relative] = len(content)

    changed_paths = sorted(
        path
        for path in set(previous_digests) | set(digests)
        if previous_digests.get(path) != digests.get(path)
    )
    tree = hashlib.sha256()
    for path in sorted(digests):
        tree.update(path.encode("utf-8"))
        tree.update(b"\0")
        tree.update(digests[path].encode("ascii"))
        tree.update(b"\n")
    return (
        {
            "generated_file_count": len(digests),
            "generated_bytes": sum(sizes.values()),
            "changed_file_count": len(changed_paths),
            "changed_bytes": sum(sizes.get(path, 0) for path in changed_paths),
            "changed_paths": changed_paths,
            "output_tree_sha256": tree.hexdigest(),
        },
        digests,
    )


def schema_classification(schema_version: int | None) -> str:
    """Classify historical results without reinterpreting their old labels."""

    if schema_version == SCHEMA_VERSION:
        return "current"
    if schema_version == 1:
        return "legacy_v1_ambiguous_incremental_label"
    return "unknown_schema"


def main() -> int:
    parser = argparse.ArgumentParser(description="Benchmark contract helpers")
    subparsers = parser.add_subparsers(dest="command", required=True)
    edit = subparsers.add_parser("apply-source-variant")
    edit.add_argument("--path", required=True)
    edit.add_argument("--variant", choices=("A", "B"), required=True)
    args = parser.parse_args()

    if args.command == "apply-source-variant":
        write_source_variant(Path(args.path), args.variant)
        return 0
    raise AssertionError(f"unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())

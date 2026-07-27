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
import os
from pathlib import Path
import re
import subprocess
from datetime import datetime, timezone
from typing import Any


SCHEMA_VERSION = 2
EDIT_MARKER = "// reflaxe-elixir benchmark variant B"
TARGET_TIMING_PREFIX = "REFLAXE_ELIXIR_TIMINGS "


def now_utc() -> str:
    """Return an ISO-8601 UTC timestamp suitable for benchmark artifacts."""

    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def host_load_observation() -> dict[str, Any]:
    """Capture enough host-load context to audit an idle/contended label.

    Load average is supporting evidence, not an automatic idle detector: its
    meaning varies with CPU count, operating system, and other background work.
    """

    return {
        "observed_at": now_utc(),
        "cpu_count": os.cpu_count(),
        "load_average": list(os.getloadavg()) if hasattr(os, "getloadavg") else None,
    }


def process_tree_rss_snapshot(root_pid: int | None) -> dict[str, Any] | None:
    """Return a post-build RSS snapshot for one process and its descendants.

    RSS (resident set size) is the memory currently held in physical memory.
    The snapshot is intentionally taken outside the timed rebuild interval. It
    helps reveal growth in a long-lived watcher or Haxe server, but it is not a
    peak-memory measurement for the compile that just completed.
    """

    if root_pid is None or root_pid <= 0:
        return None

    try:
        output = subprocess.check_output(
            ["ps", "-axo", "pid=,ppid=,rss="],
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None

    processes: dict[int, tuple[int, int]] = {}
    children: dict[int, list[int]] = {}
    for line in output.splitlines():
        fields = line.split()
        if len(fields) != 3:
            continue
        try:
            pid, parent_pid, rss_kib = (int(field) for field in fields)
        except ValueError:
            continue
        processes[pid] = (parent_pid, rss_kib)
        children.setdefault(parent_pid, []).append(pid)

    if root_pid not in processes:
        return None

    pending = [root_pid]
    observed: set[int] = set()
    rss_kib = 0
    while pending:
        pid = pending.pop()
        if pid in observed:
            continue
        observed.add(pid)
        rss_kib += processes.get(pid, (0, 0))[1]
        pending.extend(children.get(pid, []))

    return {
        "root_pid": root_pid,
        "process_count": len(observed),
        "rss_bytes": rss_kib * 1024,
    }


def target_timing_report(text: str) -> dict[str, Any] | None:
    """Return the last machine-readable Reflaxe target report in ``text``."""

    reports: list[dict[str, Any]] = []
    for line in text.splitlines():
        marker = line.find(TARGET_TIMING_PREFIX)
        if marker < 0:
            continue
        try:
            reports.append(json.loads(line[marker + len(TARGET_TIMING_PREFIX) :]))
        except json.JSONDecodeError:
            continue
    return reports[-1] if reports else None


def haxe_reported_total_ms(text: str) -> float | None:
    """Return the last ``--times`` total emitted by Haxe, converted to milliseconds."""

    pattern = re.compile(r"^total\s+\|\s*([0-9]+(?:\.[0-9]+)?)\s*\|", re.IGNORECASE)
    matches = []
    for line in text.splitlines():
        match = pattern.match(line.strip())
        if match:
            matches.append(float(match.group(1)) * 1000.0)
    return matches[-1] if matches else None


def haxe_integration_timing_report(text: str) -> dict[str, Any] | None:
    """Return the last timing block printed by the Mix/Haxe integration.

    This report measures the compilation request around the Haxe invocation. It
    includes work such as input fingerprinting and generated-file discovery,
    which Haxe's own ``--times`` table does not describe.
    """

    header_pattern = re.compile(r"^== Haxe timings: (.+) ==$")
    phase_pattern = re.compile(r"^\s{2}(.+?):\s*([0-9]+(?:\.[0-9]+)?)\s+ms$")
    reports: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None

    for line in text.splitlines():
        header = header_pattern.match(line.strip())
        if header:
            current = {"context": header.group(1), "phases": []}
            reports.append(current)
            continue
        if current is None:
            continue
        phase = phase_pattern.match(line)
        if phase:
            name = phase.group(1)
            duration_ms = float(phase.group(2))
            current["phases"].append({"name": name, "duration_ms": duration_ms})
            if name == "total wall":
                current["total_wall_ms"] = duration_ms
            continue
        if line.strip():
            current = None

    return reports[-1] if reports else None


def watch_phase_reconciliation(external_duration_ms: int, compiler_output: str) -> dict[str, Any] | None:
    """Connect one edit-to-success sample to its nested compiler measurements.

    The outer sample starts when the source file is changed and ends when the
    watcher reports success. The Mix/Haxe timing starts later, when compilation
    begins. Within that request, ``haxe.invoke`` surrounds both Haxe's own
    reported work and the Reflaxe target callback. Keeping both remainders
    explicit prevents the harness from silently assigning unknown time to the
    wrong layer. Haxe's ``--times`` total includes the Reflaxe target callback,
    so those two measurements must be treated as nested rather than added.
    """

    integration = haxe_integration_timing_report(compiler_output)
    target = target_timing_report(compiler_output)
    haxe_total = haxe_reported_total_ms(compiler_output)
    if integration is None and target is None and haxe_total is None:
        return None

    result: dict[str, Any] = {"external_edit_to_success_ms": external_duration_ms}
    if integration is not None:
        result["haxe_integration_timing"] = integration
        integration_total = integration.get("total_wall_ms")
        if isinstance(integration_total, (int, float)):
            result["outside_haxe_integration_ms"] = round(
                external_duration_ms - integration_total,
                3,
            )

        invoke_ms = next(
            (
                phase["duration_ms"]
                for phase in integration.get("phases", [])
                if phase.get("name") == "haxe.invoke"
            ),
            None,
        )
        if isinstance(invoke_ms, (int, float)):
            result["haxe_invoke_ms"] = invoke_ms
            target_total = target.get("total_wall_ms") if target is not None else None
            violations: list[str] = []
            if haxe_total is not None and haxe_total > invoke_ms:
                violations.append("haxe_reported_total_exceeds_haxe_invoke")
            if (
                haxe_total is not None
                and isinstance(target_total, (int, float))
                and target_total > haxe_total
            ):
                violations.append("reflaxe_target_total_exceeds_haxe_reported_total")
            elif (
                haxe_total is None
                and isinstance(target_total, (int, float))
                and target_total > invoke_ms
            ):
                violations.append("reflaxe_target_total_exceeds_haxe_invoke")

            if violations:
                result["timing_nesting_status"] = "inconsistent"
                result["timing_nesting_violations"] = violations
            elif haxe_total is not None and isinstance(target_total, (int, float)):
                haxe_excluding_target_ms = haxe_total - target_total
                invoke_unattributed_ms = invoke_ms - haxe_total
                result["timing_nesting_status"] = "consistent"
                result["haxe_reported_excluding_reflaxe_target_ms"] = round(
                    haxe_excluding_target_ms,
                    3,
                )
                result["haxe_invoke_unattributed_ms"] = round(
                    invoke_unattributed_ms,
                    3,
                )
                result["haxe_invoke_reconciled_ms"] = round(
                    target_total + haxe_excluding_target_ms + invoke_unattributed_ms,
                    3,
                )
            else:
                result["timing_nesting_status"] = "partial"
                known_nested_ms = haxe_total if haxe_total is not None else target_total
                if isinstance(known_nested_ms, (int, float)) and known_nested_ms <= invoke_ms:
                    result["haxe_invoke_unattributed_ms"] = round(
                        invoke_ms - known_nested_ms,
                        3,
                    )

    if haxe_total is not None:
        result["haxe_reported_total_ms"] = haxe_total
    if target is not None:
        target_total = target.get("total_wall_ms")
        if isinstance(target_total, (int, float)):
            result["reflaxe_target_total_ms"] = target_total

    return result


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


def patch_changed_paths(worktree: Path, patch_path: Path) -> list[str]:
    """Return the safe workspace-relative paths changed by a unified diff.

    ``git apply --numstat -z`` parses the standard patch format without
    changing the worktree. Rejecting absolute and parent-relative paths keeps a
    benchmark fixture from writing outside its isolated checkout.
    """

    try:
        output = subprocess.check_output(
            ["git", "apply", "--numstat", "-z", str(patch_path)],
            cwd=worktree,
            stderr=subprocess.STDOUT,
        )
    except subprocess.CalledProcessError as exc:
        detail = exc.output.decode("utf-8", errors="replace").strip()
        raise ValueError(f"cannot inspect benchmark patch {patch_path}: {detail}") from exc

    paths: list[str] = []
    for raw_record in output.split(b"\0"):
        if not raw_record:
            continue
        fields = raw_record.split(b"\t", 2)
        if len(fields) != 3:
            raise ValueError(f"unexpected git numstat record in benchmark patch: {raw_record!r}")
        relative = os.fsdecode(fields[2])
        path = Path(relative)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"unsafe path in benchmark patch: {relative}")
        paths.append(path.as_posix())

    if not paths:
        raise ValueError(f"benchmark patch changes no files: {patch_path}")
    return sorted(paths)


def apply_patch_variant(worktree: Path, patch_path: Path, variant: str) -> None:
    """Apply exact patch variant B or restore the baseline variant A.

    Variant B applies the patch. Variant A reverses it. ``--check`` runs first
    so a stale fixture fails without partially modifying the isolated checkout.
    """

    if variant not in {"A", "B"}:
        raise ValueError(f"unsupported benchmark patch variant: {variant}")

    direction = ["--reverse"] if variant == "A" else []
    check_command = ["git", "apply", *direction, "--check", str(patch_path)]
    apply_command = ["git", "apply", *direction, str(patch_path)]
    try:
        subprocess.run(
            check_command,
            cwd=worktree,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        subprocess.run(
            apply_command,
            cwd=worktree,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        detail = exc.stdout.strip()
        action = "restore variant A from" if variant == "A" else "apply variant B from"
        raise ValueError(f"cannot {action} benchmark patch {patch_path}: {detail}") from exc


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

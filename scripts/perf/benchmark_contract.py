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
import math
import os
from pathlib import Path
import re
import subprocess
from datetime import datetime, timezone
from typing import Any


SCHEMA_VERSION = 2
EDIT_MARKER = "// reflaxe-elixir benchmark variant B"
TARGET_TIMING_PREFIX = "REFLAXE_ELIXIR_TIMINGS "
TARGET_PARENT_PHASES = (
    "reflaxe_module_filters_and_init",
    "ast_pipeline_including_class_enum_construction",
    "output_iteration_including_passes_printing_maps",
    "output_transaction_including_formatting",
)


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


def reconcile_target_parent_phases(report: dict[str, Any]) -> dict[str, Any]:
    """Reconcile non-overlapping target lifecycle parents to target wall time.

    Child timings such as class construction, pass manager, and printer remain
    useful attribution within their parent spans, but they are deliberately not
    added again here.
    """

    def valid_duration(value: Any) -> bool:
        return (
            isinstance(value, (int, float))
            and not isinstance(value, bool)
            and math.isfinite(float(value))
            and value >= 0
        )

    total = report.get("total_wall_ms")
    phases = report.get("phases", [])
    if not isinstance(phases, list):
        return {
            "status": "inconsistent",
            "violations": ["target_phases_is_not_an_array"],
        }
    observed = {
        phase.get("name"): phase.get("durationMs")
        for phase in phases
        if isinstance(phase, dict)
    }
    if not valid_duration(total):
        return {
            "status": "inconsistent",
            "violations": ["target_total_is_not_a_nonnegative_duration"],
        }
    invalid = [
        name
        for name in TARGET_PARENT_PHASES
        if name in observed and not valid_duration(observed[name])
    ]
    if invalid:
        return {
            "status": "inconsistent",
            "invalid_parent_phases": invalid,
            "violations": ["target_parent_phase_is_not_a_nonnegative_duration"],
        }
    missing = [name for name in TARGET_PARENT_PHASES if name not in observed]
    if missing:
        return {
            "status": "partial",
            "missing_parent_phases": missing,
        }

    parent_total = sum(float(observed[name]) for name in TARGET_PARENT_PHASES)
    remainder = float(total) - parent_total
    if remainder < -1.0:
        return {
            "status": "inconsistent",
            "parent_phase_total_ms": round(parent_total, 3),
            "violations": ["target_parent_phases_exceed_target_wall_time"],
        }
    remainder = max(0.0, remainder)
    remainder_percent = 0.0 if total == 0 else remainder / float(total) * 100.0
    return {
        "status": "complete",
        "parent_phase_names": list(TARGET_PARENT_PHASES),
        "parent_phase_total_ms": round(parent_total, 3),
        "unattributed_target_ms": round(remainder, 3),
        "unattributed_target_percent": round(remainder_percent, 3),
        "reconciled_target_total_ms": round(float(total), 3),
    }


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


def reconcile_compiler_timer_relationship(
    outer_ms: float,
    haxe_reported_ms: float | None,
    reflaxe_target_ms: float | None,
    *,
    tolerance_ms: float = 1.0,
) -> dict[str, Any]:
    """Reconcile Haxe and Reflaxe measurements without assuming containment.

    Haxe's ``--times`` table can include the target callback in its ``macro``
    total or report only compiler work outside that callback. This helper tests
    those two candidate models against the measured outer interval. A unique
    fit supports arithmetic reconciliation under that model; durations alone
    do not prove physical timer topology or exclude partial overlap. If both
    candidates fit, the decomposition remains explicitly ambiguous instead of
    selecting the more convenient interpretation.
    """

    values = {
        "outer": outer_ms,
        "haxe_reported": haxe_reported_ms,
        "reflaxe_target": reflaxe_target_ms,
    }
    invalid = [
        name
        for name, value in values.items()
        if value is not None and (not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0)
    ]
    if invalid:
        return {
            "timing_reconciliation_status": "inconsistent",
            "timing_relationship": "unknown",
            "timing_relationship_violations": [f"{name}_is_not_a_nonnegative_finite_duration" for name in invalid],
        }

    def fits_within(value: float, limit: float) -> bool:
        return value <= limit + tolerance_ms

    known = [value for value in (haxe_reported_ms, reflaxe_target_ms) if value is not None]
    if len(known) < 2:
        if known and not fits_within(known[0], outer_ms):
            return {
                "timing_reconciliation_status": "inconsistent",
                "timing_relationship": "unknown",
                "timing_relationship_violations": ["known_compiler_total_exceeds_outer_measurement"],
            }
        result: dict[str, Any] = {
            "timing_reconciliation_status": "partial",
            "timing_relationship": "unknown",
        }
        if known:
            result["unattributed_after_known_ms"] = round(max(0.0, outer_ms - known[0]), 3)
        return result

    assert haxe_reported_ms is not None
    assert reflaxe_target_ms is not None
    nested_fits = fits_within(reflaxe_target_ms, haxe_reported_ms) and fits_within(haxe_reported_ms, outer_ms)
    disjoint_fits = fits_within(haxe_reported_ms + reflaxe_target_ms, outer_ms)

    if nested_fits and not disjoint_fits:
        haxe_excluding_target_ms = max(0.0, haxe_reported_ms - reflaxe_target_ms)
        unattributed_ms = max(0.0, outer_ms - haxe_reported_ms)
        component_total_ms = reflaxe_target_ms + haxe_excluding_target_ms + unattributed_ms
        result = {
            "timing_reconciliation_status": "complete",
            "timing_relationship": "reflaxe_target_nested_in_haxe_reported_total",
            "haxe_reported_excluding_reflaxe_target_ms": round(haxe_excluding_target_ms, 3),
            "unattributed_outer_ms": round(unattributed_ms, 3),
            "reconciled_outer_ms": round(outer_ms, 3),
        }
        rounding_adjustment_ms = outer_ms - component_total_ms
        if abs(rounding_adjustment_ms) >= 0.001:
            result["timer_rounding_adjustment_ms"] = round(rounding_adjustment_ms, 3)
        return result

    if disjoint_fits and not nested_fits:
        unattributed_ms = max(0.0, outer_ms - haxe_reported_ms - reflaxe_target_ms)
        component_total_ms = haxe_reported_ms + reflaxe_target_ms + unattributed_ms
        result = {
            "timing_reconciliation_status": "complete",
            "timing_relationship": "haxe_reported_total_and_reflaxe_target_disjoint",
            "haxe_reported_frontend_ms": round(haxe_reported_ms, 3),
            "unattributed_outer_ms": round(unattributed_ms, 3),
            "reconciled_outer_ms": round(outer_ms, 3),
        }
        rounding_adjustment_ms = outer_ms - component_total_ms
        if abs(rounding_adjustment_ms) >= 0.001:
            result["timer_rounding_adjustment_ms"] = round(rounding_adjustment_ms, 3)
        return result

    if nested_fits and disjoint_fits:
        return {
            "timing_reconciliation_status": "ambiguous",
            "timing_relationship": "nested_or_disjoint",
            "unattributed_outer_ms_range": {
                "min": round(max(0.0, outer_ms - haxe_reported_ms - reflaxe_target_ms), 3),
                "max": round(max(0.0, outer_ms - haxe_reported_ms), 3),
            },
        }

    violations = []
    if not fits_within(haxe_reported_ms, outer_ms):
        violations.append("haxe_reported_total_exceeds_outer_measurement")
    if not fits_within(reflaxe_target_ms, outer_ms):
        violations.append("reflaxe_target_total_exceeds_outer_measurement")
    if not violations:
        violations.append("compiler_totals_fit_neither_nested_nor_disjoint_model")
    return {
        "timing_reconciliation_status": "inconsistent",
        "timing_relationship": "unknown",
        "timing_relationship_violations": violations,
    }


def watch_phase_reconciliation(external_duration_ms: int, compiler_output: str) -> dict[str, Any] | None:
    """Connect one edit-to-success sample to its compiler measurements.

    The outer sample starts when the source file is changed and ends when the
    watcher reports success. The Mix/Haxe timing starts later, when compilation
    begins. Within that request, ``haxe.invoke`` surrounds Haxe's reported work
    and the Reflaxe target callback, but Haxe's ``--times`` total does not
    consistently include the callback. The shared reconciliation contract
    selects nested or disjoint only when exactly one of those two candidate
    models fits the observed durations.
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
            relationship = reconcile_compiler_timer_relationship(
                invoke_ms,
                haxe_total,
                target_total if isinstance(target_total, (int, float)) else None,
            )
            unattributed_ms = relationship.pop("unattributed_outer_ms", None)
            reconciled_ms = relationship.pop("reconciled_outer_ms", None)
            unattributed_range = relationship.pop("unattributed_outer_ms_range", None)
            partial_remainder_ms = relationship.pop("unattributed_after_known_ms", None)
            result.update(relationship)
            if unattributed_ms is not None:
                result["haxe_invoke_unattributed_ms"] = unattributed_ms
            if reconciled_ms is not None:
                result["haxe_invoke_reconciled_ms"] = reconciled_ms
            if unattributed_range is not None:
                result["haxe_invoke_unattributed_ms_range"] = unattributed_range
            if partial_remainder_ms is not None:
                result["haxe_invoke_remainder_after_known_timer_ms"] = partial_remainder_ms

    if haxe_total is not None:
        result["haxe_reported_total_ms"] = haxe_total
    if target is not None:
        target_total = target.get("total_wall_ms")
        if isinstance(target_total, (int, float)):
            result["reflaxe_target_total_ms"] = target_total
        result["reflaxe_target_phase_reconciliation"] = reconcile_target_parent_phases(target)

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
            **workload_classification("initial_build", False),
        },
        "warm_fresh_process": {
            "process_model": "fresh_process_per_compile",
            "compiler_cache_state": "no_persistent_compiler_state",
            "artifact_cache_state": "prior_outputs_and_build_artifacts_retained",
            "dependency_state": "dependencies_warm",
            "edit_kind": "none",
            "public_api_changed": False,
            **workload_classification("no_op", False),
        },
        "edited_full_fresh_process": {
            "process_model": "fresh_process_per_compile",
            "compiler_cache_state": "no_persistent_compiler_state",
            "artifact_cache_state": "prior_outputs_and_build_artifacts_retained",
            "dependency_state": "dependencies_warm",
            "edit_kind": "source_position_only_a_to_b",
            "public_api_changed": False,
            **workload_classification("edited", False),
        },
    }
    if name not in scenarios:
        raise ValueError(f"unknown compile benchmark scenario: {name}")
    return dict(scenarios[name])


def workload_classification(workload_change: str, demonstrated_incremental_reuse: bool) -> dict[str, Any]:
    """Classify source change and reuse as independent, executable facts."""

    if workload_change not in {"initial_build", "no_op", "edited"}:
        raise ValueError(f"unknown benchmark workload change: {workload_change}")
    if not isinstance(demonstrated_incremental_reuse, bool):
        raise ValueError("demonstrated incremental reuse must be boolean")
    if workload_change == "initial_build" and demonstrated_incremental_reuse:
        raise ValueError("an initial build cannot demonstrate reuse of a prior compilation")
    return {
        "workload_change": workload_change,
        "reuse_classification": (
            "demonstrated_incremental_reuse"
            if demonstrated_incremental_reuse
            else "incremental_reuse_not_demonstrated"
        ),
        "demonstrated_incremental_reuse": demonstrated_incremental_reuse,
    }


def watch_process_model(use_haxe_server: bool, edit_kind: str = "edited") -> dict[str, Any]:
    """Describe what remains alive between watch edit samples."""

    return {
        "process_model": "persistent_watch_with_haxe_server" if use_haxe_server else "persistent_watch_with_fresh_haxe_child",
        "compiler_cache_state": "haxe_server_process_retained" if use_haxe_server else "no_persistent_compiler_state",
        "artifact_cache_state": "prior_outputs_and_build_artifacts_retained",
        "dependency_state": "dependencies_warm",
        **workload_classification("no_op" if edit_kind == "none" else "edited", False),
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
        content_digest = hashlib.sha256(content).hexdigest()
        manifest_digest = owned_digests.get(relative)
        if manifest_digest is not None and manifest_digest != content_digest:
            raise ValueError(
                f"generated manifest digest does not match file bytes: {relative}"
            )
        digests[relative] = content_digest
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


def compare_watch_output_results(direct: dict[str, Any], server: dict[str, Any]) -> dict[str, Any]:
    """Verify that paired direct/server watch runs generated identical output.

    Each source variant must be internally stable in both modes and then match
    its peer mode exactly. Timing is deliberately excluded: hosted-runner
    latency may be noisy, while generated-output parity is a correctness
    contract.
    """

    errors: list[str] = []
    direct_config = direct.get("config", {})
    server_config = server.get("config", {})
    direct_repo = direct.get("repo", {})
    server_repo = server.get("repo", {})

    if direct.get("status") != "success":
        errors.append("direct run did not succeed")
    if server.get("status") != "success":
        errors.append("server run did not succeed")
    if direct_config.get("use_haxe_server") is not False:
        errors.append("direct result is not labeled as direct mode")
    if server_config.get("use_haxe_server") is not True:
        errors.append("server result is not labeled as Haxe-server mode")
    if server.get("processes", {}).get("haxe_server_identity_observed") is not True:
        errors.append("server result did not observe a persistent Haxe-server identity")

    comparable_fields = (
        ("benchmark head", direct_repo.get("benchmark_head"), server_repo.get("benchmark_head")),
        ("edit kind", direct_config.get("edit_kind"), server_config.get("edit_kind")),
        ("edit patch", direct_config.get("edit_patch_sha256"), server_config.get("edit_patch_sha256")),
        ("edited paths", direct_config.get("edited_paths"), server_config.get("edited_paths")),
        ("iterations", direct_config.get("iterations"), server_config.get("iterations")),
        ("warmups", direct_config.get("warmups"), server_config.get("warmups")),
        (
            "build inputs",
            direct_config.get("build_input_digests", {}).get("combined_sha256"),
            server_config.get("build_input_digests", {}).get("combined_sha256"),
        ),
    )
    for label, direct_value, server_value in comparable_fields:
        if direct_value != server_value:
            errors.append(f"{label} differs between direct and server results")

    def variant_hashes(label: str, result: dict[str, Any]) -> dict[str, str]:
        expected_samples = int(result.get("config", {}).get("iterations", 0))
        expected_warmups = int(result.get("config", {}).get("warmups", 0))
        samples = result.get("samples", [])
        warmups = result.get("warmup_samples", [])
        if len(samples) != expected_samples:
            errors.append(f"{label} measured sample count is {len(samples)}, expected {expected_samples}")
        if len(warmups) != expected_warmups:
            errors.append(f"{label} warmup sample count is {len(warmups)}, expected {expected_warmups}")

        observed: dict[str, set[str]] = {}
        for sample in [*warmups, *samples]:
            variant = sample.get("source_variant")
            digest = sample.get("generated_output", {}).get("output_tree_sha256")
            if sample.get("status") != "success":
                errors.append(f"{label} variant {variant!r} contains a failed sample")
                continue
            if variant not in ("A", "B") or not isinstance(digest, str) or not digest:
                errors.append(f"{label} sample lacks a valid source variant/output digest")
                continue
            observed.setdefault(variant, set()).add(digest)

        stable: dict[str, str] = {}
        for required_variant in ("A", "B"):
            if required_variant not in observed:
                errors.append(f"{label} variant {required_variant} was not observed")
        for variant, digests in sorted(observed.items()):
            if len(digests) != 1:
                errors.append(f"{label} variant {variant} generated {len(digests)} distinct output trees")
                continue
            stable[variant] = next(iter(digests))
        return stable

    direct_hashes = variant_hashes("direct", direct)
    server_hashes = variant_hashes("server", server)
    for variant in sorted(set(direct_hashes) | set(server_hashes)):
        if variant not in direct_hashes or variant not in server_hashes:
            errors.append(f"variant {variant} was not observed in both process models")
        elif direct_hashes[variant] != server_hashes[variant]:
            errors.append(f"variant {variant} output differs between direct and server modes")

    return {
        "status": "success" if not errors else "failure",
        "edit_kind": direct_config.get("edit_kind"),
        "direct_hashes": direct_hashes,
        "server_hashes": server_hashes,
        "errors": errors,
    }


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
    compare = subparsers.add_parser("compare-watch-output")
    compare.add_argument("--direct", required=True)
    compare.add_argument("--server", required=True)
    args = parser.parse_args()

    if args.command == "apply-source-variant":
        write_source_variant(Path(args.path), args.variant)
        return 0
    if args.command == "compare-watch-output":
        direct = json.loads(Path(args.direct).read_text(encoding="utf-8"))
        server = json.loads(Path(args.server).read_text(encoding="utf-8"))
        report = compare_watch_output_results(direct, server)
        print(json.dumps(report, indent=2, sort_keys=True))
        return 0 if report["status"] == "success" else 1
    raise AssertionError(f"unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())

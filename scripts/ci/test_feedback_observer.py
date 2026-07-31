#!/usr/bin/env python3
"""Explain proposed test ownership and summarize completed CI timing evidence.

This tool is observation-only. It never decides which GitHub Actions jobs run.
Unknown, cross-cutting, or stale inputs expand the reported proposal to the
complete configured evidence graph.
"""

from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


FAILURE_CONCLUSIONS = {"failure", "timed_out", "action_required", "startup_failure"}


class ObservationError(RuntimeError):
    """Raised when configuration or observation input is malformed."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ObservationError(f"cannot read JSON {path}: {error}") from error
    if not isinstance(value, dict):
        raise ObservationError(f"expected a JSON object in {path}")
    return value


def validate_manifest(manifest: dict[str, Any]) -> None:
    if manifest.get("schema_version") != 1:
        raise ObservationError("impact manifest schema_version must be 1")
    policy = manifest.get("policy")
    if not isinstance(policy, dict):
        raise ObservationError("impact manifest requires a policy object")
    if policy.get("observation_only") is not True or policy.get("controls_required_ci") is not False:
        raise ObservationError("impact manifest must remain observation-only and unable to control required CI")

    surfaces = manifest.get("product_surfaces")
    if (
        not isinstance(surfaces, list)
        or not surfaces
        or not all(isinstance(item, str) and item for item in surfaces)
        or len(set(surfaces)) != len(surfaces)
    ):
        raise ObservationError("impact manifest requires unique product_surfaces")
    surface_ids = set(surfaces)

    jobs = manifest.get("jobs")
    if not isinstance(jobs, list) or not jobs:
        raise ObservationError("impact manifest requires jobs")
    job_ids: set[str] = set()
    prefixes: set[str] = set()
    for job in jobs:
        if not isinstance(job, dict):
            raise ObservationError("each impact job must be an object")
        job_id = job.get("id")
        prefix = job.get("name_prefix")
        if not isinstance(job_id, str) or not job_id or job_id in job_ids:
            raise ObservationError(f"invalid or duplicate impact job id: {job_id!r}")
        if not isinstance(prefix, str) or not prefix or prefix in prefixes:
            raise ObservationError(f"invalid or duplicate impact job name_prefix: {prefix!r}")
        job_ids.add(job_id)
        prefixes.add(prefix)

    always_jobs = manifest.get("always_jobs")
    if not isinstance(always_jobs, list) or not all(isinstance(item, str) and item for item in always_jobs):
        raise ObservationError("impact manifest requires an always_jobs string array")
    references = list(always_jobs)
    rules = manifest.get("rules")
    if not isinstance(rules, list) or not rules:
        raise ObservationError("impact manifest requires rules")
    rule_ids: set[str] = set()
    for rule in rules:
        if not isinstance(rule, dict):
            raise ObservationError("each impact rule must be an object")
        rule_id = rule.get("id")
        owner = rule.get("owner")
        patterns = rule.get("patterns")
        rule_surfaces = rule.get("surfaces")
        reason = rule.get("reason")
        if not isinstance(rule_id, str) or not rule_id or rule_id in rule_ids:
            raise ObservationError(f"invalid or duplicate impact rule id: {rule_id!r}")
        if not isinstance(owner, str) or not owner:
            raise ObservationError(f"impact rule {rule_id} requires a semantic owner")
        if not isinstance(patterns, list) or not patterns or not all(isinstance(item, str) and item for item in patterns):
            raise ObservationError(f"impact rule {rule_id} requires path patterns")
        if (
            not isinstance(rule_surfaces, list)
            or not rule_surfaces
            or not all(isinstance(item, str) and item for item in rule_surfaces)
        ):
            raise ObservationError(f"impact rule {rule_id} requires product surfaces")
        unknown_surfaces = sorted(set(rule_surfaces) - surface_ids)
        if unknown_surfaces:
            raise ObservationError(
                f"impact rule {rule_id} references unknown product surfaces: {', '.join(unknown_surfaces)}"
            )
        if not isinstance(reason, str) or not reason:
            raise ObservationError(f"impact rule {rule_id} requires a plain-language reason")
        selection = rule.get("selection")
        if selection not in (None, "full"):
            raise ObservationError(f"impact rule {rule_id} has unsupported selection {selection!r}")
        if selection != "full":
            rule_jobs = rule.get("jobs")
            if not isinstance(rule_jobs, list) or not rule_jobs:
                raise ObservationError(f"impact rule {rule_id} requires jobs or full selection")
            references.extend(rule_jobs)
        rule_ids.add(rule_id)

    unknown_references = sorted(set(references) - job_ids)
    if unknown_references:
        raise ObservationError(f"impact manifest references unknown jobs: {', '.join(unknown_references)}")
    selectable_ids = {job["id"] for job in jobs if job.get("selectable") is True}
    nonselectable_always = sorted(set(always_jobs) - selectable_ids)
    if nonselectable_always:
        raise ObservationError(
            "always_jobs must be selectable evidence jobs: " + ", ".join(nonselectable_always)
        )


def job_index(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {job["id"]: job for job in manifest["jobs"]}


def selectable_job_ids(manifest: dict[str, Any]) -> list[str]:
    return sorted(job["id"] for job in manifest["jobs"] if job.get("selectable") is True)


def path_matches(path: str, pattern: str) -> bool:
    return fnmatch.fnmatchcase(path, pattern)


def build_plan(changed_paths: list[str], manifest: dict[str, Any], *, base: str = "", head: str = "") -> dict[str, Any]:
    validate_manifest(manifest)
    normalized_paths = sorted({path.strip().replace("\\", "/") for path in changed_paths if path.strip()})
    all_jobs = selectable_job_ids(manifest)
    selected = set(manifest.get("always_jobs", []))
    matched_rules: dict[str, dict[str, Any]] = {}
    affected_surfaces: set[str] = set()
    unmatched_paths: list[str] = []
    full_reasons: list[str] = []

    if not normalized_paths:
        full_reasons.append("No changed paths were available, so ownership cannot be established safely.")

    for path in normalized_paths:
        matches = [rule for rule in manifest["rules"] if any(path_matches(path, pattern) for pattern in rule["patterns"])]
        if not matches:
            unmatched_paths.append(path)
            continue
        for rule in matches:
            matched_rules[rule["id"]] = rule
            affected_surfaces.update(rule["surfaces"])
            if rule.get("selection") == "full":
                full_reasons.append(f"{path} matches full-fallback rule {rule['id']}: {rule['reason']}")
            else:
                selected.update(rule["jobs"])

    if unmatched_paths:
        full_reasons.append(
            "No reviewed ownership rule matched: " + ", ".join(unmatched_paths)
        )

    mode = "full_fallback" if full_reasons else "proposed_subset"
    if mode == "full_fallback":
        selected = set(all_jobs)
        affected_surfaces = set(manifest["product_surfaces"])
    selected_jobs = sorted(selected)
    omitted_jobs = sorted(set(all_jobs) - selected)
    return {
        "schema_version": 1,
        "observation_only": True,
        "controls_required_ci": False,
        "promotion_eligible": False,
        "promotion_threshold_validated": False,
        "base": base,
        "head": head,
        "changed_paths": normalized_paths,
        "mode": mode,
        "matched_rules": [
            {
                "id": rule["id"],
                "owner": rule["owner"],
                "reason": rule["reason"],
                "surfaces": rule["surfaces"],
            }
            for rule in sorted(matched_rules.values(), key=lambda item: item["id"])
        ],
        "affected_product_surfaces": sorted(affected_surfaces),
        "unmatched_paths": unmatched_paths,
        "full_fallback_reasons": full_reasons,
        "selected_jobs": selected_jobs,
        "omitted_jobs": omitted_jobs,
    }


def parse_timestamp(value: Any) -> dt.datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ObservationError(f"invalid GitHub job timestamp: {value!r}") from error


def match_job_id(name: str, manifest: dict[str, Any]) -> str | None:
    candidates: list[tuple[int, str]] = []
    for job in manifest["jobs"]:
        prefix = job["name_prefix"]
        if name == prefix or name.startswith(prefix + " /") or name.startswith(prefix + " ("):
            candidates.append((len(prefix), job["id"]))
    if not candidates:
        return None
    return max(candidates)[1]


def build_observation(
    plan: dict[str, Any],
    jobs_payload: dict[str, Any],
    manifest: dict[str, Any],
    *,
    run_id: str = "",
    run_attempt: int | None = None,
) -> dict[str, Any]:
    validate_manifest(manifest)
    jobs = jobs_payload.get("jobs")
    if not isinstance(jobs, list):
        raise ObservationError("GitHub jobs payload requires a jobs array")

    configured = job_index(manifest)
    observed_by_id: dict[str, list[dict[str, Any]]] = {}
    unknown_names: list[str] = []
    timing_rows: list[dict[str, Any]] = []

    for job in jobs:
        if not isinstance(job, dict) or not isinstance(job.get("name"), str):
            raise ObservationError("each GitHub job requires a name")
        job_id = match_job_id(job["name"], manifest)
        if job_id is None:
            unknown_names.append(job["name"])
            continue
        observed_by_id.setdefault(job_id, []).append(job)
        if configured[job_id].get("selectable") is not True:
            continue
        started = parse_timestamp(job.get("started_at"))
        completed = parse_timestamp(job.get("completed_at"))
        duration_ms = None
        if started is not None and completed is not None:
            duration_ms = max(0, round((completed - started).total_seconds() * 1000))
        timing_rows.append(
            {
                "job_id": job_id,
                "name": job["name"],
                "status": job.get("status"),
                "conclusion": job.get("conclusion"),
                "started_at": job.get("started_at"),
                "completed_at": job.get("completed_at"),
                "duration_ms": duration_ms,
                "run_attempt": job.get("run_attempt"),
            }
        )

    expected_ids = {
        job["id"]
        for job in manifest["jobs"]
        if job.get("selectable") is True and job.get("optional") is not True
    }
    missing_ids = sorted(expected_ids - observed_by_id.keys())
    manifest_fresh = not unknown_names and not missing_ids

    configured_all = set(selectable_job_ids(manifest))
    proposed_selected = set(plan.get("selected_jobs", []))
    if not proposed_selected.issubset(configured_all):
        raise ObservationError("plan selected jobs not present in the impact manifest")
    effective_selected = configured_all if not manifest_fresh else proposed_selected
    effective_mode = "full_fallback_stale_manifest" if not manifest_fresh else plan.get("mode")
    effective_omitted = configured_all - effective_selected

    misses: list[dict[str, str]] = []
    for job_id in sorted(effective_omitted):
        for job in observed_by_id.get(job_id, []):
            conclusion = job.get("conclusion")
            if conclusion in FAILURE_CONCLUSIONS:
                misses.append({"job_id": job_id, "name": job["name"], "conclusion": conclusion})

    completed_rows = [row for row in timing_rows if row["started_at"] and row["completed_at"]]
    starts = [(parse_timestamp(row["started_at"]), row) for row in completed_rows]
    ends = [(parse_timestamp(row["completed_at"]), row) for row in completed_rows]
    workflow_start = min((item[0] for item in starts), default=None)
    workflow_end = max((item[0] for item in ends), default=None)
    observed_duration_ms = None
    if workflow_start is not None and workflow_end is not None:
        observed_duration_ms = max(0, round((workflow_end - workflow_start).total_seconds() * 1000))

    critical_jobs: list[str] = []
    if workflow_end is not None:
        critical_jobs = sorted(row["name"] for timestamp, row in ends if timestamp == workflow_end)

    failed_rows = [
        row for row in completed_rows if row.get("conclusion") in FAILURE_CONCLUSIONS
    ]
    first_failure = None
    if failed_rows and workflow_start is not None:
        first_row = min(failed_rows, key=lambda row: parse_timestamp(row["completed_at"]) or workflow_start)
        first_completed = parse_timestamp(first_row["completed_at"])
        if first_completed is not None:
            first_failure = {
                "signal": "failed_job_completion",
                "job": first_row["name"],
                "elapsed_ms": max(0, round((first_completed - workflow_start).total_seconds() * 1000)),
                "limitation": "GitHub job metadata does not expose the earlier log line where the failure first became actionable."
            }

    longest_jobs = sorted(
        (
            {"name": row["name"], "duration_ms": row["duration_ms"]}
            for row in completed_rows
            if row["duration_ms"] is not None
        ),
        key=lambda item: (-item["duration_ms"], item["name"]),
    )[:5]

    return {
        "schema_version": 1,
        "observation_only": True,
        "controls_required_ci": False,
        "promotion_eligible": False,
        "run_id": run_id,
        "run_attempt": run_attempt,
        "plan": plan,
        "manifest_fresh": manifest_fresh,
        "unknown_job_names": sorted(unknown_names),
        "missing_job_ids": missing_ids,
        "effective_mode": effective_mode,
        "effective_selected_jobs": sorted(effective_selected),
        "effective_omitted_jobs": sorted(effective_omitted),
        "selector_misses": misses,
        "timing": {
            "workflow_observed_ms": observed_duration_ms,
            "completion_critical_jobs": critical_jobs,
            "longest_jobs": longest_jobs,
            "jobs": sorted(timing_rows, key=lambda row: (row["job_id"], row["name"])),
            "first_failure_signal": first_failure,
            "cache_evidence": "not_reported_by_github_jobs_api",
            "retry_evidence": (
                "run_attempt_reported_by_workflow"
                if run_attempt is not None
                else "not_reported_by_input"
            ),
        },
    }


def changed_paths(repo: Path, base: str, head: str) -> list[str]:
    if not base or not head or set(base) == {"0"}:
        return []
    # Treat renames as a deletion plus an addition so ownership sees both the
    # old and new locations. Otherwise moving source into a docs path could
    # incorrectly look like a documentation-only change.
    command = ["git", "-C", str(repo), "diff", "--no-renames", "--name-only", f"{base}..{head}"]
    try:
        output = subprocess.run(command, check=True, capture_output=True, text=True).stdout
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or "git diff failed").splitlines()[0]
        print(f"test feedback observer: cannot inspect {base}..{head}: {detail}", file=sys.stderr)
        return []
    return [line for line in output.splitlines() if line]


def write_json(path: Path | None, value: dict[str, Any]) -> None:
    text = json.dumps(value, indent=2, sort_keys=True) + "\n"
    if path is None:
        sys.stdout.write(text)
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def plan_markdown(plan: dict[str, Any]) -> str:
    lines = [
        "## Test-impact observation",
        "",
        "> This report is advisory. Every existing required CI job still runs.",
        "",
        f"- Proposed mode: `{plan['mode']}`",
        f"- Changed paths: {len(plan['changed_paths'])}",
        f"- Affected product surfaces: {', '.join(f'`{item}`' for item in plan['affected_product_surfaces']) or 'none'}",
        f"- Proposed selected jobs: {', '.join(f'`{item}`' for item in plan['selected_jobs']) or 'none'}",
        f"- Proposed omitted jobs: {', '.join(f'`{item}`' for item in plan['omitted_jobs']) or 'none'}",
    ]
    if plan["full_fallback_reasons"]:
        lines.extend(["", "Full-fallback reasons:"])
        lines.extend(f"- {reason}" for reason in plan["full_fallback_reasons"])
    if plan["matched_rules"]:
        lines.extend(["", "Matched semantic owners:"])
        for rule in plan["matched_rules"]:
            surfaces = ", ".join(f"`{item}`" for item in rule["surfaces"])
            lines.append(
                f"- `{rule['id']}` -> `{rule['owner']}` ({surfaces}): {rule['reason']}"
            )
    return "\n".join(lines) + "\n"


def observation_markdown(observation: dict[str, Any]) -> str:
    timing = observation["timing"]
    lines = [
        plan_markdown(observation["plan"]).rstrip(),
        "",
        "### Completed-run evidence",
        "",
        f"- Manifest matched the observed workflow: `{str(observation['manifest_fresh']).lower()}`",
        f"- Effective observation mode: `{observation['effective_mode']}`",
        f"- Observed workflow duration: `{timing['workflow_observed_ms']}` ms",
        f"- Completion-critical jobs: {', '.join(f'`{item}`' for item in timing['completion_critical_jobs']) or 'none'}",
        f"- Selector misses: `{len(observation['selector_misses'])}`",
        "- Promotion eligible: `false`",
    ]
    if observation["unknown_job_names"]:
        lines.append("- Unknown workflow jobs forced full fallback: " + ", ".join(observation["unknown_job_names"]))
    if observation["missing_job_ids"]:
        lines.append("- Configured jobs missing from the run forced full fallback: " + ", ".join(observation["missing_job_ids"]))
    return "\n".join(lines) + "\n"


def write_text(path: Path | None, text: str) -> None:
    if path is None:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=Path("test/impact-ownership.json"))
    subparsers = parser.add_subparsers(dest="command", required=True)

    plan_parser = subparsers.add_parser("plan", help="explain proposed ownership for a Git diff")
    plan_parser.add_argument("--repo", type=Path, default=Path("."))
    plan_parser.add_argument("--base", required=True)
    plan_parser.add_argument("--head", required=True)
    plan_parser.add_argument("--output", type=Path)
    plan_parser.add_argument("--summary", type=Path)

    observe_parser = subparsers.add_parser("observe", help="combine a plan with completed GitHub jobs")
    observe_parser.add_argument("--plan", type=Path, required=True)
    observe_parser.add_argument("--jobs", type=Path, required=True)
    observe_parser.add_argument("--run-id", default="")
    observe_parser.add_argument("--run-attempt", type=int)
    observe_parser.add_argument("--output", type=Path)
    observe_parser.add_argument("--summary", type=Path)

    args = parser.parse_args()
    try:
        manifest = load_json(args.manifest)
        validate_manifest(manifest)
        if args.command == "plan":
            plan = build_plan(changed_paths(args.repo, args.base, args.head), manifest, base=args.base, head=args.head)
            write_json(args.output, plan)
            write_text(args.summary, plan_markdown(plan))
        else:
            plan = load_json(args.plan)
            jobs_payload = load_json(args.jobs)
            observation = build_observation(
                plan,
                jobs_payload,
                manifest,
                run_id=args.run_id,
                run_attempt=args.run_attempt,
            )
            write_json(args.output, observation)
            write_text(args.summary, observation_markdown(observation))
    except ObservationError as error:
        print(f"test feedback observer: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

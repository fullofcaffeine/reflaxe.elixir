#!/usr/bin/env python3
"""Focused executable contracts for the observation-only test feedback tool."""

from __future__ import annotations

import copy
import contextlib
import importlib.util
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts/ci/test_feedback_observer.py"
SPEC = importlib.util.spec_from_file_location("test_feedback_observer", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
observer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(observer)
MANIFEST = json.loads((ROOT / "test/impact-ownership.json").read_text(encoding="utf-8"))


def github_job(name: str, conclusion: str = "success", start: str = "2026-07-31T10:00:00Z", end: str = "2026-07-31T10:01:00Z") -> dict[str, object]:
    return {
        "name": name,
        "status": "completed",
        "conclusion": conclusion,
        "started_at": start,
        "completed_at": end,
    }


def complete_jobs() -> list[dict[str, object]]:
    return [
        github_job(job["name_prefix"])
        for job in MANIFEST["jobs"]
        if job.get("selectable") is True
    ]


class PlanTests(unittest.TestCase):
    def test_documentation_change_proposes_small_advisory_subset(self) -> None:
        plan = observer.build_plan(["docs/guide.md", "AGENTS.md"], MANIFEST)
        self.assertEqual(plan["mode"], "proposed_subset")
        self.assertEqual(
            plan["selected_jobs"],
            ["dependency-audit", "docs-smoke", "dogfood-gate", "guards", "secret-scan"],
        )
        self.assertEqual(plan["affected_product_surfaces"], sorted(MANIFEST["product_surfaces"]))
        self.assertEqual(plan["matched_rules"][0]["owner"], "documentation-contracts")
        self.assertIn("test", plan["omitted_jobs"])
        self.assertFalse(plan["controls_required_ci"])
        self.assertFalse(plan["promotion_eligible"])

    def test_dependency_audit_is_unconditional_for_external_advisories(self) -> None:
        plan = observer.build_plan(["test/snapshot/core/example/Main.hx"], MANIFEST)
        self.assertIn("dependency-audit", plan["selected_jobs"])

    def test_real_compile_to_runtime_sentinel_is_unconditional(self) -> None:
        plan = observer.build_plan(["docs/guide.md"], MANIFEST)
        self.assertIn("dogfood-gate", plan["selected_jobs"])

    def test_overlapping_example_documentation_unions_owners(self) -> None:
        plan = observer.build_plan(["examples/todo-app/README.md"], MANIFEST)
        self.assertEqual(plan["mode"], "proposed_subset")
        self.assertIn("examples", plan["selected_jobs"])
        self.assertIn("examples-elixir", plan["selected_jobs"])
        self.assertIn("docs-smoke", plan["selected_jobs"])

    def test_reviewed_non_documentation_rules_select_their_semantic_owners(self) -> None:
        cases = [
            (
                "examples/todo-app/src/Main.hx",
                {"example-compilation-gate", "sentinel-gate", "examples", "examples-elixir"},
                {
                    "compiler-conformance",
                    "beam-otp-runtime",
                    "elixir-native-interop",
                    "mix-package-cli",
                    "framework-applications",
                },
            ),
            (
                "test/snapshot/core/example/Main.hx",
                {"test"},
                set(MANIFEST["product_surfaces"]),
            ),
            (
                "scripts/perf/benchmark-todo-watch.py",
                {"budgets", "test"},
                {"compiler-conformance"},
            ),
            (
                "scripts/release/test-release-policy.js",
                {"haxelib-package-smoke", "test"},
                {"mix-package-cli"},
            ),
        ]
        for path, owner_jobs, surfaces in cases:
            with self.subTest(path=path):
                plan = observer.build_plan([path], MANIFEST)
                self.assertEqual(plan["mode"], "proposed_subset")
                self.assertTrue(owner_jobs.issubset(plan["selected_jobs"]))
                self.assertEqual(set(plan["affected_product_surfaces"]), surfaces)

    def test_compiler_change_falls_back_to_full(self) -> None:
        plan = observer.build_plan(["src/reflaxe/elixir/ElixirCompiler.hx"], MANIFEST)
        self.assertEqual(plan["mode"], "full_fallback")
        self.assertEqual(plan["omitted_jobs"], [])

    def test_unknown_change_falls_back_to_full(self) -> None:
        plan = observer.build_plan(["new-unowned.file"], MANIFEST)
        self.assertEqual(plan["mode"], "full_fallback")
        self.assertEqual(plan["unmatched_paths"], ["new-unowned.file"])

    def test_selector_and_workflow_changes_fall_back_to_full(self) -> None:
        paths = ["test/impact-ownership.json", ".github/workflows/ci.yml"]
        plan = observer.build_plan(paths, MANIFEST)
        self.assertEqual(plan["mode"], "full_fallback")
        self.assertEqual(plan["omitted_jobs"], [])

    def test_no_change_evidence_falls_back_to_full(self) -> None:
        plan = observer.build_plan([], MANIFEST)
        self.assertEqual(plan["mode"], "full_fallback")

    def test_manifest_rejects_unknown_job_reference(self) -> None:
        manifest = copy.deepcopy(MANIFEST)
        manifest["always_jobs"].append("does-not-exist")
        with self.assertRaisesRegex(observer.ObservationError, "unknown jobs"):
            observer.validate_manifest(manifest)

    def test_manifest_rejects_nonselectable_always_job(self) -> None:
        manifest = copy.deepcopy(MANIFEST)
        manifest["always_jobs"].append("release")
        with self.assertRaisesRegex(observer.ObservationError, "must be selectable"):
            observer.validate_manifest(manifest)

    def test_manifest_rejects_unknown_product_surface(self) -> None:
        manifest = copy.deepcopy(MANIFEST)
        manifest["rules"][0]["surfaces"].append("imaginary-surface")
        with self.assertRaisesRegex(observer.ObservationError, "unknown product surfaces"):
            observer.validate_manifest(manifest)

    def test_semantic_owner_is_required_and_rendered_with_evidence_reason(self) -> None:
        manifest = copy.deepcopy(MANIFEST)
        manifest["rules"][0].pop("owner")
        with self.assertRaisesRegex(observer.ObservationError, "requires a semantic owner"):
            observer.validate_manifest(manifest)

        summary = observer.plan_markdown(observer.build_plan(["docs/guide.md"], MANIFEST))
        self.assertIn("`documentation` -> `documentation-contracts`", summary)
        self.assertIn("`compiler-conformance`", summary)
        self.assertIn("Documentation can change claims", summary)

    def test_rename_reports_old_and_new_ownership_paths(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / "src").mkdir()
            (repo / "docs").mkdir()
            (repo / "src/Owned.hx").write_text("class Owned {}\n", encoding="utf-8")
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            subprocess.run(["git", "config", "user.email", "observer@example.invalid"], cwd=repo, check=True)
            subprocess.run(["git", "config", "user.name", "Observer Test"], cwd=repo, check=True)
            subprocess.run(["git", "add", "."], cwd=repo, check=True)
            subprocess.run(["git", "commit", "-qm", "base"], cwd=repo, check=True)
            base = subprocess.run(
                ["git", "rev-parse", "HEAD"], cwd=repo, check=True, capture_output=True, text=True
            ).stdout.strip()
            (repo / "src/Owned.hx").rename(repo / "docs/Owned.md")
            subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
            subprocess.run(["git", "commit", "-qm", "rename"], cwd=repo, check=True)
            head = subprocess.run(
                ["git", "rev-parse", "HEAD"], cwd=repo, check=True, capture_output=True, text=True
            ).stdout.strip()

            paths = observer.changed_paths(repo, base, head)

        self.assertEqual(paths, ["docs/Owned.md", "src/Owned.hx"])
        self.assertEqual(observer.build_plan(paths, MANIFEST)["mode"], "full_fallback")

    def test_cli_diff_failure_produces_safe_empty_paths(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(observer.changed_paths(Path(directory), "missing", "head"), [])


class ObservationTests(unittest.TestCase):
    def test_stale_job_manifest_forces_effective_full_fallback(self) -> None:
        plan = observer.build_plan(["docs/guide.md"], MANIFEST)
        jobs = complete_jobs() + [github_job("New unowned CI lane")]
        result = observer.build_observation(plan, {"jobs": jobs}, MANIFEST)
        self.assertFalse(result["manifest_fresh"])
        self.assertEqual(result["effective_mode"], "full_fallback_stale_manifest")
        self.assertEqual(result["effective_omitted_jobs"], [])

    def test_missing_configured_job_forces_effective_full_fallback(self) -> None:
        plan = observer.build_plan(["docs/guide.md"], MANIFEST)
        jobs = [job for job in complete_jobs() if job["name"] != "Tests"]
        result = observer.build_observation(plan, {"jobs": jobs}, MANIFEST)
        self.assertFalse(result["manifest_fresh"])
        self.assertIn("test", result["missing_job_ids"])
        self.assertEqual(result["effective_omitted_jobs"], [])

    def test_failed_omitted_job_is_a_selector_miss(self) -> None:
        plan = observer.build_plan(["docs/guide.md"], MANIFEST)
        jobs = complete_jobs()
        for job in jobs:
            if job["name"] == "Tests":
                job["conclusion"] = "failure"
                job["completed_at"] = "2026-07-31T10:03:00Z"
        result = observer.build_observation(plan, {"jobs": jobs}, MANIFEST, run_attempt=1)
        self.assertEqual(result["selector_misses"], [{"job_id": "test", "name": "Tests", "conclusion": "failure"}])
        self.assertEqual(result["timing"]["first_failure_signal"]["elapsed_ms"], 180000)
        self.assertIn("Tests", result["timing"]["completion_critical_jobs"])

    def test_failed_selected_job_is_not_a_selector_miss(self) -> None:
        plan = observer.build_plan(["docs/guide.md"], MANIFEST)
        jobs = complete_jobs()
        for job in jobs:
            if job["name"] == "Docs Smoke (Phoenix)":
                job["conclusion"] = "failure"
        result = observer.build_observation(plan, {"jobs": jobs}, MANIFEST)
        self.assertEqual(result["selector_misses"], [])
        self.assertIsNotNone(result["timing"]["first_failure_signal"])

    def test_matrix_job_uses_longest_matching_prefix(self) -> None:
        self.assertEqual(
            observer.match_job_id("Examples (Elixir WAE) / mix-01", MANIFEST),
            "examples-elixir",
        )
        self.assertEqual(observer.match_job_id("Examples", MANIFEST), "examples")

    def test_unavailable_cache_and_retry_signals_are_not_invented(self) -> None:
        plan = observer.build_plan(["docs/guide.md"], MANIFEST)
        result = observer.build_observation(plan, {"jobs": complete_jobs()}, MANIFEST)
        self.assertEqual(result["timing"]["cache_evidence"], "not_reported_by_github_jobs_api")
        self.assertEqual(result["timing"]["retry_evidence"], "not_reported_by_input")


if __name__ == "__main__":
    unittest.main(verbosity=2)

#!/usr/bin/env python3
"""Focused executable contracts for the observation-only test feedback tool."""

from __future__ import annotations

import copy
import contextlib
import importlib.util
import io
import json
import re
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
        self.assertIn("test-lanes", plan["omitted_jobs"])
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
                {"test-lanes"},
                set(MANIFEST["product_surfaces"]),
            ),
            (
                "scripts/perf/benchmark-todo-watch.py",
                {"budgets", "test-lanes"},
                {"compiler-conformance"},
            ),
            (
                "scripts/release/test-release-policy.js",
                {"haxelib-package-smoke", "test-lanes"},
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
        jobs = [job for job in complete_jobs() if job["name"] != "Test lane"]
        result = observer.build_observation(plan, {"jobs": jobs}, MANIFEST)
        self.assertFalse(result["manifest_fresh"])
        self.assertIn("test-lanes", result["missing_job_ids"])
        self.assertEqual(result["effective_omitted_jobs"], [])

    def test_failed_omitted_job_is_a_selector_miss(self) -> None:
        plan = observer.build_plan(["docs/guide.md"], MANIFEST)
        jobs = complete_jobs()
        for job in jobs:
            if job["name"] == "Test lane":
                job["conclusion"] = "failure"
                job["completed_at"] = "2026-07-31T10:03:00Z"
        result = observer.build_observation(plan, {"jobs": jobs}, MANIFEST, run_attempt=1)
        self.assertEqual(
            result["selector_misses"],
            [{"job_id": "test-lanes", "name": "Test lane", "conclusion": "failure"}],
        )
        self.assertEqual(result["timing"]["first_failure_signal"]["elapsed_ms"], 180000)
        self.assertIn("Test lane", result["timing"]["completion_critical_jobs"])

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
        self.assertEqual(
            observer.match_job_id("Test lane / Compiler snapshots (core)", MANIFEST),
            "test-lanes",
        )
        self.assertEqual(observer.match_job_id("Tests", MANIFEST), "test")

    def test_unavailable_cache_and_retry_signals_are_not_invented(self) -> None:
        plan = observer.build_plan(["docs/guide.md"], MANIFEST)
        result = observer.build_observation(plan, {"jobs": complete_jobs()}, MANIFEST)
        self.assertEqual(result["timing"]["cache_evidence"], "not_reported_by_github_jobs_api")
        self.assertEqual(result["timing"]["retry_evidence"], "not_reported_by_input")


class WorkflowTopologyTests(unittest.TestCase):
    def test_checked_in_corpus_validation_fails_when_artifacts_are_absent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fixture = Path(tmp) / "snapshot" / "missing-intended"
            fixture.mkdir(parents=True)
            (fixture / "compile.hxml").write_text("-main Main\n", encoding="utf-8")
            result = subprocess.run(
                [
                    "bash",
                    str(ROOT / "test/validate_elixir.sh"),
                    "--artifact-dir",
                    "intended",
                    "--require-all",
                    str(Path(tmp) / "snapshot"),
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Missing required artifacts: 1", result.stdout)

    def test_compatibility_smokes_keep_vertical_contracts_without_recompiling_the_full_corpus(self) -> None:
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        minimum_match = re.search(
            r"^  smoke-min-toolchain:\n(?P<body>.*?)^  smoke-macos:\n",
            workflow,
            re.MULTILINE | re.DOTALL,
        )
        macos_match = re.search(
            r"^  smoke-macos:\n(?P<body>.*?)^  docs-smoke:\n",
            workflow,
            re.MULTILINE | re.DOTALL,
        )
        self.assertIsNotNone(minimum_match, "CI must keep the minimum-toolchain compatibility owner")
        self.assertIsNotNone(macos_match, "CI must keep the macOS compatibility owner")

        for name, body in (
            ("minimum toolchain", minimum_match.group("body")),
            ("macOS", macos_match.group("body")),
        ):
            with self.subTest(name=name):
                run_commands = re.findall(r"^        run: ([^\n]+)$", body, re.MULTILINE)
                self.assertIn(
                    'echo "$(pwd)/node_modules/.bin" >> "$GITHUB_PATH"',
                    body,
                    f"{name} must expose the repository Lix shims to direct Bash runtime steps",
                )
                self.assertNotIn(
                    "npm run test:quick",
                    run_commands,
                    "platform compatibility must not repeat the primary compiler-conformance corpus",
                )
                self.assertIn("bash scripts/ci/runtime-smoke-stdlib-io.sh", run_commands)
                self.assertIn("npm run test:otp-runtime", run_commands)
                self.assertIn(
                    "npm run test:mix-fast",
                    body,
                    f"{name} must execute the Mix integration suite",
                )

        minimum_commands = re.findall(
            r"^        run: ([^\n]+)$", minimum_match.group("body"), re.MULTILINE
        )
        self.assertIn(
            "bash test/validate_elixir.sh --artifact-dir intended --require-all test/snapshot/core test/snapshot/stdlib test/snapshot/regression",
            minimum_commands,
            "the minimum Elixir version must parse the complete generated conformance corpus",
        )

    def test_every_declared_ci_test_lane_is_required_by_the_matrix(self) -> None:
        package = json.loads((ROOT / "package.json").read_text(encoding="utf-8"))
        expected_scripts = {
            name for name in package["scripts"] if name.startswith("test:ci:")
        }
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        matrix_match = re.search(r"^  test-lanes:\n(?P<body>.*?)^  test:\n", workflow, re.MULTILINE | re.DOTALL)
        self.assertIsNotNone(matrix_match, "CI must define semantic test lanes before the Tests aggregator")
        matrix_body = matrix_match.group("body")
        scheduled_scripts = re.findall(r"^\s+command: npm run (test:ci:[\w:-]+)$", matrix_body, re.MULTILINE)

        self.assertEqual(set(scheduled_scripts), expected_scripts)
        self.assertEqual(len(scheduled_scripts), len(expected_scripts), "each CI test lane must be scheduled once")
        self.assertIn("fail-fast: false", matrix_body)

    def test_tests_aggregator_fails_closed_over_the_whole_matrix(self) -> None:
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        aggregator_match = re.search(r"^  test:\n(?P<body>.*?)^  examples:\n", workflow, re.MULTILINE | re.DOTALL)
        self.assertIsNotNone(aggregator_match, "CI must preserve the stable Tests aggregator")
        aggregator = aggregator_match.group("body")

        self.assertIn("name: Tests", aggregator)
        self.assertIn("if: ${{ always() }}", aggregator)
        self.assertIn("needs: [test-lanes]", aggregator)
        self.assertIn("needs.test-lanes.result", aggregator)
        self.assertIn('if [ "$TEST_LANES_RESULT" != "success" ]', aggregator)


if __name__ == "__main__":
    unittest.main(verbosity=2)

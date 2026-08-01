#!/usr/bin/env python3
import copy
import importlib.util
import io
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts" / "ci" / "examples_qa.py"
SPEC = importlib.util.spec_from_file_location("examples_qa", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Could not load {MODULE_PATH}")
EXAMPLES_QA = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(EXAMPLES_QA)


class ExampleQaContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.repository_manifest = EXAMPLES_QA.load_manifest()
        self.manifest = copy.deepcopy(self.repository_manifest)
        for name, entry in self.manifest["examples"].items():
            compile_only = entry["runtime"]["mode"] == "compile-only"
            entry.setdefault(
                "qa",
                {
                    "tier": "compile-only-snippet" if compile_only else "capability-showcase",
                    "owner": f"example-{name}",
                    "surfaces": ["compiler-conformance"],
                    "profiles": ["portable"],
                    "evidenceLevel": "compile" if compile_only else "runtime",
                    "claim": f"Exercise the maintained {name} example at its declared level.",
                },
            )

    def validate(self, manifest: dict) -> dict:
        with patch.object(EXAMPLES_QA, "load_manifest", return_value=manifest):
            return EXAMPLES_QA.validate_manifest()

    def assert_invalid(self, manifest: dict, expected: str) -> None:
        stderr = io.StringIO()
        with redirect_stderr(stderr), self.assertRaises(SystemExit):
            self.validate(manifest)
        self.assertIn(expected, stderr.getvalue())

    def test_current_manifest_is_valid(self) -> None:
        missing = [name for name, entry in self.repository_manifest["examples"].items() if "qa" not in entry]
        self.assertEqual([], missing, f"examples missing qa metadata: {missing}")
        self.validate(self.repository_manifest)

    def test_every_example_requires_claim_metadata(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["examples"]["01-simple-modules"].pop("qa", None)
        self.assert_invalid(manifest, "01-simple-modules.qa must be an object")

    def test_compile_only_tier_cannot_claim_runtime(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        entry = manifest["examples"]["01-simple-modules"]
        entry["qa"]["tier"] = "compile-only-snippet"
        self.assert_invalid(manifest, "compile-only-snippet must use runtime.mode=compile-only")

    def test_manual_runtime_cannot_be_marked_as_ci(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        entry = manifest["examples"]["01-simple-modules"]
        entry["runtime"]["mode"] = "manual"
        self.assert_invalid(manifest, "01-simple-modules.runtime: manual mode requires ci=false")

    def test_browser_claim_requires_ci_browser_evidence(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        entry = manifest["examples"]["15-phoenix-chat-haxe-first"]
        entry["qa"]["evidenceLevel"] = "browser"
        self.assert_invalid(manifest, "browser claim requires e2e.ci=true")

    def test_browser_claim_requires_a_browser_capable_e2e_mode(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        entry = manifest["examples"]["todo-app"]
        entry["e2e"]["mode"] = "fixture-non-browser"
        with patch.object(EXAMPLES_QA, "E2E_MODES", EXAMPLES_QA.E2E_MODES | {"fixture-non-browser"}):
            self.assert_invalid(manifest, "browser claim requires e2e.mode=sentinel-playwright")

    def test_e2e_section_rejects_a_compile_only_mode(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        entry = manifest["examples"]["todo-app"]
        entry["e2e"]["mode"] = "compile-only"
        self.assert_invalid(manifest, "todo-app.e2e.mode must be one of")

    def test_manual_e2e_cannot_be_marked_as_ci(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        entry = manifest["examples"]["15-phoenix-chat-haxe-first"]
        entry["e2e"]["ci"] = True
        self.assert_invalid(manifest, "15-phoenix-chat-haxe-first.e2e: manual mode requires ci=false")

    def test_product_surfaces_are_bounded(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        entry = manifest["examples"]["01-simple-modules"]
        entry["qa"]["surfaces"] = ["general-quality"]
        self.assert_invalid(manifest, "qa.surfaces[] must be one of")

    def test_product_surfaces_reject_non_text_values_cleanly(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        entry = manifest["examples"]["01-simple-modules"]
        entry["qa"]["surfaces"] = [["compiler-conformance"]]
        self.assert_invalid(manifest, "qa.surfaces[] must be a non-empty string")

    def test_example_owners_are_unique(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        first = manifest["examples"]["01-simple-modules"]["qa"]["owner"]
        manifest["examples"]["02-mix-project"]["qa"]["owner"] = first
        self.assert_invalid(manifest, "qa.owner must be unique")

    def test_declared_runtime_and_e2e_evidence_must_name_real_paths(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["examples"]["12-phoenix-chat"]["e2e"]["evidence"] = []
        self.assert_invalid(manifest, "12-phoenix-chat.e2e.evidence must name at least one path")

    def test_evidence_cannot_escape_its_owning_example(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["examples"]["12-phoenix-chat"]["e2e"]["evidence"] = ["../README.md"]
        self.assert_invalid(manifest, "12-phoenix-chat.e2e.evidence[] must stay inside the example")

    def test_missing_runtime_section_has_a_clean_contract_error(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["examples"]["01-simple-modules"].pop("runtime")
        self.assert_invalid(manifest, "01-simple-modules.runtime must be an object")

    def test_manifest_root_must_be_an_object(self) -> None:
        self.assert_invalid([], "Manifest root must be an object")


if __name__ == "__main__":
    unittest.main()

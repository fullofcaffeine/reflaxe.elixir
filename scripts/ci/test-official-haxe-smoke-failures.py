#!/usr/bin/env python3
"""Check deterministic failure categories for the official Haxe BEAM smoke."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CLASSIFIER = ROOT / "scripts/ci/classify-official-haxe-smoke-failure.py"
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("official_haxe_smoke_failure", CLASSIFIER)
if SPEC is None or SPEC.loader is None:
	raise RuntimeError(f"could not load {CLASSIFIER}")
classifier = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(classifier)


class OfficialHaxeSmokeFailureTest(unittest.TestCase):
	def test_assertion_failure(self) -> None:
		self.assertEqual(classifier.classify("mix-test", 2, "Assertion with == failed"), "assertion")

	def test_compiler_failure(self) -> None:
		self.assertEqual(classifier.classify("haxe-compile", 1, "Unknown identifier"), "compiler")

	def test_mix_failure(self) -> None:
		self.assertEqual(classifier.classify("mix-test", 1, "** (CompileError) Compilation error"), "mix")

	def test_runtime_failure(self) -> None:
		self.assertEqual(classifier.classify("mix-test", 2, "** (RuntimeError) boom"), "runtime")

	def test_timeout_failure(self) -> None:
		self.assertEqual(classifier.classify("haxe-compile", 124, "deadline reached"), "timeout")

	def test_missing_test_failure(self) -> None:
		self.assertEqual(classifier.classify("generated-tests", 1, "missing generated test"), "missing-test")

	def test_unclassified_record_failure(self) -> None:
		self.assertEqual(classifier.classify("provenance", 1, "unclassified fixtures"), "unclassified-record")


if __name__ == "__main__":
	unittest.main()

#!/usr/bin/env python3
"""Exercise the real Make entrypoints without compiling the compiler."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class NegativeRunnerContract(unittest.TestCase):
    def run_case(self, target, status, diagnostic, expected=None, expected_file="expected_stderr.txt"):
        with tempfile.TemporaryDirectory(prefix="negative-runner-contract-") as directory:
            root = Path(directory)
            fixture = root / "snapshot" / "negative" / "probe"
            fixture.mkdir(parents=True)
            (fixture / "compile.hxml").write_text("Main\n")
            if expected is not None:
                (fixture / expected_file).write_text(expected + "\n")
            compiler = root / "haxe"
            compiler.write_text("#!/bin/sh\n" + diagnostic + "\nexit " + str(status) + "\n")
            compiler.chmod(0o755)
            environment = os.environ.copy()
            environment["PATH"] = str(root) + os.pathsep + environment["PATH"]
            result = subprocess.run(
                ["make", "-f", str(ROOT / "test" / "Makefile"),
                 "TEST_DIR=" + str(root / "snapshot"),
                 "NEGATIVE_DIR=" + str(fixture.parent), "TIMEOUT=2s", target],
                cwd=root, env=environment, text=True, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, timeout=20,
            )
            return result.returncode, result.stdout

    def test_rejection_is_not_an_infrastructure_failure(self):
        for target in ("summary-negative", "summary-negative-safe"):
            for status in (0, 124, 127, 137):
                with self.subTest(target=target, status=status):
                    code, output = self.run_case(target, status, "echo 'expected rejection' >&2")
                    self.assertNotEqual(code, 0, output)
                    self.assertNotIn("NEG-OK", output)

    def test_rejection_requires_diagnostic_evidence(self):
        for target in ("summary-negative", "summary-negative-safe"):
            for diagnostic, expected in (
                (":", None), ("echo '   ' >&2", None),
                ("echo 'unrelated error' >&2", "expected rejection"),
                ("echo 'expected rejection' >&2", ""),
            ):
                with self.subTest(target=target, diagnostic=diagnostic):
                    code, output = self.run_case(target, 1, diagnostic, expected)
                    self.assertNotEqual(code, 0, output)
                    self.assertNotIn("NEG-OK", output)

    def test_real_rejection_passes(self):
        for target in ("summary-negative", "summary-negative-safe"):
            for expected, filename in (
                (None, "expected_stderr.txt"),
                ("expected rejection", "expected_stderr.txt"),
                ("expected rejection", "expected_message.txt"),
            ):
                with self.subTest(target=target, expected=expected, filename=filename):
                    code, output = self.run_case(target, 1, "echo 'expected rejection' >&2", expected, filename)
                    self.assertEqual(code, 0, output)
                    self.assertIn("NEG-OK", output)


if __name__ == "__main__":
    unittest.main()

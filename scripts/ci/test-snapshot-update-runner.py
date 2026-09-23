#!/usr/bin/env python3
"""Verify snapshot-update failures keep diagnostics and preserve accepted output."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class SnapshotUpdateRunnerContract(unittest.TestCase):
    def run_case(self, mode, status, writes_output):
        with tempfile.TemporaryDirectory(prefix="snapshot-update-contract-") as directory:
            root = Path(directory)
            fixture = root / "snapshot" / "probe"
            fixture.mkdir(parents=True)
            (fixture / "compile.hxml").write_text("Main\n")
            (fixture / "intended").mkdir()
            (fixture / "intended" / "main.ex").write_text("accepted\n")
            (fixture / "out").mkdir()
            (fixture / "out" / "main.ex").write_text("stale\n")
            compiler = root / "haxe"
            body = "echo 'compile detail' >&2\n"
            if writes_output:
                body += "mkdir -p out\nprintf 'fresh\\n' > out/main.ex\n"
            compiler.write_text("#!/bin/sh\n" + body + "exit " + str(status) + "\n")
            compiler.chmod(0o755)
            environment = os.environ.copy()
            environment["PATH"] = str(root) + os.pathsep + environment["PATH"]
            target = ["update-intended", "TEST=probe"] if mode == "single" else ["update-probe"]
            if mode == "generic":
                target.append("POSITIVE_TESTS=")
            result = subprocess.run(
                ["make", "-f", str(ROOT / "test" / "Makefile"),
                 "TEST_DIR=" + str(root / "snapshot"), "UPDATE_TIMEOUT=2s", *target],
                cwd=root, env=environment, text=True, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, timeout=20,
            )
            logs = "\n".join(path.read_text() for path in root.glob("test-results-*-update-*.log"))
            return result.returncode, result.stdout, logs, (fixture / "intended" / "main.ex").read_text()

    def test_failure_preserves_diagnostics_and_accepted_output(self):
        for mode in ("single", "static", "generic"):
            for status in (1, 124, 137):
                with self.subTest(mode=mode, status=status):
                    code, output, logs, intended = self.run_case(mode, status, True)
                    self.assertNotEqual(code, 0, output)
                    self.assertIn("compile detail", output)
                    self.assertIn("exit " + str(status), output)
                    self.assertIn("compile detail", logs)
                    self.assertEqual(intended, "accepted\n")

    def test_success_requires_fresh_output(self):
        for mode in ("single", "static", "generic"):
            with self.subTest(mode=mode):
                code, output, _, intended = self.run_case(mode, 0, False)
                self.assertNotEqual(code, 0, output)
                self.assertEqual(intended, "accepted\n")

    def test_success_updates_expected_output(self):
        for mode in ("single", "static", "generic"):
            with self.subTest(mode=mode):
                code, output, _, intended = self.run_case(mode, 0, True)
                self.assertEqual(code, 0, output)
                self.assertEqual(intended, "fresh\n")


if __name__ == "__main__":
    unittest.main()

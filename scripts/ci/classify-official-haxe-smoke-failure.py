#!/usr/bin/env python3
"""Write a stable failure category for the official Haxe BEAM smoke."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def classify(stage: str, status: int, log: str) -> str:
	if status in {124, 137}:
		return "timeout"
	if stage == "provenance":
		return "unclassified-record"
	if stage == "haxe-compile":
		return "compiler"
	if stage == "generated-tests":
		return "missing-test"
	if stage == "mix-test":
		if "Assertion with ==" in log or "Assertion with ===" in log:
			return "assertion"
		if "Compilation error" in log or "CompileError" in log:
			return "mix"
		return "runtime"
	return stage


def main() -> None:
	if len(sys.argv) != 5:
		raise SystemExit("usage: classify-official-haxe-smoke-failure.py <stage> <status> <log> <result>")
	stage, raw_status, log_path, result_path = sys.argv[1:]
	status = int(raw_status)
	log = Path(log_path).read_text(encoding="utf-8", errors="replace") if Path(log_path).is_file() else ""
	result = {"status": "failed", "category": classify(stage, status, log), "exitCode": status}
	Path(result_path).write_text(json.dumps(result, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
	main()

#!/usr/bin/env python3
"""Fast executable contract for performance benchmark semantics."""

from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts" / "perf" / "benchmark_contract.py"
SPEC = importlib.util.spec_from_file_location("benchmark_contract", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"PERF_BENCHMARK_CONTRACT:FAIL cannot load {MODULE_PATH}")
contract = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(contract)


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


original = "package demo;\nclass Main {}\n"
variant_b = contract.source_variant(original, "B")
check(variant_b != original, "variant B must change source bytes")
check(variant_b.endswith(f"{contract.EDIT_MARKER}\n"), "variant B marker missing")
check(contract.source_variant(variant_b, "B") == variant_b, "variant B must be idempotent")
check(contract.source_variant(variant_b, "A") == original, "variant A must restore exact original bytes")

with tempfile.TemporaryDirectory(prefix="perf-benchmark-contract-") as temporary:
    source = Path(temporary) / "Main.hx"
    source.write_text(original, encoding="utf-8")
    contract.write_source_variant(source, "B")
    check(source.read_text(encoding="utf-8") == variant_b, "atomic B write differed")
    contract.write_source_variant(source, "A")
    check(source.read_text(encoding="utf-8") == original, "atomic A restore differed")

    output_root = Path(temporary) / "lib"
    output_root.mkdir()
    generated = output_root / "main.ex"
    generated.write_text("defmodule Main do\nend\n", encoding="utf-8")
    (output_root / "_GeneratedFiles.json").write_text(
        json.dumps({"filesGenerated": ["main.ex"]}),
        encoding="utf-8",
    )
    first_state, first_digests = contract.generated_output_state(output_root, {})
    check(first_state["changed_file_count"] == 1, "first output observation must see the generated file")
    unchanged_state, unchanged_digests = contract.generated_output_state(output_root, first_digests)
    check(unchanged_state["changed_file_count"] == 0, "unchanged generated output was reported as changed")
    check(unchanged_digests == first_digests, "unchanged output digest drifted")
    generated.write_text("defmodule Main do\n  def run, do: :ok\nend\n", encoding="utf-8")
    changed_state, _ = contract.generated_output_state(output_root, first_digests)
    check(changed_state["changed_paths"] == ["main.ex"], "changed generated path was not identified")

for scenario_name in ("cold", "warm_fresh_process", "edited_full_fresh_process"):
    scenario = contract.compile_scenario(scenario_name)
    for required in (
        "process_model",
        "compiler_cache_state",
        "artifact_cache_state",
        "dependency_state",
        "edit_kind",
        "demonstrated_incremental_reuse",
    ):
        check(required in scenario, f"{scenario_name} omitted {required}")

edited = contract.compile_scenario("edited_full_fresh_process")
check(edited["demonstrated_incremental_reuse"] is False, "fresh-process edit must not claim incremental reuse")
check(contract.schema_classification(1) == "legacy_v1_ambiguous_incremental_label", "schema-v1 history must stay explicit")
check(contract.schema_classification(contract.SCHEMA_VERSION) == "current", "current schema classification failed")

server = contract.watch_process_model(True)
direct = contract.watch_process_model(False)
check(server["process_model"] != direct["process_model"], "direct and server watch modes must remain distinguishable")
check(server["demonstrated_incremental_reuse"] is False, "process reuse alone must not claim module reuse")

# Exercise the real shell harness with fake compilers. This proves the public
# scenario names and result schema without paying for a Phoenix dependency build.
fixture_rel = Path("tmp") / f"perf-benchmark-contract-{os.getpid()}"
fixture_root = ROOT / fixture_rel
fake_bin = fixture_root / "fake-bin"
artifact_rel = fixture_rel / "artifacts"
out_rel = fixture_rel / "result.json"
try:
    fake_bin.mkdir(parents=True, exist_ok=True)
    for name, version in (("haxe", "4.3.7"), ("mix", "Mix 1.18 fixture")):
        executable = fake_bin / name
        script = (
            "#!/usr/bin/env bash\n"
            "set -euo pipefail\n"
            f"if [[ \"${{1:-}}\" == \"-version\" || \"${{1:-}}\" == \"--version\" ]]; then printf '%s\\n' '{version}'; exit 0; fi\n"
        )
        if name == "haxe":
            script += (
                "for argument in \"$@\"; do\n"
                "  if [[ \"$argument\" == \"--times\" ]]; then\n"
                "    printf '%s\\n' 'total | 0.010 | 100 | 100 | 1 | fixture'\n"
                "    printf '%s\\n' 'REFLAXE_ELIXIR_TIMINGS {\"schema_version\":1,\"total_wall_ms\":25.0,\"phases\":[]}'\n"
                "  fi\n"
                "done\n"
            )
        executable.write_text(script, encoding="utf-8")
        executable.chmod(0o755)

    environment = os.environ.copy()
    environment["PATH"] = f"{fake_bin}{os.pathsep}{environment['PATH']}"
    environment["HAXE_BIN"] = "haxe"
    completed = subprocess.run(
        [
            "bash",
            "scripts/perf/benchmark-todo-compile.sh",
            "--app",
            "examples/03-phoenix-app",
            "--build-file",
            "build.hxml",
            "--edited-source",
            "src_haxe/PhoenixHaxeExample.hx",
            "--artifact-dir",
            str(artifact_rel),
            "--out",
            str(out_rel),
            "--machine-state",
            "idle",
            "--phase-timers",
            "coarse",
        ],
        cwd=ROOT,
        env=environment,
        check=True,
        timeout=30,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    result_path = ROOT / out_rel
    if not result_path.is_file():
        raise AssertionError(
            "compile harness did not write its result\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )
    result = json.loads(result_path.read_text(encoding="utf-8"))
    check(result["schema_version"] == contract.SCHEMA_VERSION, "shell harness schema version")
    check(result["environment"]["machine_state"] == "idle", "machine state was not recorded")
    check(result["config"]["phase_timer_mode"] == "coarse", "phase timer mode was not recorded")
    run_names = [run["name"] for run in result["runs"]]
    check(
        run_names == ["cold", "warm_fresh_process", "edited_full_fresh_process"],
        f"unexpected compile scenarios: {run_names}",
    )
    check("incremental" not in run_names, "fresh-process edit retained the ambiguous old name")
    edited_run = result["runs"][-1]
    check(edited_run["demonstrated_incremental_reuse"] is False, "shell harness made a false reuse claim")
    check("generated_output" in edited_run, "generated-output observation is missing")
    check(edited_run["mix_recompiled_module_count"] == 0, "fake Mix compile count should be zero")
    check(
        edited_run["phases"][0]["phase"] == "apply_source_variant_b",
        "edited scenario did not record its deterministic content change",
    )
    reconciliation = edited_run["phase_reconciliation"]
    check(reconciliation["haxe_reported_total_ms"] == 10.0, "Haxe --times total was not parsed")
    check(reconciliation["reflaxe_target_total_ms"] == 25.0, "target timing JSON was not parsed")
    check(
        reconciliation["reconciled_total_ms"] == reconciliation["external_haxe_build_ms"],
        "coarse phases did not reconcile to external Haxe wall time",
    )
finally:
    shutil.rmtree(fixture_root, ignore_errors=True)

print("PERF_BENCHMARK_CONTRACT:PASS")

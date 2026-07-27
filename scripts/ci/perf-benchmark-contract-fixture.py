#!/usr/bin/env python3
"""Fast executable contract for performance benchmark semantics."""

from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


sys.dont_write_bytecode = True


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

with tempfile.TemporaryDirectory(prefix="perf-benchmark-patch-") as temporary:
    worktree = Path(temporary) / "worktree"
    worktree.mkdir()
    edited = worktree / "fixture.txt"
    edited.write_text("variant A\n", encoding="utf-8")
    patch = Path(temporary) / "edit.patch"
    patch.write_text(
        "diff --git a/fixture.txt b/fixture.txt\n"
        "--- a/fixture.txt\n"
        "+++ b/fixture.txt\n"
        "@@ -1 +1 @@\n"
        "-variant A\n"
        "+variant B\n",
        encoding="utf-8",
    )

    check(contract.patch_changed_paths(worktree, patch) == ["fixture.txt"], "patch paths were not parsed")
    contract.apply_patch_variant(worktree, patch, "B")
    check(edited.read_text(encoding="utf-8") == "variant B\n", "patch variant B was not applied")
    try:
        contract.apply_patch_variant(worktree, patch, "B")
        raise AssertionError("reapplying patch variant B should fail closed")
    except ValueError:
        pass
    check(edited.read_text(encoding="utf-8") == "variant B\n", "failed patch check modified the worktree")
    contract.apply_patch_variant(worktree, patch, "A")
    check(edited.read_text(encoding="utf-8") == "variant A\n", "patch variant A did not restore exact bytes")

todo_patch_root = ROOT / "scripts" / "perf" / "fixtures" / "todo-edits"
todo_patches = sorted(todo_patch_root.glob("*.patch"))
check(bool(todo_patches), "todo edit fixtures are missing")
for patch in todo_patches:
    changed_paths = contract.patch_changed_paths(ROOT, patch)
    check(
        all(path.startswith("examples/todo-app/") for path in changed_paths),
        f"{patch.name} changes a path outside the todo app",
    )
    with tempfile.TemporaryDirectory(prefix=f"perf-{patch.stem}-") as temporary:
        worktree = Path(temporary)
        originals: dict[str, bytes] = {}
        for relative in changed_paths:
            source = ROOT / relative
            destination = worktree / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
            originals[relative] = destination.read_bytes()

        contract.apply_patch_variant(worktree, patch, "B")
        check(
            any((worktree / relative).read_bytes() != content for relative, content in originals.items()),
            f"{patch.name} variant B changed no bytes",
        )
        contract.apply_patch_variant(worktree, patch, "A")
        for relative, content in originals.items():
            check((worktree / relative).read_bytes() == content, f"{patch.name} did not restore {relative}")

load_observation = contract.host_load_observation()
check(load_observation["cpu_count"] == os.cpu_count(), "host CPU count was not observed")
check("observed_at" in load_observation, "host load observation has no timestamp")
own_tree = contract.process_tree_rss_snapshot(os.getpid())
check(own_tree is not None, "current process RSS tree was not observable")
check(own_tree["root_pid"] == os.getpid(), "RSS snapshot changed its root process")
check(own_tree["process_count"] >= 1, "RSS snapshot omitted its root process")
check(own_tree["rss_bytes"] > 0, "RSS snapshot reported no resident memory")
check(contract.process_tree_rss_snapshot(-1) is None, "invalid PID produced an RSS snapshot")

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

identity = contract.parse_server_identity(
    "Haxe server started on port 62327 (owner_os_pid=9123)\n"
    "Haxe server relocated and started on port 62328 (owner_os_pid=9124)"
)
check(identity["haxe_server_identity_observed"] is True, "server identity was not observed")
check(identity["haxe_server_port"] == 62328, "latest server port was not selected")
check(identity["haxe_server_owner_os_pid"] == 9124, "latest server owner PID was not selected")
check(
    contract.parse_server_identity("no server here")["haxe_server_identity_observed"] is False,
    "missing server identity was invented",
)

watch_compiler_output = """REFLAXE_ELIXIR_TIMINGS {"schema_version":1,"total_wall_ms":11520.765,"phases":[]}
name  | time(s) | %
total | 12.396 | 100
== Haxe timings: haxe watch rebuild ==
  haxe.fingerprint_inputs: 1309.1 ms
  haxe.invoke: 16627.6 ms
  haxe.find_generated_files: 25.1 ms
  total wall: 18005.5 ms
"""
reconciliation = contract.watch_phase_reconciliation(18170, watch_compiler_output)
check(reconciliation is not None, "watch timing signals were not reconciled")
check(reconciliation["haxe_reported_total_ms"] == 12396.0, "Haxe --times total was not parsed")
check(reconciliation["reflaxe_target_total_ms"] == 11520.765, "Reflaxe target total was not parsed")
check(reconciliation["haxe_invoke_ms"] == 16627.6, "Mix/Haxe invocation time was not parsed")
check(
    reconciliation["outside_haxe_integration_ms"] == 164.5,
    "watcher time outside the compilation request was not preserved",
)
check(
    reconciliation["haxe_reported_excluding_reflaxe_target_ms"] == 875.235,
    "Haxe-exclusive time double-counted the nested target callback",
)
check(
    reconciliation["haxe_invoke_unattributed_ms"] == 4231.6,
    "unknown time inside the Haxe invocation was silently reassigned",
)
check(
    reconciliation["haxe_invoke_reconciled_ms"] == reconciliation["haxe_invoke_ms"],
    "nested watch timings did not reconcile to haxe.invoke",
)
check(reconciliation["timing_nesting_status"] == "consistent", "valid nesting was rejected")
inconsistent_reconciliation = contract.watch_phase_reconciliation(
    100,
    """REFLAXE_ELIXIR_TIMINGS {"schema_version":1,"total_wall_ms":25.0,"phases":[]}
total | 0.010 | 100
== Haxe timings: fixture ==
  haxe.invoke: 50.0 ms
  total wall: 60.0 ms
""",
)
check(
    inconsistent_reconciliation["timing_nesting_status"] == "inconsistent",
    "impossible nested totals were accepted",
)
check(
    "haxe_invoke_unattributed_ms" not in inconsistent_reconciliation,
    "inconsistent totals produced a misleading negative remainder",
)
check(
    contract.watch_phase_reconciliation(100, "no timing output") is None,
    "missing timing evidence produced an invented reconciliation",
)

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
                "if [[ \"${PERF_FIXTURE_FAIL_BUILD:-0}\" == \"1\" ]]; then printf '%s\\n' 'fixture build failure' >&2; exit 7; fi\n"
                "for argument in \"$@\"; do\n"
                "  if [[ \"$argument\" == \"--times\" ]]; then\n"
                "    printf '%s\\n' 'total | 0.010 | 100 | 100 | 1 | fixture'\n"
                "    printf '%s\\n' 'REFLAXE_ELIXIR_TIMINGS {\"schema_version\":1,\"total_wall_ms\":5.0,\"phases\":[]}'\n"
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
    check(
        len(result["environment"]["host_load_observations"]) == 2,
        "compile harness omitted start/end host load observations",
    )
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
    check(reconciliation["reflaxe_target_total_ms"] == 5.0, "target timing JSON was not parsed")
    check(reconciliation["timing_nesting_status"] == "consistent", "valid compile nesting was rejected")
    check(
        reconciliation["haxe_reported_excluding_reflaxe_target_ms"] == 5.0,
        "compile reconciliation double-counted the target callback",
    )
    check(
        reconciliation["reconciled_total_ms"] == reconciliation["external_haxe_build_ms"],
        "coarse phases did not reconcile to external Haxe wall time",
    )

    failure_artifact_rel = fixture_rel / "failure-artifacts"
    failure_out_rel = fixture_rel / "failure-result.json"
    failure_environment = environment.copy()
    failure_environment["PERF_FIXTURE_FAIL_BUILD"] = "1"
    failed = subprocess.run(
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
            str(failure_artifact_rel),
            "--out",
            str(failure_out_rel),
        ],
        cwd=ROOT,
        env=failure_environment,
        check=False,
        timeout=30,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    check(failed.returncode != 0, "compile harness accepted a failed Haxe phase")
    failure_result = json.loads((ROOT / failure_out_rel).read_text(encoding="utf-8"))
    check(failure_result["status"] == "failure", "failed Haxe phase produced a successful result")
    failed_run = failure_result["runs"][-1]
    check(failed_run["status"] == "failure", "failed run was not marked as failed")
    failed_phases = [phase["phase"] for phase in failed_run["phases"]]
    check(
        failed_phases[-1] == "haxe_build" and "mix_compile" not in failed_phases,
        "the harness continued into Mix after Haxe failed",
    )
finally:
    shutil.rmtree(fixture_root, ignore_errors=True)

print("PERF_BENCHMARK_CONTRACT:PASS")

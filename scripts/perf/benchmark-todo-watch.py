#!/usr/bin/env python3
"""Bounded todo-app persistent watch-cycle benchmark.

Measures edit-to-rebuild latency for `mix haxe.watch` in an isolated worktree.
The script starts one watcher, alternates either the default source comment or
an exact unified-diff fixture between states A and B, waits for the
compile-success marker, then tears everything down and writes a JSON artifact.
A persistent watcher is not automatically an incremental compiler: the result
records server use without claiming that unaffected target modules were skipped.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import shutil
import signal
import socket
import statistics
import subprocess
import sys
import time
from datetime import datetime, timezone
from typing import Any

sys.dont_write_bytecode = True

from benchmark_contract import (
    SCHEMA_VERSION,
    apply_patch_variant,
    generated_output_state,
    host_load_observation,
    patch_changed_paths,
    parse_server_identity,
    process_tree_rss_snapshot,
    source_variant,
    target_timing_report,
    watch_phase_reconciliation,
    watch_process_model,
)


ROOT_DIR = Path(__file__).resolve().parents[2]
DEFAULT_APP_REL = "examples/todo-app"
DEFAULT_ARTIFACT_DIR_REL = "tmp/perf/todo-watch"
DEFAULT_OUT_REL = "tmp/perf/watch-cycle-times.json"
DEFAULT_SOURCE_REL = "src_shared/shared/TodoTypes.hx"
WATCH_SUCCESS_MARKER = "✅ Haxe compilation successful"
WATCHER_READY_MARKER = "HaxeWatcher started monitoring"
INITIAL_SUCCESS_MARKERS = ("✓ Compiled ", WATCH_SUCCESS_MARKER)


class BenchmarkError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Measure todo-app mix haxe.watch edit-to-rebuild latency.",
    )
    parser.add_argument("--app", default=DEFAULT_APP_REL, help=f"App path relative to repo root (default: {DEFAULT_APP_REL})")
    parser.add_argument("--ref", default="HEAD", help="Git ref to benchmark in the isolated worktree (default: HEAD)")
    parser.add_argument(
        "--artifact-dir",
        default=DEFAULT_ARTIFACT_DIR_REL,
        help=f"Artifact dir relative to repo root (default: {DEFAULT_ARTIFACT_DIR_REL})",
    )
    parser.add_argument("--out", default=DEFAULT_OUT_REL, help=f"JSON output path relative to repo root (default: {DEFAULT_OUT_REL})")
    parser.add_argument(
        "--source",
        default=DEFAULT_SOURCE_REL,
        help=f"Haxe source for the default comment edit, relative to app root; ignored with --edit-patch (default: {DEFAULT_SOURCE_REL})",
    )
    parser.add_argument(
        "--edit-patch",
        help="Workspace-relative unified diff to alternate between baseline A and patched B instead of appending the default source comment",
    )
    parser.add_argument(
        "--edit-kind",
        default="source_position_only_a_b_toggle",
        help="Precise edit classification stored with every sample (default: source_position_only_a_b_toggle)",
    )
    parser.add_argument(
        "--public-api-changed",
        action="store_true",
        help="Record that the selected edit changes a public type or callable contract",
    )
    parser.add_argument("--iterations", type=int, default=5, help="Number of edit/rebuild samples to collect (default: 5)")
    parser.add_argument("--warmups", type=int, default=1, help="Number of unreported A/B rebuilds before measurement (default: 1)")
    parser.add_argument("--debounce-ms", type=int, default=150, help="Watcher debounce in milliseconds (default: 150)")
    parser.add_argument("--deadline", type=int, default=420, help="Overall benchmark deadline in seconds (default: 420)")
    parser.add_argument("--deps-get-timeout", type=int, default=int(os.environ.get("DEPS_GET_TIMEOUT", "300")))
    parser.add_argument("--deps-compile-timeout", type=int, default=int(os.environ.get("DEPS_COMPILE_TIMEOUT", "420")))
    parser.add_argument("--startup-timeout", type=int, default=180, help="Seconds to wait for watcher initial compile (default: 180)")
    parser.add_argument("--iteration-timeout", type=int, default=90, help="Seconds to wait for each watch rebuild (default: 90)")
    parser.add_argument("--settle-ms", type=int, default=3000, help="Milliseconds to wait after watcher readiness before editing (default: 3000)")
    parser.add_argument(
        "--use-haxe-server",
        action="store_true",
        help="Opt into Haxe --wait server mode instead of the default direct Haxe invocation.",
    )
    parser.add_argument(
        "--machine-state",
        choices=("unknown", "idle", "representative_loaded", "contended"),
        default=os.environ.get("BENCHMARK_MACHINE_STATE", "unknown"),
        help=(
            "Observed host state: representative_loaded admits stable everyday background work "
            "for paired optimization decisions; only controlled idle runs may support promotion claims"
        ),
    )
    parser.add_argument(
        "--phase-timers",
        choices=("off", "coarse"),
        default=os.environ.get("PHASE_TIMERS", "off"),
        help="Enable coarse Haxe/Mix target timing in watcher logs (default: off)",
    )
    parser.add_argument("--keep-worktree", action="store_true", help="Do not remove the benchmark worktree on exit")
    return parser.parse_args()


def require_safe_relative_path(label: str, value: str) -> None:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts:
        raise BenchmarkError(f"{label} must be a workspace-relative path without '..': {value}")


def command_exists(command: str) -> bool:
    return shutil.which(command) is not None


def run_capture(command: list[str], cwd: Path = ROOT_DIR) -> str:
    try:
        return subprocess.check_output(command, cwd=cwd, stderr=subprocess.STDOUT, text=True).strip()
    except Exception as exc:
        return f"<unavailable: {exc}>"


def build_input_digests(benchmark_root: Path, app_rel: str) -> dict[str, Any]:
    """Hash pinned build inputs without storing machine-local absolute paths."""

    candidates = [benchmark_root / ".haxerc", benchmark_root / "package-lock.json", benchmark_root / app_rel / "mix.lock"]
    candidates.extend(sorted((benchmark_root / "haxe_libraries").glob("*.hxml")))
    candidates.extend(sorted((benchmark_root / app_rel).rglob("*.hxml")))
    digests: dict[str, str] = {}
    for path in candidates:
        if path.is_file():
            digests[str(path.relative_to(benchmark_root))] = hashlib.sha256(path.read_bytes()).hexdigest()
    combined = hashlib.sha256()
    for path, digest in sorted(digests.items()):
        combined.update(path.encode("utf-8"))
        combined.update(b"\0")
        combined.update(digest.encode("ascii"))
        combined.update(b"\n")
    return {"combined_sha256": combined.hexdigest(), "files": digests}


def monotonic_ms() -> int:
    return int(time.monotonic() * 1000)


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def tail_text(path: Path, max_lines: int = 80) -> str:
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return ""
    return "\n".join(lines[-max_lines:])


def target_timing_reports(path: Path) -> list[dict[str, Any]]:
    """Read opt-in machine-readable target reports from a Haxe/Mix log."""

    prefix = "REFLAXE_ELIXIR_TIMINGS "
    reports: list[dict[str, Any]] = []
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return reports
    for line in lines:
        marker = line.find(prefix)
        if marker < 0:
            continue
        try:
            reports.append(json.loads(line[marker + len(prefix) :]))
        except json.JSONDecodeError:
            continue
    return reports


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def ensure_tools() -> None:
    for command in ("git", "mix", "elixir", "erl"):
        if not command_exists(command):
            raise BenchmarkError(f"required command not found: {command}")

    haxe_bin = os.environ.get("HAXE_BIN", "haxe")
    if not command_exists(haxe_bin):
        raise BenchmarkError(f"Haxe binary not found: {haxe_bin}")


def run_phase(
    *,
    name: str,
    command: list[str],
    cwd: Path,
    timeout: int,
    log_dir: Path,
    phases: list[dict[str, Any]],
    env: dict[str, str] | None = None,
) -> None:
    log_path = log_dir / f"{name}.log"
    start = monotonic_ms()
    print(f"[watch-bench] {name} (timeout={timeout}s)")
    with log_path.open("w", encoding="utf-8") as log_file:
        try:
            completed = subprocess.run(
                command,
                cwd=cwd,
                env=env,
                stdout=log_file,
                stderr=subprocess.STDOUT,
                text=True,
                timeout=timeout,
                check=False,
            )
            exit_code = completed.returncode
            status = "success" if exit_code == 0 else "failure"
        except subprocess.TimeoutExpired:
            exit_code = 124
            status = "timeout"

    duration_ms = monotonic_ms() - start
    phase = {
        "name": name,
        "status": status,
        "exit_code": exit_code,
        "duration_ms": duration_ms,
        "timeout_seconds": timeout,
        "command": " ".join(command),
        "log": str(log_path.relative_to(ROOT_DIR)),
    }
    if status != "success":
        phase["log_tail"] = tail_text(log_path)
    phases.append(phase)
    print(f"[watch-bench] {name} {status} {duration_ms}ms")

    if status != "success":
        raise BenchmarkError(f"{name} failed; see {phase['log']}")


def prepare_worktree(worktree: Path, ref: str) -> None:
    if (worktree / ".git").exists():
        subprocess.run(["git", "-C", str(ROOT_DIR), "worktree", "remove", "--force", str(worktree)], check=False)
    elif worktree.exists():
        shutil.rmtree(worktree)

    subprocess.run(["git", "-C", str(ROOT_DIR), "worktree", "prune"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"[watch-bench] creating isolated worktree at {worktree.relative_to(ROOT_DIR)} (ref={ref})")
    subprocess.run(["git", "-C", str(ROOT_DIR), "worktree", "add", "--detach", str(worktree), ref], check=True, stdout=subprocess.DEVNULL)


def remove_worktree(worktree: Path) -> None:
    if (worktree / ".git").exists():
        subprocess.run(["git", "-C", str(ROOT_DIR), "worktree", "remove", "--force", str(worktree)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def base_env(args: argparse.Namespace) -> dict[str, str]:
    env = os.environ.copy()
    env.setdefault("MIX_ENV", "test")
    if args.use_haxe_server:
        env.setdefault("HAXE_SERVER_PORT", str(free_port()))
    else:
        env["HAXE_NO_SERVER"] = "1"
    if args.phase_timers == "coarse":
        env["HAXE_TIMINGS"] = "1"
        env["REFLAXE_ELIXIR_TIMINGS"] = "1"
    return env


def read_from(log_path: Path, offset: int) -> tuple[str, int]:
    try:
        with log_path.open("r", encoding="utf-8", errors="replace") as log_file:
            log_file.seek(offset)
            text = log_file.read()
            return text, log_file.tell()
    except FileNotFoundError:
        return "", offset


def wait_for_marker(
    *,
    process: subprocess.Popen[str],
    log_path: Path,
    offset: int,
    markers: tuple[str, ...],
    timeout: int,
    label: str,
) -> tuple[int, str]:
    deadline = time.monotonic() + timeout
    current_offset = offset
    collected = ""
    while time.monotonic() < deadline:
        text, current_offset = read_from(log_path, current_offset)
        if text:
            collected += text
            if any(marker in collected for marker in markers):
                return current_offset, collected

        exit_code = process.poll()
        if exit_code is not None:
            raise BenchmarkError(f"watcher exited while waiting for {label} (exit={exit_code})\n{tail_text(log_path)}")

        time.sleep(0.1)

    raise BenchmarkError(f"timed out waiting for {label}\n{tail_text(log_path)}")


def kill_process_group(process: subprocess.Popen[str] | None) -> None:
    if process is None or process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait(timeout=10)


def edit_source(source_path: Path, original: str, variant: str) -> None:
    updated = source_variant(original, variant)
    temp_path = source_path.with_name(f"{source_path.name}.watch-bench.tmp")
    temp_path.write_text(updated, encoding="utf-8")
    temp_path.replace(source_path)


def percentile_nearest_rank(values: list[int], percentile: float) -> int:
    if not values:
        return 0
    ordered = sorted(values)
    index = max(0, math.ceil(percentile * len(ordered)) - 1)
    return ordered[index]


def summarize(samples: list[dict[str, Any]]) -> dict[str, Any]:
    durations = [int(sample["duration_ms"]) for sample in samples]
    if not durations:
        return {"count": 0}
    return {
        "count": len(durations),
        "min_ms": min(durations),
        "max_ms": max(durations),
        "mean_ms": round(statistics.fmean(durations), 2),
        "p50_ms": percentile_nearest_rank(durations, 0.50),
        "p95_ms": percentile_nearest_rank(durations, 0.95),
    }


def memory_snapshot(process_info: dict[str, Any]) -> dict[str, Any]:
    """Observe persistent process memory after a completed rebuild."""

    return {
        "observed_at": now_utc(),
        "watcher_process_tree": process_tree_rss_snapshot(process_info.get("watcher_pid")),
        "haxe_server_process_tree": process_tree_rss_snapshot(
            process_info.get("haxe_server_owner_os_pid")
        ),
    }


def measure_watch_cycles(
    *,
    benchmark_root: Path,
    app_dir: Path,
    source_path: Path | None,
    patch_path: Path | None,
    edited_paths: list[str],
    log_dir: Path,
    phases: list[dict[str, Any]],
    samples: list[dict[str, Any]],
    warmup_samples: list[dict[str, Any]],
    process_info: dict[str, Any],
    args: argparse.Namespace,
    env: dict[str, str],
) -> None:
    watch_log = log_dir / "watch.log"
    command = [
        "mix",
        "haxe.watch",
        "--hxml",
        "build-server.hxml",
        "--dirs",
        "src_haxe/server,src_shared,src_haxe/contexts",
        "--debounce",
        str(args.debounce_ms),
        "--verbose",
    ]

    print("[watch-bench] starting watcher")
    start_ms = monotonic_ms()
    process: subprocess.Popen[str] | None = None
    with watch_log.open("w", encoding="utf-8") as log_file:
        try:
            process = subprocess.Popen(
                command,
                cwd=app_dir,
                env=env,
                stdout=log_file,
                stderr=subprocess.STDOUT,
                text=True,
                start_new_session=True,
            )
            process_info["watcher_pid"] = process.pid
            process_info.update(
                {
                    "haxe_server_identity_observed": False,
                    "haxe_server_port": None,
                    "haxe_server_owner_os_pid": None,
                }
            )
            offset, initial_chunk = wait_for_marker(
                process=process,
                log_path=watch_log,
                offset=0,
                markers=INITIAL_SUCCESS_MARKERS,
                timeout=args.startup_timeout,
                label="initial watcher compile",
            )
            if WATCHER_READY_MARKER not in initial_chunk:
                offset, _ = wait_for_marker(
                    process=process,
                    log_path=watch_log,
                    offset=offset,
                    markers=(WATCHER_READY_MARKER,),
                    timeout=args.startup_timeout,
                    label="watcher readiness",
                )
            if args.use_haxe_server:
                process_info.update(parse_server_identity(watch_log.read_text(encoding="utf-8", errors="replace")))
            process_info["memory_measurement"] = {
                "method": "post_cycle_process_tree_rss_snapshot",
                "unit": "bytes",
                "timing": "after the timed edit-to-success interval",
                "limitation": "This is retained-memory evidence, not peak compile memory.",
                "overlap": "The Haxe-server tree may be contained in the watcher tree; do not add them.",
            }
            process_info["memory_before_samples"] = memory_snapshot(process_info)
            phases.append(
                {
                    "name": "watcher_ready",
                    "status": "success",
                    "duration_ms": monotonic_ms() - start_ms,
                    "timeout_seconds": args.startup_timeout,
                    "command": " ".join(command),
                    "log": str(watch_log.relative_to(ROOT_DIR)),
                }
            )
            time.sleep(args.settle_ms / 1000)

            original = source_path.read_text(encoding="utf-8") if source_path is not None else None
            _, prior_output_digests = generated_output_state(app_dir / "lib", {})
            total_cycles = args.warmups + args.iterations
            current_variant = "A"
            try:
                for cycle in range(1, total_cycles + 1):
                    variant = "B" if cycle % 2 == 1 else "A"
                    load_before_edit = host_load_observation()
                    before_edit_ms = monotonic_ms()
                    if patch_path is not None:
                        apply_patch_variant(benchmark_root, patch_path, variant)
                    elif source_path is not None and original is not None:
                        edit_source(source_path, original, variant)
                    else:
                        raise BenchmarkError("benchmark edit has neither a source nor a patch")
                    current_variant = variant
                    offset, chunk = wait_for_marker(
                        process=process,
                        log_path=watch_log,
                        offset=offset,
                        markers=(WATCH_SUCCESS_MARKER,),
                        timeout=args.iteration_timeout,
                        label=f"watch rebuild {cycle}",
                    )
                    duration_ms = monotonic_ms() - before_edit_ms
                    is_warmup = cycle <= args.warmups
                    measured_iteration = cycle - args.warmups
                    sample = {
                        "iteration": cycle if is_warmup else measured_iteration,
                        "warmup": is_warmup,
                        "duration_ms": duration_ms,
                        "edited_paths": edited_paths,
                        "source_variant": variant,
                        "edit_kind": args.edit_kind,
                        "public_api_changed": args.public_api_changed,
                        "status": "success",
                        "host_load_before_edit": load_before_edit,
                        "host_load_after_success": host_load_observation(),
                    }
                    sample["memory_after_success"] = memory_snapshot(process_info)
                    timing = target_timing_report(chunk)
                    if timing is not None:
                        sample["reflaxe_target_timing"] = timing
                    reconciliation = watch_phase_reconciliation(duration_ms, chunk)
                    if reconciliation is not None:
                        sample["phase_reconciliation"] = reconciliation
                    output_state, prior_output_digests = generated_output_state(app_dir / "lib", prior_output_digests)
                    sample["generated_output"] = output_state
                    if is_warmup:
                        warmup_samples.append(sample)
                        print(f"[watch-bench] warmup {cycle}/{args.warmups}: {duration_ms}ms")
                    else:
                        samples.append(sample)
                        print(f"[watch-bench] iteration {measured_iteration}/{args.iterations}: {duration_ms}ms")

                    if "Compilation failed" in chunk:
                        raise BenchmarkError(f"watch rebuild {cycle} included a failure marker\n{tail_text(watch_log)}")

                    time.sleep(0.2)
            finally:
                if current_variant == "B":
                    # Stop the watcher before restoring source A. Otherwise the
                    # cleanup edit can start an unmeasured rebuild while this
                    # benchmark is tearing the process down.
                    kill_process_group(process)
                    process = None
                    if patch_path is not None:
                        apply_patch_variant(benchmark_root, patch_path, "A")
                    elif source_path is not None and original is not None:
                        edit_source(source_path, original, "A")
        except Exception:
            phases.append(
                {
                    "name": "watcher",
                    "status": "failure",
                    "duration_ms": monotonic_ms() - start_ms,
                    "timeout_seconds": args.startup_timeout,
                    "command": " ".join(command),
                    "log": str(watch_log.relative_to(ROOT_DIR)),
                    "log_tail": tail_text(watch_log),
                }
            )
            raise
        finally:
            kill_process_group(process)


def build_result(
    args: argparse.Namespace,
    edit_metadata: dict[str, Any],
    phases: list[dict[str, Any]],
    samples: list[dict[str, Any]],
    warmup_samples: list[dict[str, Any]],
    process_info: dict[str, Any],
    status: str,
) -> dict[str, Any]:
    dirty = run_capture(["git", "status", "--porcelain"]) != ""
    haxe_bin = os.environ.get("HAXE_BIN", "haxe")
    watch_log = ROOT_DIR / args.artifact_dir / "logs" / "watch.log"
    benchmark_root = ROOT_DIR / args.artifact_dir / "worktree"
    result = {
        "schema_version": SCHEMA_VERSION,
        "schema_classification": "current",
        "generated_at": now_utc(),
        "status": status,
        "repo": {
            "harness_head": run_capture(["git", "rev-parse", "HEAD"]),
            "benchmark_head": run_capture(["git", "rev-parse", "HEAD"], benchmark_root),
            "ref": args.ref,
            "dirty": dirty,
        },
        "config": {
            "app": args.app,
            "source": args.source if args.edit_patch is None else None,
            **edit_metadata,
            "artifact_dir": args.artifact_dir,
            "output": args.out,
            "iterations": args.iterations,
            "warmups": args.warmups,
            "debounce_ms": args.debounce_ms,
            "settle_ms": args.settle_ms,
            "use_haxe_server": args.use_haxe_server,
            "phase_timer_mode": args.phase_timers,
            "build_input_digests": build_input_digests(benchmark_root, args.app),
            **watch_process_model(args.use_haxe_server, args.edit_kind),
            "timeouts_seconds": {
                "deadline": args.deadline,
                "deps_get": args.deps_get_timeout,
                "deps_compile": args.deps_compile_timeout,
                "startup": args.startup_timeout,
                "iteration": args.iteration_timeout,
            },
        },
        "environment": {
            "machine_state": args.machine_state,
            "machine_state_source": "explicit_benchmark_label",
            "cpu_count": os.cpu_count(),
            "load_average": list(os.getloadavg()) if hasattr(os, "getloadavg") else None,
            "os": platform.platform(),
            "uname": run_capture(["uname", "-a"]),
            "haxe": run_capture([haxe_bin, "-version"]),
            "elixir": run_capture(["elixir", "--version"]),
            "mix": run_capture(["mix", "--version"]),
            "otp_release": run_capture(["erl", "-noshell", "-eval", 'io:format("~s", [erlang:system_info(otp_release)]), halt().']),
            "host_load_observations": [
                process_info.get("host_load_at_start"),
                host_load_observation(),
            ],
        },
        "phases": phases,
        "processes": {
            key: value for key, value in process_info.items() if key != "host_load_at_start"
        },
        "warmup_samples": warmup_samples,
        "samples": samples,
        "summary": summarize(samples),
    }
    reports = target_timing_reports(watch_log)
    if reports:
        result["reflaxe_target_timing_reports"] = reports
    return result


def write_result(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"[watch-bench] wrote {path.relative_to(ROOT_DIR)}")


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(line_buffering=True)

    args = parse_args()
    for label, value in (
        ("--app", args.app),
        ("--artifact-dir", args.artifact_dir),
        ("--out", args.out),
        ("--source", args.source),
    ):
        require_safe_relative_path(label, value)
    if args.edit_patch is not None:
        require_safe_relative_path("--edit-patch", args.edit_patch)
        if args.edit_kind == "source_position_only_a_b_toggle":
            raise BenchmarkError("--edit-patch requires an explicit --edit-kind")
    elif args.public_api_changed:
        raise BenchmarkError("--public-api-changed requires --edit-patch")
    try:
        watch_process_model(args.use_haxe_server, args.edit_kind)
    except ValueError as error:
        raise BenchmarkError(str(error)) from error
    if args.iterations <= 0:
        raise BenchmarkError("--iterations must be greater than zero")
    if args.warmups < 0:
        raise BenchmarkError("--warmups must be zero or greater")
    if args.deadline <= 0:
        raise BenchmarkError("--deadline must be greater than zero")

    ensure_tools()

    artifact_dir = ROOT_DIR / args.artifact_dir
    out_path = ROOT_DIR / args.out
    worktree = artifact_dir / "worktree"
    log_dir = artifact_dir / "logs"
    phases: list[dict[str, Any]] = []
    samples: list[dict[str, Any]] = []
    warmup_samples: list[dict[str, Any]] = []
    process_info: dict[str, Any] = {}
    process_info["host_load_at_start"] = host_load_observation()
    edit_metadata: dict[str, Any] = {
        "edit_kind": args.edit_kind,
        "public_api_changed": args.public_api_changed,
        "edit_patch": None,
        "edit_patch_sha256": None,
        "edited_paths": [(Path(args.app) / args.source).as_posix()],
    }
    status = "failure"
    deadline = time.monotonic() + args.deadline

    artifact_dir.mkdir(parents=True, exist_ok=True)
    log_dir.mkdir(parents=True, exist_ok=True)

    try:
        prepare_worktree(worktree, args.ref)
        app_dir = worktree / args.app
        if not app_dir.is_dir():
            raise BenchmarkError(f"app not found in worktree: {args.app}")

        patch_path: Path | None = None
        source_path: Path | None = None
        if args.edit_patch is not None:
            patch_path = (ROOT_DIR / args.edit_patch).resolve()
            try:
                patch_path.relative_to(ROOT_DIR.resolve())
            except ValueError as exc:
                raise BenchmarkError(f"--edit-patch resolves outside the workspace: {args.edit_patch}") from exc
            if not patch_path.is_file():
                raise BenchmarkError(f"edit patch not found: {args.edit_patch}")
            try:
                edited_paths = patch_changed_paths(worktree, patch_path)
            except ValueError as exc:
                raise BenchmarkError(str(exc)) from exc
            app_prefix = f"{Path(args.app).as_posix()}/"
            outside_app = [path for path in edited_paths if not path.startswith(app_prefix)]
            if outside_app:
                raise BenchmarkError(f"edit patch changes paths outside {args.app}: {outside_app}")
            edit_metadata.update(
                {
                    "edit_patch": args.edit_patch,
                    "edit_patch_sha256": hashlib.sha256(patch_path.read_bytes()).hexdigest(),
                    "edited_paths": edited_paths,
                }
            )
        else:
            source_path = app_dir / args.source
            if not source_path.is_file():
                raise BenchmarkError(f"source not found in app: {args.source}")
            edited_paths = [(Path(args.app) / args.source).as_posix()]

        env = base_env(args)
        run_phase(
            name="deps_get",
            command=["mix", "deps.get"],
            cwd=app_dir,
            timeout=min(args.deps_get_timeout, max(1, int(deadline - time.monotonic()))),
            log_dir=log_dir,
            phases=phases,
            env=env,
        )
        run_phase(
            name="deps_compile",
            command=["mix", "deps.compile"],
            cwd=app_dir,
            timeout=min(args.deps_compile_timeout, max(1, int(deadline - time.monotonic()))),
            log_dir=log_dir,
            phases=phases,
            env=env,
        )

        remaining = int(deadline - time.monotonic())
        if remaining <= 0:
            raise BenchmarkError("overall deadline exceeded before watch measurement")

        measure_watch_cycles(
            benchmark_root=worktree,
            app_dir=app_dir,
            source_path=source_path,
            patch_path=patch_path,
            edited_paths=edited_paths,
            log_dir=log_dir,
            phases=phases,
            samples=samples,
            warmup_samples=warmup_samples,
            process_info=process_info,
            args=args,
            env=env,
        )
        status = "success"
    except Exception as exc:
        print(f"[watch-bench] ERROR: {exc}", file=sys.stderr)
        status = "failure"
    finally:
        result = build_result(args, edit_metadata, phases, samples, warmup_samples, process_info, status)
        write_result(out_path, result)
        if not args.keep_worktree:
            remove_worktree(worktree)

    summary = summarize(samples)
    if status == "success":
        print(
            "[watch-bench] summary "
            f"count={summary['count']} p50={summary['p50_ms']}ms p95={summary['p95_ms']}ms "
            f"min={summary['min_ms']}ms max={summary['max_ms']}ms"
        )
        return 0
    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BenchmarkError as exc:
        print(f"[watch-bench] ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2)

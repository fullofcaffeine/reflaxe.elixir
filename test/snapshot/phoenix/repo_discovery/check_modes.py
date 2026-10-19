#!/usr/bin/env python3
"""Observe discovery through generated files, in cold and persistent compilers.

Reuse the normal snapshot's independently authored Elixir expectations. This
native observer owns process lifecycle and filesystem assertions, not compiler
policy. No installed compiler or consumer dependency is changed.
"""

import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time


FIXTURE = Path(__file__).resolve().parent
ROOT = FIXTURE.parents[3]
DIAGNOSTIC = "elixir_discovery must be auto or explicit."


def native_haxe():
    version = json.loads((ROOT / ".haxerc").read_text())["version"]
    override = os.environ.get("HAXE_SERVER_BIN")
    candidates = [Path(override)] if override else [
        Path.home() / "haxe/versions" / version / "haxe",
        Path.home() / ".haxe/versions" / version / "haxe",
    ]
    for candidate in candidates:
        if candidate.is_file() and os.access(candidate, os.X_OK):
            result = subprocess.run(
                [str(candidate), "--version"], capture_output=True, text=True,
                timeout=10, check=True,
            )
            if result.stdout.strip() != version:
                raise RuntimeError(f"Expected Haxe {version}, got {result.stdout.strip()}")
            return str(candidate)
    raise RuntimeError(f"Set HAXE_SERVER_BIN to the native Haxe {version} executable")


def main():
    haxe = native_haxe()
    environment = dict(os.environ)
    environment["HAXELIB_PATH"] = str(ROOT)
    # npm supplies the Lix haxelib resolver on PATH, as in the existing
    # server-cache fixture. The native Haxe executable owns the server protocol.
    (ROOT / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="discovery-modes-", dir=ROOT / "tmp") as temporary:
        output = Path(temporary) / "out"

        def compile_case(label, options, wants_repo, port=None, invalid=False):
            print(f"RUN {label}", flush=True)
            command = [haxe]
            if port is not None:
                command += ["--connect", str(port)]
            command += ["compile.hxml", *options, "-D", f"elixir_output={output}"]
            result = subprocess.run(
                command, cwd=FIXTURE, env=environment, capture_output=True,
                text=True, timeout=360,
            )
            detail = result.stdout + result.stderr
            if invalid:
                if result.returncode == 0 or DIAGNOSTIC not in detail:
                    raise AssertionError(f"{label}: expected invalid selection diagnostic\n{detail}")
            else:
                if result.returncode != 0:
                    raise AssertionError(f"{label}: compiler failed\n{detail}")
                repo = output / "my_app/repo.ex"
                if repo.exists() != wants_repo:
                    raise AssertionError(f"{label}: unexpected repository-module presence")
                expected_files = ["main.ex", "probe.ex"] + (["my_app/repo.ex"] if wants_repo else [])
                for relative in expected_files:
                    expected = (FIXTURE / "intended" / relative).read_bytes()
                    if (output / relative).read_bytes() != expected:
                        raise AssertionError(f"{label}: {relative} differs from intended Elixir")
                runtime_environment = dict(environment)
                runtime_environment["ERL_FLAGS"] = "+S 2:2"
                observed = subprocess.run(
                    ["elixir", "-r", str(output / "probe.ex"), "-r", str(output / "main.ex"),
                     "-e", 'IO.write(Main.probe())'],
                    env=runtime_environment, capture_output=True, text=True, timeout=30,
                )
                if observed.returncode != 0 or observed.stdout != "42":
                    raise AssertionError(f"{label}: native dependency result failed\n{observed.stdout}{observed.stderr}")
            print(f"PASS {label}", flush=True)

        explicit = ["-D", "elixir_discovery=explicit"]
        compile_case("cold default", [], True)
        compile_case("cold explicit removes previously discovered output", explicit, False)
        compile_case("cold invalid", ["-D", "elixir_discovery=invalid"], False, invalid=True)
        with socket.socket() as socket_reservation:
            socket_reservation.bind(("127.0.0.1", 0))
            port = socket_reservation.getsockname()[1]
        with (Path(temporary) / "server.log").open("w+") as log:
            server = subprocess.Popen(
                [haxe, "--wait", str(port)], cwd=FIXTURE, env=environment,
                stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT,
            )
            try:
                deadline = time.monotonic() + 10
                while True:
                    if server.poll() is not None:
                        raise RuntimeError("Compiler server exited before readiness")
                    try:
                        with socket.create_connection(("127.0.0.1", port), timeout=0.2):
                            break
                    except OSError:
                        if time.monotonic() >= deadline:
                            raise RuntimeError("Compiler server did not become ready")
                        time.sleep(0.1)
                compile_case("server default", [], True, port)
                compile_case("server explicit removes discovered output", explicit, False, port)
                compile_case("server explicit annotated root", [*explicit, "myapp.Repo"], True, port)
                compile_case("server auto restores discovery", ["-D", "elixir_discovery=auto"], True, port)
                compile_case("server invalid", ["-D", "elixir_discovery=invalid"], False, port, True)
            except Exception:
                log.flush()
                log.seek(0)
                print(log.read(), flush=True)
                raise
            finally:
                server.terminate()
                try:
                    server.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()


if __name__ == "__main__":
    main()

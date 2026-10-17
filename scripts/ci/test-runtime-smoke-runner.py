#!/usr/bin/env python3
"""Observe the real smoke entrypoint with isolated compiler/runtime stand-ins."""
from contextlib import contextmanager
import json
import os
from pathlib import Path
import re
import shutil
import signal
import time
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class RuntimeSmokeRunnerTest(unittest.TestCase):
    @contextmanager
    def fixture_environment(self):
        with tempfile.TemporaryDirectory(prefix='runtime-smoke-contract-') as directory:
            root = Path(directory).resolve()
            for name in ['scripts/test-runtime-smoke.sh', 'scripts/util/with-timeout.sh', 'scripts/with-timeout.sh', 'scripts/runtime-smoke.mk']:
                source = ROOT / name
                if source.exists():
                    target = root / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source, target)
            source = (ROOT / 'scripts/test-runtime-smoke.sh').read_text()
            fixtures = re.findall(r'^  "(test/[^"\n]+)"$', source, re.MULTILINE)
            self.assertTrue(fixtures)
            for name in fixtures:
                fixture = root / name
                fixture.mkdir(parents=True)
                (fixture / 'compile.hxml').write_text('Main\n')
            (root / 'scripts/ci').mkdir(parents=True)
            (root / 'scripts/ci/runtime-smoke-otp-core.sh').write_text('echo OTP >> "$FIXTURE_LOG"\n')
            binary = root / 'bin'
            binary.mkdir()
            compiler = binary / 'haxe'
            compiler.write_text('''#!/usr/bin/env python3
import json, os, time
from pathlib import Path
name=str(Path.cwd())
def event(kind):
 with open(os.environ['FIXTURE_LOG'],'a') as f:
  f.write(json.dumps([kind,name,time.monotonic()])+'\\n')
event('start')
if os.environ.get('CHILD_PIDS'):
 import subprocess, sys
 child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)'])
 with open(os.environ['CHILD_PIDS'], 'a') as f:
  f.write(str(os.getpid())+' '+str(child.pid)+'\\n')
if os.environ.get('FAIL_PHASE') == 'compile':
 raise SystemExit(7)
time.sleep(float(os.environ.get('COMPILE_DELAY', '0.08')))
Path('out').mkdir(exist_ok=True)
Path('out/main.ex').write_text('')
event('end')
''')
            compiler.chmod(0o755)
            runtime = binary / 'elixir'
            runtime.write_text('''#!/bin/sh
case "$1" in
 *validate-generated-elixir-warnings.exs) phase=strict ;;
 *) phase=runtime ;;
esac
if [ "$FAIL_PHASE" = "$phase" ]; then exit 9; fi
exit 0
''')
            runtime.chmod(0o755)
            env = os.environ.copy()
            log = root / 'events'
            env.update(PATH=str(binary)+os.pathsep+env['PATH'], FIXTURE_LOG=str(log))
            yield root, env, log, fixtures

    def run_runner(self, root, env, *arguments):
        return subprocess.run(['bash', str(root / 'scripts/test-runtime-smoke.sh'), *arguments],
                              env=env, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, timeout=45)

    def test_bounded_workers_keep_every_fixture_and_otp(self):
        for jobs in [1, 2]:
            with self.subTest(jobs=jobs), self.fixture_environment() as (root, env, log, fixtures):
                result = self.run_runner(root, env, '--jobs', str(jobs))
                self.assertEqual(result.returncode, 0, result.stdout)
                lines = log.read_text().splitlines()
                self.assertEqual(lines[-1], 'OTP')
                events = [json.loads(line) for line in lines[:-1]]
                starts = [name for kind, name, _ in events if kind == 'start']
                self.assertCountEqual(starts, [str(root / name) for name in fixtures])
                active = peak = 0
                for kind, _, _ in sorted(events, key=lambda event:event[2]):
                    active += 1 if kind == 'start' else -1
                    peak = max(active, peak)
                self.assertEqual(active, 0)
                self.assertEqual(peak, jobs)

    def test_failed_phase_cannot_report_success_or_run_otp(self):
        for phase in ['compile', 'strict', 'runtime']:
            with self.subTest(phase=phase), self.fixture_environment() as (root, env, log, _):
                env['FAIL_PHASE'] = phase
                result = self.run_runner(root, env, '--jobs', '2')
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertNotIn('All runtime smoke tests passed', result.stdout)
                self.assertNotIn('OTP', log.read_text())

    def test_compile_timeout_cannot_run_otp(self):
        with self.fixture_environment() as (root, env, log, _):
            env.update(COMPILE_DELAY='3', COMPILE_TIMEOUT_SECS='1')
            result = self.run_runner(root, env, '--jobs', '2')
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn('compile failed:', result.stdout)
            self.assertNotIn('OTP', log.read_text())

    def test_whole_run_deadline_is_nonpassing(self):
        with self.fixture_environment() as (root, env, log, _):
            env.update(COMPILE_DELAY='5', RUNTIME_SMOKE_TIMEOUT_SECS='1')
            result = self.run_runner(root, env, '--jobs', '2')
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertNotIn('All runtime smoke tests passed', result.stdout)
            self.assertNotIn('OTP', log.read_text())

    def test_interrupt_stops_compiler_descendants(self):
        with self.fixture_environment() as (root, env, log, _):
            pids_file = root / 'pids'
            env.update(CHILD_PIDS=str(pids_file), COMPILE_DELAY='30')
            with (root / 'output').open('w') as output:
                process = subprocess.Popen(['bash', str(root / 'scripts/test-runtime-smoke.sh'), '--jobs', '2'],
                                           env=env, stdout=output, stderr=subprocess.STDOUT,
                                           start_new_session=True)
                pids = []
                try:
                    deadline = time.monotonic() + 10
                    while time.monotonic() < deadline:
                        if pids_file.exists():
                            pids = [int(value) for value in pids_file.read_text().split()]
                            if len(pids) >= 4:
                                break
                        time.sleep(0.05)
                    self.assertGreaterEqual(len(pids), 4, 'Two compiler trees must start before interruption')
                    process.terminate()
                    process.wait(timeout=10)
                    deadline = time.monotonic() + 3
                    def alive(pid):
                        result = subprocess.run(['ps', '-o', 'stat=', '-p', str(pid)], capture_output=True, text=True)
                        return result.returncode == 0 and result.stdout.strip() and not result.stdout.strip().startswith('Z')
                    while time.monotonic() < deadline and any(alive(pid) for pid in pids):
                        time.sleep(0.05)
                    self.assertFalse([pid for pid in pids if alive(pid)], 'Interrupted runner left compiler descendants alive')
                    self.assertNotIn('OTP', log.read_text())
                finally:
                    # Reclaim only this test session, including timeout-created groups.
                    groups = {process.pid}
                    for pid in pids:
                        try:
                            if os.getsid(pid) == process.pid:
                                groups.add(os.getpgid(pid))
                        except ProcessLookupError:
                            pass
                    for group in groups:
                        try:
                            os.killpg(group, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                    process.wait(timeout=5)

    def test_invalid_selection_never_starts_a_compiler(self):
        for args in [('--jobs', '0'), ('--jobs', '-1'), ('--jobs', 'bad'), ('--fixture', 'test/unknown')]:
            with self.subTest(args=args), self.fixture_environment() as (root, env, log, _):
                result = self.run_runner(root, env, *args)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertFalse(log.exists())

    def test_single_fixture_uses_the_same_native_path(self):
        with self.fixture_environment() as (root, env, log, fixtures):
            result = self.run_runner(root, env, '--fixture', fixtures[0])
            self.assertEqual(result.returncode, 0, result.stdout)
            events = [json.loads(line) for line in log.read_text().splitlines()]
            self.assertEqual([event[0] for event in events], ['start', 'end'])
            self.assertTrue(all(event[1] == str(root / fixtures[0]) for event in events))


if __name__ == '__main__':
    unittest.main()

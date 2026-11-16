#!/usr/bin/env python3
"""Check scripts/test-differential.sh with stand-in haxe and elixir commands.

The differential runner is a gate: a wrong PASS hides wrong code. These tests
run the real script on small temporary fixture sets. The stand-in `haxe` and
`elixir` commands print what each fixture's marker files ask for, so every
status and every known-list rule can be checked in seconds, without a real
compile.
"""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]

FAKE_HAXE = r'''#!/usr/bin/env bash
cp=""; interp=0; out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -cp) cp="$2"; shift 2 ;;
    --interp) interp=1; shift ;;
    -D) case "$2" in elixir_output=*) out="${2#elixir_output=}" ;; esac; shift 2 ;;
    *) shift ;;
  esac
done
if [[ $interp == 1 ]]; then
  [[ -f $cp/interp-fail ]] && { echo "Main.hx:1: type error" >&2; exit 1; }
  cat "$cp/interp.txt"; exit 0
fi
[[ -f $cp/haxe-fail ]] && { echo "haxe compile error" >&2; exit 1; }
mkdir -p "$out"; echo "$cp" > "$out/main.ex"
'''

FAKE_ELIXIR = r'''#!/usr/bin/env bash
src=$(cat main.ex)
if [[ "$1" == *.exs ]]; then
  [[ -f $src/elixir-fail ]] && { echo "generated warning validation failed: 1 error(s), 0 warning(s)" >&2; exit 1; }
  touch "$2/Elixir.Main.beam"
  exit 0
fi
cat "$src/beam.txt"
exit "$(cat "$src/beam-rc" 2>/dev/null || echo 0)"
'''

FAILING_XARGS = '#!/bin/sh\nexit 127\n'


class DifferentialRunnerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='differential-runner-')
        self.root = Path(self.tmp.name).resolve()
        for name in ['scripts/test-differential.sh', 'scripts/util/with-timeout.sh', 'scripts/with-timeout.sh']:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        for name, text in [('haxe', FAKE_HAXE), ('elixir', FAKE_ELIXIR)]:
            (self.bin / name).write_text(text)
            (self.bin / name).chmod(0o755)
        self.fixtures = self.root / 'fixtures'
        self.fixtures.mkdir()
        self.work = self.root / 'work'
        self.env = os.environ.copy()
        self.env.update(HAXE_BIN=str(self.bin / 'haxe'), ELIXIR_BIN=str(self.bin / 'elixir'))

    def tearDown(self):
        self.tmp.cleanup()

    def fixture(self, name, interp, beam, *markers):
        d = self.fixtures / name
        d.mkdir()
        (d / 'Main.hx').write_text('class Main { static function main() {} }\n')
        (d / 'interp.txt').write_text(interp)
        (d / 'beam.txt').write_text(beam)
        for marker in markers:
            (d / marker).write_text('')
        return d

    def known(self, *lines):
        (self.fixtures / 'known-differences.txt').write_text('# test list\n' + ''.join(l + '\n' for l in lines))

    def known_output(self, name, text):
        d = self.fixtures / 'known'
        d.mkdir(exist_ok=True)
        (d / (name + '.out')).write_text(text)

    def run_runner(self, *args, env=None, fixture_dir=True):
        tail = [str(self.fixtures)] if fixture_dir else []
        result = subprocess.run(
            ['bash', str(self.root / 'scripts/test-differential.sh'), '--work', str(self.work),
             '--timeout', '10', *tail, *args],
            env=env or self.env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        return result.returncode, result.stdout

    def line(self, output, fixture):
        for row in output.splitlines():
            parts = row.split()
            if len(parts) >= 2 and parts[1] == fixture:
                return row
        self.fail(f'no line for {fixture}:\n{output}')

    def standard_set(self):
        self.fixture('a_match', 'a\nb\n', 'a\nb\n')
        self.fixture('b_known', 'a\n', 'WRONG\n')
        self.fixture('c_compile', 'a\n', 'a\n', 'elixir-fail')
        self.known('b_known DIFF haxe.elixir.codex-test wrong value',
                   'c_compile COMPILE-FAIL:elixir haxe.elixir.codex-test syntax error')
        self.known_output('b_known', 'WRONG\n[exit status 0]\n')

    def test_listed_failures_pass_and_new_ones_fail(self):
        self.standard_set()
        self.fixture('d_new', 'a\n', 'b\n')
        self.fixture('e_crash', 'a\nb\n', 'a\n', 'beam-rc')
        (self.fixtures / 'e_crash' / 'beam-rc').write_text('1')
        self.fixture('f_interp', 'a\n', 'a\n', 'interp-fail')
        rc, out = self.run_runner()
        self.assertEqual(rc, 1, out)
        self.assertTrue(self.line(out, 'a_match').startswith('MATCH'))
        self.assertIn('known (haxe.elixir.codex-test)', self.line(out, 'b_known'))
        self.assertIn('known (haxe.elixir.codex-test)', self.line(out, 'c_compile'))
        self.assertIn('unexpected', self.line(out, 'd_new'))
        self.assertIn('DIFF         e_crash', out)
        self.assertIn('+[exit status 1]', out)
        self.assertTrue(self.line(out, 'f_interp').startswith('INTERP-FAIL'))
        self.assertTrue(out.rstrip().endswith('[differential] FAIL'))

    def test_standard_set_passes(self):
        self.standard_set()
        rc, out = self.run_runner()
        self.assertEqual(rc, 0, out)
        self.assertTrue(out.rstrip().endswith('[differential] PASS'), out)

    def test_r1_failed_workers_never_reuse_old_results(self):
        self.standard_set()
        rc, out = self.run_runner()
        self.assertEqual(rc, 0, out)
        fake = self.root / 'fakebin'
        fake.mkdir()
        (fake / 'xargs').write_text(FAILING_XARGS)
        (fake / 'xargs').chmod(0o755)
        env = dict(self.env, PATH=str(fake) + os.pathsep + self.env['PATH'])
        rc, out = self.run_runner('-j', '2', env=env)
        self.assertEqual(rc, 1, out)
        for name in ['a_match', 'b_known', 'c_compile']:
            self.assertTrue(self.line(out, name).startswith('RUNNER-ERROR'), out)
        self.assertNotIn('PASS', out)

    def test_r2_reclassify_is_marked_and_refuses_stale_results(self):
        self.standard_set()
        rc, out = self.run_runner()
        self.assertEqual(rc, 0, out)
        rc, out = self.run_runner('--reclassify')
        self.assertEqual(rc, 0, out)
        self.assertIn('RECLASSIFY: nothing is run', out.splitlines()[0])
        self.assertTrue(out.rstrip().endswith('PASS (reclassified, nothing was run)'), out)
        (self.fixtures / 'a_match' / 'Main.hx').write_text('class Main { static function main() { trace(1); } }\n')
        rc, out = self.run_runner('--reclassify')
        self.assertEqual(rc, 1, out)
        self.assertIn('stale result', self.line(out, 'a_match'))
        self.assertTrue(out.rstrip().endswith('FAIL (reclassified, nothing was run)'), out)

    def test_r2_reclassify_refuses_results_from_another_commit(self):
        git = ['git', '-C', str(self.root), '-c', 'user.name=t', '-c', 'user.email=t@example.invalid']
        subprocess.run(git + ['init', '-q'], check=True)
        subprocess.run(git + ['add', 'scripts'], check=True)
        subprocess.run(git + ['commit', '-qm', 'one'], check=True)
        self.standard_set()
        rc, out = self.run_runner('--scope', str(self.root))
        self.assertEqual(rc, 0, out)
        rc, out = self.run_runner('--scope', str(self.root), '--reclassify')
        self.assertEqual(rc, 0, out)
        subprocess.run(git + ['commit', '-q', '--allow-empty', '-m', 'two'], check=True)
        rc, out = self.run_runner('--scope', str(self.root), '--reclassify')
        self.assertEqual(rc, 1, out)
        self.assertIn('stale result', self.line(out, 'b_known'))

    def test_listed_stage_must_match(self):
        self.standard_set()
        (self.fixtures / 'c_compile' / 'elixir-fail').unlink()
        (self.fixtures / 'c_compile' / 'haxe-fail').write_text('')
        rc, out = self.run_runner()
        self.assertEqual(rc, 1, out)
        self.assertIn('listed as COMPILE-FAIL:elixir', self.line(out, 'c_compile'))

    def test_fixed_and_changed_entries_fail(self):
        self.standard_set()
        (self.fixtures / 'b_known' / 'beam.txt').write_text('a\n')
        (self.fixtures / 'c_compile' / 'elixir-fail').unlink()
        rc, out = self.run_runner()
        self.assertEqual(rc, 1, out)
        self.assertIn('FIXED: remove it', self.line(out, 'b_known'))
        self.assertIn('FIXED: remove it', self.line(out, 'c_compile'))
        (self.fixtures / 'b_known' / 'beam.txt').write_text('WRONG2\n')
        rc, out = self.run_runner('--fixture', 'b_known')
        self.assertEqual(rc, 1, out)
        self.assertIn('known output CHANGED', self.line(out, 'b_known'))
        self.assertIn('-WRONG\n+WRONG2', out)

    def test_corrupt_result_is_a_runner_error(self):
        self.standard_set()
        rc, out = self.run_runner()
        self.assertEqual(rc, 0, out)
        (self.work / 'a_match' / 'result').write_text('')
        rc, out = self.run_runner('--reclassify')
        self.assertEqual(rc, 1, out)
        self.assertIn('empty or corrupt', self.line(out, 'a_match'))
        self.assertTrue(self.line(out, 'a_match').startswith('RUNNER-ERROR'))

    def test_usage_errors_exit_2(self):
        self.standard_set()
        cases = []
        rc, out = self.run_runner('--fixture')
        cases.append((rc, out))
        self.assertIn('--fixture needs a value', out)
        rc, out = self.run_runner('--fixture', 'nope')
        cases.append((rc, out))
        self.known_output('a_match', 'orphan\n')
        rc, out = self.run_runner()
        cases.append((rc, out))
        self.assertIn('has no DIFF entry', out)
        (self.fixtures / 'known' / 'a_match.out').unlink()
        self.known('b_known DIFF haxe.elixir.codex-test wrong value',
                   'c_compile COMPILE-FAIL haxe.elixir.codex-test no stage')
        rc, out = self.run_runner()
        cases.append((rc, out))
        self.known('zz DIFF haxe.elixir.codex-test no such fixture')
        rc, out = self.run_runner()
        cases.append((rc, out))
        for rc, out in cases:
            self.assertEqual(rc, 2, out)


if __name__ == '__main__':
    unittest.main()

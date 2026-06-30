# Performance Guide (Compiler + Dev Workflow)

This guide focuses on **practical** performance work for Reflaxe.Elixir’s AST pipeline:
fast feedback in development, predictable output in CI, and a clear strategy for diagnosing slow builds.

> [!NOTE]
> This is an **advanced** guide. Command blocks are for local investigation and are not CI-smoked unless explicitly stated.

## Measure Before Optimizing

Start with Haxe’s built‑in timings:

```bash
haxe build.hxml --times
```

If you’re investigating macro‑time work specifically, enable macro timings:

```bash
haxe build.hxml -D macro-times --times
```

For Mix-integrated Haxe builds, enable phase timing output:

```bash
HAXE_TIMINGS=1 mix compile
```

`HAXE_TIMINGS` is silent by default and accepts `1`, `true`, `yes`, or `y`. When enabled, the
`compile.haxe` task prints a short summary with phases such as Mix config/staleness checks, Haxe server
setup, source discovery, Haxe invocation, generated-file discovery, manifest writes, diagnostics, and
total wall time. This is useful when the benchmark says a build is slow and you need to see which local
phase is responsible.

For the todo-app compile baseline, use the bounded benchmark harness:

```bash
npm run perf:todo-compile
```

This writes `tmp/perf/compile-times.json` and keeps detailed logs under
`tmp/perf/todo-compile/logs/`. The harness runs in an isolated git worktree so the cold path can
delete build artifacts without mutating your working copy. It records:

- `cold` — removes `_build`, `deps`, and manifest-listed generated `lib/` files, then runs deps,
  Haxe generation, and Mix WAE compile.
- `warm` — reruns Haxe generation and Mix WAE compile with dependencies/build cache already present.
- `incremental` — touches one todo-app Haxe source file, then reruns Haxe generation and Mix WAE
  compile.

The JSON includes Haxe/Elixir/Mix/OTP versions, per-phase durations, command strings, log paths, and
the last log lines for failed phases. The artifact intentionally lives under `tmp/` because it includes
machine-specific environment data.

For a smaller representative Phoenix example baseline, use:

```bash
npm run perf:example-compile
```

This reuses the same bounded compile harness against `examples/03-phoenix-app`, writes
`tmp/perf/example-compile-times.json`, and keeps logs under `tmp/perf/example-compile/logs/`.
It records the same `cold`, `warm`, and `incremental` phases, using `build.hxml` and
`src_haxe/PhoenixHaxeExample.hx`.

For todo-app edit→rebuild latency through `mix haxe.watch`, use the bounded watch benchmark:

```bash
npm run perf:todo-watch
```

This writes `tmp/perf/watch-cycle-times.json` and keeps watcher/dependency logs under
`tmp/perf/todo-watch/logs/`. The harness runs in an isolated git worktree, starts `mix haxe.watch`,
waits for the initial compile, atomically rewrites `src_shared/shared/TodoTypes.hx` with a harmless
comment, waits for the watch task’s `✅ Haxe compilation successful` marker, and repeats the cycle.
It reports p50/p95 plus min/max/mean.

Useful local options:

```bash
npm run perf:todo-watch -- --iterations 10 --debounce-ms 150 --deadline 600
npm run perf:todo-watch -- --ref HEAD~1 --out tmp/perf/watch-before.json
```

The JSON includes Haxe/Elixir/Mix/OTP versions, dependency setup phases, watcher startup timing,
per-iteration samples, command strings, log paths, and the last log lines for failed phases. Like the
compile benchmark, this is a local/non-gating baseline tool; use it before and after compiler/watch
changes when you need evidence for DevX performance claims.

By default, the watch benchmark sets `HAXE_NO_SERVER=1` so the run does not leave a persistent Haxe
`--wait` server behind. To measure server-backed watcher behavior explicitly:

```bash
npm run perf:todo-watch -- --use-haxe-server --iterations 10 --deadline 600
```

GitHub Actions also has an optional **Perf Todo Compile Benchmark** workflow. It is intentionally not
attached to `push` or `pull_request`, so it does not gate PRs or regular CI. Run it manually from
Actions when you want a shared timing artifact; the scheduled run provides a low-frequency trend sample.
The workflow uploads `compile-times.json`, phase logs, and the intermediate metadata as an artifact.

## Read Benchmark JSON

Use the JSON artifacts to compare phases, not just total wall time.

Compile benchmark (`tmp/perf/compile-times.json`):

- `repo` and `environment` identify the exact compiler commit, dirty state, Haxe version, Elixir/Mix
  version, OTP release, and host OS.
- `runs[].name` is one of `cold`, `warm`, or `incremental`.
- `runs[].phases[]` contains timed phases such as `deps_get`, `deps_compile`, `haxe_build`, and
  `mix_compile`.
- Failed phases include `log_tail`; full logs live under `tmp/perf/todo-compile/logs/`.

Representative example benchmark (`tmp/perf/example-compile-times.json`):

- Uses the same schema as the todo-app compile benchmark.
- `config.app`, `config.build_file`, and `config.incremental_source` identify the example and HXML
  entrypoint.
- Full logs live under `tmp/perf/example-compile/logs/`.

Watch benchmark (`tmp/perf/watch-cycle-times.json`):

- `phases[]` covers setup costs such as dependency resolution and watcher startup.
- `samples[]` are the measured edit→rebuild cycles.
- `summary` reports `min_ms`, `max_ms`, `mean_ms`, `p50_ms`, and `p95_ms`.
- Full logs live under `tmp/perf/todo-watch/logs/`.

Interpretation rules:

- Compare `warm` with `warm`, `incremental` with `incremental`, and watch samples with watch samples.
  Do not compare cold compile totals with watch-cycle latency.
- A slow `cold/deps_compile` phase is usually Hex/Mix dependency work, not Reflaxe.Elixir codegen.
- A slow `haxe_build` phase points at Haxe macro work, AST building, AST transforms, or printing.
- A slow `mix_compile` phase points at generated Elixir compilation, warnings, dependency checks, or
  generated output shape.
- Watch p95 matters more than a single fast sample; it captures the annoying tail of the edit loop.

## Compile-Time Profiling Playbook

Use this loop when a compile feels slow or a CI budget starts drifting.

1. Capture a bounded baseline:

   ```bash
   npm run perf:todo-compile
   npm run perf:example-compile
   npm run perf:todo-watch -- --iterations 5 --deadline 720
   ```

2. Compare against a known-good ref:

   ```bash
   npm run perf:todo-compile -- --ref HEAD~1 --out tmp/perf/compile-before.json
   npm run perf:example-compile -- --ref HEAD~1 --out tmp/perf/example-before.json
   npm run perf:todo-watch -- --ref HEAD~1 --out tmp/perf/watch-before.json
   ```

3. Classify the slow phase from JSON before adding debug flags. Debug flags can change timing, so use
   them after the baseline tells you where to look.

4. If the slow phase is Mix integration overhead, enable Mix/Haxe phase timing:

   ```bash
   HAXE_TIMINGS=1 mix compile
   ```

   For examples where Haxe generation has already happened and you only want generated Elixir compile
   cost, isolate Mix:

   ```bash
   HAXE_NO_COMPILE=1 MIX_ENV=test mix compile --force --warnings-as-errors --no-deps-check
   ```

5. If the slow phase is Haxe generation, use Haxe timings:

   ```bash
   haxe build-server.hxml --times
   haxe build-server.hxml -D macro-times --times
   ```

   For HXX/HEEx macro hotspots, enable the repo's opt-in macro instrumentation:

   ```bash
   haxe build-server.hxml -D hxx_instrument_sys --times
   haxe build-server.hxml -D hxx_instrument_sys --times 2>&1 | rg 'InlineMarkup|HXX\\.|TemplateHelpers'
   ```

   This adds labels such as `InlineMarkup.build`, `InlineMarkup.parseTsxRoot`,
   `InlineMarkup.parseBalancedPayload`, `HXX.processTemplateString`, and `TemplateHelpers.*` to Haxe's
   timing report. The labels include template byte sizes where useful, so repeated large templates are
   easier to spot before changing parser or transform code. Haxe may omit very small timers from the
   report, so validate instrumentation against a realistic template-heavy build before assuming a label
   is missing.

   Parser output caching is intentionally not enabled for inline TSX templates yet. The parser returns
   Haxe macro expressions with source positions and nested `${...}` expressions tied to the original
   location; reusing those expressions for another template occurrence would make errors point at the
   wrong source span and can corrupt later typing. If timings show repeated large templates dominate,
   cache only a position-independent intermediate representation first, then rebuild fresh `Expr`
   nodes per callsite.

   Use verbose Haxe logging only for diagnosis, and redirect it because it is noisy:

   ```bash
   haxe -v build-server.hxml > tmp/haxe-verbose.log 2>&1
   ```

6. If the slow phase is an AST transform, enable pass-level diagnostics:

   ```bash
   haxe build-server.hxml -D debug_pass_metrics
   rm -f /tmp/passF-macro.log
   haxe build-server.hxml -D profile_passes
   ```

   `debug_pass_metrics` prints which passes changed the AST. `profile_passes` writes pass timings to
   `/tmp/passF-macro.log`; narrow noisy output with `-D hxx_pass_timing_filter=<substring>` when needed.

7. If the slow phase is generated Elixir compilation, inspect generated shape instead of patching
   outputs:

   ```bash
   MIX_ENV=test mix compile --force --warnings-as-errors --no-deps-check
   ```

   Look for warnings-as-errors, huge generated modules, duplicated helper output, dependency checks, and
   non-linear generated code. Fix the compiler/std source-of-truth, not generated `.ex` files.

8. If the symptom is runtime slowness rather than compile slowness, switch tools. Use ExUnit,
   Phoenix integration tests, or targeted BEAM profilers (`:timer.tc`, `:eprof`, `:fprof`) around the
   generated function/runtime path. Do not infer runtime performance from compile-time benchmarks.

Common hot spots and mitigations:

| Signal | Likely cause | First mitigation |
| --- | --- | --- |
| `deps_compile` dominates only cold runs | Hex/Mix dependency compilation | Treat as environment/setup cost; keep dependency work out of WAE timing where possible. |
| `haxe_build` dominates warm/incremental runs | Macro expansion, stdlib shaping, AST transforms, or printer work | Use `--times`, `-D macro-times`, then `-D profile_passes`; prefer single-pass transforms and better data structures. |
| Watch p95 is much higher than warm compile | Watcher startup, file event debounce, Haxe server behavior, or repeated full rebuilds | Compare default direct mode with `--use-haxe-server`; inspect `tmp/perf/todo-watch/logs/watch.log`. |
| `mix_compile` dominates after Haxe output | Generated Elixir shape, warning churn, oversized modules, or dependency checks | Use `HAXE_NO_COMPILE=1`; fix emitted shape upstream; compile deps without WAE and project with WAE. |
| CI slow but local fast | Runner cache misses, slower CPU, dependency download, or shard imbalance | Compare phase logs/artifacts; do not tune local-only microbenchmarks to CI wall time. |
| A debug flag makes timings worse | Instrumentation overhead | Re-run the baseline without debug flags before claiming a regression or improvement. |

## Use the Right Compilation Profile

### Default (recommended for CI / release builds)

- Full pass set enabled
- Highest output quality and hygiene

### `fast_boot` (opt‑in, local iteration)

`fast_boot` is an **opt‑in** profile designed to speed up iteration on large modules by skipping
or simplifying selected expensive macro/transform work.

- Enable in Haxe: `-D fast_boot`
- Enable in Mix (this repo’s convention): `HAXE_FAST_BOOT=1 mix compile`

Details and tradeoffs are documented in:
- `docs/01-getting-started/development-workflow.md`
- `docs/06-guides/KNOWN_LIMITATIONS.md`

## Diagnose “Which Pass Did It?”

When output shape changes unexpectedly or compilation work spikes:

- `-D debug_pass_metrics` — prints which passes changed the AST
- `-D debug_ast_pipeline` / `-D debug_ast_transformer` — focused traces for pipeline stages

These are intended for contributor workflows; keep them off by default.

## Avoid Known Bad Flags

Do not use `-D analyzer-optimize` for Elixir output. It can destroy functional/idiomatic shapes
and makes downstream transforms harder. See `docs/01-getting-started/compiler-flags-guide.md`.

## Dev Ergonomics: Incremental Compilation

For Phoenix projects, prefer incremental compilation to avoid recompiling everything on each change:

- The Mix tasks integrate a background Haxe server when available.
- Phoenix watchers use `haxe ... --wait <port>` for client builds.

If you hit `EADDRINUSE` from `--wait`, prefer reusing/adjusting the wait port (see the todo‑app’s
`config/dev.exs`) rather than disabling watching entirely.

## Contributor Rule of Thumb: Keep Passes Linear

If you’re touching transformer passes:

- Prefer **single‑pass** analyzers (`VarUse`/symbol tables) over repeated tree scans.
- Avoid O(n²) “fix‑it” passes that re‑walk the full AST multiple times.
- Gate expensive cosmetic hygiene behind profiles (`fast_boot`, `disable_hygiene_final`) only when
  semantics remain correct.

If you find a pass that must exist but is too expensive, the fix is algorithmic (data structures,
single‑pass analysis), not arbitrary limits.

## CI Budgets (Determinism + Time Bounds)

To guard against “it got slow” / “output order changed” regressions without flakiness, CI runs a
budget check on the todo‑app’s server + client builds:

```bash
npm run ci:budgets
```

This script:
- Builds the todo‑app server and client twice and diffs the outputs (determinism).
- Enforces generous per‑build timeouts via `scripts/with-timeout.sh` (no tight wall‑time asserts).

You can override the timeouts locally:
- `SERVER_TIMEOUT_SECS=240 CLIENT_TIMEOUT_SECS=180 npm run ci:budgets`

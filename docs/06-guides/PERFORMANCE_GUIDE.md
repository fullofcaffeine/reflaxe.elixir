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

### Benchmark vocabulary

The process and cache model are part of every result. In this guide:

- **cold command-line generation** starts a new Haxe process after removing generated output and
  compiler-owned build artifacts; dependency acquisition/compilation is reported separately;
- **warm fresh-process generation** starts a new Haxe process but retains dependency and filesystem
  state from the prior build;
- **edited full-program fresh-process generation** changes real source bytes, starts a new Haxe
  process, and submits the complete HXML build again;
- **persistent server rebuild** sends another complete request to the same `haxe --wait` process;
- **persistent watch rebuild** measures edit-to-completed-output while one watcher remains alive;
- **incremental** means the measurement proves previous compiler or module work was reused or skipped.

Changing one file does not by itself make a build incremental. For example, editing `TodoTypes.hx`
and then launching a brand-new `haxe build-server.hxml` process is an edited full build. A server can
reuse Haxe frontend state, but server reuse alone still does not prove that Reflaxe skipped unaffected
target modules.

### Compile benchmark

For the todo-app compile baseline, use the bounded benchmark harness:

```bash
npm run perf:todo-compile
```

This writes `tmp/perf/compile-times.json` and keeps detailed logs under
`tmp/perf/todo-compile/logs/`. The harness runs in an isolated git worktree so the cold path can
delete build artifacts without mutating your working copy. It records:

- `cold` — removes `_build`, `deps`, and manifest-listed generated `lib/` files, then runs deps,
  Haxe generation, and Mix WAE compile.
- `warm_fresh_process` — starts a new Haxe process and reruns generation plus Mix WAE with dependency
  and filesystem state already warm.
- `edited_full_fresh_process` — applies a deterministic A→B content change to one Haxe source file,
  then starts a new Haxe process and submits the complete build again. It explicitly records
  `demonstrated_incremental_reuse: false`.

The JSON includes Haxe/Elixir/Mix/OTP versions, per-phase durations, command strings, log paths, and
the last log lines for failed phases. The artifact intentionally lives under `tmp/` because it includes
machine-specific environment data.

For a smaller representative Phoenix example baseline, use:

```bash
npm run perf:example-compile
```

This reuses the same bounded compile harness against `examples/03-phoenix-app`, writes
`tmp/perf/example-compile-times.json`, and keeps logs under `tmp/perf/example-compile/logs/`.
It records the same `cold`, `warm_fresh_process`, and `edited_full_fresh_process` scenarios, using `build.hxml` and
`src_haxe/PhoenixHaxeExample.hx`.

For todo-app edit→rebuild latency through `mix haxe.watch`, use the bounded watch benchmark:

```bash
npm run perf:todo-watch
```

This writes `tmp/perf/watch-cycle-times.json` and keeps watcher/dependency logs under
`tmp/perf/todo-watch/logs/`. The harness runs in an isolated git worktree, starts `mix haxe.watch`,
waits for the initial compile, atomically alternates `src_shared/shared/TodoTypes.hx` between exact A/B
contents, waits for the watch task’s `✅ Haxe compilation successful` marker, and repeats the cycle.
The B variant adds one comment line: runtime behavior stays the same, while the source bytes and source
positions genuinely change. The harness performs one unreported warm-up by default, then reports
p50/p95 plus min/max/mean for measured samples.

Useful local options:

```bash
npm run perf:todo-watch -- --warmups 5 --iterations 10 --debounce-ms 150 --deadline 600
npm run perf:todo-watch -- --ref HEAD~1 --out tmp/perf/watch-before.json
```

The default comment edit answers one narrow question: what happens when source bytes and source
positions change but runtime behavior does not? For other edit shapes, pass one of the checked-in
unified diff patches to the same harness. The isolated worktree starts in baseline state A, applies
the patch for state B, reverses it for A, and repeats. The harness checks each patch before applying
it, so a patch that no longer matches the selected revision fails without partially changing the
worktree.

For example, compare the exact same HXX text edit with and without a persistent Haxe server:

```bash
npm run perf:todo-watch -- \
  --edit-patch scripts/perf/fixtures/todo-edits/hxx-component.patch \
  --edit-kind hxx_component_text \
  --iterations 10

npm run perf:todo-watch -- \
  --edit-patch scripts/perf/fixtures/todo-edits/hxx-component.patch \
  --edit-kind hxx_component_text \
  --use-haxe-server \
  --iterations 10
```

Available todo-app patches under `scripts/perf/fixtures/todo-edits/`:

| Patch | `--edit-kind` | What changes |
|---|---|---|
| `private-implementation.patch` | `private_implementation` | Rewrites a private hash calculation to an equivalent expression without changing its callable contract. |
| `public-signature.patch` | `public_callable_signature` | Adds an optional argument to a public function; pass `--public-api-changed`. |
| `hxx-component.patch` | `hxx_component_text` | Changes visible text inside inline HXX/HEEx markup. |
| `shared-protocol.patch` | `shared_protocol_type` | Adds an optional field to a client/server channel payload; pass `--public-api-changed`. |
| `build-input-define.patch` | `hxml_define` | Adds an HXML define and a watched source marker, so the watcher receives an event and the build-input fingerprint changes. |

Patch paths, their SHA-256 digest, `--edit-kind`, `--public-api-changed`, and every edited path are
stored in the result. The flag records the semantic class of the edit; it does not make the harness
infer dependency impact or claim that incremental reuse occurred.

The JSON includes Haxe/Elixir/Mix/OTP versions, dependency setup phases, watcher startup timing,
per-iteration samples, command strings, log paths, and the last log lines for failed phases. Like the
compile benchmark, this is a local/non-gating baseline tool; use it before and after compiler/watch
changes when you need evidence for DevX performance claims.

By default, the watch benchmark sets `HAXE_NO_SERVER=1` so the run does not leave a persistent Haxe
`--wait` server behind. The result calls this `persistent_watch_with_fresh_haxe_child`. To measure a
server-backed watcher explicitly:

```bash
npm run perf:todo-watch -- --use-haxe-server --iterations 10 --deadline 600
```

That mode records `persistent_watch_with_haxe_server`, plus the port and operating-system PID of the
process that owns the Haxe server. It still leaves `demonstrated_incremental_reuse` false until module
reuse is observed directly. A stable process identity proves that the same server stayed alive; it
does not, by itself, prove which compiler work was reused.

The watch artifact also records retained-memory snapshots before sampling and after every completed
rebuild. “Retained memory” here means RSS (resident set size): the physical memory currently occupied
by the watcher process tree and, in server mode, by the owned Haxe-server process tree. The snapshot is
taken after the edit-to-success timer stops, so observing memory does not make the measured rebuild look
slower. It is useful for detecting growth across a long session—for example, whether ten edits leave the
server using steadily more memory—but it is not the highest memory usage reached during compilation.

### Choose a machine-state label

A developer workstation does not need to be perfectly idle before its measurements can guide an
optimization. Use `--machine-state representative_loaded` when ordinary background work is present
but reasonably stable. Run matched direct and Haxe-server sessions close together, reverse their order
in a second session when practical, and compare paired deltas or ratios. Each watch sample records load
immediately before the edit and immediately after rebuild success so reviewers can reject a period
whose background work changed materially.

Do not divide latency by load average or subtract an estimated background cost. CPU scheduling, memory
bandwidth, caches, disk activity, and thermal limits interact nonlinearly, so that calculation would
invent precision. A representative-loaded run can rank optimizations and show whether an improvement
survives normal workstation activity. It does not establish an absolute latency budget or a public p95.

Use the labels as follows:

- `idle`: a human-reviewed, repeatable reference machine with no material unrelated work; required for
  absolute budgets or promoted performance claims;
- `representative_loaded`: stable everyday background work intentionally admitted for matched relative
  comparisons;
- `contended`: changing, saturating, or pathological competing work; retain for diagnostics but do not
  use it to rank close alternatives;
- `unknown`: the environment was not sufficiently observed, as with an ordinary hosted runner.

For low-perturbation phase attribution, run either harness with coarse timers:

```bash
npm run perf:todo-compile -- --phase-timers coarse --machine-state idle
npm run perf:todo-watch -- --use-haxe-server --phase-timers coarse --machine-state idle --iterations 10
```

Coarse mode enables Haxe `--times`, existing Mix phase timers, and a Reflaxe target summary for each
compile or watch rebuild. Each measured watch sample keeps its matching target summary. The target
summary accumulates dependency discovery, class/enum AST construction, pass-manager, printer,
source-map, and output-transaction time. `class_ast_including_dependency_discovery` is deliberately a
nested total; subtract `dependency_discovery` when estimating the remaining class AST work. Detailed
per-pass fingerprints stay disabled because they can dominate the operation being measured.

GitHub Actions also has an optional **Perf Todo Compile Benchmark** workflow. It is intentionally not
attached to `push` or `pull_request`, so it does not gate PRs or regular CI. Run it manually from
Actions when you want a shared timing artifact; the scheduled run provides a low-frequency trend sample.
The workflow uploads `compile-times.json`, phase logs, and the intermediate metadata as an artifact.

The manually dispatched **Perf Todo Watch Matrix** workflow runs the five checked-in edit classes in
both direct and Haxe-server modes, sequentially on one runner. Before the job can pass, every source
variant must produce one stable generated-output tree in each mode, the paired tree hashes must match,
and the server run must report a persistent Haxe-server identity. This makes generated-output parity a
correctness gate rather than a claim inferred from a successful timing run. The artifacts also support
cleanup and phase inspection. GitHub-hosted runner contention is unknown, so latency remains
provisional and cannot replace a controlled idle-machine baseline or support a public p95 claim.

## Read Benchmark JSON

Use the JSON artifacts to compare phases, not just total wall time.

Compile benchmark (`tmp/perf/compile-times.json`):

- `repo` distinguishes the harness commit from the detached benchmark commit and records harness dirty
  state. `environment` records Haxe/Elixir/Mix/OTP versions, host OS, start/end CPU-load observations,
  and the explicitly labelled machine state. A label such as `idle` remains a human-reviewed statement;
  load average is supporting evidence, not an automatic verdict. `config.build_input_digests`
  fingerprints the relevant HXML, Lix, lock, and package
  inputs without storing machine-local absolute paths.
- `runs[].name` is one of `cold`, `warm_fresh_process`, or `edited_full_fresh_process`.
- Each run states `process_model`, compiler/artifact/dependency cache state, `edit_kind`, and whether
  incremental reuse was actually demonstrated.
- `runs[].phases[]` contains timed phases such as `deps_get`, `deps_compile`, `haxe_build`, and
  `mix_compile`.
- `runs[].generated_output` reports manifest-owned file/byte counts, the exact output-tree digest, and
  which generated paths changed since the prior scenario. `mix_recompiled_module_count` is parsed from
  the Mix compiler log when available.
- In coarse mode, `phase_reconciliation` treats the measurements as nested:
  the external `haxe_build` contains Haxe's reported total, and Haxe's total contains the Reflaxe
  target callback. It splits the wall clock into Reflaxe target work, Haxe work outside that callback,
  and unattributed process/measurement time. The non-overlapping pieces must reconcile to the external
  wall clock. `timing_nesting_status: inconsistent` rejects impossible ordering instead of reporting a
  misleading negative remainder.
- Failed phases include `log_tail`; full logs live under `tmp/perf/todo-compile/logs/`.

Representative example benchmark (`tmp/perf/example-compile-times.json`):

- Uses the same schema as the todo-app compile benchmark.
- `config.app`, `config.build_file`, and `config.edited_source` identify the example and HXML
  entrypoint.
- Full logs live under `tmp/perf/example-compile/logs/`.

Watch benchmark (`tmp/perf/watch-cycle-times.json`):

- `phases[]` covers setup costs such as dependency resolution and watcher startup.
- `samples[]` are the measured edit→rebuild cycles.
- `warmup_samples[]` are retained for audit but excluded from summary statistics.
- `config.process_model` distinguishes direct child compilation from the persistent Haxe server.
- For patch-driven runs, `config.edit_patch`, `edit_patch_sha256`, `edit_kind`, `edited_paths`, and
  `public_api_changed` identify the exact edit and its intended dependency class. These fields describe
  the input; they do not claim which compiler work was reused.
- Each sample's `generated_output` reports whether the edit actually changed generated files and keeps
  an exact output-tree digest for clean-versus-warm comparison.
- `samples[].host_load_before_edit` and `host_load_after_success` bracket each timed rebuild. Use them to
  detect changing contention; they are evidence for accepting or rejecting a sample, not a formula for
  normalizing its latency.
- `processes.memory_before_samples` and `samples[].memory_after_success` contain post-build RSS
  snapshots. `watcher_process_tree` covers the long-running Mix watcher and its live descendants;
  `haxe_server_process_tree` starts at the native owner that keeps `haxe --wait` alive. A missing process
  is recorded as `null`, and the artifact explicitly describes the measurement as a snapshot rather
  than a peak-memory value. The server tree can be a descendant of the watcher tree, so compare each
  series over time; do not add the two byte counts together.
- In coarse mode, each sample's `phase_reconciliation` connects the outer edit-to-success duration to
  the nested Mix/Haxe request and Haxe invocation. For example, it reports how much time fell outside
  the nested compilation timer (including file detection, debounce, and observing the success marker),
  how long `haxe.invoke` took, the Reflaxe callback inside Haxe's reported total, Haxe time outside that
  callback, and any still-unattributed invocation time. These are nested measurements, not values to
  add directly. An unattributed remainder is an explicit unknown to investigate; the harness does not
  guess that Haxe, Reflaxe, or Mix owns it.
- `summary` reports `min_ms`, `max_ms`, `mean_ms`, `p50_ms`, and `p95_ms`.
- Full logs live under `tmp/perf/todo-watch/logs/`.

Interpretation rules:

- Compare identical scenario names, edit kinds, process models, and cache states. Do not compare a cold
  compile total with watch-cycle latency or editor diagnostics.
- Check the run-level and per-sample host-load observations against the selected machine-state label.
  A low load average alone does not prove an uncontended machine; record obvious background builds,
  indexers, or thermal constraints in the surrounding benchmark notes.
- A slow `cold/deps_compile` phase is usually Hex/Mix dependency work, not Reflaxe.Elixir codegen.
- A slow `haxe_build` phase points at Haxe macro work, AST building, AST transforms, or printing.
- A slow `mix_compile` phase points at generated Elixir compilation, warnings, dependency checks, or
  generated output shape.
- Ten measured samples can prioritize local work. A promoted persistent-edit p95 or TypeScript-class
  claim needs at least 50 measured samples per edit class, multiple controlled sessions, raw samples,
  and an idle machine. With only a handful of samples, p95 is effectively the slowest observation.

Schema version 1 artifacts used the name `incremental` for a touched-file fresh-process build. They are
historical evidence with the classification `legacy_v1_ambiguous_incremental_label`; do not merge them
with schema version 2 results or silently relabel their samples.

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
   npm run profile:passes:baseline
   ```

   `debug_pass_metrics` prints which passes changed the AST. `profile_passes` writes pass timings to
   `/tmp/passF-macro.log` by default. Use `-D hxx_pass_timing_module_filter=<module>` to select one
   module, `-D hxx_pass_timing_filter=<pass>` to select pass names, and
   `-D hxx_pass_timing_output=<path>` to avoid shared append-only logs. The baseline command wraps
   these defines in a bounded report across representative compiler scopes.

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
| `haxe_build` dominates warm or edited full fresh-process runs | Macro expansion, stdlib shaping, AST construction/transforms, or printer work | Use coarse phase timers, then `-D macro-times` or `-D profile_passes` only for the identified owner. |
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

It may skip cosmetic output cleanup, but it does not relax semantic correctness. Passes that carry
state across Elixir closures, including returned `Enum.reduce_while` accumulators, remain enabled.

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

## Dev Ergonomics: Persistent Compilation

For Phoenix projects, prefer the long-running watcher during development so the Haxe process can be
reused between edits:

- `mix haxe.watch` owns and reuses a background Haxe server for its lifetime.
- Ordinary one-shot `mix compile`, test, CI, and production commands remain direct by default.

If you hit `EADDRINUSE` from `--wait`, prefer reusing/adjusting the wait port (see the todo‑app’s
`config/dev.exs`) rather than disabling watching entirely.

This is a faster process model, not yet a blanket product claim of module-level incrementality. Current
measurement work distinguishes Haxe frontend cache reuse, Reflaxe module regeneration, generated-file
publication, and Mix recompilation before using that term.

## TypeScript-class DevEx is an objective

The project aims for TypeScript-class feedback, especially for persistent no-op and leaf edits. A fair
comparison must match the work: full typecheck+emit against full typecheck+emit, persistent emit against
persistent emit, and editor diagnostics against editor diagnostics. Genes/TSX client compilation is a
separate lane from Phoenix server Haxe-to-Elixir generation.

Until the matched adapter and controlled results are complete, this is an engineering objective—not a
measured parity or superiority claim. Absolute latency and memory figures are promotion goals until an
idle, repeatable reference-runner baseline makes them safe as regression budgets.

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

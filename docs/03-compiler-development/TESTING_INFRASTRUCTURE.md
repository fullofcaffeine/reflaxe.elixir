# Testing Strategy: Fast Agent Loops and Release Evidence

## Outcome

Reflaxe.Elixir uses one testing portfolio at different feedback horizons. A developer or agent should
get a useful failure from the smallest semantic owner while editing, then widen validation as the
claim and blast radius widen. The release path still proves clean package installation, generated
Elixir acceptance, BEAM behavior, framework integrations, and supported toolchains.

For example, a compiler pass can emit valid Elixir that returns `nil` instead of the Haxe function's
value. A snapshot or result-invariant test should catch that quickly. Running only that snapshot does
not prove that the emitted application starts on BEAM, while starting the todo app does not precisely
locate the faulty compiler pass. Both tests are useful, but they answer different questions.

The governing rule is:

```text
changed behavior
  -> smallest test that owns that behavior
  -> smallest runtime check needed for the claim
  -> broader affected checks
  -> clean full and release evidence
```

Do not run the largest suite on every edit. Do not call a change complete from a fast test that omits
the behavior being claimed.

## Two independent evidence axes

Results must remain separate:

1. **Portable Haxe semantics** — ordinary Haxe operations compile through Reflaxe.Elixir and behave
   correctly on BEAM. This includes language regressions, standard-library behavior, diagnostics,
   and the applicable active portion of the pinned official Haxe test corpus.
2. **Elixir/BEAM-native product behavior** — typed Elixir APIs, OTP, Phoenix, Ecto, LiveView,
   LiveReact/Genes browser code, package installation, output quality, atom/runtime safety, and
   performance.

A Phoenix browser flow cannot turn a missing portable `Array` contract into a pass. An upstream
`unitstd` pass cannot prove Phoenix routing or OTP supervision. Public readiness must report both
axes rather than one blended percentage.

## Evidence vocabulary

Use these labels in testing reports and design reviews:

- **Observed** — read directly from the current checkout or produced by an executed command.
- **Inferred** — follows from observed evidence but was not directly executed.
- **Assumed** — a working premise, with a named check that will confirm it.
- **Unknown/untested** — this repository does not currently establish the claim.

Applicability and execution are separate facts. An upstream test may be applicable, unsupported by
product policy, or require a faithful harness adaptation; its execution may independently pass,
fail correctness, fail infrastructure, or not run. Only an applicable test that executes
successfully contributes a compatibility pass.

## Live repository binding

| Parameter | Current binding and evidence |
|---|---|
| Target | `reflaxe.elixir` / Haxe→Elixir, as installed by the repository's scoped Lix configuration or packaged as `reflaxe.elixir` for Haxelib |
| Haxe baseline | `.haxerc` pins Haxe 4.3.7; the local official reference checkout used during this review is also tag 4.3.7, but its exact commit is not yet recorded in the fixture manifest |
| Primary CI toolchain | Node 22.14.0, Haxe 4.3.7, Elixir 1.18.3, and OTP 27.2 in `.github/workflows/ci.yml` |
| Minimum CI evidence | Elixir 1.14 and OTP 25 smoke; this is compatibility evidence for that lane, not by itself a complete release-support statement |
| Authoring axes | Portable stdlib-first Haxe and typed Elixir-first/native boundaries; `metal` is a local HXX/target-syntax escape hatch, not a second compiler backend |
| Public consumer path | Isolated Haxelib ZIP installation in `scripts/ci/haxelib-package-smoke.sh`; scheduled README smoke separately downloads and exercises a released artifact |
| Focused command | The exact snapshot, negative fixture, macro invariant, Haxe ExUnit file, or focused script owned by the change |
| Local smoke | No universal R1 command is accepted yet; compose the focused owner with the smallest strict-output/runtime command from the change map |
| Full evidence | The complete CI graph: `npm test` plus independently owned examples, framework/browser, package, security, platform, and release jobs |
| Artifacts | Existing owner-specific roots such as snapshot `out/`, `_tmp/examples-elixir-wae/`, QA logs, package-smoke temporary workspaces, and workflow artifacts; no parallel artifact database |

## What each current layer proves

| Layer | Primary commands | Positive contract | Does not prove |
|---|---|---|---|
| Focused compiler shape | `make -C test test-<category>__<case>`, `npm run test:<category>` | Haxe input generates the reviewed Elixir tree; negative fixtures own diagnostics | BEAM runtime behavior by itself |
| Compiler invariants | `npm run test:ast-children`, `test:pass-context`, `test:pass-registry`, `test:result-invariant` | Compiler-internal ownership, registry, traversal, and non-`Void` value preservation | Framework or package behavior |
| Generated Elixir acceptance | `npm run test:elixir-validate`, `test:examples-elixir` | `test:elixir-validate` parses already-generated snapshot `out/` trees that exist and skips absent ones; example WAE lanes compile maintained examples and reject warnings | Snapshot generation, absent `out/` trees, or correct runtime semantics |
| Portable BEAM runtime | `npm run test:haxe-exunit-stdlib` | Selected ordinary Haxe stdlib behavior executes on BEAM/ExUnit | Complete official Haxe `unit.TestMain` coverage |
| Mixed BEAM aggregate | `npm run test:runtime-smoke`, `test:mix-fast` | Selected portable runtime, compiler integration, and native OTP/Mix behavior execute | A pass cannot be attributed wholly to either evidence axis; failures must be routed to their owning test |
| Official `unitstd` subset | `npm run guard:upstream-unitstd`, `test:haxe-exunit-stdlib` | The currently enabled/adapted checked-in specs remain inventoried and execute | Shared top-level language classes, issue corpus, or all 120 manifest entries |
| Output quality | `npm run test:handwritten-output`, `test:generated-formatting` | Representative generated Elixir stays formatted and within reviewed structural budgets | Semantic correctness alone |
| Examples | `test:examples`, `test:examples-output`, `test:examples-elixir`, `test:examples-runtime` | Maintained examples compile, keep reviewed output, pass strict Elixir checks, and run where declared | Unlisted examples or unsupported capabilities |
| Framework/application | `test:mix-fast`, todo-app Haxe ExUnit tests, bounded QA sentinel and Playwright specs | OTP/Phoenix/Ecto callbacks and selected browser journeys work end to end | General portable-Haxe conformance |
| Server/watch lifecycle | `test:haxe-server-*`, `test:reflaxe-server-cache`, dev-watcher sentinel flow | Process ownership, cleanup, invalidation, and watched application behavior | Clean fresh-process/package behavior |
| Package/consumer | `test:haxelib-package`, scheduled README release smoke | An isolated consumer can install the built/released artifact and generate equivalent output | Every release matrix combination |
| Security/release/performance | dependency/secret scans, release policy tests, `ci:budgets`, dedicated perf workflows | Those named policies and bounded measurements hold | Language or framework correctness not exercised there |

Snapshots, generated-source checks, runtime tests, examples, and browser tests are complementary.
Never use one as a cheaper substitute for another contract.

## Feedback rings for people and agents

The same code and test commands serve humans and agents. Agents additionally require bounded process
ownership and guaranteed teardown; this is why they use the QA sentinel instead of a foreground
Phoenix server.

| Ring | Purpose in this repository | Current use |
|---|---|---|
| **R0 — focused/editor** | Prove the changed semantic owner while coding | One snapshot/negative case, one macro invariant, one Haxe-authored ExUnit file, or one focused script |
| **R1 — local claim smoke** | Prove the smallest compile→Elixir-check→BEAM-runtime chain needed by the change | Compose the focused owner with `test:runtime-smoke`, `test:mix-fast`, or a bounded sentinel flow as applicable; a universal fast smoke is not yet accepted |
| **R2 — clean required change gate** | Reproduce the primary environment and all affected owners remotely | Current PR workflow runs the full main graph; affected selection has not been promoted |
| **R3 — affected extended** | Add browser, framework, package, platform, capability, or performance evidence when the diff can affect it | Today these jobs run broadly on every PR/main push; future selection must begin in observation mode |
| **R4 — main/full backstop** | Run the complete current-primary repository suite and detect selection misses | Current `main` CI graph, including `npm test`, examples, sentinel, package, minimum-toolchain, macOS, security, and budgets |
| **R5 — release** | Publish only the exact commit that passed every named gate; separately exercise the released artifact | `Release exact CI-tested commit`, package smoke, and scheduled README release-tag smoke |

The starting time budgets from the shared testing review are goals to measure, not assertions about
this repository: roughly 15–30 seconds for R0, 60–90 seconds for R1, and a 10–12 minute required-PR
critical path. **Observed:** exact-head CI run `30612110872` took about 51 minutes in `Tests`, 25
minutes in macOS smoke, and 19 minutes in minimum-toolchain smoke. The current PR graph therefore
does not meet the proposed R2 budget. Reducing it requires measured ownership and selector-recall
evidence, not broad path ignores.

## Agentic TDD loop

1. **Name the claim and semantic owner.** “Fix arrays” is too broad. “Preserve the value returned
   after this pass” points to a result-invariant regression; “LiveView click changes the task” points
   to Haxe-authored LiveViewTest plus a thin browser flow.
2. **Write or identify the smallest failing contract.** Bugs use the same public Haxe operation that
   failed. Do not replace it with `untyped`, raw Elixir, or a lower-level helper merely to simplify
   output.
3. **Iterate in R0.** Run one case or focused owner with a bounded command. Review intended generated
   output rather than accepting snapshot drift automatically.
4. **Cross the real runtime boundary in R1 when behavior can change.** A source-shape-only change may
   need strict parsing/formatting; stdlib semantics need BEAM execution; Phoenix UI behavior needs
   LiveView/ConnTest and, for critical browser wiring, Playwright.
5. **Run all affected repository contracts before pushing.** Use the change map below. Cross-cutting
   compiler, stdlib, runner, manifest, package, or CI changes expand to the full relevant suite.
6. **Push the closed task and require exact-head CI.** The latest `main` run must be green before the
   next task. A cancelled superseded run is not a failure; an older green run is not evidence for a
   newer commit.
7. **Preserve the failure.** Do not hide deterministic failures with retries or silently convert a
   retry pass into an ordinary green claim. Record the original attempt and classify infrastructure
   failures separately.

`npm run test:changed` is a local convenience heuristic. It has no reviewed semantic-ownership
manifest or selector-miss audit, so it is **advisory only** and cannot establish completion or become
a blocking CI selector in its current form.

### Observation-only test feedback

The repository has a separate, fail-safe observer for evaluating whether future affected-test
selection is worth pursuing. It does **not** replace `test:changed`, and it does not control which CI
jobs run.

For example, when only `docs/guide.md` changes, the observer may propose dependency audit,
guardrails, secret scan, docs smoke, and the generated-Phoenix dogfood sentinel. That proposal is a
hypothesis to evaluate, not a claim that those jobs already provide sufficient evidence. Dependency
audit is always included because a newly published advisory can make an unchanged lockfile fail.
Dogfood is always included because it exercises authored Haxe through generation, strict upgraded
Elixir compilation, and a real Phoenix boot. GitHub still runs the complete required graph. After
the run, the observer compares that proposal with every configured selectable job result in that
workflow attempt. A configured job missing from the attempt forces full fallback. If an omitted job
failed, the report records a selector miss; it does not turn the run green.

```text
changed paths -> reviewed ownership rules -> proposed jobs
                                      full CI still runs
                                               |
                       completed job results <-+
                                  |
                 timings + omitted-job failures
```

The reviewed ownership data lives in `test/impact-ownership.json`. A rule starts from deterministic
paths, but it also names the semantic owner and the independent product surfaces whose claims may be
affected: compiler conformance, BEAM/OTP runtime, Elixir-native interop, Mix/package/CLI, and
framework applications. Those labels explain risk; they are not a scorecard and do not claim that
one selected job proves every named surface. Unknown paths, compiler/runtime source, workflows,
runners, and changes to the observer or its manifest propose the full graph. A workflow job that is
missing from or unknown to the manifest also changes the effective observation to full fallback.
These are positive safety rules: uncertainty causes more testing, never less.

CI publishes `test-feedback-observation-<run-id>-<attempt>` with:

- the changed paths, matched rules, and plain-language reasons;
- proposed selected and omitted stable jobs;
- actual job durations, the jobs that completed last, and the earliest failed-job completion signal;
- explicit limitations when GitHub job metadata does not expose cache hits, retries, or the first
  failing log line; and
- any failure from a job the proposal would have omitted.

Run the focused executable contract with `npm run test:test-feedback-observer`. A completed report is
not promotion evidence by itself. No number of days or observations has been validated. Each rule
remains on full CI until its mappings, historical failures, and a real shadow change are all reviewed
under the later promotion task.

## Change-to-test ownership map

Choose the smallest row that fully covers the change, then add rows when the diff crosses boundaries.

| Change | R0 owner | Required widening before closure |
|---|---|---|
| AST builder/pass/printer | Focused snapshot plus owning macro/pass invariant | Relevant snapshot categories, result invariant when values can change, Elixir validation, runtime owner when semantics change |
| Diagnostic/unsupported feature | Focused negative fixture | Full negative summary and affected positive category |
| Standard library/portable semantics | Focused stdlib snapshot and Haxe ExUnit assertion | `guard:upstream-unitstd`, `test:haxe-exunit-stdlib`, runtime smoke, API/layout/parity guards as applicable |
| ExUnit/Mix compiler integration | Focused Haxe-authored ExUnit or Mix test | `test:mix-fast`; package parity if consumer compilation changes |
| OTP/Phoenix/Ecto API or macro | Focused category snapshot and Haxe integration test | Relevant example compile/output/WAE/runtime layers |
| LiveView/browser/assets/Genes | Haxe LiveView/ConnTest or focused Genes integration | Agent-safe async sentinel with the smallest Playwright spec; affected example QA |
| Server/watch/cache/output transaction | Focused lifecycle/cache fixture | Direct/server parity, clean equivalent, affected sentinel dev-watcher flow |
| Example source or expected output | That example's compile/output check | Its WAE and declared runtime/E2E contract; `guard:examples-qa` when coverage metadata changes |
| Package/generator/release | Focused policy/fixture | Haxelib package smoke, release tests, and release-artifact path appropriate to the claim |
| Docs/snippets | Link guard and focused docs smoke | Compile/run the documented example when behavior is the point |
| Test runner/manifest/selector/CI | Harness self-test and fail-closed fixture | Broader/full suite because ownership itself changed; verify unknown inputs expand safely |
| Cross-cutting compiler/runtime | Small reproducer while editing | `npm test`, examples QA, relevant runtime/framework/package gates, exact-head full CI |

## Todo-app and browser lifecycle

Never run an unbounded foreground server during agent work. The application path is not
agent-specific; the lifecycle wrapper is.

```bash
# Agent-safe, asynchronous, bounded boot/build/runtime smoke
npm run qa:sentinel

# Browser regression owned by a compiler/std/runtime change
scripts/qa-sentinel.sh \
  --app examples/todo-app \
  --port 4001 \
  --env e2e \
  --async \
  --deadline 900 \
  --playwright \
  --e2e-spec "e2e/smoke/*.spec.ts" \
  --verbose

# Bounded result inspection
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 180
```

Most Phoenix UI behavior belongs in Haxe-authored ExUnit integration tests using
`Phoenix.LiveViewTest`/`ConnTest`. Playwright stays thin and proves browser assets, hooks, hydration,
and critical user journeys.

## Current-state gap matrix

This matrix records the live review on 2026-07-31. “Missing” means the repository does not yet prove
the contract; it is not permission to relabel the gap as a pass.

| Layer | Observed existing evidence | Missing evidence | Smallest owning seam | Planned stage |
|---|---|---|---|---|
| Compiler internals | Categorized positive/negative snapshots, pass/AST/result guards | No major structural gap identified in this review | Keep focused regressions beside the owning compiler stage | Ongoing |
| Generated target | Snapshot trees, Elixir validation, WAE, formatting and handwritten-output corpus | These do not prove runtime behavior | Preserve as separate source-quality gates | Ongoing |
| Portable runtime | Runtime smoke and Haxe-authored ExUnit stdlib parity | Complete applicable active official Haxe contract | Expand through the existing ExUnit generation seam | Official smoke, then baseline expansion |
| Official `unitstd` | 120 product entries: 24 enabled, 9 adapted, 13 target-specific skips, 3 unsupported, 71 without upstream specs; 32 checked-in fixtures | Exact per-fixture upstream commit/path/hash, local hash, adaptation diff/hash, independent disposition/outcome, secure TLS classification | Harden `test/upstream_unitstd/manifest.json` and its existing guards | Provenance/classification |
| Shared language/issues | General local regressions exist | No source-identity-preserving smoke from official shared top-level and issue families | Add one meaningful case from each family beside the existing ExUnit official-fixture lane | Official representative smoke |
| Capabilities | Runtime, OTP, IO, framework and platform smokes cover selected contracts | No complete capability manifest for filesystem/process/env/locale/time/network/TLS/thread/atomic behavior | Versioned capability classification tied to the official inventory | Classification, then capability shards |
| Examples/E2E | Manifested compile/output/WAE/runtime coverage; todo, chat and LiveReact browser gates | Ring/selection ownership and comparable timing/failure-yield data | Extend `examples/qa-manifest.json`, not a parallel example registry | Instrumentation and selector observation |
| Package/install | Isolated Haxelib ZIP parity and scheduled released-artifact smoke | Full official portable smoke through the installed package | Reuse package workspace and official ExUnit smoke once provenance is hardened | Official smoke, then release evidence |
| Native/framework | Mix, OTP, Phoenix, Ecto, LiveView, LiveReact/Genes and output-quality gates | No gap that portable-suite work is allowed to replace | Keep this axis independently required | Ongoing |
| Feedback efficiency | Focused commands, parallel snapshots, bounded sentinels, sharded WAE, observation-only ownership/timing reports | R0/R1 p50/p95 and validated per-rule promotion evidence; GitHub job metadata does not expose every cache/retry/first-log signal | Extend existing runners only when a missing signal changes a decision; observe before selecting | Selector observation, then measured promotion |
| CI topology | Full PR/main graph with exact tested-commit release plus a non-blocking post-gate timing/miss observer | PR critical path is about 51 minutes; repeated setup; no required aggregator for future selected jobs | Keep the observer unable to skip jobs; use its reports to decide whether selective CI is worthwhile | Measured R2/R3 promotion |
| Retry policy | macOS Mix and QA-sentinel Playwright paths retry failed semantic tests | A later pass can erase the original red outcome or log; setup/download retries are not classified separately | Preserve attempt logs/outcomes and classify setup, infrastructure, flake, and deterministic semantic failures without turning red into an unqualified pass | Retry-policy repair |

## Consolidation plan

Implement gaps in this order:

1. **Canonical policy (this document).** Route AGENTS and contributor docs here and remove
   contradictory “full suite after every edit” guidance.
2. **Fixture provenance and classification.** Keep the current runner; enrich the existing manifest
   and fail closed on upstream/adaptation drift.
3. **Official representative smoke.** Add shared-language, `unitstd`, and issue cases through the
   public package path, with intentional-failure and timeout propagation tests.
4. **Measure loops before filtering.** The observation job records GitHub job timing and selection
   explanations without inventing cache/retry signals unavailable from that API.
5. **Observe impact selection.** Keep the current full gate required. Unknown ownership,
   cross-cutting changes, and stale job mappings select full.
6. **Promote rules only after direct evidence.** Each rule needs executable mappings, historical
   replay, and a real shadow change with no missed failing owner. Rules without that evidence remain
   full; elapsed calendar time alone is not evidence.
7. **Tie compatibility wording to R5 evidence.** Until the complete applicable active baseline
   passes through the installed package and supported toolchains, documentation must say partial or
   representative coverage.

Do not create a shared cross-repository runner for symmetry. Share vocabulary and report shape first;
reuse this repository's test runners, ExUnit generator, example manifest, sentinel, package smoke, and
CI workflows.

## Commands by closure scope

```bash
# One snapshot
make -C test test-core__<case>

# Focused categories
npm run test:core
npm run test:stdlib
npm run test:regression

# Portable runtime
npm run test:haxe-exunit-stdlib

# Mixed BEAM aggregates
npm run test:runtime-smoke
npm run test:mix-fast

# Examples
npm run test:examples-qa

# Broad local compiler/runtime aggregate (not the complete CI graph)
npm test

# Focused contract for the advisory CI observer
npm run test:test-feedback-observer

# Agent-safe application/browser lifecycle
npm run qa:sentinel
```

Every command invoked by an agent must finish on its own or use the repository timeout/sentinel
mechanisms. A successful cached or warm run accelerates feedback but never replaces the clean path
needed for package and release claims.

## Focused implementation notes

### Warnings-as-errors example shards

“WAE” means `mix compile --warnings-as-errors`. Each `mix-XX` CI shard sets
`EXAMPLES_ELIXIR_WAE_ONLY` so one example's generated Elixir is checked in
isolation. This catches undefined calls, unused values, module conflicts, and
other target warnings without making one monolithic example job. The owning
runner is `scripts/test-examples-elixir.sh`; failures retain logs under
`_tmp/examples-elixir-wae/`.

### Snapshot runner internals

Sequential and parallel snapshot execution share normalization and directory-
comparison behavior through the test harness rather than maintaining separate
expected-output rules. Detailed fixture authoring and runner contracts live in
[`test/snapshot/AGENTS.md`](../../test/snapshot/AGENTS.md). This strategy
document owns *when and why* to run a layer; the snapshot instructions own
*how* to author and debug that layer.

### Wall-clock checks under ordinary load

Fast correctness suites must not enforce tight millisecond cutoffs. Scheduler
pauses, filesystem latency, indexing, and shared-runner load can move a correct
operation across a narrow threshold. `npm run ci:budgets` uses generous bounded
timeouts to catch hangs and severe regressions. Tighter comparisons belong in
the dedicated compile/watch benchmark workflows, with host-load observations
and multiple samples. Never promote one workstation timing into a blocking
budget.

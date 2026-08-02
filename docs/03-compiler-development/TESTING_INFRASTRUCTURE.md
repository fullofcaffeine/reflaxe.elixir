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

## Behavior-first change contract

Before broad automation, describe meaningful new or changed behavior as one concrete scenario. This
is not a request for Gherkin or a new specification system. A Bead, PR, fixture comment, or small
scenario table is enough when it records:

1. the precondition and authored input;
2. the action or compilation path;
3. the observable result;
4. the error or edge behavior;
5. the owning product surface; and
6. the public or internal claim protected by the test.

For a bug fix or behavior change, start with the lowest-cost test that can still observe the defect.
Run it against the unfixed behavior and retain the command plus the relevant failure. A separate red
commit is optional; an unrelated setup error is not red-state evidence. Expected values must come
from an independent source: a specification, manually authored minimal result, pinned differential
reference, invariant, reviewed golden with provenance, or real consumer behavior. The production
implementation must not create its own expected value.

For a new capability, prove one narrow real path before multiplying fixtures. This **tracer bullet**
starts with authored Haxe, crosses generated Elixir and the strict target check, and reaches the Mix,
package, framework, runtime, or browser observer needed by the claim. When one change affects both
compiler semantics and Phoenix/framework behavior, retain one tracer for each surface; one green app
cannot stand in for the compiler contract.

When a system or browser test discovers a stable compiler/generator defect, keep a **double lock**:

- a focused deterministic regression for fast diagnosis;
- the representative vertical integration that crosses the failed boundary; and
- a system/browser regression only when that complete environment owns the user-visible promise.

Mocks are valid only when they do not remove the failure class being claimed. OTP Process, Task,
Agent, supervision, and message expectations come from the documented Elixir/OTP contract, not from
the current generated implementation shape.

High-risk changes to compiler representation, runtime semantics, ABI, package publication, security,
migration behavior, or public claims require a review pass distinct from implementation. Record the
review's findings and dispositions, challenging test sensitivity, oracle independence, missing
negative cases, mocked boundaries, selector omissions, scorecard laundering, and claims broader than
the executed evidence.

## Evidence lenses and independent product surfaces

Two broad lenses remain useful for orientation:

1. **Portable Haxe semantics** — ordinary Haxe operations compile through Reflaxe.Elixir and behave
   correctly on BEAM. This includes language regressions, standard-library behavior, diagnostics,
   and the applicable active portion of the pinned official Haxe test corpus.
2. **Elixir/BEAM-native product behavior** — typed Elixir APIs, OTP, Phoenix, Ecto, LiveView,
   LiveReact/Genes browser code, package installation, output quality, atom/runtime safety, and
   performance.

A Phoenix browser flow cannot turn a missing portable `Array` contract into a pass. An upstream
`unitstd` pass cannot prove Phoenix routing or OTP supervision. Public readiness must report both
axes rather than one blended percentage.

Those two lenses are not detailed enough to own release evidence. The repository therefore keeps
five independent scorecards below. A scorecard is a map from one bounded claim to the tests that can
actually observe it. “Partial” means the named slice has useful evidence but the surface is not
qualified as a whole. There is deliberately no combined green status.

### Haxe-to-Elixir compiler conformance

| Field | Current binding |
|---|---|
| Stable owner and status | `compiler-conformance`; **partial** compiler/target surface |
| Authored input → output | Ordinary Haxe, diagnostics, macros, and applicable stdlib declarations → generated Elixir and source maps |
| Supported/tested profiles | Portable and Elixir-first authoring; Haxe 4.3.7; primary and minimum toolchains from the [Support Matrix](../06-guides/SUPPORT_MATRIX.md) |
| Focused owners | Positive/negative snapshot categories, AST/pass/result invariants, generated-output and source-map comparisons |
| Vertical/runtime owners | Strict generated-Elixir validation, Haxe-authored ExUnit stdlib runtime, maintained examples, and isolated package compilation |
| Browser owners | None. Browser results may expose a compiler bug but cannot qualify compiler conformance. |
| Representative examples | `01-simple-modules`, `10-option-patterns`, `16-portable-chat-domain`, and the compiler path exercised by `todo-app` |
| Oracle and provenance | Haxe language/stdlib contracts, manually reviewed generated goldens, semantic invariants, and pinned official fixtures; exact fixture provenance remains `haxe.elixir.codex-ydd` |
| Skips/adaptations/quarantine | Recorded in `test/upstream_unitstd/manifest.json`; disposition and execution outcome must remain separate |
| Selector/backstop/release | `compiler-snapshot-aggregate` and cross-cutting full fallback; `npm test`, official/runtime lanes, package smoke, and exact-commit release gate |
| Last clean proof and residual risk | CI `30664953897`: Tests, Examples/WAE, minimum-toolchain, and macOS jobs passed at `fb633dbff`; complete applicable official/stdlib qualification remains open |

### BEAM/OTP runtime semantics

| Field | Current binding |
|---|---|
| Stable owner and status | `beam-otp-runtime`; **partial** runtime surface |
| Authored input → output | Haxe operations and typed OTP calls → processes, messages, return values, timeouts, shutdown, and application boot on BEAM |
| Supported/tested profiles | The bounded operations in the [OTP Support Contract](../04-api-reference/OTP_SUPPORT_CONTRACT.md), tested on primary and minimum Elixir/OTP lanes |
| Focused owners | Haxe-authored runtime/ExUnit fixtures for portable semantics plus Process, Task, and Agent lifecycle behavior |
| Vertical/runtime owners | `test:haxe-exunit-stdlib`, runtime smoke, Mix tests, todo-app Mix tests, and application boot sentinels |
| Browser owners | None for general BEAM/OTP semantics; browser flows can prove only their application behavior. |
| Representative examples | `08-behaviors`, `10-option-patterns`, `14-abstraction-lab`, `16-portable-chat-domain`, and `todo-app` |
| Oracle and provenance | Explicit Elixir/OTP behavior contracts and manually authored runtime expectations; generated callback structure is not the oracle |
| Skips/adaptations/quarantine | Custom GenServer callbacks, Registry, broad supervisor failure policy, raw mailbox behavior, and distributed OTP are outside the current promise |
| Selector/backstop/release | `test`/runtime owners with cross-cutting full fallback; `test:runtime-smoke`, `test:mix-fast`, and exact-head full CI |
| Last clean proof and residual risk | CI `30664953897`: Tests, runtime examples, todo-app Mix, dogfood, minimum-toolchain, and sentinel jobs passed; broad OTP behavior is intentionally unclaimed |

### Elixir-native, metal, macros, and interop

| Field | Current binding |
|---|---|
| Stable owner and status | `elixir-native-interop`; **partial** native-boundary surface |
| Authored input → output | Typed externs, annotations, HXX, macros, and isolated metal escape hatches → ordinary Elixir/Phoenix/Ecto/OTP calls and modules |
| Supported/tested profiles | Elixir-first is primary; portable code may cross a typed boundary deliberately; `metal` remains a local escape hatch rather than an application profile |
| Focused owners | Phoenix/Ecto/OTP/ExUnit snapshot categories, strict-boundary diagnostics, macro/pass guards, and typed interop fixtures |
| Vertical/runtime owners | `test:mix-fast` and the relevant runtime examples using real Elixir, Ecto, Phoenix, or OTP APIs |
| Browser owners | Only when the native boundary itself is browser-visible, such as the LiveReact/Genes integration; those results do not qualify unrelated native APIs |
| Representative examples | `07-protocols`, `13-elixir-first-liveview`, `14-abstraction-lab`, `18-phoenixhx-live-react` |
| Oracle and provenance | Elixir/Phoenix/Ecto/OTP public contracts, manually authored minimal target equivalents, strict target compilation, and real consumer behavior |
| Skips/adaptations/quarantine | No broad promise that every Hex dependency has a typed facade; raw HEEx/metal use stays explicitly isolated |
| Selector/backstop/release | `test` and affected example/framework owners with cross-cutting full fallback; Mix/runtime/example QA plus exact-head full CI |
| Last clean proof and residual risk | CI `30664953897`: Tests, Example WAE/runtime, and LiveReact/Phoenix sentinels passed; coverage remains API-by-API rather than ecosystem-wide |

### Mix package, CLI, and installation

| Field | Current binding |
|---|---|
| Stable owner and status | `mix-package-cli`; **partial** consumer/distribution surface |
| Authored input → output | Mix configuration, HXML, source checkout, and packaged archive → compilation, generated-file ownership, clean rebuild, and installable consumer output |
| Supported/tested profiles | Repository checkout, isolated Haxelib ZIP consumer, scheduled released-artifact smoke, primary/minimum toolchains where declared |
| Focused owners | Haxe compiler Mix tests, invalidation/ownership fixtures, generator/package policy, and release workflow contracts |
| Vertical/runtime owners | `test:haxelib-package`, dogfood generation/boot/upgrade, docs smoke, and installed-package output parity |
| Browser owners | None for installation itself; a generated Phoenix app boot may prove the installed product crosses into the framework surface. |
| Representative examples | `02-mix-project`, `lix-installation`, `test-integration`, and package-created dogfood applications |
| Oracle and provenance | Mix compiler/application contracts, declarative package contents, source/package parity, immutable release artifacts, and clean-consumer behavior |
| Skips/adaptations/quarantine | `lix-installation` is compile evidence in the example lane; it does not by itself prove a released download occurred |
| Selector/backstop/release | `package-consumer-contracts` with full fallback for package/release changes; package smoke, release policy, and exact tested-commit publication |
| Last clean proof and residual risk | CI `30664953897`: Haxelib Package Smoke, Docs Smoke, Dogfood, minimum-toolchain, and release jobs passed; final 1.0 support/licensing approval remains blocked |

### Phoenix and framework applications

| Field | Current binding |
|---|---|
| Stable owner and status | `framework-applications`; **partial** application surface |
| Authored input → output | Haxe-authored Phoenix/Ecto/LiveView/LiveReact application code and assets → production build, booted endpoint, runtime state, and browser-visible behavior |
| Supported/tested profiles | Elixir-first on the pinned Phoenix/LiveView/Ecto/LiveReact combinations documented by the [Support Matrix](../06-guides/SUPPORT_MATRIX.md) |
| Focused owners | Phoenix/Ecto/LiveView snapshots, Haxe-authored ConnTest/LiveViewTest/ExUnit, and focused client/binding tests |
| Vertical/runtime owners | Example Mix tests, strict builds, dogfood generation/upgrade, and bounded QA sentinels; `03-phoenix-app` production-boots and verifies its exact JSON controller response, while `04-ecto-migrations` executes freshly generated migrations against an isolated PostgreSQL database |
| Browser owners | Playwright for `12-phoenix-chat`, `18-phoenixhx-live-react`, and the flagship `todo-app`; `15` and `17` browser specs remain manual and are not CI evidence |
| Representative examples | All framework examples, with `03` as a runtime-backed minimal HTTP capability, `04` as a real Ecto migration capability, `todo-app` as the flagship application, and `12`/`18` as browser-backed capability showcases |
| Oracle and provenance | Phoenix/Ecto/LiveView public contracts plus user-visible browser behavior; a compiler snapshot alone cannot prove application behavior |
| Skips/adaptations/quarantine | Compile-only examples claim source generation only; manual browser checks are named but do not advance CI-backed claims |
| Selector/backstop/release | `example-qa-portfolio`, framework sentinel, dogfood, and full fallback; `test:examples-qa`, bounded sentinels, and exact-head full CI |
| Last clean proof and residual risk | CI `30664953897`: example runtime/WAE, Phoenix chat, LiveReact, todo Mix/browser, docs, and dogfood jobs passed; only pinned paths are claimed |

The broad [Production Readiness scorecard](../06-guides/PRODUCTION_READINESS.md) combines these
surface results into release decisions. It must link back to the relevant surface evidence; it does
not replace the five scorecards or allow one surface to advance another.

## Incremental strategy crosswalk

This table records the 2026-08-01 audit against the behavior-first update. “Satisfied” can mean the
policy and owner now exist; it does not erase the residual execution gaps named in the final column.

| Conclusion | Before this update | Current status | Evidence or residual work |
|---|---|---|---|
| Behavior discovery/formulation | Partial | **Satisfied** | The six-field scenario contract above uses existing Beads, PRs, fixture notes, or scenario tables rather than a new BDD system. |
| TDD at the lowest faithful layer | Partial | **Satisfied** | The agent loop plus red-state rule require the exact pre-fix command/failure for behavior changes; the example-manifest guard was developed red-first. |
| Independent oracle | Partial | **Partial** | New/materially changed expectations require provenance; official fixture pin/adaptation provenance remains `haxe.elixir.codex-ydd`. |
| One tracer bullet first | Partial | **Satisfied** | New capabilities require a narrow authored-source → target → real observer path, with separate compiler and framework tracers when both change. |
| Lowest faithful layer and double lock | Partial | **Satisfied** | The policy retains focused diagnosis and real-boundary proof without forcing browser tests where the browser cannot observe the defect. |
| Portfolio review, not quotas | Partial | **Partial** | Per-surface review is now required; ratios remain smell detectors. Unique failure yield and critical-path optimization remain measured follow-up work. |
| Executable examples | Partial | **Partial, with current claims audited** | Manifest schema v2 classifies every example and rejects internally inconsistent tier/evidence/CI declarations. The current `ci: true` entries were checked against required workflows, but independent workflow linkage remains `haxe.elixir.codex-jvg.4`; advertised execution gaps receive separate Beads. |
| Preserve R0–R5 | Satisfied | **Satisfied with residual** | Rings, conservative fallback, and full backstop remain unchanged; retry evidence repair remains `haxe.elixir.codex-04s`. |
| Targeted high-risk verification | Partial | **Satisfied as policy** | A distinct review is now required and this update records one; future findings must remain durable in the Bead/PR or decision trail. |

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

## Per-surface portfolio review

Review balance by stable behavior owner inside each scorecard, never by mixing surfaces to reach one
percentage. Static formatting, lint, strict types, manifests, generated freshness, workflow policy,
and security checks remain outside the denominator: they are important floors, but they do not
exercise a product behavior.

Approximate diagnostic ranges—not gates—are:

- compiler/backend: 55–70% focused semantic/diagnostic owners, 25–40% real
  compile/build/run integration, and 0–10% downstream/system qualification;
- browser-capable framework/application: 50–60% focused deterministic/contract owners, 30–40%
  vertical integration/application runtime, and 5–10% browser E2E scenarios.

Count scenarios or stable owners, not assertions, parameter rows, files, or CI minutes. Investigate
an imbalance using unique actionable failure yield, escaped defects, diagnosis time, framework/build
failures missed below the boundary, browser discoveries converted into focused regressions, flake and
quarantine rates, example health, selector misses, maintenance cost, and claim-to-test ownership.
Unknown values stay unknown. The job-level feedback observer cannot infer all of these metrics from
durations alone, and no ratio controls CI.

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

### Representative behavior-first workflow: example claims

This 2026-08-01 update closed a real policy gap rather than inventing a compiler feature for process
demonstration.

| Scenario field | Recorded behavior |
|---|---|
| Preconditions/input | An entry in `examples/qa-manifest.json` declares its tier, product surfaces, authoring profiles, strongest evidence level, and one distinctive claim. |
| Action/path | `npm run guard:examples-qa` loads every maintained example and validates that declaration against its compile, runtime, and E2E decisions. |
| Observable result | A compile-only claim may compile; a runtime claim requires `runtime.ci=true`; a browser claim requires both runtime CI and `e2e.ci=true`; the flagship todo app therefore remains browser-backed QA. |
| Error/edge behavior | Missing metadata, unknown surfaces/profiles, duplicate owners, incompatible tier/runtime pairs, and browser claims with manual-only E2E fail nonzero. |
| Owning surface | The guard owns example evidence declarations; each entry separately names affected product surfaces for scorecard routing. `evidenceLevel` and the distinctive claim bound what the example may actually prove. |
| Protected claim | An example cannot advance a stronger product claim than the level CI executes. |

The focused test was red before implementation:

```bash
scripts/with-timeout.sh --secs 60 -- python3 scripts/ci/test-examples-qa.py
```

It exited 1 because all 21 entries lacked claim metadata and the old validator accepted invalid
tier/runtime pairs, unknown product surfaces, duplicate owners, and a browser claim without CI
browser evidence. The expectation is independently authored from the example QA contract; the
validator does not generate its own expected manifest.

The focused owner is `scripts/ci/test-examples-qa.py`. The vertical tracer is the `todo-app` entry:
its declaration passes schema validation, and the separately reviewed required sentinel workflows
build Haxe to Elixir, strict-compile the application, boot Phoenix, run the compact browser smoke,
and exercise create, edit, complete/uncomplete, and delete through the local-development watcher
path. The guard checks declaration consistency; the sentinels observe the application. Neither
substitutes for the other. The guard does not yet prove that every future `ci: true` edit is wired
into a required workflow; `haxe.elixir.codex-jvg.4` owns that bounded follow-up. `npm run ci:guards`,
example QA, and exact-head CI are the broader contracts.

### Representative migration tracer: generated source to real PostgreSQL

The `04-ecto-migrations` capability owns one narrow database scenario. Haxe-authored `CreateUsers`
and `CreatePosts` declarations compile in a new temporary workspace, so checked-in `.exs` files
cannot make the run pass. Ecto executes those fresh timestamped files against a uniquely named
database. A Haxe-authored ExUnit test then queries PostgreSQL's `information_schema.tables` as the
independent oracle: `users` and `posts` must exist after `up`; the same fresh path is passed to
`Ecto.Migrator` for `down`, after which neither table may remain.

The first runtime contract was red because the example had no `EctoMigrationsExample.Repo`. Once
the Repo existed, fresh generation exposed a lower compiler regression: application-wide Phoenix
target qualification (introduced by commit `18efaf896`) replaced Ecto's timestamped root output
with a nested module path. The focused `ecto/migration_exs_emission` snapshot was red with that path
mismatch. It now locks the timestamped filename and `App.Repo.Migrations.*` module, while the
database tracer retains the real Ecto/PostgreSQL boundary. `scripts/ci/test-ecto-migrations-qa.sh`
separately proves that a migration failure remains nonzero and still drops the prefix-validated
database owned by the run.

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
| Examples/E2E | Schema-v2 manifested tiers, stable owners, affected product surfaces, profiles, claims, compile/output/WAE/runtime coverage; `03` bounded boot, `04` isolated PostgreSQL migration execution, and todo/chat/LiveReact browser gates | Required browser ownership for the maintained `15`/`17` manual specs, and an independently executable link from `ci: true` declarations to required workflows | Existing manifest/guard plus `haxe.elixir.codex-jvg.3` and `.4`; no parallel example registry | Close only the evidence-backed child gaps; portfolio metrics remain observational |
| Package/install | Isolated Haxelib ZIP parity and scheduled released-artifact smoke | Full official portable smoke through the installed package | Reuse package workspace and official ExUnit smoke once provenance is hardened | Official smoke, then release evidence |
| Native/framework | Mix, OTP, Phoenix, Ecto, LiveView, LiveReact/Genes and output-quality gates | No gap that portable-suite work is allowed to replace | Keep this axis independently required | Ongoing |
| Feedback efficiency | Focused commands, parallel snapshots, bounded sentinels, sharded WAE, observation-only ownership/timing reports | R0/R1 p50/p95 and validated per-rule promotion evidence; GitHub job metadata does not expose every cache/retry/first-log signal | Extend existing runners only when a missing signal changes a decision; observe before selecting | Selector observation, then measured promotion |
| CI topology | Full PR/main graph with exact tested-commit release, parallel semantic test lanes, a fail-closed `Tests` aggregator, and a non-blocking post-gate timing/miss observer | Minimum-toolchain and macOS smoke are expected to become the next critical-path owners; code-level compiler and harness costs remain measured follow-up work | Keep the observer unable to skip jobs; optimize the newly visible owners from evidence rather than weakening lanes | Measured R2/R3 promotion |
| Retry policy | macOS Mix and QA-sentinel Playwright paths retry failed semantic tests | A later pass can erase the original red outcome or log; setup/download retries are not classified separately | Preserve attempt logs/outcomes and classify setup, infrastructure, flake, and deterministic semantic failures without turning red into an unqualified pass | Retry-policy repair |

### Primary Tests critical-path baseline and split

Five successful `main` runs on 2026-08-01/02 supplied timestamped step logs: `30725109709`,
`30723143092`, `30713283042`, `30710833880`, and `30694846998`. These are hosted-runner
measurements, not local estimates. The old sequential `Tests` job had a 50.1-minute p50 and
50.2-minute p95. Checkout, toolchain, cache, and dependency setup took only 29 seconds p50 and
34 seconds p95, so repeating that small setup is cheaper than keeping the behavior owners in one
fifty-minute chain.

| Semantic stage | Bounded local reproduction | p50 | p95 | Owning evidence |
|---|---|---:|---:|---|
| Core snapshots | `npm run test:ci:compiler-core` | 5m 34s | 5m 35s | Core Haxe-to-Elixir compiler conformance |
| Stdlib snapshots | `npm run test:ci:compiler-stdlib` | 4m 05s | 4m 08s | Generated stdlib shape |
| Regression snapshots | `npm run test:ci:compiler-regression` | 7m 31s | 7m 33s | Previously escaped compiler behavior |
| Phoenix + LiveView snapshots | `npm run test:ci:compiler-phoenix` | 6m 21s | 6m 22s | Framework code generation |
| Ecto/OTP/ExUnit/bootstrap snapshots | `npm run test:ci:compiler-target-domains` | 3m 12s | 3m 14s | Independent target-domain generated shapes |
| Negative/compiler/target-quality contracts | `npm run test:ci:compiler-contracts` | 8m 33s | 8m 34s | Diagnostics, result invariants, strict Elixir, and target quality |
| Portable stdlib runtime | `npm run test:ci:stdlib-runtime` | 1m 15s | 1m 16s | Portable Haxe behavior on BEAM |
| Mix + BEAM runtime | `npm run test:ci:mix-runtime` | 7m 34s | 7m 35s | Mix integration, native runtime, and server ownership |
| Persistent Haxe-server differential | `npm run test:ci:server-cache` | 4m 58s | 5m 00s | Warm-cache invalidation versus clean-build output |

The `Test lane / ...` matrix runs these owners independently with `fail-fast: false`, so one failure
does not hide the other lanes' evidence. The stable required check remains `Tests`; it runs after the
whole matrix and fails unless every lane succeeded. Release and the advisory observer depend on that
aggregator. The AST/pass/performance contracts are no longer repeated here because the required
`Guardrails` dependency already runs the exact same commands before the lanes start.

The portable stdlib lane intentionally remains separate even though the broad Mix harness currently
loads the same Haxe-authored modules. Its green result belongs to the portable-runtime scorecard,
while the mixed harness cannot substitute for that claim. Bead `haxe.elixir.codex-bk4` owns removing
the duplicated generation/execution without merging those evidence surfaces. Code-level profiling is
also tracked separately: `haxe.elixir.codex-u9q` for compiler/snapshot cost and
`haxe.elixir.codex-1ud` for the persistent-server differential fixture.

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

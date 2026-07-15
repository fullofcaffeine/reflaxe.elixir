# Production Readiness: What Still Blocks 1.0

This page summarizes what current tests and reviews prove about using Reflaxe.Elixir in production.
It does not claim that every Haxe program is supported, and it is not approval to publish `1.0.0`.

> [!IMPORTANT]
> **Current status (reviewed 2026-07-14): ready for limited, closely monitored production trials,
> but not ready to promise 1.0 stability.** The documented configurations have strong automated test
> coverage. Before 1.0, the project still needs to:
>
> - publish an exact list of APIs and version combinations that 1.0 promises to support;
> - get a qualified licensing review for generated files and bundled runtime/support code; and
> - test one unchanged proposed release build (a release candidate) in independent real-world
>   projects for a defined period.
>
> The compiler bugs found during the review, including the callback-binder bug discovered during OTP
> testing, are fixed. Mix now notices when known Haxe build inputs change, and the compiler refuses
> to overwrite or delete files that it cannot prove it generated. However,
> [`release/manifest.json`](../../release/manifest.json) does not yet authorize a `1.x` release.

Detailed findings and reasons are in the
[1.0 Production Readiness Review](../08-roadmap/1.0-production-readiness-review.md). Execution is
tracked by Beads epic `haxe.elixir.codex-0yn`.

Related policies and support pages:

- [Versioning & Stability](VERSIONING_AND_STABILITY.md)
- [Support Matrix](SUPPORT_MATRIX.md)
- [Known Limitations](KNOWN_LIMITATIONS.md)
- [Stdlib Support Matrix](../04-api-reference/STDLIB_SUPPORT_MATRIX.md)
- [OTP Support Contract](../04-api-reference/OTP_SUPPORT_CONTRACT.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT.md)
- [Security Policy](../../SECURITY.md)
- [Releasing](../10-contributing/RELEASING.md)

## How To Read The Scorecard

- **Ready:** the specific claim in this row has direct automated tests and no known blocker.
- **Conditional:** useful and substantially tested, but safe use still requires the listed limit or
  precaution.
- **Blocked:** a known defect or unanswered decision prevents the project from making this 1.0
  promise.
- **Out of scope:** version 1.0 deliberately does not promise this feature.

Green CI means the tested cases passed. It does not prove untested Haxe semantics, framework
versions, operating systems, third-party libraries, or deployment conditions.

## Current Scorecard

| Dimension | Status | Evidence | Remaining condition or gap |
| --- | --- | --- | --- |
| Haxe program behavior | **Conditional** | Generated-code checks and runtime tests cover normal and invalid inputs, loop control, nested list comprehensions, and callbacks inside `Result` branches | No known compiler bug affects the reviewed examples. The final support list must still say exactly which Haxe code patterns 1.0 promises to handle. |
| Mix build invalidation | **Ready** | Deterministic fingerprint regressions cover same-timestamp edits, timestamp-only touches, recursive HXML, `src_shared`, resources, libraries/package descriptors, toolchain identity, explicit macro inputs, removed roots, and no-op behavior | Macro filesystem reads outside the discoverable graph must be declared with `:extra_inputs`; project watchers do not monitor external package/toolchain caches, but the next `mix compile` detects them. |
| Generated-file ownership | **Ready** | Versioned path/digest manifests, staged formatting, unowned-collision and modified-owned rejection, stale/namespace cleanup, interrupted-transaction recovery, Mix clean, legacy upgrade, source rollback, in-place/isolated examples, and source/package manifest parity | Keep `_GeneratedFiles.json` and reserved transaction paths under compiler control; hand-editing ownership metadata is unsupported. |
| Generated Elixir quality | **Conditional** | Warnings-as-errors examples, canonical `mix format` integration, handwritten-output corpus, support-footprint checks | Some semantics require visible helpers or conservative reducers. Style work can continue after 1.0; unexplained semantic repairs cannot. |
| Haxe stdlib behavior | **Conditional** | Classified manifest, Haxe-authored ExUnit, selected upstream `unitstd`, snapshots | Only the classified subset is claimed. The stable set must be frozen, and the runtime suite should become warning-clean (`haxe.elixir.codex-0yn.7`). |
| Phoenix and LiveView | **Conditional** | Compile/runtime examples, strict Elixir compilation, todo-app Mix tests, browser sentinels, dogfood upgrades | This is the strongest framework surface, but only pinned versions and documented paths are covered. |
| Ecto | **Conditional** | Schema, changeset, repository, query, compile, and runtime fixtures | Selected APIs are covered. Migration `.exs` generation remains experimental. |
| OTP | **Conditional** | Haxe-authored Process/Task/Agent lifecycle runtime test, warning-free generated Elixir, minimum and primary toolchain lanes, typed child-spec snapshots, and Phoenix application boot | Only the local operations and application-wiring shapes in the [OTP Support Contract](../04-api-reference/OTP_SUPPORT_CONTRACT.md) are covered. GenServer, Registry, broad supervisor failure behavior, and distributed OTP are outside the 1.0 promise. |
| Gradual Elixir adoption | **Conditional** | Existing-app guide, safe in-place and isolated output, typed extern generation, hand-written/generated interop example | The compiler protects files it did not generate. The project must still publish the exact pre-1.0 support and version promises and test an unchanged proposed release in an independent project. |
| Shared browser/server logic | **Conditional** | [`16-portable-chat-domain`](../../examples/16-portable-chat-domain/) runs selected domain logic on Elixir and JavaScript | Only a deliberately portable classpath is demonstrated; arbitrary cross-target parity is not claimed. |
| Source checkout vs release package | **Ready** | Reflaxe `_std` staging contract, package smoke, installed-package codegen parity, deterministic artifacts | Consumers should use a release ZIP. Contributors must use the scoped source-checkout HXML, not bare global `haxelib dev`. |
| Release integrity and rollback | **Ready** | Same-CI-commit publication, protected tags, reproducible package builds, checksums and hosted attestations | Host controls remain part of the trust boundary and must be audited at approval time. |
| Licensing and distribution | **Blocked** | GPL-3.0 repository license and current informational guide | A qualified decision must cover generated source and shipped runtime/support code before broad commercial positioning. Tracked by `haxe.elixir.codex-0yn.4`. |
| Toolchains and operating systems | **Conditional** | Ubuntu CI, Elixir 1.14/OTP 25 minimum smoke, macOS smoke, Haxe 4.3.7 | Windows is out of scope. Haxe 5 is preview-only. Untested Haxe 4.x versions are not implied. |
| Security and supply chain | **Conditional** | Gitleaks, npm/Hex advisory gates, pinned Actions, JS/TS CodeQL, release verification | No formal response SLA; CodeQL does not cover Haxe/Elixir; dependency PRs are disabled; downloaded scanner provenance needs verification (`haxe.elixir.codex-0yn.6`). |
| Exact 1.0 support list | **Blocked** | Versioning tiers, API docs, feature and stdlib matrices | There is not yet one complete list connecting every 1.0 promise to its tests and clearly naming what is not supported. Tracked by `haxe.elixir.codex-0yn.5`. |
| Build performance | **Conditional** | Bounded CI, compile/watch benchmark harnesses, scheduled trend artifacts | There is a diagnostic baseline, not a universal compile-latency SLO. Record a candidate regression comparison before approval. |
| Final 1.0 approval | **Blocked** | SemVer policy, deprecation rules, and a release file that rejects unapproved stable versions | The same proposed release still needs a defined test period in independent projects, followed by an explicit decision to approve or reject 1.0. Tracked by `haxe.elixir.codex-0yn.8` and `.9`. |

## Recently Completed 1.0 Work

### Compiler Bugs Fixed

`haxe.elixir.codex-3qh.23`, `.24`, `.25`, and `.26` are closed. Loops now keep the right accumulated
value when they use `break` or `continue`. Nested list comprehensions keep their inner results, and a
loop inside another loop no longer mixes up the two loops' accumulated values. A callback inside a
successful `Result` branch also keeps its own parameter. It can still intentionally use the branch
value, and nested callbacks can safely reuse a parameter name. The Haxe-authored
`test/runtime/loop_control_accumulators` and `test/runtime/nested_dynamic_comprehensions` suites test
the failed loop behavior directly. `test/snapshot/regression/result_switch_lambda_binders` and the
OTP runtime test cover the callback behavior directly.

### Effective Mix Build Inputs

`haxe.elixir.codex-0yn.1` makes Mix rebuild whenever the actual inputs to a Haxe build change, instead
of trusting one directory's modification time. It compares the contents of imported HXML files,
source folders, resources, libraries, compiler versions, declared macro inputs, and settings that can
change generated code. If the saved build record is old or unreadable, Mix rebuilds instead of
incorrectly saying that everything is up to date. Tests cover both changed inputs and the normal case
where nothing changed, including the todo app's shared source folder.

### Generated Output Ownership

`haxe.elixir.codex-0yn.2` replaces direct one-file-at-a-time publication and marker-based clean with
one versioned manifest protocol. The compiler stages and optionally formats the complete output,
rejects unowned collisions and modified hash-owned files, journals updates/stale deletions, and
commits the manifest last. Haxe compilation and Mix clean recover interrupted transactions; version 1
manifests upgrade in place. Lifecycle regressions cover first/unchanged generation, updates, namespace
moves, rollback, collision preservation, clean, and interruption. Package smoke requires identical
version 2 ownership manifests from source and installed-package builds. See
[Generated Output Ownership And Safe Cleanup](../02-user-guide/GENERATED_OUTPUT_OWNERSHIP.md).

### Bounded OTP Contract

`haxe.elixir.codex-0yn.3` replaces broad OTP wording with an exact, testable boundary. A Haxe-authored
runtime fixture starts and stops local processes, covers Task success/timeout/shutdown, and covers
Agent start/read/update/cast ordering/stop. Generated Elixir must compile without warnings on the
minimum and primary toolchains. Typed child specs and `@:application` retain their documented
application-boot evidence, while custom GenServer callbacks, Registry, supervisor restart/failure
policy, raw mailbox behavior, and distributed OTP are explicitly outside the 1.0 promise. See the
[OTP Support Contract](../04-api-reference/OTP_SUPPORT_CONTRACT.md).

## Known 1.0 Blockers

### 1. Decide Licensing And Distribution

`haxe.elixir.codex-0yn.4` requires qualified review of the GPL-3.0 compiler, externs, generated
source, and support/runtime modules that may ship in an application. The result may keep the current
license, add an exception, separate runtime licensing, or adopt another lawful model. Engineering
documentation must not improvise the legal answer.

### 2. Publish One Exact 1.0 Support List

`haxe.elixir.codex-0yn.5` must list the language features, standard-library modules, annotations,
externs, flags, Mix tasks, generated naming rules, framework APIs, versions, and exclusions covered
by 1.0. Every promised item needs an executable test or a precise description of its limits.

This does not require implementing every Haxe or Elixir API. It requires making the claimed subset
true and discoverable.

### 3. Test One Unchanged Release Candidate Outside This Repository

After the product contract is complete, `haxe.elixir.codex-0yn.8` must use immutable packages and
clean workspaces to prove:

- fresh installation, generation, and one-module gradual adoption;
- isolated and in-place output behavior, including collision rejection and stale deletion;
- source/package parity and primary/minimum toolchains;
- upgrade from the previous supported release;
- todo-app and representative Phoenix runtime/browser behavior;
- rollback by restoring the previous immutable tag;
- warning-clean stdlib evidence and verified CI security-tool provenance.

Run the same release candidate long enough to receive and address feedback from real users. Do not
quietly change the proposed 1.0 promise during that test period.

### 4. Explicitly Approve Or Reject 1.0

`haxe.elixir.codex-0yn.9` reviews the completed evidence and either approves or rejects a 1.0 release.
Only an approval may populate `releaseLines.1.approval`. Approval does not publish a release; a later
reviewed breaking Conventional Commit allows semantic-release to derive `1.0.0`.

## Features 1.0 Does Not Need To Promise

These can remain deferred when the support contract says so clearly:

- Haxe 5 and Windows support;
- Phoenix 1.6 and older;
- complete Haxe stdlib or BEAM ecosystem coverage;
- source maps, migration `.exs` generation, and `fast_boot` graduating from experimental;
- every idiomatic-output optimization or elimination of semantically required runtime helpers;
- internal AST pass API compatibility;
- a universal compile-time performance promise.

Version 1.0 can make a reliable, limited promise without supporting every possible Haxe or Elixir
feature.

## Production Pilots Before 1.0

Use the compiler in a production pilot only when all of these conditions are acceptable:

1. Pin an immutable release tag, verify its checksum, and review GPL distribution implications.
2. Pin a tested toolchain from the [Support Matrix](SUPPORT_MATRIX.md).
3. Choose an isolated or in-place generated root deliberately; retain `_GeneratedFiles.json`, and
   treat any unowned collision or modified-owned error as a source-of-truth decision rather than
   bypassing the check.
4. Declare any out-of-graph macro reads with `:extra_inputs`; retain a clean full generation in CI as
   defense in depth.
5. Stay inside the documented supported surface.
6. Compile generated Elixir with warnings as errors and review the target diff.
7. Add runtime tests around important generated and extern boundaries.
8. Keep the previous release tag as the rollback pin.

These precautions make an early production trial safer. They do not provide the same confidence as
years of independent production use.

## Required Evidence

The final local/CI evidence set for compiler or framework semantics is:

```bash
npm run ci:guards
npm test
npm run test:haxe-exunit-stdlib
npm run guard:upstream-unitstd
npm run test:examples
npm run test:examples-output
npm run test:examples-elixir
npm run test:examples-runtime
npm run test:haxelib-package
npm run ci:budgets
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --env e2e --playwright --e2e-spec "e2e/smoke/*.spec.ts" --async --deadline 900 --verbose
```

Release-policy and package work additionally uses the exact commands in
[Releasing](../10-contributing/RELEASING.md). The latest `main` CI for the exact reviewed commit must
be green; a nearby green commit is not evidence for a changed tree.

## Final 1.0 Approval

The final decision must state:

- the exact supported language, stdlib, framework, build, ABI, and toolchain subset;
- every remaining known limitation and why none is a P0/P1 issue in that subset;
- package provenance, source/package parity, and external install/upgrade/rollback evidence;
- generated-file ownership and complete invalidation evidence;
- licensing/distribution policy and security residuals;
- stabilization duration, candidate performance comparison, and reviewer approval.

Until that decision exists, README language remains pre-1.0 and conditional.

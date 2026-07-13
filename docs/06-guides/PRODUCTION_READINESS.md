# Production Readiness And The 1.0 Gate

This page is the current evidence-based readiness contract for Reflaxe.Elixir. It does not claim that
every Haxe program is supported, and it is not approval to publish `1.0.0`.

> [!IMPORTANT]
> **Current verdict (reviewed 2026-07-13): suitable for controlled production pilots, not general
> 1.0 stability.** The pinned and documented paths have substantial project-local evidence. Stable
> graduation is still blocked by known semantic defects, incomplete build invalidation and generated
> output ownership, an unfrozen support contract, unbounded OTP wording, a licensing decision, and an
> external stabilization run. The `1` release line remains unapproved in
> [`release/manifest.json`](../../release/manifest.json).

The durable findings and rationale are in the
[1.0 Production Readiness Review](../08-roadmap/1.0-production-readiness-review.md). Execution is
tracked by Beads epic `haxe.elixir.codex-0yn`.

Related contracts:

- [Versioning & Stability](VERSIONING_AND_STABILITY.md)
- [Support Matrix](SUPPORT_MATRIX.md)
- [Known Limitations](KNOWN_LIMITATIONS.md)
- [Stdlib Support Matrix](../04-api-reference/STDLIB_SUPPORT_MATRIX.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT.md)
- [Security Policy](../../SECURITY.md)
- [Releasing](../10-contributing/RELEASING.md)

## How To Read The Scorecard

- **Ready:** the stated, bounded contract has direct automated evidence and no known blocker.
- **Conditional:** useful and substantially tested, but use requires an explicit constraint or
  operational safeguard.
- **Blocked:** a known defect or missing decision prevents the stated 1.0 claim.
- **Out of scope:** intentionally excluded from 1.0 and documented as such.

Green CI means the tested cases passed. It does not prove untested Haxe semantics, framework
versions, operating systems, third-party libraries, or deployment conditions.

## Current Scorecard

| Dimension | Status | Evidence | Remaining condition or gap |
| --- | --- | --- | --- |
| Compiler semantics | **Blocked** | Full snapshot categories, negative cases, function-result invariants, generated Elixir validation, Mix runtime tests | P1 defects `haxe.elixir.codex-3qh.23` and `.24` affect reducer control flow and nested dynamic comprehensions. |
| Mix build invalidation | **Blocked** | Mix compiler tests and example builds | The current freshness model does not fingerprint every effective HXML, define, library/toolchain, or additional classpath input. A normal incremental compile can retain stale output. Tracked by `haxe.elixir.codex-0yn.1`. |
| Generated-file ownership | **Blocked** | Isolated output, generated-file metadata in selected paths, package and upgrade tests | In-place writes, clean, stale deletion, and collision handling do not yet share one fail-closed ownership protocol for all generated app modules. Tracked by `haxe.elixir.codex-0yn.2`. |
| Generated Elixir quality | **Conditional** | Warnings-as-errors examples, canonical `mix format` integration, handwritten-output corpus, support-footprint checks | Some semantics require visible helpers or conservative reducers. Style work can continue after 1.0; unexplained semantic repairs cannot. |
| Haxe stdlib behavior | **Conditional** | Classified manifest, Haxe-authored ExUnit, selected upstream `unitstd`, snapshots | Only the classified subset is claimed. The stable set must be frozen, and the runtime suite should become warning-clean (`haxe.elixir.codex-0yn.7`). |
| Phoenix and LiveView | **Conditional** | Compile/runtime examples, strict Elixir compilation, todo-app Mix tests, browser sentinels, dogfood upgrades | This is the strongest framework surface, but only pinned versions and documented paths are covered. |
| Ecto | **Conditional** | Schema, changeset, repository, query, compile, and runtime fixtures | Selected APIs are covered. Migration `.exs` generation remains experimental. |
| OTP | **Blocked for a broad claim** | Typed APIs, snapshots, and selected runtime examples | 1.0 must prove a bounded lifecycle/failure subset or narrow the stable wording. Tracked by `haxe.elixir.codex-0yn.3`. |
| Gradual Elixir adoption | **Conditional** | Existing-app guide, isolated namespaces, typed extern generation, hand-written/generated interop example | The model is sound, but production use must account for the open invalidation and ownership gaps. |
| Shared browser/server logic | **Conditional** | [`16-portable-chat-domain`](../../examples/16-portable-chat-domain/) runs selected domain logic on Elixir and JavaScript | Only a deliberately portable classpath is demonstrated; arbitrary cross-target parity is not claimed. |
| Source checkout vs release package | **Ready** | Reflaxe `_std` staging contract, package smoke, installed-package codegen parity, deterministic artifacts | Consumers should use a release ZIP. Contributors must use the scoped source-checkout HXML, not bare global `haxelib dev`. |
| Release integrity and rollback | **Ready** | Same-CI-commit publication, protected tags, reproducible package builds, checksums and hosted attestations | Host controls remain part of the trust boundary and must be audited at approval time. |
| Licensing and distribution | **Blocked** | GPL-3.0 repository license and current informational guide | A qualified decision must cover generated source and shipped runtime/support code before broad commercial positioning. Tracked by `haxe.elixir.codex-0yn.4`. |
| Toolchains and operating systems | **Conditional** | Ubuntu CI, Elixir 1.14/OTP 25 minimum smoke, macOS smoke, Haxe 4.3.7 | Windows is out of scope. Haxe 5 is preview-only. Untested Haxe 4.x versions are not implied. |
| Security and supply chain | **Conditional** | Gitleaks, npm/Hex advisory gates, pinned Actions, JS/TS CodeQL, release verification | No formal response SLA; CodeQL does not cover Haxe/Elixir; dependency PRs are disabled; downloaded scanner provenance needs verification (`haxe.elixir.codex-0yn.6`). |
| Stable support contract | **Blocked** | Versioning tiers, API docs, feature and stdlib matrices | There is no single enumerable 1.0 inventory tying every stable claim to evidence and exclusions. Tracked by `haxe.elixir.codex-0yn.5`. |
| Build performance | **Conditional** | Bounded CI, compile/watch benchmark harnesses, scheduled trend artifacts | There is a diagnostic baseline, not a universal compile-latency SLO. Record a candidate regression comparison before approval. |
| Stability governance | **Blocked** | SemVer policy, deprecation rules, fail-closed per-major manifest | External soak evidence and an explicit graduation decision are absent. Tracked by `haxe.elixir.codex-0yn.8` and `.9`. |

## Known 1.0 Blockers

### 1. Close Known P1 Correctness Defects

- `haxe.elixir.codex-3qh.23`: reducer-lowered accumulator loops can emit uncaught internal
  `break`/`continue` throws.
- `haxe.elixir.codex-3qh.24`: nested array comprehensions over dynamic iterables can lose the inner
  result tail.

Both require Haxe-authored runtime tests and fixes at the typed/Elixir AST lowering boundary. Target
injection in a regression test or generated-text cleanup is not an acceptable substitute.

### 2. Make Incremental Builds Complete

`haxe.elixir.codex-0yn.1` must replace the single-root/mtime-oriented freshness decision with a
deterministic model of all effective source roots, nested HXML files, defines, libraries, compiler
identity, and relevant configuration. Tests must prove both rebuild and no-op behavior.

### 3. Make Generated Output Fail Closed

`haxe.elixir.codex-0yn.2` must give generation, formatting, clean, upgrade, stale deletion, and
rollback one atomic ownership protocol. An existing hand-written file must never be overwritten or
deleted merely because its target path matches generated output.

### 4. Bound The OTP Contract

`haxe.elixir.codex-0yn.3` can be resolved in either of two honest ways:

- prove selected lifecycle and failure semantics with runtime conformance tests; or
- remove unproved OTP paths from the stable tier.

API-shaped output or compilation alone is not enough evidence for supervision behavior.

### 5. Decide Licensing And Distribution

`haxe.elixir.codex-0yn.4` requires qualified review of the GPL-3.0 compiler, externs, generated
source, and support/runtime modules that may ship in an application. The result may keep the current
license, add an exception, separate runtime licensing, or adopt another lawful model. Engineering
documentation must not improvise the legal answer.

### 6. Freeze One Enumerable Stable Surface

`haxe.elixir.codex-0yn.5` must inventory language forms, stdlib modules, annotations, externs, flags,
Mix tasks, generated ABI/naming, framework APIs, versions, and exclusions. Every stable item needs
executable evidence or a precise bounded behavior statement.

This does not require implementing every Haxe or Elixir API. It requires making the claimed subset
true and discoverable.

### 7. Run External Stabilization

After the product contract is complete, `haxe.elixir.codex-0yn.8` must use immutable packages and
clean workspaces to prove:

- fresh installation, generation, and one-module gradual adoption;
- isolated and in-place output behavior, including collision rejection and stale deletion;
- source/package parity and primary/minimum toolchains;
- upgrade from the previous supported release;
- todo-app and representative Phoenix runtime/browser behavior;
- rollback by restoring the previous immutable tag;
- warning-clean stdlib evidence and verified CI security-tool provenance.

The stabilization window must be long enough to receive and resolve package/adopter feedback without
casually changing the proposed stable contract.

### 8. Approve Graduation Explicitly

`haxe.elixir.codex-0yn.9` reviews the completed evidence and either approves or rejects graduation.
Only an approval may populate `releaseLines.1.approval`. Approval does not publish a release; a later
reviewed breaking Conventional Commit allows semantic-release to derive `1.0.0`.

## What Does Not Block A Bounded 1.0

These can remain deferred when the support contract says so clearly:

- Haxe 5 and Windows support;
- Phoenix 1.6 and older;
- complete Haxe stdlib or BEAM ecosystem coverage;
- source maps, migration `.exs` generation, and `fast_boot` graduating from experimental;
- every idiomatic-output optimization or elimination of semantically required runtime helpers;
- internal AST pass API compatibility;
- a universal compile-time performance promise.

A bounded 1.0 can be stable without being universal.

## Production Pilots Before 1.0

Use the compiler in a production pilot only when all of these conditions are acceptable:

1. Pin an immutable release tag, verify its checksum, and review GPL distribution implications.
2. Pin a tested toolchain from the [Support Matrix](SUPPORT_MATRIX.md).
3. Prefer an isolated generated root; if output shares a tree with hand-written Elixir, review
   ownership and collisions explicitly.
4. Run a clean full generation in CI instead of relying only on incremental freshness.
5. Stay inside documented surfaces and confirm the app does not depend on either known P1 bug shape.
6. Compile generated Elixir with warnings as errors and review the target diff.
7. Add runtime tests around important generated and extern boundaries.
8. Keep the previous release tag as the rollback pin.

This is a controlled-adoption contract, not the assurance of a mature compiler with years of
independent production use.

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

## Graduation Decision

The final decision must state:

- the exact supported language, stdlib, framework, build, ABI, and toolchain subset;
- every remaining known limitation and why none is a P0/P1 issue in that subset;
- package provenance, source/package parity, and external install/upgrade/rollback evidence;
- generated-file ownership and complete invalidation evidence;
- licensing/distribution policy and security residuals;
- stabilization duration, candidate performance comparison, and reviewer approval.

Until that decision exists, README language remains pre-1.0 and conditional.

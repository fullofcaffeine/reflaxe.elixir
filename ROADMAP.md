# Reflaxe.Elixir Roadmap To 1.0

Reflaxe.Elixir is on the pre-1.0 (`v0.x`) release line. The immediate goal is a defensible `1.0.0`:
complete support for the public Haxe standard library that applies to generated Elixir programs,
plus an exact and tested language, Phoenix, Ecto, OTP, build, and toolchain contract. It is not a
promise to support every Phoenix version, BEAM library, operating system, or possible Haxe program.

The current scorecard lives in [Production Readiness](docs/06-guides/PRODUCTION_READINESS.md), and the
adversarial baseline is preserved in the
[1.0 Production Readiness Review](docs/08-roadmap/1.0-production-readiness-review.md). Work status and
dependencies live in Beads epic `haxe.elixir.codex-0yn`; this file explains direction rather than
duplicating issue state.

## Before 1.0

### 1. Correctness Before Breadth

- Fix all known P0/P1 semantic defects in the documented subset.
- Keep runtime semantics, snapshots, negative tests, source/package parity, examples, and browser QA
  aligned for every fix.
- Reject generated-text cleanup and test escape hatches as substitutes for fixing typed/Elixir AST
  ownership.

The reducer, nested-comprehension, nested-accumulator, and callback-binder defects found during the
readiness review are closed with direct Haxe runtime or generated-output regressions.

### 2. Complete The Haxe Standard Library

- Inventory every public API in the pinned Haxe standard library, not just local target files.
- Use the official Haxe implementation unchanged when it works, compiler lowering when it maps
  directly, and a BEAM-specific override or helper when Haxe semantics need one.
- Require positive compile and runtime evidence for every runtime-relevant API.
- Allow “not applicable” only for compile-time or other-target-only declarations with a narrow,
  source-backed reason.
- Reach zero unsupported, partial, unknown, or untested runtime-relevant entries before 1.0.

This 1.0 requirement is tracked by `haxe.elixir.codex-0yn.10`. The current unsupported and partial
stdlib behavior is real release work, even when Ecto or another Elixir-native API remains the
recommended authoring style. See
[Standard Libraries And Packages](docs/08-roadmap/stdlib-and-package-ecosystem.md).

### 3. Make Build And Generated Output Lifecycles Safe

- Fingerprint every effective Haxe input used by `mix compile`, including nested HXML, defines,
  libraries, compiler identity, and every source/classpath root.
- Give generation, formatting, stale deletion, clean, upgrade, and rollback one fail-closed ownership
  manifest.
- Reject a hand-written target collision before changing any file, and never clean an unowned file.

These are tracked by `haxe.elixir.codex-0yn.1` and `.2`.

### 4. Publish A Truthful Support List

- Audit public annotations, externs, Mix tasks, flags, stdlib APIs, naming, and framework APIs against
  executable evidence.
- Keep stable, experimental, internal, unsupported, and out-of-scope surfaces visibly distinct.
- Preserve one compiler pipeline for portable and Elixir-first authoring; profiles are authoring
  guidance, not semantic backend switches.
- Prove a bounded OTP lifecycle/failure subset or move unproved paths outside the stable tier.

The exact support list is tracked by `haxe.elixir.codex-0yn.5`; it cannot close before the complete
stdlib review. OTP scope is `haxe.elixir.codex-0yn.3`.

### 5. Decide Distribution Policy

- Obtain qualified review of GPL-3.0 compiler use, generated source, and shipped runtime/support code.
- Make the resulting policy visible near installation, package metadata, and commercial positioning.
- Keep engineering docs informational; do not improvise legal conclusions.

This decision is tracked by `haxe.elixir.codex-0yn.4`.

### 6. Test One Release Candidate In Clean External Projects

- Install the immutable release package in a clean external workspace.
- Exercise one-module gradual adoption, a generated Phoenix app, source/package parity, and upgrade
  from the previous supported release.
- Run the primary/minimum toolchains, package smoke, runtime examples, todo-app and chat sentinels,
  collision/stale-file cases, verified security tooling, warning-clean stdlib runtime, and rollback
  pinning during a defined external test period.

This real-world test period is tracked by `haxe.elixir.codex-0yn.8`.

### 7. Make The Final 1.0 Decision

- Review remaining limitations and confirm none is a P0/P1 correctness issue in the stable subset.
- Record the exact support boundary and results from the external test period in a durable decision.
- Populate the major-1 approval in `release/manifest.json` only after that review.
- Let a subsequent reviewed breaking Conventional Commit derive `1.0.0`; do not manufacture the
  version by editing tracked version strings.

The final approve-or-reject decision is tracked by `haxe.elixir.codex-0yn.9`.

## After 1.0

These are important 1.x work, but they are separate from the Haxe stdlib promise required for 1.0:

- a complete, versioned, properly typed Haxe surface for the public Elixir standard library;
- deterministic package-level adoption for Mix dependencies, with precise-or-omitted mapping from
  published Elixir types to Haxe types, safe writes, and companion-package conventions;
- more direct native string and finite-float operations where semantic proofs allow them;
- fewer avoidable IIFEs and conservative reducers in generated output;
- useful generated typespecs and broader behaviour/protocol surfaces;
- smaller runtime/support footprint and clearer DCE controls;
- moving source maps from experimental to supported after end-to-end debugger evidence;
- broader framework/version matrices based on adopter demand;
- stronger static-analysis coverage as Haxe/Elixir tooling becomes available;
- Haxe 5 support after its typed AST is stable enough for a supported contract;
- Windows support when the project can add a real CI lane and ownership.

## Product Direction

The compiler is not trying to replace Elixir with a sealed new ecosystem. Its durable product thesis
is narrower:

1. Add a typed Haxe authoring layer where it removes meaningful boundary risk or duplication.
2. Emit reviewable Elixir that remains at home in Mix, Phoenix, Ecto, OTP, and BEAM operations.
3. Let generated and hand-written Elixir coexist so adoption and rollback can happen module by
   module.
4. Share only genuinely portable domain logic across server and browser targets.
5. Prefer target-native output whenever semantics allow, and make required Haxe-runtime machinery
   visible and explainable when they do not.

See [Why Reflaxe.Elixir?](docs/01-getting-started/WHY_REFLAXE_ELIXIR.md) for the user-facing product
position, [Standard Libraries And Packages](docs/08-roadmap/stdlib-and-package-ecosystem.md) for the
stdlib and ecosystem plan, and [Vision](docs/08-roadmap/vision.md) for longer-term principles.

## Scope Boundaries

The following are explicitly not implied by 1.0:

- every possible combination of Haxe language features, even though the applicable public Haxe
  stdlib itself must be complete;
- a complete typed surface for the Elixir standard library or every Hex/Mix dependency (these are
  explicit 1.x workstreams);
- every Phoenix, Ecto, OTP, or Elixir library version;
- Haxe 5 or Windows support;
- zero generated runtime helpers;
- source compatibility for internal AST pass APIs;
- production status for features still labeled experimental;
- a paid support SLA or a mature independent adopter ecosystem.

The framework and toolchain contract can stay narrow. The Haxe standard-library contract cannot hide
runtime gaps behind that boundary.

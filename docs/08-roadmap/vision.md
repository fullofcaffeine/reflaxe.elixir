# Vision: Typed Elixir Without Leaving Elixir Behind

Reflaxe.Elixir aims to make static typing, compile-time abstractions, and selected cross-target code
sharing available to Elixir teams without asking them to abandon the Elixir/Phoenix application
model.

This is a direction document, not a release contract. Current stability and support boundaries live
in [Production Readiness](../06-guides/PRODUCTION_READINESS.md) and
[Versioning & Stability](../06-guides/VERSIONING_AND_STABILITY.md).

## The Thesis

Many teams do not need a new runtime or an all-or-nothing language migration. They need stronger
feedback at a few expensive boundaries:

- framework callbacks and assigns;
- application data shapes and result values;
- route, schema, changeset, and query declarations;
- OTP child specs and message contracts;
- browser/server domain rules;
- repetitive project-specific glue that drifts during refactors.

Haxe can provide that authoring layer. Reflaxe.Elixir's job is to lower it into conventional Elixir
source that enters the normal Mix build and remains understandable to Elixir developers.

## The Product Promise

### Adopt It Gradually

A team should be able to start with one generated module in an isolated namespace, test it from
Elixir, inspect the output, and remove it without restructuring the application. Haxe-first Phoenix
applications are supported, but they are a destination a team can choose, not an entry requirement.

### Generate Target-Native Code

Generated Elixir should look like a capable Elixir developer wrote it whenever source and target
semantics agree: normal `case`, `cond`, pattern matching, maps, tuples, `Enum`, pipelines, framework
callbacks, and Mix-compatible files. Required Haxe semantic machinery must be centralized, bounded,
and visible rather than hidden behind a marketing claim.

### Type The Boundaries That Matter

Types should prevent duplicated strings, invalid field selectors, mismatched callback returns, unsafe
child specs, and unreviewed external terms before they reach a deployed system. The compiler should
not wrap every Elixir call merely to say it is typed; abstractions must remove real drift or risk.

### Keep Elixir Interoperability First-Class

Hand-written Elixir is not legacy code. Existing modules, dependencies, and operational tools remain
normal parts of the system. Typed externs describe stable boundaries to Haxe; generated modules expose
ordinary function/arity contracts back to Elixir.

### Share Only Portable Logic

Haxe's JavaScript and other targets create a valuable option for selected domain logic. Portability
must be explicit: deterministic data rules can be shared, while Phoenix, Ecto, OTP, DOM, and platform
integration stay in target-specific edges. The goal is less duplicated business logic, not one giant
lowest-common-denominator application.

## Why Haxe

Haxe combines several useful traits in one mature compiler front end:

- static type inference and structural records;
- algebraic enums and pattern matching;
- expression-oriented control flow and higher-order functions;
- compile-time macros, metadata, and typed DSL construction;
- typed externs for native ecosystem APIs;
- established JavaScript and other source/runtime targets;
- enough imperative and object-oriented support to adopt existing Haxe code, with functional style
  available where it maps naturally to Elixir.

That breadth is also a cost. Reflaxe.Elixir must preserve semantics for source features that have no
direct Elixir equivalent. The project therefore supports both Elixir-first and portable authoring
through one compiler pipeline and makes their tradeoffs explicit.

## An LLM Lever, Not An AI Runtime

The project does not need a proprietary AI service or generated-code magic to improve AI-assisted
development. Its leverage comes from deterministic structure:

- typed Phoenix/Ecto/OTP vocabulary narrows valid completions;
- macros replace repeated stringly boilerplate with compiler-checked declarations;
- Haxe source, generated Elixir, tests, and snapshots provide multiple reviewable representations;
- compile errors and runtime suites catch invalid suggestions before deployment;
- one portable domain model can give an assistant shared client/server context without duplicating
  rules by hand.

LLMs remain fallible. The compiler and tests are the verification layer; generated suggestions are
not evidence by themselves.

## Design Principles

1. **Correctness before aesthetics.** Handwritten-looking output is valuable only when behavior is
   preserved.
2. **Elixir remains the runtime model.** Supervision, processes, messages, framework callbacks, and
   Mix releases are not hidden behind a foreign runtime.
3. **Gradual adoption and rollback are product features.** Generated modules must coexist cleanly
   with hand-written code and immutable release pins.
4. **One semantic pipeline.** Portable and Elixir-first are authoring profiles, not divergent
   backends that silently change behavior.
5. **Abstractions must pay rent.** Add a macro or wrapper only when it removes meaningful duplication,
   unsafe states, or maintenance drift.
6. **Target output is a public artifact.** Naming, formatting, file placement, warnings, runtime
   footprint, and source/package parity receive direct CI review.
7. **Support claims follow executable evidence.** Examples, runtime tests, package smoke, upgrade
   dogfood, and browser sentinels define the supported subset more credibly than feature lists.

## Long-Term Directions

After a defensible 1.0, the project can expand in measured steps:

- improve native Elixir lowering where semantic proofs permit it;
- broaden stable Phoenix/Ecto/OTP externs based on real application needs;
- emit useful typespecs for target-native public surfaces;
- reduce avoidable runtime footprint while preserving Haxe behavior;
- graduate source maps only after end-to-end debugging works reliably;
- expand stdlib conformance through upstream runtime fixtures;
- strengthen portable server/browser examples and protocol tooling;
- evaluate Haxe 5 and additional host platforms only with dedicated CI contracts.

Mobile, desktop, additional Reflaxe targets, or migration compilers may be useful future projects, but
they are not current Reflaxe.Elixir capabilities and do not belong in the 1.0 promise.

## Success Looks Like

The vision is working when an Elixir developer can review a generated module without learning a
private runtime, a Haxe developer can use familiar typed tools without fighting BEAM conventions, and
a team can adopt or remove the compiler one bounded feature at a time.

The best outcome is not the largest amount of Haxe. It is the smallest typed layer that makes the
system safer, easier to refactor, and less repetitive while leaving a normal Elixir application
behind.

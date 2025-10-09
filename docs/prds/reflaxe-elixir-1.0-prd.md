# Reflaxe.Elixir v1.0 PRD — Idiomatic Elixir From Haxe, Production-Ready

Date: 2025-10-08
Owner: Reflaxe.Elixir Compiler Team
Status: Draft for execution (to be tracked via Shrimp tasks)

## 1) Executive Summary

Reflaxe.Elixir compiles typed Haxe into idiomatic Elixir that looks hand‑written, integrates deeply with Phoenix/Ecto/OTP, and leverages Haxe’s type system (macros, abstracts, typing) to improve Elixir developer ergonomics. v1.0 delivers:

- Idiomatic Elixir output that passes human review and compiles cleanly.
- Full Phoenix/Ecto/OTP integration following official APIs and conventions (no invented APIs).
- Solid Haxe stdlib + Elixir stdlib coverage via externs/overrides with correct target-conditional classpath.
- AST-based pipeline (Builder → Transformer → Printer) with hygienic variable handling.
- Snapshot tests guarding shapes and idioms; todo-app compiles and runs as primary integration test.
- Documentation that encourages writing Haxe “the Elixir way” while allowing imperative Haxe compiled to functional Elixir equivalents.

Non-negotiables:
- No band-aids, no TODOs in production code. Fix root causes.
- Never use `-D analyzer-optimize` for Elixir target; optimize for idiomatic/maintainable Elixir.

## 2) Goals and Success Criteria

Functional goals
- Generate idiomatic Elixir for core language features and patterns (pattern matching, pipelines, case/switch, enums, comprehensions, protocols, behaviors, supervision trees).
- Support Phoenix (controllers, LiveView, components, router), Ecto (schemas, changesets, migrations, queries), and OTP (GenServer, Supervisor, Registry) idioms.
- Provide Haxe-driven type-safe augmentations: typed assigns, typed events, typed socket structures, typed changesets, typed routes, etc., while emitting standard Phoenix/Ecto calls.
- Compile imperative Haxe into equivalent functional Elixir patterns where applicable (loops → Enum pipelines/comprehensions), while recommending an “Elixir style” in docs.

Architecture goals
- AST-only pipeline (TypedExpr → ElixirAST → Transformations → Printer) with predictable passes and context preservation.
- Hygienic name resolution; no infrastructure variables (`_g`, `g1`, etc.) leaked to final code.
- Target-conditional classpath injection for std overrides to avoid macro-context pollution.
- Snapshot testing discipline with idiomatic intended outputs. Todo-app acts as integration canary.

Quality gates (must all be true for v1.0)
- 0 undefined-variable errors; 0 infrastructure variable leaks; reserved words escaped.
- Todo-app compiles and runs; Phoenix server boots; core routes respond.
- Snapshot suite passes at 90%+ with remaining failures triaged or intentionally skipped via principled exclusions (not band-aids).
- No analyzer-optimize; generated Elixir reads as natural/idiomatic.

## 3) Current State (Observed)

Source of truth: repository docs and code as of 2025-10-08.

- Pipeline: AST-based default in `src/reflaxe/elixir/ast/` (Builder, Transformer, Printer) — complete and in active use.
- Tests: Extensive snapshot suites under `test/snapshot/` (core, phoenix, ecto, regression, stdlib). Reported pass rate in `COMPILER_1.0_ROADMAP.md` is ~19% (40/208) and trending unstable pending fixes.
- Integration app: `examples/todo-app` exists; compilation currently blocked by enum parameter extraction producing undefined `_g` in generated Elixir (see `COMPILER_1.0_ROADMAP.md`).
- Variable hygiene and mapping: TVar.id→name mapping infra exists but not fully integrated in all builders/transforms; leaks of infrastructure variables observed in snapshots and todo-app output.
- Enum parameter extraction: Known bug where TEnumParameter falls back to infra var when `enumBindingPlan`/clause context not preserved.
- Loop/iterator desugaring: Several patterns improved; still requires consistent TVar.id-based name mapping and idiomatic `Enum.with_index` where beneficial.
- Stdlib and externs: Broad coverage present; target-conditional classpath injection not fully implemented (risk of macro-context exposure of `__elixir__()` constructs).
- Documentation: Rich architecture docs; snapshot testing policy documented; guidance against `analyzer-optimize` present; Phoenix integration and “Haxe for Phoenix” guides exist. README claims production-ready status that should match v1.0 reality once blockers are resolved.

## 4) Gaps to v1.0 (What’s Left)

P0 (blockers)
- Enum parameter extraction bug causing `_g` undefined assignments in switch/case bodies; body should directly use pattern-bound variables.
- Todo-app fails to compile; must build and run cleanly (mix compile, phx.server) with idiomatic output.

P1 (quality, idiom, stability)
- Variable hygiene: complete TVar.id mapping integration across loop desugaring and any builder paths generating temps.
- Infrastructure variable elimination and reserved-word escaping pass; assert final AST contains no `_g*` names.
- Context preservation audit in Builder/Transformer invocations; remove any bypass routes (e.g., compileExpressionImpl) that drop clause context.
- Improve loop/array iteration idioms (Enum.with_index for indexed cases; prefer comprehensions when clearer).
- Snapshot coverage for enum parameter binding, loop desugaring with indices, phoenix assign/event typing shapes.

P2 (architecture, ecosystem)
- Target-conditional classpath injection for `.cross.hx`/std overrides; macro context sees regular Haxe std only.
- Phoenix/Ecto integration polish on edge cases (Presence patterns, LiveView assigns typing surface, changeset ergonomics).
- Documentation updates: “Write Haxe the Elixir Way” quick guide surfaced in README, with links to detailed patterns.

## 5) Non-Goals for v1.0

- No analyzer-based cross-target optimizations; prefer idiomatic readability over premature micro-opts.
- No vendor lock-in abstractions that diverge from Phoenix/Ecto APIs; Haxe aids at compile-time but runtime APIs are canonical.
- No detours via string post-processing or output regex cleanups; fixes must occur in AST pipeline.

## 6) Functional Requirements (Representative)

Language features
- Pattern matching: correct binding propagation from case head to body; guard extraction; clause ordering preserved.
- Enums/ADTs: constructors compile to tagged tuples; parameters available by variable name; no redundant rebinds.
- Loops/Comprehensions: imperative for/while reduce to idiomatic pipelines or comprehensions with clear scope and indices.
- Functions: arities preserved; unused params prefixed; reserved words escaped.

Phoenix/Ecto/OTP
- LiveView: typed assigns/events → standard `assign/3`, `handle_event/3` with compile-time checks; generated code matches common patterns.
- Ecto: schemas, changesets, migrations emit conventional DSL; pipelines readable.
- OTP: GenServer callbacks typed and mapped to idiomatic callbacks; Supervisor child specs idiomatic.

Stdlib
- Haxe std mapped or bridged to Elixir equivalents where possible; unsupported pieces documented with deliberate extern design (no fake APIs).

## 7) Technical Design Notes

AST pipeline (current)
- Builder: TypedExpr→ElixirAST with complete context (clause, enum binding plan, variable ids).
- Transformer: Pass-based, pure functions; multi-pass sequencing explicit; no logic duplication across builder/transformer.
- Printer: Strictly formatting/naming; no semantic rewrites.

Hygiene & Symbols
- Adopt/complete a minimal symbol table overlay keyed by TVar.id for hygienic naming and shadowing handling. Compute final names late, use everywhere.
- Eliminate infrastructure variable emissions in final AST; add validation pass that fails CI if any remain.

Context Preservation
- All compile steps that descend into subexpressions must carry live ClauseContext (no new-compilation-context fall-throughs). Replace any `compileExpressionImpl` routes that reset state with builder entry preserving context.

Target-conditional classpath
- Move std override injection to bootstrap/CompilerInit to only include Elixir-specific `.cross.hx` under the Elixir target, not in macro or other targets.

## 8) Testing & Validation

Snapshot tests (required)
- regression/enum_parameter_in_switch — direct use of pattern names, no rebind.
- loop_desugaring/with_index — prefer Enum.with_index when index required; otherwise comprehensions.
- phoenix/assigns_and_events_typing — typed assigns/events compile to idiomatic LiveView.
- stdlib/extern_injection_guard — ensure macro context doesn’t see Elixir-only paths.

Todo-app integration
- Haxe compile: `npx haxe build-server.hxml`
- Elixir compile: `mix compile --force`
- Runtime: `mix phx.server`, basic route checks; presence or pubsub flows compile and run.

Quality gates
- No `_g*` names in printed code (enforced via AST validation pass + CI check).
- No empty `()` expressions; unused params prefixed with `_`.
- Reserved words escaped consistently.

## 9) Milestones & Timeline (Guidance)

M0 — Stabilization (1–2 days)
- Fix enum parameter `_g` bug via context preservation + single-source-of-truth enumBindingPlan in Builder.
- Get todo-app to compile; accept Elixir warnings temporarily if needed but no undefined vars.

M1 — Hygiene & Symbolization (3–5 days)
- Complete TVar.id-based name mapping across loop desugaring and all builder sites.
- Add hygiene pass for final names; reserved words; underscore unused params.
- Add AST validation to prohibit infra vars in final output.

M2 — Idiom & Coverage (3–4 days)
- Implement Enum.with_index optimization and comprehension preference.
- Expand snapshot coverage for Phoenix/Ecto patterns and stdlib surfaces.
- Target-conditional classpath injection for std overrides.

M3 — Hardening (3–4 days)
- Burn down remaining snapshot failures to ≥90% pass rate.
- Polish todo-app warnings; ensure runtime stability; finalize docs.

## 10) Risks & Mitigations

- Context-loss regressions — Mitigate with explicit builder entry points that preserve ClauseContext and unit tests for enum/loop paths.
- Multiple detection paths — Consolidate detection to AST passes; add comments and guards to prevent logic duplication.
- Std override exposure in macro context — Fix via conditional classpath in bootstrap; add tests exercising macros.
- README drift vs reality — Close the gap at release lock; use snapshot + todo-app gates as truth.

## 11) Documentation Updates

- README: Add a short “Write Haxe the Elixir Way” section linking to `docs/02-user-guide/haxe-for-phoenix.md` and patterns. Reiterate no `analyzer-optimize`.
- docs/03-compiler-development: Add/update context-preservation examples and hygiene pass rationale, tying to symbol table overlay.
- Snapshot testing policy: ensure all new scenarios have intended outputs that are idiomatic.

## 12) References

- COMPILER_1.0_ROADMAP.md — Current blockers and priorities
- ROADMAP_TO_1.0.md — Milestones M0–M3
- docs/05-architecture/AST_PIPELINE_MIGRATION.md — AST pipeline overview
- docs/03-compiler-development/* — Context preservation, variable mapping, enum extraction
- examples/todo-app — Integration baseline


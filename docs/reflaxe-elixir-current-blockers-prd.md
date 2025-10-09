# Reflaxe.Elixir – Current State & Blockers PRD (October 2025)

## 1. Project Summary

Reflaxe.Elixir is an AST-driven Haxe → Elixir compiler that enables teams to write business logic once in Haxe and emit idiomatic, production-grade Elixir code. The compiler is a pillar of the broader “write once, deploy anywhere” vision: the same Haxe sources should compile to clean Elixir for BEAM backends and (via _genes_) modern ES6 for Phoenix frontends. The target experience is that an experienced Elixir developer can read the generated code and see hand-written, Phoenix-idiomatic modules with zero scaffolding smells.

### Architecture Highlights
- **Pure AST pipeline**: `ElixirASTBuilder` → `ElixirASTTransformer` → `ElixirASTPrinter`; no legacy string emitters.
- **Target-conditional bootstrap**: `CompilerInit.Start()` only mounts `std/_std` overrides for the Elixir target, keeping macro/other targets clean.
- **Switch handling**: `SwitchBuilder` reconstructs idiomatic `case` clauses from Haxe enums, recovers binder names, and synthesizes guards.
- **Preprocessors**: `PreserveSwitchReturnsImpl` retains switch-return structure before the typer erases it; `TypedExprPreprocessor` strips infrastructure variables (`g`, `_g1`, …) ahead of AST conversion.
- **Transformation passes**: >70 passes in `ElixirASTTransformer`; responsible for binder hygiene, idiomatic Phoenix/Ecto rewrites, LiveView patterns, infrastructure validation.
- **Stdlib strategy**: heavy use of `__elixir__()` to surface native BEAM functions without sacrificing Haxe typing.
- **Todo-app sample**: canonical Phoenix LiveView app entirely in Haxe used as integration test and smoke target.

### 1.1 Mission Objectives
1. Produce **idiomatic Elixir** indistinguishable from human Phoenix code.
2. Guarantee **compile-time safety** by mirroring Haxe’s static guarantees in emitted Elixir.
3. Act as an **LLM productivity multiplier**: deterministic code shapes so assistants do not hallucinate bespoke APIs.
4. Support **framework integration**: Phoenix, Ecto, OTP behaviours, LiveView hooks, PubSub, Presence.
5. Maintain **framework agnosticism**: compiler must not assume Phoenix-only semantics; it should support pure OTP/Nerves apps.
6. Deliver **hand-written quality** outputs so downstream Elixir tooling (Dialyzer, mix format, etc.) works seamlessly.

## 2. Current Status Snapshot

| Area | State | Notes |
| --- | --- | --- |
| Haxe → Elixir compilation | **Partially working** | AST pipeline stable; many snapshots passing; significant binder/warning regressions remain. |
| Snapshot suite | **Improving** | New Phoenix PubSub option-binder snapshot added; overall suite still <90% pass (large backlog of outdated intended outputs). |
| Todo-app Haxe build | ✅ Successful | `npx haxe build-server.hxml` completes; Router macro validates LiveView routes. |
| Todo-app Mix compile | ⚠️ Errors & warnings | Emits numerous warnings (`this1`, unused variables/imports) and hard error (undefined `level` in `TodoPubSub.parse_message_impl/1`). |
| Runtime smoke | ❌ Blocked | Mix compile failure prevents running `mix phx.server`; runtime behaviour unverified. |
| Genes JS output | Untouched in this cycle | Not assessed; assumed functional but unverified post-latest changes. |

## 3. Key Challenges Blocking 1.0

### 3.1 Option Some/Ok Binder Enforcement
- **Symptom**: For switch clauses returning `Option`/`Result`, the binder in `{:some|:ok, binder}` often fails to rename to contextually-correct identifiers (e.g., should be `level`).
- **Impact**: Generated code references variables (e.g., `level`) that the pattern never defined, leading to Mix compile errors (`undefined variable "level"`).
- **Root Cause**: Conflicting transformation heuristics in `SwitchBuilder` and multiple passes in `ElixirASTTransformer`. Heuristics that rename based on usage run before late enforcement, and some AST shapes (clauses produced inside `cond` or after guard splitting) skip the renamer. Clause-local alias injection is only applied in some builders.
- **Status**: Terminal renamers (`AbsoluteLevelBinderEnforcement`, `OptionLevelAliasInjection`) were added, but they are not yet hitting the problematic clause—likely due to traversal gaps or earlier passes clobbering pattern metadata.
- **Requirement**: Single-purpose, deterministic pass executed last that (a) detects `*_level` targets, (b) renames/aliases binder to `level`, and (c) prevents upstream heuristics from undoing it. Needs targeted debug instrumentation around `SwitchBuilder` and transformer recursion for `ECase` nodes inside `cond` or nested blocks.

### 3.2 Todo-app Mix Warnings Hygiene
- **Warnings observed** (all must be eliminated for 1.0):
  - Repeated unused temp variable `this1` (multiple modules).
  - Unused import (`Ecto.Changeset`) and unused helper functions (`JsonPrinter.write_*`).
  - Unused variables in pattern clauses (`priority`, `tag`, `payload`, `e`).
  - Range warning `0..-1` (needs explicit step `0..-1//-1`).
  - Variable `label` shadowing in `Log.trace`.
  - Module redefinition warning (`StringTools`).
- **Impact**: Mix compile warnings erode developer trust; some reveal incomplete analyzer cleanup (e.g., `this1` should be removed by cleanup passes).
- **Status**: No active cleanup pass handles these warnings end-to-end. Need to revisit `thisAndChainCleanupPass`, pattern unused renaming, and conditional compilation of unused stdlib helpers.

### 3.3 Snapshot Debt & Idiom Drift
- **Context**: Snapshot suite spans core language, Phoenix integration, Ecto, infrastructure hygiene. Many intended outputs predate latest pipeline changes.
- **Problem**: Without up-to-date intended outputs, regressions sneak in; parity with hand-written idioms is unclear.
- **Need**: Coordinated sweep to regenerate intended outputs for “idiom-only” improvements while fixing real regressions before bumping tolerance thresholds.

### 3.4 Transformation Pass Complexity & Ordering
- **Issue**: `ElixirASTTransformer` has >70 passes; interplay is fragile. Several passes (e.g., `patternVarRenameByUsage`, `optionBinderConsistency`, `ForceOptionLevelBinderWhenBodyUsesLevel`, newly added absolute enforcement) touch the same clause.
- **Action Item**: Document pass ordering, annotate invariants, add debug macros to inspect per-pass deltas, and isolate Option binder logic in a deterministic pipeline.

### 3.5 Infrastructure Variable Residue
- **Observation**: Todo-app warnings mention `this1` (remnant of infrastructure variable preservation) in multiple modules. Ideally `TypedExprPreprocessor` + `removeSwitchResultWrapper` + `thisAndChainCleanupPass` would eliminate them.
- **Risk**: Infrastructure temporaries in final code undermine the “hand-written” guarantee.
- **Need**: Confirm `InfraVarValidation` enforces failure when residues remain and extend cleanup passes to cover them.

### 3.6 Documentation & LLM Readiness
- Extensive instructions exist (`AGENTS.md`, multiple docs), but there is no concise state-of-the-union for external collaborators. This PRD fills that gap; future documentation should keep it current.

## 4. Todo-app Compilation Status (Detailed)

### 4.1 Haxe Compilation
```
cd examples/todo-app
npx haxe build-server.hxml
```
- ✅ Success.
- Router macro logs confirm nine route functions validated and generated.
- No Haxe-side errors thrown; relies on AST pipeline.

### 4.2 Elixir Compilation
```
mix compile --force
```
- ⚠️ Warnings (must be eliminated):
  - `this1` unused across contexts and todo modules.
  - `priority`, `tag` unused in `bulk_action_to_string/1` pattern clauses.
  - `payload`, `e` unused in `Phoenix.SafePubSub` helpers.
  - Unused import `Ecto.Changeset`, unused functions `JsonPrinter.write_*`, `quote_string/2`.
  - Range warning `0..-1`.
  - Module redefinition warning `StringTools`.
- ❌ Error (blocks runtime):
  - `undefined variable "level"` in `examples/todo-app/lib/server/pubsub/todo_pub_sub.ex:64`, caused by Option Some binder misalignment.

### 4.3 Runtime
- Not attempted; Mix compile error prevents launching `mix phx.server`. Once Mix compile is clean, we must run LiveView flows and watch logs.

## 5. Additional Observations
- **Transformation debugging**: Existing debug defines (`debug_option_some_binder`) emit broad traces but are not filtered to todo-app. Need targeted logging keyed on module/pos.
- **Stdlib duplication**: `StringTools` redefinition suggests generated module overlaps with an existing beam; should namespace or avoid emission when the standard library already provides it.
- **Genes**: Not assessed this sprint; ensure Option fixes do not regress JS output when shared modules compile to ES6.
- **Docs**: Rich but scattered; this PRD should be updated whenever new blockers emerge.

## 6. Recommended Next Steps
1. **Instrument binder pipeline**: Add granular logs around `SwitchBuilder` and `ElixirASTTransformer` for `TodoPubSub.parse_message_impl`, verifying binder rename decisions.
2. **Finalize terminal binder fix**: Ensure the absolute enforcement pass executes after all other renames and handles `ECase` nodes embedded in `cond`/`if` transformations. Guarantee clause-local alias injection for body references to `level`.
3. **Warnings cleanup**:
   - Expand cleanup passes to drop `this1` assignments and underscore unused tuple binders.
   - Remove or conditionally compile unused helpers (`JsonPrinter` functions) and imports.
   - Adjust range generation logic to emit explicit step syntax (`0..-1//-1`).
4. **Snapshot sweep**: Regenerate intended outputs for tests touched by binder fixes; aim for ≥90% pass rate.
5. **Document transformer ordering**: Produce a concise reference for pass sequencing and invariants to reduce regression risk.
6. **Runtime validation**: Once Mix compile is clean, run `mix phx.server`, exercise LiveView routes, and inspect logs for runtime errors.
7. **LLM collaboration**: Use the GPT5Pro prompt below to derive a detailed remediation PRD.

## 7. Prompt for GPT5Pro (to generate solution PRDs)
```
You are GPT5Pro collaborating on Reflaxe.Elixir, a Haxe→Elixir compiler that must reach 1.0 quality. Read the attached “Reflaxe.Elixir – Current State & Blockers PRD (October 2025)” and produce a comprehensive remediation plan.

Deliverables:
1. One or more detailed PRDs that describe concrete fixes to remove the Mix compile error (Option binder `level` mismatch) and eliminate all remaining warnings in the todo-app build. Each PRD should include:
   - Problem statement
   - Current behaviour vs. desired behaviour
   - Root cause analysis (referencing `SwitchBuilder`, `ElixirASTTransformer`, and relevant passes)
   - Step-by-step implementation plan (with code hotspots, pass ordering changes, debug instrumentation, and snapshot additions)
   - Testing strategy (snapshot coverage, todo-app smoke, Mix compile gating)
   - Acceptance criteria (Haxe compile, Mix compile warning-free, runtime smoke clean)
2. A secondary plan to raise snapshot coverage ≥90%, specifying which directories require intended-output refresh vs. code fixes.
3. Risk assessment for modifying late-stage transformer passes, including mitigation (e.g., targeted debug defines, incremental verification).

Outputs must be explicit enough that another senior engineer can execute them without additional context.
```

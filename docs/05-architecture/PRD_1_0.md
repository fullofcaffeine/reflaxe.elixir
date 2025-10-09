# Reflaxe.Elixir 1.0 PRD

## Vision

Deterministic, idiomatic Elixir generation from Haxe with a pure AST pipeline, zero app-specific coupling, and first-class framework integration. Generated code must pass human review as natural Elixir, be warning-free, and support real-world Phoenix/Ecto/OTP apps. Tests (snapshots + todo-app E2E) drive development.

## Goals (1.0)

- Idiomatic AST pipeline (Builder → Transformer → Printer) complete and stable
- Enum patterns (including Option.Some/None) normalized generically
- Generic binder alignment and aliasing (no app-specific names)
- Zero compile warnings in generated code (todo-app, snapshots)
- Target-conditional classpath (no macro-target leakage)
- Strict typing discipline (no unjustified Dynamic)
- Enable symbol IR (behind flag) and finalize gate-on path
- Snapshot suites comprehensive; todo-app E2E passes without runtime errors
- CI pipeline runs targeted suites and full sweep as needed

## Non-Goals

- Performance tuning beyond idiomatic correctness of 1.0
- New language features not required for Elixir idioms

## Requirements

- No analyzer-optimize; favor DCE full; follow Snapshot Testing Policy
- Phoenix/Ecto/OTP outputs must be idiomatic and warning-free
- No application-specific identifiers in compiler logic (see Anti-Coupling Directive)

## Architecture & Key Decisions

- Pure AST pipeline: all code generation goes through ElixirAST
- Transformations remain generic and data-driven; no name-specific branches
- Binder alignment: generic viability rule (body-usage ∧ ¬field-base ∧ ¬declared ∧ ¬param-collision) with single-candidate requirement; else alias
- Warning eradication: printer-level chain split + transformer cleanup; no app-special cases
- Target-conditional classpath: Elixir-specific std/overrides only present when compiling to Elixir
- Symbol IR (enable_symbol_ir): integrate after stability; gate and verify snapshots

## Milestones & Deliverables

1) Enum Patterns Consolidation & Binder Alignment
   - Complete Batch 3 final normalization
   - Generic binder rename/alias pass (no app-specific names)
   - Snapshot coverage (core/enum/options)

2) Warning-Free Generation
   - Printer chain-split for nested assignments
   - Block-level cleanup of dead assigns
   - Hygiene passes (usage/underscore) stable; no stack overflow
   - Todo-app compiles with warnings-as-errors

3) Target-Conditional Classpath
   - Bootstrap macro gates Elixir std only for elixir target
   - Macro contexts see regular std only

4) Strict Typing Audit
   - Remove/justify Dynamic; add hxdoc annotations where unavoidable
   - Strengthen typedefs/enums

5) Enable Symbol IR
   - Integrate ApplyNames with context; validate unchanged behavior under flag
   - Gate on & snapshot verification

6) Test Strategy & CI
   - Snapshot suites (core, stdlib, regression, phoenix)
   - Todo-app E2E (dev & CI)
   - Targeted suites run for fast iteration; full sweep pre-release

## Risks & Mitigations

- Over-renaming/shadowing: strictly follow single-candidate rule; prefer alias otherwise
- App-specific drift: enforce Anti-Coupling Directive; review PRs for name-special cases
- Hygiene recursion: structural sharing in transformers; unit tests for pathological shapes

## Acceptance Criteria

- All snapshot suites pass with idiomatic intended outputs
- Todo-app compiles for Haxe→Elixir without warnings and runs without runtime errors
- No app-specific names in compiler logic; directive present in docs and enforced in review


# Snapshot Suite Triage — 1.0 Gate (2025-10-24)

This report categorizes the current snapshot test failures to drive 1.0 fixes without app coupling. It reflects a bounded run executed on 2025-10-24 from the repo root.

## Run Facts
- Command (positive): `make -C test summary`
- Command (negative): `make -C test summary-negative-safe`
- Positive total discovered: 276
- Negative total discovered: 5
- Positive failures captured: 208
  - Invalid Elixir syntax: 9
  - Output mismatch (syntax OK): 195
- Negative suite: 5/5 correctly failed (PASS)
- Integration sentinel: launched async at the end of this triage (RUN_ID recorded below)

Reproduce locally
- Positive: `make -C test summary | tee /tmp/reflaxe-triage/summary.pos.txt`
- Negative (sequential): `make -C test summary-negative-safe | tee /tmp/reflaxe-triage/summary.neg.txt`
- Logs used for this report stored under `/tmp/reflaxe-triage/` on the runner.

## Category Breakdown (from captured failures)

Counts are derived by path/keyword heuristics to guide fix streams. The “Other” bucket will be further split after first two fix passes land.

- Switch/Pattern: 28
- Naming/Hygiene: 20
- HEEx/HXX/Phoenix: 15
- Ecto DSL: 11
- Stdlib: Reflect: 4
- Stdlib: Date: 0 in this bounded capture (note: earlier long run showed Date cases failing; re-check after next full pass)
- Other: 130

## Invalid Syntax Cases (high priority)
Focus first on syntax-invalid outputs since they block printer correctness:
- core/array_comprehension_nested — Invalid Elixir syntax
- core/domain_abstractions — Invalid Elixir syntax
- core/dynamic — Invalid Elixir syntax
- core/enhanced_pattern_matching — Invalid Elixir syntax
- core/enhanced_patterns — Invalid Elixir syntax
- exunit/ExunitComprehensive — Invalid Elixir syntax
- loops/nested_variable_declaration — Invalid Elixir syntax
- regression/infrastructure_variables_complete — Invalid Elixir syntax
- regression/troubleshooting_patterns — Invalid Elixir syntax

## Fix Streams (mapped to shrimp tasks)

1) Fix: Naming/Hygiene Snapshot Group
- WHAT: Variable hygiene, shadowing, underscore normalization, unused param variable style, digit-suffix normalization (no numeric hacks), reserved keyword params.
- WHY: Ensure readable, idiomatic Elixir and remove post-hoc renames that drift from Haxe intent.
- HOW (AST):
  - Builder: ensure binding-introduction is explicit and carries origin metadata.
  - Transformer: enforce non-numeric, descriptive temporary names; consistent `_unused` for dead params; prevent underscore-after-use.
  - Printer: preserve renamed identifiers deterministically; never append digits to disambiguate.
- ACCEPTANCE: All tests under regression/*hygiene* and *variable* pass; zero new warnings; E2E green via sentinel.

2) Fix: Switch/Pattern Snapshot Group
- WHAT: Tighten switch/guard transformation semantics, success-case alignment, temp result handling, and side-effects ordering.
- HOW (AST):
  - Normalize guard chains; explicit success binding; single temp for multi-branch expressions with clear scope; preserve evaluation order.
- ACCEPTANCE: All `regression/*switch*`, `*pattern*`, `success_case_alignment`, `temp_result_switch*` pass; E2E green.

3) Fix: Stdlib Date/Reflect Snapshot Group
- WHAT: Update canonical externs in `std/_std` to align Date and Reflect shapes with idiomatic Elixir and builder expectations.
- ACCEPTANCE: `stdlib/date/*` and `stdlib/*Reflect*` pass; no changes to generated runtime `.ex` files except via std extern sources.

4) Follow-ups
- HEEx/HXX/Phoenix: Validate assigns/JS externs shape; confirm printer for attribute/value quoting and block/if forms.
- Ecto DSL Pass 2: `order_by` dynamic, `limit/offset`, `select_merge`, simple `subquery/2`.

## Integration Sentinel (non‑blocking)
- Launched: `npm run qa:sentinel` (async, verbose)
- RUN_ID: recorded in `/tmp/qa-sentinel.<RUN_ID>.log`
- Quick check: readiness progressing; Phoenix booted in background; full result to be confirmed by the sentinel’s final status line in the run log.

## Next Steps
- Land Naming/Hygiene fixes first (widest impact, lowest risk), then Switch/Pattern.
- Re-run `make -C test summary -j1` to obtain a complete pass/fail matrix and refresh the category counts (expect Stdlib:Date to reappear if still failing).
- Keep sentinel runs bounded and attach logs per task. Ensure no changes to generated runtime `.ex` without upstream source changes.

---
Document owner: 1.0 Verification Gate triage
Last updated: 2025-10-24

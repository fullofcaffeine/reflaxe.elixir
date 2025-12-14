# PRD: Temp Alias Follow-Up – Literal Restoration & Loop Idiomaticity

## Context
The temp-alias guard rails are now in place, and we reintroduced literal map folding in
`ElixirASTBuilder`. However, several snapshot suites still regress because:

1. **Loop idioms:** `Enum.reduce_while` continues to surface where we previously emitted
   `Enum.each/Enum.map`, due to the new alias filter short-circuiting comprehension heuristics.
2. **Assignment cleanup:** `TempAliasCleanup` was disabled during debugging; we must restore it
   with the refined skip logic to prevent stale temp assignments in non-literal contexts.
3. **Debug scaffolding:** Temporary `#if debug_*` traces remain sprinkled across the builder and
   transformer and should be removed before a clean snapshot refresh.

This PRD tracks the remaining compiler work required before we regenerate snapshots and continue
with todo-app validation.

## Goals
- Restore idiomatic loop emission (e.g. `%Map.keys|Enum.each`) without re-introducing enum-pattern
  bugs or temp alias churn.
- Re-enable `TempAliasCleanup` with the updated guard so only `temp→temp/self` assignments are
  dropped.
- Remove the debug instrumentation introduced during the investigation.
- Produce clean, deterministic snapshot outputs for `core/maps`, `core/array_map_idiomatic`, and
  dependent suites, ready for review.

## Non-Goals
- Broader loopbuilder feature work beyond what is necessary to get back the previous idiomatic
  behaviour.
- Updating snapshot fixtures today; that happens only after the compiler fixes land and tests pass.
- Todo-app rebuilds – those are tracked in the overarching temp-alias plan once snapshots stabilise.

## Deliverables
1. Updated compiler code with:
   - `TempAliasCleanup` re-enabled and the stricter skip condition in place.
   - Builder/transformer logic that folds `Map.keys` iterations back to `Enum.each`
     (or existing heuristics) now that map literals are rebuilt earlier.
   - Debug traces removed.
2. Local snapshot runs (`make -C test -j1 test-core__maps` and
   `test-core__array_map_idiomatic`) showing clean diffs.
3. Follow-up PR checklist noting any remaining suites that still mismatch (if any).

## Plan
1. **Temp Alias Pass Restoration**
   - Reintroduce `tempAliasCleanupPass` in the pass list.
   - Keep the refined skip logic: only drop assignments when LHS is a temp and RHS is the same temp
     (or another `g*` alias), or when `valueName == name`.
   - Confirm no regressions by grepping for stray `g = value` in generated snapshots.
   - Add a regression spec covering `g = g` within nested `let`/pattern destructuring to ensure the
     pass stays opt-in for real assignments.
   - Document the guard in `TempAliasCleanup` hxdoc so future passes understand the new contract.

2. **Loop Idiom Fixes**
   - Audit `ElixirASTBuilder` loop sections after the literal collapse to ensure the heuristics can
     see the final `%{}` literal rather than the builder block.
   - If the existing detection still trips, patch the loop emission (likely in
     `LoopBuilder`/`EverythingIsExprSanitizer` integration) to recognise the restored AST shape.
   - Validate with `core/maps` and `core/array_map_idiomatic`, ensuring we emit the previous
     `Enum.each`/`Enum.map` patterns.
   - Capture before/after samples in the PR description (old `Enum.reduce_while` vs new
     `Enum.each`) to make review easier.
   - Add a guardrail test for `%{}` comprehensions nested in other loops so we do not regress when
     introducing additional literal optimisations later.

3. **Cleanup + Tests**
   - Remove `debug_map_literal`, `debug_temp_alias`, and similar instrumentation.
   - Run targeted suites (`test-core__maps`, `test-core__array_map_idiomatic`, plus a smoke run of
     `test-core__MapIdiomatic`) to confirm stability.
   - Document any residual mismatches for the next session if they remain.
   - Record the validation matrix in `docs/08-roadmap/PRD_TEMP_ALIAS_SNAPSHOT_PLAN.md` once the
     compiler work is ready for snapshot regeneration.

## Milestones & Tracking
- **M1 – Pass reinstated:** `TempAliasCleanup` merged with unit coverage and no new temp churn in
  `test/snapshot/core/maps` diffs.
- **M2 – Loop idioms restored:** targeted suites show `Enum.each`/`Enum.map` forms, confirmed with
  reviewers via the captured before/after snippets.
- **M3 – Debug cleanup:** codebase free of `debug_*` guards; validation matrix updated and linked in
  this PRD.
- **M4 – Snapshot readiness:** once the above land, hand off to the snapshot plan to regenerate
  intended outputs.

## Metrics & Validation Signals
- `rg "g = g" -g"*.ex" _build` reports zero hits after synthetic fixtures run.
- `grep -R "Enum.reduce_while" test/intended/core` only appears where explicitly expected.
- `make -C test -j1 test-core__maps` and `test-core__array_map_idiomatic` exit 0 twice consecutively
  to guard against flaky literal folding.
- PR checklist includes links to before/after snippets and references this PRD section for reviewers.

## Risks & Mitigations
- **False-positive cleanup:** overzealous alias removal could drop meaningful assignments in macro
  expansions. Mitigation: broaden the regression suite with nested patterns and include manual code
  review of tricky cases before merging.
- **Loop heuristic drift:** literal folding may expose new edge cases (e.g., matching on maps with
  guards). Mitigation: keep the loop change isolated, add assertions during development, and plan a
  follow-up pass if broader refactors are required.
- **Timeline creep:** without explicit milestones the fix may stall. Mitigation: track progress in
  weekly syncs, update this PRD as each milestone completes, and escalate if blockers persist for
  more than two days.

## Stakeholders & Reviews
- **Primary implementer:** compiler working group member assigned to the temp-alias stream.
- **Reviewers:** maintainers familiar with `ElixirASTBuilder` and `TempAliasCleanup` (e.g.,
  @fullofcaffeine, @core-maintainer-alias).
- **Rust/Elixir cross-check:** loop heuristics should get a courtesy review from the runtime layer
  owners to ensure generated code remains idiomatic for OTP consumers.

## Acceptance Criteria
- `make -C test -j1 test-core__maps` shows either zero diffs or only expected literal improvements
  ready for snapshot update.
- Generated code no longer contains invalid constructs like `map.clear()` or `acc_key.has_next()`.
- No debug traces remain in the compiler.
- The PR ready for review contains code changes plus a note pointing to the upcoming snapshot
  refresh step.

## Owners & Dependencies
- **Primary owner:** the next coding session (can be picked up immediately).
- **Dependencies:** none external; all changes local to the compiler.

## Open Questions
- Do we want to add regression tests specifically for the map literal collapse? Consider adding a
  snapshot under `test/snapshot/core/map_literal_builder` once the pipeline is back to green.

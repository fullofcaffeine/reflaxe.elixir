# PRD: Snapshot Realignment & Todo App Verification Post Temp-Alias Cleanup

## Context
Recent compiler changes removed redundant temp-variable alias assignments (e.g. `g = data`). While targeted regressions now pass, the broader snapshot suite and the todo app still need to be validated and updated. Snapshot failures largely arise from intentional behaviour changes; we must capture the new idiomatic Elixir output and re-confirm e2e correctness.

Reference materials:
- `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference` for canonical Haxe/Reflaxe patterns.
- Existing PRDs under `docs/03-compiler-development/` for enum handling context.

## Goals
1. Align all snapshot tests with the new temp-alias behaviour while safeguarding legitimate non-temp assignments.
2. Validate the todo app end-to-end (Haxe build, Elixir compile, smoke/runtime checks) with the updated compiler.
3. Ensure architectural consistency by cross-checking against the reference repo before updating intended outputs.

## Non-Goals
- Introducing new compiler features unrelated to alias cleanup.
- Refactoring unrelated modules beyond what is required to stabilise snapshots and the todo app.

## Deliverables
- Updated intended outputs across affected snapshot suites (core, bootstrap, ecto, etc.), each representing clean, idiomatic Elixir without redundant aliases.
- Verified todo app compilation in both Haxe and Elixir, with follow-up issues documented if sandbox restrictions block runtime checks.
- Supplemental regression tests (where necessary) ensuring we still emit required assignments when aliases are meaningful.

## Plan
1. **Snapshot Audit & Update**
   - Run targeted suites (starting with `core`, `bootstrap`, `ecto`, `array_map_idiomatic`, etc.).
   - For each failure, compare generated output against the reference repo to confirm the cleanup is correct.
   - Regenerate intended outputs only after verifying behaviour; add regression tests for non-temp alias cases if gaps exist.

2. **Focused Regression Coverage**
   - Add or adjust snapshots ensuring scenarios needing real assignments remain intact.
   - Document any divergence from reference patterns and justify changes in commit messages.

3. **Todo App Verification**
   - Rebuild via `haxe build.hxml` (already green) and re-run after snapshot updates.
   - Compile with `mix compile`; if sandbox blocks TCP access, execute outside restricted environments and log outcomes.
   - Smoke-test (`mix test`, minimal Phoenix run) where feasible; record warnings/errors for follow-up.

4. **Final Validation**
   - Re-run `make -C test summary` to ensure clean snapshot suite.
   - Rerun Haxe & Mix builds for the todo app to confirm end-to-end stability.

## Milestones & Tracking
- **M1:** Core snapshot suite updated & passing (`core/*`, `constructor_patterns`, etc.).
- **M2:** Bootstrap suites updated & passing.
- **M3:** Ecto & higher-level suites updated & passing.
- **M4:** Todo app compiled via Haxe & Mix, smoke-tested (or sandbox blocked with documented workaround).
- **M5:** Full snapshot summary passes; plan archived in `docs/08-roadmap/`.

## Risks & Mitigations
- **Risk:** Accidentally remove necessary assignments. Mitigation: cross-check with reference repo, add focused regression snapshots.
- **Risk:** Sandbox prevents Mix runtime verification. Mitigation: run locally or request elevated permissions; document any outstanding verification steps.
- **Risk:** Snapshot churn hiding real regressions. Mitigation: incremental updates with dedicated commits per suite; review diffs carefully.

## Approval
- Requires review from compiler maintainers (Reflaxe.Elixir core team) before mass snapshot updates.

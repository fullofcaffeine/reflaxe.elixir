# Plans

This directory stores implementation plans that are larger than a single beads task.

## Source Of Truth

- **Beads tasks are the implementation source of truth.**
  - A beads task must be decision-complete on its own: an engineer should be able to implement it without opening a plan.
- **Plans are an index + historical reference.**
  - Plans exist to preserve the original reasoning, decisions, and cross-task coherence.
  - Plans may link to docs, but should not be required reading to implement any single task.

## Lifecycle (Active -> Archived)

- Active plans live in `plans/active/` while any related beads task is still `open`.
- When all related beads tasks are `closed`, move the plan to `plans/archived/`.
  - Add a short footer section to the archived plan:
    - `Archived at: <date>`
    - `Completed by: <commit SHA(s)>`
    - `Beads: <ids>`
- If a plan is superseded, archive it and add a note pointing at the new plan.

## Conventions

- Active plans: `plans/active/<topic>.md`
- Archived plans: `plans/archived/<topic>-<YYYY-MM-DD>.md` (or similar)
- Plans should list:
  - The beads task IDs they drive
  - A concise decision summary
  - Any cross-cutting invariants (policies/constraints)

## Beads Task Requirements (Decision Complete)

When a beads task has a `plan_ref`, it should still include (inline) at least:

- `FILES`: exact paths and key symbols to touch
- `ALGORITHM`: deterministic rewrite rules and lowering shapes
- `FAILURE MODES`: fail-fast behavior + diagnostics requirements
- `TESTS`: concrete fixtures/snapshots/tests to add or update (paths + names)
- `VERIFICATION`: bounded commands to run locally
- `ROLLOUT`: defaults vs opt-ins, backward compatibility notes, escape hatches

## Scope Changes (Agent Policy)

Beads tasks list the expected touch points under `FILES`, but they are not a hard limit.

- Allowed: touch additional files if required to meet the task acceptance criteria.
- Required: record the scope change:
  - Update the beads task description (`FILES` and/or add a `TOUCHED` section + rationale), or
  - Create a follow-up beads task if the scope is truly separate work.
- Stop and ask the human when:
  - The scope expansion changes public APIs significantly
  - The work would add/replace a major subsystem
  - The change affects multiple examples/apps with non-obvious tradeoffs


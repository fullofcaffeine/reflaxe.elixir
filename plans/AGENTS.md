# Agent Notes (plans/)

This directory is a planning artifact index.

Read: `plans/README.md`

Rules:
- Beads tasks are the implementation source of truth; plans are historical context.
- If a plan’s linked beads tasks are all `closed`, move the plan from `plans/active/` to `plans/archived/` and add a short footer:
  - Archived at (date)
  - Completed by (commit SHA(s))
  - Beads (ids)
- When implementation discoveries change the plan:
  - Update the affected beads task(s) first (decision-complete specs).
  - Then update the plan doc to reflect the new decisions.


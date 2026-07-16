# Crema Beads Resume Note

The Crema task snapshot is intentionally preserved on branch
`codex/haxe-elixir-crema-71` in this branch's `.beads/issues.jsonl`.

Relevant records are:

- `haxe.elixir.codex-9ae` — the open native Crema Invite Request LiveView and
  bounded React-island visual proof, including the implementation and preview
  checkpoints;
- `haxe.elixir.codex-cf4` — the completed project-local Vite plus stock
  `live_react` binding proof used by Crema;
- `haxe.elixir.codex-0e9` — the completed direct-inline HXX correction for that
  proof; and
- `haxe.elixir.codex-a2y` — the open QA-sentinel process-group reporting bug
  discovered while tearing down the Crema preview.

The local Beads database was previously shared across Git worktrees. Main was
cleaned after this snapshot, so the branch JSONL and any future main database
may diverge.

Before resuming Crema work:

1. Back up the active database and both branches' `.beads/issues.jsonl` files.
2. Compare this branch's records with the then-current main export by issue ID,
   comments, dependencies, status, and timestamps.
3. Consolidate newer non-Crema task changes from main and the Crema-only records
   from this branch into one reviewed import. Do not blindly export an existing
   shared database over either branch.
4. Import the reviewed JSONL with `bd`, verify the four records above, run the
   Beads dependency-cycle/lint checks, and commit the reconciled branch export
   before changing source code.

This note is a recovery boundary, not permission to reopen or promote the
Crema proof. `haxe.elixir.codex-9ae` still requires owner visual disposition,
and `haxe.elixir.codex-a2y` remains an independent tooling bug.

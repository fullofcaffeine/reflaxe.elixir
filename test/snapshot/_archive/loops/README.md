# Archived Snapshot Suite: `loops/`

This directory contains a legacy snapshot suite that was removed from the default test run.

Why it’s archived (not deleted)
- The suite predates the current curated snapshot categories (`core/`, `stdlib/`, `regression/`, `phoenix/`, etc.).
- Its generated outputs were frequently **invalid/uncompilable Elixir** and drifted from the current compiler’s idiomatic targets.
- Keeping it under `_archive/` preserves historical fixtures without making `make -C test summary` unreliable.

Where loop coverage lives now
- `test/snapshot/loop_desugaring/` — focused loop idiom rewrites
- `test/snapshot/regression/` — regressions for real bugs (including loop-related ones)

If you want to resurrect tests from here
- Copy the relevant fixture(s) into an active suite (usually `regression/` or `loop_desugaring/`).
- Ensure the fixture’s output is valid Elixir and matches current idiomatic targets.

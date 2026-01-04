# PRD: Public Release Onboarding + Scaffolding (Post‑1.0)

## Context

Reflaxe.Elixir reached `v1.0.x`, but “new user” onboarding still relies on manual setup (or brittle generator outputs). To prepare for a public release, we need repeatable, tested scaffolding for Phoenix projects and a clear path to *gradual adoption* inside existing Elixir/Phoenix apps.

This PRD intentionally focuses on **developer UX** and **public-repo readiness** rather than new compiler features.

## Goals

1. **Greenfield Phoenix scaffold**
   - A single command that creates a Phoenix project skeleton wired for Haxe→Elixir compilation (server) and optional JS generation (client).
   - Output must be aligned with current compiler flags and practices.

2. **Gradual adoption scaffold**
   - A command that modifies an existing Phoenix project to:
     - add `src_haxe/`
     - compile Haxe into an isolated namespace (e.g. `lib/<app>_hx`)
     - integrate with Mix compilers/watcher in `dev` only
   - No invented Phoenix APIs; follow Phoenix conventions exactly.

3. **Generator correctness**
   - Fix stale/default generator output so it matches current reality:
     - no `npx lix run haxe ...` usage
     - correct output flags (`-D elixir_output=...`)
     - correct `-lib reflaxe.elixir`
     - correct “what to run” and version printing

4. **Docs alignment**
   - Once scaffolds are correct, update docs to recommend them confidently (no “maybe outdated” caveats).
   - Keep “manual setup” as a fallback path.

5. **Public repo readiness**
   - Ensure CI + releases are configured for a public GitHub repo:
     - fast, cache-aware CI
     - clear release/tag workflow
     - badges and README instructions match reality

## Non‑Goals

- Adding new compiler capabilities (unless required to make the scaffold compile).
- Refactoring compiler internals beyond what’s necessary to make generator output truthful.
- Replacing Playwright with Haxe-authored E2E tests (nice-to-have; not required here).

## Known Issues / Inputs (from recent cleanup)

- `src/Run.hx` and `lib/mix/tasks/haxe.gen.project.ex` historically recommended toolchain commands that don’t work in fresh scopes (see “Tooling conventions” below).
- Example apps/scripts still have mixed expectations about “global `haxe`” vs “lix-managed `haxe`”.
- The todo-app contains multiple `build-server-pass*.hxml` files that confuse new users; needs consolidation or a clear explanation.

## Proposed Approach

### A) Make scaffolding “example-driven”

- Treat the working `examples/` as the source-of-truth templates.
- CI should compile-check the templates so they cannot drift.
- Scaffolding commands should be thin copy/parameterization layers over those templates.

### B) Tooling conventions

- Prefer:
  - `haxe ...` (when a proper Haxe install is present), or
  - `npx haxe ...` (lix-managed wrapper pinned via `.haxerc`).
- Do not recommend `npx lix run haxe ...` for new users: it requires additional (non-default) toolchain wiring and fails in fresh scopes.
- Elixir output must use `-D elixir_output=...` consistently.
- Keep Haxe “Phoenix helpers” in `std/phoenix/**` (no `__elixir__()` in app code).

### C) Deliver as Mix tasks (primary UX)

Suggested commands (names tbd):
- `mix haxe.new.phoenix MyApp` (greenfield)
- `mix haxe.add` (adopt into existing Phoenix project)

Alternative: keep the existing `mix haxe.gen.project` but fix its output and extend it with a `--type phoenix` / `--type add-to-existing`.

## Work Items

1. Fix generator output
   - Update `src/Run.hx` output strings and version plumbing.
   - Update `lib/mix/tasks/haxe.gen.project.ex` to emit:
     - correct `build.hxml` (`-lib reflaxe.elixir`, `-D elixir_output=...`, `-D reflaxe_runtime`, `--macro reflaxe.elixir.CompilerInit.Start()`)
     - correct scripts (no `npx lix run haxe ...`)
     - correct “next steps” instructions

2. Add Phoenix scaffolds
   - New project skeleton:
     - wired watcher + `compilers: [:haxe] ++ Mix.compilers()` in dev
     - uses a dedicated namespace for generated Elixir modules
   - Add-to-existing:
     - idempotent modifications (safe rerun)
     - minimal diffs, no overwriting user code

3. Consolidate / document multi-pass HXML in todo-app
   - Decide whether pass files are still required.
   - If not required: remove and simplify to `build-server.hxml`.
   - If required: document the exact reason and default to the simplest entrypoint.

4. CI + releases
   - CI jobs:
     - `npm ci`
     - `npm test`
     - `npm run test:examples`
     - todo-app runtime smoke via sentinel (CI may run sync mode but must use `--deadline`)
   - Add release workflow:
     - tag → GitHub release (notes, artifacts if any)
     - verify README badges and links

## Acceptance Criteria

- A newcomer can:
  - create a new Phoenix project scaffold and run it successfully, or
  - add Haxe to an existing Phoenix project and run it successfully,
  following the README/docs without needing to “guess” flags or fix generator output.
- No public-facing doc recommends `npx lix run haxe ...`.
- Generated `build.hxml` uses `-D elixir_output=...` and `-lib reflaxe.elixir`.
- CI verifies “templates/scaffolds compile” and fails on drift.

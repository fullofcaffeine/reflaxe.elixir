# Development Guidelines (AI Agent Operational Rules)

## Scope

- These standards govern ALL AI agent modifications in this repository.
- Apply to compiler code under `src/reflaxe/elixir/**`, Haxe std sources under `std/_std/**`, example app Haxe under `examples/todo-app/src_haxe/**`, docs under `docs/**`, tests under `test/**`, and build/qa scripts under `scripts/**`.
- Enforce these rules for every new task and PR; integrate the acceptance gates below into each task’s verificationCriteria.

## Code Standards

### Naming (Hard Rules)

- Do NOT use numeric‑suffixed local variable names (e.g., `pvar2`, `name2`, `args2`).
- Use clear, descriptive names; reuse the same names within each match/case scope; when distinct names improve clarity, choose different descriptive names (e.g., `paramsVar`, `socketVar`, `firstArg`).
- Never introduce app‑specific names or heuristics in compiler logic.

### Files and Documentation

- Keep each transformer/printer module under 2000 LOC.
- Add hxdoc to every new or modified transformer/printer with WHAT/WHY/HOW/EXAMPLES and links to snapshots.
- Prefer small helpers over ad‑hoc inline conditionals when logic repeats.

## Workflow Standards

### Runtime QA – Non‑Blocking Only

- Use the QA sentinel scripts exclusively; never run `mix phx.server` in the foreground.
- Quick run (bounded): `npm run qa:sentinel`
- Async run (recommended for E2E): `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --verbose --deadline 300`
- Log peek: `scripts/qa-logpeek.sh --run-id <RUN_ID> --last 200` or `--follow 60`
- Keep‑alive (manual browsing): `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --keep-alive -v`

### Test Layers

- Snapshots (compiler): `make -C test summary` and focused `make -C test single TEST=<path>`.
- ExUnit (Haxe‑authored): compile to idiomatic Elixir tests; keep fast and deterministic.
- Playwright (TS): keep smoke‑level, resilient selectors, under ~1 minute total; run against the sentinel‑managed server.

## Source‑of‑Truth and File Interaction

- Do NOT edit generated runtime `.ex` files (e.g., `reflect.ex`, `std.ex`, outputs under `test/snapshot/**/out/**`).
- Make behavior changes only in:
  - Compiler pipeline: `src/reflaxe/elixir/ast/**`
  - Haxe std sources: `std/_std/**` and `std/*.cross.hx` (only when documented canonical)
- When adding/modifying a transform:
  - Update `src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx` ordering as needed.
  - Add/refresh focused snapshots covering the change.
  - Document with hxdoc and reference snapshots.

## Architecture & Tooling Rules

- AST pipeline is the only path; do not add string‑concatenation codegen.
- NEVER enable `-D analyzer-optimize` for Elixir targets.
- JS client guardrails: keep client builds using libraries via `-lib`; do not add repo‑level `std/` or `src/` to client classpaths.

## Decision‑Making Standards

- Prefer a targeted transformer when the issue is shape/semantic; prefer printer changes only for formatting/serialization concerns.
- Make example‑app changes only when the issue is not a compiler bug and remains idiomatic Phoenix.
- Never add name‑based heuristics tied to the example domain (todos/presence/etc.).

## Prohibited Actions

- No band‑aids or temporary workarounds; fix root causes.
- No numeric‑suffix local variables (see Naming).
- No foreground Phoenix servers during validation.
- No edits to generated runtime `.ex` files.

## Acceptance Gates (Apply to Every New/Updated Task)

- Naming check (hard): No numeric‑suffixed locals in any new/modified code. Fail review if variables end with digits.
- QA sentinel: bounded run is green; when applicable, Playwright smoke passes serially.
- Docs: hxdoc present/updated with WHAT/WHY/HOW/EXAMPLES and file size < 2000 LOC.
- Source‑of‑truth: changes are restricted to `src/reflaxe/elixir/**` and/or `std/_std/**`; never runtime `.ex`.

## Suggested Checks (Non‑blocking)

- Quick grep for numeric suffix locals:
  - `rg -n "\b(var|final|static)?\s*[a-zA-Z_]+\d+\b" src/ std/ examples/todo-app/src_haxe`
  - Review only locals; do not target legitimate arity suffixes in function names like `handle_event/3` (these are function arities, not variable names).

## Examples

### Do

- `var paramsVar = secondArgVar(args);`
- `var socketVar = thirdArgVar(args);`

### Don’t

- `var pvar2 = secondArgVar(args);`
- `var name2 = ...; var args2 = ...;`


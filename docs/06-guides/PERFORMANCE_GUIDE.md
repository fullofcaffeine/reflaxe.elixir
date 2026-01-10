# Performance Guide (Compiler + Dev Workflow)

This guide focuses on **practical** performance work for Reflaxe.Elixir’s AST pipeline:
fast feedback in development, predictable output in CI, and a clear strategy for diagnosing slow builds.

> [!NOTE]
> This is an **advanced** guide. Command blocks are for local investigation and are not CI-smoked unless explicitly stated.

## Measure Before Optimizing

Start with Haxe’s built‑in timings:

```bash
haxe build.hxml --times
```

If you’re investigating macro‑time work specifically, enable macro timings:

```bash
haxe build.hxml -D macro-times --times
```

## Use the Right Compilation Profile

### Default (recommended for CI / release builds)

- Full pass set enabled
- Highest output quality and hygiene

### `fast_boot` (opt‑in, local iteration)

`fast_boot` is an **opt‑in** profile designed to speed up iteration on large modules by skipping
or simplifying selected expensive macro/transform work.

- Enable in Haxe: `-D fast_boot`
- Enable in Mix (this repo’s convention): `HAXE_FAST_BOOT=1 mix compile`

Details and tradeoffs are documented in:
- `docs/01-getting-started/development-workflow.md`
- `docs/06-guides/KNOWN_LIMITATIONS.md`

## Diagnose “Which Pass Did It?”

When output shape changes unexpectedly or compilation work spikes:

- `-D debug_pass_metrics` — prints which passes changed the AST
- `-D debug_ast_pipeline` / `-D debug_ast_transformer` — focused traces for pipeline stages

These are intended for contributor workflows; keep them off by default.

## Avoid Known Bad Flags

Do not use `-D analyzer-optimize` for Elixir output. It can destroy functional/idiomatic shapes
and makes downstream transforms harder. See `docs/01-getting-started/compiler-flags-guide.md`.

## Dev Ergonomics: Incremental Compilation

For Phoenix projects, prefer incremental compilation to avoid recompiling everything on each change:

- The Mix tasks integrate a background Haxe server when available.
- Phoenix watchers use `haxe ... --wait <port>` for client builds.

If you hit `EADDRINUSE` from `--wait`, prefer reusing/adjusting the wait port (see the todo‑app’s
`config/dev.exs`) rather than disabling watching entirely.

## Contributor Rule of Thumb: Keep Passes Linear

If you’re touching transformer passes:

- Prefer **single‑pass** analyzers (`VarUse`/symbol tables) over repeated tree scans.
- Avoid O(n²) “fix‑it” passes that re‑walk the full AST multiple times.
- Gate expensive cosmetic hygiene behind profiles (`fast_boot`, `disable_hygiene_final`) only when
  semantics remain correct.

If you find a pass that must exist but is too expensive, the fix is algorithmic (data structures,
single‑pass analysis), not arbitrary limits.

## CI Budgets (Determinism + Time Bounds)

To guard against “it got slow” / “output order changed” regressions without flakiness, CI runs a
budget check on the todo‑app’s server + client builds:

```bash
npm run ci:budgets
```

This script:
- Builds the todo‑app server and client twice and diffs the outputs (determinism).
- Enforces generous per‑build timeouts via `scripts/with-timeout.sh` (no tight wall‑time asserts).

You can override the timeouts locally:
- `SERVER_TIMEOUT_SECS=240 CLIENT_TIMEOUT_SECS=180 npm run ci:budgets`

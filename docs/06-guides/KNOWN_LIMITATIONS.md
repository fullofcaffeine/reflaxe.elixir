# Known Limitations

This page documents the remaining sharp edges and experimental surfaces that may surprise early adopters.
Reflaxe.Elixir is production‑ready for the **documented subset**, but some features remain opt‑in/experimental.

If you hit something not covered here, please open an issue and include your **Haxe/Elixir/OTP/Phoenix versions** and a small repro.

## Stability expectations

- **API surface (std/phoenix + std/ecto)**: intended to be stable within `v1.0.x`, but still subject to changes where Phoenix/Elixir idioms require it.
- **Compiler output**: intended to be idiomatic and readable, but edge‑case semantics may change as the transformer passes mature.
- **Examples**: treated as “living docs”; they may evolve as patterns improve.

## Escape hatches (and where they belong)

Reflaxe.Elixir supports escape hatches when you need to cross an untyped boundary:

- Prefer **typed externs** in `std/elixir`, `std/phoenix`, `std/ecto` for anything reusable.
- In application code, prefer `elixir.types.Term` as the boundary type, then decode into typed structures.
- Use `__elixir__()` / `Syntax.code()` only as a last resort.

Important policy:

- **Avoid `__elixir__()` in application code**. If something is Phoenix‑specific but not app‑specific, promote it into the Phoenix std/framework layer so every app benefits.

See: `docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md` and `docs/02-user-guide/ESCAPE_HATCHES.md`.

## Typing boundaries (avoid `Dynamic`/`Any`/`untyped`)

Haxe can model BEAM values precisely, but not every external shape is known at compile time.

Preferred patterns:

- Use `elixir.types.Term` for untyped inputs (params/session/messages) and decode at the boundary.
- Keep assigns typed via `typedef Assigns = { ... }` and `Socket<Assigns>`.
- For JS interop, prefer explicit externs; use `reflaxe.js.Unknown` only at the boundary and narrow immediately.

In general: if you feel you “need `Dynamic`”, that’s a signal a missing extern/abstraction should be added to `std/` (or a small app‑local wrapper) instead.

## `fast_boot` (opt‑in development profile)

`fast_boot` is an **opt‑in** compilation profile intended for faster iteration while editing Haxe code in large Phoenix projects.

What it does:

- Enables `-D fast_boot`, which **disables or simplifies** some expensive macro/transform work.

What it does *not* guarantee:

- Fully idiomatic final output across all edge cases.

How to use it:

```bash
HAXE_FAST_BOOT=1 mix compile
```

Recommendation:

- Use `fast_boot` for **local dev iteration**, but do full compiles in CI/production builds.

## Tooling / watcher port conflicts

Phoenix watchers (`mix phx.server`) often run the Haxe client compiler in `--wait <port>` mode. If something else is already bound to that port you may see `EADDRINUSE`.

Fix options:

- Stop the process using the port and restart.
- Change the watcher `--wait` port to a free port (example apps use `HAXE_CLIENT_WAIT_PORT` and will probe for a nearby free port automatically).
- Disable Haxe server usage for a single build with `HAXE_NO_SERVER=1` (see `docs/06-guides/PRODUCTION_DEPLOYMENT.md`).

See also: `docs/06-guides/TROUBLESHOOTING.md`.

## Coverage notes

For what is supported vs experimental, see:

- `docs/04-api-reference/FEATURES.md`
- `docs/06-guides/SUPPORT_MATRIX.md`

For examples of intentionally rejected/invalid DSL usages (stable compile-time errors), see:

- `test/snapshot/negative/**`

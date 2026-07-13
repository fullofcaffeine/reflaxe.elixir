# Known Limitations

This page documents the remaining sharp edges and experimental surfaces that may surprise early adopters.
Reflaxe.Elixir is currently on the pre-1.0 (`v0.x`) release line. Some features remain
opt-in/experimental. See [Versioning & Stability](VERSIONING_AND_STABILITY.md) for the canonical
current version, release line, and compatibility policy.

If you hit something not covered here, please open an issue and include your **Haxe/Elixir/OTP/Phoenix versions** and a small repro.

## Stability expectations

- **API surface (`std/phoenix` + `std/ecto`)**: documented surfaces use the stable compatibility
  tier. While the project is pre-1.0, incompatible changes require an explicitly documented minor
  release; stable graduation has not yet been approved.
- **Compiler output**: intended to be idiomatic and readable, but edge‑case semantics may change as the transformer passes mature.
- **Examples**: treated as “living docs”; they may evolve as patterns improve.

## Known P1 correctness blockers

These defects are tracked as blockers for stable graduation, even though their shapes are not common
in ordinary Phoenix-facing code:

- `haxe.elixir.codex-3qh.23`: accumulator loops lowered through `Enum.reduce` can leave internal
  `break` or `continue` throws uncaught.
- `haxe.elixir.codex-3qh.24`: nested array comprehensions over dynamic iterables can lose the inner
  result tail.

Do not classify an application that depends on either shape as inside the production-capable subset
until the corresponding runtime regression suite and compiler fix have landed. See
[Production Readiness](PRODUCTION_READINESS.md) for the full 1.0 gate.

## Incremental build invalidation

The current Mix compiler does not yet fingerprint every effective Haxe input. Changes to nested HXML
content, defines, library/compiler identity, or an additional classpath such as `src_shared` may not
always force regeneration through a normal incremental `mix compile`.

Until `haxe.elixir.codex-0yn.1` closes:

- use clean, full Haxe generation in CI and release builds;
- review generated diffs after build configuration or dependency changes;
- do not use an incremental no-op as the only proof that generated Elixir is current.

## Generated file ownership

An isolated generated output root is the safest pre-1.0 adoption shape. In-place output beside
hand-written Phoenix modules does not yet have one fail-closed ownership protocol shared by compiler
writes, formatting, stale deletion, `mix clean`, upgrades, and rollback.

Until `haxe.elixir.codex-0yn.2` closes:

- keep generated modules in a dedicated directory or namespace where practical;
- review target-path collisions before generation;
- avoid treating a broad clean operation as proof that only generated files will be removed.

## OTP support boundary

The project exposes typed GenServer, Supervisor, Registry, process, and child-spec surfaces, but the
1.0 lifecycle/failure contract is not yet frozen. Do not infer comprehensive parity for crash reasons,
restart policy, supervision, mailbox behavior, or every OTP callback from successful compilation.
`haxe.elixir.codex-0yn.3` will either add runtime evidence for a bounded subset or narrow the stable
claim.

## Licensing decision

The repository is GPL-3.0, and generated applications may include support/runtime code originating
here. The implications depend on how software is built and distributed. Review
[Licensing & Distribution](LICENSING_AND_DISTRIBUTION.md) and obtain qualified advice; the 1.0 product
policy is still tracked by `haxe.elixir.codex-0yn.4`.

## Escape hatches (and where they belong)

Reflaxe.Elixir supports escape hatches when you need to cross an untyped boundary:

- Prefer **typed externs** in `std/elixir`, `std/phoenix`, `std/ecto` for anything reusable.
- In application code, prefer `elixir.types.Term` as the boundary type, then decode into typed structures.
- Use `__elixir__()` / `Syntax.code()` only as a last resort.

Important policy:

- **Avoid `__elixir__()` in application code**. If something is Phoenix‑specific but not app‑specific, promote it into the Phoenix std/framework layer so every app benefits.

See [Elixir Injection](../04-api-reference/ELIXIR_INJECTION_GUIDE.md) and
[Escape Hatches](../02-user-guide/ESCAPE_HATCHES.md).

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
- Keeps semantic correctness passes active. Fast builds may differ in cosmetic output hygiene, but
  must preserve the same Haxe program behavior as full builds.

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

- [Features](../04-api-reference/FEATURES.md)
- [Support Matrix](SUPPORT_MATRIX.md)

For examples of intentionally rejected/invalid DSL usages (stable compile-time errors), see:

- [`test/snapshot/negative/**`](../../test/snapshot/negative/)

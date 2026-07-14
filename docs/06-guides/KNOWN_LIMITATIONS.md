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

## Recently closed correctness defects

The reducer/comprehension defects found during the 1.0 review are closed:

- reducer-lowered accumulators preserve state across `break` and `continue` (`3qh.23`);
- nested dynamic comprehensions preserve their inner results (`3qh.24`);
- nested reducer callbacks retain their own lexical accumulator state (`3qh.25`).

The Haxe-authored runtime suites under `test/runtime/loop_control_accumulators` and
`test/runtime/nested_dynamic_comprehensions` exercise the source-language operations directly. This
evidence closes those known bugs; it does not imply that every Haxe program is supported. The stable
surface is still being enumerated under `haxe.elixir.codex-0yn.5`. See
[Production Readiness](PRODUCTION_READINESS.md) for the full 1.0 gate.

## Open callback-binder correctness defect

A callback lambda written directly inside a `Result` switch branch can bind the branch value instead
of the lambda's own parameter. For example, a callback such as `(value:Int) -> value + 1` inside
`case Ok(agent)` can incorrectly use `agent` where it should use `value`. This is a compiler bug, not
Agent behavior, and is tracked as `haxe.elixir.codex-3qh.26`.

That source shape is not part of the proposed stable surface. It must be fixed or remain explicitly
excluded when the full 1.0 support list is frozen.

## Macro inputs outside the build graph

Mix freshness now fingerprints the effective discoverable build: recursive HXML and defines, all
direct classpaths such as `src_shared`, resources, resolved libraries and package configuration, the
Haxe toolchain/standard library, relevant environment, and output-affecting Mix options. Fingerprints
use file content rather than timestamps.

Haxe macros can still read arbitrary non-Haxe files that are not declared as HXML resources. Mix
cannot infer those reads, even when a file lives below a classpath or resolved library. Declare them
explicitly:

```elixir
haxe: [
  # ...
  extra_inputs: ["config/haxe/**/*.json"]
]
```

Files, directories, and globs are accepted. Keep clean full generation in release validation as a
defense-in-depth check, not as a substitute for declaring macro inputs.

## Generated file ownership

Compiler writes, optional formatting, stale deletion, interrupted-build recovery, and `mix clean`
now share the version 2 `_GeneratedFiles.json` ownership protocol. In-place output rejects an
existing unowned target before publication, and clean deletes only validated manifest-owned paths.
An isolated generated root is still useful because it makes review and source-of-truth boundaries
more obvious; it is no longer required to compensate for marker-based cleanup.

The intentional sharp edge is fail-closed behavior: hand-editing a generated file changes its
recorded digest, deleting/corrupting the manifest removes overwrite authority, and a malformed
reserved transaction path blocks recovery. Resolve the ownership/source decision explicitly rather
than adding paths to the manifest by hand. See
[Generated Output Ownership And Safe Cleanup](../02-user-guide/GENERATED_OUTPUT_OWNERSHIP.md).

## OTP support boundary

The planned 1.0 promise now covers a small runtime-tested local subset: selected Process operations,
Task success/timeout/shutdown, Agent state lifecycle and cast ordering, plus the documented
application/typed-child-spec boot shapes. Those calls compile to normal Elixir/OTP functions.

Custom `@:genserver` callbacks, `@:supervisor` lifecycle and restart/failure policy, Registry,
TaskSupervisor, raw mailbox/monitor behavior, abnormal cross-process failures, distributed OTP, and
hot upgrades remain experimental or outside 1.0. Successful compilation alone is not lifecycle
evidence. See the [OTP Support Contract](../04-api-reference/OTP_SUPPORT_CONTRACT.md) for the exact
operations, generated Elixir, tests, and exclusions.

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

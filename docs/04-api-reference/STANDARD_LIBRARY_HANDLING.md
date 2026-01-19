# Standard Library Handling (Haxe stdlib + Elixir externs)

Reflaxe.Elixir supports two complementary “stdlib” layers:

1) **Haxe standard library compatibility** (e.g. `Array`, `StringTools`, `haxe.io.*`, `sys.*`)
2) **Typed Elixir externs** (e.g. `elixir.File`, `elixir.DateTime`, `elixir.IO`, plus `phoenix.*`, `ecto.*`)

You can use either layer (or both) in the same codebase. The choice is about **portability vs BEAM-first ergonomics**.

See also:
- `docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md`
- `docs/02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md`
- `docs/02-user-guide/WRITING_IDIOMATIC_HAXE_FOR_ELIXIR.md`
- `docs/02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md`
- `docs/06-guides/KNOWN_LIMITATIONS.md`

## “reflaxe_runtime” is not a Mix project

`reflaxe_runtime` is a **Haxe compilation define**, not an Elixir/Mix project.

You will see it in `.hxml` files and docs because it gates code that should type-check during compilation
(`#if (macro || reflaxe_runtime)` / `#if (elixir || reflaxe_runtime)`) even though it does not exist at runtime
in other targets (and should not leak into the Haxe macro/interp contexts). See
`docs/02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md`.

Runtime helpers that *must exist as emitted Elixir* (for example, the exception/throw bridge used by the
Elixir lowering pipeline) live as Haxe sources under:

- `std/reflaxe/elixir/runtime/**` (native modules like `Reflaxe.Elixir.HaxeThrow`)

They are forcibly included/kept at macro-time by `src/reflaxe/elixir/CompilerInit.hx`, so they are emitted
into your app’s generated `.ex` output even under `-dce full`.

## The core strategy

### Don’t “re-implement the whole Haxe stdlib” blindly

For many `haxe.*` modules, the upstream Haxe stdlib already compiles correctly for the Elixir target.
We only override/replace modules when one (or more) is true:

- upstream implementation uses inline patterns that produce invalid Elixir after lowering
- upstream implementation compiles, but produces systematically non-idiomatic Elixir (hard to read/maintain)
- we can map to a strong BEAM primitive (binary, iodata, pattern matching) and get both correctness + readability
- we need a **BEAM mapping** of `sys.*` (filesystem/process/network/thread) rather than “pretend-JS” behavior

### Target-conditional stdlib overrides (the `.cross.hx` + `std/_std` model)

This repo ships a small set of Elixir-target overrides in `std/`:

- `std/*.cross.hx`: “cross” overrides for core modules (`Array`, `String`, `Std`, etc.)
- `std/haxe/**`: selected Haxe std modules implemented/adjusted for Elixir
- `std/sys/**`: BEAM-backed `sys.*` surfaces
- `std/_std/**`: **staged overrides** injected only for Elixir builds (to prevent `__elixir__()` leaking into macro/other targets)

The injection point is macro-time, in:
- `src/reflaxe/elixir/CompilerInit.hx:1` (adds `std/` and `std/_std/` only when targeting Elixir)

This keeps:
- macro context and other targets using the official Haxe stdlib
- Elixir builds using the Elixir-specific overrides (and only those)

## Choosing an API layer (practical guidance)

### Use the Haxe stdlib when…

Best for:
- **pure business logic** you want to reuse across targets (JS/Node, Elixir, etc.)
- algorithms/data transforms that don’t need Phoenix/Ecto/OTP primitives
- libraries you intend to ship as “multi-target Haxe code”

Typical examples:
- `Array`, `StringTools`, `haxe.ds.Option`, `haxe.format.JsonPrinter`
- `haxe.io.Bytes` for binary data manipulation (portable API, BEAM-optimized implementation)

### Use typed Elixir externs when…

Best for:
- Phoenix/LiveView/Ecto integration
- BEAM primitives (processes, iodata/binaries, filesystem ops) where the Elixir API is the “native shape”
- eliminating impedance mismatch (structs, atoms, tagged tuples) in app code

Typical examples:
- `elixir.DateTime` / `elixir.File` / `elixir.Path` / `elixir.IO`
- `phoenix.*` / `ecto.*` integrations from `std/phoenix` and `std/ecto`

### Mixing and matching (recommended pattern)

The ideal architecture for most Phoenix apps:

- **Haxe stdlib** in the “domain layer” (pure logic, transformations, validation logic, parsing)
- **typed Elixir/Phoenix externs** in the “integration layer” (LiveView, Ecto, OTP callbacks)
- explicit boundaries:
  - decode `Term` inputs to typed structures at the edges
  - keep assigns typed (`Socket<Assigns>`)

Rule of thumb:
- if you’re writing code that “looks like Phoenix”, prefer Phoenix/Elixir externs
- if you’re writing code that “looks like a reusable library”, prefer Haxe stdlib

## How to contribute new stdlib support safely

When you need to fix stdlib behavior for the Elixir target:

1) Prefer adding/adjusting Haxe sources in:
   - `std/*.cross.hx`, `std/haxe/**`, `std/sys/**`, or `std/_std/**`
2) Add a snapshot test under:
   - `test/snapshot/stdlib/**`
3) **Do not patch generated `.ex`** as a behavior change (generated outputs are not the source of truth).

If a change touches `std/_std`, keep it Elixir-target-only (it is injected conditionally).

## Notes on portability expectations

“Support the whole stdlib” doesn’t mean “every `sys.*` module is identical to native OS targets”.

For `sys.*`:
- implement what maps cleanly to BEAM/Elixir
- document differences when semantics diverge
- fail fast with actionable errors for things that cannot be supported safely

Track the current stdlib parity work in bd:
- `haxe.elixir-hm47` (stdlib parity roadmap)

# Standard Library Handling (Haxe stdlib + Elixir externs)

Reflaxe.Elixir supports two complementary “stdlib” layers:

1) **Haxe standard library compatibility** (e.g. `Array`, `StringTools`, `haxe.io.*`, `sys.*`)
2) **Typed Elixir externs** (e.g. `elixir.File`, `elixir.DateTime`, `elixir.IO`, plus `phoenix.*`, `ecto.*`)

You can use either layer (or both) in the same codebase. The choice is about **portability vs BEAM-first ergonomics**.

See also:
- `docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md`
- `docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md`
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

### Minimal runtime, compiler-first lowering

Reflaxe.Elixir does **not** aim to ship a broad Haxe runtime on the BEAM. The
stdlib strategy is:

1) Let the compiler lower Haxe constructs to ordinary Elixir when it can do so
   correctly.
2) Map stdlib APIs to idiomatic BEAM primitives when the target already has the
   right abstraction.
3) Use small emitted support modules only when Haxe semantics cannot be
   represented cleanly as compile-time lowering or a thin native wrapper.

Good examples:

- `haxe.crypto.Sha224` / `Sha256` call `:crypto.hash/2` and
  `Base.encode16/2` at runtime, with a pure-Haxe fallback only for macro/eval
  contexts.
- `haxe.ds.Map` and related map surfaces use native `%{}` storage and lower to
  `Map.*` / `Enum.*` shapes where that preserves Haxe semantics.
- `DynamicAccess` is a legitimate boundary case: JSON, params, and other
  map-like values can arrive as native Elixir terms, so the target needs a
  contained bridge for typed access. That does not make `Dynamic` a general app
  programming model.
- `Reflaxe.Elixir.HaxeThrow` and `Reflaxe.Elixir.HaxeFloat` are deliberately
  small compatibility helpers for semantics the BEAM cannot directly represent:
  throwing arbitrary Haxe values, and IEEE `NaN` / infinity values.

Runtime support is a last resort. If a stdlib feature can be expressed by
better AST lowering, an Elixir-native extern, or a targeted stdlib override, do
that before adding another runtime helper.

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
- `std/_std/**`: **Elixir-only shims** injected only for Elixir builds (to prevent `__elixir__()` leaking into macro/other targets)

### Bootstrap-safe overrides (early, dual-mode)

Some stdlib modules are resolved **very early** during compilation, and Haxe runs macros using the `eval` interpreter.
That combination means a few modules must satisfy two requirements at once:

1) **Macro/eval phase (host-side)**: constructors must exist and be runnable (eval can instantiate classes).
2) **Elixir output phase (target-side)**: we must avoid emitting the canonical Haxe stdlib implementation when it is
   non-idiomatic for BEAM or produces Elixir warnings that fail CI under `--warnings-as-errors` (WAE).

For those specific modules, we use a **dual-mode override** under `src/`:

- `#if macro`: small in-memory implementation (keeps macro/eval happy).
- `#else`: `@:nativeGen extern` surface (prevents canonical stdlib code from being emitted into generated `.ex`).

Examples:
- `src/haxe/ds/BalancedTree.hx`
- `src/haxe/ds/EnumValueMap.hx`

Why `src/`?
- For haxelib installs, `src/` is the only path guaranteed to be on the initial classpath for `-lib reflaxe.elixir`.
- Macro-time classpath injection can be too late because Haxe may cache some stdlib modules before bootstrap macros run.

What does this “replace”?
- Only the specific modules we place under `src/haxe/**` are shadowed early.
- Everything else still comes from the upstream Haxe stdlib unless we explicitly override it via:
  - `std/*.cross.hx` (cross-platform override selection), or
  - `std/haxe/**`, `std/sys/**`, `std/_std/**` (Elixir-target additions/shims).

Why the path looks like the Haxe stdlib (`src/haxe/ds/...`)?
- This is intentional: Haxe module resolution is path-based. Putting a file at `haxe/ds/BalancedTree.hx`
  on the classpath shadows the upstream `haxe.ds.BalancedTree` module *for this compilation*.
- We keep it surgical: only add these early overrides when we have a concrete macro/eval + WAE reason.

Is this a Reflaxe convention?
- It’s a common pattern across target compilers (including Reflaxe-based ones): when a module must be
  resolved before bootstrap/injection can run, it needs to live on the library’s initial classpath.
- The “dual-mode” approach (`#if macro` implementation, `#else` extern) is specific to our constraints:
  Haxe eval must be able to instantiate the type, but we don’t want to emit the upstream implementation
  into Elixir output when it is non-idiomatic or breaks `--warnings-as-errors`.

The injection point is macro-time, in:
- `src/reflaxe/elixir/CompilerBootstrap.hx:1` (early injection, invoked from `extraParams.hxml`)
- `src/reflaxe/elixir/CompilerInit.hx:1` (compiler registration + early injection)

See also:
- `docs/01-getting-started/cross-hx.md`
- `docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md`

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

1) Classify the module first:
   - upstream fallback works; add tests/docs/tracking, not a duplicate local file
   - compiler lowering should own the behavior
   - a BEAM-native stdlib override is needed
   - a small runtime helper is unavoidable
   - the feature should fail fast as unsupported on the Elixir target
2) Prefer adding/adjusting Haxe sources in:
   - `std/*.cross.hx`, `std/haxe/**`, `std/sys/**`, or `std/_std/**`
3) Add a snapshot test under:
   - `test/snapshot/stdlib/**`
4) Add Haxe-authored ExUnit coverage when runtime semantics matter.
5) **Do not patch generated `.ex`** as a behavior change (generated outputs are not the source of truth).

If a change touches `std/_std`, keep it Elixir-target-only (it is injected conditionally).

## Notes on portability expectations

“Support the whole stdlib” doesn’t mean “every `sys.*` module is identical to native OS targets”.

For `sys.*`:
- implement what maps cleanly to BEAM/Elixir
- document differences when semantics diverge
- fail fast with actionable errors for things that cannot be supported safely

Track the current stdlib parity work in bd:
- `haxe.elixir-hm47` (stdlib parity roadmap)

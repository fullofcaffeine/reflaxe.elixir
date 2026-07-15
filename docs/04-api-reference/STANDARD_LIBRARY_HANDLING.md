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
- `docs/08-roadmap/stdlib-and-package-ecosystem.md`

Major 1 now requires complete support for every public Haxe stdlib API applicable to generated
Elixir programs. That does not change the selective-override design below: a tested official Haxe
fallback is support, and copying an unchanged file is not progress. See Beads epic
`haxe.elixir.codex-0yn.10` for the API inventory and remaining semantics work.

## Target selection vs compiler development

Application builds select this target through `-lib reflaxe.elixir`; the library supplies
the `elixir` define used by typed target APIs and stdlib overrides. Applications do not
need to define `reflaxe_runtime`.

`reflaxe_runtime` remains a compiler-development define for typing implementation code
guarded by `#if (macro || reflaxe_runtime)` outside macro mode. It is not an Elixir/Mix
project and does not exist in the generated application. See
[`REFLAXE_RUNTIME_EXPLAINED.md`](../02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md).

Runtime helpers that *must exist as emitted Elixir* live as Haxe sources under:

- `std/reflaxe/elixir/runtime/**` (native modules like `Reflaxe.Elixir.HaxeThrow`)

The two core helpers, `Reflaxe.Elixir.HaxeThrow` and
`Reflaxe.Elixir.HaxeFloat`, are currently force-typed and kept at macro time by
`src/reflaxe/elixir/CompilerInit.hx`. They are therefore emitted into normal
generated `.ex` output even under `-dce full`. Their call sites remain
selective, but module inclusion is not yet fully demand-driven. See
[`reflaxe_runtime` and Generated Elixir Helpers](../02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md)
for the reason and the tracked footprint work.

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

- `haxe.crypto.Hmac` calls `:crypto.mac(:hmac, ...)`; `haxe.crypto.Sha224` /
  `Sha256` call `:crypto.hash/2` and `Base.encode16/2` at runtime, with a
  pure-Haxe fallback only for macro/eval contexts.
- `haxe.crypto.BaseCode` is a small emitted support module because BEAM has no
  native primitive for arbitrary caller-provided power-of-two dictionaries.
- `haxe.ds.Map` and related map surfaces use native `%{}` storage and lower to
  `Map.*` / `Enum.*` shapes where that preserves Haxe semantics.
- `DynamicAccess` is a legitimate boundary case: JSON, params, and other
  map-like values can arrive as native Elixir terms, so the target needs a
  contained bridge for typed access. That does not make `Dynamic` a general app
  programming model.
- `Reflaxe.Elixir.HaxeThrow` and `Reflaxe.Elixir.HaxeFloat` are deliberately
  small compatibility helpers for semantics the BEAM cannot directly represent:
  throwing arbitrary Haxe values, and IEEE `NaN` / infinity values.

Runtime support is a last resort for generated call shapes and new compiler
design. If a stdlib feature can be expressed by better AST lowering, an
Elixir-native extern, or a targeted stdlib override, do that before adding
another runtime helper. This design rule is separate from the current
conservative policy that retains the two core helper modules in every normal
build.

### Don’t “re-implement the whole Haxe stdlib” blindly

For many `haxe.*` modules, the upstream Haxe stdlib already compiles correctly for the Elixir target.
We only override/replace modules when one (or more) is true:

- upstream implementation uses inline patterns that produce invalid Elixir after lowering
- upstream implementation compiles, but produces systematically non-idiomatic Elixir (hard to read/maintain)
- we can map to a strong BEAM primitive (binary, iodata, pattern matching) and get both correctness + readability
- we need a **BEAM mapping** of `sys.*` (filesystem/process/network/thread) rather than “pretend-JS” behavior

Absence from local override roots is therefore meaningful. If Reflaxe.Elixir does not provide a module
under `std/elixir/_std/` or a target-owned support module under `std/`, Haxe falls through to the
installed official Haxe stdlib later on the classpath. That upstream fallback is the preferred answer
for modules that need no Elixir-specific implementation. Do not copy an upstream file into this repo
unless the target owns a real override or documented bootstrap exception.

### Target-conditional stdlib overrides (`_std` source model)

This repo ships a small set of Elixir-target overrides using the Reflaxe source-layout convention:

- `std/elixir/_std/*.hx`: core Haxe stdlib overrides (`Array`, `String`, `Std`, etc.)
- `std/elixir/_std/haxe/**/*.hx`: selected Haxe std modules implemented/adjusted for Elixir
- `std/elixir/_std/sys/**/*.hx`: BEAM-backed `sys.*` surfaces

Layout rule:

- Use `std/elixir/_std/**/*.hx` when replacing an upstream Haxe stdlib module with an
  Elixir-specific implementation that keeps the same public API. Reflaxe package builds turn these
  authored files into packaged `.cross.hx` files.
- Do **not** add a plain `.hx` copy of an upstream stdlib file just to reduce
  the parity gap. If the upstream implementation works unchanged, use it from
  the official Haxe stdlib and add tests/tracking instead.
- Use plain `.hx` under `std/haxe/**` only for modules this target genuinely
  owns as new support surfaces, or when there is a documented bootstrap/dual-mode
  reason that `.cross.hx` cannot satisfy.

Packaging note:

- Reflaxe's generated-project skeleton authors target std overrides as plain `.hx` under configured
  `_std` paths, then `haxelib run reflaxe build` copies those files into the published classpath as
  `.cross.hx`.
- Reflaxe.Elixir follows that source layout for stdlib overrides. For normal repo, GitHub-tag, and
  Lix builds, `CompilerBootstrap.Start()` adds `std/elixir/_std/` directly to the active Haxe
  classpath so the authored files are used without a packaging step.
- Adding these paths means Haxe searches the installed package's override/API directories earlier for
  this compile. It does not copy files, generate files, or rewrite `.hx` filenames during compilation.
- If we publish to haxelib.org, validate the generated package path separately with
  `npm run test:haxelib-package`. That smoke test asserts that release artifacts use the
  Reflaxe-flattened shape: no raw `std/` or `src/elixir/_std/` source tree is published, while
  upstream-colliding overrides are present as packaged `src/**/*.cross.hx` files.

`haxe.Exception` is a normal `_std` override at `std/elixir/_std/haxe/Exception.hx`. Source-checkout
HXML files make that root visible before typing, and Reflaxe build publishes the same implementation
as `src/haxe/Exception.cross.hx`. The executable implementation and its `elixir_output` guard are the
same in both modes.

### Bootstrap-safe overrides (early source-classpath modules)

Some stdlib modules are resolved **very early** during compilation, and Haxe runs macros using the `eval` interpreter.
That combination means a few modules must satisfy two requirements at once:

1) **Macro/eval phase (host-side)**: constructors must exist and be runnable (eval can instantiate classes).
2) **Elixir output phase (target-side)**: we must avoid emitting the canonical Haxe stdlib implementation when it is
   non-idiomatic for BEAM or produces Elixir warnings that fail CI under `--warnings-as-errors` (WAE).

For those specific modules, we use an early override under `src/haxe/**`, the package classpath that
is available immediately when a project uses `-lib reflaxe.elixir`.

There are two current shapes:

- `src/haxe/ds/{ArraySort,BalancedTree,EnumValueMap,ListSort}.hx` are dual-mode plain `.hx` modules:
  `#if macro` gives eval a small implementation, while `#else` exposes an extern surface or target
  diagnostic surface so generated Elixir does not emit the canonical mutable stdlib implementation.
- `src/haxe/ds/{GenericStack,HashMap,List}.hx` are early BEAM-safe implementations whose observable
  mutation semantics depend on the compiler's receiver-rebinding rules.

For dual-mode plain `.hx` modules, the usual pattern is:

- `#if macro`: small in-memory implementation (keeps macro/eval happy).
- `#else`: `@:nativeGen extern` surface (prevents canonical stdlib code from being emitted into generated `.ex`).

Examples:
- `src/haxe/ds/BalancedTree.hx`
- `src/haxe/ds/EnumValueMap.hx`
- `src/haxe/ds/ArraySort.hx`
- `src/haxe/ds/ListSort.hx`

Why `src/`?
- For haxelib installs, `src/` is the only path guaranteed to be on the initial classpath for `-lib reflaxe.elixir`.
- Macro-time classpath injection can be too late because Haxe may cache some stdlib modules before bootstrap macros run.

What does this “replace”?
- Only the specific modules we place under `src/haxe/**` are shadowed early.
- Everything else still comes from the upstream Haxe stdlib unless we explicitly override it via:
  - `std/elixir/_std/**/*.hx` (Elixir stdlib override source), or
  - `std/**/*.hx` excluding upstream std namespaces (Elixir-target additions/shims).

Why the path looks like the Haxe stdlib (`src/haxe/ds/...`)?
- This is intentional: Haxe module resolution is path-based. Putting a file at `haxe/ds/BalancedTree.hx`
  on the classpath shadows the upstream `haxe.ds.BalancedTree` module *for this compilation*.
- We keep it surgical: only add these early overrides when we have a concrete macro/eval + WAE reason.

Is this a Reflaxe convention?
- It’s a common pattern across target compilers (including Reflaxe-based ones): when a module must be
  resolved before bootstrap/injection can run, it needs to live on the library’s initial classpath.
- The dual-mode approach (`#if macro` implementation, `#else` extern) is specific to our constraints:
  Haxe eval must be able to instantiate the type, but we don’t want to emit the upstream implementation
  into Elixir output when it is non-idiomatic or breaks `--warnings-as-errors`.
- `haxe.Exception` does not need this initial-classpath exception. It is selected from `_std` in
  source builds and generated as `.cross.hx` in release packages, matching other Reflaxe targets.

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
   - `std/elixir/_std/**/*.hx`
   - plain `std/**/*.hx` only for new target-owned support modules or documented
     exceptions, not unchanged upstream copies
3) Add a snapshot test under:
   - `test/snapshot/stdlib/**`
4) Add Haxe-authored ExUnit coverage when runtime semantics matter.
5) **Do not patch generated `.ex`** as a behavior change (generated outputs are not the source of truth).

## Notes on portability expectations

“Support the whole stdlib” doesn’t mean “every `sys.*` module is identical to native OS targets”.

For `sys.*`:
- implement what maps cleanly to BEAM/Elixir
- document differences when semantics diverge
- fail fast with actionable errors for things that cannot be supported safely

Track the current stdlib parity work in bd:
- `haxe.elixir-hm47` (stdlib parity roadmap)

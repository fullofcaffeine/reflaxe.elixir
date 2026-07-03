# The `reflaxe_runtime` Define (What It Is and Why You Need It)

`reflaxe_runtime` is a **Haxe compilation define** used by Reflaxe targets (including Reflaxe.Elixir)
to control **which code is visible during compilation**.

It is not related to “runtime on the BEAM” — it does not change how Elixir executes after codegen.

## What `reflaxe_runtime` Is

- A build define you add to your `.hxml` (all examples do).
- Used throughout the compiler and standard library to guard macro/target‑specific code:
  - `#if (macro || reflaxe_runtime)` for compiler/tooling code
  - `#if (elixir || reflaxe_runtime)` for Elixir‑target APIs that must type‑check in tooling/tests

This is especially useful for:

- running Haxe tooling under `--interp` (e.g., doc generators)
- snapshot tests that compile Haxe → Elixir in a controlled environment
- custom targets where a single “target define” isn’t available in every compilation context

## What `reflaxe_runtime` Is NOT

- It does **not** make Haxe code execute on the BEAM.
- It does **not** mean “the compiler exists at runtime”.
  - The compiler runs at macro‑time and disappears after code generation.
- It does **not** opt your program into a large Haxe compatibility runtime.
  Reflaxe.Elixir prefers compile-time lowering and Elixir-native stdlib
  mappings. Emitted runtime helpers are intentionally small and reserved for
  cases where the BEAM cannot directly represent required Haxe semantics.

Examples of legitimate emitted helpers:

- `Reflaxe.Elixir.HaxeThrow` wraps arbitrary Haxe thrown values so they can move
  through Elixir `raise` / `rescue` correctly.
- `Reflaxe.Elixir.HaxeFloat` represents `NaN` and infinities, which are valid
  Haxe `Float` values but not ordinary BEAM numbers.

Examples that should not use a runtime helper:

- Hashing APIs such as `haxe.crypto.Sha256` should call BEAM primitives like
  `:crypto.hash/2`.
- Map and iterator APIs should lower to ordinary Elixir data operations when
  that preserves Haxe behavior.
- Dynamic payload access should be contained at typed boundaries such as JSON,
  params, or `DynamicAccess`, not spread through application code.

## Typical Build Configuration

Minimum example (simplified):

```hxml
-lib reflaxe.elixir
-cp src_haxe
-D reflaxe_runtime
-D elixir_output=lib
--macro reflaxe.elixir.CompilerInit.Start()
Main
```

## Important Boundary: App Code vs Framework Code

Reflaxe.Elixir uses `untyped __elixir__(...)` internally inside its **standard library / framework**
layer to provide native Elixir implementations when necessary.

Application code should **not** call `__elixir__` directly. Prefer:

- typed externs under `std/elixir/**`
- Phoenix/Ecto helper libraries provided by the project
- compiler‑supported annotations and transforms

## Related Reading

- `docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md`
- `docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md`

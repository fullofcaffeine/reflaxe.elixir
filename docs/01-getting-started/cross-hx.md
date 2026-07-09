# .cross.hx Files — Beginner‑Friendly Guide

> At a glance
> - `.cross.hx` = target-specific implementation of a familiar API (same surface, idiomatic target code)
> - The suffix is Haxe 4's target-specific file mechanism; `cross` is Haxe's generic custom-target platform, not a promise that the file is portable across all targets
> - In this repo, authored stdlib replacements live as plain `.hx` files under `std/elixir/_std/**`; Reflaxe build can package them as `.cross.hx`
>   - No `.cross.hx` files are checked into `src/` or `std/`; `haxe.Exception` follows the same `_std` rule as Rust and OCaml. Selected `src/haxe/ds/*.hx` files remain early plain `.hx` dual-mode overrides for macro/eval requirements.
> - `std/elixir/_std/` is a selective override root: modules we do not provide there keep resolving from the installed official Haxe stdlib
> - Reflaxe's skeleton `build` command generates packaged `.cross.hx` files from `_std` source roots; checked-in `std/**/*.cross.hx` is no longer the source layout
> - Prefer `_std` overrides for stable API mappings; use macros for authoring ergonomics; use AST transforms for shape-driven rewrites
> - Transitional stubs are legacy only and require explicit removal criteria and gating

This guide explains what `.cross.hx` files are, why they exist in Reflaxe‑based compilers (like Haxe → Elixir), when to use them, and how they are loaded. It is written for developers new to Haxe and Reflaxe.

If you want the deeper, architecture‑level details (Haxe module resolution + target-gated classpaths), read: docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md

## What Is a `.cross.hx` File?

In Reflaxe compilers, a `.cross.hx` file is a Haxe source file that provides a target-specific implementation of a library or function while preserving the same public API. Think of it as “the target-optimized version of a familiar API.”

Haxe itself owns this mechanism. Since Haxe 4.0, the compiler can prefer `Module.<target>.hx`
over `Module.hx` when compiling for a target named `<target>`. For Reflaxe targets on Haxe 4,
that target name is `cross`, so the filename becomes `Module.cross.hx`.

Important wording point: `cross` here means Haxe's **custom-target platform mode**. It does not
mean "this file is portable across every Haxe target." Reflaxe.Elixir uses the `cross` platform
because Elixir is not a built-in Haxe compiler target with its own suffix like `.js.hx` or `.cpp.hx`.

- Packaged file naming: `Name.cross.hx` (examples: `String.cross.hx`, `Std.cross.hx`, `HXX.cross.hx`).
- Purpose: generate clean, idiomatic code for the target (Elixir here) instead of post‑processing generic code later.
- Scope: used primarily for standard library overrides or small glue APIs needed by the target.

Why this matters: generating the right target code from the start is almost always better than rewriting it later with transforms. `.cross.hx` gives you that “early hook”.

## Where Do These Files Live?

By convention in this repository, author upstream-colliding stdlib replacements under
`std/elixir/_std/` as plain `.hx` files. Example tree:

```
std/elixir/_std/
  String.hx
  StringTools.hx
  haxe/crypto/Sha256.hx
```

Practical note (source checkout versus package)
- Scoped source-checkout builds resolve `haxe_libraries/reflaxe.elixir.hxml`, which adds `std/` and `std/elixir/_std/` before typing; bootstrap retains package-root fallback setup.
- Built haxelib packages already contain generated `src/**/*.cross.hx` files, so installed consumers need only `-lib reflaxe.elixir`.
- A bare global `haxelib dev` pointing at the unbuilt checkout is not a supported compiler-development path. Use the scoped Lix configuration, explicit source classpaths, or build/install the package artifact first.
- "Added" means Haxe searches the installed package's override/API directories before the official Haxe stdlib for that compile. No files are copied, generated, or renamed at that moment.
- In rare cases we use an early plain `.hx` override for modules that must work in **both** macro/eval and Elixir target compilation, or whose receiver semantics are tied to compiler lowering. Those files live under `src/haxe/**` (examples: `src/haxe/ds/BalancedTree.hx`, `src/haxe/ds/List.hx`).

When compiling for the `cross` platform from a packaged Reflaxe build, Haxe treats files ending in
`.cross.hx` as platform-specific module implementations. During normal source-tree/GitHub/Lix builds,
the same authored overrides are selected because bootstrap prepends `std/elixir/_std/` only for
Elixir builds.

The override root is selective. If Reflaxe.Elixir does not provide a matching module in
`std/elixir/_std/` or `std/`, Haxe continues normal classpath resolution and uses the installed
official Haxe stdlib module. Do not copy upstream stdlib files locally just to make the parity report
count smaller; add a local file only when the Elixir target needs a target-specific implementation,
a target-owned API, or a documented early bootstrap exception.

See the full mechanism in docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md

## Reflaxe Skeleton vs This Repository

The upstream Reflaxe skeleton uses a packaging convention:

- author compiler code under `src/`
- author normal API files under `std/`
- author target std overrides under a folder ending in `_std`, such as `std/LANG/_std/`
- run `haxelib run reflaxe build` before publishing to haxelib

During that packaging step, Reflaxe copies all configured std paths into the single published
`classPath`. Files from paths ending in `_std` are copied with a `.cross.hx` extension.

Reflaxe.Elixir now uses that same source layout for stdlib replacements:

- checked-in upstream-colliding target overrides live under `std/elixir/_std/**/*.hx`
- scoped source HXML adds `std/elixir/_std/` before typing, with bootstrap fallback for supported consumer paths; this is only classpath order, not file copying
- Reflaxe build can still generate packaged `.cross.hx` files when creating a haxelib-style package
- releases installed by Lix from GitHub tags consume the authored source layout directly

So do not add checked-in `std/**/*.cross.hx` files for ordinary stdlib work. The path should describe
the role of the file:

- `std/elixir/_std/**/*.hx`: target-specific replacement for an existing Haxe module; packaged as `.cross.hx` by Reflaxe build
- plain `.hx` in `std/`: target-owned public/support API such as `phoenix.*`, `ecto.*`, or `elixir.*`
- plain `.hx` in `src/haxe/**`: rare early dual-mode override that must work in macro/eval and target compilation

## How Are They Loaded? (Target‑Conditional Gating)

We only want the Elixir‑specific overrides when compiling to Elixir. Otherwise, macro tools, unit tests,
or other targets would “see” Elixir‑only code and fail (for example, code using `__elixir__()` would not
exist in JS or macro contexts).

This project implements target‑conditional gating through scoped source HXML plus the bootstrap macro:

- In scoped source builds, `haxe_libraries/reflaxe.elixir.hxml` adds `std/` and
  `std/elixir/_std/` before typing so authored overrides win over the official Haxe stdlib.
- `CompilerBootstrap.Start()` retains package-root fallback insertion and vendored dependency setup.
- For other contexts (macro-only tools, non-Elixir targets), the library still exposes its normal
  `src/` classpath, but does not add the Elixir target std root.

### What is `-D elixir_output`?

On **Haxe 4**, Reflaxe targets compile under the `cross` platform, so `#if cross` is not specific enough
to mean “Elixir”. Reflaxe.Elixir therefore uses the presence of the `elixir_output` define as the stable
signal that the Elixir backend is active.

In practice, builds pass it as:

```bash
-D elixir_output=<output_dir>
```

Target-specific overrides that can appear as generated `.cross.hx` package files may use it as:

- `#if elixir_output ... #else extern ... #end`

That pattern keeps those modules safe when they are visible to non-Elixir compilation contexts (macros,
JS/genes, tooling), while still providing the correct Elixir implementation when the Elixir backend is active.

Benefits:

- Macro context uses the regular Haxe stdlib (no `__elixir__()` errors).
- Other targets (like JavaScript) are unaffected.
- Clean separation of concerns and predictable builds.

More details: docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md

## When Should I Use `_std` Overrides?

Use `std/elixir/_std/**/*.hx` when you need to generate truly idiomatic, target‑specific code for a
well‑known API. Reflaxe build packages these authored files as `.cross.hx`. Typical cases:

- Standard library methods whose direct, idiomatic Elixir equivalent is obvious (e.g., String functions, `StringBuf`, collection helpers).
- Lightweight shims that compile to pure Elixir calls for performance/clarity.

Prefer this `_std` override path over late AST transformations when:

- The mapping is stable and shape‑driven (same signature and behavior, different implementation).
- The result should look exactly like hand‑written target code.

Avoid a std override when:

- The change depends on dynamic program structure (better handled in the AST transformer passes).
- You are tempted to bake in application‑specific heuristics (names, atoms, routes): that belongs in user code, not compiler libraries.

## How Does It Compare to Macros and AST Transforms?

You have three levers (from “earliest” to “latest” in the pipeline):

1) `_std` / packaged `.cross.hx` (Compile‑time API override)
- Best for: stable APIs with a clear, idiomatic mapping to target.
- Pros: zero runtime overhead, simplest output, closest to hand‑written code.
- Cons: not suited for program‑shape‑dependent rewrites.

2) Macros (Compile-time code generation)
- Best for: authoring ergonomics (e.g., HXX authoring), validations, and compile‑time safety.
- Pros: clear authoring UX, early errors.
- Cons: runs in macro context; must avoid target‑only constructs in macro code.

3) AST Transforms (Mid/Late pipeline)
- Best for: structural rewrites based on typed program shape (loops → comprehensions, pattern rewrites, control‑flow normalization, etc.).
- Pros: full view of typed code; expressive and target-aware.
- Cons: can be harder to reason about if used for what a `_std` override should do.

Rule of thumb:
- If it’s an API surface with a known, idiomatic target implementation → `std/elixir/_std/**/*.hx`.
- If it’s an authoring DSL or compile‑time sugar → macro.
- If it needs typed program analysis or whole‑function restructuring → AST transform.

## Example: Tiny Target‑Specific Helper

HXX status update: the transitional target stub has been removed. HXX now compiles via a macro by default:

```haxe
// std/HXX.hx
class HXX {
  public static macro function hxx(template) {
    return reflaxe.elixir.macros.HXX.hxx(template);
  }
  public static macro function block(content) {
    return reflaxe.elixir.macros.HXX.block(content);
  }
}
```

This macro path validates and transforms templates at compile time and feeds the builder with `@:heex` literals that are emitted as `ESigil("H", ...)` — no string → ~H post‑processing required.

## Pitfalls and How We Avoid Them

- “Leaking” target code into macro/other targets: keep target std overrides under `std/elixir/_std/`,
  which is added to the classpath only for Elixir builds.
- Using std overrides for app-specific behavior: don't. Keep overrides generic and API-faithful; follow Phoenix and Elixir APIs exactly.
- Using `Dynamic` as a shortcut: project follows a strict no‑Dynamic policy for public surfaces. Keep types precise.
- Overusing late string rewriting: prefer early, structural approaches (overrides or AST passes) over fragile string surgery.

## FAQ

Q: Are `.cross.hx` files required?

A: They are the packaged form Reflaxe uses for target-specific std overrides. In this source tree,
author those overrides under `std/elixir/_std/**/*.hx`; do not check in `.cross.hx` files under
`src/` or `std/`.

Q: Do `.cross.hx` files run at runtime?

A: No. They are compiled into the target output like any other Haxe source. Many overrides use `inline` or inject native target code via helper mechanisms so there’s no runtime penalty.

Q: How do I know if my override is being used?

A: Build with the Elixir target and inspect verbose `Parsed ...` lines or generated `.ex`; source-tree
builds should reference `std/elixir/_std/...`, and packaged builds should reference the corresponding
`.cross.hx` file.

## Checklist Before Adding a Std Override

- Is there a stable, idiomatic target implementation for this API?
- Will this generate code that looks hand‑written by an Elixir developer?
- Can I avoid app‑specific names or heuristics?
- Will types remain precise (no Dynamic on public surfaces)?
- Are there tests/snapshots to lock the desired output?

## Further Reading

- Haxe Manual: Target-Specific Files — https://haxe.org/manual/lf-target-specific-files.html
- docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md — How `_std` source layout, packaged `.cross.hx` resolution, and target std classpath insertion work
- docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md — Why we gate `.cross.hx` by target and how it’s implemented
- docs/05-architecture/HXX_ARCHITECTURE.md — How HXX authoring flows through the AST pipeline into HEEx (~H)

---

## Removal Criteria & CI Gates (for transitional stubs)

Use this to decide when a transitional target stub can be removed:

- Macro path only: `HXX.hxx()` expands at compile‑time and the builder emits `ESigil("H", ...)` directly (no string→~H conversion)
- Example apps compile and run with only the macro implementation enabled
- Snapshot tests green: verify block HEEx generation, assigns mapping, and control‑tag normalization without relying on string post‑processing
- Control‑tag transforms become no‑ops for macro‑produced content (idempotence check)
- Target‑conditional gating remains in place (no leaks to macro/other targets)

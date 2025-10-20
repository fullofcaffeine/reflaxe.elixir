# .cross.hx Files — Beginner‑Friendly Guide

> At a glance
> - `.cross.hx` = target‑specific implementation of a familiar API (same surface, idiomatic target code)
> - Lives under `std/`, staged to `std/_std/` during build, and classpath‑gated so only Elixir builds see them
> - Prefer `.cross.hx` for stable API mappings; use macros for authoring ergonomics; use AST transforms for shape‑driven rewrites
> - Transitional stubs (e.g., `std/HXX.cross.hx`) are allowed only with explicit removal criteria and gating

This guide explains what `.cross.hx` files are, why they exist in Reflaxe‑based compilers (like Haxe → Elixir), when to use them, and how they are loaded. It is written for developers new to Haxe and Reflaxe.

If you want the deeper, architecture‑level details (classpath staging and ordering), read: docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md

## What Is a `.cross.hx` File?

In Reflaxe compilers, a `.cross.hx` file is a Haxe source file that provides a target‑specific implementation of a library or function while preserving the same public API. Think of it as “the target‑optimized version of a familiar API.”

- File naming: `Name.cross.hx` (examples: `String.cross.hx`, `Std.cross.hx`, `HXX.cross.hx`).
- Purpose: generate clean, idiomatic code for the target (Elixir here) instead of post‑processing generic code later.
- Scope: used primarily for standard library overrides or small glue APIs needed by the target.

Why this matters: generating the right target code from the start is almost always better than rewriting it later with transforms. `.cross.hx` gives you that “early hook”.

## Where Do These Files Live?

By convention, place them under `std/` in the repository. Example tree:

```
std/
  String.cross.hx
  StringTools.cross.hx
  HXX.cross.hx
```

During compilation, the compiler stages these files to `std/_std/` (with the `.cross` suffix removed), making them appear as normal Haxe sources to the compiler/type checker:

- `std/String.cross.hx` → `std/_std/String.hx`

See the staging flow in docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md

## How Are They Loaded? (Target‑Conditional Gating)

We only want the Elixir‑specific overrides when compiling to Elixir. Otherwise, macro tools, unit tests, or other targets would “see” Elixir‑only code and fail (for example, code using `__elixir__()` would not exist in JS or macro contexts).

This project implements target‑conditional gating in the compiler bootstrap (CompilerInit.Start):

- When building the Elixir target (or when `-D elixir_output` is present), the staged `std/_std/` path is added to the classpath.
- For other contexts (macro‑only tools, tests on other targets), the staging path is not added.

Benefits:

- Macro context uses the regular Haxe stdlib (no `__elixir__()` errors).
- Other targets (like JavaScript) are unaffected.
- Clean separation of concerns and predictable builds.

More details: docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md

## When Should I Use `.cross.hx`?

Use `.cross.hx` when you need to generate truly idiomatic, target‑specific code for a well‑known API. Typical cases:

- Standard library methods whose direct, idiomatic Elixir equivalent is obvious (e.g., String functions, `StringBuf`, collection helpers).
- Lightweight shims that compile to pure Elixir calls for performance/clarity.

Prefer `.cross.hx` over late AST transformations when:

- The mapping is stable and shape‑driven (same signature and behavior, different implementation).
- The result should look exactly like hand‑written target code.

Avoid `.cross.hx` when:

- The change depends on dynamic program structure (better handled in the AST transformer passes).
- You are tempted to bake in application‑specific heuristics (names, atoms, routes): that belongs in user code, not compiler libraries.

## How Does It Compare to Macros and AST Transforms?

You have three levers (from “earliest” to “latest” in the pipeline):

1) `.cross.hx` (Compile‑time API override)
- Best for: stable APIs with a clear, idiomatic mapping to target.
- Pros: zero runtime overhead, simplest output, closest to hand‑written code.
- Cons: not suited for program‑shape‑dependent rewrites.

2) Macros (Compile‑time code generation)
- Best for: authoring ergonomics (e.g., HXX authoring), validations, and compile‑time safety.
- Pros: great developer UX, early errors.
- Cons: runs in macro context; must avoid target‑only constructs in macro code.

3) AST Transforms (Mid/Late pipeline)
- Best for: structural rewrites based on typed program shape (loops → comprehensions, pattern rewrites, control‑flow normalization, etc.).
- Pros: full view of typed code; powerful and target‑aware.
- Cons: can be harder to reason about if used for what a `.cross.hx` override should do.

Rule of thumb:
- If it’s an API surface with a known, idiomatic target implementation → `.cross.hx`.
- If it’s an authoring DSL or compile‑time sugar → macro.
- If it needs typed program analysis or whole‑function restructuring → AST transform.

## Example: Tiny Target‑Specific Helper

HXX status update: The transitional stub (`std/HXX.cross.hx`) has been removed. HXX now compiles via a macro by default:

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

- “Leaking” target code into macro/other targets: handled by target‑conditional classpath gating (only add `std/_std/` for Elixir builds).
- Using `.cross.hx` for app‑specific behavior: don’t. Keep overrides generic and API‑faithful; follow Phoenix and Elixir APIs exactly.
- Using `Dynamic` as a shortcut: project follows a strict no‑Dynamic policy for public surfaces. Keep types precise.
- Overusing late string rewriting: prefer early, structural approaches (overrides or AST passes) over fragile string surgery.

## FAQ

Q: Are `.cross.hx` files required?

A: No, but they’re the cleanest way to produce idiomatic target code for standard APIs without complex transforms.

Q: Do `.cross.hx` files run at runtime?

A: No. They are compiled into the target output like any other Haxe source. Many overrides use `inline` or inject native target code via helper mechanisms so there’s no runtime penalty.

Q: How do I know if my `.cross.hx` override is being used?

A: Build with Elixir target and inspect the generated `.ex`; the output should match the idiomatic function you coded. You can also temporarily add a compile‑time trace in the override (guarded by a debug define) to confirm it’s picked up.

## Checklist Before Adding a `.cross.hx`

- Is there a stable, idiomatic target implementation for this API?
- Will this generate code that looks hand‑written by an Elixir developer?
- Can I avoid app‑specific names or heuristics?
- Will types remain precise (no Dynamic on public surfaces)?
- Are there tests/snapshots to lock the desired output?

## Further Reading

- docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md — How staging works (std → std/_std) with examples
- docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md — Why we gate `.cross.hx` by target and how it’s implemented
- docs/03-compiler-development/hxx-template-compilation.md — How HXX authoring flows through the AST pipeline into HEEx (~H)

---

## Removal Criteria & CI Gates (for transitional stubs)

Use this to decide when a transitional stub (like `std/HXX.cross.hx`) can be removed:

- Macro path only: `HXX.hxx()` expands at compile‑time and the builder emits `ESigil("H", ...)` directly (no string→~H conversion)
- Example apps compile and run with only the macro implementation enabled
- Snapshot tests green: verify block HEEx generation, assigns mapping, and control‑tag normalization without relying on string post‑processing
- Control‑tag transforms become no‑ops for macro‑produced content (idempotence check)
- Target‑conditional gating remains in place (no leaks to macro/other targets)

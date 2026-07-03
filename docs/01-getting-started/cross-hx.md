# .cross.hx Files — Beginner‑Friendly Guide

> At a glance
> - `.cross.hx` = target-specific implementation of a familiar API (same surface, idiomatic target code)
> - The suffix is Haxe 4's target-specific file mechanism; `cross` is Haxe's generic custom-target platform, not a promise that the file is portable across all targets
> - Usually lives under `std/` and is selected by Haxe when compiling for the `cross` platform (the mode used by Reflaxe targets on Haxe 4)
>   - Exception: a small set of *early-resolved* overrides may live under the library `src/` classpath so consumer installs pick them up before bootstrap macros run (example: `src/haxe/Exception.cross.hx`)
> - `std/` is a selective override root: modules we do not provide there keep resolving from the installed official Haxe stdlib
> - Reflaxe's skeleton `build` command can generate `.cross.hx` files for package distribution, but this repo keeps the `.cross.hx` overrides checked in directly
> - Prefer `.cross.hx` for stable API mappings; use macros for authoring ergonomics; use AST transforms for shape‑driven rewrites
> - Transitional stubs (e.g., `std/HXX.cross.hx`) are allowed only with explicit removal criteria and gating

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

Practical note (consumer installs)
- When installed via haxelib/lix, the library’s `src/` classpath is available immediately, but `std/` is added by bootstrap macros.
- "Added" means Haxe searches the installed package's `std/` directory before the official Haxe stdlib for that compile. No files are copied, generated, or renamed at that moment.
- Some Haxe stdlib modules are resolved *very early* (before bootstrap can run). If a `.cross.hx` override must win for those modules, it needs to live on the initial classpath (under `src/`).
  - In rare cases we also use this “early override” pattern for plain `.hx` modules that must work in **both** macro/eval and Elixir target compilation. Those files are dual-mode (`#if macro` implementation, `#else` extern) and live under `src/haxe/**` (example: `src/haxe/ds/BalancedTree.hx`).

When compiling for the `cross` platform, Haxe treats files ending in `.cross.hx` as platform-specific
module implementations. That is, these files participate in normal module resolution while still
being visually distinct from upstream Haxe stdlib sources.

The override root is selective. If Reflaxe.Elixir does not provide a matching module in `std/`
(`Foo.cross.hx`, `Foo.hx`, or a package equivalent), Haxe continues normal classpath resolution and
uses the installed official Haxe stdlib module. Do not copy upstream stdlib files locally just to make
the parity report count smaller; add a local file only when the Elixir target needs a target-specific
implementation, a target-owned API, or a documented early bootstrap exception.

See the full mechanism in docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md

## Reflaxe Skeleton vs This Repository

The upstream Reflaxe skeleton uses a packaging convention:

- author compiler code under `src/`
- author normal API files under `std/`
- author target std overrides under a folder ending in `_std`, such as `std/LANG/_std/`
- run `haxelib run reflaxe build` before publishing to haxelib

During that packaging step, Reflaxe copies all configured std paths into the single published
`classPath`. Files from paths ending in `_std` are copied with a `.cross.hx` extension.

Reflaxe.Elixir uses a different working layout:

- checked-in target overrides already use `.cross.hx`
- `std/` is added to the active Haxe classpath by bootstrap macros for Elixir builds; this is only classpath order, not file copying
- releases are installed by Lix from GitHub tags, not from a generated `_Build/` haxelib package

So do not rename every file to `.cross.hx`, and do not assume adding `haxelib run reflaxe build`
will change the normal repo/test/release path. The file name should describe the role of the file:

- `.cross.hx`: target-specific replacement for an existing Haxe module
- plain `.hx` in `std/`: target-owned public/support API such as `phoenix.*`, `ecto.*`, or `elixir.*`
- plain `.hx` in `src/haxe/**`: rare early dual-mode override that must work in macro/eval and target compilation

## How Are They Loaded? (Target‑Conditional Gating)

We only want the Elixir‑specific overrides when compiling to Elixir. Otherwise, macro tools, unit tests,
or other targets would “see” Elixir‑only code and fail (for example, code using `__elixir__()` would not
exist in JS or macro contexts).

This project implements target‑conditional gating in the compiler bootstrap macros (`CompilerBootstrap.Start()` and `CompilerInit.Start()`):

- When building the Elixir target, `std/` is added early to the active Haxe classpath by
  `CompilerBootstrap.Start()` so
  direct `.cross.hx` overrides and target-owned externs win over the official Haxe stdlib.
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

You’ll also see a few early-resolved overrides under `src/` use it as:

- `#if elixir_output ... #else extern ... #end`

That pattern keeps those modules safe when they are visible to non-Elixir compilation contexts (macros,
JS/genes, tooling), while still providing the correct Elixir implementation when the Elixir backend is active.

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

2) Macros (Compile-time code generation)
- Best for: authoring ergonomics (e.g., HXX authoring), validations, and compile‑time safety.
- Pros: clear authoring UX, early errors.
- Cons: runs in macro context; must avoid target‑only constructs in macro code.

3) AST Transforms (Mid/Late pipeline)
- Best for: structural rewrites based on typed program shape (loops → comprehensions, pattern rewrites, control‑flow normalization, etc.).
- Pros: full view of typed code; expressive and target-aware.
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

- “Leaking” target code into macro/other targets: keep target std overrides under `std/`, which is
  added to the classpath only for Elixir builds.
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

- Haxe Manual: Target-Specific Files — https://haxe.org/manual/lf-target-specific-files.html
- docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md — How `.cross.hx` resolution + target std classpath insertion works
- docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md — Why we gate `.cross.hx` by target and how it’s implemented
- docs/05-architecture/HXX_ARCHITECTURE.md — How HXX authoring flows through the AST pipeline into HEEx (~H)

---

## Removal Criteria & CI Gates (for transitional stubs)

Use this to decide when a transitional stub (like `std/HXX.cross.hx`) can be removed:

- Macro path only: `HXX.hxx()` expands at compile‑time and the builder emits `ESigil("H", ...)` directly (no string→~H conversion)
- Example apps compile and run with only the macro implementation enabled
- Snapshot tests green: verify block HEEx generation, assigns mapping, and control‑tag normalization without relying on string post‑processing
- Control‑tag transforms become no‑ops for macro‑produced content (idempotence check)
- Target‑conditional gating remains in place (no leaks to macro/other targets)

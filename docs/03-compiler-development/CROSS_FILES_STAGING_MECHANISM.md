# Cross Files: `.cross.hx` Resolution + Target-Gated Stdlib Paths

This document is the **mechanical** (compiler-contributor) companion to the beginner guide
in `docs/01-getting-started/cross-hx.md`.

Terminology note: older discussions sometimes say "staging" for this mechanism. In this document,
read that as **prepending package directories to Haxe's active classpath**. It does not mean copying
files, renaming files, or creating a generated package tree during a normal compile.

For the historical reason this repo does not use the generated Reflaxe skeleton `_std` +
`haxelib run reflaxe build` layout, see
`docs/09-history/REFLAXE_LAYOUT_AND_PACKAGING_HISTORY.md`.

It answers four questions:

1) How does Haxe resolve modules from `*.cross.hx` files?
2) What does upstream Reflaxe's `build` packaging command do with std paths?
3) What are `extraParams.hxml`, `CompilerBootstrap.Start()`, and `CompilerInit.Start()` for?
4) How does Reflaxe.Elixir add its target std root to the active classpath without leaking it into
   macros or other targets?

## 1) How `.cross.hx` participates in module resolution

Haxe supports **platform-specific file suffixes** for module resolution. This is a Haxe 4
compiler feature, not a Reflaxe.Elixir convention.

When compiling for a platform named `X`, the compiler can resolve a module `Foo` from:

- `Foo.X.hx` (platform-specific implementation)
- `Foo.hx` (fallback implementation)

Reflaxe targets on **Haxe 4** compile in the `cross` platform mode:

- `target.name = cross`
- the `cross` define is set

That means:

- `Std` can be provided by `Std.cross.hx`
- `haxe.Log` can be provided by `haxe/Log.cross.hx`
- `String` can be provided by `String.cross.hx`

The word `cross` is easy to misread. Here it means Haxe's generic **custom-target platform**,
not "portable across every Haxe target". Reflaxe.Elixir uses that platform because Elixir is not
a built-in Haxe compiler target with its own suffix such as `.js.hx`, `.cpp.hx`, or `.python.hx`.

This repo places these files under `std/` so they can shadow upstream Haxe stdlib modules by
**classpath precedence** when (and only when) the Elixir target is active.

Classpath precedence is not an all-or-nothing stdlib replacement. `std/` is searched before the
official Haxe stdlib, but only modules that actually exist in this repo shadow upstream modules. If
there is no `std/path/Module.cross.hx` or `std/path/Module.hx`, Haxe keeps searching later classpaths
and resolves the module from the installed official Haxe stdlib. That is the intended fallback path
for upstream stdlib code that already compiles and behaves correctly on BEAM.

Important distinction:

- Haxe owns the target-specific file lookup rule.
- Reflaxe owns the custom target framework and, in generated Reflaxe projects, provides a packaging
  helper that can copy/rename target std files into `.cross.hx` form for distribution.
- Reflaxe.Elixir currently keeps its `.cross.hx` overrides checked in directly under `std/` and uses
  bootstrap macros to put that path on the classpath for Elixir builds.

### How to verify which file was selected

Run a compile with verbose output and inspect `Parsed ...` lines:

```bash
npx haxe -v --no-output <your.hxml>
```

In an Elixir build, you should see things like:

- `Parsed .../std/Std.cross.hx`
- `Parsed .../std/StringTools.cross.hx` (and other `.cross.hx` overrides that apply)
- `Parsed .../src/haxe/Exception.cross.hx` (early-resolved override needed before bootstrap can inject `std/`)

Note: some upstream Haxe stdlib modules may still appear as `Parsed .../std/<module>.hx` before
bootstrap runs. If a module must be overridden *that* early for correctness, it should live on the
library `src/` classpath (consumer installs always have `src/` immediately).

Macro typing uses a different platform (eval), so it will *not* select `.cross.hx` files.
Seeing a later `Parsed .../haxe/std/.../Module.hx` line is expected for modules we intentionally
leave to upstream fallback.

## 2) Upstream Reflaxe `build` packaging vs this repo

Upstream Reflaxe projects generated with `haxelib run reflaxe new` usually have multiple source
roots: compiler sources plus one or more std/API roots listed in `haxelib.json` under
`reflaxe.stdPaths`.

`haxelib run reflaxe build` is a packaging step for haxelib distribution. It copies those roots into
the single haxelib `classPath`. For std paths whose folder name ends in `_std`, Reflaxe copies the
files with a `.cross.hx` extension so the published package exposes target-specific overrides on
Haxe's normal target-file mechanism.

Reflaxe.Elixir does not rely on that copy/rename step for normal repo, Lix, or generated-app builds:

- checked-in target overrides already use `.cross.hx` where appropriate
- `extraParams.hxml` and `haxe_libraries/reflaxe.elixir.hxml` invoke our bootstrap/init macros
- `CompilerBootstrap.Start()` prepends `std/` to the active Haxe classpath for Elixir builds

The upstream Reflaxe `_std` convention is packaging input only. This repo does not keep a live
`std/_std` source root; direct `.cross.hx` files under `std/` are the source of truth.

Keeping the `.cross.hx` files checked in is intentional for this repo. It keeps the reviewed source,
the compiled source, source maps, snapshots, and GitHub-tag Lix installs aligned. It also makes the
override boundary explicit: true upstream Haxe replacements use `.cross.hx`; target-owned APIs such as
`phoenix.*`, `ecto.*`, and `elixir.*` remain plain `.hx` files.

Haxelib can support this direct layout. `haxelib.json` can keep `classPath` pointed at `src`, while
`extraParams.hxml` at the package root contributes bootstrap macros when users compile with
`-lib reflaxe.elixir`. Those macros can then add sibling paths such as `std/` from the installed
package root to the active classpath.

The package artifact path is covered by `npm run test:haxelib-package`, which builds a zip from the
tracked source, installs it with `haxelib install <zip>` in a clean temporary project, and proves the
installed package includes `extraParams.hxml`, `std/`, and `vendor/reflaxe/src`. The same smoke compiles
through `-lib reflaxe.elixir` so target classpath insertion is tested from the installed package root.

### Would the Reflaxe skeleton build path need these bootstrap macros?

It depends on what the target package needs.

A simple skeleton-style Reflaxe target may not need a separate classpath-insertion bootstrap macro just
to expose target std overrides, because `haxelib run reflaxe build` copies configured `_std` files into
the published `classPath` as `.cross.hx` files.

It still needs some way to initialize the compiler. Reflaxe targets usually do that with an init macro
from `extraParams.hxml` or from the user's `.hxml`, because Reflaxe must be told which compiler to run
and where to write output.

Reflaxe.Elixir keeps `CompilerBootstrap.Start()` because our package has extra constraints beyond the
basic skeleton:

- `haxelib.json` exposes only `src` as the initial package `classPath`
- `std/` is a sibling package directory that must be added from the installed package root
- stdlib overrides must be inserted before the official Haxe stdlib in classpath order
- `vendor/reflaxe/src` must be visible for the patched vendored Reflaxe framework

So the skeleton build path can reduce the need for this exact classpath-insertion macro in simpler packages, but it
does not remove the need for compiler initialization, and it would not automatically satisfy this repo's
current layout and gating rules.

## 3) What `extraParams.hxml` is

`extraParams.hxml` is a haxelib/lix package hook. When a user compiles with:

```hxml
-lib reflaxe.elixir
```

Haxe loads the package from `haxelib.json`, puts the package `classPath` (`src`) on the classpath, and
also includes the package-root `extraParams.hxml`.

In this repo, `extraParams.hxml` deliberately contains no relative `-cp src` or `-cp std` lines. HXML
paths are resolved from the consumer project's current working directory, so relative package paths
there would point at the user's project, not at the installed library. Instead, `extraParams.hxml` only
does cwd-independent setup:

```hxml
--macro reflaxe.elixir.CompilerBootstrap.Start()
--macro reflaxe.elixir.CompilerInit.Start()
-D loop_unroll_max_cost=0
```

For repo-local scoped-lib builds, `haxe_libraries/reflaxe.elixir.hxml` plays the same role, but it can
use `${SCOPE_DIR}` because Lix expands that to this repository's library root.

## 4) What the bootstrap/init macros do

`CompilerBootstrap.Start()` is the early package-layout macro.

It:

- resolves `reflaxe/elixir/CompilerBootstrap.hx` to find the installed package root
- prepends `vendor/reflaxe/src` so consumers use the patched vendored Reflaxe framework
- detects Elixir builds using `-D elixir_output`, Haxe 5 custom target metadata, or Haxe 4 `cross`
  platform fallback
- for Elixir builds, prepends `std/`
- inserts these paths at the front of the classpath so our overrides win over the official Haxe stdlib

Plain English version: after bootstrap runs, Haxe looks in this package's `std/` directory before it
looks in the installed Haxe stdlib. If a module exists locally, the local module wins for that
compile. If it does not exist locally, Haxe keeps searching and uses the official stdlib module.

`CompilerInit.Start()` is the compiler-registration macro.

It:

- calls Reflaxe initialization
- registers `ElixirCompiler` with output define `elixir_output`
- installs global metadata and framework preservers
- enables strict/boundary checks and AST prepasses

Keep the split:

- bootstrap owns package-root discovery and target-conditional classpath insertion
- init owns compiler registration and compiler behavior

## 5) Target-conditional classpath injection

Some older notes call this "classpath staging." In this repo that only means
**target-conditional classpath insertion**, not file copying or generated package
output:

- In consumer projects, `extraParams.hxml` (loaded via `-lib reflaxe.elixir`) invokes:
  - `reflaxe.elixir.CompilerBootstrap.Start()`
  - `reflaxe.elixir.CompilerInit.Start()`
- In this repository’s own test/examples harness (scoped libs via `haxe_libraries/*.hxml`),
  `haxe_libraries/reflaxe.elixir.hxml` also invokes `CompilerBootstrap.Start()` so local builds
  behave like consumer installs (stdlib overrides are present early).
- Those macros detect an Elixir build (Haxe 4: `-D elixir_output=...`; Haxe 5: custom target)
  and then add `std/` (externs + `.cross.hx` overrides).

Important detail (Haxe 4 / `cross`)
- Reflaxe targets compile under the `cross` platform on Haxe 4.
- When `CompilerBootstrap.Start()` is invoked from a library `.hxml` (via `-lib ...`), it can run
  before downstream `-D elixir_output=...` arguments are observed by macro code.
- For that reason, the bootstrap treats `platform == cross` as an early “this is a Reflaxe build”
  signal, and uses `-D elixir_output=...` as a secondary confirmation where available.

### Why `elixir_output` shows up inside some `.cross.hx` files

Most target-specific code is hidden from other contexts by classpath gating (`std/` is added to the
active classpath only for Elixir builds). However, a small set of overrides must live on the library `src/` classpath
so consumer installs resolve them *before* bootstrap macros run (example: `src/haxe/Exception.cross.hx`).

Because `src/` is visible in more situations (tools, JS/genes builds, etc.), those early overrides often use:

- `#if elixir_output ... #else extern ... #end`

This ensures they only emit Elixir-specific implementations (including `__elixir__()` injections) when the
Elixir backend is actually active, while remaining harmless type surfaces elsewhere.

Implementation:

- `src/reflaxe/elixir/CompilerBootstrap.hx`
- `src/reflaxe/elixir/CompilerInit.hx`

More context: `docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md`.

## 6) Practical guidance (when adding/adjusting stdlib)

- Prefer `std/**/*.cross.hx` when you are replacing a well-known Haxe API with an idiomatic Elixir mapping.
- Keep plain `std/**/*.hx` for target-owned APIs/support modules and documented exceptions; do not rename
  everything just because it lives under `std/`.
- Leave a module absent from local `std/` when upstream Haxe stdlib is already the right implementation;
  track that decision with tests/docs instead of copying the upstream source.
- Do not add repo-level classpaths like `../../std` to JS/genes builds; use `-lib` and library-provided hxml instead.

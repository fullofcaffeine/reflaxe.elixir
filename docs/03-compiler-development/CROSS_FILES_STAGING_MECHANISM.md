# Cross Files: `.cross.hx` Resolution + Target-Gated Stdlib Paths

This document is the **mechanical** (compiler-contributor) companion to the beginner guide
in `docs/01-getting-started/cross-hx.md`.

Terminology note: older discussions sometimes say "staging" for this mechanism. In this document,
read that as **prepending package directories to Haxe's active classpath**. It does not mean copying
files, renaming files, or creating a generated package tree during a normal compile.

For the historical reason this repo now uses the generated Reflaxe skeleton `_std` source layout
while still supporting GitHub/Lix installs directly from the source tree, see
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

In this source tree, upstream-colliding Elixir stdlib overrides are authored as plain `.hx` files
under `std/elixir/_std/**`. Reflaxe package builds turn those authored files into packaged
`.cross.hx` files. Repo-local and GitHub/Lix builds do not copy files during compilation; instead,
bootstrap prepends `std/elixir/_std/` only for Elixir builds, so those plain `.hx` overrides shadow
upstream Haxe stdlib modules by **classpath precedence**.

Classpath precedence is not an all-or-nothing stdlib replacement. `std/elixir/_std/` is searched
before the official Haxe stdlib for Elixir builds, but only modules that actually exist in this repo
shadow upstream modules. If there is no `std/elixir/_std/path/Module.hx`, Haxe keeps searching later
classpaths and resolves the module from the installed official Haxe stdlib. That is the intended
fallback path for upstream stdlib code that already compiles and behaves correctly on BEAM.

Important distinction:

- Haxe owns the target-specific file lookup rule.
- Reflaxe owns the custom target framework and provides the packaging helper that copies configured
  `_std` source roots into `.cross.hx` form for distribution.
- Reflaxe.Elixir now follows that authored-source convention for stdlib overrides while still using
  bootstrap macros to put the source root on the classpath for source-tree/GitHub/Lix builds.

### How to verify which file was selected

Run a compile with verbose output and inspect `Parsed ...` lines:

```bash
npx haxe -v --no-output <your.hxml>
```

In an Elixir build, you should see things like:

- `Parsed .../std/elixir/_std/Std.hx`
- `Parsed .../std/elixir/_std/StringTools.hx` (and other authored std overrides that apply)
- `Parsed .../src/haxe/Exception.cross.hx` (early-resolved override needed before bootstrap can inject `std/`)

Note: some upstream Haxe stdlib modules may still appear as `Parsed .../std/<module>.hx` before
bootstrap runs. If a module must be overridden *that* early for correctness, it should live on the
library `src/` classpath (consumer installs always have `src/` immediately).

Macro typing uses a different platform (eval), so it will *not* select `.cross.hx` files.
Seeing a later `Parsed .../haxe/std/.../Module.hx` line is expected for modules we intentionally
leave to upstream fallback.

## 2) Upstream Reflaxe `build` packaging and this repo

Upstream Reflaxe projects generated with `haxelib run reflaxe new` usually have multiple source
roots: compiler sources plus one or more std/API roots listed in `haxelib.json` under
`reflaxe.stdPaths`.

`haxelib run reflaxe build` is a packaging step for haxelib distribution. It copies those roots into
the single haxelib `classPath`. For std paths whose folder name ends in `_std`, Reflaxe copies the
files with a `.cross.hx` extension so the published package exposes target-specific overrides on
Haxe's normal target-file mechanism.

Reflaxe.Elixir follows that source convention for upstream-colliding stdlib overrides:

- authored std overrides live in `std/elixir/_std/**/*.hx`
- target-owned APIs and support modules live in `std/**/*.hx`
- `extraParams.hxml` and `haxe_libraries/reflaxe.elixir.hxml` invoke bootstrap/init macros
- `CompilerBootstrap.Start()` prepends `std/elixir/_std/`, then `std/`, to the active Haxe classpath
  for Elixir builds

The Reflaxe `_std` convention is still packaging input. Normal repo, GitHub-tag, and Lix builds do
not run `haxelib run reflaxe build` before each compile; bootstrap makes the authored `_std` files
visible directly. A Reflaxe package build can still materialize packaged `.cross.hx` files from the
same authored source.

This keeps the source tree close to a fresh Reflaxe target while preserving source-tree installs and
the explicit ownership boundary: upstream Haxe replacements live under `_std`; target-owned APIs such
as `phoenix.*`, `ecto.*`, and `elixir.*` remain plain `.hx` files under `std/`.

Haxelib can support this source layout. `haxelib.json` can keep `classPath` pointed at `src`, while
`extraParams.hxml` at the package root contributes bootstrap macros when users compile with
`-lib reflaxe.elixir`. Those macros can then add sibling paths such as `std/elixir/_std/` and `std/`
from the installed package root to the active classpath.

The package artifact path is covered by `npm run test:haxelib-package`, which runs
`scripts/release/package-haxelib.sh`, installs the generated zip with `haxelib install <zip>` in a
clean temporary project, and proves the installed package has the Reflaxe-flattened layout:
`stdPaths` are merged into `src/`, `_std` overrides appear as packaged `.cross.hx` files, and vendored
framework roots remain available beside `src/`. The same smoke compiles through `-lib reflaxe.elixir`
so target classpath insertion is tested from the installed package root.

### Would the Reflaxe skeleton build path need these bootstrap macros?

It depends on what the target package needs.

A simple skeleton-style Reflaxe target may not need a separate classpath-insertion bootstrap macro just
to expose target std overrides from a generated haxelib package, because `haxelib run reflaxe build`
copies configured `_std` files into the published `classPath` as `.cross.hx` files.

It still needs some way to initialize the compiler. Reflaxe targets usually do that with an init macro
from `extraParams.hxml` or from the user's `.hxml`, because Reflaxe must be told which compiler to run
and where to write output.

Reflaxe.Elixir keeps `CompilerBootstrap.Start()` because our package has extra constraints beyond the
basic skeleton:

- `haxelib.json` exposes only `src` as the initial package `classPath`
- `std/elixir/_std/` and `std/` are source-tree/GitHub/Lix roots that must be added from the installed
  source package root when the package has not been flattened by Reflaxe build
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
--macro nullSafety("reflaxe.elixir")
--macro reflaxe.elixir.CompilerBootstrap.Start()
--macro reflaxe.elixir.CompilerInit.Start()
-D loop_unroll_max_cost=0
```

The null-safety macro is scoped to the compiler package (`reflaxe.elixir`), matching Reflaxe-generated
target entrypoints without applying null-safety metadata to user application packages.
For repo-local scoped-lib builds, `haxe_libraries/reflaxe.elixir.hxml` plays the same role, but it can
use `${SCOPE_DIR}` because Lix expands that to this repository's library root.

## 4) What the bootstrap/init macros do

`CompilerBootstrap.Start()` is the early package-layout macro.

It:

- resolves `reflaxe/elixir/CompilerBootstrap.hx` to find the installed package root
- prepends `vendor/reflaxe/src` so consumers use the patched vendored Reflaxe framework
- detects Elixir builds using `-D elixir_output`, Haxe 5 custom target metadata, or Haxe 4 `cross`
  platform fallback
- for Elixir builds, prepends `std/elixir/_std/`, then `std/`
- inserts these paths at the front of the classpath so our overrides win over the official Haxe stdlib

Plain English version: after bootstrap runs, Haxe looks in this package's Elixir std override root
before it looks in the installed Haxe stdlib. If a module exists locally, the local module wins for
that compile. If it does not exist locally, Haxe keeps searching and uses the official stdlib module.

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
  and then add `std/elixir/_std/` (authored std overrides) plus `std/` (target-owned APIs/support).

Important detail (Haxe 4 / `cross`)
- Reflaxe targets compile under the `cross` platform on Haxe 4.
- When `CompilerBootstrap.Start()` is invoked from a library `.hxml` (via `-lib ...`), it can run
  before downstream `-D elixir_output=...` arguments are observed by macro code.
- For that reason, the bootstrap treats `platform == cross` as an early “this is a Reflaxe build”
  signal, and uses `-D elixir_output=...` as a secondary confirmation where available.

### Why `elixir_output` shows up inside some `.cross.hx` files

Most target-specific code is hidden from other contexts by classpath gating (`std/elixir/_std/` and
`std/` are added to the active classpath only for Elixir builds). However, a small set of overrides
must live on the library `src/` classpath so consumer installs resolve them *before* bootstrap macros
run.

`src/haxe/Exception.cross.hx` is intentionally the lone source-tree `.cross.hx` file in that early
set. Upstream `haxe.Exception` is extern, so macro/eval and non-cross targets can keep resolving the
official stdlib file. The Elixir target needs a concrete emitted base module for exception structs,
so the early `.cross.hx` file provides that implementation only when `elixir_output` is active.
`npm run guard:stdlib-layout` enforces that this remains the only checked-in `src/**/*.cross.hx`
source file; ordinary target-specific std replacements should stay under `std/elixir/_std/**/*.hx`
and be materialized as packaged `.cross.hx` files by Reflaxe build.

Because `src/` is visible in more situations (tools, JS/genes builds, etc.), those early overrides often use:

- `#if elixir_output ... #else extern ... #end`

This ensures they only emit Elixir-specific implementations (including `__elixir__()` injections) when the
Elixir backend is actually active, while remaining harmless type surfaces elsewhere.

The plain `.hx` early overrides under `src/haxe/ds/**` are the other side of the same constraint:
they must be visible to macro/eval when Haxe needs constructors or WAE-safe stdlib surfaces before
target std insertion can run. See `docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md` for the
current inventory and ownership rules.

Implementation:

- `src/reflaxe/elixir/CompilerBootstrap.hx`
- `src/reflaxe/elixir/CompilerInit.hx`

More context: `docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md`.

## 6) Practical guidance (when adding/adjusting stdlib)

- Prefer `std/elixir/_std/**/*.hx` when you are replacing a well-known Haxe API with an idiomatic
  Elixir mapping. Reflaxe build turns these authored files into packaged `.cross.hx` files.
- Keep plain `std/**/*.hx` for target-owned APIs/support modules and documented exceptions; do not put
  upstream-colliding stdlib replacements directly under `std/`.
- Leave a module absent from local `std/` when upstream Haxe stdlib is already the right implementation;
  track that decision with tests/docs instead of copying the upstream source.
- Do not add repo-level classpaths like `../../std` to JS/genes builds; use `-lib` and library-provided hxml instead.

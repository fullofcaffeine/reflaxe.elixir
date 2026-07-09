# Reflaxe Layout and Packaging History

This is a historical/contributor note. For the current mechanical rules, see:

- [Cross Files: `.cross.hx` Resolution + Target-Gated Stdlib Paths](../03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md)
- [Standard Library Handling](../04-api-reference/STANDARD_LIBRARY_HANDLING.md)
- [Target-Conditional Stdlib Gating](../05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md)

## Summary

Reflaxe.Elixir now follows the important Reflaxe source-layout convention for target stdlib
overrides, while keeping bootstrap support for normal source-tree, GitHub-tag, and Lix development.
The normal development path does not run `haxelib run reflaxe build` before every compile.

The important practical difference is stdlib packaging:

- A typical Reflaxe skeleton authors target std overrides as plain `.hx` files under a configured
  `_std` source root, then uses `haxelib run reflaxe build` to copy/rename them into final
  `.cross.hx` files for publishing.
- This repo now authors upstream-colliding stdlib overrides under `std/elixir/_std/**/*.hx`, and
  uses bootstrap macros to add that source root from the installed package root to the active Haxe
  classpath for source-tree/GitHub/Lix Elixir builds.

That keeps Reflaxe-style authored std sources while still supporting direct source-tree consumption
without requiring a generated `_Build/` package in the edit/test loop.

## Why This Repo Differs

This repo evolved around GitHub-tag/Lix consumption, repo-local examples, generated-output snapshots,
and a vendored Reflaxe framework. Earlier versions kept direct, checked-in `.cross.hx` files under
`std/` so the reviewed source and compiled source were identical.

The current layout moves those upstream-colliding stdlib overrides into `std/elixir/_std/**/*.hx`.
That matches the Reflaxe skeleton convention and sibling compiler layouts more closely. The tradeoff
is that source-tree builds need bootstrap classpath insertion for `_std`, while packaged Reflaxe builds
can still materialize `.cross.hx` files.

The current layout optimizes for:

- reviewed source following Reflaxe conventions
- stable source-map and snapshot paths
- GitHub-tag/Lix installs consuming the same files tested in the repo
- explicit ownership: upstream Haxe stdlib replacements live under `_std`; target-owned APIs stay plain `.hx`
- no generated packaging directory that can drift from the source tree during normal development

This is a repository convention, not a Haxe language requirement. Haxe owns the `.cross.hx` lookup
rule; Reflaxe's skeleton build step is one way to produce files in that shape for haxelib packages.

## Typical Reflaxe Skeleton Flow

A project generated from the usual Reflaxe skeleton generally has:

```text
src/                  compiler implementation
std/                  normal target/user API files
some_target/_std/     target stdlib override inputs
haxelib.json          reflaxe.stdPaths lists the roots to package
```

Before publishing, the package author runs:

```bash
haxelib run reflaxe build
```

That build step copies configured std paths into the package classpath. Files under roots ending in
`_std` are copied with a `.cross.hx` extension so Haxe can select them through its normal
target-specific file mechanism when compiling for the Reflaxe `cross` platform.

In that model, the source tree and published package tree are intentionally different.

## Reflaxe.Elixir Flow

Reflaxe.Elixir keeps:

```text
src/                  compiler source, bootstrap macros, early dual-mode overrides
std/elixir/_std/      authored Elixir stdlib overrides; Reflaxe build packages these as .cross.hx
std/                  target-owned APIs and support modules
vendor/reflaxe/src    vendored Reflaxe framework used by this compiler
extraParams.hxml      haxelib/lix hook that runs bootstrap/init macros
```

When a consumer compiles with:

```hxml
-lib reflaxe.elixir
```

Haxe loads `haxelib.json`, puts the package `classPath` (`src`) on the initial classpath, and includes
`extraParams.hxml`. `extraParams.hxml` runs:

```hxml
--macro reflaxe.elixir.CompilerBootstrap.Start()
--macro reflaxe.elixir.CompilerInit.Start()
```

`CompilerBootstrap.Start()` resolves the installed package root from its own source path, then
prepends package-root-relative directories to the active Haxe classpath. This is classpath insertion,
not file copying or generation. The directories are:

- `std/elixir/_std/` for Elixir builds, so authored stdlib overrides are visible in source-tree installs.
- `std/` for Elixir builds, so target-owned APIs and support modules are visible.
- `vendor/reflaxe/src`, so consumers use the vendored Reflaxe framework expected by this compiler.

The repo-local `haxe_libraries/reflaxe.elixir.hxml` provides an equivalent scoped-library path for
tests and examples in this repository.

### Terminology: "staging"

Older notes sometimes say the bootstrap macro "stages" `std/` or `vendor/reflaxe/src`. In this repo,
that word should be read narrowly as "adds this package directory to the current Haxe classpath before
type resolution continues." It does not mean copying files, generating a `_Build` directory, or
renaming source files. Prefer "prepends to the classpath" in new docs and code comments.

The practical effect is simple: for the current compile, Haxe checks the added package directory
earlier. A local override wins when it exists; otherwise Haxe continues to the official Haxe stdlib.

## Stdlib Handling

Both approaches rely on the same Haxe resolver behavior:

- `Module.cross.hx` is selected for the Haxe 4 `cross` platform used by Reflaxe targets.
- `Module.hx` remains the fallback if no target-specific file exists.
- Classpath order decides which root is searched first.

The difference is how the `.cross.hx` files get there:

| Topic | Reflaxe skeleton build | Reflaxe.Elixir current repo |
| --- | --- | --- |
| Target std override authoring | Plain `.hx` under `_std` input roots | Plain `.hx` under `std/elixir/_std/` |
| Packaging step | `haxelib run reflaxe build` copies/renames | Source-tree builds use bootstrap; package builds can copy/rename |
| Published source path | Generated package layout | GitHub/Lix installs consume checked-in source layout directly |
| Source maps/snapshots | May point at generated package paths | Source-tree builds point at `std/elixir/_std/**` |
| Missing std modules | Fall through to official Haxe stdlib | Fall through to official Haxe stdlib |
| Target-owned APIs | Plain `.hx` in configured std roots | Plain `.hx` under `std/` (`elixir.*`, `phoenix.*`, `ecto.*`) |

In this repo, absence from local `std/elixir/_std/` is meaningful. If a module is not present locally,
Haxe keeps searching later classpaths and resolves it from the installed official Haxe stdlib. Do not
copy an unchanged upstream stdlib module into this repo just to reduce the parity gap.

## Pros and Cons

Source-tree `_std` layout:

- Pro: matches the generated Reflaxe skeleton and sibling compiler conventions more closely.
- Pro: target overrides are grouped away from target-owned APIs/support modules.
- Pro: GitHub/Lix installs and repo-local tests still consume the checked-in source layout directly.
- Con: bootstrap must prepend `std/elixir/_std/` in source-tree/dev mode so the authored files win over
  the official Haxe stdlib.
- Con: source-tree source maps reference `_std` paths, while a generated package may reference packaged
  `.cross.hx` paths.

Skeleton `_std` plus `reflaxe build`:

- Pro: follows the generated Reflaxe project convention.
- Pro: haxelib packaging gets a curated, flattened classpath layout.
- Pro: authors can write input files as plain `.hx` and let packaging produce `.cross.hx`.
- Con: source files and published files are different, which can obscure source-map and snapshot paths.
- Con: normal development must distinguish authored sources from generated package output.
- Con: generated-package validation is separate from source-tree validation.

## Consumption Paths

Current supported path:

- GitHub tag + Lix install.
- Consumers use `-lib reflaxe.elixir`.
- `extraParams.hxml` runs bootstrap/init macros.
- Bootstrap prepends `std/elixir/_std/`, `std/`, and `vendor/reflaxe/src` from the installed package
  root to the active Haxe classpath.

Repo-local path:

- Tests/examples use scoped library files under `haxe_libraries/`.
- `haxe_libraries/reflaxe.elixir.hxml` points at this checkout using `${SCOPE_DIR}`.
- It also invokes bootstrap/init so local behavior matches consumer installs.

Haxelib.org package artifact path:

- Is validated from the generated package artifact, not just the working tree.
- The package is built with `scripts/release/package-haxelib.sh`, which delegates `stdPaths`
  flattening to Reflaxe build.
- The package must include `extraParams.hxml`, flattened `src/**/*.cross.hx` std overrides, and
  vendored framework roots such as `vendor/reflaxe/src` and `vendor/phoenix_shared/src`.
- The package must not include a top-level `std/`; source std roots are packaging input, not package
  output.
- A clean temp consumer project must compile with `-lib reflaxe.elixir` and no repo-local classpaths.
- Run `npm run test:haxelib-package` to build the zip, install it into an isolated haxelib repo, and
  compile the smoke fixture.

## Verdict

Use `std/elixir/_std/**/*.hx` for upstream-colliding stdlib overrides. Do not add new checked-in
`std/**/*.cross.hx` files for ordinary stdlib work. Keep plain `std/**/*.hx` for target-owned
APIs/support modules that do not replace upstream Haxe std namespaces; BEAM `sys.*` implementations
belong under `std/elixir/_std/sys/**`. Keep rare early overrides under `src/haxe/**` only when
bootstrap timing requires it.

Before publishing to haxelib.org, run the package smoke described above. That validates the exact
artifact users would install.

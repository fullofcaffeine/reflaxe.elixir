# Reflaxe Layout and Packaging History

This is a historical/contributor note. For the current mechanical rules, see:

- [Cross Files: `.cross.hx` Resolution + Target-Gated Stdlib Paths](../03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md)
- [Standard Library Handling](../04-api-reference/STANDARD_LIBRARY_HANDLING.md)
- [Target-Conditional Stdlib Gating](../05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md)

## Summary

Reflaxe.Elixir is not laid out like a fresh project created by `haxelib run reflaxe new`, and the
normal development/release path does not run `haxelib run reflaxe build`.

The important practical difference is stdlib packaging:

- A typical Reflaxe skeleton can author target std overrides as plain `.hx` files under a configured
  `_std` source root, then use `haxelib run reflaxe build` to copy/rename them into final
  `.cross.hx` files for publishing.
- This repo keeps the final `.cross.hx` files checked in directly under `std/`, then uses bootstrap
  macros to add `std/` from the installed package root to the active Haxe classpath for Elixir builds.

That means this repo is "post-build style" for target std override filenames, but it is still a
source-layout compiler repository overall.

## Why This Repo Differs

This repo evolved around GitHub-tag/Lix consumption, repo-local examples, generated-output snapshots,
and a vendored Reflaxe framework. Those constraints made direct, checked-in `.cross.hx` files simpler
than keeping a separate `_std` input tree and generated `_Build` output.

The current layout optimizes for:

- reviewed source matching compiled source
- stable source-map and snapshot paths
- GitHub-tag/Lix installs consuming the same files tested in the repo
- explicit ownership: upstream Haxe stdlib replacements use `.cross.hx`; target-owned APIs stay plain `.hx`
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
std/                  target-owned APIs and checked-in direct .cross.hx std overrides
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

- `std/` for Elixir builds, so direct `.cross.hx` overrides and target-owned APIs are visible.
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
| Target std override authoring | Plain `.hx` under `_std` input roots | Direct `.cross.hx` under `std/` |
| Packaging step | `haxelib run reflaxe build` copies/renames | No normal copy/rename step |
| Published source path | Generated package layout | Same checked-in file path for Lix/GitHub tag installs |
| Source maps/snapshots | May point at generated package paths | Point at reviewed source files |
| Missing std modules | Fall through to official Haxe stdlib | Fall through to official Haxe stdlib |
| Target-owned APIs | Plain `.hx` in configured std roots | Plain `.hx` under `std/` (`elixir.*`, `phoenix.*`, `ecto.*`) |

In this repo, absence from local `std/` is meaningful. If a module is not present locally, Haxe keeps
searching later classpaths and resolves it from the installed official Haxe stdlib. Do not copy an
unchanged upstream stdlib module into this repo just to reduce the parity gap.

## Pros and Cons

Direct checked-in `.cross.hx` files:

- Pro: source review, source maps, snapshots, and Lix installs all refer to the same files.
- Pro: no generated `_Build` tree to remember during normal development.
- Pro: it makes target overrides visually explicit in the working tree.
- Con: contributors must understand that this repo intentionally does not mirror the skeleton `_std`
  authoring convention.
- Con: haxelib.org publishing needs an explicit package smoke because we do not get the skeleton
  build layout validation automatically.

Skeleton `_std` plus `reflaxe build`:

- Pro: follows the generated Reflaxe project convention.
- Pro: haxelib packaging gets a curated, flattened classpath layout.
- Pro: authors can write input files as plain `.hx` and let packaging produce `.cross.hx`.
- Con: source files and published files are different, which can obscure source-map and snapshot paths.
- Con: normal development must distinguish authored sources from generated package output.
- Con: adopting it now would add a second layout to maintain without changing Haxe module semantics.

## Consumption Paths

Current supported path:

- GitHub tag + Lix install.
- Consumers use `-lib reflaxe.elixir`.
- `extraParams.hxml` runs bootstrap/init macros.
- Bootstrap prepends `std/` and `vendor/reflaxe/src` from the installed package root to the active
  Haxe classpath.

Repo-local path:

- Tests/examples use scoped library files under `haxe_libraries/`.
- `haxe_libraries/reflaxe.elixir.hxml` points at this checkout using `${SCOPE_DIR}`.
- It also invokes bootstrap/init so local behavior matches consumer installs.

Future haxelib.org path:

- Should be validated from the exact submitted package artifact, not just the working tree.
- The package must include `extraParams.hxml`, `std/`, and `vendor/reflaxe/src`.
- A clean temp consumer project must compile with `-lib reflaxe.elixir` and no repo-local classpaths.

Tracked follow-up:

- `haxe.elixir.codex-8yh`: Packaging smoke: validate haxelib zip layout.

## Verdict

Do not add `haxelib run reflaxe build` to the normal Reflaxe.Elixir development flow just to match the
skeleton convention. The direct `.cross.hx` layout is acceptable and clearer for the current Lix/GitHub
release path.

Before publishing to haxelib.org, add and run the package smoke described above. That validates this
repo's direct layout in the exact artifact users would install.

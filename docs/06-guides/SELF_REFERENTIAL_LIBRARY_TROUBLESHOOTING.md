# Self-Referential Library Configuration (Contributor Guide)

This document explains how Reflaxe.Elixir’s tests and examples compile Haxe code using `-lib reflaxe.elixir` **while developing `reflaxe.elixir` itself**.

Most end-users installing from GitHub release tags will never need this. It primarily matters for:
- contributors working inside this repository
- CI runs that compile “toy projects” against the in-repo compiler

## The core challenge

Haxe libraries are normally consumed from an installed location. In this repo, tests need to compile with the *local* compiler source via `-lib reflaxe.elixir`, which is inherently self-referential.

## How it works in this repo

There are two configurations:

### 1) Repo-local development config

File: `haxe_libraries/reflaxe.elixir.hxml`

- Used whenever you compile Haxe (in this repo) with `-lib reflaxe.elixir`.
- Points `-cp` to the repo’s `src/` and `std/`.
- Uses `${SCOPE_DIR}` because the preferred Haxe entrypoint for development is the lix-managed shim at `node_modules/.bin/haxe`, which sets `SCOPE_DIR`.

### 2) Test/temp-project config (for Mix + ExUnit)

Files:
- `test/support/haxe_test_helper.ex` (creates temp projects)
- `test/support/test_reflaxe_elixir.hxml` (template copied into temp `haxe_libraries/`)

The helper:
- sets `REFLAXE_ELIXIR_PROJECT_ROOT` to the repo root
- copies `test/support/test_reflaxe_elixir.hxml` into the temp project as `haxe_libraries/reflaxe.elixir.hxml`
- copies the base `reflaxe` library into the temp project’s `haxe_libraries/` (needed for `-lib reflaxe`)

This avoids symlinking the entire compiler source tree into the temp project (which can cause “compiled the whole compiler” surprises).

## Path resolution rules

**Important**: paths in `.hxml` files are resolved from the Haxe process **current working directory** (CWD), not from the `.hxml` file location.

In Mix integration, we intentionally run Haxe with `cd: Path.dirname(hxml_file)` so that relative paths in a project’s `build.hxml` keep working. See `lib/haxe_compiler.ex`.

## Variable substitution in `.hxml`

Use `${ENV_VAR}` (with braces). Haxe expands these inside `.hxml` files:

```hxml
-cp ${SCOPE_DIR}/src/
-cp ${REFLAXE_ELIXIR_PROJECT_ROOT}/src/
```

Do **not** use `$ENV_VAR` (without braces) — it will be treated as a literal path and compilation will fail.

## Common errors

### Error: "Library reflaxe.elixir is not installed"

Meaning: Haxe cannot locate `haxe_libraries/reflaxe.elixir.hxml` (or your `HAXELIB_PATH` is pointing elsewhere).

Checks:
- When working in this repo, prefer `node_modules/.bin/haxe` so scoped libs resolve correctly.
- In tests, ensure you use `HaxeTestHelper.setup_test_project/1` (it sets `HAXELIB_PATH` and writes the test config).

### Error: "classpath ... is not a directory or cannot be read from"

Meaning: a `-cp` entry in an `.hxml` expanded to a path that doesn’t exist.

Common causes:
- `REFLAXE_ELIXIR_PROJECT_ROOT` isn’t set (or points at the wrong directory)
- you’re compiling with the wrong CWD and relying on relative paths that no longer resolve

### Error: "Type not found : ..."

Meaning: your `-cp` set doesn’t include the file, or package paths don’t match folders.

Rule of thumb: `package foo.bar;` must live at `foo/bar/SomeFile.hx` under a classpath.

## Debugging tips

- Run with verbose logging:
  - Mix: `mix compile.haxe --verbose`
  - Haxe: `haxe -v build.hxml` (from the project directory)
- Confirm which `haxe` binary Mix is using (the lix shim is preferred): see `get_haxe_command/0` in `lib/haxe_compiler.ex`.

## Related docs

- Testing infrastructure overview: `docs/03-compiler-development/TESTING_INFRASTRUCTURE.md`
- End-user troubleshooting: `docs/06-guides/TROUBLESHOOTING.md`

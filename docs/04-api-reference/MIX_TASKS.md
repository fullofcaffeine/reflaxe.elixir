# Mix Tasks Reference

Complete reference for all Mix tasks provided by Reflaxe.Elixir for compilation, debugging, and development workflows.

> [!NOTE]
> This is a **reference/advanced** doc. Many commands are safe to copy/paste, but not every snippet is CI-smoked.
> The core compile path is exercised by the repo’s Mix integration tests and the todo-app QA sentinel; long-running commands
> (like `mix haxe.watch`) are intentionally **not** run in CI.

## Table of Contents
1. [Authoring Custom Mix Tasks in Haxe (Optional)](#authoring-custom-mix-tasks-in-haxe-optional)
2. [Compilation Tasks](#compilation-tasks)
3. [Source Mapping Tasks](#source-mapping-tasks)
4. [Debugging Tasks](#debugging-tasks)
5. [Development Tasks](#development-tasks)
6. [Generation Tasks](#generation-tasks)
7. [Migration Tasks](#migration-tasks)
8. [Task Options & Flags](#task-options--flags)
9. [Examples & Workflows](#examples--workflows)

## Authoring Custom Mix Tasks in Haxe (Optional)

Reflaxe.Elixir can generate an ordinary Mix task from a typed Haxe class with
`@:mixTask`. Use this when Haxe ownership improves shared types, completion, or
compiler dogfooding. It does not replace Elixir as an application language:
handwritten `.ex` tasks remain first-class, and a project can freely mix both.

Haxe input:

```haxe
package;

/** Reports compiler status from a Haxe-authored task. */
@:mixTask({
  shortdoc: "Reports compiler status",
  requirements: ["app.config"]
})
@:native("Mix.Tasks.Haxe.Status")
class StatusTask {
  public static function run(args:Array<String>):Int {
    return args.length;
  }
}
```

Generated target shape:

```elixir
defmodule Mix.Tasks.Haxe.Status do
  @moduledoc """
  Reports compiler status from a Haxe-authored task.
  """

  use Mix.Task

  @shortdoc "Reports compiler status"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    length(args)
  end
end
```

The generated module is normal Elixir: Mix discovers it by its `Mix.Tasks.*`
name, Elixir modules can call it, and Haxe-authored code can call handwritten
Elixir through typed externs. The compiler does not inject task-specific runtime
code or require Haxe when an already-generated task executes.

Use direct Elixir instead when it is the clearest application-owned choice. The
repository's Haxe-first rule is a contributor dogfooding policy for
Reflaxe.Elixir-owned tooling, not a downstream restriction.

See [`@:mixTask` in the annotation reference](ANNOTATIONS.md#mixtask---optional-haxe-authored-mix-task)
for the exact signature and literal-option contract.

## Compilation Tasks

### mix compile.haxe

Primary compilation task for Haxe→Elixir transpilation.

```bash
# Basic compilation
mix compile.haxe

# Long-running watch (keeps the Mix VM alive)
mix haxe.watch

# With verbose output
mix compile.haxe --verbose

# Force recompilation
mix compile.haxe --force
```

**Options:**
- `--verbose` - Show detailed compilation output
- `--force` - Force full recompilation (ignore cache)
- `--no-watch` - Disable auto-watching in long-running Mix (e.g., under `mix phx.server`)

**Environment Variables:**
- `MIX_QUIET=1` - Suppress all output except errors
- `HAXE_PATH=/path/to/haxe` - Use an explicit Haxe command instead of project/PATH discovery
- `HAXELIB_CMD=/path/to/haxelib` - Use an explicit `haxelib` command for library resolution
- `HAXE_SERVER_PORT=6116` - Preferred port for the Haxe compilation server (default: 6116). If the port is busy, the server relocates unless attach is explicitly enabled.
- `HAXE_SERVER_ALLOW_ATTACH=1` - Allow attaching to an externally-started compatible `haxe --wait` server (including a prior compatible server recorded in the cookie) (default: off)
- `HAXE_SERVER_AUTOSTART=dev|always|never` - Opt a caller into automatic `haxe --wait` startup (default: `never`; `mix haxe.watch` starts its own server)
- `HAXE_NO_SERVER=1` - Disable the Haxe `--wait` server and compile directly
- `HAXE_NO_COMPILE=1` - Skip Haxe compilation entirely (useful for CI/sentinels)

**Mix configuration:**

```elixir
def project do
  [
    compilers: [:haxe] ++ Mix.compilers(),
    haxe: [
      hxml_file: "build-server.hxml",
      source_dir: "src_haxe",
      target_dir: "lib",
      # Only needed for files read by macros outside HXML/classpath discovery:
      extra_inputs: ["config/haxe/**/*.json"]
    ]
  ]
end
```

**Incremental freshness:**

`mix compile` stores a deterministic content fingerprint for the effective Haxe build. It includes
recursive HXML files and their options/defines, every direct classpath (including roots such as
`src_shared`), resources, resolved `-lib` roots and descriptors, package `haxelib.json` and
`extraParams.hxml`, the selected Haxe/haxelib commands, `.haxerc`, the Haxe standard library, relevant
toolchain environment, `HAXE_FAST_BOOT`, and output-affecting Mix configuration.

The check hashes content rather than modification times. Editing a file invalidates even when its
timestamp is unchanged; merely touching unchanged content does not rebuild. Missing or legacy
manifests fail closed and force compilation.

Haxe macros can read arbitrary non-Haxe files that are not declared as HXML resources. Declare those
paths with `:extra_inputs`, even when they live below a classpath or library root; each entry may be a
file, directory, or glob and may use `${ENV_NAME}` expansion.
The watcher monitors direct classpaths, HXML locations, and configured extra-input roots. Library and
toolchain changes outside the project are still detected on the next `mix compile`, but do not rely on
the project watcher to observe an external package cache in real time.

**Generated-output ownership and clean:**

Compilation returns only paths listed by the validated target-root `_GeneratedFiles.json`; it does
not scan all `.ex`/`.exs` files in `target_dir`. The version 2 manifest content-hashes each owned
file, rejects unowned target collisions, removes stale owned paths, and recovers interrupted
publication before Mix records compiler freshness.

`mix clean` delegates to the same ownership protocol. It preflights the whole manifest, then deletes
only owned regular files. A missing manifest owns nothing; an invalid path, symlink, unknown version,
or manually modified generated file makes clean fail before another file is removed. See
[Generated Output Ownership And Safe Cleanup](../02-user-guide/GENERATED_OUTPUT_OWNERSHIP.md).

## Source Mapping Tasks

### mix haxe.source_map

Query and validate source mapping information.

> Note: Source mapping is currently **experimental**, but is wired end‑to‑end when enabled
> (`-D source_map_enabled`). See `docs/04-api-reference/SOURCE_MAPPING.md`.

```bash
# Query specific position
mix haxe.source_map lib/UserService.ex 45 12

# Reverse lookup (Haxe → Elixir): `--reverse` is optional when FILE ends with `.hx`
mix haxe.source_map src_haxe/UserService.hx 15 5 --reverse
mix haxe.source_map src_haxe/UserService.hx 15 5

# List all source maps
mix haxe.source_map --list-maps

# Validate source map files
mix haxe.source_map --validate-maps

# Query with context
mix haxe.source_map lib/UserService.ex 45 12 --with-context

# JSON output
mix haxe.source_map lib/UserService.ex 45 12 --format json

# Copy-paste location (VS Code / editors)
mix haxe.source_map lib/UserService.ex 45 12 --format goto
```

**Arguments:**
- `file` - Path to generated Elixir (`.ex`) or Haxe (`.hx`) file
- `line` - Line number in the input file (1-based)
- `column` - Column number in the input file (0-based)

**Options:**
- `--list-maps` - List all available source map files
- `--validate-maps` - Validate all source map files
- `--with-context` - Include surrounding code context
- `--reverse` - Perform reverse lookup (Haxe → Elixir)
- `--target-dir` - Directory to search for source maps (default: `lib`)
- `--format` - Output format: `json`, `table`, `detailed`, `goto` (default: `detailed`)
- `--json` - Alias for `--format json`

**Output Example (JSON):**
```json
{
  "lookup": {
    "input": { "file": "lib/UserService.ex", "line": 45, "column": 12 },
    "output": { "file": "src_haxe/UserService.hx", "line": 23, "column": 15 },
    "direction": "elixir_to_haxe",
    "accurate": true
  },
  "source_map": { "generated_file": "lib/UserService.ex" }
}
```

### mix haxe.inspect

Cross-reference analysis between Haxe source and generated Elixir.

```bash
# Analyze transformation patterns
mix haxe.inspect --analyze-patterns

# Compare Haxe source with generated Elixir
mix haxe.inspect src_haxe/UserService.hx --compare

# Include source mapping details
mix haxe.inspect src_haxe/UserService.hx --with-mappings

# JSON output for LLM processing
mix haxe.inspect src_haxe/UserService.hx --format json
```

**Options:**
- `--analyze-patterns` - Show all transformation patterns
- `--compare` - Side-by-side comparison of Haxe and Elixir
- `--with-mappings` - Include detailed source map data
- `--format` - Output format: `detailed`, `json`, `table` (default: `detailed`)
- `--json` - Alias for `--format json`

## Debugging Tasks

### mix haxe.status

Quick overview of the current Haxe→Elixir integration state in your Mix project (manifest, server, watcher, and stored errors).

```bash
# Human readable
mix haxe.status

# JSON output for tools/LLMs
mix haxe.status --json
```

**Options:**
- `--format` - Output format: `table`, `json`, `detailed` (default: `table`)
- `--json` - Alias for `--format json`

### mix haxe.errors

Enhanced error reporting with source positions.

```bash
# List all compilation errors
mix haxe.errors

# JSON output for LLM agents
mix haxe.errors --json

# Filter by error type
mix haxe.errors --filter error
mix haxe.errors --filter warning

# Show only recent errors
mix haxe.errors --recent 5

# Filter by file
mix haxe.errors --file UserService.hx
```

**Options:**
- `--format` - Output format: `table`, `json`, `detailed`
- `--json` - Alias for `--format json`
- `--filter` - Filter by type: `error`, `warning`, `info`
- `--recent` - Show only N most recent errors
- `--file` - Filter errors by source file

**JSON Output Example:**
```json
[
  {
    "type": "compilation_error",
    "file": "src_haxe/UserService.hx",
    "line": 23,
    "message": "Type not found : UserModel",
    "error_id": "haxe_error_..."
  }
]
```

### mix haxe.stacktrace

Detailed stacktrace analysis with source mapping.

```bash
# Analyze specific error
mix haxe.stacktrace haxe_error_123456_0

# With cross-reference to Haxe source
mix haxe.stacktrace haxe_error_123456_0 --cross-reference

# Include source context
mix haxe.stacktrace haxe_error_123456_0 --with-context

# Show compilation pipeline
mix haxe.stacktrace haxe_error_123456_0 --trace-generation
```

**Options:**
- `--cross-reference` - Map stacktrace to Haxe source
- `--with-context` - Include surrounding code
- `--trace-generation` - Show compilation pipeline trace
- `--format` - Output format: `table`, `json`, `detailed` (default: `detailed`)
- `--json` - Alias for `--format json`

## Development Tasks

### mix haxe.watch

Watches Haxe files and recompiles on changes (recommended for local development).

```bash
mix haxe.watch
mix haxe.watch --verbose
mix haxe.watch --once
mix haxe.watch --dirs src_haxe,test
mix haxe.watch --hxml build.hxml
```

**Options:**
- `--hxml <file>` - HXML file to run (default: `build.hxml`)
- `--dirs <dir1,dir2,...>` - Comma-separated list of directories to watch (defaults depend on task)
- `--debounce <ms>` - Debounce window for file events before compiling (default: `200`)
- `--once` - Compile directly once and exit (no compilation server or watcher)
- `--promote <from:to,...>` - Post-compile file promotion spec (comma-separated `from:to` pairs)
  - Use this to publish Haxe outputs into stable paths without exposing intermediate build artifacts to other watchers.
  - Example: `--promote assets/js/_hx_app_tmp.js:assets/js/hx_app.js`
- `--verbose` - Print more detailed output

## Generation Tasks

These tasks generate **Haxe-first** scaffolding (they write `.hx` source files).
Elixir output is produced when you run `mix compile.haxe` (or `haxe build.hxml`).

Why multiple scaffold entrypoints exist:

- `haxe --run Run create ...` is for creating a **new project directory** (greenfield flow).
- `mix haxe.gen.project` is for patching an **existing** project with Haxe server-side plumbing.
- `mix haxe.phoenix.scaffold` is the canonical Phoenix client wiring layer used by both flows.

This split keeps one canonical Phoenix patching implementation while supporting both user stories.
See `docs/06-guides/SCAFFOLDING_SYSTEM.md` for the scenario-driven guide.

### mix haxe.phoenix.scaffold

Applies Phoenix client wiring for LiveView projects.

Modes:
- `--client-mode genes` (default): typed Haxe/Genes client build + watcher promotion + hook merge.
- `--client-mode plain-js`: remove scaffold-managed Genes wiring and converge back to plain Phoenix JS bootstrap.

This task wires the "temp output + promote" pattern to avoid esbuild `--watch` racing Haxe's `-js`
output deletion window (which can otherwise produce transient `Could not resolve "./hx_app.js"` errors).

**Idempotency + marker blocks**

This task is safe to run repeatedly. It patches files using explicit marker blocks:

- `BEGIN reflaxe_elixir ...` / `END reflaxe_elixir ...`

On re-run, only the content inside those blocks is replaced (no repeated insertions).
On first run, if an expected Phoenix shape isn't found, the task fails fast by default.
Use `--warn-only` to keep going (it emits a warning and skips that patch).
If it finds an existing scaffolded entry that is not marker-managed, it also fails fast (to avoid silently skipping updates).

**Files patched**

- `build-client.hxml`: outputs to `assets/js/_hx_app_tmp.js` (temp).
- `assets/js/hx_app.js`: ensures a stable file exists for esbuild imports.
- `assets/js/app.js`: imports `./hx_app.js` and merges `window.Hooks` into Phoenix hooks.
- `config/dev.exs`: adds a `haxe_client:` watcher under `watchers:` that runs `mix haxe.watch --promote ...`.
- `mix.exs`: adds a `"haxe.compile.client"` alias and ensures `assets.build`/`assets.deploy` run it first.
- `.gitignore`: ignores the temp output and promoted stable output (`assets/js/_hx_app_tmp.js*`, `assets/js/hx_app.js*`).

```bash
mix haxe.phoenix.scaffold
mix haxe.phoenix.scaffold --client-mode genes
mix haxe.phoenix.scaffold --client-mode plain-js --yes
mix haxe.phoenix.scaffold --verbose
mix haxe.phoenix.scaffold --warn-only
```

**Options:**
- `--verbose` - Print more detailed output
- `--warn-only` - Do not raise on unexpected Phoenix template shapes; emit warnings and skip those patches
- `--client-mode <genes|plain-js>` - Choose typed Genes mode or plain Phoenix JS convergence
- `--yes` - Skip confirmation prompts (used by generators/CI; especially for `plain-js` mode)

### mix haxe.gen.project

Adds Reflaxe.Elixir support to an existing Elixir project (creates `build.hxml`, `.haxerc`, and starter `src_haxe/` structure).

```bash
mix haxe.gen.project
mix haxe.gen.project --phoenix
mix haxe.gen.project --phoenix --client-mode plain-js
mix haxe.gen.project --basic-modules
```

If you pass `--phoenix`, the task also invokes `mix haxe.phoenix.scaffold` for client wiring.
Use `--client-mode genes|plain-js` (default `genes`) to control which client shape is applied.

It also scaffolds baseline Haxe ExUnit wiring:
- `build-tests.hxml` (Haxe test compile target to `test/generated/**/*.exs`)
- `test_haxe/` and `test/generated/` directories
- `test/test_helper.exs` bootstrap block that requires generated `*_test.exs` files
- Mix aliases: `"haxe.compile.tests"` and (when absent) `"test": ["haxe.compile.tests", "test"]`

- Writes/updates `build-client.hxml` (Genes) to output to `assets/js/_hx_app_tmp.js`
- Ensures a stable import path at `assets/js/hx_app.js`
- Patches `assets/js/app.js` to import `./hx_app.js` and merge hooks from `window.Hooks`
- Adds a dev watcher that promotes `_hx_app_tmp.js -> hx_app.js` after successful compiles

This avoids the common esbuild `--watch` race where Haxe deletes the `-js` output at compile start and
esbuild briefly fails with `Could not resolve "./hx_app.js"`.

### mix haxe.gen.schema

Generates an Ecto schema authored in Haxe.

```bash
mix haxe.gen.schema User
mix haxe.gen.schema Post --table posts
mix haxe.gen.schema Account --fields "name:string,email:string,age:integer"
```

### mix haxe.gen.context

Generates a Phoenix context authored in Haxe.

```bash
mix haxe.gen.context Accounts User users
mix haxe.gen.context Blog Post posts --schema-attrs "title:string,body:text"
```

### mix haxe.gen.live

Generates a Phoenix LiveView authored in Haxe.

```bash
mix haxe.gen.live DashboardLive
mix haxe.gen.live TodoLive --assigns "count:Int"
mix haxe.gen.live UsersLive --events "refresh,search"
```

### mix haxe.gen.extern

Generates a starter Haxe `extern` from an Elixir/Erlang module.

```bash
mix haxe.gen.extern Enum
mix haxe.gen.extern Ecto.Changeset --package externs.ecto --out src_haxe/externs
mix haxe.gen.extern :crypto --package externs.erlang --out src_haxe/externs
mix haxe.gen.extern Jason --wrapper --decoder --test-pointer
mix haxe.gen.extern MyApp.PubSub --boundary --package my_app.infrastructure --out src_haxe
```

Options:
- `--out DIR` - Output directory (default: `src_haxe/externs`)
- `--package PKG` - Haxe package name (default: `externs`)
- `--class-name Name` - Override generated Haxe class name
- `--boundary` - Generate a minimal app-local module-reference extern without loading the Elixir module
- `--wrapper` - Generate a normal Haxe wrapper class for app-facing calls
- `--decoder` - Generate a `TermDecoder` helper template
- `--test-pointer` - Generate a minimal Haxe ExUnit test scaffold pointer

Generated files:
- `<Module>.hx` - Thin `@:native` extern surface using `elixir.types.Term`
- `<Module>.hx` with no functions when `--boundary` is used; this is for app-owned module references such as `MyApp.PubSub`
- `<Module>Wrapper.hx` - Optional app-facing wrapper
- `<Module>Decoder.hx` - Optional decoder helper template
- `<Module>InteropTest.md` - Optional Haxe ExUnit test pointer

Files are written under the package-matching directory. For example,
`--out src_haxe/externs --package externs.ecto` writes
`src_haxe/externs/ecto/<Module>.hx`.

Use `--boundary` for strict-mode app-local markers where the Elixir module may not be loadable or callable from Haxe, but the compiler needs a typed module reference:

```haxe
package my_app.infrastructure;

@:native("MyApp.PubSub")
@:unsafeExtern
extern class PubSub {}
```

## Migration Tasks

### mix haxe.gen.migration

Generate a **Haxe-authored migration skeleton**.

This task is intentionally Haxe-first: it writes a Haxe migration file you can evolve in Haxe.
Ecto executes migrations from `priv/repo/migrations/*.exs`. Reflaxe.Elixir can emit runnable
`.exs` migrations via an opt-in migration build (`-D ecto_migrations_exs` + `-D elixir_output=priv/repo/migrations`).

```bash
# Generate a Haxe migration skeleton
mix haxe.gen.migration CreateUsersTable --table users --columns "name:string,email:string"

# Add an index
mix haxe.gen.migration AddIndexToUsers --table users --index email --unique

# Custom output directory (default: src_haxe/migrations)
mix haxe.gen.migration CreatePostsTable --haxe-dir src_haxe/migrations
```

**Options:**
- `--table` - Table name (defaults to inferred from migration name)
- `--columns` - Comma-separated columns (e.g. `"name:string,email:string,age:integer"`)
- `--index` - Index field(s)
- `--unique` - Unique index
- `--timestamp` - Timestamp used for `.exs` emission ordering (default: UTC now as `YYYYMMDDHHMMSS`)
- `--haxe-dir` - Output dir for Haxe migrations (default: `src_haxe/migrations`)

**Generated Files:**
- `src_haxe/migrations/<MigrationName>.hx` (or `--haxe-dir`)

### mix haxe.compile.migrations

Compile runnable `.exs` migration files.

This task expects a migration-only HXML (commonly `build-migrations.hxml`) that:

- Defines `-D ecto_migrations_exs`
- Sets `-D elixir_output=priv/repo/migrations`
- Includes only your `@:migration` classes

```bash
mix haxe.compile.migrations
mix haxe.compile.migrations --hxml build-migrations.hxml
```

## Task Options & Flags

### Global Options

These options work with most Mix tasks:

- `--format [table|json|detailed]` - Output format (when supported)
- `--verbose` - Verbose output
- `--quiet` - Suppress non-error output
- `--no-color` - Disable colored output

### Compilation Flags

Set in your `build.hxml` or `compile.hxml`:

```hxml
-D source-map          # Enable source mapping
-D incremental        # Support incremental compilation
-D watch-mode         # Optimize for file watching
-D source-map-verbose # Verbose source map generation
```

### Environment Variables

```bash
# Quiet mode
MIX_QUIET=1 mix haxe.source_map lib/User.ex 10 5

# Custom Haxe command
HAXE_PATH="/path/to/haxe" mix compile.haxe

# Haxe compilation server configuration
HAXE_SERVER_PORT=7000 mix haxe.watch
```

## Examples & Workflows

### Development Workflow

```bash
# 1. Start file watching with source mapping
mix haxe.watch

# 2. Make changes to Haxe files
# (automatic recompilation)

# 3. Check for errors
mix haxe.errors

# 4. Debug with source positions
mix haxe.source_map lib/User.ex 45 12
```

### LLM Agent Workflow

```bash
# 1. Start watching with JSON output
mix haxe.watch --verbose

# 2. Agent checks errors
mix haxe.errors --format json

# 4. Agent queries source positions
mix haxe.source_map lib/User.ex 45 12 --format json

# 5. Agent makes fixes
# (file watcher triggers recompilation)
```

### Debugging Workflow

```bash
# 1. Identify error location
mix haxe.errors --recent 1

# 2. Map to source position
mix haxe.source_map lib/UserService.ex 45 12

# 3. Inspect transformation
mix haxe.inspect src_haxe/UserService.hx --compare

# 4. Analyze stacktrace if needed
mix haxe.stacktrace haxe_error_123456_0 --cross-reference
```

### Migration Generation Workflow

```bash
# 1. Generate a Haxe migration skeleton
mix haxe.gen.migration CreateUsersTable --table users --columns "name:string,email:string"

# 2. Include CreateUsersTable in your build.hxml (or migrations build) and compile
haxe build-migrations.hxml

# Or via Mix:
mix haxe.compile.migrations
```

## Performance Tips

### Incremental Compilation

```bash
# Use file watching for automatic compilation
mix haxe.watch
```

### Batch Operations

```bash
# Query multiple positions at once
for line in 10 20 30; do
  mix haxe.source_map lib/User.ex $line 1 --format json
done | jq -s '.'
```

### Caching

```bash
# Force fresh compilation
mix compile.haxe --force
```

## Troubleshooting

### Common Issues

**No source maps generated:** Source mapping is currently experimental; `.ex.map` files are not emitted
by default builds yet. See `docs/04-api-reference/SOURCE_MAPPING.md`.

**Server connection issues:**
```bash
# Use a different Haxe compilation-server port if needed
HAXE_SERVER_PORT=7000 mix haxe.watch
```

**Stale compilation results:**
```bash
# Clean and rebuild
mix compile.haxe --force
```

## Integration with Editors

### VS Code Tasks

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Compile Haxe",
      "type": "shell",
      "command": "mix haxe.watch",
      "problemMatcher": "$haxe"
    },
    {
      "label": "Check Errors",
      "type": "shell",
      "command": "mix haxe.errors --format json"
    }
  ]
}
```

### IEx Helpers

```elixir
# In .iex.exs
defmodule H do
  def source(file, line, col \\ 1) do
    System.cmd("mix", ["haxe.source_map", file, "#{line}", "#{col}"])
    |> elem(0)
    |> IO.puts()
  end
  
  def errors() do
    System.cmd("mix", ["haxe.errors", "--format", "json"])
    |> elem(0)
    |> Jason.decode!()
    |> IO.inspect()
  end
end
```

Usage:
```elixir
iex> H.source("lib/User.ex", 45)
iex> H.errors()
```

## Summary

Reflaxe.Elixir provides a comprehensive suite of Mix tasks for:

- ✅ **Compilation** with file watching and incremental builds
- 🧪 **Source mapping (experimental)** for Haxe↔Elixir position lookups
- ✅ **Error reporting** with structured output for LLMs
- ✅ **Development tools** for status checking and debugging
- ✅ **Migration generation** from Haxe DSL

Most tasks support JSON output for programmatic access, making them suitable for both human developers and LLM agents. Source mapping is present but remains experimental; see `docs/04-api-reference/SOURCE_MAPPING.md`.

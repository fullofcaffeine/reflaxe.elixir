# Mix Tasks Reference

Complete reference for all Mix tasks provided by Reflaxe.Elixir for compilation, debugging, and development workflows.

## Table of Contents
1. [Compilation Tasks](#compilation-tasks)
2. [Source Mapping Tasks](#source-mapping-tasks)
3. [Debugging Tasks](#debugging-tasks)
4. [Development Tasks](#development-tasks)
5. [Generation Tasks](#generation-tasks)
6. [Migration Tasks](#migration-tasks)
7. [Task Options & Flags](#task-options--flags)
8. [Examples & Workflows](#examples--workflows)

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
- `HAXE_SERVER_PORT=6116` - Custom port for Haxe compilation server (default: 6116)
- `HAXE_NO_SERVER=1` - Disable the Haxe `--wait` server and compile directly
- `HAXE_NO_COMPILE=1` - Skip Haxe compilation entirely (useful for CI/sentinels)

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

## Generation Tasks

These tasks generate **Haxe-first** scaffolding (they write `.hx` source files).
Elixir output is produced when you run `mix compile.haxe` (or `haxe build.hxml`).

### mix haxe.gen.project

Adds Reflaxe.Elixir support to an existing Elixir project (creates `build.hxml`, `.haxerc`, and starter `src_haxe/` structure).

```bash
mix haxe.gen.project
mix haxe.gen.project --phoenix
mix haxe.gen.project --basic-modules
```

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
HAXE_CMD="haxe" mix compile.haxe

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

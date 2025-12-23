# Mix Tasks Reference

Complete reference for all Mix tasks provided by Reflaxe.Elixir for compilation, debugging, and development workflows.

## Table of Contents
1. [Compilation Tasks](#compilation-tasks)
2. [Source Mapping Tasks](#source-mapping-tasks)
3. [Debugging Tasks](#debugging-tasks)
4. [Development Tasks](#development-tasks)
5. [Migration Tasks](#migration-tasks)
6. [Task Options & Flags](#task-options--flags)
7. [Examples & Workflows](#examples--workflows)

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

> Note: Source mapping is currently **experimental**. The task is present, but `.ex.map` emission and
> lookup are not yet fully wired end‑to‑end. See `docs/04-api-reference/SOURCE_MAPPING.md`.

```bash
# Query specific position
mix haxe.source_map lib/UserService.ex 45 12

# List all source maps
mix haxe.source_map --list-maps

# Validate source map files
mix haxe.source_map --validate-maps

# Query with context
mix haxe.source_map lib/UserService.ex 45 12 --with-context

# JSON output
mix haxe.source_map lib/UserService.ex 45 12 --format json
```

**Arguments:**
- `file` - Path to generated Elixir file
- `line` - Line number in Elixir file
- `column` - Column number in Elixir file

**Options:**
- `--list-maps` - List all available source map files
- `--validate-maps` - Validate all source map files
- `--with-context` - Include surrounding code context
- `--format` - Output format: `text`, `json`, `table`

**Output Example (JSON):**
```json
{
  "elixir": {
    "file": "lib/UserService.ex",
    "line": 45,
    "column": 12
  },
  "haxe": {
    "source": "src_haxe/UserService.hx",
    "line": 23,
    "column": 15
  }
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
- `--format` - Output format: `text`, `json`, `table`

## Debugging Tasks

### mix haxe.errors

Enhanced error reporting with source positions.

```bash
# List all compilation errors
mix haxe.errors

# JSON output for LLM agents
mix haxe.errors --format json

# Filter by error type
mix haxe.errors --filter error
mix haxe.errors --filter warning

# Show only recent errors
mix haxe.errors --recent 5

# Filter by file
mix haxe.errors --file UserService.hx
```

**Options:**
- `--format` - Output format: `text`, `json`, `detailed`
- `--filter` - Filter by type: `error`, `warning`, `info`
- `--recent` - Show only N most recent errors
- `--file` - Filter errors by source file

**JSON Output Example:**
```json
{
  "errors": [
    {
      "type": "error",
      "file": "src_haxe/UserService.hx",
      "line": 23,
      "column": 15,
      "message": "Type not found: UserModel",
      "suggestion": "Did you mean 'User'?",
      "timestamp": "2025-08-11T10:30:45Z"
    }
  ],
  "total": 1,
  "status": "compilation_failed"
}
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
- `--format` - Output format: `text`, `json`

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

- `--format [text|json|table]` - Output format
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
- ✅ **Source mapping** for precise debugging at Haxe level
- ✅ **Error reporting** with structured output for LLMs
- ✅ **Development tools** for status checking and debugging
- ✅ **Migration generation** from Haxe DSL

All tasks support JSON output for programmatic access, making them ideal for both human developers and LLM agents. The source mapping feature, unique among Reflaxe targets, provides seamless debugging across the compilation boundary.

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

# With file watching
mix compile.haxe --watch

# With verbose output
mix compile.haxe --verbose

# Force recompilation
mix compile.haxe --force
```

**Options:**
- `--watch` - Enable file watching for automatic recompilation
- `--verbose` - Show detailed compilation output
- `--force` - Force full recompilation (ignore cache)
- `--no-deps-check` - Skip dependency checking
- `--return-errors` - Return compilation errors as data structure

**Environment Variables:**
- `MIX_QUIET=1` - Suppress all output except errors
- `HAXE_SERVER_PORT=6000` - Custom port for Haxe compilation server

## Source Mapping Tasks

### mix haxe.source_map

Query and validate source mapping information.

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

### mix haxe.status

Get current project compilation status.

```bash
# Basic status
mix haxe.status

# JSON format for automation
mix haxe.status --format json

# Detailed status with file information
mix haxe.status --detailed
```

**JSON Output:**
```json
{
  "watching": true,
  "last_compilation": "2025-08-11T10:30:45Z",
  "files_compiled": 3,
  "errors": [],
  "warnings": 0,
  "server_running": true,
  "server_port": 6000
}
```

### mix haxe.clean

Clean generated files and cache.

```bash
# Clean generated Elixir files
mix haxe.clean

# Clean everything including source maps
mix haxe.clean --all

# Clean only cache
mix haxe.clean --cache-only
```

**Options:**
- `--all` - Remove all generated files and source maps
- `--cache-only` - Only clean compilation cache
- `--deps` - Also clean dependency files

### mix haxe.server

Manage Haxe compilation server.

```bash
# Start compilation server
mix haxe.server start

# Stop compilation server
mix haxe.server stop

# Restart compilation server
mix haxe.server restart

# Get server status
mix haxe.server status
```

**Options:**
- `--port` - Custom server port (default: 6000)
- `--timeout` - Compilation timeout in ms
- `--verbose` - Verbose server output

## Migration Tasks

### mix haxe.gen.migration

Generate Ecto migrations from Haxe classes.

```bash
# Generate migration from Haxe class
mix haxe.gen.migration CreateUsers

# With custom module
mix haxe.gen.migration AddIndexToUsers --module Users

# Specify timestamp
mix haxe.gen.migration CreatePosts --timestamp 20250115120000
```

**Options:**
- `--module` - Source Haxe module name
- `--timestamp` - Custom migration timestamp
- `--path` - Output path for migration file

**Generated Files:**
- `priv/repo/migrations/[timestamp]_create_users.ex`
- Source Haxe file in `src_haxe/migrations/`

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
HAXE_CMD="npx haxe" mix compile.haxe

# Server configuration
HAXE_SERVER_PORT=7000 mix haxe.server start
```

## Examples & Workflows

### Development Workflow

```bash
# 1. Start file watching with source mapping
mix compile.haxe --watch

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
mix compile.haxe --watch --verbose

# 2. Agent queries status
mix haxe.status --format json

# 3. Agent checks errors
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
# 1. Create Haxe migration class
vim src_haxe/migrations/CreateUsers.hx

# 2. Generate Ecto migration
mix haxe.gen.migration CreateUsers

# 3. Review generated migration
cat priv/repo/migrations/*_create_users.ex

# 4. Run migration
mix ecto.migrate
```

## Performance Tips

### Incremental Compilation

```bash
# Start Haxe server for faster rebuilds
mix haxe.server start

# Use file watching for automatic compilation
mix compile.haxe --watch
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
# Clear cache if performance degrades
mix haxe.clean --cache-only

# Force fresh compilation
mix compile.haxe --force
```

## Troubleshooting

### Common Issues

**No source maps generated:**
```bash
# Ensure -D source-map flag is set
grep "source-map" build.hxml

# Verify source maps exist
ls lib/*.ex.map
```

**Server connection issues:**
```bash
# Check server status
mix haxe.server status

# Restart server
mix haxe.server restart

# Use different port if needed
HAXE_SERVER_PORT=7000 mix haxe.server start
```

**Stale compilation results:**
```bash
# Clean and rebuild
mix haxe.clean
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
      "command": "mix compile.haxe --watch",
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
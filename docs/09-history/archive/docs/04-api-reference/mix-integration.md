# Mix Integration Reference

## Overview

Reflaxe.Elixir provides deep integration with Mix, Elixir's build tool, enabling seamless compilation of Haxe code within Elixir projects. This integration includes automatic compilation, file watching, error reporting, and code generation tools.

## Table of Contents

1. [Compiler Integration](#compiler-integration)
2. [Mix Tasks Reference](#mix-tasks-reference)
3. [Configuration](#configuration)
4. [Error Handling](#error-handling)
5. [File Watching](#file-watching)
6. [Code Generation](#code-generation)
7. [Source Mapping](#source-mapping)
8. [Troubleshooting](#troubleshooting)

## Compiler Integration

### Mix.Tasks.Compile.Haxe

The core compiler task integrates Haxe compilation into Mix's build pipeline.

#### Installation

Add to your `mix.exs`:

```elixir
defmodule YourApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :your_app,
      version: "0.1.0",
      compilers: [:haxe] ++ Mix.compilers(),  # Add :haxe before default compilers
      haxe: haxe_config()                      # Haxe-specific configuration
    ]
  end

  defp haxe_config do
    [
      hxml_file: "build.hxml",      # Path to HXML build file
      source_dir: "src_haxe",        # Haxe source directory
      target_dir: "lib",             # Generated Elixir output directory
      watch: Mix.env() == :dev,     # Enable file watching in dev
      verbose: false                 # Show detailed compilation output
    ]
  end
end
```

#### Usage

```bash
# Compile Haxe files
mix compile

# Force recompilation
mix compile --force

# Verbose output
mix compile --verbose

# Clean generated files
mix clean
```

#### How It Works

1. **Dependency Resolution**: Mix ensures Haxe compilation happens before Elixir compilation
2. **Incremental Compilation**: Only recompiles when source files change
3. **Manifest Tracking**: Maintains compilation state in `_build/dev/lib/your_app/.mix/compile.haxe`
4. **Error Integration**: Compilation errors are reported through Mix's diagnostic system

## Mix Tasks Reference

### Debugging Tasks

#### mix haxe.errors

Display compilation errors in various formats for debugging and LLM agent consumption.

```bash
# Display errors in table format (default)
mix haxe.errors

# JSON output for LLM agents
mix haxe.errors --format json

# Detailed format with suggestions
mix haxe.errors --format detailed

# Filter by file
mix haxe.errors --file UserLive.hx

# Show only recent errors
mix haxe.errors --recent 5

# Filter by error type
mix haxe.errors --filter error
```

**Options:**
- `--format` - Output format: table, json, detailed
- `--recent N` - Show only N most recent errors
- `--filter TYPE` - Filter by type: error, warning, stacktrace
- `--file FILE` - Show errors from specific file
- `--line LINE` - Show errors at specific line
- `--level LEVEL` - Filter by level: haxe, elixir, mix

#### mix haxe.stacktrace

Analyze error stacktraces with cross-level debugging support.

```bash
# Analyze specific error
mix haxe.stacktrace haxe_error_12345

# JSON format for programmatic access
mix haxe.stacktrace haxe_error_12345 --format json

# Include cross-reference information
mix haxe.stacktrace haxe_error_12345 --cross-reference

# Show generation trace
mix haxe.stacktrace haxe_error_12345 --trace-generation
```

**Options:**
- `--format FORMAT` - Output format: detailed, json
- `--cross-reference` - Show Haxe→Elixir mapping
- `--trace-generation` - Show code generation trace

#### mix haxe.inspect

Inspect generated code and understand the compilation process.

```bash
# Inspect specific module
mix haxe.inspect UserLive

# Show generation details
mix haxe.inspect UserLive --detailed

# Compare Haxe source with generated Elixir
mix haxe.inspect UserLive --compare
```

#### mix haxe.source_map

Perform source mapping lookups between Haxe and Elixir positions.

```bash
# Map Elixir position to Haxe source
mix haxe.source_map lib/user_live.ex 25 10

# Reverse lookup (Haxe to Elixir)
mix haxe.source_map src_haxe/UserLive.hx 15 5 --reverse

# JSON output
mix haxe.source_map lib/user_live.ex 25 10 --format json

# With source context
mix haxe.source_map lib/user_live.ex 25 10 --with-context

# List all source maps
mix haxe.source_map --list-maps

# Validate source maps
mix haxe.source_map --validate-maps
```

### File Watching

#### mix haxe.watch

Manually control file watching for development.

```bash
# Start watching with defaults
mix haxe.watch

# Verbose output
mix haxe.watch --verbose

# Compile once (no watching)
mix haxe.watch --once

# Watch specific directories
mix haxe.watch --dirs src_haxe,test_haxe

# Custom debounce period
mix haxe.watch --debounce 200

# Custom HXML file
mix haxe.watch --hxml custom.hxml
```

**Configuration in mix.exs:**

```elixir
haxe: [
  watch_dirs: ["src_haxe", "test_haxe"],
  debounce_ms: 200,
  auto_compile: true
]
```

## Code Generation

### mix haxe.gen.schema

Generate Ecto schemas from Haxe type definitions.

```bash
# Basic schema
mix haxe.gen.schema User

# With custom table
mix haxe.gen.schema Post --table posts

# With fields
mix haxe.gen.schema User --fields "name:string,email:string:unique,age:integer"

# With associations
mix haxe.gen.schema Post --belongs-to "User:author" --has-many "Comment:comments"

# Without timestamps
mix haxe.gen.schema Config --no-timestamps

# With changeset
mix haxe.gen.schema User --changeset
```

**Generated Files:**
- `src_haxe/schemas/User.hx` - Haxe source with @:schema annotation
- `lib/your_app/schemas/user.ex` - Compiled Elixir schema

### mix haxe.gen.live

Generate Phoenix LiveView modules with type safety.

```bash
# Basic LiveView
mix haxe.gen.live UserLive

# With actions
mix haxe.gen.live UserLive --actions "index,show,edit"

# With schema association
mix haxe.gen.live UserLive --schema User

# With custom path
mix haxe.gen.live UserLive --path "/users"

# Component-based
mix haxe.gen.live UserLive --component
```

**Generated Structure:**
```
src_haxe/live/
├── UserLive.hx           # Main LiveView module
├── UserLiveComponent.hx  # Optional component
└── UserLiveHelpers.hx    # Helper functions
```

### mix haxe.gen.context

Generate Phoenix contexts with business logic.

```bash
# Basic context
mix haxe.gen.context Accounts User users

# With fields
mix haxe.gen.context Accounts User users --fields "name:string,email:string"

# With custom repo
mix haxe.gen.context Accounts User users --repo MyApp.CustomRepo

# Without changeset
mix haxe.gen.context Accounts User users --no-changeset
```

### mix haxe.gen.migration

Generate database migrations from Haxe.

```bash
# Create table migration
mix haxe.gen.migration CreateUsers --table users

# Add columns migration
mix haxe.gen.migration AddAgeToUsers --alter users --add "age:integer"

# Remove columns
mix haxe.gen.migration RemoveEmailFromUsers --alter users --remove "email"

# Add index
mix haxe.gen.migration AddIndexToUsersEmail --index "users:email:unique"
```

### mix haxe.gen.project

Scaffold a new Haxe→Elixir project.

```bash
# Phoenix application
mix haxe.gen.project my_app --type phoenix

# Pure OTP application
mix haxe.gen.project my_app --type otp

# Library
mix haxe.gen.project my_lib --type lib

# With Ecto
mix haxe.gen.project my_app --ecto

# With specific Elixir version
mix haxe.gen.project my_app --elixir "~> 1.14"
```

## Configuration

### Complete Configuration Reference

```elixir
# mix.exs
config :your_app,
  haxe: [
    # Compilation
    hxml_file: "build.hxml",           # HXML build configuration
    source_dir: "src_haxe",             # Haxe source directory
    target_dir: "lib",                  # Generated Elixir directory
    
    # Watching
    watch: true,                        # Enable file watching
    watch_dirs: ["src_haxe", "test"],   # Directories to watch
    debounce_ms: 100,                   # Debounce period
    auto_compile: true,                 # Auto-compile on changes
    
    # Compilation options
    verbose: false,                     # Verbose output
    force: false,                       # Force recompilation
    server_mode: true,                  # Use Haxe compilation server
    server_port: 6000,                  # Compilation server port
    
    # Source mapping
    source_maps: true,                  # Generate source maps
    source_map_dir: "priv/source_maps", # Source map directory
    
    # Error handling
    store_errors: true,                 # Store errors for analysis
    error_format: :structured,          # Error format: :structured or :raw
    
    # Code generation
    generator_defaults: [
      timestamps: true,                 # Include timestamps in schemas
      changeset: true,                  # Generate changesets
      repo: "Repo"                      # Default repo module
    ]
  ]
```

## Error Handling

### Error Storage System

Compilation errors are automatically stored in ETS for analysis:

```elixir
# Access from Elixir code
errors = HaxeCompiler.get_compilation_errors(:map)
json_errors = HaxeCompiler.get_compilation_errors(:json)

# Clear errors
HaxeCompiler.clear_compilation_errors()
```

### Error Structure

```elixir
%{
  type: :compilation_error,        # :compilation_error, :warning, :stacktrace
  level: :haxe,                    # :haxe, :elixir, :mix
  file: "src_haxe/UserLive.hx",
  line: 45,
  column_start: 12,
  column_end: 20,
  error_type: "Type not found",
  message: "UnknownType",
  error_id: "haxe_error_12345",
  timestamp: ~U[2025-08-26 10:30:00Z],
  stacktrace: [],
  source_mapping: %{               # If source maps available
    original_haxe: %{
      file: "src_haxe/UserLive.hx",
      line: 45,
      column: 12
    },
    generated_elixir: %{
      file: "lib/user_live.ex",
      line: 67,
      column: 8
    }
  }
}
```

## Source Mapping

### How Source Maps Work

1. **Generation**: During compilation, SourceMapWriter.hx creates .ex.map files
2. **Format**: Source Map v3 specification with VLQ encoding
3. **Storage**: Maps stored alongside generated .ex files
4. **Lookup**: SourceMapLookup module provides reverse mapping

### Source Map Files

```json
{
  "version": 3,
  "file": "user_live.ex",
  "sourceRoot": "",
  "sources": ["../../src_haxe/UserLive.hx"],
  "names": [],
  "mappings": "AAAA;AACA;AACA..."  // VLQ encoded mappings
}
```

### Using Source Maps

```elixir
# From Elixir code
{:ok, source_map} = SourceMapLookup.parse_source_map("lib/user_live.ex.map")
{:ok, haxe_pos} = SourceMapLookup.lookup_haxe_position(source_map, 67, 8)
# Returns: %{file: "src_haxe/UserLive.hx", line: 45, column: 12}

# Enhance errors with source mapping
enhanced_error = SourceMapLookup.enhance_error_with_source_mapping(error)
```

## Troubleshooting

### Common Issues

#### "Module HaxeCompiler not found"

The support modules may not be compiled. Run:
```bash
mix deps.compile
mix compile --force
```

#### File watching not working

1. Check FileSystem dependency:
```elixir
# mix.exs
defp deps do
  [
    {:file_system, "~> 0.2"}
  ]
end
```

2. Verify watch configuration:
```bash
mix haxe.watch --verbose
```

#### Source maps not generated

1. Ensure source_maps enabled in configuration
2. Check SourceMapWriter is being invoked during compilation
3. Verify .ex.map files exist alongside .ex files

#### Compilation errors not displayed

1. Check error storage is enabled
2. Run `mix haxe.errors` to see stored errors
3. Use `--verbose` flag for detailed output

### Debug Commands

```bash
# Check Haxe installation
which haxe
haxe --version

# Verify lix setup
npx lix --version
npx lix list

# Test direct compilation
npx haxe build.hxml

# Check Mix integration
mix compile.haxe --verbose

# Inspect generated files
find lib -name "*.ex" -newer src_haxe/Main.hx

# Validate source maps
find lib -name "*.ex.map" -exec cat {} \;
```

## Integration with LLM Agents

### Design for AI Assistance

The Mix integration is specifically designed to support LLM agents:

1. **Structured JSON Output**: All tasks support `--format json` for programmatic parsing
2. **Error IDs**: Unique identifiers for tracking errors across debugging sessions
3. **Cross-Reference Support**: Map between abstraction levels (Haxe→Elixir)
4. **Debugging Guidance**: Built-in suggestions for fixing common issues

### LLM Workflow Example

```bash
# 1. Detect compilation error
mix compile
# Error: Type not found at UserLive.hx:45

# 2. Get structured error information
mix haxe.errors --format json > errors.json

# 3. Analyze specific error
mix haxe.stacktrace haxe_error_12345 --format json

# 4. Map to source position
mix haxe.source_map lib/user_live.ex 67 8 --format json

# 5. Get debugging suggestions
mix haxe.errors --format detailed
```

### Programmatic Access

```elixir
# For LLM agent integration
defmodule LLMDebugger do
  def analyze_errors do
    errors = HaxeCompiler.get_compilation_errors(:map)
    
    Enum.map(errors, fn error ->
      # Enhance with source mapping
      enhanced = SourceMapLookup.enhance_error_with_source_mapping(error)
      
      # Generate fix suggestions
      %{
        error: enhanced,
        suggestions: generate_suggestions(enhanced),
        debug_level: determine_debug_level(enhanced)
      }
    end)
  end
end
```

## Best Practices

### Project Structure

```
your_app/
├── mix.exs                  # Mix configuration with :haxe compiler
├── build.hxml               # Haxe build configuration
├── src_haxe/                # Haxe source files
│   ├── Main.hx
│   ├── schemas/            # Ecto schemas
│   ├── live/               # LiveView modules
│   └── contexts/           # Business logic
├── lib/                     # Generated Elixir files
│   ├── your_app/
│   └── your_app_web/
├── priv/
│   └── source_maps/        # Source map files
└── haxe_libraries/         # Lix dependencies
```

### Development Workflow

1. **Initial Setup**:
   ```bash
   mix haxe.gen.project my_app --type phoenix
   cd my_app
   mix setup
   ```

2. **Development Cycle**:
   ```bash
   # Start watcher in one terminal
   mix haxe.watch
   
   # Run Phoenix in another
   mix phx.server
   ```

3. **Debugging**:
   ```bash
   # When compilation fails
   mix haxe.errors --detailed
   
   # Map errors to source
   mix haxe.source_map <file> <line> <column>
   ```

4. **Code Generation**:
   ```bash
   # Generate new features
   mix haxe.gen.live TodoLive --schema Todo
   mix haxe.gen.migration CreateTodos --table todos
   ```

## Performance Considerations

### Compilation Server

The Haxe compilation server significantly improves incremental compilation speed:

```elixir
# Enable in configuration
haxe: [
  server_mode: true,
  server_port: 6000
]
```

Benefits:
- 10-50x faster incremental compilation
- Cached type information
- Reduced memory allocation

### File Watching Optimization

```elixir
# Optimize watching
haxe: [
  watch_dirs: ["src_haxe"],     # Only watch source directories
  debounce_ms: 200,             # Prevent rapid recompilation
  patterns: ["**/*.hx"]         # Only watch Haxe files
]
```

## Extending the Integration

### Creating Custom Mix Tasks

```elixir
defmodule Mix.Tasks.Haxe.Custom do
  use Mix.Task
  
  @shortdoc "Custom Haxe task"
  
  def run(args) do
    # Access Haxe configuration
    config = Mix.Project.config()[:haxe] || []
    
    # Use HaxeCompiler module
    {:ok, files} = HaxeCompiler.compile(config)
    
    # Process results
    Enum.each(files, &process_file/1)
  end
end
```

### Hooking into Compilation

```elixir
# In mix.exs
def project do
  [
    compilers: [:pre_haxe, :haxe, :post_haxe] ++ Mix.compilers()
  ]
end
```

## Version Compatibility

| Reflaxe.Elixir | Elixir | Mix  | Haxe  |
|----------------|--------|------|-------|
| 0.1.0          | ≥1.14  | ≥1.14| ≥4.3  |
| 0.2.0          | ≥1.15  | ≥1.15| ≥4.3  |

## Related Documentation

- [Compiler Development Guide](/docs/03-compiler-development/)
- [Source Mapping Architecture](/docs/05-architecture/source-mapping.md)
- [Testing Infrastructure](/docs/03-compiler-development/testing-infrastructure.md)
- [Project Configuration](/docs/02-user-guide/configuration.md)
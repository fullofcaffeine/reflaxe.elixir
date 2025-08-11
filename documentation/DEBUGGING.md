# Debugging Guide for Reflaxe.Elixir

## Overview

This guide covers debugging strategies for Haxe→Elixir compilation, including our pioneering source mapping implementation - the first among all Reflaxe targets!

## Table of Contents
1. [Source Mapping Architecture](#source-mapping-architecture)
2. [Current Capabilities](#current-capabilities)
3. [Known Limitations](#known-limitations)
4. [Debugging Workflow](#debugging-workflow)
5. [Transformation Patterns](#transformation-patterns)
6. [Mix Tasks Reference](#mix-tasks-reference)
7. [Troubleshooting](#troubleshooting)

## Source Mapping Architecture

### How It Works

Reflaxe.Elixir generates Source Map v3 specification files that map generated Elixir code back to original Haxe source:

```
Haxe Source (.hx) → ElixirCompiler → Generated Elixir (.ex) + Source Map (.ex.map)
```

### Key Components

1. **SourceMapWriter.hx** (Haxe side)
   - Generates .ex.map files during compilation
   - Implements VLQ Base64 encoding for compact storage
   - Tracks position mappings between source and generated code

2. **SourceMapLookup.ex** (Elixir side)
   - Parses source map files
   - Performs reverse lookups (Elixir position → Haxe position)
   - Enhances compilation errors with source positions

3. **Mix Tasks** (User interface)
   - `mix haxe.source_map` - Query position mappings
   - `mix haxe.inspect` - Cross-reference analysis
   - `mix haxe.errors` - Enhanced error reporting

### Source Map Format

Generated .ex.map files follow Source Map v3 specification:

```json
{
  "version": 3,
  "file": "Generated.ex",
  "sources": ["Original.hx"],
  "mappings": "AAAA,SAASA,UAAU...",  // VLQ-encoded position data
  "sourceRoot": "",
  "names": []
}
```

## Current Capabilities

### ✅ What's Working

1. **Source Map Generation**
   - Valid Source Map v3 files are generated for every .ex file
   - VLQ encoding produces real mapping data (not empty!)
   - Sources array correctly references Haxe files
   - Enable with `-D source-map` compilation flag

2. **Mix Task Infrastructure**
   ```bash
   # List available source maps
   mix haxe.source_map --list-maps
   
   # Validate source map files
   mix haxe.source_map --validate-maps
   
   # Attempt position lookup (decoder incomplete)
   mix haxe.source_map lib/MyModule.ex 25 10
   ```

3. **Error Enhancement**
   - Compilation errors are stored with structured data
   - JSON output available for LLM agents
   - Phoenix error handler integration scaffolded

4. **Cross-Reference Tools**
   ```bash
   # Analyze transformation patterns
   mix haxe.inspect --analyze-patterns
   
   # Compare Haxe source with generated Elixir
   mix haxe.inspect src/MyClass.hx --compare
   ```

## Known Limitations

### ⚠️ VLQ Decoder Incomplete

The VLQ Base64 decoder in `SourceMapLookup.decode_vlq_segment/3` is currently a mock implementation:

```elixir
# TODO: Implement proper VLQ Base64 decoding
# Current implementation returns mock mappings
```

**Impact**: Position lookups fail with "No mapping found for position X:Y"

**Workaround**: Use file comparison and pattern analysis instead of exact position lookups

### ⚠️ Position Tracking Coverage

Not all expression types have position tracking implemented. Complex expressions may have approximate positions.

## Debugging Workflow

### For Compilation Errors

1. **Get structured error information**
   ```bash
   mix haxe.errors --format json
   ```

2. **Analyze specific error**
   ```bash
   mix haxe.stacktrace haxe_error_123456_0
   ```

3. **Inspect the source file**
   ```bash
   mix haxe.inspect src/ProblematicFile.hx
   ```

### For Runtime Errors

1. **Check generated Elixir code**
   ```bash
   mix haxe.inspect lib/Generated.ex --with-mappings
   ```

2. **Understand transformation pattern**
   ```bash
   mix haxe.inspect --analyze-patterns
   ```

3. **Debug at appropriate level**
   - Haxe level: Logic errors, type issues
   - Elixir level: Integration issues, framework problems

## Transformation Patterns

Understanding how Haxe constructs map to Elixir is crucial for effective debugging.

### Why Patterns Matter

The `mix haxe.inspect --analyze-patterns` task exists because:
1. **Predictability**: Knowing patterns helps predict where issues occur
2. **Debug Strategy**: Determines whether to debug at Haxe or Elixir level
3. **LLM Assistance**: Helps agents understand the compilation model

### Common Patterns

| Haxe Construct | Elixir Output | Notes |
|---------------|---------------|-------|
| `class MyClass` | `defmodule MyClass` | Classes become modules |
| `static function` | `def` | Static methods become public functions |
| `function` (instance) | `def` with context | First param becomes implicit self |
| `@:liveview` | `use Phoenix.LiveView` | Annotation-driven framework integration |
| `@:schema` | `use Ecto.Schema` | Database model generation |
| `@:genserver` | `use GenServer` | OTP behavior implementation |
| `@:changeset` | Validation pipeline | Ecto changeset generation |
| `new MyClass()` | `%MyClass{}` | Constructor becomes struct creation |
| `array[index]` | `Enum.at(array, index)` | Array access pattern |
| `map.get(key)` | `Map.get(map, key)` | Map access pattern |

### Pattern Analysis Example

```haxe
// Haxe source
@:liveview
class UserLive {
    public function mount(params: Dynamic, session: Dynamic, socket: Socket): Socket {
        return socket.assign("users", []);
    }
}
```

Transforms to:

```elixir
# Generated Elixir
defmodule UserLive do
  use Phoenix.LiveView
  
  def mount(params, session, socket) do
    {:ok, assign(socket, users: [])}
  end
end
```

## Mix Tasks Reference

### `mix haxe.errors`
Lists compilation errors with structured output.

Options:
- `--format json` - JSON output for programmatic access
- `--recent N` - Show only N most recent errors
- `--file FILE` - Filter by source file

### `mix haxe.source_map`
Query source mapping information.

Options:
- `--list-maps` - List all available source maps
- `--validate-maps` - Check source map validity
- `--format FORMAT` - Output format (json, table, detailed)
- `--with-context` - Include source code context

### `mix haxe.inspect`
Cross-reference analysis between Haxe and Elixir.

Options:
- `--analyze-patterns` - Show transformation patterns
- `--compare` - Side-by-side comparison
- `--with-mappings` - Include source mapping details
- `--format FORMAT` - Output format

### `mix haxe.stacktrace`
Detailed stacktrace analysis for specific errors.

Options:
- `--cross-reference` - Show Haxe↔Elixir mapping
- `--with-context` - Include source context
- `--trace-generation` - Show compilation pipeline

## Troubleshooting

### "No mapping found for position"
**Cause**: VLQ decoder is incomplete
**Solution**: Use `--compare` mode instead of exact position lookup

### Empty source maps
**Cause**: Compilation without `-D source-map` flag
**Solution**: Add flag to compile.hxml or build command

### Source map validation failures
**Cause**: Incomplete compilation or file system issues
**Solution**: Clean and rebuild with `rm -rf out/ && haxe build.hxml`

### Phoenix runtime errors not enhanced
**Cause**: PhoenixErrorHandler not configured
**Solution**: Add to endpoint configuration (see Phoenix integration guide)

## Future Improvements

Planned enhancements (see ROADMAP.md for details):
- Complete VLQ decoder implementation
- Enhanced position tracking for all expressions
- Source map validation test suite
- IEx debugging integration
- Hot reload with source map updates

## Contributing

To improve debugging support:
1. See `src/reflaxe/elixir/SourceMapWriter.hx` for generation logic
2. See `lib/source_map_lookup.ex` for decoding logic
3. Reference Haxe's `context/sourcemaps.ml` for VLQ implementation
4. Add tests in `test/tests/source_map_*` directories

Remember: We're pioneering source mapping for Reflaxe targets - your contributions make history!
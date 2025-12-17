# Source Mapping Architecture

## Overview

Source mapping enables debugging of generated Elixir code by mapping positions back to original Haxe source files. This is crucial for the developer experience, allowing errors and stack traces in Elixir to reference the original Haxe code that generated them.

## Current Status ⚠️

**Source maps are currently generated but empty** - The infrastructure exists but isn't properly integrated into the compilation process.

**Priority: Post-1.0** - Source mapping will be fully implemented after the compiler is working well for generating code without issues. The foundation is in place for efficient implementation using Haxe's position APIs.

### What Works
- ✅ SourceMapWriter.hx implementation following Source Map v3 spec
- ✅ VLQ encoding for compact position storage
- ✅ .ex.map files are generated alongside .ex files
- ✅ Mix integration can read and parse source maps

### What's Missing
- ❌ ElixirCompiler doesn't call `mapPosition()` during code generation
- ❌ No position tracking during AST traversal
- ❌ VLQ decoding in Elixir (SourceMapLookup.ex) is incomplete

## Architecture Components

### 1. SourceMapWriter.hx (Haxe/Compiler Side)

Located at `src/reflaxe/elixir/SourceMapWriter.hx`, this class generates Source Map v3 compliant `.ex.map` files.

```haxe
// Key methods:
mapPosition(pos: Position): Void     // Map a Haxe position to current output
stringWritten(str: String): Void     // Track generated string output
generateSourceMap(): String          // Create final .ex.map file
```

**How it should work:**
1. Before writing any code derived from a Haxe AST node, call `mapPosition(expr.pos)`
2. Write the generated Elixir code
3. Call `stringWritten(generatedCode)` to update position tracking
4. At end of compilation, call `generateSourceMap()` to write .ex.map file

### 2. ElixirCompiler Integration Points

The compiler needs to integrate source mapping at these key locations:

```haxe
// In ElixirCompiler.hx or OutputFileManager.hx
class OutputFileManager {
    var sourceMapWriter: SourceMapWriter;
    
    function writeExpression(expr: TypedExpr, output: String) {
        // Map position BEFORE writing
        sourceMapWriter.mapPosition(expr.pos);
        
        // Write the output
        buffer.add(output);
        
        // Track what was written
        sourceMapWriter.stringWritten(output);
    }
}
```

### 3. SourceMapLookup.ex (Elixir/Runtime Side)

Located at `lib/source_map_lookup.ex`, this module reverse-maps Elixir errors to Haxe source.

```elixir
# Key functions:
enhance_error_with_source_mapping(error)  # Add Haxe position to error
parse_source_map(path)                    # Load and parse .ex.map file
decode_vlq(encoded)                       # Decode VLQ positions (incomplete)
```

### 4. Mix Integration

The Mix compiler task (`lib/mix/tasks/compile.haxe.ex`) uses source maps to enhance error messages:

```elixir
defp format_errors(errors) do
  errors
  |> SourceMapLookup.enhance_errors_with_source_mapping()
  |> Enum.map(&format_single_error/1)
end
```

## Source Map v3 Specification

Reflaxe.Elixir implements the [Source Map v3](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k) specification.

### Format Structure
```json
{
  "version": 3,
  "file": "generated_file.ex",
  "sourceRoot": "",
  "sources": ["original.hx", "other.hx"],
  "names": [],
  "mappings": "AAAA,SAAS;AACT,GCAE"
}
```

### VLQ Encoding

Variable Length Quantity (VLQ) encoding compresses position data:
- Each mapping segment contains 4-5 values: [genCol, sourceIdx, sourceLine, sourceCol, nameIdx?]
- Values are delta-encoded (relative to previous position)
- Base64 encoding with continuation bits for compact storage

## Implementation Plan (Post-1.0)

### Why Use Haxe APIs

Haxe provides robust position tracking APIs that make source mapping reliable and efficient:
- **`Context.getPosInfos(pos)`** - Extract file, line, column from Position objects
- **`expr.pos`** - Every TypedExpr has position information from the parser
- **Position objects** - Already tracked throughout the AST by Haxe's type checker

Using these APIs ensures:
- ✅ **Reliability** - Position data is guaranteed accurate by Haxe's parser
- ✅ **Efficiency** - No need to track positions manually
- ✅ **Simplicity** - Just pass expr.pos to mapPosition() during compilation

### Simple Implementation Approach

The fix is straightforward - we need to connect three existing pieces:

1. **In CodeFixupCompiler.hx**: Actually create SourceMapWriter instances
```haxe
public function initSourceMapWriter(outputPath: String): Void {
    compiler.currentSourceMapWriter = new SourceMapWriter(outputPath);
    compiler.pendingSourceMapWriters.push(compiler.currentSourceMapWriter);
}
```

2. **In ElixirCompiler.hx**: Call mapPosition() before generating code
```haxe
override public function compileExpression(expr: TypedExpr): String {
    // Track position using Haxe's position API
    if (currentSourceMapWriter != null && expr.pos != null) {
        currentSourceMapWriter.mapPosition(expr.pos);
    }
    
    var result = super.compileExpression(expr);
    
    // Track generated output
    if (currentSourceMapWriter != null && result != null) {
        currentSourceMapWriter.stringWritten(result);
    }
    
    return result;
}
```

3. **Enable generation**: Set `sourceMapOutputEnabled = true` in compiler initialization

## Fixing the Integration (Detailed Steps)

### Step 1: Add Position Tracking to ElixirCompiler

The main issue is that ElixirCompiler never calls SourceMapWriter methods. We need to:

1. **Create SourceMapWriter instances** for each output file
2. **Call mapPosition()** before generating code from AST nodes
3. **Call stringWritten()** after adding to output buffer
4. **Generate source maps** when saving files

### Step 2: Key Integration Points

```haxe
// In ElixirCompiler.hx
override public function compileExpression(expr: TypedExpr): String {
    // Track position before compilation
    if (currentSourceMapWriter != null && expr.pos != null) {
        currentSourceMapWriter.mapPosition(expr.pos);
    }
    
    var result = super.compileExpression(expr);
    
    // Track generated output
    if (currentSourceMapWriter != null && result != null) {
        currentSourceMapWriter.stringWritten(result);
    }
    
    return result;
}
```

### Step 3: OutputManager Integration

The OutputManager (from Reflaxe base) handles file writing. We need to enhance it:

```haxe
// In OutputManager or custom extension
function saveFileWithSourceMap(path: String, content: String, sourceMap: SourceMapWriter) {
    // Save the .ex file
    saveFile(path, content);
    
    // Generate and save the .ex.map file
    sourceMap.generateSourceMap();
}
```

## Benefits When Working

### 1. Enhanced Error Messages
```elixir
# Current (without source mapping):
** (CompileError) lib/todo_app_web/router.ex:15: undefined function get/2

# With source mapping:
** (CompileError) src/TodoAppRouter.hx:25: undefined function get/2
    lib/todo_app_web/router.ex:15 (generated from src/TodoAppRouter.hx:25)
```

### 2. Debugger Support
- IDEs can set breakpoints in Haxe code
- Step through original source while debugging Elixir
- Stack traces reference original Haxe locations

### 3. LLM Agent Benefits
- Errors point to actual source code, not generated code
- Easier to understand compilation issues
- Direct correlation between input and output

## Implementation Priority

1. **High Priority**: Fix ElixirCompiler to call SourceMapWriter methods
2. **Medium Priority**: Complete VLQ decoding in SourceMapLookup.ex
3. **Low Priority**: Add source map support to additional Mix tasks

## Testing Source Maps

### Manual Testing
```bash
# 1. Compile with source maps
haxe build-server.hxml

# 2. Check .ex.map files exist
ls lib/**/*.ex.map

# 3. Verify mappings aren't empty
cat lib/todo_app_web/router.ex.map | jq '.mappings'
# Should see VLQ encoded data, not empty string
```

### Automated Testing
```elixir
# In test/source_map_test.exs
test "source maps contain valid mappings" do
  {:ok, source_map} = SourceMapLookup.parse_source_map("path/to/file.ex.map")
  assert source_map["mappings"] != ""
  assert length(source_map["sources"]) > 0
end
```

## Related Documentation

- [Mix Integration](/docs/04-api-reference/mix-integration.md) - How Mix uses source maps
- [Compiler Architecture](/docs/03-compiler-development/architecture.md) - Where source mapping fits
- [Error Handling](/docs/06-guides/troubleshooting.md#source-mapping) - Using source maps for debugging

## Future Enhancements

### Phase 1: Basic Position Mapping ✅ (Infrastructure exists)
- Map TypedExpr positions to generated code
- Generate valid Source Map v3 files
- Basic error enhancement

### Phase 2: Complete Integration 🚧 (Current work)
- Integrate with ElixirCompiler
- Track all AST node positions
- Complete VLQ decoder

### Phase 3: Advanced Features 📋 (Future)
- Name mappings for variable renaming
- Multiple source file support
- Inline source content in maps
- Source map composition for multi-stage compilation

## Appendix: Source Map Example

A properly generated source map for a simple Haxe→Elixir compilation:

**Input (Main.hx):**
```haxe
class Main {
    static function main() {
        trace("Hello");
    }
}
```

**Output (main.ex):**
```elixir
defmodule Main do
  def main() do
    IO.puts("Hello")
  end
end
```

**Source Map (main.ex.map):**
```json
{
  "version": 3,
  "file": "main.ex",
  "sourceRoot": "",
  "sources": ["Main.hx"],
  "names": [],
  "mappings": "AAAA;AACA,EACE;AACF"
}
```

The mappings encode:
- Line 1 of .ex maps to line 1 of .hx
- Line 2 (`def main()`) maps to line 2 (`static function main()`)
- Line 3 (`IO.puts`) maps to line 3 (`trace`)

When working correctly, clicking on an error in the Elixir code will jump to the corresponding Haxe source line.

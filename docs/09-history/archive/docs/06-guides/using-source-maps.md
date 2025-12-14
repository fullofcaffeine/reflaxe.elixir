# Using Source Maps for Haxe→Elixir Debugging

## What Are Source Maps and Why Do They Matter?

Source maps are JSON files that create a bridge between your original Haxe source code and the generated Elixir code. They enable debugging tools to show you the original source even when an error occurs in the generated code.

### Key Benefits

1. **Debug in Haxe, Not Generated Elixir**
   - Set breakpoints in your `.hx` files
   - Step through Haxe code logic
   - See Haxe variable names and structures

2. **Meaningful Error Messages**
   - Stack traces point to Haxe line numbers
   - Compilation errors show original source location
   - Runtime errors map back to your code

3. **LLM-Friendly Development**
   - AI assistants can understand errors in context
   - Better code navigation and understanding
   - Preserves semantic meaning across transformation

## Enabling Source Maps

### During Compilation

```bash
# Enable source maps with compiler flag
haxe build.hxml -D source_map_enabled

# Or add to your build.hxml
-D source_map_enabled
```

### In Mix Projects

```elixir
# In mix.exs, add to Haxe compiler options
def project do
  [
    haxe_options: ["-D", "source_map_enabled"],
    # ...
  ]
end
```

## How Source Maps Work

When enabled, the compiler generates `.ex.map` files alongside each `.ex` file:

```
lib/
├── my_app.ex          # Generated Elixir code
├── my_app.ex.map      # Source map linking to MyApp.hx
└── my_module.ex
└── my_module.ex.map
```

Each source map contains:
- **version**: Source Map specification version (v3)
- **sources**: Original Haxe files
- **mappings**: VLQ-encoded position mappings
- **names**: Original identifier names (when implemented)

## Debugging Scenarios

### 1. VS Code Debugging (Future Enhancement)

**Theoretical Integration** (not yet implemented):

```json
// .vscode/launch.json
{
  "type": "mix_task",
  "request": "launch",
  "name": "Debug Haxe→Elixir",
  "task": "phx.server",
  "sourceMaps": true,
  "sourceMapPathOverrides": {
    "lib/*.ex": "${workspaceFolder}/src_haxe/*.hx"
  }
}
```

**What Would Be Needed:**
1. VS Code extension that understands Elixir source maps
2. Debugger adapter that can map breakpoints
3. Integration with ElixirLS (Elixir Language Server)

### 2. Mix Compilation Error Enhancement (Current Focus)

When Mix encounters a compilation error, source maps can transform:

```elixir
# Without source maps
** (CompileError) lib/todo_app.ex:47: undefined function process_item/1

# With source maps  
** (CompileError) src_haxe/TodoApp.hx:23: undefined function processItem/1
                                     ^^^^ Original Haxe location!
```

### 3. Runtime Stack Trace Translation

Runtime errors can be mapped back:

```elixir
# Without source maps
** (ArgumentError) argument error
    lib/calculator.ex:89: Calculator.divide/2
    lib/main.ex:45: Main.run/0

# With source maps
** (ArgumentError) argument error
    src_haxe/Calculator.hx:15: Calculator.divide/2
    src_haxe/Main.hx:10: Main.run/0
```

## Manual Source Map Usage

### Reading Source Maps with Elixir

```elixir
defmodule SourceMapReader do
  @moduledoc """
  Decode source maps to find original Haxe positions
  """
  
  def find_original_position(ex_file, line, column) do
    map_file = ex_file <> ".map"
    
    with {:ok, content} <- File.read(map_file),
         {:ok, source_map} <- Jason.decode(content) do
      
      # Decode VLQ mappings
      decoded = decode_mappings(source_map["mappings"])
      
      # Find the mapping for this line/column
      mapping = find_mapping(decoded, line, column)
      
      # Return original position
      %{
        file: Enum.at(source_map["sources"], mapping.source_index),
        line: mapping.source_line,
        column: mapping.source_column
      }
    end
  end
  
  # VLQ decoder implementation needed here
  defp decode_mappings(mappings_string) do
    # Base64 VLQ decoding logic
    # See SourceMapLookup.ex for full implementation
  end
end
```

### Using with IEx (Elixir REPL)

```elixir
# In IEx, load source map helper
iex> c("source_map_reader.ex")

# When you get an error, map it back
iex> SourceMapReader.find_original_position("lib/main.ex", 47, 5)
%{file: "src_haxe/Main.hx", line: 23, column: 10}
```

## Browser DevTools Support (For Web Targets)

While Reflaxe.Elixir targets server-side Elixir, the source map format is the same as JavaScript:

```html
<!-- If generating client-side code -->
<script src="app.js"></script>
<!-- Browser automatically loads app.js.map -->
```

Modern browsers automatically:
- Load source maps when available
- Show original source in debugger
- Map console errors to source

## Integration with Error Reporting

### Sentry/Rollbar Integration

```elixir
defmodule ErrorReporter do
  def report_with_source_map(exception, stacktrace) do
    enhanced_stack = Enum.map(stacktrace, fn {module, fun, arity, location} ->
      file = location[:file]
      line = location[:line]
      
      # Map back to Haxe
      case SourceMapReader.find_original_position(file, line, 0) do
        {:ok, original} ->
          {module, fun, arity, Keyword.merge(location, [
            original_file: original.file,
            original_line: original.line
          ])}
        _ ->
          {module, fun, arity, location}
      end
    end)
    
    # Send to error tracking service
    Sentry.capture_exception(exception, stacktrace: enhanced_stack)
  end
end
```

## Command-Line Tools

### Source Map Validator

```bash
# Validate source map structure
mix haxe.source_map.validate lib/my_module.ex.map

# Decode specific position
mix haxe.source_map.decode lib/my_module.ex:45:10
# Output: src_haxe/MyModule.hx:23:5

# Show mapping coverage
mix haxe.source_map.coverage lib/
# Output: 78% of lines have mappings
```

## Current Limitations

### What's Working
- ✅ Source map generation infrastructure
- ✅ Basic position tracking for classes
- ✅ Valid Source Map v3 format

### What's Not Yet Implemented
- ❌ Fine-grained expression-level mappings
- ❌ VS Code debugging integration  
- ❌ Automatic stack trace translation
- ❌ Mix error enhancement
- ❌ Browser debugging (not applicable for Elixir)

### Implementation Roadmap

1. **Phase 1** (Current): Basic infrastructure
2. **Phase 2** (Next): Expression-level tracking
3. **Phase 3**: Mix integration for error messages
4. **Phase 4**: VS Code extension for debugging
5. **Phase 5**: Full debugging experience

## Best Practices

### For Library Authors
- Always generate source maps in debug/dev builds
- Include source maps in published packages
- Document source map availability

### For Application Developers  
- Enable source maps in development
- Consider keeping them in production for error tracking
- Use error reporting services that understand source maps

### For Debugging
- Keep original `.hx` files in version control
- Don't modify generated `.ex` files
- Use source maps for error reporting

## Troubleshooting

### Source Maps Not Generated
```bash
# Check if flag is set
haxe build.hxml -D source_map_enabled --display

# Verify output directory permissions
ls -la lib/
```

### Invalid Mappings
```bash
# Validate source map format
node -e "console.log(JSON.parse(require('fs').readFileSync('lib/main.ex.map')))"

# Check mapping coverage
grep -o ';' lib/main.ex.map | wc -l  # Count line mappings
```

### Performance Impact
- Source map generation adds ~5-10% compilation time
- No runtime performance impact
- File size overhead: ~30% of source file size

## Future Possibilities

### IDE Integration Vision

Imagine debugging Haxe→Elixir like TypeScript→JavaScript:
1. Set breakpoint in Haxe file
2. Run Elixir application  
3. Debugger stops at Haxe line
4. Step through Haxe code
5. Inspect Haxe variables

### AI-Assisted Debugging

With source maps, AI assistants could:
- Understand errors in original context
- Suggest fixes in Haxe, not generated Elixir
- Navigate codebase using semantic meaning
- Provide better completion and refactoring

## Technical Reference

### Source Map Specification
- [Source Map Revision 3](https://sourcemaps.info/spec.html)
- [Base64 VLQ Encoding](https://www.lucidchart.com/techblog/2019/08/22/decode-base64-vlq-source-map-mappings/)

### Related Tools
- [ElixirLS](https://github.com/elixir-lsp/elixir-ls) - Language server
- [VS Code Elixir](https://marketplace.visualstudio.com/items?itemName=JakeBecker.elixir-ls) - Editor support
- [source-map](https://www.npmjs.com/package/source-map) - JavaScript library for manipulation

## Contributing

Help improve source map support:
1. Test and report issues
2. Contribute to VS Code extension
3. Improve mapping granularity
4. Add debugging tools

---

*Note: Source map support is actively being developed. This documentation reflects the current state and future vision.*
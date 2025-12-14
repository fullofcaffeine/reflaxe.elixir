# Source Mapping Status & Implementation Plan

## Current Status (August 2025)

### ✅ What's Complete
1. **SourceMapWriter.hx** - Full implementation of Source Map v3 specification
   - VLQ encoding for compact position storage
   - Position tracking infrastructure
   - JSON output generation
   
2. **Infrastructure in ElixirCompiler** - Hooks and placeholders ready
   - `currentSourceMapWriter` field declared
   - `initSourceMapWriter()` and `finalizeSourceMapWriter()` methods exist
   - `pendingSourceMapWriters` array for batch processing

3. **Mix Integration** - Ready to consume source maps
   - SourceMapLookup.ex module for reading maps
   - Error enhancement infrastructure in HaxeCompiler
   - Mix tasks prepared to display enhanced errors

4. **Tests** - Comprehensive test coverage created
   - `test/source_map_test.exs` - Elixir-side tests
   - `test/tests/SourceMapGeneration/` - Snapshot test
   - Test script for validation

5. **Documentation** - Complete architecture guide
   - [Source Mapping Architecture](/docs/05-architecture/source-mapping.md)
   - Implementation plan with code examples
   - Integration with Haxe position APIs documented

### ❌ What's Missing (Post-1.0)
1. **Actual Position Tracking** - The critical missing piece
   - `mapPosition()` is never called during compilation
   - No connection between AST traversal and source mapping
   - Placeholder methods don't create SourceMapWriter instances

2. **VLQ Decoder** - Elixir side incomplete
   - SourceMapLookup.decode_vlq() not implemented
   - Can't reverse-map positions without decoder

3. **Compiler Flag** - Not wired up
   - `-D source_map_enabled` flag exists but isn't checked
   - `sourceMapOutputEnabled` always false in ElixirCompiler

## Why It's Not Working

The infrastructure is complete but disconnected. It's like having:
- 🚗 A car (SourceMapWriter)
- ⛽ Fuel (Position data from Haxe)
- 🛣️ A road (Output system)
- But no driver to connect them!

## Simple Fix Required (Post-1.0)

### Phase 1: Connect Existing Infrastructure (2-3 hours)
```haxe
// In CodeFixupCompiler.hx - replace placeholder with:
public function initSourceMapWriter(outputPath: String): Void {
    if (compiler.options.getDefine("source_map_enabled") != null) {
        compiler.currentSourceMapWriter = new SourceMapWriter(outputPath);
        compiler.pendingSourceMapWriters.push(compiler.currentSourceMapWriter);
        compiler.sourceMapOutputEnabled = true;
    }
}

// In ElixirCompiler.hx - add to compileExpression():
if (currentSourceMapWriter != null && expr.pos != null) {
    currentSourceMapWriter.mapPosition(expr.pos);
}
// ... generate code ...
if (currentSourceMapWriter != null && result != null) {
    currentSourceMapWriter.stringWritten(result);
}
```

### Phase 2: Complete VLQ Decoder (1-2 hours)
```elixir
# In SourceMapLookup.ex
def decode_vlq(encoded) do
  # Implement VLQ decoding per Source Map v3 spec
  # Convert Base64 VLQ to position deltas
end
```

### Phase 3: Test & Validate (1 hour)
- Run `test/tests/SourceMapGeneration/test_source_map.sh`
- Verify mappings are populated
- Test error enhancement with real compilation errors

## Benefits When Complete

### For Developers
- **Debugging** - Set breakpoints in Haxe, debug in Elixir
- **Error Messages** - See original Haxe source in error reports
- **Navigation** - Jump from generated code to source

### For LLM Agents
- **Context** - Errors reference actual source, not generated code
- **Understanding** - Direct correlation between input and output
- **Fixes** - Can suggest fixes in Haxe, not Elixir

## Testing Infrastructure Ready

### Tests Created
```bash
# Elixir tests (3 passing, 2 pending)
MIX_ENV=test mix test test/source_map_test.exs

# Snapshot test
cd test/tests/SourceMapGeneration && ./test_source_map.sh

# Current output:
✓ Elixir files generated
✗ No source map files generated (expected until implementation)
```

### Test Coverage
- File generation validation ✅
- JSON structure validation ✅
- Mapping content validation 🔄 (pending)
- VLQ decoding 🔄 (pending)
- Error enhancement 🔄 (pending)

## Why This is Post-1.0

1. **Core Functionality First** - Compiler must generate correct code
2. **Not Breaking** - Missing source maps don't break compilation
3. **Enhancement** - This improves DX but isn't essential
4. **Clean Implementation** - Better to do it right than rush it

## Implementation Checklist

When implementing post-1.0:

- [ ] Enable `-D source_map_enabled` flag checking
- [ ] Connect SourceMapWriter creation in CodeFixupCompiler
- [ ] Add mapPosition() calls in expression compilation
- [ ] Add stringWritten() calls after output generation
- [ ] Implement VLQ decoder in Elixir
- [ ] Update tests to remove @pending tags
- [ ] Validate with todo-app example
- [ ] Document usage in user guide

## Related Documentation

- [Source Mapping Architecture](/docs/05-architecture/source-mapping.md) - Complete technical details
- [Mix Integration](/docs/04-api-reference/mix-integration.md) - How Mix uses source maps
- [Testing Infrastructure](/docs/03-compiler-development/testing-infrastructure.md) - Test setup

---

**Status**: Infrastructure complete, implementation deferred to post-1.0 release.
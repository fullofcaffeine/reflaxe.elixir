# Source Mapping Implementation Plan

## Executive Summary

Source mapping support exists but is disconnected. We have:
- ✅ Complete SourceMapWriter.hx (VLQ encoding, position tracking)
- ✅ Mix integration ready (SourceMapLookup.ex)
- ❌ No connection between AST traversal and position mapping
- ❌ Incomplete VLQ decoder on Elixir side

**Total Effort**: 28-40 hours for production-ready implementation
**MVP Effort**: 12-15 hours for basic functionality

## Current State Analysis

### What's Already Done
1. **SourceMapWriter.hx** (100% complete)
   - Full Source Map v3 implementation
   - VLQ Base64 encoding
   - Position tracking methods
   - JSON generation

2. **Infrastructure Hooks** (50% complete)
   - Fields declared in ElixirCompiler
   - Placeholder methods in CodeFixupCompiler
   - Mix error enhancement ready

3. **Tests** (Framework ready, implementation pending)
   - Elixir test suite created
   - Snapshot test structure
   - Validation scripts

### Critical Missing Pieces
1. **Position Mapping Calls** - `mapPosition()` is never invoked
2. **SourceMapWriter Creation** - Placeholders don't create instances
3. **VLQ Decoder** - Elixir can't read the mappings
4. **Compiler Flag** - `-D source_map_enabled` not checked properly

## Implementation Phases

### Phase 1: Foundation Setup (1.5 hours) ⚡ QUICK WIN

#### Task 1.1: Enable Source Mapping Flag
**File**: `src/reflaxe/elixir/ElixirCompiler.hx:348`
```haxe
// Current (broken):
this.sourceMapOutputEnabled = Context.defined("source-map") || Context.defined("debug");

// Fix to:
this.sourceMapOutputEnabled = Context.defined("source_map_enabled") || 
                               Context.defined("source-map") || 
                               Context.defined("debug");
```
**Effort**: 30 minutes
**Priority**: CRITICAL - Blocks everything else

#### Task 1.2: Create Real SourceMapWriter Instances
**File**: `src/reflaxe/elixir/helpers/CodeFixupCompiler.hx:269-305`
```haxe
// Replace placeholder with actual implementation:
public function initSourceMapWriter(outputPath: String): Void {
    if (compiler.sourceMapOutputEnabled) {
        var writer = new SourceMapWriter(outputPath);
        compiler.currentSourceMapWriter = writer;
        compiler.pendingSourceMapWriters.push(writer);
        
        #if debug_source_map
        trace('[SourceMap] Initialized for: ${outputPath}');
        #end
    }
}

public function finalizeSourceMapWriter(): Null<String> {
    if (compiler.currentSourceMapWriter != null) {
        var mapPath = compiler.currentSourceMapWriter.generateSourceMap();
        compiler.currentSourceMapWriter = null;
        
        #if debug_source_map
        trace('[SourceMap] Generated: ${mapPath}');
        #end
        
        return mapPath;
    }
    return null;
}
```
**Effort**: 1 hour
**Priority**: CRITICAL

### Phase 2: Core Position Mapping (10-14 hours) 🔧 MAIN WORK

#### Task 2.1: Add Position Tracking to Expression Compilation
**Strategy**: Wrap key compilation methods with position mapping

**Key Integration Points**:
1. `compileExpression()` - Main expression handler
2. `compileClass()` - Class definition starts
3. `compileEnum()` - Enum definition starts
4. `compileFunction()` - Function body starts
5. `compileSwitch()` - Switch case positions

**Implementation Pattern**:
```haxe
// Add helper method to ElixirCompiler:
private function trackPosition(pos: Position): Void {
    if (currentSourceMapWriter != null && pos != null) {
        currentSourceMapWriter.mapPosition(pos);
    }
}

private function trackOutput(output: String): Void {
    if (currentSourceMapWriter != null && output != null) {
        currentSourceMapWriter.stringWritten(output);
    }
}

// Then in compilation methods:
override public function compileExpression(expr: TypedExpr): String {
    trackPosition(expr.pos);
    
    var result = switch(expr.expr) {
        case TConst(c): compileConstant(c);
        case TLocal(v): compileVariable(v);
        case TCall(e, el): compileCall(e, el, expr.pos);
        // ... all cases
    };
    
    trackOutput(result);
    return result;
}
```

**Specific Files to Modify**:
- `ElixirCompiler.hx` - Main compilation methods (~20 locations)
- `helpers/ClassCompiler.hx` - Class member positions (~5 locations)
- `helpers/EnumCompiler.hx` - Enum constructor positions (~3 locations)
- `helpers/PatternMatchingCompiler.hx` - Case positions (~5 locations)

**Effort**: 8-10 hours (tedious but straightforward)
**Priority**: HIGH - Core functionality

#### Task 2.2: Integrate with Output System
**Challenge**: DirectToStringCompiler manages file writing
**Solution**: Hook into the output generation process

**Options**:
1. Override `generateOutputIterator()` to wrap output
2. Modify `compileClass/Enum/Typedef` return values
3. Add position tracking to string concatenation

**Recommended Approach**:
```haxe
// In ElixirCompiler, override compilation entry points:
override public function compileClass(c: ClassType, varFields: Array<String>): String {
    // Initialize source mapping for this class
    var className = getClassName(c);
    trackPosition(c.pos);
    
    var result = super.compileClass(c, varFields);
    
    trackOutput(result);
    return result;
}
```

**Effort**: 4-6 hours
**Priority**: HIGH - Required for file-level mapping

### Phase 3: VLQ Decoder Implementation (6-8 hours) 🔍

#### Task 3.1: Implement Elixir VLQ Decoder
**File**: `lib/source_map_lookup.ex:256-278`

**Current Mock Implementation**:
```elixir
def decode_vlq(_encoded) do
  # Mock implementation
  [{0, 0, 0, 0}]
end
```

**Required Implementation**:
```elixir
@vlq_chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

def decode_vlq(encoded) when is_binary(encoded) do
  encoded
  |> String.to_charlist()
  |> decode_vlq_chars([])
  |> Enum.reverse()
end

defp decode_vlq_chars([], acc), do: acc
defp decode_vlq_chars(chars, acc) do
  {value, rest} = decode_vlq_value(chars, 0, 0)
  decoded = if rem(value, 2) == 1, do: -(div(value, 2) + 1), else: div(value, 2)
  decode_vlq_chars(rest, [decoded | acc])
end

defp decode_vlq_value([char | rest], acc, shift) do
  index = :binary.match(@vlq_chars, <<char>>) |> elem(0)
  digit = index &&& 0x1F
  acc = acc + (digit <<< shift)
  
  if (index &&& 0x20) > 0 do
    decode_vlq_value(rest, acc, shift + 5)
  else
    {acc, rest}
  end
end
```

**Testing**: Use known VLQ sequences from Source Map v3 spec
**Effort**: 4-5 hours
**Priority**: MEDIUM - Needed for error enhancement

#### Task 3.2: Optimize Lookup Performance
**Requirements**:
- Index mappings by line number
- Binary search for position ranges
- Cache decoded mappings

**Effort**: 2-3 hours
**Priority**: LOW - Can optimize later

### Phase 4: Error Integration (4-6 hours) 📍

#### Task 4.1: Enhance Mix Compilation Errors
**File**: `lib/mix/tasks/compile.haxe.ex`

**Integration Points**:
1. Parse Elixir compilation errors
2. Extract file and line number
3. Look up source position in .ex.map
4. Enhance error with Haxe location

**Implementation**:
```elixir
defp enhance_error_with_source_map(error) do
  case SourceMapLookup.find_source_position(error.file, error.line, error.column) do
    {:ok, %{source: haxe_file, line: haxe_line, column: haxe_column}} ->
      %{error | 
        original_file: haxe_file,
        original_line: haxe_line,
        original_column: haxe_column,
        message: "#{error.message}\n  (from #{haxe_file}:#{haxe_line}:#{haxe_column})"
      }
    _ ->
      error
  end
end
```

**Effort**: 4-6 hours
**Priority**: MEDIUM - Nice to have

### Phase 5: Testing & Validation (6-10 hours) ✅

#### Task 5.1: Basic Test Validation
**Location**: `test/tests/SourceMapGeneration/`
- Verify .ex.map files are generated
- Check mappings are non-empty
- Validate JSON structure
- Test VLQ decoding

**Effort**: 2-3 hours
**Priority**: HIGH

#### Task 5.2: Comprehensive Test Suite
**New Tests Needed**:
1. **Position Accuracy Test**
   - Map known positions
   - Verify correct line/column

2. **Complex Expression Test**
   - Nested expressions
   - Lambda functions
   - Pattern matching

3. **Multi-file Test**
   - Multiple source files
   - Cross-file references

4. **Performance Test**
   - Large file compilation
   - Measure overhead

**Effort**: 4-7 hours
**Priority**: MEDIUM

## Implementation Order

### MVP Path (12-15 hours) 🎯
1. **Phase 1**: Foundation (1.5 hours)
2. **Phase 2**: Core Integration (10-14 hours)
3. **Task 5.1**: Basic Testing (2-3 hours)

This gives basic source mapping functionality.

### Production Path (28-40 hours) 💎
1. **MVP Path** (12-15 hours)
2. **Phase 3**: VLQ Decoder (6-8 hours)
3. **Phase 4**: Error Integration (4-6 hours)
4. **Task 5.2**: Full Testing (4-7 hours)

This gives complete source mapping with error enhancement.

## Success Criteria

### MVP Success
- [ ] Source map files generated for all .ex files
- [ ] Mappings contain valid VLQ data (not empty)
- [ ] Basic test passes

### Production Success
- [ ] All positions correctly mapped
- [ ] Errors show Haxe source location
- [ ] VLQ decoder handles all cases
- [ ] Performance overhead < 10%
- [ ] All tests passing

## Risk Mitigation

### Risk 1: Performance Impact
**Mitigation**: Add conditional compilation flag to disable in production

### Risk 2: Complex AST Patterns
**Mitigation**: Start with simple expressions, add complex ones incrementally

### Risk 3: DirectToStringCompiler Integration
**Mitigation**: Study Reflaxe reference implementation first

## Debug Helpers

Add these debug flags for development:
```hxml
-D debug_source_map        # Trace all position mappings
-D debug_vlq              # Trace VLQ encoding/decoding
-D source_map_validate    # Validate all mappings
```

## Validation Script

Create `validate_source_maps.sh`:
```bash
#!/bin/bash
# Validate all source maps in project

for map in $(find lib -name "*.ex.map"); do
  echo "Checking $map..."
  
  # Check JSON validity
  jq . "$map" > /dev/null || echo "Invalid JSON!"
  
  # Check mappings not empty
  mappings=$(jq -r '.mappings' "$map")
  if [ -z "$mappings" ]; then
    echo "Empty mappings!"
  fi
  
  # Count sources
  sources=$(jq '.sources | length' "$map")
  echo "  Sources: $sources"
  
  # Sample mappings
  echo "  Mappings: ${mappings:0:50}..."
done
```

## Next Steps

1. **Immediate**: Fix compiler flag (Task 1.1) - 30 minutes
2. **Today**: Implement SourceMapWriter creation (Task 1.2) - 1 hour
3. **This Week**: Start position mapping integration (Task 2.1) - Begin systematic integration
4. **MVP Target**: 2-3 days of focused work
5. **Production Target**: 1-2 weeks with testing

## Related Documentation

- [Source Mapping Architecture](/docs/05-architecture/source-mapping.md)
- [Source Mapping Status](/docs/05-architecture/source-mapping-status.md)
- [Testing Infrastructure](/docs/03-compiler-development/testing-infrastructure.md)

---

**Priority**: Post-1.0 (unless developer experience becomes blocking issue)
**Owner**: TBD
**Status**: Implementation plan complete, awaiting execution
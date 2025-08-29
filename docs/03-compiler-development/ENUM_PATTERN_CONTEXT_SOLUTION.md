# Enum Pattern Context Tracking Solution

## Problem Statement

Enum pattern variables in switch cases were being incorrectly mapped to `g_array` instead of the extracted enum parameters (`g_param_0`, `g_param_1`, etc.). This caused compilation errors in generated Elixir code.

## Root Cause Analysis

### The Context Loss Problem

1. **Compilation Phase Separation**: PatternMatchingCompiler and VariableCompiler run in different phases
2. **Context Not Persistent**: Runtime flags like `currentSwitchCaseBody` are lost between phases
3. **No Metadata Tracking**: TVars created for enum patterns lack contextual metadata

### AST Structure Discovery

```haxe
// Expected structure
case EnumConstructor(param):
    TBlock([
        TVar(g_param_0, TEnumParameter(...)),
        TVar(param, TLocal(g_param_0)),
        // case body
    ])

// Actual structure found
case EnumConstructor(param):
    TBinop(OpAssignOp,
        TVar(g_param_0, TEnumParameter(...)),
        TBinop(OpAssignOp,
            TVar(param, TLocal(g_param_0)),
            // case body
        )
    )
```

## Solution Architecture

### Immediate Fix (Implemented)

Override `g_array` mapping when enum extraction variables are detected:

```haxe
// In VariableCompiler.hx
if (enumExtractionVars.exists(name)) {
    var extractionName = enumExtractionVars.get(name);
    return extractionName; // Use g_param_0 instead of g_array
}
```

### Long-term Architectural Solution

#### 1. Metadata-Based Context Tracking

Following Reflaxe's established pattern (like `-reflaxe.unused`), add metadata to track enum pattern context:

```haxe
// When TVar is created in enum pattern context
tvar.meta.add("-reflaxe.enumPattern", [
    { expr: EConst(CString(enumFieldName)), pos: pos },
    { expr: EConst(CInt(paramIndex)), pos: pos }
], pos);
```

#### 2. Context Abstraction Layer

Create a dedicated helper class to manage enum pattern context:

```haxe
class EnumPatternContext {
    // Track enum pattern variables with metadata
    public static function markEnumPatternVar(tvar: TVar, context: EnumPatternInfo): Void;
    
    // Check if a TVar is from enum pattern extraction
    public static function isEnumPatternVar(tvar: TVar): Bool;
    
    // Get the extraction variable name for a pattern var
    public static function getExtractionVar(tvar: TVar): String;
}
```

## Implementation Details

### Created Abstraction: EnumPatternContext

We created a metadata-based abstraction layer for tracking enum pattern context across compilation phases:

```haxe
// src/reflaxe/elixir/helpers/EnumPatternContext.hx
class EnumPatternContext {
    static inline final ENUM_PATTERN_META = "-reflaxe.enumPattern";
    
    // Mark a TVar with enum pattern metadata
    public static function markEnumPatternVar(tvar: TVar, info: EnumPatternInfo, pos: Position): Void {
        var params = [
            { expr: EConst(CString(info.enumField)), pos: pos },
            { expr: EConst(CInt(Std.string(info.paramIndex))), pos: pos },
            { expr: EConst(CString(info.extractionVar)), pos: pos }
        ];
        
        if (info.originalVar != null) {
            params.push({ expr: EConst(CString(info.originalVar)), pos: pos });
        }
        
        tvar.meta.maybeAdd(ENUM_PATTERN_META, params, pos);
    }
    
    // Check if a TVar has enum pattern metadata
    public static function isEnumPatternVar(tvar: TVar): Bool {
        return tvar.meta != null && tvar.meta.has(ENUM_PATTERN_META);
    }
    
    // Get extraction variable from metadata
    public static function getExtractionVar(tvar: TVar): Null<String> {
        if (tvar.meta == null) return null;
        
        var meta = tvar.meta.extract(ENUM_PATTERN_META);
        if (meta.length == 0) return null;
        
        // Return the extraction variable name (third parameter)
        var params = meta[0].params;
        if (params != null && params.length >= 3) {
            switch (params[2].expr) {
                case EConst(CString(s)): return s;
                case _:
            }
        }
        return null;
    }
}
```

### Integration Points

#### 1. VariableCompiler Integration (Partially Implemented)

```haxe
// When compiling TEnumParameter extraction
if (tvar != null) {
    var info: EnumPatternInfo = {
        extractionVar: uniqueVarName,
        enumField: enumField.name,
        paramIndex: index
    };
    EnumPatternContext.markEnumPatternVar(tvar, info, expr.pos);
}

// When compiling TLocal references
var enumExtractionVar = EnumPatternContext.getExtractionVar(v);
if (enumExtractionVar != null) {
    return enumExtractionVar; // Use metadata-tracked extraction variable
}
```

#### 2. PatternMatchingCompiler Integration (TODO)

The abstraction should also be used to track switch expression variables to prevent variable name mismatches in case statements.

### Phase 1: Documentation and Current Fix Stabilization ✓
- Document all findings comprehensively ✓
- Create EnumPatternContext abstraction ✓
- Integrate metadata marking in VariableCompiler ✓
- Add comprehensive debug traces ✓

### Phase 2: Full Integration (In Progress)
- Complete metadata checking in VariableCompiler
- Add metadata injection in PatternMatchingCompiler for switch variables
- Update all enum pattern handling to use the abstraction
- Maintain backward compatibility with enumExtractionVars

### Phase 3: Cleanup and Optimization
- Remove direct enumExtractionVars map access
- Centralize all enum pattern tracking through EnumPatternContext
- Add validation and error handling
- Performance optimization if needed

## Benefits of This Approach

1. **Persistent Context**: Metadata survives across compilation phases
2. **Follows Reflaxe Patterns**: Uses established `-reflaxe.*` metadata convention
3. **Clean Architecture**: Proper abstraction instead of ad-hoc fixes
4. **Backward Compatible**: Current fix remains as fallback
5. **Debuggable**: Metadata visible in AST dumps

## Testing Strategy

1. **Regression Test**: `underscore_prefix_consistency` test ensures fix works
2. **Todo-App Validation**: Primary integration test for real-world patterns
3. **Metadata Verification**: Check metadata is properly added and retrieved

## Related Issues Fixed

- Orphaned `g_array` variables in enum switch cases
- Incorrect variable mapping for enum pattern parameters
- Context loss between compiler phases

## Future Improvements

1. **Generalize Pattern**: Apply metadata tracking to other pattern types
2. **Optimize Detection**: Cache metadata lookups for performance
3. **Enhanced Debugging**: Add AST visualization for pattern contexts

## References

- [MarkUnusedVariablesImpl.hx](../../reference/reflaxe/src/reflaxe/preprocessors/implementations/MarkUnusedVariablesImpl.hx) - Metadata pattern example
- [ENUM_PATTERN_VARIABLE_FIX_PRD.md](./ENUM_PATTERN_VARIABLE_FIX_PRD.md) - Original problem documentation
- [PatternMatchingCompiler.hx](../../src/reflaxe/elixir/helpers/PatternMatchingCompiler.hx) - Pattern compilation logic
- [VariableCompiler.hx](../../src/reflaxe/elixir/helpers/VariableCompiler.hx) - Variable name resolution
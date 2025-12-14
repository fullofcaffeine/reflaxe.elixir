# Variable Mapping Architecture in Reflaxe.Elixir

## Overview

This document describes how variable mappings work in the Reflaxe.Elixir compiler, particularly focusing on the complex case of Haxe's desugared expressions and the g vs g_array mismatch issue.

## The Problem: Haxe's Desugaring Creates Mismatched Variable References

### What Haxe Does

When you write:
```haxe
switch (Type.typeof(value)) {
    case TNull: // ...
    case TInt: // ...
}
```

Haxe desugars this into a TBlock containing:
1. `TVar(g, Type.typeof(value))` - Assigns result to temp variable
2. `TSwitch(TLocal(g), cases)` - Switches on that temp variable

### The Issue

Our compiler renames the TVar to "g_array" (for clarity in generated Elixir), but the TLocal still references "g", causing undefined variable errors:

```elixir
# Generated (WRONG):
g_array = Type.typeof(value)
case g do  # ERROR: g is undefined!
  :t_null -> ...
end

# Should be:
g_array = Type.typeof(value)
case g_array do
  :t_null -> ...
end
```

## The Data Flow Through Compiler Components

### 1. AST Reception
- Haxe provides a fully-typed AST with TBlock[TVar, TSwitch]
- The TVar and TLocal share the same TVar.id internally

### 2. Block Compilation (ControlFlowCompiler)
```haxe
compileBlock(expressions) ->
  for each expression:
    compile(expression)
```

### 3. Variable Declaration (VariableCompiler)
```haxe
compileVariableDeclaration(TVar(g, Type.typeof())) ->
  1. Detect Type.typeof pattern
  2. Register mapping: TVar.id -> "g_array"
  3. Generate: "g_array = Type.typeof(value)"
```

### 4. Switch Compilation (PatternMatchingCompiler)
```haxe
compileSwitch(TSwitch(TLocal(g), cases)) ->
  1. Compile switch expression: TLocal(g)
  2. TLocal goes to ExpressionVariantCompiler
```

### 5. Variable Reference (ExpressionVariantCompiler)
```haxe
case TLocal(v):
  variableCompiler.compileVariableReference(v) ->
    Check variableIdMap[v.id] ->
      Should return "g_array" (if mapping exists)
```

## The Variable Mapping Systems

### 1. ID-Based Mapping (Primary)
- **Storage**: `variableIdMap: Map<Int, String>`
- **Key**: TVar.id (unique integer)
- **Purpose**: Map specific variable instances to renamed versions
- **Priority**: Highest - checked first

### 2. Name-Based Mapping (Fallback)
- **Storage**: `currentFunctionParameterMap: Map<String, String>`
- **Key**: Variable name (string)
- **Purpose**: General name transformations
- **Priority**: Lower - used when no ID mapping exists

### 3. Rename Tracking
- **Storage**: `variableRenameMap: Map<String, String>`
- **Purpose**: Track all transformations (snake_case conversions, etc.)

## The Critical Fix Points

### Detection Point (VariableCompiler.compileVariableDeclaration)
```haxe
// When we see TVar(g, expr):
if (isTypeTypeofCall(expr)) {
    // 1. Register ID mapping
    registerVariableMapping(tvar, "g_array");
    
    // 2. Register name mapping
    currentFunctionParameterMap.set("g", "g_array");
    
    // 3. Use mapped name for declaration
    varName = "g_array";
}
```

### Resolution Point (VariableCompiler.compileVariableReference)
```haxe
// When we see TLocal(v):
if (variableIdMap.exists(v.id)) {
    return variableIdMap.get(v.id); // Returns "g_array"
}
```

## Why Previous Fixes Failed

### Attempt 1: String Parsing
- **Tried**: Extract variable from "g_array = ..." string
- **Problem**: Band-aid fix, not architectural solution

### Attempt 2: Fallback Mechanism
- **Tried**: Check currentFunctionParameterMap when ID mapping missing
- **Problem**: Quick fix, not addressing root cause

### Attempt 3: Pre-Registration
- **Tried**: Register mappings before compiling block
- **Problem**: Timing issue - mappings not available when needed

### Root Cause
The mapping was being registered but not applied to the actual variable declaration. We registered `TVar.id -> "g_array"` but still generated `g = Type.typeof(value)`.

## The Solution

### Step 1: Detect Pattern
In `compileVariableDeclaration`, detect when initializing with Type.typeof():
```haxe
if (isTypeTypeofPattern(expr)) {
    needsArrayMapping = true;
}
```

### Step 2: Register Mapping
Register both ID and name mappings:
```haxe
if (needsArrayMapping) {
    registerVariableMapping(tvar, "g_array");
    currentFunctionParameterMap.set("g", "g_array");
}
```

### Step 3: Apply Mapping
Actually use the mapped name for the declaration:
```haxe
if (needsArrayMapping) {
    varName = "g_array"; // CRITICAL: Actually use the mapped name!
}
```

### Step 4: Resolution
When TLocal is compiled, it checks the ID mapping:
```haxe
case TLocal(v):
    return variableCompiler.compileVariableReference(v);
    // This checks variableIdMap[v.id] and returns "g_array"
```

## Testing the Fix

### Test Case
```haxe
// Input (Haxe):
switch (Type.typeof(value)) {
    case TNull: this.field = this.field + "null";
    case TInt: this.field = this.field + Std.string(value);
    default: this.field = this.field + "other";
}
```

### Expected Output
```elixir
# Correct:
g_array = Type.typeof(value)
case g_array do
  :t_null -> struct = %{struct | field: struct.field <> "null"}
  :t_int -> struct = %{struct | field: struct.field <> Std.string(value)}
  _ -> struct = %{struct | field: struct.field <> "other"}
end
```

## Related Files

### Core Implementation
- `src/reflaxe/elixir/helpers/VariableCompiler.hx` - Variable declaration and reference compilation
- `src/reflaxe/elixir/helpers/ExpressionVariantCompiler.hx` - TLocal handling
- `src/reflaxe/elixir/helpers/PatternMatchingCompiler.hx` - Switch compilation
- `src/reflaxe/elixir/helpers/ControlFlowCompiler.hx` - Block compilation

### Documentation
- `docs/03-compiler-development/G_ARRAY_MISMATCH_ISSUE.md` - Original issue documentation
- `docs/03-compiler-development/AST_CLEANUP_PATTERNS.md` - Related AST patterns

## Key Lessons

1. **Understand the complete data flow** - Variable mapping happens at multiple points
2. **Both registration AND application are needed** - Registering a mapping isn't enough; you must apply it
3. **ID-based mapping is primary** - TVar.id is the authoritative identifier
4. **Haxe's desugaring creates complexity** - What looks simple in source becomes complex in AST

## Implementation Checklist

When fixing variable mapping issues:

- [ ] Identify where the variable is declared (TVar)
- [ ] Identify where the variable is referenced (TLocal)
- [ ] Ensure ID mapping is registered at declaration
- [ ] Ensure mapped name is used in declaration
- [ ] Verify TLocal resolution uses ID mapping
- [ ] Test with actual code generation

## Common Patterns Requiring Mapping

1. **Type.typeof() switches** - Creates g -> g_array mapping
2. **Array desugaring** - Creates g_counter, g_limit mappings
3. **Lambda parameters** - Parameter renaming for clarity
4. **State threading** - _this -> struct mappings

## Debugging Variable Mapping Issues

### 1. Enable Debug Output
```haxe
-D debug_variable_compiler
-D debug_expression_variants
-D debug_pattern_matching
```

### 2. Check Mapping Registration
Look for: `REGISTERED MAPPING: TVar.id=X -> g_array`

### 3. Check Mapping Resolution
Look for: `Found ID mapping: g(X) -> g_array`

### 4. Verify Generated Code
Check actual .ex output files for variable mismatches

## Future Improvements

1. **Centralized mapping system** - Single source of truth for all mappings
2. **Validation pass** - Check all TLocal references have valid mappings
3. **Better debug visibility** - Make trace statements work in macro context
4. **Comprehensive tests** - Test all desugaring patterns
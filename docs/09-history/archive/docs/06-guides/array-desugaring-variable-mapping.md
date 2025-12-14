# Array Desugaring Variable Mapping Guide

**Critical Fix Documentation**: This guide documents the resolution of undefined `_g` variable errors in enum parameter extraction contexts.

## 🚨 Problem Summary

When Haxe array operations (like `array.filter()`, `array.map()`) are compiled, they generate temporary variables prefixed with `_g`:
- `_g` - Base array variable
- `_g_array` - Array element
- `_g_counter` - Loop counter

However, the VariableMappingManager establishes mappings like `_g` → `g_array` to create idiomatic Elixir variable names. When enum parameter extraction uses `elem()` functions, it needs to reference these variables correctly.

### The Error Pattern
```elixir
# ❌ ERROR: Undefined variable "_g"
g_array = elem(_g, 1)    # _g is undefined!

# ✅ CORRECT: Properly mapped variable  
g_array = elem(g_array, 1)  # Uses mapped variable name
```

## 🔍 Root Cause Analysis

### Issue Location 1: EnumIntrospectionCompiler.hx

The EnumIntrospectionCompiler generates `elem()` calls for enum parameter extraction:

```haxe
// BEFORE: Didn't apply variable mappings
var enumExpr = compiler.compileExpression(e);
return 'elem(${enumExpr}, ${index})';  // Generated: elem(_g, 1)
```

**Problem**: TLocal expressions for `_g` variables were compiled without applying the `_g` → `g_array` mappings established by VariableMappingManager.

### Issue Location 2: VariableCompiler.hx

The VariableCompiler had blocking logic that prevented array variable mappings in enum extraction contexts:

```haxe
// BEFORE: Blocked array desugaring mappings
if (compiler.isInEnumExtraction && originalName.charAt(0) == '_' && ~/^_g\d*$/.match(originalName)) {
    return originalName; // WRONG: Prevented mapping
}
```

**Problem**: This logic incorrectly blocked the `_g` → `g_array` mapping when inside enum parameter extraction, causing undefined variables.

## ✅ Solution Implementation

### Fix 1: Enhanced EnumIntrospectionCompiler

Modified `compileEnumParameterExpression()` to apply variable mappings for TLocal expressions:

```haxe
// AFTER: Apply variable mappings for TLocal expressions
var enumExpr = switch(e.expr) {
    case TLocal(v):
        // Check if this variable has a mapping (like _g -> g_array)
        if (compiler.currentFunctionParameterMap.exists(v.name)) {
            var mapped = compiler.currentFunctionParameterMap.get(v.name);
            #if debug_enum_introspection_compiler
            trace('[EnumIntrospectionCompiler] ✓ Applied variable mapping: ${v.name} → ${mapped}');
            #end
            mapped;
        } else {
            v.name;
        }
    case _:
        compiler.compileExpression(e);
};

return 'elem(${enumExpr}, ${index})';  // Now generates: elem(g_array, 1)
```

### Fix 2: Removed Blocking Logic in VariableCompiler

Simplified `compileLocalVariable()` to always apply array desugaring mappings:

```haxe
// AFTER: Always apply array desugaring mappings
if (originalName.charAt(0) == '_' && ~/^_g\d*$/.match(originalName)) {
    var mapped = compiler.currentFunctionParameterMap.get(originalName);
    if (mapped != null) {
        #if debug_variable_compiler
        trace('[VariableCompiler] ✓ Applied array desugaring mapping: ${originalName} → ${mapped}');
        #end
        return mapped;  // Always return mapped name
    }
}
```

**Key Change**: Removed the `compiler.isInEnumExtraction` condition that was blocking necessary mappings.

## 🧪 Verification Results

### Before Fix
```elixir
# ERROR: Undefined variable "_g" 
case value do
  {:some, value} ->
    g_array = elem(_g, 1)  # ❌ _g is undefined
    # ... rest of case
end
```

### After Fix  
```elixir
# SUCCESS: Properly mapped variables
case value do
  {:some, value} ->
    g_array = elem(g_array, 1)  # ✅ g_array is defined and mapped
    # ... rest of case  
end
```

### Compilation Results
- **Before**: `error: undefined variable "_g"` (5 locations in todo_live.ex)
- **After**: Clean compilation with no undefined variable errors
- **Side Effect**: Warnings about unused `temp_string` variables (lower priority)

## 🔧 Technical Details

### Variable Mapping Architecture

The VariableMappingManager establishes mappings during array desugaring:

```haxe
// In VariableMappingManager.hx line 106
compiler.currentFunctionParameterMap.set('_${baseVarName}', '${baseVarName}_array');

// This creates mappings like:
// "_g" → "g_array"
// "_g_counter" → "g_counter_array"
```

### Context Integration

The fix ensures that enum parameter extraction respects these established mappings:

1. **VariableMappingManager** sets up `_g` → `g_array` mapping
2. **EnumIntrospectionCompiler** applies the mapping when compiling TLocal expressions
3. **VariableCompiler** no longer blocks the mapping in enum contexts
4. **Result**: Consistent variable names throughout generated Elixir code

## 🔮 Future Considerations

### Pattern Generalization

This fix establishes the pattern that **all specialized compilers must respect variable mappings**:

- EnumIntrospectionCompiler ✅ (Fixed)
- FieldAccessCompiler (Should be checked)
- MethodCallCompiler (Should be checked)
- Other expression compilers (Should be verified)

### Debug Infrastructure

Enhanced XRay debug traces provide visibility into variable mapping decisions:

```haxe
#if debug_enum_introspection_compiler
trace('[EnumIntrospectionCompiler] ✓ Applied variable mapping: ${original} → ${mapped}');
#end

#if debug_variable_compiler  
trace('[VariableCompiler] ✓ Applied array desugaring mapping: ${original} → ${mapped}');
#end
```

## 🚨 Troubleshooting Guide

### If You See `undefined variable "_g"` Errors

1. **Check Variable Mappings**: Verify VariableMappingManager is creating mappings
2. **Check Compiler Integration**: Ensure specialized compilers apply mappings for TLocal
3. **Check Blocking Logic**: Look for conditions preventing mapping application
4. **Enable Debug Traces**: Use `-D debug_variable_compiler -D debug_enum_introspection_compiler`

### Debug Commands
```bash
# Enable comprehensive variable mapping debug traces
npx haxe build-server.hxml -D debug_variable_compiler -D debug_enum_introspection_compiler -D debug_variable_mapping_manager

# Check generated variable names
grep -n "elem(" examples/todo-app/lib/todo_app_web/live/todo_live.ex

# Verify no undefined variables
mix compile --force 2>&1 | grep "undefined variable"
```

## 📋 Testing Checklist

When modifying variable mapping logic:

- [ ] Run `npm test` - All snapshot tests pass
- [ ] Compile todo-app: `cd examples/todo-app && npx haxe build-server.hxml`
- [ ] Elixir compilation: `mix compile --force` (no undefined variable errors)
- [ ] Phoenix server: `mix phx.server` (starts without crashes)
- [ ] Check enum parameter usage in generated files
- [ ] Verify array operations generate proper variable names

## 🎯 Key Takeaways

1. **Variable Mappings Are Global**: All specialized compilers must respect established mappings
2. **Don't Block Necessary Mappings**: Avoid conditions that prevent required variable transformations
3. **TLocal Requires Special Handling**: Direct variable references need mapping application
4. **Debug Infrastructure Is Essential**: XRay traces provide critical visibility
5. **Root Cause Over Band-Aids**: Fix mapping application, don't post-process output

This fix establishes the architectural principle that variable mappings are a compiler-wide concern, not just for specific contexts.
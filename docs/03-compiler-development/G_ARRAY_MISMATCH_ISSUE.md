# The Persistent G vs G_ARRAY Variable Mismatch Issue

## Problem Summary
When compiling Haxe switch expressions with `Type.typeof()` to Elixir, the compiler generates:
```elixir
g_array = Type.typeof(value)
case g do  # WRONG: Should be 'case g_array do'
```

This creates an undefined variable error because `g` is never defined, only `g_array`.

## Root Cause Analysis

### The Two-System Disconnect
The compiler has two separate variable mapping systems that aren't properly synchronized:

1. **Name-based mapping** (`currentFunctionParameterMap`)
   - Maps variable names like 'g' -> 'g_array'
   - Set up in `VariableMappingManager.setupArrayDesugatingMappings()`

2. **ID-based mapping** (`variableIdMap` in `VariableCompiler`)
   - Maps TVar.id to transformed names
   - Has higher priority in `compileVariableReference()`
   - Requires explicit registration via `registerVariableMapping()`

### Why The Issue Persists

When Haxe desugars `switch(Type.typeof(value))`:
1. It creates a TVar with name 'g' (or '_g')
2. The VariableMappingManager sets name mapping: 'g' -> 'g_array'
3. BUT this mapping is ONLY in `currentFunctionParameterMap`
4. The TVar.id is NOT registered in `variableIdMap`
5. When TLocal(v) is compiled, `compileVariableReference()` checks `variableIdMap` first
6. No ID mapping exists, so it falls back to the original name 'g'
7. Result: Assignment uses mapping ('g_array') but reference doesn't ('g')

## Architectural Insights

### Why This is Unique to Elixir

Other Reflaxe compilers (Go, C++, C#) don't have this issue because:
- They target **mutable** languages where variable shadowing is simpler
- They don't need complex renaming to avoid collisions in pattern matching
- Elixir's **immutability** forces us to use different variable names to avoid rebinding

### The Compilation Flow Problem

```
TSwitch(TCall(Type.typeof), cases)
  ↓
Desugared by Haxe to:
  ↓
TBlock([
  TVar(g, TCall(Type.typeof)),  // Creates TVar but doesn't register ID mapping
  TSwitch(TLocal(g), cases)      // References TVar by ID
])
  ↓
Compiled to:
  g_array = Type.typeof(value)   // Name mapping applied
  case g do                       // ID mapping missing, falls back to 'g'
```

## Previous Fix Attempts (That Failed)

1. **Removing 'g' mapping before compilation** - Made it worse, both used 'g'
2. **Extracting variable from assignment pattern** - Band-aid that didn't address root cause
3. **Manipulating currentFunctionParameterMap** - Only affected name-based lookups
4. **Pattern matching fixes in PatternMatchingCompiler** - Didn't fix TLocal compilation

## The Correct Solution

### Option 1: Register TVar.id Mapping When Created
When the compiler creates or encounters a TVar that needs mapping:
```haxe
// In the code that handles TVar creation for switch desugaring
var tvar = /* the TVar being created */;
if (needsArrayMapping(tvar.name)) {
    var mappedName = tvar.name + "_array";
    compiler.variableCompiler.registerVariableMapping(tvar, mappedName);
}
```

### Option 2: Synchronize Both Mapping Systems
When setting up array desugaring mappings:
```haxe
public function setupArrayDesugatingMappings(baseVarName: String, tvar: TVar): Void {
    var mappedName = baseVarName + "_array";
    // Name-based mapping (existing)
    compiler.currentFunctionParameterMap.set(baseVarName, mappedName);
    // ID-based mapping (NEW - fixes the issue)
    compiler.variableCompiler.registerVariableMapping(tvar, mappedName);
}
```

### Option 3: Fix at TLocal Compilation
Make `compileVariableReference` check name-based mappings when no ID mapping exists:
```haxe
public function compileVariableReference(tvar: TVar): String {
    // Check ID mapping first (existing)
    if (variableIdMap.exists(tvar.id)) {
        return variableIdMap.get(tvar.id);
    }
    
    // NEW: Check name-based mapping as fallback
    var originalName = getOriginalVarName(tvar);
    if (compiler.currentFunctionParameterMap.exists(originalName)) {
        return compiler.currentFunctionParameterMap.get(originalName);
    }
    
    // Default conversion (existing)
    return NamingHelper.toSnakeCase(originalName);
}
```

## Lessons Learned

1. **Always synchronize mapping systems** - When you have multiple ways to track the same information, they must be kept in sync
2. **ID-based mapping has priority** - The compiler prefers TVar.id mappings over name-based ones
3. **Understand the full compilation flow** - The issue wasn't in pattern matching but in how TLocal variables are resolved
4. **Architectural differences matter** - Solutions that work for mutable target languages may not work for immutable ones
5. **Root cause over band-aids** - String manipulation and pattern extraction are symptoms fixes, not solutions

## Testing the Fix

After implementing the correct solution, verify with:
```bash
# Test the specific case
haxe test/Test.hxml test=struct_field_assignment

# Check the generated code
cat test/tests/struct_field_assignment/out/test_struct.ex | grep -A2 "Type.typeof"
# Should show: g_array = Type.typeof(value)
#              case g_array do  # CORRECT!

# Full test suite
npm test
```

## Prevention for Future

1. When creating variable mappings, ALWAYS update both systems
2. Add debug traces in both mapping registration and lookup
3. Test switch expressions with function calls specifically
4. Document the dual mapping system clearly in the code
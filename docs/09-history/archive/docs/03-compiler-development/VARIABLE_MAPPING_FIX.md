# Variable Mapping Fix: From Heuristics to TVar.id

**Date**: 2025-01-25  
**Context**: Fixing Y-combinator compilation errors revealed fundamental variable mapping issues  
**Solution**: Replace heuristic string-based mapping with proper TVar.id tracking  

## 📋 The Problem: Variable Name Collisions

### Symptom
JsonPrinter.ex generated invalid Elixir code with duplicate variable references:
```elixir
fn -> ((g_array < g_array)) end,  # Same variable for both counter and limit!
```

### Root Cause Analysis

**Haxe Array Desugaring**: When Haxe processes array operations like filtering, it desugars them into while loops with generated variables:
```haxe
// Original: array.filter(predicate)
// Becomes internally: 
var g_counter = 0;
var g_array = array.length;  // limit variable
while (g_counter < g_array) {
    // loop body with different 'g' for switch expressions
}
```

**The Issue**: Multiple `g` variables are created with different purposes:
1. `g_counter` - loop counter variable (TVar with id=123)
2. `g_array` - loop limit variable (TVar with id=456)  
3. `g` - switch expression temporary (TVar with id=789)

**String-Based Mapping Failure**: Our compiler used variable names as Map keys:
```haxe
// All 'g' variables collide on the same string key!
compiler.variableMap.set("g", "g_array");  // First mapping
compiler.variableMap.set("g", "g_array");  // Overwrites previous!
```

## 🔄 The Journey: Learning from Failed Attempts

### Attempt 1: Heuristic String Checking ❌
```haxe
// Brittle heuristic approach
if (originalName == "g" && isCounterReference(tvar)) {
    return "g_counter";
} else if (originalName == "g" && isArrayReference(tvar)) {
    return "g_array";
}
```

**Problems:**
- Timing-dependent (relies on compilation order)
- Fragile detection logic
- Doesn't scale to new variable patterns
- Hard to debug and maintain

### Attempt 2: TVar Object Reference ❌
```haxe
// Using object reference as unique ID
var uniqueId = Std.string(tvar);  // Object memory reference
variableMap.set(uniqueId, mappedName);
```

**Problems:**
- Non-deterministic (memory addresses change between runs)
- Still a workaround, not addressing root cause
- Doesn't follow established patterns

### Attempt 3: Research Reflaxe Patterns ✅
**Discovery**: Found that Reflaxe's `MarkUnusedVariablesImpl` uses the proper pattern:
```haxe
// From MarkUnusedVariablesImpl.hx
var tvarMap: Map<Int, Null<TVar>> = [];
// ...
case TVar(tvar, maybeExpr): {
    tvarMap.set(tvar.id, tvar);  // Uses tvar.id as unique key!
}
case TLocal(tvar): {
    if(tvarMap.exists(tvar.id)) {
        tvarMap.set(tvar.id, null);
    }
}
```

## ✅ The Solution: TVar.id-Based Mapping

### Core Insight
**TVar.id is the unique identifier for variables in Haxe's AST.** Every TVar instance has a unique integer ID that persists throughout compilation.

### Implementation Pattern

**Before (Broken):**
```haxe
// String-based mapping causes collisions
class VariableCompiler {
    var variableMap: Map<String, String> = new Map();
    
    function mapVariable(name: String, mappedName: String) {
        variableMap.set(name, mappedName);  // Collision risk!
    }
}
```

**After (Fixed):**
```haxe
// TVar.id-based mapping prevents collisions
class VariableCompiler {
    var variableIdMap: Map<Int, String> = new Map();
    
    function mapVariable(tvar: TVar, mappedName: String) {
        variableIdMap.set(tvar.id, mappedName);  // Unique mapping!
    }
    
    function resolveVariable(tvar: TVar): String {
        var mapped = variableIdMap.get(tvar.id);
        return mapped != null ? mapped : NamingHelper.toSnakeCase(tvar.name);
    }
}
```

### Key Changes Required

1. **Map Key Type Change**: `Map<String, String>` → `Map<Int, String>`
2. **Function Signatures**: Accept `TVar` instead of just `String` 
3. **Lookup Logic**: Use `tvar.id` instead of variable name
4. **Metadata Integration**: Check for `-reflaxe.unused` metadata

## 🏗️ Architecture Benefits

### Single Responsibility Principle
- **Variable Identity**: TVar.id handles unique identification
- **Variable Naming**: NamingHelper handles string transformations  
- **Variable Mapping**: Compiler maps between identities and names

### Open/Closed Principle
- **Extension**: New variable patterns work automatically
- **Modification**: No need to change core mapping logic

### Testability
- **Deterministic**: Same TVar.id always maps to same name
- **Isolated**: Variable mapping independent of compilation order

### Performance
- **Integer Keys**: Faster Map operations than string keys
- **No String Parsing**: No heuristic pattern matching needed

## 🧪 Testing Strategy

### Regression Tests
Ensure existing functionality still works:
```bash
npm test  # All snapshot tests must pass
cd examples/todo-app && npx haxe build-server.hxml && mix compile
```

### Specific Variable Mapping Tests
Create tests for different variable collision scenarios:
- Multiple 'g' variables in same scope
- Nested loop variable conflicts  
- Enum parameter variable overlaps
- CamelCase to snake_case transformations

### JsonPrinter Validation
The specific case that revealed this issue:
```elixir
# Should generate unique variables:
fn -> ((g_counter < g_array)) end,  # Different variables now!
```

## 📚 Lessons Learned

### ⚠️ Never Use Heuristics When Framework Provides Proper APIs
**Wrong Approach**: Inventing custom detection systems based on string patterns  
**Right Approach**: Using Reflaxe's established metadata and ID systems

### ⚠️ Fix Root Causes, Not Symptoms
**Wrong Approach**: Post-processing to clean up bad mappings  
**Right Approach**: Fix the mapping system itself at the AST level

### ⚠️ Study Reference Implementations First
**Wrong Approach**: Assuming we need to invent new patterns  
**Right Approach**: Checking how Reflaxe preprocessors handle similar issues

### ⚠️ Architectural Alignment is Critical
**Wrong Approach**: Ad-hoc solutions that don't fit the framework  
**Right Approach**: Following established Reflaxe patterns and conventions

## 🔄 Implementation Checklist

- [ ] Update VariableCompiler to use `Map<Int, String>`
- [ ] Change function signatures to accept TVar parameters
- [ ] Update all variable resolution to use tvar.id
- [ ] Remove heuristic string checking logic
- [ ] Add metadata support for `-reflaxe.unused`
- [ ] Update VariableMappingManager if it exists
- [ ] Run complete test suite validation
- [ ] Test JsonPrinter variable generation
- [ ] Validate todo-app compilation and runtime

## 🎯 Expected Outcomes

### Immediate Benefits
1. **JsonPrinter compiles correctly** with unique variable names
2. **No more variable collision errors** in generated Elixir
3. **Cleaner, more maintainable code** without heuristics

### Long-term Benefits
1. **Scalable variable mapping** for any future patterns
2. **Framework-aligned architecture** following Reflaxe principles
3. **Robust foundation** for complex variable transformations

---

**Remember**: This fix represents a fundamental shift from ad-hoc problem solving to proper framework integration. TVar.id is the key to robust variable identity tracking in Haxe AST processing.
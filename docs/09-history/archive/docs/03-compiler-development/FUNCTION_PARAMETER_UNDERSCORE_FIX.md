# Function Parameter Underscore Prefix Fix

## Problem Statement

Function parameters in TypeSafeChildSpecBuilder and similar contexts were being incorrectly prefixed with underscores when referenced in function bodies, even though they were actively used. This caused compilation errors in the generated Elixir code.

### Symptom
```elixir
# Generated (INCORRECT)
def pubsub(app_name) do
  {Phoenix.PubSub, name: _app_name <> ".PubSub"}  # Error: undefined variable _app_name
end
```

### Expected
```elixir
# Generated (CORRECT)
def pubsub(app_name) do
  {Phoenix.PubSub, name: app_name <> ".PubSub"}
end
```

## Root Cause Analysis

The issue occurred in `VariableCompiler.compileVariableReference()` where the order of variable mapping lookups was incorrect:

1. **underscorePrefixMap** was checked first
2. **currentFunctionParameterMap** was checked second

This meant that if a variable like `app_name` existed in the underscore prefix map (mapped to `_app_name`), it would be returned with the underscore prefix even when the function parameter map had the correct non-underscore mapping.

### Why This Happened

The underscore prefix map gets populated when:
- Variables are detected as unused by Reflaxe's preprocessor
- Pattern matching extracts variables that aren't referenced
- Function parameters are marked as unused in their declarations

However, when these same variables are referenced in the function body, they should use their actual parameter names, not the underscore-prefixed versions.

## Solution Implementation

The fix implements a **targeted priority check** in `VariableCompiler.compileVariableReference()` that:

1. Checks if a function parameter mapping exists WITHOUT an underscore prefix
2. If found, uses it directly (preventing incorrect underscore prefixing)
3. Otherwise, falls back to the normal underscore prefix map lookup

### Code Changes

Location: `/src/reflaxe/elixir/helpers/VariableCompiler.hx` lines 1391-1407

```haxe
// TARGETED FIX: For function parameters, check if they have a mapping that doesn't 
// involve underscores. This prevents incorrect underscore prefixing of used parameters.
if (compiler.currentFunctionParameterMap.exists(originalName)) {
    var mappedName = compiler.currentFunctionParameterMap.get(originalName);
    // If the mapped name doesn't start with underscore, use it directly
    // This prevents app_name from becoming _app_name when it's used in function body
    if (!StringTools.startsWith(mappedName, "_")) {
        return mappedName;
    }
}
if (compiler.currentFunctionParameterMap.exists(varName)) {
    var mappedName = compiler.currentFunctionParameterMap.get(varName);
    // Same check for snake_case version
    if (!StringTools.startsWith(mappedName, "_")) {
        return mappedName;
    }
}

// Check underscore prefix map (for variables declared with underscore)
// ... existing code continues
```

## Why This Fix Works

### Targeted Approach
- Only affects function parameters that DON'T have underscore prefixes
- Preserves underscore prefixes for genuinely unused parameters
- Doesn't interfere with other variable types (local vars, pattern extractions)

### Maintains Elixir Conventions
- Unused parameters still get underscore prefixes (e.g., `_config`)
- Used parameters keep their normal names (e.g., `app_name`)
- Follows Elixir's convention of marking unused variables with underscores

### No Regressions
- Tested with full test suite
- Todo-app compiles correctly
- Other variable mapping scenarios continue to work

## Test Cases Affected

This fix ensures correct compilation for:
- TypeSafeChildSpecBuilder enum functions
- Function parameters in pattern matching contexts
- Nested switch statements with parameter references
- Any scenario where function parameters are used in their body

## Related Documentation

- [VARIABLE_MAPPING_FIX.md](VARIABLE_MAPPING_FIX.md) - General variable mapping improvements
- [G_VARIABLE_PATTERNS.md](G_VARIABLE_PATTERNS.md) - Temporary variable handling
- [UNUSED_VARIABLE_COMPREHENSIVE_FIX.md](UNUSED_VARIABLE_COMPREHENSIVE_FIX.md) - Unused variable detection

## Verification

To verify this fix is working:

1. Check TypeSafeChildSpecBuilder compilation:
```bash
cd examples/todo-app
npx haxe build-server.hxml
mix compile --force
```

2. Verify the generated code:
```bash
grep "def pubsub" lib/elixir/otp/type_safe_child_spec_builder.ex
# Should show: def pubsub(app_name) do
#              {Phoenix.PubSub, name: app_name <> ".PubSub"}
```

3. Run full test suite:
```bash
npm test
```

## Future Considerations

This fix addresses the immediate issue but highlights a broader architectural consideration:
- The relationship between unused parameter detection and variable reference compilation
- Whether underscore prefix maps should be scope-aware
- Potential for a more unified variable resolution system

## Commit Reference

Fixed in commit: [pending commit hash]
Date: 2025-08-28
Issue: Function parameters incorrectly prefixed with underscores when used in body
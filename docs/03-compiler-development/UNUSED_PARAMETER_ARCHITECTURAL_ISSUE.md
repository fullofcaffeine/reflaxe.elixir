# Unused Parameter Prefixing Architectural Issue

## Problem Summary

Function parameters marked as unused by Reflaxe's `-reflaxe.unused` metadata are being prefixed with underscore in the function signature, but the function body still references the unprefixed variable name, causing "undefined variable" compilation errors.

### Example of the Issue
```elixir
# Generated function signature with prefixed parameter
def to_legacy(_spec, app_name) do
  # Body still uses unprefixed name, causing error
  case elem(spec, 0) do  # ERROR: undefined variable "spec"
    # ...
  end
end
```

## Root Causes

### 1. Reflaxe Preprocessor Limitations
The Reflaxe `MarkUnusedVariablesImpl` preprocessor doesn't recognize certain parameter usage patterns:
- `elem(spec, 0)` - tuple element extraction
- Parameters used in switch/case expressions
- Parameters passed to certain Elixir-specific functions

### 2. Compilation Path Inconsistency
Not all functions go through our `FunctionCompiler`:
- Standard library functions may use different compilation paths
- Static functions in certain classes bypass our parameter detection
- Our `detectUsedParameters` function isn't called for all function types

### 3. Metadata vs Detection Mismatch
- Reflaxe applies `-reflaxe.unused` metadata during preprocessing
- Our compiler tries to detect usage during compilation
- The two systems disagree on what constitutes "usage"

## Attempted Solutions

### 1. ✅ Pattern Detection Enhancement (Partial Success)
We enhanced `detectUsedParameters` to properly detect:
- Parameters in TCall arguments (like `elem(spec, 0)`)
- Parameters in switch expressions
- Parameters in all expression types

**Result**: Works for functions that go through FunctionCompiler, but not all functions do.

### 2. ❌ Parameter Mapping (Failed)
We tried mapping original parameter names to prefixed names:
- Map `spec` -> `_spec` in function body references
- Update `currentFunctionParameterMap` for TLocal lookups

**Issue**: The mapping isn't applied consistently across all compilation paths.

### 3. ❌ Metadata-Based Detection (Failed)
We tried using Reflaxe's `-reflaxe.unused` metadata directly:
- Check `arg.tvar.meta.has("-reflaxe.unused")`
- Prefix based on metadata

**Issue**: Reflaxe incorrectly marks parameters as unused when they're actually used.

## Architectural Challenges

### 1. Multiple Compilation Paths
The compiler has different paths for:
- Instance methods vs static methods
- Standard library vs user code
- Special annotations (@:liveview, @:genserver, etc.)

Not all paths use FunctionCompiler, leading to inconsistent parameter handling.

### 2. AST Processing Order
- Reflaxe preprocessor runs BEFORE our compiler
- Metadata is already applied when we receive the AST
- We can't modify Reflaxe's detection logic

### 3. Enum Destructuring Complexity
Switch expressions on enums generate complex Elixir code:
- `switch(spec)` becomes `case elem(spec, 0) do`
- Pattern extraction uses `elem(spec, N)` for each field
- These patterns aren't recognized as parameter usage

## Proper Architectural Fix

### Option 1: Unified Function Compilation
Ensure ALL functions go through FunctionCompiler:
1. Identify all compilation paths
2. Route them through FunctionCompiler
3. Apply consistent parameter detection

### Option 2: Enhanced Reflaxe Integration
Work with Reflaxe to improve unused detection:
1. Submit PR to MarkUnusedVariablesImpl
2. Add recognition for `elem()` patterns
3. Improve switch expression analysis

### Option 3: Post-Processing Fix
Add a post-processing phase:
1. After compilation, scan for undefined variable errors
2. Map them back to prefixed parameters
3. Update references to use prefixed names

### Option 4: Disable Underscore Prefixing (Current Workaround)
Simply don't prefix "unused" parameters:
- Generates warnings but no errors
- Code compiles and runs correctly
- Not ideal but functional

## Current Status

The issue remains unresolved at the architectural level. Functions that don't go through FunctionCompiler (like TypeSafeChildSpecTools.toLegacy) still generate incorrect code with mismatched parameter names.

## Next Steps

1. **Investigate Compilation Paths**: Map out exactly which functions bypass FunctionCompiler
2. **Unify Compilation**: Ensure all functions use the same parameter handling logic
3. **Improve Detection**: Enhance parameter usage detection for all AST patterns
4. **Consider Reflaxe PR**: Submit improvements to Reflaxe's unused detection

## Related Files

- `src/reflaxe/elixir/helpers/FunctionCompiler.hx` - Parameter detection logic
- `src/reflaxe/elixir/helpers/VariableCompiler.hx` - Variable reference compilation
- `std/elixir/otp/TypeSafeChildSpec.hx` - Example of affected code
- `docs/03-compiler-development/UNUSED_VARIABLE_COMPREHENSIVE_FIX.md` - Earlier investigation
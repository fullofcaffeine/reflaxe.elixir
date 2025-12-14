# CRITICAL BUG: Guard Condition Flattening Breaks Inline Function Expansion

## Issue Summary
The guard condition flattening implementation introduced a critical bug where inline functions with optional parameters (like `String.substr`) generate syntactically invalid Elixir code when used in switch case bodies with guard conditions.

## Symptoms
- Invalid Elixir syntax errors in 4 tests
- Malformed code generation: `len = nil` followed by orphaned if statements
- Affects: idiomatic_enum_patterns, ExunitComprehensive, and others

## Root Cause
The interaction between:
1. **Inline function expansion**: `substr(pos, ?len)` expands to conditional String.slice
2. **Guard condition flattening**: Transforms nested if-else to cond expressions  
3. **Switch case body handling**: Incorrectly splits the inline expansion

## Example of Bug

### Haxe Source
```haxe
case str if (str.indexOf("set_priority:") == 0):
    SetPriority(str.substr(13));
```

### Expected Elixir Output
```elixir
str if (case :binary.match(str, "set_priority:") do
    {pos, _} -> pos
    nil -> -1
end == 0) ->
    {:set_priority, String.slice(str, 13..-1)}
```

### Actual Broken Output
```elixir
str if (case :binary.match(str, "set_priority:") do
    {pos, _} -> pos
    nil -> -1
end == 0) ->
    {:set_priority, len = nil
if (len == nil) do
  String.slice(str, 13..-1)
else
  String.slice(str, 13, len)
end}
```

## Technical Details

The `substr` function in `std/String.cross.hx`:
```haxe
extern inline public function substr(pos: Int, ?len: Int): String {
    if (len == null) {
        return untyped __elixir__('String.slice({0}, {1}..-1)', this, pos);
    } else {
        return untyped __elixir__('String.slice({0}, {1}, {2})', this, pos, len);
    }
}
```

When this inline function is expanded in a switch case body with a guard condition, the expansion is incorrectly handled, leading to:
1. Partial assignment: `len = nil` (incomplete)
2. Orphaned conditional: The if statement that should use `len`
3. Missing variable assignment for the result

## Impact
- 4 tests generate invalid syntax
- Potentially affects any code using inline functions with optional parameters in guarded switch cases
- Blocks test suite progress

## Proposed Solutions

### Option 1: Fix GuardConditionFlattener
- Detect inline function expansions
- Ensure complete expressions are preserved
- Handle optional parameter defaults correctly

### Option 2: Disable Flattening for Complex Cases
- Skip flattening when case bodies contain inline function calls
- Preserve original nested structure for safety

### Option 3: Fix Inline Expansion Timing
- Ensure inline expansion happens after guard flattening
- Or ensure guard flattening handles expanded code correctly

## Affected Files
- `src/reflaxe/elixir/ast/transformers/GuardConditionFlattener.hx`
- `src/reflaxe/elixir/ast/ElixirASTTransformer.hx`
- `std/String.cross.hx` (contains the problematic inline functions)

## Test Cases to Verify Fix
- `test/snapshot/core/idiomatic_enum_patterns`
- `test/snapshot/exunit/ExunitComprehensive`
- Any test using `substr`, `substring` with optional parameters in guarded cases

## Priority
**CRITICAL** - Generates syntactically invalid Elixir code that cannot compile

## Workaround
None currently. The guard flattening must be fixed or disabled for these cases.
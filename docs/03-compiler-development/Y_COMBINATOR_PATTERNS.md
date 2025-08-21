# Y Combinator Pattern Compilation and Fixes

## Overview
The Y combinator pattern is used in Reflaxe.Elixir to compile imperative while loops into functional Elixir recursive functions. This document describes critical patterns and fixes for proper Y combinator compilation.

## Critical Fix: Struct Update Pattern Detection

### Problem
Struct updates like `struct = %{struct | field: value}` were being compiled into inline if-else expressions, creating malformed syntax:
```elixir
# MALFORMED OUTPUT (before fix)
if (condition), do: struct = %{struct | b: struct.b <> "\n"}, else: nil
```

This causes Elixir compilation errors because struct updates cannot be used as inline expressions.

### Root Cause
The compiler's TIf (if-else expression) compilation logic wasn't detecting struct update patterns as complex expressions requiring block syntax. This allowed struct updates to be placed in inline conditionals where they create invalid syntax.

### Solution
Enhanced pattern detection in `ElixirCompiler.hx` (lines 3020-3095) to specifically identify struct update patterns and force block syntax:

```haxe
/**
 * STRUCT UPDATE PATTERN DETECTION: Critical for Y combinator compilation
 * 
 * WHY: Struct updates like `struct = %{struct | field: value}` create malformed
 * syntax when used in inline if-else expressions, causing compilation errors
 * in generated code like JsonPrinter (lines 219, 222).
 * 
 * WHAT: Force block syntax whenever struct update patterns are detected.
 * The pattern `%{struct |` or `%{var |` indicates a struct update operation
 * that MUST use block syntax to avoid malformed conditionals.
 * 
 * HOW: Check both if and else branches for struct update patterns using
 * specific pattern matching that identifies the update syntax.
 */
var hasStructUpdatePattern = false;
if (ifExpr != null) {
    // Pattern: variable = %{variable | field: value}
    hasStructUpdatePattern = hasStructUpdatePattern || 
        (ifExpr.contains(" = %{") && ifExpr.contains(" | ") && ifExpr.contains("}"));
    // Also catch direct struct updates without assignment
    hasStructUpdatePattern = hasStructUpdatePattern || 
        (ifExpr.contains("%{struct |") || ifExpr.contains("%{_this |"));
}
```

### XRay Debug Traces
The fix includes comprehensive XRay debugging traces to visualize when struct update patterns are detected:

```haxe
#if debug_y_combinator
trace("[XRay Y-Combinator] STRUCT UPDATE DETECTION START");
trace("[XRay Y-Combinator] - Checking ifExpr for struct updates...");
if (hasAssignmentWithUpdate || hasDirectStructUpdate) {
    trace("[XRay Y-Combinator] ✓ STRUCT UPDATE FOUND IN IF BRANCH");
    trace('[XRay Y-Combinator]   - Pattern matched: ${ifExpr.substring(0, 150)}');
}
if (hasStructUpdatePattern) {
    trace("[XRay Y-Combinator] ⚠️ STRUCT UPDATE PATTERN DETECTED - FORCING BLOCK SYNTAX");
}
#end
```

### Result
After the fix, struct updates are properly compiled using block syntax:
```elixir
# CORRECT OUTPUT (after fix)
if condition do
  struct = %{struct | b: struct.b <> "\n"}
else
  nil
end
```

## Other Y Combinator Patterns

### Array Building Pattern
Detects and optimizes array-building loops to use Enum.reduce instead of Y combinator:
- Pattern: Loop that builds an array with `++` operator
- Optimization: Convert to `Enum.reduce` with accumulator

### Reflect.fields Pattern
Detects iteration over object fields and optimizes to Map.merge:
- Pattern: `for (f in Reflect.fields(obj))`
- Optimization: Convert to `Map.merge` operation

### Break/Continue Support
Y combinator patterns support break and continue using throw/catch:
```elixir
loop_helper = fn loop_fn, {state} ->
  try do
    # loop body
    loop_fn.(loop_fn, {state})
  catch
    :break -> {state}
    :continue -> loop_fn.(loop_fn, {state})
  end
end
```

## Debug Flags
Use these conditional compilation flags to debug Y combinator patterns:
- `debug_y_combinator` - General Y combinator debugging
- `debug_if_expressions` - If-else expression compilation
- `debug_inline_if` - Inline vs block syntax decisions

Example:
```bash
npx haxe build-server.hxml -D debug_y_combinator
```

## Testing
Key test cases for Y combinator patterns:
- `test/tests/Y_Combinator/` - Basic Y combinator tests
- `examples/todo-app/` - Real-world usage in JsonPrinter

## Related Documentation
- [`DEBUG_XRAY_SYSTEM.md`](DEBUG_XRAY_SYSTEM.md) - XRay debugging system
- [`COMPILER_BEST_PRACTICES.md`](COMPILER_BEST_PRACTICES.md) - General compiler patterns
- [`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md) - Testing Y combinator fixes
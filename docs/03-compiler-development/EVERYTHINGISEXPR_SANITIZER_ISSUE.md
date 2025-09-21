# EverythingIsExprSanitizer Switch Expression Issue

**Status**: Known Issue - Requires Reflaxe Fix
**Discovered**: January 2025
**Impact**: Static methods returning switch expressions generate incorrect code
**Latest Finding**: RemoveRedundantEnumExtraction transformer conflicts with the workaround

## The Problem

When a static method returns a switch expression directly, EverythingIsExprSanitizer (a Reflaxe preprocessor) incorrectly transforms the code, causing the switch body to be lost and replaced with just one of the case variables. Additionally, our RemoveRedundantEnumExtraction transformer removes critical assignments needed for the workaround.

### Example of the Issue

**Haxe Source** (Changeset.hx):
```haxe
public static function unwrapOr<T, P>(result: Result<T, Changeset<T, P>>, defaultValue: T): T {
    return switch(result) {
        case Ok(value): value;
        case Error(_): defaultValue;
    };
}
```

**Expected Elixir Output**:
```elixir
def unwrap_or(result, default_value) do
  case result do
    {:ok, value} -> value
    {:error, _} -> default_value
  end
end
```

**Actual (Incorrect) Output**:
```elixir
def unwrap_or(result, default_value) do
  temp_result = value  # ERROR: value is undefined!
  temp_result
end
```

## Root Cause

EverythingIsExprSanitizer is designed to transform expression-oriented code into imperative style for targets that don't support expressions everywhere. When it encounters:

```haxe
return switch(result) { ... }
```

It transforms it to:
```haxe
var temp_result = /* switch expression */;
return temp_result;
```

However, there's a bug in how it handles the switch expression, particularly in static methods. Instead of preserving the full switch expression, it incorrectly evaluates to just "value" (one of the case variables).

## Investigation Details

1. **Location in Pipeline**: This happens in the Reflaxe preprocessor phase, BEFORE our Elixir compiler sees the code
2. **File**: `vendor/reflaxe/src/reflaxe/preprocessors/implementations/everything_is_expr/EverythingIsExprSanitizer.hx`
3. **Method**: `standardizeSubscopeValue` (lines 719-762)
4. **Configuration**: Enabled in `src/reflaxe/elixir/CompilerInit.hx` line 46

## Attempted Workarounds

### 1. Detection in AST Builder (Partial)
We added detection in ElixirASTBuilder.hx to identify when a TVar has a TSwitch initialization:

```haxe
case TSwitch(switchExpr, cases, edef):
    // Special handling for lifted switches
    trace('[TVar] Switch expression lifted by EverythingIsExprSanitizer detected');
    // Build the switch expression properly
```

However, by the time our code runs, the switch has already been transformed to just "value".

### 2. Disable EverythingIsExprSanitizer (Not Viable)
Disabling the preprocessor breaks other patterns that rely on it.

## Temporary Workaround for Users

Until this is fixed in Reflaxe, users can work around the issue by:

1. **Avoid direct switch returns in static methods**:
```haxe
// Instead of:
public static function unwrapOr<T, P>(result: Result<T, Changeset<T, P>>, defaultValue: T): T {
    return switch(result) { ... };
}

// Use:
public static function unwrapOr<T, P>(result: Result<T, Changeset<T, P>>, defaultValue: T): T {
    var output = switch(result) {
        case Ok(value): value;
        case Error(_): defaultValue;
    };
    return output;
}
```

2. **Use if-else for simple cases**:
```haxe
public static function unwrapOr<T, P>(result: Result<T, Changeset<T, P>>, defaultValue: T): T {
    if (result.match(Ok(_))) {
        return result.extract(Ok(value));
    } else {
        return defaultValue;
    }
}
```

## Long-term Solution

This requires a fix in the Reflaxe framework itself:

1. **Report issue to Reflaxe**: The EverythingIsExprSanitizer preprocessor needs to correctly handle switch expressions in return statements
2. **Fix location**: `vendor/reflaxe/src/reflaxe/preprocessors/implementations/everything_is_expr/EverythingIsExprSanitizer.hx`
3. **Specific issue**: The `standardizeSubscopeValue` method loses the switch structure when lifting it to a temporary variable

## Affected Code Patterns

- Static methods returning switch expressions directly
- Utility functions with pattern matching returns
- Result/Option unwrapping utilities
- Any `return switch(...)` pattern in static context

## Testing

To verify if this issue affects your code:

1. Look for static methods with `return switch(...)`
2. Check the generated .ex files for undefined variables
3. Look for patterns like `temp_result = value` where `value` is not defined

## References

- Reflaxe GitHub: https://github.com/SomeRanDev/reflaxe
- EverythingIsExprSanitizer: `vendor/reflaxe/src/reflaxe/preprocessors/`
- Related Haxe issue: (to be filed)
# Array.cross.hx Optional Parameter Fix

## Issue Summary
When using `inline` functions with optional parameters in Array.cross.hx, the compiler was generating runtime code that referenced undefined variables like `from_index`, causing compilation errors.

## Root Cause
The issue occurred because:
1. `inline` functions with optional parameters generate runtime initialization code
2. This code referenced variables that didn't exist in the generated Elixir
3. The optional parameter checks were being compiled as runtime code instead of being resolved at compile-time

## The Solution: `extern inline`
Using `extern inline` instead of just `inline` fundamentally changes the compilation behavior:

### How `extern inline` Works
1. **Compile-Time Resolution**: The optional parameter logic is evaluated during Haxe's typing phase
2. **No Runtime Variables**: Only the relevant branch is compiled based on actual usage
3. **Clean Output**: No references to undefined variables in generated code

### Example Implementation
```haxe
/**
 * Using extern inline to ensure optional parameters are resolved at compile-time
 */
extern inline public function indexOf(x: T, ?fromIndex: Int = 0): Int {
    // This if statement is evaluated at compile-time
    if (fromIndex != 0) {
        // This branch compiles only when fromIndex is provided
        return untyped __elixir__("
            {0}
            |> Enum.drop({2})
            |> Enum.find_index(fn item -> item == {1} end)
            |> case do
                nil -> -1
                idx -> idx + {2}
            end
        ", this, x, fromIndex);
    } else {
        // This branch compiles when fromIndex is not provided
        return untyped __elixir__("
            case Enum.find_index({0}, fn item -> item == {1} end) do
                nil -> -1
                idx -> idx
            end
        ", this, x);
    }
}
```

### Compilation Examples
- `array.indexOf(5)` → Compiles only the else branch (fromIndex = 0)
- `array.indexOf(5, 2)` → Compiles only the if branch with fromIndex = 2

## Other Fixed Issues

### Modulo Operator
Fixed the modulo operator compilation to generate valid Elixir syntax:
- **Before**: `x rem 2` (invalid Elixir syntax)
- **After**: `rem(x, 2)` (correct function call)

The fix was implemented in ElixirASTTransformer by converting the binary Remainder operation to a function call.

## Testing
All fixes have been validated with:
1. The `array_cross_operations` snapshot test
2. Updated intended output to match the corrected generation

## Related Documentation
- [Haxe Manual: extern inline](https://haxe.org/manual/class-field-inline.html#extern-inline)
- [STDLIB_IMPLEMENTATION_GUIDE.md](./STDLIB_IMPLEMENTATION_GUIDE.md)
# Switch Return Optimization Limitation

**STATUS**: Known Limitation (January 2025)
**WORKAROUND**: Available

## The Problem

When using a switch expression directly in a return statement with enum pattern matching, Haxe's optimizer removes the switch structure before it reaches the Reflaxe.Elixir compiler.

### Example of the Issue

**Haxe Source:**
```haxe
public static function unwrapOr<T>(result: Result<T>, defaultValue: T): T {
    return switch(result) {
        case Ok(value): value;
        case Error(_): defaultValue;
    };
}
```

**Expected Elixir Output:**
```elixir
def unwrap_or(result, default_value) do
  case result do
    {:ok, value} -> value
    {:error, _} -> default_value
  end
end
```

**Actual Elixir Output:**
```elixir
def unwrap_or(result, default_value) do
  value  # Just the variable, causing undefined variable error!
end
```

## Root Cause

Haxe's optimizer performs aggressive optimizations on switch expressions in return position:

1. **Pattern Extraction**: Haxe extracts enum parameters to temporary variables
2. **Direct Return Optimization**: When the switch result is immediately returned, Haxe simplifies the entire expression
3. **Lost Context**: The switch structure is removed, leaving only the final variable reference
4. **TypedExpr Limitation**: By the time our compiler receives the TypedExpr, it only contains `TReturn(TLocal(value))`

## The Workaround

Use a temporary variable to prevent Haxe's optimization:

```haxe
public static function unwrapOr<T>(result: Result<T>, defaultValue: T): T {
    var output = switch(result) {
        case Ok(value): value;
        case Error(_): defaultValue;
    };
    return output;
}
```

This generates the correct Elixir output:
```elixir
def unwrap_or(result, default_value) do
  output = case result do
    {:ok, value} -> value
    {:error, _} -> default_value
  end
  output
end
```

## Why This Happens

Haxe's TypedExpr is designed for imperative targets where switch expressions compile to if-else chains or jump tables. The optimization makes sense for those targets but loses important structural information needed for pattern-matching targets like Elixir.

## Attempted Solutions

1. **AST Reconstruction**: Tried to detect and rebuild switch structure - not feasible without original AST
2. **TReturn Special Handling**: Added detection for TSwitch in TReturn - but the switch is already gone
3. **Metadata Preservation**: Investigated using metadata to preserve structure - metadata is also lost

## Impact

- Functions returning switch expressions directly may generate invalid Elixir
- The generated code references undefined variables
- Runtime errors occur when the code executes

## Recommendations

1. **Use the Workaround**: Always use a temporary variable for switch expressions that are returned
2. **Code Style Guide**: Document this pattern in project guidelines
3. **Linting**: Consider a Haxe macro to detect and warn about this pattern
4. **Future Investigation**: Work with Haxe team to preserve AST information for pattern-matching targets

## Related Issues

- Similar optimization affects while loops with breaks
- Array comprehensions also lose structure when optimized
- General issue: Haxe optimizations designed for imperative targets

## Example Test Case

See: `test/snapshot/regression/switch_return_sanitizer/` for a comprehensive test case demonstrating the issue and workaround.
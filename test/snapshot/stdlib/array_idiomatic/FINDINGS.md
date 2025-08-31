# Array.hx Testing Findings

## Current Status

The Array.hx implementation using `__elixir__()` injection is not working as expected with the AST pipeline.

### The Problem

1. **Array.hx uses runtime injection**: The `untyped __elixir__()` pattern is meant for runtime code injection
2. **AST compilation doesn't expand methods**: When compiling `numbers.map(x -> x * 2)`, the compiler generates `numbers.map(fn x -> x * 2 end)` directly
3. **Elixir lists don't have these methods**: The generated code will fail at runtime because Elixir lists don't have `map`, `filter`, etc. methods

### Generated Code Issues

```elixir
# Current (BROKEN) - will fail at runtime
doubled = numbers.map(fn x -> x * 2 end)

# Expected (using Array.hx __elixir__ pattern)
doubled = Enum.map(numbers, fn x -> x * 2 end)
```

### Root Cause

The `__elixir__()` injection mechanism only works when:
1. The injection is directly in the compiled expression
2. The compiler sees the `__elixir__()` call itself

But when calling array methods:
1. The method body (containing `__elixir__()`) is not expanded during compilation
2. The compiler just generates a method call assuming the method exists on the target

### Solutions

#### Option 1: AST Transformer Pattern Detection (Recommended)
Add transformation passes in ElixirASTTransformer to detect array method calls and transform them to Enum functions:
- Detect `ECall` on array types with methods like `map`, `filter`, `concat`
- Transform to appropriate `Enum.map`, `Enum.filter`, `++` operators

#### Option 2: Macro-based Array Implementation
Use Haxe macros to expand array methods at compile time instead of runtime injection

#### Option 3: Extern-based Implementation
Define Array as an extern class that maps directly to Elixir's list operations

## Current Workaround

Since the direct method calls are being generated, the code will fail at runtime. We need to implement array method transformation in the AST transformer to generate proper Enum function calls.

## Test Results

- ❌ `map` generates `list.map()` instead of `Enum.map(list, ...)`
- ❌ `filter` generates `list.filter()` instead of `Enum.filter(list, ...)`
- ✅ `concat` generates `++` operator correctly
- ❌ Other methods also generate invalid direct calls

## Next Steps

1. Implement array method transformation in ElixirASTTransformer
2. Detect array method call patterns
3. Transform to idiomatic Elixir Enum functions
4. Re-test to ensure proper code generation
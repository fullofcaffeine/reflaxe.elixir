# ExUnit Macro Expansion Architecture

## Overview

This document explains the architectural decision to use `extern inline` functions for ExUnit assertions, enabling proper macro expansion in the generated Elixir test code.

## The Problem: Macro Context Requirements

ExUnit's assertion system is built on Elixir macros that must be expanded at compile-time within the test module's context. This creates a fundamental challenge for a Haxe→Elixir transpiler.

### Why Regular Functions Don't Work

```haxe
// Attempt 1: Regular static function
class Assert {
    public static function assertEqual<T>(expected: T, actual: T): Void {
        untyped __elixir__('assert {0} == {1}', actual, expected);
    }
}
```

This generates:
```elixir
defmodule Assert do
    def assert_equal(expected, actual) do
        assert actual == expected  # ERROR: assert macro not available here!
    end
end

# In test:
Assert.assert_equal(5, result)  # Fails - assert isn't a function
```

The `assert` macro is only available in modules that `use ExUnit.Case`, not in arbitrary modules.

### Why Module Imports Don't Solve It

```elixir
defmodule Assert do
    import ExUnit.Assertions  # Even with this...
    
    def assert_equal(expected, actual) do
        assert actual == expected  # Still wrong - macro expansion at wrong time
    end
end
```

Macros expand at compile-time where they're called. Wrapping them in functions defeats their purpose.

## The Solution: Extern Inline Functions

### How Extern Inline Works

```haxe
class Assert {
    extern inline public static function assertEqual<T>(expected: T, actual: T): Void {
        untyped __elixir__('assert {0} == {1}', actual, expected);
    }
}
```

Key components:
1. **`extern`** - No function body is compiled; it exists only at compile time
2. **`inline`** - Function body is copied to every call site
3. **Result** - The `__elixir__()` code appears directly where the function is called

### Compilation Process

```haxe
// Haxe test code
@:exunit
class UserTest extends TestCase {
    @:test
    function testUserCreation() {
        var result = createUser("John");
        assertEqual("John", result.name);  // Call site
    }
}
```

Compilation steps:
1. Haxe sees `assertEqual("John", result.name)`
2. Because of `extern inline`, it replaces the call with the function body
3. The `__elixir__()` injection happens at the call site
4. Generated Elixir has `assert result.name == "John"` directly in the test

Final output:
```elixir
defmodule UserTest do
    use ExUnit.Case
    
    test "user creation" do
        result = create_user("John")
        assert result.name == "John"  # Direct macro call!
    end
end
```

## Benefits of This Architecture

### 1. Proper Macro Expansion
- Macros expand in the correct context (test module)
- Full access to ExUnit.Case imported macros
- Proper error messages with correct line numbers

### 2. Zero Runtime Overhead
- No function call overhead
- No separate Assert module in runtime
- Direct macro expansion as if hand-written

### 3. Type Safety Preserved
- Haxe still type-checks at compile time
- IDE autocomplete and documentation work
- Refactoring tools understand the API

### 4. Clean Generated Code
```elixir
# What we generate (clean, idiomatic)
assert user.age >= 18

# What we avoided (function call indirection)
Assert.assert_true(user.age >= 18)
```

## Implementation Details

### Assert Module Compilation

The Assert module essentially disappears during compilation:
```elixir
defmodule Assert do
    nil  # Empty module - all functions were inlined
end
```

### Domain-Specific Assertions

For Result and Option types, we use pattern matching:
```haxe
extern inline public static function assertIsOk<T,E>(result: Dynamic): Void {
    untyped __elixir__('assert match?({:ok, _}, {0})', result);
}
```

Generates:
```elixir
assert match?({:ok, _}, parse_result)
```

## Alternative Approaches Considered

### 1. Macro Generation (Rejected)
**Idea**: Generate Elixir macros instead of functions
**Problem**: Would require complex macro generation and wouldn't provide type safety

### 2. Import Manipulation (Rejected)  
**Idea**: Import ExUnit.Assertions into every test module
**Problem**: Still wouldn't work - wrapping macros in functions breaks them

### 3. AST Transformation (Rejected)
**Idea**: Detect Assert calls and transform them during AST processing
**Problem**: Complex, fragile, and breaks the separation of concerns

### 4. Direct __elixir__ Usage (Rejected)
**Idea**: Have users write `untyped __elixir__('assert ...')` directly
**Problem**: No type safety, poor developer experience, error-prone

## Decision Rationale

The `extern inline` approach was chosen because it:
1. **Maintains type safety** - Full Haxe type checking
2. **Generates idiomatic code** - Output looks hand-written
3. **Has zero overhead** - No runtime cost
4. **Is maintainable** - Simple, clear implementation
5. **Provides good DX** - Clean API with documentation

## Future Considerations

### Potential Enhancements
- Custom assertion macros with `extern inline`
- Property-based testing assertions
- Async assertion helpers

### Maintenance Notes
- All Assert methods MUST use `extern inline`
- New assertions should follow the established pattern
- Documentation should explain the inline behavior

## Related Documentation

- [ExUnit Testing Guide](../02-user-guide/exunit-testing.md)
- [Compiler Macro System](../03-compiler-development/macro-time-vs-runtime.md)
- [Standard Library Architecture](../04-api-reference/standard-library.md)

## Code References

- Implementation: `std/exunit/Assert.hx`
- Tests: `test/tests/ExunitEdgeCases/`, `test/snapshot/core/domain_abstractions_exunit/`
- Transformation: `src/reflaxe/elixir/ast/transformers/AnnotationTransforms.hx`
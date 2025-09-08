# The .cross.hx Solution for __elixir__ Injection in Core Types

## Problem Summary

When using `@:coreApi` to replace Haxe's built-in types (like Array) with custom implementations that use `untyped __elixir__()` for target code injection, we encounter "Unknown identifier: __elixir__" errors during the eval/macro expansion phase.

### Why This Happens

1. **Unconditional Core Type Shadowing**: Using `@:coreApi` on `Array.hx` unconditionally replaces Haxe's built-in Array
2. **Eval Target Processing**: During macro expansion, Haxe's eval target processes the replacement Array
3. **Injection Function Timing**: `__elixir__` is injected by Reflaxe AFTER the typing phase, but eval needs it DURING typing
4. **Inline Method Problem**: Inline methods are typed immediately when the type is imported, before Reflaxe initialization

## The Solution: Conditional Compilation with .cross.hx

### Haxe's Cross-Platform File Naming Convention

Haxe provides a built-in solution for conditional type replacement:
- **`.cross.hx` suffix** (Haxe 4.x) - Only includes the file when compiling for the specific target
- **`.target.hx` suffix** (Haxe 5.0+) - More explicit naming for the same functionality

### Implementation

Instead of:
```
std/Array.hx          # Unconditionally replaces Array for ALL targets
```

Use:
```
std/Array.cross.hx    # Only replaces Array when compiling for Elixir
```

### How It Works

1. **During Eval/Macro Expansion**: Haxe uses its built-in Array type (no replacement)
2. **During Elixir Compilation**: Array.cross.hx replaces the built-in Array
3. **Result**: `__elixir__()` is only needed when actually compiling to Elixir, after Reflaxe has initialized

## Verified Working Example

### Array.cross.hx with Inline Methods
```haxe
@:coreApi
class Array<T> {
    // Inline methods with __elixir__ injection now work!
    public inline function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__('Enum.map({0}, {1})', this, f);
    }
    
    public inline function filter(f: T -> Bool): Array<T> {
        return untyped __elixir__('Enum.filter({0}, {1})', this, f);
    }
    
    // Other Array methods...
}
```

### Generated Elixir Output
```elixir
# Clean, idiomatic Elixir code
doubled = Enum.map(numbers, fn x -> x * 2 end)
evens = Enum.filter(numbers, fn x -> x rem 2 == 0 end)
result = Enum.map(Enum.filter(numbers, fn x -> x > 2 end), fn x -> x * 10 end)
```

## Benefits

1. **No "Unknown identifier" errors** - Eval never sees `__elixir__` calls
2. **Inline methods work** - Can use `inline` for better performance
3. **Clean generated code** - Direct Enum calls without wrappers
4. **Standard Haxe pattern** - Uses Haxe's built-in cross-platform conventions
5. **No compiler modifications needed** - Works with existing Reflaxe configuration

## Implementation Steps

1. **Rename core type files**:
   ```bash
   mv std/Array.hx std/Array.cross.hx
   mv std/Bytes.hx std/Bytes.cross.hx
   # etc. for other @:coreApi types
   ```

2. **Verify compilation**:
   ```bash
   npx haxe build.hxml  # Should compile without errors
   ```

3. **Test generated code**:
   ```bash
   mix compile          # Verify Elixir code is valid
   ```

## Comparison with Other Approaches

### ❌ @:runtime Metadata
- **Issue**: Only works for non-inline methods
- **Limitation**: Loses inline optimization benefits

### ❌ extern inline
- **Issue**: Only works for abstract types, not classes
- **Limitation**: Can't use for core type replacement

### ❌ @:nativeFunctionCode
- **Issue**: More complex syntax, less readable
- **Limitation**: Requires metadata on every method

### ✅ .cross.hx Convention
- **Works**: For all scenarios - inline methods, classes, abstracts
- **Simple**: Just rename the file
- **Standard**: Built into Haxe, no special configuration

## Other Reflaxe Compilers

Most Reflaxe compilers that successfully use injection functions either:
1. **Piggyback on Haxe built-ins** (e.g., Reflaxe.CSharp uses `__cs__`)
2. **Use @:nativeFunctionCode** metadata (e.g., Reflaxe.lua)
3. **Don't replace core types** (avoid the issue entirely)

The .cross.hx solution is the cleanest approach for custom injection functions.

## Conclusion

The `.cross.hx` naming convention elegantly solves the injection function timing issue by making core type replacement conditional. This allows us to use `__elixir__()` in inline methods while maintaining clean, idiomatic code generation and avoiding eval target errors.

This solution was discovered through collaboration with the Reflaxe author and extensive testing across multiple Reflaxe targets.
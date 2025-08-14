# Compiler Inheritance Architecture

## Decision: DirectToStringCompiler over BaseCompiler

### Date: 2025-08-14
**Decision**: ElixirCompiler extends `DirectToStringCompiler` instead of `BaseCompiler`

## Why DirectToStringCompiler?

### Fundamental Alignment
- **Elixir compilation is string generation**: We transform Haxe AST to Elixir text files
- **Our implementation is string-based**: Every compile method returns strings
- **Pure functional approach**: No side effects, easier testing and composition
- **Simpler mental model**: AST → String → File

### Technical Benefits
```haxe
// With DirectToStringCompiler (our choice)
public override function compileClass(...): String {
    return "defmodule " + className + " do\n" + body + "\nend";
}

// With BaseCompiler (wrong for us)
public override function compileClass(...): Void {
    output.write("defmodule " + className + " do\n");
    output.write(body);
    output.write("\nend");
    // More complex, no return value for testing
}
```

### Testing Advantages
- **Unit testable**: `assertEquals(expected, compiler.compileClass(...))`
- **Composable**: String results can be combined and transformed
- **Debuggable**: Can print intermediate strings easily

## BaseCompiler vs DirectToStringCompiler

### BaseCompiler
**Design**: Direct file I/O during compilation
- **Returns**: `Void` (side effects only)
- **Use case**: Binary formats, multi-file outputs (like C/C++ with .h/.c split)
- **Complexity**: Must manage output streams and file handles
- **Testing**: Harder - need to mock file system

### DirectToStringCompiler
**Design**: Build strings in memory, framework handles file writing
- **Returns**: `String` (pure functions)
- **Use case**: Script languages (JavaScript, Python, Ruby, Elixir)
- **Complexity**: Simple string concatenation and manipulation
- **Testing**: Easy - just compare strings

## Typedef Handling

### Important Clarification
**Typedefs CAN be used in Haxe source code targeting Elixir!**

```haxe
// In your Haxe code - FULLY SUPPORTED
typedef User = {
    name: String,
    age: Int,
    email: String
}

typedef Point = {x: Float, y: Float};
typedef AsyncCallback<T> = (T -> Void) -> Void;
```

### How It Works
1. **You write**: Typedefs in Haxe for better code organization
2. **Haxe resolves**: During typing phase, expands all typedef references
3. **We receive**: Already-resolved types in the AST
4. **We generate**: Elixir code with expanded types

### Why compileTypedef Returns Empty
```haxe
public override function compileTypedef(defType: DefType): String {
    return ""; // No separate typedef file needed in Elixir
}
```

- Elixir doesn't have direct typedef equivalents
- Types are already resolved by Haxe's typing phase
- Generating typedef files would create invalid Elixir syntax

## Migration from Reflaxe 3.0 to 4.0

### Breaking Changes
1. **Inheritance change**: BaseCompiler → DirectToStringCompiler
2. **New required methods**: `compileClass`, `compileEnum` must be implemented
3. **Return type changes**: Methods return `String` not `Null<String>`
4. **Removed methods**: `formatExpressionLine` no longer exists

### Migration Steps Taken
```haxe
// 1. Change inheritance
class ElixirCompiler extends DirectToStringCompiler // was BaseCompiler

// 2. Add required overrides
public override function compileClass(...): String {
    return compileClassImpl(...) ?? "";
}

// 3. Fix return types
public override function compileAbstract(...): String { // was Void
    return generateTypeAlias(...);
}

// 4. Remove obsolete overrides
// Deleted: formatExpressionLine
```

## Preprocessor Benefits (Reflaxe 4.0)

With DirectToStringCompiler and Reflaxe 4.0, we get:
- **Full preprocessor pipeline**: Automatic AST optimization
- **Cleaner output**: No more `_g`, `temp_array` variables
- **Better performance**: Optimized AST before string generation

## Decision Rationale

**DirectToStringCompiler is the correct choice because:**
- ✅ Matches our string-based implementation perfectly
- ✅ Aligns with other script language Reflaxe targets
- ✅ Simpler, more maintainable code
- ✅ Better testing capabilities
- ✅ No unnecessary complexity from output stream management

**BaseCompiler would have been wrong because:**
- ❌ Forces stream-based I/O we don't need
- ❌ Requires rewriting all compilation methods
- ❌ Makes testing much harder
- ❌ Adds complexity with no benefit for Elixir generation

## References
- [Reflaxe Documentation](https://github.com/SomeRanDev/reflaxe)
- [DirectToStringCompiler Source](https://github.com/SomeRanDev/reflaxe/blob/main/src/reflaxe/DirectToStringCompiler.hx)
- Other DirectToStringCompiler targets: Reflaxe.JavaScript, Reflaxe.Python
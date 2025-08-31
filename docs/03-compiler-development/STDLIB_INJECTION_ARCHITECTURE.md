# Standard Library Code Injection Architecture

## The __elixir__() Injection Limitation

### Discovery (August 2025)

During implementation of idiomatic array transformations, we discovered a fundamental limitation with `__elixir__()` injection in the AST pipeline.

## The Problem

When compiling code like:
```haxe
var doubled = numbers.map(fn x -> x * 2 end);
```

The compiler sees a `TCall` to the `map` method on an array object. However:

1. **Method bodies are not expanded** - The compiler doesn't execute/expand Array.hx's `map()` implementation
2. **Direct compilation** - The call is compiled directly as `numbers.map(fn x -> x * 2 end)`
3. **No injection opportunity** - The `__elixir__()` code inside Array.hx never gets processed

## Why This Happens

The AST pipeline operates on typed expressions (TypedExpr) from Haxe's type checker:
- Haxe has already resolved that `numbers.map` refers to Array's map method
- The TypedExpr just contains a method call, not the method's implementation
- Standard library method bodies are not part of the compilation unit

## Architectural Decision: Separation of Concerns

### Principle
**The compiler handles language constructs, the stdlib handles its own implementation**

### What This Means

**Compiler Responsibilities** (ElixirASTBuilder/Transformer):
- Core language constructs (for, while, if, switch)
- List comprehensions
- Pattern matching
- Module/class compilation
- OTP patterns

**Standard Library Responsibilities** (std/):
- Array methods via inline or extern patterns
- String methods via extern
- Date/Time via extern
- Collections via extern

### Benefits

1. **Clean boundaries** - No coupling between compiler and stdlib
2. **Maintainability** - Changes to Array methods don't require compiler changes
3. **Modularity** - Stdlib can evolve independently
4. **Framework-agnostic** - Compiler doesn't assume specific stdlib implementations

## Alternative Approaches

### Option 1: Inline Expansion (Not Viable)
Would require the compiler to:
- Parse and understand stdlib source files
- Inline method bodies during compilation
- Handle recursive expansion
- **Problem**: Breaks macro-time/runtime separation

### Option 2: Compiler Transformations (Rejected)
Adding array transformations to ElixirASTBuilder:
- **Problem**: Creates tight coupling
- **Problem**: Compiler needs to know about every stdlib method
- **Problem**: Maintenance burden as stdlib grows

### Option 3: Extern Pattern (Recommended)
Define Array as extern with proper Elixir module mapping:
```haxe
@:native("Enum")
extern class Array<T> {
    function map<S>(f: T -> S): Array<S>;
}
```
- **Benefit**: Clean separation
- **Benefit**: Idiomatic output
- **Benefit**: No compiler coupling

### Option 4: Metadata-Driven (Future)
Use metadata to guide compilation:
```haxe
@:elixirCall("Enum.map")
public function map<S>(f: T -> S): Array<S>;
```
- **Benefit**: Declarative
- **Benefit**: Compiler can optimize
- **Benefit**: Maintains separation

## Current Status

As of August 2025:
- Array method transformations removed from ElixirASTBuilder
- `__elixir__()` injection works for direct calls but not method bodies
- Need to implement extern pattern or metadata-driven approach

## Lessons Learned

1. **AST pipelines don't expand method bodies** - This is by design
2. **Separation of concerns is critical** - Compiler vs stdlib boundaries
3. **Code injection has limitations** - Works for direct use, not indirect
4. **Extern patterns are powerful** - Better than trying to inject code

## Next Steps

1. Convert Array.hx to extern pattern
2. Document stdlib implementation guidelines
3. Consider metadata-driven compilation for future
4. Maintain clear compiler/stdlib boundaries

## References

- [CLAUDE.md](/CLAUDE.md) - Architectural principles
- [ElixirASTBuilder.hx](../../src/reflaxe/elixir/ast/ElixirASTBuilder.hx) - Where transformations were removed
- [Array.hx](../../std/Array.hx) - Current stdlib implementation
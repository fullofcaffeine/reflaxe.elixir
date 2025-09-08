# @:runtime Inline Pattern - Investigation and Findings

## Executive Summary

After extensive investigation, we discovered that **@:runtime has limited applicability for our Elixir target**. While C++ successfully uses @:runtime with both `untyped __cpp__()` AND real methods that exist on types, our Elixir target lacks equivalent native methods to reference, making the pattern less useful for us.

## Key Finding: How C++ Uses @:runtime

The C++ compiler successfully uses @:runtime inline with BOTH:
1. **`untyped __cpp__()`** - For native C++ code injection
2. **`untyped this.method()`** - For methods that exist on the C++ type

```haxe
// C++ Array.hx - ACTUAL WORKING CODE
@:runtime public inline function reverse(): Void {
    @:include("algorithm", true)
    untyped __cpp__("std::reverse({0}, {1})", this.begin(), this.end());
}

@:runtime public inline function push(x: T): Int {
    untyped this.push_back(x);  // push_back exists on std::deque
    return length;
}

@:runtime public inline function sort(f: (T, T) -> Int): Void {
    @:include("algorithm", true)
    untyped __cpp__("std::sort({0}, {1}, {2})", this.begin(), this.end(), function(a, b) {
        return f(a, b) < 0;
    });
}
```

## Why This Pattern Doesn't Translate to Elixir

**C++ has native methods on types**:
- `std::deque` has `push_back()`, `begin()`, `end()`, etc.
- These methods exist during typing phase
- `untyped` allows bypassing type checking while the methods still exist

**Elixir lists have no methods**:
- Elixir lists are just data structures `[1, 2, 3]`
- Operations are module functions: `Enum.map(list, fn)`
- No methods exist on the type itself to reference with `untyped`

## The Timing Problem with __elixir__()

### Why We Can't Use Regular Inline with __elixir__()

```haxe
// ❌ THIS FAILS - "Unknown identifier: __elixir__"
public inline function map<S>(f: T -> S): Array<S> {
    return untyped __elixir__('Enum.map({0}, {1})', this, f);
}
```

**The Timing Issue:**
1. **Macro expansion phase**: Haxe processes `inline` functions and expands them
2. **Problem**: `__elixir__()` doesn't exist yet - it's injected by Reflaxe AFTER typing
3. **Result**: Compilation error "Unknown identifier: __elixir__"

### The Performance Cost Without Inline

Without inline, every array operation generates a wrapper function:

```elixir
# Generated Elixir WITHOUT inline - WRAPPER OVERHEAD
defmodule Array do
  def map(array, f) do
    Enum.map(array, f)  # Just delegates - unnecessary wrapper!
  end
end

# User code becomes:
doubled = Array.map(my_array, fn x -> x * 2 end)  # Extra function call!
```

## The Solution: @:runtime + untyped Pattern

### The C++ Pattern We're Adopting

```haxe
// C++ uses untyped expressions (no __cpp__() in inline methods)
@:runtime public inline function push(x: T): Int {
    untyped this.push_back(x);  // Bypasses typing completely
    return length;
}

// Elixir adaptation - use untyped with direct calls
@:runtime public inline function map<S>(f: T -> S): Array<S> {
    return untyped Enum.map(this, f);  // No __elixir__() needed!
}
```

**The Key Insight:**
- `untyped` tells Haxe "don't type-check this expression"
- The expression is passed through as-is to the compiler
- The compiler recognizes these patterns and generates appropriate Elixir code
- No `__elixir__()` identifier needed during typing phase!

### Generated Output Comparison

```haxe
// Haxe source
var doubled = myArray.map(x -> x * 2);
```

**Without @:runtime (wrapper function):**
```elixir
# Generates wrapper module
defmodule Array do
  def map(array, f), do: Enum.map(array, f)
end

# Call goes through wrapper
doubled = Array.map(my_array, fn x -> x * 2 end)
```

**With @:runtime (direct call):**
```elixir
# No wrapper generated - direct call!
doubled = Enum.map(my_array, fn x -> x * 2 end)
```

## Implementation in ElixirCompiler

### Compiler Support

```haxe
// In ElixirCompiler.hx
switch(func.field.kind) {
    case FMethod(MethInline):
        // Check for @:runtime metadata
        if (!func.field.meta.has(":runtime")) {
            continue; // Skip regular inline functions
        }
        // @:runtime inline functions are generated normally
        // They will be inlined at call sites with __elixir__() support
    case _:
        // Normal function generation
}
```

### When Processing Call Sites

The compiler can detect @:runtime inline methods and expand them with __elixir__() support:

```haxe
// At call sites, the compiler can:
1. Detect the method has @:runtime inline
2. Expand the method body with __elixir__() calls
3. Generate direct Elixir code without wrappers
```

## Usage Guidelines

### When to Use @:runtime inline

**Perfect for simple delegations:**
```haxe
@:runtime public inline function map<S>(f: T -> S): Array<S> {
    return untyped __elixir__('Enum.map({0}, {1})', this, f);
}

@:runtime public inline function filter(f: T -> Bool): Array<T> {
    return untyped __elixir__('Enum.filter({0}, {1})', this, f);
}

@:runtime public inline function join(sep: String): String {
    return untyped __elixir__('Enum.join({0}, {1})', this, sep);
}
```

### When NOT to Use @:runtime inline

**Complex logic should stay as regular methods:**
```haxe
// Complex conditional logic - keep as regular method
public function slice(pos: Int, ?end: Int): Array<T> {
    if (end == null) {
        return untyped __elixir__('Enum.slice({0}, {1}..-1//1)', this, pos);
    } else {
        return untyped __elixir__('Enum.slice({0}, {1}..{2}//1)', this, pos, end - 1);
    }
}

// Multiple statements - keep as regular method
public function lastIndexOf(x: T, ?fromIndex: Int): Int {
    if (fromIndex == null) {
        return untyped __elixir__("
            case Enum.reverse({0}) |> Enum.find_index(fn item -> item == {1} end) do
                nil -> -1
                idx -> length({0}) - idx - 1
            end
        ", this, x);
    } else {
        // Handle fromIndex case
        return untyped __elixir__("
            {0}
            |> Enum.slice(0, {2} + 1)
            |> Enum.reverse()
            |> Enum.find_index(fn item -> item == {1} end)
            |> case do
                nil -> -1
                idx -> {2} - idx
            end
        ", this, x, fromIndex);
    }
}
```

## Performance Benefits

### Zero-Overhead Abstraction

With @:runtime inline, we achieve true zero-overhead abstraction:

| Pattern | Generated Code | Performance |
|---------|---------------|-------------|
| Without inline | `Array.map(list, f)` | Extra function call overhead |
| With @:runtime inline | `Enum.map(list, f)` | Direct native call - ZERO overhead |
| Hand-written Elixir | `Enum.map(list, f)` | Identical to @:runtime output |

### Benchmark Impact

For functional programming chains:
```haxe
result = array
    .filter(x -> x > 0)
    .map(x -> x * 2)
    .reduce((a, b) -> a + b, 0);
```

- **Without @:runtime**: 3 wrapper function calls
- **With @:runtime**: 0 wrapper function calls - direct Elixir
- **Performance gain**: Eliminates function call overhead completely

## Comparison with Other Approaches

### @:nativeFunctionCode (Not Applicable for @:coreApi)

```haxe
// Only works on extern classes - can't use with @:coreApi
@:nativeFunctionCode("Enum.map({this}, {arg0})")
extern public function map<S>(f: T -> S): Array<S>;
```

**Limitations:**
- Requires extern class (incompatible with @:coreApi)
- No support for conditional logic
- Static pattern only

### Regular __elixir__() Without Inline

```haxe
// Works but generates wrapper functions
public function map<S>(f: T -> S): Array<S> {
    return untyped __elixir__('Enum.map({0}, {1})', this, f);
}
```

**Limitations:**
- Generates wrapper module/functions
- Extra function call overhead
- Non-idiomatic generated code

### @:runtime inline (Our Solution)

```haxe
// Best of both worlds - inline WITH injection
@:runtime public inline function map<S>(f: T -> S): Array<S> {
    return untyped __elixir__('Enum.map({0}, {1})', this, f);
}
```

**Benefits:**
- ✅ Works with @:coreApi classes
- ✅ Supports __elixir__() injection
- ✅ Zero wrapper overhead
- ✅ Idiomatic Elixir output
- ✅ Maintains type safety

## Implementation Checklist

When implementing @:runtime support:

1. **Compiler modification**:
   - [x] Detect @:runtime metadata in inline method processing
   - [x] Treat @:runtime inline methods as regular functions during generation
   - [ ] Implement call-site inlining for @:runtime methods

2. **Standard library updates**:
   - [x] Add @:runtime to simple delegation methods
   - [ ] Avoid @:runtime on complex logic methods
   - [x] Document performance characteristics

3. **Testing**:
   - [ ] Verify no wrapper functions generated
   - [ ] Confirm direct Elixir calls in output
   - [ ] Benchmark performance improvements

## Technical Deep Dive

### Why Other Reflaxe Compilers Use @:runtime

**C++ (reflaxe.CPP):**
```haxe
@:runtime public inline function push(x: T): Int {
    untyped this.push_back(x);
    return length;
}
```

**JavaScript (reflaxe.JS):**
```haxe
@:runtime inline function map<S>(f:T->S):Array<S> {
    var result:Array<S> = js.Syntax.construct(Array, length);
}
```

They all face the same timing issue: target injection doesn't exist during macro expansion.

### The Universal Pattern

All Reflaxe compilers follow this pattern:
1. **Regular inline**: Can't use target injection
2. **No inline**: Generates wrappers (overhead)
3. **@:runtime inline**: Defers expansion, enables injection

## Future Enhancements

### Automatic @:runtime Detection

The compiler could automatically detect when inline methods use __elixir__() and apply @:runtime behavior implicitly:

```haxe
// Future: Compiler auto-detects __elixir__() usage
public inline function map<S>(f: T -> S): Array<S> {
    return untyped __elixir__('Enum.map({0}, {1})', this, f);
    // Compiler: "This has __elixir__(), treating as @:runtime"
}
```

### Call-Site Optimization

Enhanced call-site processing could further optimize @:runtime methods:
- Constant folding for literal arguments
- Dead code elimination for unused return values
- Pipeline fusion for chained operations

## Summary

**The Investigation**: We explored whether @:runtime could enable inline + __elixir__() for zero-overhead abstractions, similar to how C++ uses it.

**The Discovery**: 
- C++ successfully uses @:runtime with `untyped __cpp__()` in inline methods
- The fundamental issue is that `__elixir__()` doesn't exist as an identifier during Haxe's typing phase
- Even with attempts to provide it globally, the typing phase still fails

**Why C++ Works But Elixir Doesn't**:
- **`__cpp__` is built into Haxe itself** - It's a magic function provided by the Haxe compiler for the C++ target
- **`__elixir__` is NOT built into Haxe** - It's injected by Reflaxe AFTER typing, which is too late for @:runtime inline
- The C++ target gets special treatment from Haxe, while custom targets like Elixir don't have this privilege

**Current Best Practices**:
1. **Use regular methods with __elixir__()** - Accept the minimal wrapper overhead
2. **Focus on idiomatic code generation** - Even with wrappers, generate clean Elixir
3. **Future consideration**: Would require deeper Haxe compiler integration to work

**Key Lesson**: The @:runtime pattern works for C++ because Haxe has built-in support for `__cpp__` as a magic function. Custom Reflaxe targets don't get this privilege - our injection functions are added AFTER Haxe's typing phase, making them incompatible with @:runtime inline.

**Verification**: You can see this in Haxe's own standard library at `/std/cpp/` where files like `Int64Map.hx` use `untyped __cpp__()` freely. This is possible because Haxe knows about `__cpp__` natively.

**Status**: @:runtime inline with __elixir__() is not currently possible for our Elixir target. The regular method approach with __elixir__() remains our solution, accepting the small overhead of wrapper functions.

## Investigation Findings: How Other Reflaxe Compilers Work

After thorough investigation of Reflaxe.CPP and Reflaxe.CSharp:

### Reflaxe.CPP Success with @:runtime
- Uses `untyped __cpp__()` in @:runtime inline methods successfully
- Sets `targetCodeInjectionName: "__cpp__"` in CompilerInit.hx
- **KEY**: `__cpp__` is a built-in Haxe magic function (found in /std/cpp/)
- Reflaxe.CPP is "claiming" an identifier that Haxe already knows about

### Reflaxe.CSharp Also Works
- Uses `untyped __cs__()` in test files
- Sets `targetCodeInjectionName: "__cs__"` in CSCompilerInit.hx  
- **KEY**: `__cs__` is ALSO a built-in Haxe magic function (found in /std/cs/)
- Like CPP, it hijacks Haxe's existing magic function

### Why Elixir Cannot Use This Pattern
- **`__elixir__` is NOT built into Haxe** - It's purely a Reflaxe injection
- **No `/std/elixir/` in Haxe** - Elixir isn't a native Haxe target
- **Timing issue remains**: Reflaxe can only inject after typing phase
- **Cannot hijack**: There's no existing `__elixir__` to claim

### The Fundamental Difference
**C++ and C# work because they're hijacking Haxe's existing magic functions:**
- Haxe already knows about `__cpp__` and `__cs__` during typing
- Reflaxe just tells its compiler to handle these existing functions
- The identifiers exist throughout the entire compilation pipeline

**Elixir cannot work this way because:**
- `__elixir__` doesn't exist in Haxe
- We're creating it from scratch via Reflaxe
- By the time we inject it, the typing phase is over
- @:runtime inline methods are typed before our injection exists

### How Other Custom Targets Handle This

**Reflaxe.GDScript:**
- Sets `targetCodeInjectionName: "__gdscript__"` but faces same limitation
- Uses `@:runtime` but NOT with `__gdscript__()`
- Instead uses `@:nativeFunctionCode` metadata for injection
- Example: `@:nativeFunctionCode("({arg0} as {arg1})")`

**Reflaxe.Go:**
- Sets `targetCodeInjectionName: "__go__"` 
- Uses `untyped __go__()` in regular methods
- Uses `@:runtime inline` only with pure Haxe code, never with `__go__()`
- Cannot combine `@:runtime inline` with `__go__()` - same timing issue as us

### Conclusion: Only Native Haxe Targets Can Use @:runtime with Injection
- **Works**: C++ (`__cpp__`), C# (`__cs__`) - built into Haxe
- **Doesn't Work**: Elixir (`__elixir__`), Go (`__go__`), GDScript (`__gdscript__`) - custom Reflaxe targets
- **Alternative Patterns**: Metadata-based injection (@:nativeFunctionCode) or regular methods without inline
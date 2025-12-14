# Title: Custom target injection functions (`__elixir__`, `__go__`, etc.) cannot be used with `@:runtime inline` - Unlike native targets (`__cpp__`, `__cs__`)

## Problem Description

After extensive investigation, I've discovered a fundamental limitation that affects all custom Reflaxe targets: **target injection functions (like `__elixir__()`, `__go__()`, `__gdscript__()`) cannot be used with `@:runtime inline`**, while native Haxe targets (C++, C#) work perfectly with their injection functions.

This creates a performance disadvantage for custom Reflaxe targets when implementing standard libraries, as we cannot achieve zero-overhead abstractions for simple operations.

## The Core Issue

### What Works (Native Haxe Targets)

C++ and C# can successfully use `@:runtime inline` with their injection functions:

```haxe
// From Haxe's std/cpp/Int64Map.hx
@:runtime public inline function keyValueIterator():KeyValueIterator<Int64, T> {
    return new haxe.iterators.MapKeyValueIterator(this);
}

// From reflaxe.CPP's Array implementation
@:runtime public inline function reverse(): Void {
    untyped __cpp__("std::reverse({0}, {1})", this.begin(), this.end());
}
```

This works because **`__cpp__` and `__cs__` are built-in magic functions in the Haxe compiler itself**. They exist throughout the entire compilation pipeline.

### What Doesn't Work (Custom Reflaxe Targets)

When trying the same pattern with custom targets:

```haxe
// Attempting in Reflaxe.Elixir
@:runtime public inline function map<S>(f: T -> S): Array<S> {
    return untyped __elixir__('Enum.map({0}, {1})', this, f);
}
// ERROR: Unknown identifier: __elixir__
```

The error occurs because:
1. `@:runtime` defers inline expansion until after the typing phase
2. But `__elixir__()` is injected by Reflaxe AFTER the typing phase
3. When the runtime inline method is typed, `__elixir__` doesn't exist yet

## Investigation Findings

I've checked how other custom Reflaxe targets handle this:

### Reflaxe.GDScript
- Sets `targetCodeInjectionName: "__gdscript__"`
- **Cannot use** `@:runtime inline` with `__gdscript__()`
- Instead uses `@:nativeFunctionCode` metadata for simple injections
- Uses `@:runtime` only with pure Haxe code

### Reflaxe.Go
- Sets `targetCodeInjectionName: "__go__"`
- Uses `untyped __go__()` in regular methods
- **Cannot combine** `@:runtime inline` with `__go__()`
- Uses `@:runtime inline` only with pure Haxe code

### Why C++ and C# Work

Looking at Haxe's source code:
- `/std/cpp/` contains many files using `untyped __cpp__()`
- `/std/cs/` contains many files using `untyped __cs__()`

These are **built into Haxe itself**, not injected by Reflaxe. When Reflaxe.CPP sets `targetCodeInjectionName: "__cpp__"`, it's claiming an identifier that already exists, not creating a new one.

## The Impact

This limitation means custom Reflaxe targets must accept wrapper function overhead for standard library implementations:

```elixir
# What we have to generate (with wrapper):
defmodule Array do
  def map(array, f), do: Enum.map(array, f)  # Extra function call
end

# What we want to generate (direct call):
Enum.map(array, f)  # No wrapper
```

While the overhead is minimal (microseconds), it prevents us from achieving true zero-overhead abstractions.

## Potential Solutions

### 1. Reflaxe Framework Enhancement (Preferred)
Could Reflaxe provide a mechanism to register injection functions earlier in the compilation pipeline? Perhaps during `Context.onMacroContextReused()` or through a special initialization that makes the identifier available during typing?

### 2. Haxe Compiler Plugin
We could potentially write a Haxe compiler plugin to register `__elixir__` as a built-in identifier, similar to how `__cpp__` and `__cs__` are handled. However, this would require users to compile a custom Haxe version or load a plugin.

### 3. Alternative Metadata Pattern
Similar to GDScript's `@:nativeFunctionCode`, we could use metadata-based injection for simple cases:
```haxe
@:runtime @:inlineCode("Enum.map({0}, {1})")
public inline function map<S>(f: T -> S): Array<S>;
```
This would require compiler changes but might be more feasible.

## Questions

1. **Is there a way to make custom injection functions available during the typing phase that I'm missing?**
2. **Could Reflaxe be enhanced to support this use case?**
3. **Have you encountered this limitation before, and do you have any recommended workarounds?**
4. **Would you be interested in a PR that adds support for metadata-based injection as an alternative?**

## Reproduction

To reproduce the issue:

1. In any custom Reflaxe target, create a `@:coreApi` class
2. Add a method with `@:runtime inline` that uses the target injection function
3. Compilation will fail with "Unknown identifier: __[target]__"

Example for Reflaxe.Elixir:
```haxe
@:coreApi
class Array<T> {
    @:runtime public inline function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__('Enum.map({0}, {1})', this, f);
    }
}
```

## Environment
- Haxe: 4.3.7
- Reflaxe: Latest
- Affected: All custom Reflaxe targets (Elixir, Go, GDScript, etc.)
- Working: Native Haxe targets (C++, C#)

## References
- Investigation documentation: [RUNTIME_INLINE_PATTERN.md](https://github.com/EliteMasterEric/reflaxe_elixir/blob/main/docs/03-compiler-development/RUNTIME_INLINE_PATTERN.md)
- Related Haxe source: `/std/cpp/`, `/std/cs/` (shows built-in `__cpp__` and `__cs__` usage)

---

This is a fundamental architectural limitation that affects all custom Reflaxe targets. Any insights or solutions would be greatly appreciated, as this would enable true zero-overhead abstractions for standard library implementations across all Reflaxe compilers.
# StringTools Implementation Strategy

## Executive Summary

This document captures the architectural decision made for implementing StringTools in Reflaxe.Elixir and compares it with approaches taken by other Reflaxe compilers. After careful analysis, we chose the **Extern + Runtime Library** pattern over full Haxe compilation.

## The Problem

When compiling Haxe standard library classes like `StringTools`, the naive approach of compiling their inline Haxe implementations directly results in invalid target language code. For Elixir, this produced JavaScript-like syntax:

```elixir
# Invalid Elixir generated from Haxe StringTools
c = s.charCodeAt(pos)  # JavaScript syntax, not Elixir!
```

## Our Solution: Extern + Runtime Library Pattern

### Architecture
```
┌─────────────────────────┐
│   Haxe Source Code      │
│   using StringTools     │
└───────────┬─────────────┘
            │
            ▼ Compilation
┌─────────────────────────┐
│  /std/StringTools.hx    │  ← Extern definitions
│  @:coreApi extern class │    (compile-time API)
└───────────┬─────────────┘
            │
            ▼ Maps to
┌─────────────────────────┐
│ /std/elixir/           │  ← Runtime implementation
│ StringTools.ex          │    (Elixir native code)
└─────────────────────────┘
```

### Key Characteristics
- **Extern class** with method signatures only
- **Runtime library** with native Elixir implementations
- **Compile-time mapping** of method names (camelCase → snake_case)
- **No code generation** from Haxe method bodies

## Comparison with Other Reflaxe Implementations

### 1. Reflaxe.GDScript: Full Haxe Compilation
```haxe
// std/gdscript/_std/StringTools.hx
class StringTools {
    public static function htmlEscape(s:String, quotes = false):String {
        var buf = new StringBuf();
        for (code in new haxe.iterators.StringIteratorUnicode(s)) {
            switch (code) {
                case '&'.code: buf.add("&amp;");
                // ... actual Haxe implementation
            }
        }
        return buf.toString();
    }
}
```

**Approach**: Full Haxe implementation that gets compiled to GDScript
- ✅ **Pros**: Single source of truth, automatic feature parity
- ❌ **Cons**: Complex transpilation, potential for invalid target code

### 2. Reflaxe.CPP: Native Binding Pattern
```haxe
// std/cxx/_std/Array.hx
@:cxxStd
@:haxeStd
@:pseudoCoreApi
@:filename("HxArray")
class HxArray {
    public static function concat<T>(a: cxx.Ptr<Array<T>>, other: cxx.Ptr<Array<T>>): Array<T> {
        // Haxe implementation using C++ primitives
    }
}

@:coreApi
@:nativeName("std::deque", "Array")
extern class Array<T> {
    // Extern bindings to C++ std::deque
}
```

**Approach**: Hybrid with helper classes + extern bindings
- ✅ **Pros**: Direct C++ STL integration, type-safe
- ❌ **Cons**: Complex annotation system, C++-specific

### 3. Reflaxe.Go: Cross-compilation Files
```haxe
// src/Array.cross.hx
// Special .cross.hx files for standard library
```

**Approach**: Special cross-compilation files
- ✅ **Pros**: Clear separation of cross-platform code
- ❌ **Cons**: Additional file convention to maintain

## Comparison Matrix

| Aspect | Reflaxe.Elixir (Ours) | Reflaxe.GDScript | Reflaxe.CPP | Reflaxe.Go |
|--------|------------------------|------------------|-------------|------------|
| **Pattern** | Extern + Runtime | Full Compilation | Native Binding | Cross Files |
| **StringTools Source** | Extern only | Full Haxe impl | Uses Haxe std | Cross impl |
| **Runtime Dependency** | Yes (Elixir module) | No (compiled) | Yes (C++ STL) | No |
| **Code Generation** | None for StringTools | Full transpilation | Partial | Full |
| **Method Name Mapping** | Compile-time | Automatic | Mixed | Automatic |
| **Distribution** | Requires runtime lib | Self-contained | Requires C++ runtime | Self-contained |
| **Maintenance** | Two files to sync | Single source | Complex annotations | Cross files |
| **Type Safety** | Extern signatures | Full Haxe typing | C++ type mapping | Go type mapping |

## Why We Chose Extern + Runtime

### Decision Drivers
1. **Predictability**: No surprises from transpiling complex Haxe idioms
2. **Performance**: Native Elixir implementations, no translation overhead
3. **Idiomaticity**: Methods follow Elixir conventions (e.g., `starts_with?`)
4. **Debugging**: Clear Elixir code in stacktraces
5. **Flexibility**: Can optimize for BEAM VM specifics

### Trade-offs Accepted
- **Dual Maintenance**: Must keep extern and runtime in sync
- **Distribution Complexity**: Requires runtime library as dependency
- **Manual Feature Parity**: New StringTools methods need manual implementation

## Implementation Details

### 1. Extern Definition (`/std/StringTools.hx`)
```haxe
@:coreApi
extern class StringTools {
    public static function trim(s: String): String;
    public static function isSpace(s: String, pos: Int): Bool;
    // ... other method signatures
}
```

### 2. Runtime Implementation (`/std/elixir/StringTools.ex`)
```elixir
defmodule StringTools do
  @spec trim(String.t()) :: String.t()
  def trim(s) when is_binary(s) do
    String.trim(s)
  end
  
  @spec is_space(String.t(), integer()) :: boolean()
  def is_space(s, pos) when is_binary(s) and is_integer(pos) do
    case String.at(s, pos) do
      nil -> false
      char -> :binary.first(char) in [9, 10, 11, 12, 13, 32]
    end
  end
end
```

### 3. Compiler Method Mapping
```haxe
// ElixirCompiler.hx
case "StringTools":
    fieldName = switch(fieldName) {
        case "isSpace": "is_space";
        case "startsWith": "starts_with?";
        case "endsWith": "ends_with?";
        // ... other mappings
    };
```

## Lessons Learned

### What Worked Well
1. **Clear separation** between compile-time and runtime
2. **No invalid code generation** from complex Haxe patterns
3. **Easy to debug** - just regular Elixir code at runtime
4. **Flexible naming** - can use Elixir conventions like `?` suffix

### Challenges Encountered
1. **UTF-16 compatibility stubs** needed for StringIteratorUnicode
2. **@:coreApi restrictions** on allowed fields
3. **Distribution model** needs runtime library packaging

### Future Improvements
1. **Automated testing** to ensure extern/runtime stay in sync
2. **Mix package** for runtime library distribution
3. **Macro generation** of extern from runtime (or vice versa)
4. **Comprehensive documentation** of all mapped methods

## Recommendations for Future Standard Library Additions

Based on this experience, for future standard library classes:

1. **Start with extern** - Define the API contract first
2. **Implement incrementally** - Add methods as needed
3. **Test thoroughly** - Both compilation and runtime behavior
4. **Document mappings** - Be explicit about name transformations
5. **Consider the pattern** - Extern works well for stable APIs; compilation might be better for complex logic

## Conclusion

The Extern + Runtime Library pattern proved to be the right choice for Reflaxe.Elixir's StringTools implementation. While it requires maintaining two files, it provides predictable, performant, and idiomatic Elixir code generation. This pattern should be the default for standard library implementations unless there's a compelling reason to compile Haxe implementations directly.

The key insight: **Not all code needs to be transpiled** - sometimes the best transpilation is no transpilation at all.
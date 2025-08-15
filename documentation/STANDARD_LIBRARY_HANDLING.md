# Standard Library Handling in Reflaxe.Elixir

## The Problem
When compiling Haxe standard library classes like `StringTools`, the compiler tries to transpile their inline implementations, resulting in invalid Elixir code with JavaScript-like syntax.

## The Solution: Extern Classes

### 1. Define Extern API (`/std/StringTools.hx`)
```haxe
@:coreApi
extern class StringTools {
    public static function isSpace(s: String, pos: Int): Bool;
    public static function trim(s: String): String;
    // ... other methods
}
```

### 2. Provide Runtime Implementation
The Elixir implementation should be provided as a separate runtime library that projects include as a dependency.

**IMPORTANT**: We should NEVER copy standard library files into project directories!

### Options for Runtime Library Distribution:

#### Option A: Hex Package (Recommended for Production)
```elixir
# mix.exs
defp deps do
  [
    {:reflaxe_runtime, "~> 1.0"}
  ]
end
```

#### Option B: Path Dependency (Development)
```elixir
# mix.exs
defp deps do
  [
    {:reflaxe_runtime, path: "../reflaxe_runtime"}
  ]
end
```

#### Option C: Compiler Bundle (Simple but Less Flexible)
The compiler could automatically include runtime files in output, but this couples compilation with runtime.

## Lessons Learned

### ❌ What NOT to Do:
- Don't copy standard library files around
- Don't patch generated output files  
- Don't mix compile-time and runtime concerns

### ✅ What TO Do:
- Use extern classes for standard library
- Provide runtime as a proper dependency
- Keep clear separation between:
  - Haxe API definitions (externs)
  - Compiler (transpilation)
  - Runtime library (Elixir implementations)

## Implementation Status

### Current Implementation ✅
- StringTools defined as extern in `/std/StringTools.hx`
- Implementation in `/std/elixir/StringTools.ex`
- Compiler maps method names at compile-time
- See [STRINGTOOLS_STRATEGY.md](./STRINGTOOLS_STRATEGY.md) for detailed architectural decisions

### Target Architecture
```
reflaxe.elixir/
├── std/                    # Haxe extern definitions
│   └── StringTools.hx
├── src/                    # Compiler source
└── runtime/                # Elixir runtime library (separate package)
    ├── mix.exs
    └── lib/
        └── string_tools.ex
```

## Special Cases: Primitive Type Methods

When Haxe code calls methods on primitive types (String, Int, Float), these need special handling:

### String Methods
```haxe
// Haxe code
s.charAt(0)
s.charCodeAt(0)
s.length

// Should transpile to:
String.at(s, 0)
:binary.first(String.at(s, 0))
String.length(s)
```

### Why This Matters
- Haxe treats strings as objects with methods
- Elixir treats strings as binaries with module functions
- The compiler must bridge this paradigm difference

## Next Steps

1. Create `reflaxe_runtime` as a separate Mix project
2. Move all runtime implementations there
3. Update compiler to reference runtime properly
4. Document dependency setup for users

## Architectural Decision

After comparing with other Reflaxe implementations (GDScript, CPP, Go), we chose the **Extern + Runtime Library** pattern for StringTools. This provides:

- **Predictable code generation** - No surprises from transpiling Haxe idioms
- **Native performance** - Direct Elixir implementations
- **Idiomatic code** - Following Elixir naming conventions
- **Clear debugging** - Regular Elixir code in stacktraces

See [STRINGTOOLS_STRATEGY.md](./STRINGTOOLS_STRATEGY.md) for the complete analysis and comparison with other approaches.

## Result<T,E> Type: Pure Haxe Implementation

The `Result<T,E>` type in `std/haxe/functional/Result.hx` represents a different approach from extern-based standard library components.

**See Also**: [Paradigm Bridge](paradigms/PARADIGM_BRIDGE.md) - Complete guide to Result types in cross-platform development with functional error handling patterns.

### Why Pure Haxe Implementation?

Unlike StringTools which needs native Elixir implementations, Result types are **algebraic data types** that compile naturally to target patterns:

```haxe
// Pure Haxe implementation
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class ResultTools {
    public static function map<T, U, E>(result: Result<T, E>, transform: T -> U): Result<U, E> {
        return switch (result) {
            case Ok(value): Ok(transform(value));
            case Error(error): Error(error);
        }
    }
}
```

### Target-Specific Compilation

The Reflaxe.Elixir compiler generates **idiomatic patterns** for each target:

**Elixir Output**:
```elixir
# Ok(42) compiles to:
{:ok, 42}

# Error("failed") compiles to:
{:error, "failed"}

# Pattern matching works naturally:
case result do
  {:ok, value} -> value
  {:error, reason} -> nil
end
```

**Other Targets** (JavaScript, Python, etc.):
- Generate appropriate discriminated unions or dataclasses
- Maintain type safety and pattern matching
- Follow each target's idioms

### Benefits of Pure Haxe Approach

1. **Cross-Platform Consistency**: Same API works on all targets
2. **Zero Dependencies**: No external runtime libraries required
3. **Compile-Time Optimization**: Target-specific code generation
4. **Type Safety**: Full compile-time checking across targets
5. **Pattern Matching**: Native switch/case compilation

### When to Use Each Approach

**Extern + Runtime Library** (like StringTools):
- ✅ When wrapping existing target platform APIs
- ✅ When performance requires native implementations
- ✅ When target has specialized data structures (e.g., Elixir binaries)

**Pure Haxe Implementation** (like Result):
- ✅ For algebraic data types and functional patterns
- ✅ When compile-time transformation is sufficient
- ✅ For cross-platform abstractions
- ✅ When target-specific optimization is possible

### Implementation Strategy

The Result type uses **selective compilation patterns**:

```haxe
// In ElixirCompiler.hx
private function isResultType(enumType: EnumType): Bool {
    return enumType.module == "haxe.functional.Result" && enumType.name == "Result";
}

// Special handling for Result constructors
if (isResult) {
    // Generate {:ok, value} or {:error, reason}
    return '{:${fieldName}, ${compiledArgs[0]}}';
} else {
    // Standard enum compilation
    return '${enumName}.${optionName}()';
}
```

This approach allows Result types to compile to **native platform patterns** while maintaining the same Haxe API across all targets.

**See**: [`documentation/FUNCTIONAL_PATTERNS.md`](FUNCTIONAL_PATTERNS.md) for comprehensive Result usage patterns and examples.
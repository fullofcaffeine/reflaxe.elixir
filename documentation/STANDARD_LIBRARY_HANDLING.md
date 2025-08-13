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
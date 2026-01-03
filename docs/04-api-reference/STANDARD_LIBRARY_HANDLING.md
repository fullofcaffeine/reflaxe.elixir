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

## Result<T,E> Type: Pure Haxe Implementation

The `Result<T,E>` type in `std/haxe/functional/Result.hx` represents a different approach from extern-based standard library components.

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
- ✅ When integrating with framework-specific modules (Phoenix, Ecto)

**Pure Haxe Implementation** (like Result<T,E> and Option<T>):
- ✅ For algebraic data types and functional patterns
- ✅ When compile-time transformation is sufficient
- ✅ For cross-platform abstractions
- ✅ When target-specific optimization is possible
- ✅ For type-safe error handling and null safety
- ✅ When zero external dependencies are preferred

### Implementation Strategy

Both Result<T,E> and Option<T> use **selective compilation patterns**:

```haxe
// In ElixirCompiler.hx
private function isResultType(enumType: EnumType): Bool {
    return enumType.module == "haxe.functional.Result" && enumType.name == "Result";
}

private function isOptionType(enumType: EnumType): Bool {
    return enumType.module == "haxe.ds.Option" && enumType.name == "Option";
}

// Special handling for algebraic type constructors
if (isResult) {
    // Generate {:ok, value} or {:error, reason}
    return '{:${fieldName.toLowerCase()}, ${compiledArgs[0]}}';
} else if (isOption) {
    // Generate {:some, value} or :none
    return switch(fieldName) {
        case "Some": '{:some, ${compiledArgs[0]}}';
        case "None": ':none';
        default: '${enumName}.${optionName}()';
    }
} else {
    // Standard enum compilation
    return '${enumName}.${optionName}()';
}
```

This approach allows both types to compile to **native platform patterns** while maintaining the same Haxe API across all targets.

**See**: [Functional Patterns](../07-patterns/FUNCTIONAL_PATTERNS.md) for comprehensive Result and Option usage patterns and examples.

## Option<T> Type: Pure Haxe Implementation

The `Option<T>` type in `std/haxe/ds/Option.hx` provides type-safe null handling following Gleam's explicit-over-implicit philosophy.

**See Also**: [Haxe→Elixir Mappings](../02-user-guide/HAXE_ELIXIR_MAPPINGS.md) - Complete mapping reference including Option<T> patterns.

### Why Option<T> Over Nullable Types?

Option<T> eliminates the entire class of null pointer exceptions by making absence explicit:

```haxe
// ❌ Nullable approach - runtime errors possible
function findUser(id: Int): Null<User> {
    // Could return null, requires manual checks everywhere
}

var user = findUser(123);
if (user != null) {  // Easy to forget this check!
    processUser(user);
}

// ✅ Option approach - compile-time safety
import haxe.ds.Option;
using haxe.ds.OptionTools;

function findUser(id: Int): Option<User> {
    var user = Database.query("users", {id: id});
    return user != null ? Some(user) : None;
}

// Compiler forces explicit handling
switch (findUser(123)) {
    case Some(user): processUser(user);  // Type-safe access
    case None: handleNotFound();         // Must handle absence
}
```

### Target-Specific Compilation

Option<T> compiles to **idiomatic patterns** for each target:

**Elixir Output**:
```elixir
# Some(42) compiles to:
{:some, 42}

# None compiles to:
:none

# Pattern matching works naturally:
case find_user(123) do
  {:some, user} -> process_user(user)
  :none -> handle_not_found()
end
```

**JavaScript Output** (for reference):
```javascript
// Some(42) compiles to:
{tag: "some", value: 42}

// None compiles to: 
{tag: "none"}
```

### Functional Operations

Option<T> provides comprehensive monadic operations:

```haxe
import haxe.ds.Option;
using haxe.ds.OptionTools;

class UserService {
    public static function getUserDisplayName(id: Int): String {
        return findUser(id)
            .map(user -> user.displayName)           // Transform if present
            .filter(name -> name.length > 0)         // Filter based on predicate
            .or(() -> findUser(id).map(u -> u.name)) // Fallback to username
            .unwrap("Anonymous User");               // Provide default
    }
    
    // Chain multiple Option operations
    public static function getUserProfile(id: Int): Option<Profile> {
        return findUser(id)
            .then(user -> findProfile(user.profileId))
            .filter(profile -> profile.isPublic);
    }
    
    // Combine multiple Option values
    public static function combineUsers(id1: Int, id2: Int): Option<String> {
        return switch ([findUser(id1), findUser(id2)]) {
            case [Some(user1), Some(user2)]: Some('${user1.name} and ${user2.name}');
            case _: None;
        }
    }
}
```

### Migration from Nullable Types

**Progressive Migration Strategy**:

```haxe
// Phase 1: Maintain Backward Compatibility
class UserService {
    // Legacy method (deprecated)
    @:deprecated("Use findUserSafe instead")
    public static function findUser(id: Int): Null<User> {
        return findUserSafe(id).toNullable();
    }
    
    // New type-safe method
    public static function findUserSafe(id: Int): Option<User> {
        var user = Database.query("users", {id: id});
        return OptionTools.fromNullable(user);
    }
}

// Phase 2: Bridge External APIs
class ExternalAPIWrapper {
    public static function getRemoteUser(id: Int): Option<User> {
        var result = ExternalAPI.fetchUser(id); // Returns Null<User>
        return OptionTools.fromNullable(result);
    }
}
```

## Standard Library Strategy Comparison

| Component | Pattern | Rationale | Benefits | Trade-offs |
|-----------|---------|-----------|----------|------------|
| **StringTools** | Extern + Runtime | Platform-specific optimizations needed | Native performance, idiomatic code | Requires runtime dependency |
| **Result<T,E>** | Pure Haxe | Cross-platform consistency | Zero deps, compile-time optimization | More complex compiler logic |
| **Option<T>** | Pure Haxe | Type safety across targets | Eliminates null errors | Paradigm shift for developers |
| **IO/File** | Extern + Runtime | Platform APIs vary significantly | Direct platform integration | Target-specific implementations |
| **Math** | Mixed | Basic ops pure, advanced ops extern | Best of both approaches | Complexity in deciding boundaries |

### Decision Framework

When adding new standard library components, use this decision tree:

1. **Is it an algebraic data type?** → Pure Haxe (Result, Option, Either)
2. **Does it wrap platform-specific APIs?** → Extern + Runtime (File, Process, IO)
3. **Does it need framework integration?** → Extern + Runtime (Phoenix, Ecto)
4. **Is performance critical with platform differences?** → Extern + Runtime (StringTools, Math)
5. **Is cross-platform consistency the priority?** → Pure Haxe (functional patterns)

### Cross-References

- **[Haxe→Elixir Mappings](../02-user-guide/HAXE_ELIXIR_MAPPINGS.md)** - How Option<T> and Result<T,E> compile to Elixir patterns
- **[Functional Patterns](../07-patterns/FUNCTIONAL_PATTERNS.md)** - Comprehensive usage examples and patterns
- **[ExUnit Testing](../02-user-guide/exunit-testing.md)** - Testing patterns for type-safe code

**Implementation Files**:
- `std/haxe/ds/Option.hx` - Option<T> type definition and tools
- `std/haxe/functional/Result.hx` - Result<T,E> type definition and tools  
- `std/StringTools.hx` - StringTools extern definitions
- `std/elixir/StringTools.ex` - StringTools runtime implementation

# Standard Library Development Context for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions, architecture, and core development principles

## 🔗 Shared AI Context (Import System)

@docs/claude-includes/compiler-principles.md
@docs/claude-includes/testing-commands.md
@docs/claude-includes/code-style.md
@docs/claude-includes/framework-integration.md

This file contains standard library-specific guidance for agents working on Reflaxe.Elixir's standard library modules.

## 📚 Standard Library Architecture Overview

### Directory Structure Philosophy
```
std/
├── ArrayTools.hx          # Core Haxe type extensions
├── StringTools.hx         # Cross-platform string utilities
├── MapTools.hx           # Map/object manipulation tools
├── HXX.hx                # Template system core
├── ecto/                 # Ecto ORM integration
├── elixir/              # Elixir standard library externs
│   └── otp/             # OTP/BEAM abstractions (Application, Supervisor)
├── haxe/                # Haxe standard library extensions
├── phoenix/             # Phoenix framework integration
│   └── types/           # Phoenix-specific type abstractions
├── plug/                # Plug framework types (Conn, etc.)
└── reflaxe/             # Reflaxe framework extensions
```

### Framework Layering Organization ⚡ **NEW**

**CRITICAL PRINCIPLE: Organize types by framework origin, not usage context**

```
┌─ Erlang/OTP (std/elixir/otp/) ────┐
│ • Application.hx                   │  ← Core BEAM/OTP concepts
│ • Supervisor.hx                    │
└────────────────────────────────────┘
           ↑ depends on
┌─ Plug (std/plug/) ────────────────┐
│ • Conn.hx                          │  ← HTTP abstraction layer
└────────────────────────────────────┘
           ↑ depends on
┌─ Phoenix (std/phoenix/types/) ────┐
│ • Socket.hx (LiveView)             │  ← Web framework features
│ • FlashMessage.hx                  │
│ • Assigns.hx                       │
└────────────────────────────────────┘
```

**Import Pattern**:
```haxe
// Framework-specific imports reflect origin
import elixir.otp.Application;     // ✅ OTP concept
import elixir.otp.Supervisor;      // ✅ OTP concept
import plug.Conn;                  // ✅ Plug concept
import phoenix.types.Socket;       // ✅ Phoenix concept
```

**Benefits**:
- **Framework-agnostic code**: OTP types can be used in any Elixir application
- **Clear dependencies**: Lower layers don't depend on higher layers  
- **Logical organization**: Directory structure reflects framework relationships
- **Better reusability**: Each layer provides appropriate abstractions

### ⚡ Dual-API Pattern **CRITICAL PHILOSOPHY**

**Every standard library type MUST provide BOTH cross-platform AND native APIs** - Give developers maximum flexibility:

```haxe
class Date {
    // === Haxe Standard Library API (Cross-Platform) ===
    public function getTime(): Float { }        // Milliseconds since epoch
    public function getMonth(): Int { }         // 0-based (0-11)
    public function toString(): String { }      // Standard format
    public static function now(): Date { }      // Current time
    
    // === Elixir Native API Extensions ===
    public function add(amount: Int, unit: TimeUnit): Date { }      // Elixir-style
    public function diff(other: Date, unit: TimeUnit): Int { }      // Elixir-style
    public function toIso8601(): String { }                         // ISO format
    public function beginningOfDay(): Date { }                      // Phoenix/Timex
    public function compare(other: Date): ComparisonResult { }      // Elixir atoms
    
    // === Conversion Methods ===
    public function toNaiveDateTime(): elixir.NaiveDateTime { }
    public function toElixirDate(): elixir.Date { }
    public static function fromNaiveDateTime(dt: elixir.NaiveDateTime): Date { }
}
```

**Implementation Guidelines**:
1. **Always implement full Haxe interface first** - Ensures cross-platform compatibility
2. **Add native methods as extensions** - Don't break the Haxe contract
3. **Use Haxe naming conventions** - `camelCase` for all methods to maintain consistency
4. **Provide conversion methods** - Seamless interop between type systems
5. **Document both APIs clearly** - Mark cross-platform vs platform-specific
6. **Match Elixir functionality** - Methods should behave like their Elixir counterparts

**Benefits**:
- **Cross-Platform Code**: Write once, run anywhere using Haxe methods
- **Platform Power**: Access full Elixir/BEAM capabilities when needed
- **Gradual Migration**: Teams can migrate from pure Elixir gradually
- **Familiar APIs**: Elixir developers can use methods they know
- **No Compromise**: Full type safety with maximum flexibility

**See**: [`/documentation/COMPILER_BEST_PRACTICES.md`](/documentation/COMPILER_BEST_PRACTICES.md#dual-api-philosophy-for-standard-library) - Complete implementation guidelines

### Core Design Patterns

#### 1. Extern + Runtime Library Pattern
**Best for**: Elixir standard library integration
```haxe
// Define extern interface
@:native("Enum")
extern class ElixirEnum {
    static function map<T,R>(enumerable: Array<T>, func: T -> R): Array<R>;
}

// Provide runtime implementation
// - StringTools.ex (Elixir runtime)
// - StringTools.hx (Haxe interface)
```

#### 2. Pure Haxe + Target Compilation Pattern  
**Best for**: Cross-platform functionality
```haxe
// Result<T,E> compiles to target-specific patterns
// {:ok, value} | {:error, reason} in Elixir
// Right(value) | Left(error) in other targets
abstract Result<T,E> {
    // Pure Haxe implementation
}
```

#### 3. Framework Integration Pattern
**Best for**: Phoenix/Ecto deep integration
```haxe
// phoenix/LiveView.hx
// Provides type-safe Phoenix LiveView API
// with proper Elixir module generation
```

## 🎯 Standard Library Development Rules ⚠️ CRITICAL

### ❌ NEVER Do This:
- **Create Std.hx, Log.hx or other core Haxe classes in std/** - These are handled by the compiler
- Define test infrastructure types in application code
- Create duplicated functionality across different std modules
- Use Dynamic for standard library APIs
- Implement escape hatches in standard library
- Break type safety for convenience

### ⚠️ CRITICAL: Core Haxe Classes Rule
**NEVER create these files in std/ directory:**
- `Std.hx` - Core Haxe class handled by compiler
- `Log.hx` - Trace/logging handled by compiler transformation
- `Math.hx` - Core math functions handled by compiler
- Any other core Haxe standard library class

**How Core Classes Are Actually Generated:**

The compiler automatically generates runtime support modules from different sources:

1. **`Std` module** → Generated from `/std/Std.cross.hx`
   - Our custom implementation with Elixir-specific optimizations
   - Compiles to `std.ex` with methods like `string()`, `int()`, `parseFloat()`
   - Uses `untyped __elixir__()` for native Elixir implementations
   - Located at: `/Users/fullofcaffeine/workspace/code/haxe.elixir/std/Std.cross.hx`

2. **`Log` module** → Generated from Haxe's standard library
   - Source: `/Users/fullofcaffeine/haxe/versions/4.3.7/std/haxe/Log.hx`
   - Generates `haxe/log.ex` containing the Log module
   - When you call `trace("hello")` in Haxe, the compiler transforms it to `Log.trace("hello", metadata)`
   - The Log.hx class defines the `trace()` and `formatOutput()` methods that handle the actual output
   - Part of official Haxe distribution (haxe.Log package)

3. **How the Compiler Knows to Use Log.trace()**:
   - Haxe has a built-in `trace()` function that's part of the language
   - The Haxe compiler (not our Reflaxe compiler) transforms `trace()` calls into calls to `haxe.Log.trace()`
   - Our Reflaxe.Elixir compiler sees these as static method calls to the Log class
   - It then compiles the haxe/Log.hx file to generate the Log module in Elixir

4. **Dependency Tracking**:
   - `ElixirASTBuilder.trackDependency()` tracks which modules are used
   - `ElixirCompiler.moduleDependencies` maintains the dependency graph
   - The compiler generates only the modules that are actually referenced

**Example Generated Structure:**
```
out/
├── main.ex           # Your compiled code
├── std.ex            # From std/Std.cross.hx (our custom implementation)
├── haxe/
│   └── log.ex        # From Haxe stdlib's haxe/Log.hx
└── map_tools.ex      # From std/MapTools.cross.hx (if used)
```

**Cross-Platform Files (.cross.hx)**:
- Use `.cross.hx` extension for cross-platform utility classes
- Examples: `MapTools.cross.hx`, `Std.cross.hx`
- These override or extend Haxe's default implementations
- Provide Elixir-specific optimizations using `__elixir__()`

**Instead of Creating Core Classes in std/**:
- Never create `Log.hx` - it comes from Haxe's standard library
- Use `Std.cross.hx` for custom Std implementation (already exists)
- The compiler automatically handles the compilation and inclusion

### ✅ ALWAYS Do This:
- Define test types in `/std/phoenix/test/` and `/std/ecto/test/`
- Use proper type annotations throughout
- Follow the "Extern + Runtime" or "Pure Haxe" patterns consistently
- Provide comprehensive documentation with examples
- Maintain cross-platform compatibility where possible

## 📁 Module Organization Guidelines

### Test Infrastructure Location
**CRITICAL**: Test types belong in standard library, not application code
```haxe
// ✅ CORRECT: Standard library test types
import phoenix.test.Conn;
import ecto.test.Sandbox;
import haxe.test.ExUnit;

// ❌ WRONG: Application-defined test types
typedef Conn = Dynamic;
```

### Namespace Conventions
- **elixir/**: Direct Elixir standard library externs
- **haxe/**: Extended Haxe functionality (Option, Result, validation)
- **phoenix/**: Phoenix framework integration
- **ecto/**: Ecto ORM integration
- **reflaxe/**: Reflaxe framework-specific extensions

### File Naming Patterns
- **CamelCase.hx**: Main module files (StringTools.hx)
- **test/**: Test utilities and infrastructure
- **types/**: Type definitions and abstracts

## 🔧 Extern Definition Best Practices

### Type-Safe Extern Pattern
```haxe
@:native("ModuleName")
extern class ExternModule {
    // 1. Use proper Haxe types, not Dynamic
    static function operation<T>(input: T): Result<T, String>;
    
    // 2. Include helper functions for common patterns
    @:overload(function(items: Array<T>): Array<T> {})
    static function filter<T>(items: Array<T>, pred: T -> Bool): Array<T>;
    
    // 3. Document complex APIs
    /**
     * Performs operation with detailed behavior explanation.
     * @param input The input value of type T
     * @return Result containing success value or error string
     */
    static function complexOperation<T>(input: T): Result<T, String>;
}
```

### Runtime Implementation Pattern
```elixir
# StringTools.ex - Elixir runtime implementation
defmodule StringTools do
  def kebab_case(str) when is_binary(str) do
    # Idiomatic Elixir implementation
    str
    |> String.replace(~r/([a-z])([A-Z])/, "\\1-\\2")
    |> String.downcase()
  end
end
```

## 🎨 Type System Integration

### Abstract Types for Safety
```haxe
// haxe/validation/Email.hx - Type-safe email validation
abstract Email(String) from String {
    public function new(email: String) {
        if (!isValid(email)) {
            throw 'Invalid email: $email';
        }
        this = email;
    }
    
    private static function isValid(email: String): Bool {
        // Validation logic
        return ~/^[^\s@]+@[^\s@]+\.[^\s@]+$/.match(email);
    }
}
```

### Option/Result Functional Patterns
```haxe
// haxe/ds/Option.hx - Functional null handling
enum Option<T> {
    Some(value: T);
    None;
}

// haxe/functional/Result.hx - Functional error handling  
enum Result<T,E> {
    Ok(value: T);
    Error(error: E);
}
```

## 🧪 Testing Patterns for Standard Library

### Test Infrastructure Architecture
```haxe
// haxe/test/ExUnit.hx - ExUnit integration
extern class ExUnit {
    static function start(): Void;
    static function configure(options: Dynamic): Void;
}

// phoenix/test/ConnCase.hx - Phoenix test patterns
extern class ConnCase {
    static function build_conn(): Conn;
    static function get(conn: Conn, path: String): Conn;
}
```

### Standard Library Test Structure
- **Unit Tests**: Test individual module functionality
- **Integration Tests**: Test cross-module interaction
- **Phoenix Integration**: Test framework compatibility
- **Type Safety**: Validate type system guarantees

## 📊 Performance Considerations

### Compilation Performance
- **Extern Pattern**: Fastest compilation, delegates to native runtime
- **Pure Haxe Pattern**: Moderate compilation, maximum type safety
- **Hybrid Pattern**: Balance of safety and performance

### Runtime Performance  
- **Elixir Externs**: Native performance, idiomatic patterns
- **Compiled Haxe**: Comparable performance with type safety
- **Avoid**: Dynamic types and reflection in hot paths

## 🎯 Framework Integration Guidelines

### Phoenix Integration Standards
```haxe
// phoenix/LiveView.hx - Type-safe LiveView API
extern class LiveView {
    static function assign<T>(socket: Socket, assigns: T): Socket;
    static function push_event(socket: Socket, event: String, payload: Dynamic): Socket;
}

// phoenix/types/Assigns.hx - Type-safe assigns
abstract Assigns<T>(Dynamic) {
    @:arrayAccess
    public function get(key: String): Dynamic;
    
    @:arrayAccess  
    public function set(key: String, value: Dynamic): Dynamic;
}
```

### Ecto Integration Standards
```haxe
// ecto/Changeset.hx - Type-safe changesets
extern class Changeset<T> {
    static function cast<T>(data: T, params: Dynamic, permitted: Array<String>): Changeset<T>;
    static function validate_required<T>(changeset: Changeset<T>, fields: Array<String>): Changeset<T>;
}
```

## 🔍 Quality Standards for Standard Library

### Type Safety Requirements
- **100% typed APIs**: No Dynamic in public interfaces except for framework compatibility
- **Null safety**: Use Option<T> for optional values
- **Error handling**: Use Result<T,E> for fallible operations
- **Validation**: Abstract types for constrained values

### Documentation Requirements
```haxe
/**
 * Brief description of the module functionality.
 * 
 * Detailed explanation including:
 * - What the module provides
 * - How it integrates with Elixir/Phoenix  
 * - Usage patterns and examples
 * - Performance characteristics
 * 
 * @see RelatedModule or documentation/FILE.md for related information
 */
class StandardLibraryModule {
    /**
     * Brief description of the method functionality.
     * 
     * @param paramName Description with type information
     * @return Description with null/error conditions
     */
    public static function operation(): ReturnType;
}
```

### ⚠️ CRITICAL RULE: Type Documentation Standards (Complexity-Scaled)

**Documentation depth MUST match type complexity:**

#### **Simple Types** (minimal docs needed):
- Basic typedefs: Brief description + field meanings
- Simple enums: One-line descriptions per variant
- Wrapper abstracts: Purpose + basic usage

#### **Complex/Generic Types** (comprehensive docs required):
- Generic types (`Socket<T>`, `Result<T,E>`): Full documentation
- Framework integration types: Usage patterns + type safety benefits
- Multi-variant enums with data: Complete examples

#### **Required Elements for Complex Types**:
1. **Generic Parameters**: What `<T>` represents and type constraints
2. **Usage Patterns**: Complete code examples showing generic usage  
3. **Type Safety Benefits**: What compile-time guarantees the generics provide
4. **Framework Integration**: How generics compile to target framework patterns

**Example Required Documentation Pattern**:
```haxe
/**
 * Type description with full type safety
 * 
 * @param T The specific type this generic represents (e.g., "socket assigns structure")
 * 
 * ## Generic Usage Pattern
 * 
 * Define your specific type:
 * ```haxe
 * typedef MySpecificType = { var field: String; }
 * ```
 * 
 * Use with generics:
 * ```haxe
 * function myFunction(input: GenericType<MySpecificType>): Result<MySpecificType> {
 *     // Implementation with full type safety
 * }
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Benefit 1**: Specific compile-time guarantee
 * - **Benefit 2**: IntelliSense and refactoring support
 * - **Benefit 3**: Framework compatibility details
 */
enum GenericType<T> {
    // Variants with detailed documentation
}
```

**Why This Matters**: Generic types are complex. Without comprehensive documentation, developers cannot understand how to use them correctly, defeating the purpose of type safety.
```

### Testing Requirements
- **Test Coverage**: All public APIs must have test coverage
- **Type Validation**: Test type safety guarantees  
- **Framework Integration**: Test Phoenix/Ecto compatibility
- **Error Scenarios**: Test error handling and validation

## 🎨 Code Generation Patterns

### Idiomatic Elixir Output
Standard library modules should generate idiomatic Elixir that follows BEAM conventions:
```elixir
# ✅ GOOD: Generated from Option<T>
case some_operation() do
  {:some, value} -> value
  :none -> default_value
end

# ✅ GOOD: Generated from Result<T,E>  
case dangerous_operation() do
  {:ok, result} -> handle_success(result)
  {:error, reason} -> handle_error(reason)
end
```

### Cross-Platform Compatibility
```haxe
// Compile to different patterns per target
#if elixir
    {:ok, value} | {:error, reason}
#elseif js
    Promise.resolve(value) | Promise.reject(reason)  
#elseif java
    Optional.of(value) | Optional.empty()
#end
```

## 📚 Related Documentation

### Core References
- [`/documentation/STANDARD_LIBRARY_HANDLING.md`](/documentation/STANDARD_LIBRARY_HANDLING.md) - Complete standard library strategy
- [`/documentation/FUNCTIONAL_PATTERNS.md`](/documentation/FUNCTIONAL_PATTERNS.md) - Option/Result functional patterns
- [`/documentation/STRINGTOOLS_STRATEGY.md`](/documentation/STRINGTOOLS_STRATEGY.md) - Extern + Runtime pattern example

### Framework Integration
- [`/documentation/PHOENIX_INTEGRATION.md`](/documentation/PHOENIX_INTEGRATION.md) - Phoenix framework patterns
- [`/documentation/ECTO_INTEGRATION.md`](/documentation/ECTO_INTEGRATION.md) - Ecto ORM integration
- [`/documentation/HXX_VS_TEMPLATE.md`](/documentation/HXX_VS_TEMPLATE.md) - Template system architecture

### Development Guides
- [`/documentation/guides/DEVELOPER_PATTERNS.md`](/documentation/guides/DEVELOPER_PATTERNS.md) - Best practices
- [`/documentation/TESTING_PRINCIPLES.md`](/documentation/TESTING_PRINCIPLES.md) - Testing methodology
- [`/documentation/TYPE_SAFETY.md`](/documentation/TYPE_SAFETY.md) - Type system guidelines

### Code Injection and Architecture
- [`/documentation/ELIXIR_INJECTION_GUIDE.md`](/documentation/ELIXIR_INJECTION_GUIDE.md) - **CRITICAL**: Complete `__elixir__()` usage guide
- [`/documentation/CRITICAL_ARCHITECTURE_LESSONS.md`](/documentation/CRITICAL_ARCHITECTURE_LESSONS.md) - **MANDATORY**: Idiomatic code generation principles
- [`/documentation/STANDARD_LIBRARY_COMPILATION_CONTEXT.md`](/documentation/STANDARD_LIBRARY_COMPILATION_CONTEXT.md) - Why `untyped` is required for `__elixir__()`

## 🏆 Standard Library Quality Checklist

Before adding any standard library module, verify:

### Type Safety ✓
- [ ] All public APIs properly typed (no Dynamic unless required)
- [ ] Optional values use Option<T> pattern
- [ ] Error handling uses Result<T,E> pattern  
- [ ] Validation types use abstract pattern
- [ ] Test infrastructure properly typed

### Framework Integration ✓
- [ ] Phoenix/Ecto compatibility verified
- [ ] Generates idiomatic Elixir code
- [ ] Follows BEAM conventions
- [ ] Performance characteristics documented
- [ ] Cross-platform patterns considered

### Documentation ✓
- [ ] Comprehensive JavaDoc-style documentation
- [ ] Usage examples provided
- [ ] Performance characteristics explained
- [ ] Cross-references to related modules
- [ ] Integration patterns documented

### Testing ✓
- [ ] Unit tests for all public APIs
- [ ] Integration tests with framework
- [ ] Type safety validation
- [ ] Error scenario coverage
- [ ] Performance regression tests

**Remember**: The standard library is the foundation of type safety for all applications. Every module must meet the highest quality standards and provide exemplary patterns for application developers.
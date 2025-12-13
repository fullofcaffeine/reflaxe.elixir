# Standard Library Development Context for Reflaxe.Elixir

> **⚠️ SYNC DIRECTIVE**: This file (`AGENTS.md`) and `CLAUDE.md` in the same directory must be kept in sync. When updating either file, update the other as well.

> **Parent Context**: See [/AGENTS.md](/AGENTS.md) for project-wide conventions, architecture, and core development principles

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

**See**: [`/docs/03-compiler-development/COMPILER_BEST_PRACTICES.md`](/docs/03-compiler-development/COMPILER_BEST_PRACTICES.md#dual-api-philosophy-for-standard-library) - Complete implementation guidelines

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

## ⚠️ CRITICAL: Architectural Hierarchy - .cross.hx → Externs → Transformations

**FUNDAMENTAL PRINCIPLE: Generate idiomatic code at the EARLIEST possible stage in the compilation pipeline.**

### The Three-Layer Architecture (In Priority Order)

#### 1. **FIRST CHOICE: .cross.hx Override Files (Compile-Time Generation)**

**When to Use**: When you control the type definition and need idiomatic output
**How it Works**: Replaces Haxe's standard implementation entirely
**Advantages**:
- Zero runtime overhead with `extern inline`
- Generates perfect Elixir code from the start
- Type checking happens at Haxe compile time
- No AST manipulation needed
- Cleanest generated code

**Example**:
```haxe
// String.cross.hx - Replaces ALL String methods
extern inline function toUpperCase(): String {
    return untyped __elixir__('String.upcase({0})', this);
}
// Generates: String.upcase(str) instead of str.to_upper_case()
```

**Best For**:
- Core types (String, Array, Map)
- Standard library utilities (StringTools, Lambda)
- Mathematical operations (Math)
- Any type where you want COMPLETE control over generation

#### 2. **SECOND CHOICE: Extern Classes with Native Mapping**

**When to Use**: Wrapping existing Elixir/Erlang/Phoenix/Ecto modules
**How it Works**: Maps Haxe types to existing Elixir modules
**Advantages**:
- Direct access to ecosystem libraries
- Type-safe wrappers around dynamic APIs
- No runtime overhead
- Preserves library semantics exactly

**Example**:
```haxe
// Phoenix.LiveView extern
@:native("Phoenix.LiveView")
extern class LiveView {
    @:native("assign")
    static function assign<T>(socket: Socket<T>, key: String, value: Dynamic): Socket<T>;
}
// Generates: Phoenix.LiveView.assign(socket, key, value)
```

**Best For**:
- Framework integration (Phoenix, Ecto)
- Erlang/OTP modules
- Third-party libraries
- When you DON'T control the implementation

#### 3. **LAST RESORT: AST Transformation Passes**

**When to Use**: Only for context-dependent patterns that can't be known at definition time
**How it Works**: Post-processes generated AST to fix patterns
**Disadvantages**:
- Performance overhead during compilation
- Complexity in compiler
- Harder to debug
- Can miss edge cases
- Order-dependent transformations

**Legitimate Use Cases**:
```haxe
// Pattern: Immutable array operations
arr.push(item) → arr = arr ++ [item]
// This REQUIRES context analysis - is 'arr' a local var or struct field?

// Pattern: Loop to comprehension conversion
for (i in 0...10) { result.push(i * 2); }
→ result = for i <- 0..9, do: i * 2
// Requires analyzing entire loop body structure
```

**Should Be Transformation**:
- Immutability transformations (needs usage context)
- Loop optimizations (needs pattern analysis)
- Dead code elimination (needs flow analysis)
- Operator overloading resolution (needs type context)

### Why This Hierarchy Matters

#### Compilation Pipeline Stages:
```
1. Haxe Parsing
2. Type Checking
3. .cross.hx Override ← EARLIEST INTERVENTION (Best)
4. Macro Expansion
5. TypedExpr Generation
6. ElixirASTBuilder
7. AST Transformations ← LATEST INTERVENTION (Worst)
8. Code Printing
```

#### Performance Impact:
- **.cross.hx**: ~0ms overhead (compile-time inline)
- **Externs**: ~0ms overhead (direct mapping)
- **Transformations**: 10-100ms per pass (AST traversal + pattern matching)

#### Code Quality Impact:
- **.cross.hx**: Perfect idiomatic code
- **Externs**: Native library calls
- **Transformations**: Risk of edge cases, ordering issues

### Decision Tree for Implementation Strategy

```
Need to change how a type generates code?
├─ Do you control the type definition?
│  ├─ YES → Use .cross.hx override
│  └─ NO → Is it an external library?
│     ├─ YES → Use extern with @:native
│     └─ NO → Is it context-dependent?
│        ├─ YES → Use AST transformation (last resort)
│        └─ NO → Reconsider - probably needs .cross.hx
```

### Real-World Example: String Methods Problem

**The Problem**: `str.length` generates as method call, invalid in Elixir

**❌ Wrong Solution (What we initially tried)**:
```haxe
// AST Transformation to detect and fix method calls
case ECall(target, "length", []):
    makeAST(ERemoteCall(makeAST(EVar("String")), "length", [target]))
```
Problems: Complexity, missed edge cases, runs on EVERY compilation

**✅ Right Solution (Using .cross.hx)**:
```haxe
// String.cross.hx
@:coreApi
extern class String {
    extern inline var length(get, never): Int;
    extern inline function get_length(): Int {
        return untyped __elixir__('String.length({0})', this);
    }
}
```
Benefits: Zero overhead, always correct, generates `String.length(str)` directly

### Lessons from Other Reflaxe Compilers

**Reflaxe.CPP**: Uses extensive .cross.hx overrides for entire stdlib
**Reflaxe.CS**: Minimal transformations, mostly externs
**Reflaxe.Py**: Heavy transformation use (and it's their biggest pain point)

The most successful Reflaxe compilers minimize AST transformations.

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

2. **`Log` module** → Generated from our override `/std/haxe/Log.cross.hx`
   - **OVERRIDE PATTERN**: We use `.cross.hx` files to override Haxe's standard library behavior
   - Our Log.cross.hx implementation generates idiomatic `IO.inspect()` calls instead of `Log.trace()`
   - When you call `trace("hello")` in Haxe, it becomes `IO.inspect("hello")` in Elixir
   - The override uses `untyped __elixir__()` to generate native Elixir code
   - This produces cleaner, more idiomatic Elixir output for better debugging experience

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

### ⚠️ CRITICAL: Generic Type Parameters for Phoenix.Presence - NO DYNAMIC!

**ARCHITECTURAL SOLUTION: The PresenceMacro uses generic type parameters <T, M> for complete type safety.**

**How Generic Types Solve the Multiple Socket Problem:**
1. **Generic Parameter T Handles All Socket Types**: 
   - `phoenix.Socket` (client-side WebSocket, non-generic) ✅
   - `Phoenix.Socket<T>` (server-side LiveView, generic) ✅
   - Custom socket types (user-defined) ✅
   - ALL work with the same generic parameter

2. **Macro Generates Type-Safe Universal Code**:
   - Methods use `<T, M>` generic parameters at compile-time
   - Type `T` accepts ANY socket type when methods are called
   - Type `M` accepts ANY metadata structure
   - Zero Dynamic usage - complete type safety

3. **extern inline for Zero-Cost Abstraction**:
   - Methods marked `extern inline` are resolved at compile-time
   - No runtime overhead - code is inlined at call sites
   - Type checking happens during compilation
   - Clean, idiomatic Elixir output

4. **Complete Type Safety Throughout**:
   - Socket type preserved: `trackInternal<T, M>(socket: T, ...): T`
   - Metadata fully typed: `meta: M` instead of `meta: Dynamic`
   - Return types match input types exactly
   - Full IDE support with IntelliSense and refactoring

**Example Generated Method:**
```haxe
extern inline public static function trackInternal<T, M>(
    socket: T,      // ANY socket type works
    key: String, 
    meta: M         // ANY metadata type works  
): T {              // Returns SAME socket type
    return untyped __elixir__('track({0}, {1}, {2}, {3})', 
        untyped __elixir__('self()'), socket, key, meta);
}
```

**This is the CORRECT pattern - generic types provide universal compatibility WITH type safety.**

See: `std/phoenix/macros/PresenceMacro.hx` for complete implementation

### ⚠️ CRITICAL: @:native Annotation Pattern for Extern Classes

**FUNDAMENTAL RULE: When an extern class has `@:native("Module.Name")` at the class level, method-level `@:native` annotations should ONLY contain the method name, not the full module path.**

**Why This Matters**: Haxe combines the class-level and method-level @:native annotations. If both contain the full module path, you get malformed output like `Phoenix.Presence.phoenix._presence.track`.

```haxe
// ✅ CORRECT: Class has module, methods have only method names
@:native("Phoenix.Presence")
extern class Presence {
    @:native("track")  // Just the method name!
    static function track(socket: Dynamic, key: String, meta: Dynamic): Dynamic;
    
    @:native("list")   // Just the method name!
    static function list(topic: String): Dynamic;
}

// ❌ WRONG: Duplicating the module path in method annotations
@:native("Phoenix.Presence")
extern class Presence {
    @:native("Phoenix.Presence.track")  // WRONG! Creates malformed output
    static function track(socket: Dynamic, key: String, meta: Dynamic): Dynamic;
}
```

**Lesson Learned (September 2025)**: Fixed Phoenix.Presence extern where methods incorrectly had full module paths in their @:native annotations, causing compilation errors in modules that used Phoenix.Presence.

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
 * @see RelatedModule or docs/FILE.md for related information
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
- [`/docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md`](/docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md) - Complete standard library strategy
- [`/docs/07-patterns/FUNCTIONAL_PATTERNS.md`](/docs/07-patterns/FUNCTIONAL_PATTERNS.md) - Option/Result functional patterns
- [`/docs/04-api-reference/STRINGTOOLS_STRATEGY.md`](/docs/04-api-reference/STRINGTOOLS_STRATEGY.md) - Extern + Runtime pattern example

### Framework Integration
- [`/docs/02-user-guide/PHOENIX_INTEGRATION.md`](/docs/02-user-guide/PHOENIX_INTEGRATION.md) - Phoenix framework patterns
- [`/docs/02-user-guide/ECTO_INTEGRATION_PATTERNS.md`](/docs/02-user-guide/ECTO_INTEGRATION_PATTERNS.md) - Ecto ORM integration
- [`/docs/02-user-guide/HXX_VS_TEMPLATE.md`](/docs/02-user-guide/HXX_VS_TEMPLATE.md) - Template system architecture

### Development Guides
- [`/docs/06-guides/DEVELOPER_PATTERNS.md`](/docs/06-guides/DEVELOPER_PATTERNS.md) - Best practices
- [`/docs/03-compiler-development/TESTING_PRINCIPLES.md`](/docs/03-compiler-development/TESTING_PRINCIPLES.md) - Testing methodology
- [`/docs/03-compiler-development/TYPE_SAFETY_REQUIREMENTS.md`](/docs/03-compiler-development/TYPE_SAFETY_REQUIREMENTS.md) - Type system guidelines

### Code Injection and Architecture
- [`/docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md`](/docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md) - **CRITICAL**: Complete `__elixir__()` usage guide
- [`/docs/05-architecture/CRITICAL_ARCHITECTURE_LESSONS.md`](/docs/05-architecture/CRITICAL_ARCHITECTURE_LESSONS.md) - **MANDATORY**: Idiomatic code generation principles
- [`/docs/05-architecture/STANDARD_LIBRARY_COMPILATION_CONTEXT.md`](/docs/05-architecture/STANDARD_LIBRARY_COMPILATION_CONTEXT.md) - Why `untyped` is required for `__elixir__()`

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

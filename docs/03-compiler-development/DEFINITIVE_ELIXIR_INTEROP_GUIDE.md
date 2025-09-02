# The Definitive Guide to Elixir API Interfacing in Reflaxe.Elixir

## Purpose

This is THE authoritative guide for interfacing with Elixir/BEAM APIs from Haxe code. It covers every method, pattern, and scenario you'll encounter when bridging Haxe's type system with Elixir's runtime.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [The Complete Tool Arsenal](#the-complete-tool-arsenal)
3. [Decision Framework](#decision-framework)
4. [Pattern Catalog](#pattern-catalog)
5. [Advanced Scenarios](#advanced-scenarios)
6. [Performance Considerations](#performance-considerations)
7. [Debugging Guide](#debugging-guide)
8. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

## Core Concepts

### The Fundamental Challenge

Haxe and Elixir operate at different levels:
- **Haxe**: Compile-time type safety, object-oriented + functional
- **Elixir**: Runtime dynamism, functional, actor-based
- **The Bridge**: Reflaxe.Elixir translates between these worlds

### The Compilation Pipeline

```
Haxe Source → Parse → Type → Reflaxe Init → Transform → Elixir Output
     ↑           ↑        ↑         ↑            ↑           ↑
   .hx files   AST    Typed AST  __elixir__  Compiler    .ex files
                                  injected    runs here
```

## The Complete Tool Arsenal

### 1. Code Injection: `untyped __elixir__()`

**Purpose**: Direct Elixir code injection with parameter substitution

```haxe
// Basic injection
untyped __elixir__('IO.puts({0})', message);

// Multi-line injection
untyped __elixir__('
    case {0} do
        {:ok, value} -> value
        {:error, _} -> {1}
    end
', result, defaultValue);
```

**When to use**:
- Need exact Elixir syntax
- Working with Elixir-specific patterns
- Performance-critical paths

**Constraints**:
- Abstract types need `extern inline`
- Not available during macro expansion
- Must use `{N}` placeholders, not `$variable`

### 2. Native Metadata: `@:native`

**Purpose**: Map Haxe names to Elixir module/function names

```haxe
// Module mapping
@:native("Phoenix.LiveView")
extern class LiveView {
    // Function mapping
    @:native("assign")
    static function assign<T>(socket: Socket<T>, key: String, value: Dynamic): Socket<T>;
    
    // Direct name (no @:native needed if names match)
    static function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic;
}
```

**When to use**:
- Mapping to existing Elixir modules
- No implementation needed
- Want IDE autocomplete

### 3. Extern Classes

**Purpose**: Define contracts for external Elixir modules

```haxe
// Pure extern - no implementation
extern class ElixirModule {
    static function someFunction(): String;
}

// Extern with inline implementation
extern class Utils {
    extern inline static function atomize(s: String): Dynamic {
        return untyped __elixir__('String.to_atom({0})', s);
    }
}
```

**When to use**:
- Interfacing with Elixir stdlib
- Third-party libraries
- OTP behaviors

### 4. Abstract Types

**Purpose**: Type-safe wrappers around dynamic Elixir values

```haxe
// Wrapping dynamic Elixir data
abstract Pid(Dynamic) from Dynamic to Dynamic {
    extern inline public function send(message: Dynamic): Dynamic {
        return untyped __elixir__('send({0}, {1})', this, message);
    }
    
    extern inline public function isAlive(): Bool {
        return untyped __elixir__('Process.alive?({0})', this);
    }
}
```

**Critical Rule**: MUST use `extern inline` for methods with `__elixir__`!

### 5. Metadata-Driven Generation

**Purpose**: Use metadata to control code generation

```haxe
@:struct  // Generate defstruct
class User {
    public var name: String;
    public var age: Int;
}

@:behaviour("GenServer")  // Implement OTP behavior
class MyServer {
    public function init(args: Dynamic): Dynamic { ... }
    public function handle_call(request: Dynamic, from: Dynamic, state: Dynamic): Dynamic { ... }
}
```

### 6. Compile-Time Macros

**Purpose**: Generate code at compile-time based on Elixir patterns

```haxe
@:build(ElixirMacro.buildFromSpec("priv/api_spec.json"))
class ApiClient {}

// Macro generates typed methods from OpenAPI spec
```

## Decision Framework

### Choosing the Right Tool

```mermaid
graph TD
    Start[Need Elixir interop?] --> Q1{Existing module?}
    Q1 -->|Yes| Q2{Need implementation?}
    Q1 -->|No| Create[Create in Haxe]
    
    Q2 -->|No| Extern[@:native extern]
    Q2 -->|Yes| Q3{Complex patterns?}
    
    Q3 -->|Yes| Injection[__elixir__ injection]
    Q3 -->|No| Q4{Type safety needed?}
    
    Q4 -->|Yes| Abstract[Abstract type wrapper]
    Q4 -->|No| Dynamic[Dynamic with Reflect]
```

## Pattern Catalog

### Pattern 1: Wrapping Elixir Modules

```haxe
// Step 1: Define extern
@:native("Ecto.Repo")
extern class EctoRepo {
    @:native("get")
    static function get<T>(repo: Dynamic, schema: Class<T>, id: Int): Null<T>;
}

// Step 2: Create type-safe wrapper
class Repo {
    public static function find<T>(schema: Class<T>, id: Int): Null<T> {
        return EctoRepo.get(untyped __MODULE__, schema, id);
    }
}
```

### Pattern 2: OTP Behavior Implementation

```haxe
@:behaviour("GenServer")
class Counter {
    // Required callbacks with exact signatures
    public function init(args: Dynamic): {String, Int} {
        return untyped __elixir__('{"ok", 0}');
    }
    
    public function handle_call(request: Dynamic, from: Dynamic, state: Int): Dynamic {
        return switch request {
            case "get": untyped __elixir__('{"reply", {0}, {0}}', state);
            case "increment": untyped __elixir__('{"reply", "ok", {0}}', state + 1);
            default: untyped __elixir__('{"reply", "error", {0}}', state);
        }
    }
}
```

### Pattern 3: Phoenix LiveView Integration

```haxe
@:liveview
class TodoLive {
    // Type-safe assigns
    typedef Assigns = {
        todos: Array<Todo>,
        editing: Null<Todo>
    }
    
    public function mount(params: Dynamic, session: Dynamic, socket: LiveSocket<Assigns>): LiveSocket<Assigns> {
        return socket
            .assign(_.todos, TodoContext.list_todos())
            .assign(_.editing, null);
    }
    
    public function handle_event(event: String, params: Dynamic, socket: LiveSocket<Assigns>): LiveSocket<Assigns> {
        return switch event {
            case "add_todo": 
                var todo = TodoContext.create_todo(params);
                socket.update(_.todos, todos -> todos.concat([todo]));
            case "edit_todo":
                var id = Reflect.field(params, "id");
                var todo = todos.find(t -> t.id == id);
                socket.assign(_.editing, todo);
            default: 
                socket;
        }
    }
}
```

### Pattern 4: Working with Processes

```haxe
abstract Process(Dynamic) {
    extern inline public static function spawn(fun: Void -> Void): Process {
        return untyped __elixir__('spawn({0})', fun);
    }
    
    extern inline public function send<T>(message: T): T {
        return untyped __elixir__('send({0}, {1})', this, message);
    }
    
    extern inline public function isAlive(): Bool {
        return untyped __elixir__('Process.alive?({0})', this);
    }
}
```

### Pattern 5: Ecto Schema & Changeset

```haxe
@:schema
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var age: Int;
    
    @:changeset
    public function changeset(user: User, attrs: Dynamic): Changeset<User> {
        return cast(user, attrs, ["name", "email", "age"])
            .validateRequired(["name", "email"])
            .validateFormat("email", ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
            .validateNumber("age", {greater_than: 0, less_than: 150});
    }
}
```

## Advanced Scenarios

### Scenario 1: Interfacing with NIFs

```haxe
@:native("NifModule")
extern class NifModule {
    @:native("fast_operation")
    static function fastOperation(data: haxe.io.Bytes): haxe.io.Bytes;
}

// Safe wrapper
class NifWrapper {
    public static function process(data: haxe.io.Bytes): Null<haxe.io.Bytes> {
        try {
            return NifModule.fastOperation(data);
        } catch (e: Dynamic) {
            trace('NIF error: $e');
            return null;
        }
    }
}
```

### Scenario 2: Dynamic Supervisor Children

```haxe
class DynamicSupervisor {
    extern inline public static function startChild(spec: ChildSpec): Dynamic {
        return untyped __elixir__('
            DynamicSupervisor.start_child(__MODULE__, {0})
        ', spec);
    }
}
```

### Scenario 3: Macro-Generated Interop

```haxe
// Generate from Elixir module introspection
@:autoBuild(ElixirModuleMacro.buildFrom("ElixirModuleName"))
class GeneratedWrapper {}
```

## Performance Considerations

### Direct vs Wrapped Calls

```haxe
// FAST: Direct injection (zero overhead)
untyped __elixir__('Enum.map({0}, {1})', list, fun);

// SLOWER: Multiple wrapping layers
ElixirEnum.map(list, fun);  // Extern call
EnumWrapper.map(list, fun);  // Another layer
```

### Inline Everything Critical

```haxe
// Always inline hot paths
abstract FastOps(Dynamic) {
    extern inline public function quickOp(): Dynamic {
        return untyped __elixir__('fast_elixir_op({0})', this);
    }
}
```

## Debugging Guide

### Problem: "Unknown identifier: __elixir__"

**Diagnosis**: Code being typed before Reflaxe initialization

**Solutions**:
1. For abstracts: Add `extern inline`
2. For classes: Remove `inline` or add conditional compilation
3. Check compilation order

### Problem: "Field index not found on prototype"

**Diagnosis**: Trying to use @:native with eval target

**Solution**: Use __elixir__ injection instead of direct extern calls

### Problem: Generated code has wrong function names

**Diagnosis**: Missing or incorrect @:native metadata

**Solution**: Add explicit @:native("correct_name") annotations

## Anti-Patterns to Avoid

### ❌ Don't: Mix injection styles

```haxe
// BAD: Inconsistent
class BadExample {
    function method1() { return untyped __elixir__(...); }
    @:native("method2") function method2(): Dynamic;
}
```

### ❌ Don't: Overuse Dynamic

```haxe
// BAD: No type safety
function process(data: Dynamic): Dynamic {
    return untyped __elixir__('process({0})', data);
}

// GOOD: Typed interfaces
function process<T>(data: T): Result<T, String> {
    return untyped __elixir__('process({0})', data);
}
```

### ❌ Don't: Forget extern inline for abstracts

```haxe
// WILL FAIL
abstract Bad(Dynamic) {
    public function method() {  // Missing extern inline!
        return untyped __elixir__(...);
    }
}
```

## Quick Reference Card

| Scenario | Tool | Example |
|----------|------|---------|
| Call Elixir function | `__elixir__` | `untyped __elixir__('Module.fun({0})', arg)` |
| Map to Elixir module | `@:native` | `@:native("Elixir.Module")` |
| Wrap dynamic value | Abstract | `abstract Pid(Dynamic)` |
| Implement behavior | `@:behaviour` | `@:behaviour("GenServer")` |
| Generate structure | `@:struct` | `@:struct class MyStruct` |
| Inline implementation | `extern inline` | `extern inline function f()` |
| Pure extern | extern class | `extern class Module` |

## Conclusion

This guide represents the complete knowledge for interfacing with Elixir APIs from Haxe. The key insights:

1. **Choose the right tool**: Each approach has specific use cases
2. **Abstract types need special handling**: Always use `extern inline` with `__elixir__`
3. **Performance matters**: Prefer direct injection for hot paths
4. **Type safety is paramount**: Wrap Dynamic values in typed abstractions

When in doubt, refer to this guide's decision framework and pattern catalog.

## Related Resources

- [`ELIXIR_INJECTION_COMPLETE_GUIDE.md`](ELIXIR_INJECTION_COMPLETE_GUIDE.md) - Deep dive on `__elixir__` specifically
- [`/std/phoenix/LiveSocket.hx`](/std/phoenix/LiveSocket.hx) - Real-world abstract type example
- [`/CLAUDE.md`](/CLAUDE.md) - Project-wide principles and lessons learned
# Haxe Best Practices for Reflaxe.Elixir Development

*Generated August 2025 - Based on real-world Phoenix LiveView integration experience*

**See Also**: [Paradigm Bridge](paradigms/PARADIGM_BRIDGE.md) - Cross-platform development patterns, conditional compilation guidelines, and functional programming techniques for effective Haxe→Elixir code.

## 📋 Quick Reference

### Core Principles
1. **Minimize Dynamic usage** - Use only when justified with comments
2. **Follow modern Haxe 4.3+ patterns** - No legacy idioms
3. **Type safety first** - Leverage Haxe's type system for compile-time error prevention
4. **Document macro-time vs runtime** - Critical for Reflaxe development

## 🎯 Dynamic Type Usage Guidelines

### ✅ When to Use Dynamic
```haxe
// ✅ GOOD: Exception handling (various error types)
} catch (e: Dynamic) {
    // Dynamic used here because Haxe's catch can throw various error types
    // Converting to String for error reporting
    EctoErrorReporter.reportSchemaError(className, Std.string(e), pos);
}

// ✅ GOOD: External API integration with unclear types
function handlePhoenixCallback(data: Dynamic): Void {
    // Dynamic required - Phoenix passes varied data structures
    // that change based on LiveView event type
}

// ✅ GOOD: Reflection operations
var fields: Array<String> = Reflect.fields(obj); // obj can be Dynamic here
```

### ❌ When NOT to Use Dynamic
```haxe
// ❌ BAD: Known data structures
function processUser(user: Dynamic): Void { } // Should be User type

// ❌ BAD: Return types that can be specific
function getConfig(): Dynamic { } // Should return Config typedef

// ❌ BAD: Function parameters with known structure
function validateForm(data: Dynamic): Bool { } // Should be FormData typedef
```

### 🔧 Better Alternatives
```haxe
// Instead of Dynamic everywhere, use typed interfaces:
typedef SocketAssigns = {
    ?todos: Array<Todo>,
    ?current_user: User,
    ?filter: String
};

typedef LiveViewSocket = {
    assigns: SocketAssigns,
    function assign(assigns: SocketAssigns): LiveViewSocket;
    function put_flash(type: String, message: String): LiveViewSocket;
};
```

## 🔄 Method Overloading with @:overload

### Haxe Supports Method Overloading
*Key Discovery: Haxe 4.2+ supports method overloading with `@:overload` metadata*

```haxe
// ✅ GOOD: Proper method overloading
@:native("Phoenix.PubSub")
extern class PubSub {
    /**
     * Subscribe to a topic
     */
    static function subscribe(topic: String, ?opts: Dynamic): Dynamic;
    
    /**
     * Subscribe with specific PubSub name
     */
    @:overload(function(pubsub: Dynamic, topic: String, ?opts: Dynamic): Dynamic {})
    static function subscribe(topic: String, ?opts: Dynamic): Dynamic;
}
```

### Alternative: Different Method Names
```haxe
// ✅ ALSO GOOD: Different method names for clarity
static function subscribe(topic: String, ?opts: Dynamic): Dynamic;
static function subscribe_to(pubsub: Dynamic, topic: String, ?opts: Dynamic): Dynamic;
```

## 🏗️ Architecture Patterns

### Macro-Time vs Runtime Understanding
**THE MOST CRITICAL CONCEPT for Reflaxe development:**

```haxe
// MACRO-TIME: During Haxe compilation
#if macro
class ElixirCompiler extends BaseCompiler {
    // This class ONLY exists while Haxe is compiling
    // It transforms AST → Elixir code, then DISAPPEARS
}
#end

// RUNTIME: After compilation, when tests/code runs
class MyTest {
    function test() {
        // ElixirCompiler DOES NOT EXIST HERE
        // It already did its job and vanished
        var result = SomeCompiledCode.run(); // ✅ This works
        var compiler = new ElixirCompiler(); // ❌ ERROR: Type not found
    }
}
```

### Extern Class Best Practices
```haxe
// ✅ GOOD: Complete extern with proper typing
@:native("Phoenix.Controller")
extern class Controller {
    /**
     * Render a template with assigns
     * @param conn The connection struct
     * @param template Template name (e.g., "index.html")
     * @param assigns Data to pass to template
     */
    static function render(conn: Dynamic, template: String, ?assigns: Dynamic): Dynamic;
}
```

### JavaScript Interop Patterns
```haxe
// ✅ GOOD: Type-safe JavaScript hook creation
static function createHookFunction(handler: LiveViewHook -> Void): Dynamic {
    return function() {
        var hook: LiveViewHook = cast untyped js.Lib.nativeThis;
        handler(hook);
    };
}

// ❌ BAD: Untyped everywhere
static function makeHook(): Dynamic {
    return untyped Syntax.code("this"); // Avoid this pattern
}
```

## 📦 Import and Alias Patterns

### Clean Import Organization
```haxe
// ✅ GOOD: Organized imports with aliases
import phoenix.Ecto;
import phoenix.Phoenix;

// Convenience aliases for frequently used classes
typedef Repo = phoenix.Ecto.EctoRepo;
typedef Changeset = phoenix.Ecto.EctoChangeset;

using StringTools; // Extensions at the end
```

### Module Structure
```haxe
package live;

// Standard imports first
import schemas.Todo;
import phoenix.Phoenix;
import phoenix.Ecto;

// using directives last
using StringTools;

// Convenience aliases after imports
typedef Repo = phoenix.Ecto.EctoRepo;

@:liveview
class TodoLive {
    // Implementation
}
```

## 🔄 Error Handling Patterns

### Pattern Matching Alternative
Since Haxe doesn't have Elixir's pattern matching, use conditional logic:

```haxe
// ❌ BAD: Elixir-style pattern matching doesn't work
return switch (Repo.insert(changeset)) {
    case Ok(todo): // This doesn't work in Haxe
        handleSuccess(todo);
    case Error(changeset):
        handleError(changeset);
}

// ✅ GOOD: Conditional result handling
var result = Repo.insert(changeset);
if (result.success) {
    var todo = result.data;
    return handleSuccess(todo);
} else {
    return handleError(result.error);
}
```

### Exception Handling
```haxe
// ✅ GOOD: Specific exception handling with Dynamic justification
try {
    performRiskyOperation();
} catch (e: Dynamic) {
    // Dynamic used here because various error types can be thrown
    // from Elixir/Phoenix operations. Converting to string for logging.
    Logger.error("Operation failed: " + Std.string(e));
}
```

## 🔧 Type System Leverage

### Modern Haxe 4.3+ Features
```haxe
// ✅ GOOD: Use modern features
// Null safety
var user: Null<User> = getUser();
if (user != null) {
    processUser(user); // Type-safe after null check
}

// Abstract types for type-safe wrappers
abstract UserId(Int) from Int to Int {
    public function new(id: Int) this = id;
}

// Arrow functions in expressions
var filtered = todos.filter(t -> !t.completed);

// Pattern matching with enums
var priority = switch (todo.priority) {
    case "high": Priority.High;
    case "medium": Priority.Medium;
    case "low": Priority.Low;
    case _: Priority.Medium;
};
```

### Avoid Legacy Patterns
```haxe
// ❌ BAD: Legacy patterns
Std.is(obj, String); // Use Std.isOfType() instead
untyped __js__("code"); // Use js.Syntax.code() instead
var x: Dynamic = anything; // Use proper typing when possible
```

## 🌐 Dual-Target Compilation

### Client-Side JavaScript Patterns
```haxe
// ✅ GOOD: Platform-specific compilation
#if js
// JavaScript-specific code
import js.Browser;
import js.html.Element;

class ClientHooks {
    static function setupHooks(): Void {
        Browser.window.addEventListener("DOMContentLoaded", initializeHooks);
    }
}
#end

#if (!js)
// Server-side (Elixir) code  
@:liveview
class ServerLive {
    public static function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        return socket.assign({initialized: true});
    }
}
#end
```

### Shared Code Patterns
```haxe
// ✅ GOOD: Shared validation logic
class TodoValidator {
    public static function validateTitle(title: String): Bool {
        return title != null && title.length >= 3 && title.length <= 200;
    }
    
    public static function validatePriority(priority: String): Bool {
        return ["low", "medium", "high"].contains(priority);
    }
}

// Used by both client and server:
// - Client: Real-time validation feedback
// - Server: Changeset validation  
```

## 🧪 Testing Patterns

### Snapshot Testing for Reflaxe
```haxe
// Test compilation output, not runtime behavior
// Reflaxe.Elixir generates Elixir code at compile-time

// ✅ GOOD: Test pattern
class TodoTest {
    public static function main() {
        // Test business logic that compiles to Elixir
        var validator = new TodoValidator();
        assert(validator.isValid("Valid Title"));
        
        // The generated Elixir code is tested separately
        // via Mix/ExUnit tests
    }
}
```

## 📚 Documentation Standards

### Code Comments
```haxe
// ✅ GOOD: Comprehensive documentation
/**
 * Creates a new todo item with validation
 * 
 * @param params Form parameters from LiveView
 * @param socket LiveView socket with user context
 * @return Updated socket with todo added or error flash
 */
public static function createTodo(params: Dynamic, socket: Dynamic): Dynamic {
    // Validation logic here
}
```

### Dynamic Usage Documentation
```haxe
// ✅ GOOD: Always justify Dynamic usage
function handleCallback(data: Dynamic): Void {
    // Dynamic used here because Phoenix LiveView passes different
    // event payload structures depending on the event type
    // (form data, click events, custom events, etc.)
}
```

## 🛣️ Roadmap Patterns

### Type-Safe Improvements
Future improvements to consider:

1. **Typed Phoenix APIs**
   ```haxe
   // Future: Replace Dynamic with typed interfaces
   typedef LiveViewSocket = {
       assigns: SocketAssigns,
       function assign(assigns: SocketAssigns): LiveViewSocket;
   };
   ```

2. **PubSub Topic Typing**
   ```haxe
   // Future: Type-safe topic strings
   abstract TopicString(String) from String {
       public static inline var TODO_UPDATES = "todo:updates";
       public static inline var USER_UPDATES = "user:updates";
   }
   ```

3. **Event Callback Typing**
   ```haxe
   // Future: Generic event handlers
   typedef EventHandler<T> = T -> Void;
   function pushEvent<T>(event: String, payload: T, ?callback: EventHandler<T>): Void;
   ```

## ⚡ Performance Patterns

### Compilation Efficiency
```haxe
// ✅ GOOD: Efficient patterns
// Use inline for small, frequently called functions
inline function isCompleted(todo: Todo): Bool {
    return todo.completed == true;
}

// Use abstracts for zero-cost type wrappers
abstract TodoId(Int) from Int to Int {
    inline function new(id: Int) this = id;
}
```

### Memory Management
```haxe
// ✅ GOOD: Resource cleanup in JavaScript target
#if js
class ResourceManager {
    static var listeners: Array<() -> Void> = [];
    
    static function cleanup(): Void {
        for (listener in listeners) {
            listener();
        }
        listeners = [];
    }
}
#end
```

## 🔍 Debugging Techniques

### Source Mapping Usage
```bash
# Use source mapping for precise error location
mix haxe.source_map lib/MyModule.ex 45 12
# Output: src_haxe/MyModule.hx:23:15

# Check compilation status
mix haxe.status --format json
```

### Compile-Time Validation
```haxe
// ✅ GOOD: Compile-time assertions
#if macro
class CompileTimeChecks {
    static function validateSchema() {
        // Macro-time validation of schema definitions
        // Ensures consistency between Haxe and Elixir
    }
}
#end
```

---

## 📖 Summary

### Key Takeaways
1. **Dynamic is not evil, but must be justified** with comments explaining why
2. **Haxe supports method overloading** with `@:overload` metadata  
3. **Macro-time vs runtime distinction** is critical for Reflaxe understanding
4. **Type safety should be the default** - use Haxe's powerful type system
5. **Modern Haxe 4.3+ patterns** provide better safety and performance
6. **Dual-target compilation** enables shared logic between client and server

### Quick Checklist
- [ ] All Dynamic usage has justification comments
- [ ] Using modern Haxe 4.3+ patterns (no legacy idioms)
- [ ] Extern classes are fully typed with documentation
- [ ] Error handling uses conditional logic, not pattern matching
- [ ] Imports are organized with proper aliases
- [ ] Platform-specific code uses `#if` conditionals appropriately

This guide evolved from real-world Phoenix LiveView integration and JavaScript interop challenges. Apply these patterns for maintainable, type-safe Haxe code that compiles efficiently to both Elixir and JavaScript targets.
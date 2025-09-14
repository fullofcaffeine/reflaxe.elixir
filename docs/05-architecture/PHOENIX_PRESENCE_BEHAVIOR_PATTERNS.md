# Phoenix.Presence Behavior Patterns and Architecture

## Overview

Phoenix.Presence is one of the most complex integrations in Reflaxe.Elixir because it has a dual nature:
1. **External API**: Called from LiveViews/Channels via `MyApp.Presence.track()`
2. **Internal Behavior**: Injected functions when you `use Phoenix.Presence`

This document explains the current implementation, its challenges, and future improvement paths.

## The Phoenix.Presence Dual API Problem

### External API (From LiveView/Channel)

When calling from OUTSIDE a Presence module:

```elixir
# In a LiveView
defmodule MyAppWeb.UserLive do
  alias MyAppWeb.Presence
  
  def mount(_params, _session, socket) do
    # External call - goes through the Presence module
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: System.system_time(:second)
    })
    {:ok, socket}
  end
end
```

The external API signatures:
- `track(socket, key, meta)` - 3 arguments
- `update(socket, key, meta)` - 3 arguments  
- `list(socket)` - 1 argument

### Internal Behavior API (Inside Presence Module)

When inside a module with `use Phoenix.Presence`:

```elixir
defmodule MyAppWeb.Presence do
  use Phoenix.Presence, otp_app: :my_app
  
  def track_user(socket, user_id, meta) do
    # Internal call - uses injected local function
    # Note: Different signature! Needs self() as first arg
    track(self(), socket, user_id, meta)
  end
end
```

The injected function signatures:
- `track(pid, topic, key, meta)` - 4 arguments, needs self()
- `update(pid, topic, key, meta)` - 4 arguments, needs self()
- `list(topic)` - 1 argument, no self() needed

## Historical Approach: BehaviorTransformer (Deprecated)

### Overview

Before the macro-based solution, Reflaxe.Elixir used a creative runtime transformation approach called the BehaviorTransformer. While this has been replaced with the cleaner macro-based solution, it's worth documenting as an interesting architectural exploration.

### How BehaviorTransformer Worked

The BehaviorTransformer was a compiler-level AST transformation system that intercepted method calls during compilation and rewrote them based on context.

#### 1. Detection Phase

```haxe
// In PresenceBehaviorTransformer.hx
function transformMethodCall(
    className: String,
    methodName: String,
    args: Array<ElixirAST>,
    isStatic: Bool
): Null<ElixirAST> {
    // Only transform Phoenix.Presence calls
    if (className != "Presence" && className != "phoenix.Presence") {
        return null;
    }
    // ...
}
```

#### 2. Transformation Logic

The transformer would:
1. Detect calls to `Phoenix.Presence` methods
2. Check if the code was inside a `@:presence` annotated module
3. Transform external calls to internal calls with `self()` injection

```haxe
// Original Haxe code in a @:presence module:
Phoenix.Presence.track(socket, user_id, meta);

// BehaviorTransformer would generate:
track(self(), socket, user_id, meta);
```

#### 3. Method-Specific Rules

```haxe
function needsSelf(methodName: String, argCount: Int): Bool {
    return switch(methodName) {
        case "track": true;      // Always needs self()
        case "update": true;     // Always needs self()
        case "untrack": true;    // Always needs self()
        case "list", "getByKey": false;  // No self() needed
        default: false;
    };
}
```

### Architecture Details

#### Integration with ElixirCompiler

The BehaviorTransformer was integrated into the main compilation pipeline:

```haxe
// In ElixirCompiler.hx
var behaviorTransformers = [
    new PresenceBehaviorTransformer(),
    // Other transformers could be added here
];

// During AST transformation
for (transformer in behaviorTransformers) {
    var result = transformer.transformMethodCall(className, methodName, args, isStatic);
    if (result != null) {
        return result;  // Use transformed version
    }
}
```

#### Snake Case Conversion

The transformer also handled Haxe's camelCase to Elixir's snake_case:

```haxe
function toSnakeCase(str: String): String {
    var result = "";
    for (i in 0...str.length) {
        var char = str.charAt(i);
        if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase()) {
            result += "_" + char.toLowerCase();
        } else {
            result += char.toLowerCase();
        }
    }
    return result;
}
```

### Interesting Aspects of the BehaviorTransformer

#### 1. Context-Aware Compilation

The transformer demonstrated how a compiler could be context-aware, generating different code based on where the source appeared:

- Inside a `@:presence` module → Generate internal calls with `self()`
- Outside (in LiveViews) → Keep external calls to the module

#### 2. Transparent API Transformation

Developers could write consistent code using `Phoenix.Presence` everywhere, and the compiler would "do the right thing" based on context.

#### 3. AST-Level Operation

By working at the AST level rather than string manipulation, the transformer could:
- Preserve type information
- Maintain source positions for error reporting
- Integrate cleanly with the rest of the compilation pipeline

### Limitations That Led to Deprecation

#### 1. Hidden Magic

The transformation was invisible to developers:
- No IntelliSense hints about the transformation
- Debugging showed transformed code, not what was written
- Difficult to understand without reading compiler source

#### 2. Compiler Complexity

The logic lived in the compiler rather than the standard library:
- Required compiler changes for Phoenix.Presence improvements
- Couldn't be versioned independently
- Made the compiler Phoenix-aware (framework coupling)

#### 3. Limited Extensibility

Adding new behaviors required:
- Creating new transformer classes
- Modifying the compiler to register them
- No way for users to create their own behavior transformations

#### 4. Testing Challenges

Testing required:
- Compiling code and checking generated output
- No unit testing possible for the transformation logic
- Difficult to test edge cases

### Lessons Learned

The BehaviorTransformer approach taught valuable lessons:

1. **Explicit is Better Than Implicit**: The macro-based approach makes the dual API explicit and discoverable
2. **Library Over Compiler**: Moving logic to the standard library (via macros) is more maintainable
3. **Type System Integration**: Using Haxe's type system (interfaces + macros) provides better IDE support
4. **User Extensibility**: The macro approach allows users to create their own similar patterns

### Code Archaeology: The Original Implementation

For historical reference, the complete PresenceBehaviorTransformer implementation can be found in the git history at:
`src/reflaxe/elixir/behaviors/PresenceBehaviorTransformer.hx`

Key commits:
- Initial implementation: [commit hash]
- Detection improvements: [commit hash]  
- Deprecation in favor of macros: [commit hash]

This transformer was an interesting exploration of compiler-assisted API adaptation, showing how a transpiler can bridge differences between source and target language patterns. While ultimately replaced, it demonstrated creative thinking about solving the impedance mismatch between Haxe's static nature and Phoenix's dynamic behavior injection.

## Current Implementation: Macro-Based Dual API

### Overview

The current implementation uses Haxe's macro system to generate both internal and external APIs at compile-time. This approach is cleaner, more maintainable, and provides better IDE support than the previous BehaviorTransformer.

### How It Works

1. **Interface with @:autoBuild**: `PresenceBehavior` interface triggers macro generation
2. **Compile-Time Generation**: `PresenceMacro.build()` generates methods during compilation
3. **Dual API**: Both internal (with self()) and external methods are available
4. **Type Safety**: Full type checking and IntelliSense support

```haxe
// Developer writes:
@:native("MyAppWeb.Presence")
class MyPresence implements PresenceBehavior {
    // Methods are generated automatically
}

// Macro generates:
// - trackInternal(socket, key, meta) → track(self(), socket, key, meta)
// - track(socket, key, meta) → Phoenix.Presence.track(socket, key, meta)
// - updateInternal(...), update(...), etc.
```

### Benefits Over BehaviorTransformer

- **Explicit API**: Developers can see and use both internal and external methods
- **IDE Support**: Full IntelliSense for all generated methods
- **Library-Based**: Logic in standard library, not compiler
- **Extensible**: Users can create similar patterns for other behaviors
- **Debuggable**: Generated code is visible and debuggable

## Detailed Comparison: BehaviorTransformer vs Macro-Based Approach

### Architecture Comparison

| Aspect | BehaviorTransformer (Old) | Macro-Based (Current) |
|--------|---------------------------|----------------------|
| **Location** | Compiler (`src/reflaxe/elixir/behaviors/`) | Standard Library (`std/phoenix/macros/`) |
| **Trigger** | `@:presence` annotation | `implements PresenceBehavior` |
| **Generation Time** | During AST transformation | During macro expansion |
| **Visibility** | Hidden transformation | Explicit generated methods |
| **Extensibility** | Requires compiler changes | User-definable patterns |

### Code Generation Comparison

#### BehaviorTransformer Approach

```haxe
// Developer writes:
@:presence
class TodoPresence {
    function trackUser(socket, user) {
        // Magic happens here - Phoenix.Presence becomes local track()
        Phoenix.Presence.track(socket, user.id, meta);
    }
}

// Generated Elixir (invisible transformation):
defmodule TodoAppWeb.Presence do
    use Phoenix.Presence, otp_app: :todo_app
    
    def track_user(socket, user) do
        # Transformer injected self() here
        track(self(), socket, user.id, meta)
    end
end
```

#### Macro-Based Approach

```haxe
// Developer writes:
class TodoPresence implements PresenceBehavior {
    function trackUser(socket, user) {
        // Explicit choice: use internal method
        trackInternal(socket, user.id, meta);
    }
}

// Macro generates these methods (visible in IDE):
class TodoPresence {
    // Internal API (generated)
    static function trackInternal(socket, key, meta) {
        return untyped __elixir__('track({0}, {1}, {2}, {3})', 
            untyped __elixir__('self()'), socket, key, meta);
    }
    
    // External API (generated)
    static function track(socket, key, meta) {
        return Phoenix.Presence.track(socket, key, meta);
    }
}
```

### Developer Experience Comparison

#### BehaviorTransformer DX

```haxe
// Confusing: Same code, different behavior based on context
Phoenix.Presence.track(socket, key, meta);  // What does this do?
// - In @:presence module: Transforms to track(self(), ...)
// - In LiveView: Stays as Phoenix.Presence.track(...)
// - No IDE hints about the transformation
```

#### Macro-Based DX

```haxe
// Clear: Explicit method choice
trackInternal(socket, key, meta);  // Obviously internal (with self())
track(socket, key, meta);          // Obviously external
// - IDE shows both methods
// - Autocomplete works
// - Documentation available
```

### Debugging Experience Comparison

#### BehaviorTransformer Debugging

```elixir
# Error in generated Elixir:
** (ArgumentError) argument error
    (todo_app) lib/todo_app_web/presence.ex:45: TodoAppWeb.Presence.track_user/2
    
# Developer confusion: "But I called Phoenix.Presence.track, not track!"
# Must understand the hidden transformation to debug
```

#### Macro-Based Debugging

```elixir
# Error in generated Elixir:
** (ArgumentError) argument error  
    (todo_app) lib/todo_app_web/presence.ex:45: TodoAppWeb.Presence.track_internal/3
    
# Clear: Error is in track_internal, which developer explicitly called
# Stack trace matches what was written
```

### Maintenance Comparison

#### BehaviorTransformer Maintenance

```haxe
// To add a new behavior method:
// 1. Edit PresenceBehaviorTransformer.hx in compiler
// 2. Add to needsSelf() switch statement
// 3. Update toSnakeCase() if needed
// 4. Recompile entire compiler
// 5. Test with example projects
// 6. Release new compiler version
```

#### Macro-Based Maintenance

```haxe
// To add a new behavior method:
// 1. Edit PresenceMacro.hx in standard library
// 2. Add new generateXXX() method
// 3. No compiler changes needed
// 4. Users get update with stdlib update
// 5. Can be versioned independently
```

### Testing Comparison

#### BehaviorTransformer Testing

```haxe
// Testing requires full compilation:
// 1. Create test Haxe file with @:presence
// 2. Compile to Elixir
// 3. Check generated output
// 4. No unit testing possible
// 5. Difficult to test edge cases
```

#### Macro-Based Testing  

```haxe
// Direct testing possible:
@:build(phoenix.macros.PresenceMacro.build())
class TestPresence {}

// Can test:
// - Method generation
// - Type signatures
// - Error cases
// - Edge cases
// Unit tests can verify macro behavior
```

### Performance Comparison

| Metric | BehaviorTransformer | Macro-Based |
|--------|-------------------|-------------|
| **Compile Time** | Slower (AST traversal) | Faster (macro expansion) |
| **Runtime** | Identical | Identical |
| **Memory** | Higher (transformer instances) | Lower (static macros) |
| **Caching** | Limited | Full macro caching |

### Philosophical Differences

#### BehaviorTransformer Philosophy
- **Implicit Magic**: "The compiler knows what you mean"
- **Context-Aware**: "Same code, different behavior based on location"
- **Compiler-Centric**: "The compiler is smart and handles complexity"
- **Hidden Complexity**: "Users don't need to know how it works"

#### Macro-Based Philosophy
- **Explicit Control**: "Developers choose which API to use"
- **Predictable**: "Same code always does the same thing"
- **Library-Centric**: "Standard library provides the tools"
- **Transparent**: "Generated code is visible and understandable"

### Migration Path

For projects using the old BehaviorTransformer:

```haxe
// Old code:
@:presence
class MyPresence {
    function helper(socket, key, meta) {
        Phoenix.Presence.track(socket, key, meta);
    }
}

// New code:
class MyPresence implements PresenceBehavior {
    function helper(socket, key, meta) {
        trackInternal(socket, key, meta);  // Explicit internal call
    }
}
```

### Conclusion

The macro-based approach represents a maturation of the Phoenix.Presence integration:
- From **compiler magic** to **standard library patterns**
- From **implicit behavior** to **explicit APIs**
- From **hidden transformations** to **visible generated code**
- From **monolithic compiler** to **modular standard library**

While the BehaviorTransformer was a creative solution that demonstrated the power of AST transformation, the macro-based approach better aligns with Haxe's philosophy of explicit, type-safe code with excellent tooling support

## Alternative Approaches Considered

### Option 1: BasePresence with Dual API

### The Design

```haxe
// std/phoenix/BasePresence.hx
@:autoBuild(phoenix.macros.PresenceMacro.build())
class BasePresence {
    // ====== INTERNAL API (for use within Presence modules) ======
    
    /**
     * Track presence internally (within a Presence module)
     * Compiles to: track(self(), socket, key, meta)
     */
    protected static function trackInternal(socket: Socket, key: String, meta: Dynamic): Dynamic {
        // This uses the injected local function
        return untyped __elixir__('track(self(), {0}, {1}, {2})', socket, key, meta);
    }
    
    protected static function updateInternal(socket: Socket, key: String, meta: Dynamic): Dynamic {
        return untyped __elixir__('update(self(), {0}, {1}, {2})', socket, key, meta);
    }
    
    protected static function listInternal(topic: String): Dynamic {
        return untyped __elixir__('list({0})', topic);
    }
    
    // ====== EXTERNAL API (for use from LiveViews/Channels) ======
    
    /**
     * Track presence externally (from LiveView/Channel)
     * Must be called on the specific Presence module instance
     * 
     * Usage from LiveView:
     * ```haxe
     * TodoPresence.track(socket, user_id, meta);
     * ```
     * 
     * Compiles to:
     * ```elixir
     * TodoAppWeb.Presence.track(socket, user_id, meta)
     * ```
     */
    public static function track(socket: Socket, key: String, meta: Dynamic): Dynamic {
        // This calls through the module's public API
        // The actual implementation would be generated by the macro
        throw "This should be overridden by macro";
    }
    
    public static function update(socket: Socket, key: String, meta: Dynamic): Dynamic {
        throw "This should be overridden by macro";
    }
    
    public static function list(socketOrTopic: Dynamic): Dynamic {
        throw "This should be overridden by macro";
    }
}
```

### Usage Example

```haxe
// Your Presence module
@:presence
@:native("TodoAppWeb.Presence")
class TodoPresence extends BasePresence {
    // Custom type for your metadata
    typedef UserMeta = {
        onlineAt: Float,
        userName: String,
        status: String
    }
    
    // Internal helper using the protected methods
    public static function trackUser(socket: Socket, user: User): Socket {
        var meta: UserMeta = {
            onlineAt: Date.now().getTime(),
            userName: user.name,
            status: "online"
        };
        
        // Uses the internal API (protected method from BasePresence)
        trackInternal(socket, Std.string(user.id), meta);
        return socket;
    }
    
    // The public static methods are available for external callers
    // They're automatically implemented by the macro
}

// From a LiveView (external usage)
class UserLive {
    function mount(params: Dynamic, session: Dynamic, socket: Socket): {ok: Socket} {
        // External API - calls the public static method
        TodoPresence.track(socket, Std.string(currentUser.id), {
            onlineAt: Date.now().getTime()
        });
        
        // Get all presences
        var allUsers = TodoPresence.list(socket);
        
        return {ok: socket};
    }
}
```

### How the Macro Would Work

The `PresenceMacro.build()` macro would:

1. **Generate External API**: Create public static methods that compile to proper module calls
2. **Setup Behavior**: Add `use Phoenix.Presence, otp_app: :app_name`
3. **Wire Methods**: Ensure external methods call through the module correctly

Generated Elixir for external call:
```elixir
# From UserLive
TodoAppWeb.Presence.track(socket, user_id, meta)
```

Generated Elixir for internal call:
```elixir
# Inside TodoAppWeb.Presence module
track(self(), socket, user_id, meta)
```

## Comparison of Approaches

### Current: BehaviorTransformer

**Pros:**
- Works without standard library changes
- Transparent to the user
- No inheritance needed

**Cons:**
- Hidden compiler magic
- Poor IDE support
- Hard to debug
- Compiler complexity

### Future: BasePresence Pattern

**Pros:**
- Clear separation of internal/external APIs
- Full IDE support and IntelliSense
- Documentation in standard library
- Easier to debug
- Less compiler complexity

**Cons:**
- Requires inheritance (not idiomatic in Elixir)
- More standard library code
- Need to maintain two API surfaces

### Alternative: Static Extensions

```haxe
// Could also use static extensions
using phoenix.PresenceExtensions;

@:presence
class TodoPresence {
    public static function trackUser(socket: Socket, user: User): Socket {
        // Extension method adds the behavior
        TodoPresence.trackBehavior(socket, user.id, meta);
        return socket;
    }
}
```

**Pros:**
- No inheritance needed
- Haxe idiomatic
- Composable

**Cons:**
- Less discoverable
- Still need dual API handling

## Implementation Roadmap

### Phase 1: Document Current State (DONE)
- Document BehaviorTransformer approach ✓
- Explain the dual API problem ✓
- Show current usage patterns ✓

### Phase 2: Design BasePresence Pattern
- Create BasePresence class in std/phoenix/
- Implement PresenceMacro for code generation
- Test with todo-app

### Phase 3: Migration
- Update todo-app to use BasePresence
- Update documentation
- Deprecate BehaviorTransformer approach

### Phase 4: Extend to Other Behaviors
- Apply same pattern to GenServer
- Apply to Supervisor
- Apply to other Phoenix behaviors

## Key Insights

1. **Phoenix behaviors are complex** because they inject local functions that differ from their public API
2. **Dual API is necessary** - we need both internal (within module) and external (from LiveView) access
3. **Standard library patterns are better** than compiler magic for maintainability
4. **BasePresence with protected/public methods** provides the clearest mental model
5. **Macros can bridge the gap** between Haxe's OOP and Elixir's behaviors

## Testing Considerations

When implementing the BasePresence pattern, ensure:

1. **External calls work** from LiveViews and Channels
2. **Internal calls work** within the Presence module
3. **Type safety is preserved** for metadata
4. **Generated Elixir is idiomatic**
5. **No runtime overhead** compared to direct implementation

## Migration Guide (Future)

When BasePresence is ready:

1. **Update imports**: Add `extends BasePresence`
2. **Change method calls**: Use `trackInternal()` for internal, `track()` for external
3. **Remove __elixir__**: No more direct native code injection needed
4. **Update types**: Use typed metadata instead of Dynamic
5. **Test thoroughly**: Both internal and external API usage

## Static Method Inheritance in Haxe (Research Findings)

### The Question
Can the BasePresence pattern work with static methods? Would `TodoPresence.track()` inherit static methods from `BasePresence`?

### Research Findings

After investigating the Haxe documentation, reference implementations, community discussions, and GitHub issues, the findings about static method inheritance are definitive:

**Sources Consulted:**
- [Stack Overflow: Static methods not inherited](https://stackoverflow.com/questions/24051752/static-methods-not-inherited)
- [Haxe Community: "Class has no field" Error](https://community.haxe.org/t/class-has-no-field-error/472)
- [GitHub Issue #2902: Method inherited from generic class](https://github.com/HaxeFoundation/haxe/issues/2902)
- Multiple Haxe forum discussions confirming the behavior

1. **Haxe does NOT inherit static methods**
   - Static methods belong to the class itself, not instances
   - Child classes don't automatically get parent static methods
   - Attempting to call a parent's static method on a child class results in a compiler error
   
   ```haxe
   class BasePresence {
       public static function track() { /* ... */ }
   }
   
   class TodoPresence extends BasePresence {}
   
   // This FAILS with compiler error:
   TodoPresence.track(); // Class<TodoPresence> has no field track
   
   // Must call through parent:
   BasePresence.track(); // Works, but not what we want
   ```

2. **This is intentional language design**
   - Static methods are class-specific by design
   - Inheritance is meant for instance behaviors and polymorphism
   - Static "inheritance" doesn't align with OOP principles

3. **Macro-based solution is the only way**
   - The `@:autoBuild` macro on BasePresence would need to generate static methods on child classes
   - This is how we'd make `TodoPresence.track()` work as an external API
   - The macro would inject both internal (protected) and external (public) static methods

### Implications for BasePresence Pattern

The BasePresence pattern would need modification:

```haxe
// BasePresence with @:autoBuild macro
@:autoBuild(phoenix.macros.PresenceMacro.build())
class BasePresence {
    // These DON'T automatically appear on TodoPresence
    public static function track(...) { }
    
    // The macro must generate these on each child class
}

// TodoPresence after macro processing
class TodoPresence extends BasePresence {
    // Macro-generated external API
    public static function track(...) { /* calls module */ }
    public static function update(...) { /* calls module */ }
    
    // Can use protected methods from parent
    // But must be called as BasePresence.trackInternal()
}
```

### Alternative Approaches Given These Limitations

1. **Static Extension Pattern** (using Haxe's `using` keyword)
   - More idiomatic for Haxe
   - Doesn't require inheritance
   - Clear separation of concerns

2. **Macro-Only Pattern** (current BehaviorTransformer approach)
   - Already works without inheritance
   - Could be enhanced with better IDE support

3. **Hybrid Pattern**
   - Use instance methods for internal API
   - Use macro-generated static methods for external API
   - Mix of both approaches

### Comparison with Other OOP Languages

Understanding how other languages handle static method inheritance helps contextualize Haxe's design choices:

#### **Java: Inherited but Hidden**
```java
class Parent {
    public static void track() { System.out.println("Parent.track"); }
}

class Child extends Parent {
    // Child inherits track(), can be called as Child.track()
    // But if Child defines its own track(), it HIDES (not overrides) Parent's
    public static void track() { System.out.println("Child.track"); }
}

// Usage:
Child.track();  // Works! Calls Child's version (hiding)
Parent p = new Child();
p.track();  // Calls Parent's version (compile-time binding)
```

**Key Differences from Haxe:**
- Java DOES inherit static methods (child can call parent's static methods)
- But uses "method hiding" not overriding (no polymorphism)
- Resolution happens at compile-time based on reference type

#### **C#: Similar to Java**
```csharp
class Parent {
    public static void Track() { Console.WriteLine("Parent.Track"); }
}

class Child : Parent {
    // Child can access Parent.Track() but must use Parent class name
    public static void CallParentTrack() {
        Parent.Track();  // Must explicitly use Parent
    }
    
    // Can hide with 'new' keyword
    public new static void Track() { Console.WriteLine("Child.Track"); }
}

// Usage:
Child.Track();  // If Child defines it, calls Child's version
                // If not, compiler error (unlike Java)
```

**Key Differences from Haxe:**
- C# allows calling parent static methods but requires explicit parent class name
- Can use `new` keyword to explicitly hide parent methods
- No automatic inheritance of static method names to child class

#### **Haxe: No Inheritance At All**
```haxe
class Parent {
    public static function track() { trace("Parent.track"); }
}

class Child extends Parent {}

// Usage:
Child.track();    // COMPILER ERROR: Class<Child> has no field track
Parent.track();   // Works, but must use Parent explicitly
```

**Haxe's Stricter Approach:**
- NO inheritance of static methods whatsoever
- Child classes cannot call parent static methods using their own name
- Must always explicitly reference the parent class

### Comprehensive Language Comparison

#### Static/Class Method Inheritance Across Languages

| Language | Static/Class Inheritance | Method Hiding | Polymorphism | Child Access | Special Features |
|----------|--------------------------|---------------|--------------|--------------|------------------|
| **Java** | ✅ Yes | ✅ Yes (automatic) | ❌ No | `Child.parentMethod()` works | Compile-time binding |
| **C#** | ⚠️ Partial | ✅ Yes (with `new`) | ❌ No | Must use `Parent.method()` | Explicit hiding with `new` |
| **Haxe** | ❌ No | N/A | ❌ No | Must use `Parent.method()` | Build macros can simulate |
| **Ruby** | ✅ Yes (full) | ✅ Yes | ✅ Yes! | `Child.parent_method` works | `inherited` hook, singleton classes |
| **Elixir** | N/A (no classes) | N/A | N/A | N/A | Modules with `use`/`defdelegate` |

#### Ruby: Most Flexible Approach
```ruby
class Parent
  def self.track
    puts "Parent.track"
  end
  
  # Hook called when subclassed
  def self.inherited(subclass)
    puts "#{subclass} inherits from #{self}"
  end
end

class Child < Parent
  # Inherits Parent.track automatically
end

Child.track  # Works! Calls Parent.track
```

**Ruby's Unique Features:**
- **Full inheritance**: Class methods ARE inherited
- **Polymorphism works**: Can override and use `super`
- **`inherited` hook**: Parent knows when it's subclassed
- **Singleton classes**: Each class has its own singleton class for class methods

#### Elixir: No Classes, Only Modules
```elixir
defmodule Parent do
  def track(socket, key, meta) do
    # Module function
  end
end

defmodule Child do
  use Parent  # Doesn't inherit - injects code via __using__ macro
  
  # Must explicitly delegate
  defdelegate track(socket, key, meta), to: Parent
end
```

**Elixir's Approach:**
- **No inheritance**: Modules don't inherit
- **Composition over inheritance**: Use `use`, `import`, `defdelegate`
- **Macro-based code injection**: `__using__` macro injects code
- **Explicit delegation**: Must explicitly forward calls

### Pros and Cons of Each Approach

#### **Java: Inherited with Hiding**
**Pros:**
- ✅ Convenient - child classes automatically get parent static methods
- ✅ Less boilerplate - no need to redefine or delegate
- ✅ Familiar to OOP developers

**Cons:**
- ❌ Confusing method hiding vs overriding semantics
- ❌ No polymorphism - compile-time binding only
- ❌ Can accidentally hide parent methods
- ❌ Inconsistent with instance method behavior

#### **C#: Partial Inheritance**
**Pros:**
- ✅ Explicit hiding with `new` keyword prevents accidents
- ✅ Clear intent when hiding is desired
- ✅ Middle ground between convenience and safety

**Cons:**
- ❌ Must use parent class name for access
- ❌ More verbose than Java
- ❌ Still no polymorphism
- ❌ Can be confusing which class owns the method

#### **Ruby: Full Inheritance with Polymorphism**
**Pros:**
- ✅ Most flexible - true polymorphism for class methods
- ✅ `inherited` hook enables powerful metaprogramming
- ✅ Can use `super` to call parent implementation
- ✅ Consistent with instance method behavior

**Cons:**
- ❌ Can be "too magical" - hard to trace method origin
- ❌ Singleton class concept is complex
- ❌ Performance overhead from method lookup
- ❌ Hard to compile to static languages

#### **Elixir: No Inheritance, Only Composition**
**Pros:**
- ✅ Explicit is better than implicit
- ✅ Clear module boundaries
- ✅ Powerful macro system for code injection
- ✅ No confusion about method origin

**Cons:**
- ❌ More verbose - must explicitly delegate
- ❌ No traditional inheritance patterns
- ❌ Learning curve for OOP developers
- ❌ Requires different mental model

#### **Haxe: No Static Inheritance**
**Pros:**
- ✅ **Unambiguous**: Always know which class owns the method
- ✅ **Cross-platform safe**: Compiles predictably to all targets
- ✅ **No hiding surprises**: Can't accidentally shadow methods
- ✅ **Build macros**: Can simulate inheritance when needed
- ✅ **Clear compilation**: Easier to understand generated code

**Cons:**
- ❌ More verbose - must use parent class name
- ❌ Less convenient for library design
- ❌ Requires macros for inheritance-like behavior
- ❌ Different from mainstream OOP languages

### Why Haxe's Approach Makes Sense

Haxe's strict no-inheritance policy for static methods is **optimal for a cross-platform language**:

1. **Target Language Compatibility**: Since Haxe compiles to Java, C#, JavaScript, Python, etc., each with different static method semantics, having the strictest rules ensures consistent behavior across all targets

2. **Predictable Compilation**: The generated code is always explicit about which class's method is being called, making debugging easier

3. **Build Macros as Escape Hatch**: When you truly need inheritance-like behavior, build macros provide a powerful, explicit way to generate the necessary code

4. **Alignment with Functional Programming**: Static methods are essentially namespaced functions, and treating them as non-inheritable aligns with FP principles

5. **Prevents Design Mistakes**: Forces developers to think about whether they really need static methods or if instance methods would be better

### Community Consensus and Recommended Patterns

Based on extensive research across Haxe forums, GitHub issues, and community discussions:

1. **Universal Agreement**: The Haxe community universally confirms that static methods are NOT inherited
2. **Common Error**: "Class has no field" when trying to access parent static methods from child classes
3. **Rationale**: "Static functions belong directly to the class, not to instances. Since there is no instantiation or polymorphism with static methods, inheriting them makes little sense"

#### Recommended Solutions from the Community:

1. **Build Macros (`@:autoBuild`)** - Most Powerful
   - Generate static methods in child classes at compile-time
   - This is exactly what our BehaviorTransformer does internally
   - Community consensus: "What you really need is build macro (haxe unique feature)"

##### How Build Macros Simulate Static Inheritance

Build macros can effectively make static methods "inheritable" by generating them in child classes:

```haxe
// BasePresence with build macro
@:autoBuild(phoenix.macros.PresenceMacro.build())
class BasePresence {
    // Define the API contract
}

// The macro generates in each child:
class TodoPresence extends BasePresence {
    // Macro-generated at compile time:
    public static function track(socket, key, meta) {
        // Generated implementation
        return TodoAppWeb.Presence.track(socket, key, meta);
    }
    
    public static function update(socket, key, meta) {
        // Generated implementation
        return TodoAppWeb.Presence.update(socket, key, meta);
    }
}
```

**Result**: Child classes appear to "inherit" static methods, but they're actually generated at compile-time. This gives the developer experience of inheritance while respecting Haxe's design constraints.

### Creating Java-Like or Better Inheritance with Haxe Macros

Haxe's macro system is powerful enough to implement **any inheritance pattern** you want, including surpassing what traditional OOP languages offer. Here's how:

#### Implementing Java-Like Static Inheritance

```haxe
// Macro that provides Java-like static inheritance
class StaticInheritanceMacro {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        
        // Get parent class
        if (cls.superClass != null) {
            var parentClass = cls.superClass.t.get();
            var parentFields = parentClass.statics.get();
            
            // Copy all parent static methods to child
            for (field in parentFields) {
                if (!hasField(fields, field.name)) {
                    // Generate delegating method in child
                    var newField = {
                        name: field.name,
                        access: [APublic, AStatic],
                        kind: FFun({
                            args: extractArgs(field),
                            expr: macro return $p{[parentClass.name, field.name]}($a{args}),
                            ret: field.type
                        }),
                        pos: Context.currentPos()
                    };
                    fields.push(newField);
                }
            }
        }
        return fields;
    }
}

// Usage - Java-like behavior
@:autoBuild(StaticInheritanceMacro.build())
class InheritableStatics {}

class Parent extends InheritableStatics {
    public static function track() { trace("Parent.track"); }
}

class Child extends Parent {
    // Automatically gets track() via macro!
}

// Now this works:
Child.track(); // ✅ Works! Macro generated this method
```

#### Going Beyond Java: Compile-Time Method Versioning

```haxe
// Macro that generates multiple method versions at COMPILE-TIME
class VersionedStaticsMacro {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        
        // COMPILE-TIME: Analyze version metadata
        for (field in fields) {
            var meta = field.meta.filter(m -> m.name == ":version");
            if (meta.length > 0) {
                var version = meta[0].params[0];
                
                // COMPILE-TIME: Generate multiple method signatures
                var v2Method = createVersionedMethod(field, 2);
                var v1Method = createDeprecatedVersion(field, 1);
                var dispatcher = createSmartDispatcher(field);
                
                // Add all generated methods at COMPILE-TIME
                fields.push(v2Method);
                fields.push(v1Method);
                fields.push(dispatcher);
            }
        }
        
        return fields;
    }
}

// Usage
@:autoBuild(VersionedStaticsMacro.build())
class APIClass {
    @:version(2)
    public static function connect(host: String, port: Int) { }
    
    // At COMPILE-TIME, macro generates these methods:
    // - connect_v2(host, port) - new version
    // - connect_v1(url) - old signature (marked @:deprecated)
    // - connect(...) - overloaded dispatcher
    // All versioning is resolved at COMPILE-TIME, no runtime overhead
}
```

#### Ruby-Like with Inheritance Hooks

##### The Proper Way: Compile-Time Inheritance Hook (Recommended)

```haxe
// Macro that implements true compile-time inheritance hooks
class InheritanceHookMacro {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        
        // COMPILE-TIME: Execute the parent's onInherited hook NOW during compilation
        if (cls.superClass != null) {
            var parentClass = cls.superClass.t.get();
            
            // Check if parent has a special metadata indicating it wants to know about children
            if (parentClass.meta.has(":trackChildren")) {
                // This executes at COMPILE TIME - we're actually calling a macro function
                onChildInherited(parentClass.name, cls.name);
                
                // Also generate a static field listing this child
                var childField = {
                    name: "__isChildOf_" + parentClass.name,
                    access: [AStatic, APublic, AFinal],
                    kind: FVar(macro : Bool, macro true),
                    pos: Context.currentPos()
                };
                fields.push(childField);
            }
        }
        
        return fields;
    }
    
    // This function runs at COMPILE TIME when a child is discovered
    static function onChildInherited(parentName: String, childName: String) {
        // COMPILE-TIME operations:
        #if macro
        trace('COMPILE TIME: ${childName} inherits from ${parentName}');
        
        // Could write to a file, generate code, validate rules, etc.
        // This is like Ruby's inherited hook but at compile-time!
        
        // Example: Enforce naming conventions at compile-time
        if (!childName.endsWith(parentName.substr(4))) { // If parent is "Base*"
            Context.warning('Child ${childName} should follow naming convention for ${parentName}', Context.currentPos());
        }
        #end
    }
}

// Usage - true compile-time tracking
@:trackChildren
@:autoBuild(InheritanceHookMacro.build())
class TrackableParent {
    // The macro could generate this at compile-time with all known children
    public static final children: Array<String> = ["Child1", "Child2"]; // Generated!
}

class Child1 extends TrackableParent {
    // At COMPILE TIME when this class is processed:
    // 1. onChildInherited("TrackableParent", "Child1") is called
    // 2. A field __isChildOf_TrackableParent = true is added
    // 3. Parent's children array is updated (if using initialization macros)
}
```

##### Alternative: Runtime Registration (When Actually Needed)

```haxe
// Use runtime ONLY when you truly need dynamic behavior
class RuntimeRegistrationMacro {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        
        if (cls.superClass != null) {
            // Generate runtime registration ONLY if you need:
            // - Lazy loading of classes
            // - Plugin systems
            // - Dynamic module loading
            // - Runtime reflection
            
            var initField = {
                name: "__init__",
                access: [AStatic, APrivate],
                kind: FFun({
                    args: [],
                    expr: macro {
                        // This runs at RUNTIME - usually not needed!
                        registerWithParent();
                    },
                    ret: null
                }),
                pos: Context.currentPos()
            };
            fields.push(initField);
        }
        
        return fields;
    }
}
```

##### When to Use Each Approach

**Compile-Time Hooks (RECOMMENDED for onInherited):**
- ✅ **Inheritance is static** - Known at compile-time in Haxe
- ✅ **Zero runtime cost** - No initialization overhead
- ✅ **Can enforce rules** - Validate inheritance patterns at compile-time
- ✅ **Generate optimal code** - Create exactly what's needed
- ✅ **True to Haxe's nature** - Leverage compile-time knowledge

**Runtime Registration (RARE - Only When Necessary):**
- ⚠️ **Plugin systems** - When loading external modules at runtime
- ⚠️ **Lazy initialization** - When you need delayed registration
- ⚠️ **Runtime reflection** - When using runtime type information
- ❌ **Not for inheritance** - Inheritance is compile-time in Haxe!

**Key Insight**: Unlike Ruby where classes are created at runtime, Haxe knows all inheritance at compile-time. The `onInherited` hook should execute during compilation, not at runtime. This is more efficient and allows for compile-time validation and code generation.

#### Creating Polymorphic-Like Static Methods

```haxe
// Macro that simulates polymorphic static methods through code generation
class PolymorphicStaticsMacro {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        
        // COMPILE-TIME: Analyze which methods need polymorphic behavior
        for (field in fields) {
            if (field.meta.has(":polymorphicStatic")) {
                // COMPILE-TIME: Generate specialized version for this class
                var specializedField = createSpecializedVersion(field, cls);
                fields.push(specializedField);
            }
        }
        
        return fields;
    }
    
    // COMPILE-TIME: Creates a specialized version of the method
    static function createSpecializedVersion(field: Field, cls: ClassType): Field {
        // Generate code that will run at RUNTIME with correct type
        return {
            name: field.name,
            access: [AStatic, APublic],
            kind: FFun({
                args: [],
                expr: macro {
                    // This code runs at RUNTIME but is specialized at COMPILE-TIME
                    return new $i{cls.name}();
                },
                ret: null
            }),
            pos: Context.currentPos()
        };
    }
}

// Usage - Compile-time specialized statics
@:autoBuild(PolymorphicStaticsMacro.build())
class PolymorphicBase {
    @:polymorphicStatic
    public static function getInstance(): PolymorphicBase {
        // Each child class gets its own specialized version at COMPILE-TIME
        throw "Should be overridden by macro";
    }
}
```

#### Aspect-Oriented Static Methods Through Compile-Time Wrapping

```haxe
// Macro that wraps methods with cross-cutting concerns at COMPILE-TIME
class AspectStaticsMacro {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        
        for (field in fields) {
            // COMPILE-TIME: Analyze metadata and wrap methods
            if (hasMetadata(field, ":logged")) {
                // COMPILE-TIME: Modify the AST to add logging
                field = wrapWithLogging(field);
            }
            
            if (hasMetadata(field, ":cached")) {
                // COMPILE-TIME: Generate caching wrapper code
                field = wrapWithCache(field);
            }
            
            if (hasMetadata(field, ":retry")) {
                // COMPILE-TIME: Generate retry logic wrapper
                field = wrapWithRetry(field);
            }
        }
        
        return fields;
    }
    
    // COMPILE-TIME: Wraps the original method with logging
    static function wrapWithLogging(field: Field): Field {
        var originalExpr = getFieldExpression(field);
        field.expr = macro {
            trace('Calling ${field.name}');  // This trace runs at RUNTIME
            var result = $originalExpr;      // Original method runs at RUNTIME
            trace('Completed ${field.name}');
            return result;
        };
        return field;
    }
}

// Usage
@:autoBuild(AspectStaticsMacro.build())
class ServiceClass {
    @:logged
    @:cached(ttl = 60)
    @:retry(attempts = 3)
    public static function fetchData(id: String): Data {
        // At COMPILE-TIME, macro wraps this with logging, caching, and retry
        // At RUNTIME, the wrapped version executes
        return API.get('/data/$id');
    }
    
    // After macro processing at COMPILE-TIME, this becomes:
    // public static function fetchData(id: String): Data {
    //     trace('Calling fetchData');           // Added by @:logged
    //     var cached = checkCache(id);          // Added by @:cached
    //     if (cached != null) return cached;
    //     var attempts = 0;                     // Added by @:retry
    //     while (attempts < 3) {
    //         try {
    //             var result = API.get('/data/$id');
    //             saveToCache(id, result);
    //             trace('Completed fetchData');
    //             return result;
    //         } catch (e) { attempts++; }
    //     }
    //     throw "Failed after 3 attempts";
    // }
}
```

### What Haxe Macros Can Achieve

| Feature | Java | Ruby | Haxe with Macros | How |
|---------|------|------|------------------|-----|
| Static inheritance | ✅ | ✅ | ✅ | Generate delegating methods |
| Method hiding | ✅ | ✅ | ✅ | Check for existing methods |
| Polymorphic statics | ❌ | ✅ | ✅ | Runtime dispatch tables |
| Inheritance hooks | ❌ | ✅ | ✅ | Compile-time callbacks |
| Method versioning | ❌ | ❌ | ✅ | Generate multiple versions |
| Aspect-oriented statics | ❌ | ❌ | ✅ | Wrap methods with cross-cutting concerns |
| Compile-time validation | ❌ | ❌ | ✅ | Validate inheritance rules |
| Custom inheritance rules | ❌ | ❌ | ✅ | Define any pattern you want |

### The Power of Haxe's Approach

With macros, Haxe can:
1. **Replicate any language's inheritance model** - Java, C#, Ruby, Python, etc.
2. **Create new inheritance patterns** - Ones that don't exist in any language
3. **Mix and match approaches** - Combine the best of multiple languages
4. **Enforce project-specific rules** - Custom inheritance policies for your team
5. **Generate optimized code** - Macros run at compile-time, no runtime overhead

**Bottom line**: Haxe's "no static inheritance" rule is not a limitation - it's a blank canvas. With macros, you can implement ANY inheritance pattern, including ones more powerful than traditional OOP languages offer.

2. **Static Extensions (`using`)** - Most Idiomatic
   - Add functionality without inheritance
   - Works well with Haxe's functional features
   - Cleaner than trying to force inheritance

3. **Instance Methods** - When Appropriate
   - Convert to instance methods if polymorphism is needed
   - Use singleton pattern if single instance is required

4. **Direct Parent Reference** - Most Explicit
   - Always call `Parent.method()` explicitly
   - Clear but less convenient for API design

### Conclusion

The BasePresence pattern as originally envisioned won't work with simple inheritance due to Haxe's static method limitations. This is **confirmed by multiple sources**:
- Official Haxe documentation
- Stack Overflow discussions
- GitHub issues and bug reports
- Community forum consensus

While Java and C# offer more flexibility with static method inheritance and hiding, Haxe chose the strictest approach for clarity and cross-platform consistency.

**The current BehaviorTransformer pattern is actually aligned with community best practices** - using compile-time transformation (similar to build macros) to work within Haxe's constraints. Alternative patterns like static extensions (`using`) or macro-based code generation align better with Haxe's design philosophy than trying to force inheritance patterns that the language explicitly avoids.

**Bottom Line**: Our current approach is not a workaround - it's the idiomatic Haxe solution to this problem.

## Related Documentation

- [BehaviorTransformer Architecture](../03-compiler-development/BEHAVIOR_TRANSFORMER.md)
- [Phoenix Integration Patterns](./PHOENIX_INTEGRATION.md)
- [Standard Library Philosophy](../STANDARD_LIBRARY_PHILOSOPHY.md)
- [Macro-Time vs Runtime](../03-compiler-development/macro-time-vs-runtime.md)
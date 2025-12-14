# Phoenix.Presence Integration - Product Requirements Document

## Executive Summary

Phoenix.Presence is a distributed, real-time presence tracking system in Phoenix that presents unique compilation challenges due to its dual nature as both an external module and a behavior that injects local functions. This PRD defines the optimal Haxe API design and compilation strategy to generate idiomatic Elixir code while maintaining type safety.

## Problem Statement

### The Dual Nature Challenge

Phoenix.Presence operates in two distinct modes:

1. **External Module Mode**: When called from outside a Presence module (e.g., from LiveView)
2. **Injected Behavior Mode**: When called from inside a module that uses `use Phoenix.Presence`

The same Haxe code must compile to different Elixir patterns based on context:

```haxe
// Same Haxe code:
Presence.track(socket, "users", user_id, meta)

// Different Elixir output based on context:
// Outside Presence module → MyPresence.track(socket, "users", user_id, meta)
// Inside Presence module  → track(self(), socket, "users", user_id, meta)
```

### Why This Dual Nature Exists (Understanding `use` Macro)

When an Elixir module includes `use Phoenix.Presence`, it's not just importing functions - the macro literally **injects function definitions** into the module at compile time:

```elixir
defmodule MyAppWeb.Presence do
  use Phoenix.Presence, otp_app: :my_app  # <-- Injects functions!
  
  # These functions are now LOCAL to this module:
  # - track/5 (requires self() as first argument)
  # - update/5 (requires self() as first argument)
  # - untrack/4 (requires self() as first argument)
  # - list/1 (no self() needed)
  # - get_by_key/2 (no self() needed)
end
```

These injected functions:
- Are **local** to the module (not imported from Phoenix.Presence)
- Have **different signatures** than the external Phoenix.Presence functions
- Require `self()` to identify the tracker process for distributed synchronization

### The self() Requirement

`self()` is an Erlang/Elixir built-in that returns the current process's PID. Phoenix.Presence needs this because:

1. **Distributed Tracking**: Presence works across multiple nodes in a cluster
2. **Process Monitoring**: When a process dies, its presence is automatically removed
3. **CRDT Synchronization**: The PID identifies which tracker is making updates
4. **Fault Tolerance**: Each presence module manages its own tracker process

### Current Issues

1. **FunctionClauseError**: Generated code missing `self()` parameter causes runtime errors
   ```
   ** (FunctionClauseError) no function clause matching in Phoenix.Tracker.track/4
   The function expects 5 arguments (including self())
   ```

2. **Non-idiomatic output**: Remote calls used where local calls are expected
   ```elixir
   # Currently generates (WRONG):
   Phoenix.Presence.track(socket, "users", user_id, meta)
   
   # Should generate (inside presence module):
   track(self(), socket, "users", user_id, meta)
   ```

3. **Type safety vs flexibility**: Need to maintain Haxe's compile-time guarantees while supporting Elixir's dynamic behavior injection

## Design Principles

### 1. Idiomatic Elixir Generation
Generated code should be indistinguishable from hand-written Phoenix applications.

### 2. Transparent API
Users shouldn't need to know about the compilation complexity - the API should "just work".

### 3. Type Safety First
Maintain full type checking for all Presence operations.

### 4. Context Awareness
The compiler must track and respond to compilation context intelligently.

## Proposed Haxe API Design

### Core Extern Definition

```haxe
package phoenix;

/**
 * Phoenix.Presence extern for distributed presence tracking
 * 
 * This extern has special compilation behavior:
 * - Outside @:presence modules: Generates remote module calls
 * - Inside @:presence modules: Generates local function calls with self()
 */
@:native("Phoenix.Presence")
extern class Presence {
    // Channel-based tracking (most common)
    @:overload(function(socket: Dynamic, key: String, meta: Dynamic): Dynamic {})
    static function track(socket: Dynamic, topic: String, key: String, meta: Dynamic): Dynamic;
    
    // Process-based tracking
    static function trackPid(pid: Dynamic, topic: String, key: String, meta: Dynamic): Dynamic;
    
    // Update presence metadata
    @:overload(function(socket: Dynamic, key: String, meta: Dynamic): Dynamic {})
    static function update(socket: Dynamic, topic: String, key: String, meta: Dynamic): Dynamic;
    
    static function updatePid(pid: Dynamic, topic: String, key: String, meta: Dynamic): Dynamic;
    
    // Remove presence
    @:overload(function(socket: Dynamic, key: String): Dynamic {})
    static function untrack(socket: Dynamic, topic: String, key: String): Dynamic;
    
    static function untrackPid(pid: Dynamic, topic: String, key: String): Dynamic;
    
    // Query operations (no self() needed)
    static function list(topicOrSocket: Dynamic): Dynamic;
    static function getByKey(topicOrSocket: Dynamic, key: String): Array<Dynamic>;
}
```

### User-Facing Presence Module

```haxe
package myapp;

import phoenix.Presence;

/**
 * Application presence module using Phoenix.Presence behavior
 * 
 * The @:presence annotation triggers special compilation:
 * - Generates `use Phoenix.Presence, otp_app: :myapp`
 * - Transforms Presence.* calls to local function calls with self()
 */
@:presence
@:native("MyAppWeb.Presence")
class MyPresence {
    /**
     * Track a user's presence with typed metadata
     */
    public static function trackUser<T>(socket: Socket<T>, user: User): Socket<T> {
        var meta = {
            onlineAt: Date.now().getTime(),
            userName: user.name,
            userEmail: user.email
        };
        // Compiles to: track(self(), socket, "users", user_id, meta)
        return Presence.track(socket, "users", Std.string(user.id), meta);
    }
    
    /**
     * Update user's editing state
     */
    public static function updateUserEditing<T>(socket: Socket<T>, user: User, todoId: Null<Int>): Socket<T> {
        var meta = {
            editingTodoId: todoId,
            editingStartedAt: todoId != null ? Date.now().getTime() : null
        };
        // Compiles to: update(self(), socket, "users", user_id, meta)
        return Presence.update(socket, "users", Std.string(user.id), meta);
    }
    
    /**
     * List all online users
     */
    public static function listOnlineUsers(topic: String = "users"): Map<String, PresenceEntry> {
        // Compiles to: list(topic) - no self() needed
        return Presence.list(topic);
    }
}
```

### Usage from LiveView

```haxe
@:liveview
class TodoLive {
    function mount(params: Dynamic, session: Dynamic, socket: Socket): Socket {
        // Outside @:presence module - generates remote call
        // Compiles to: MyPresence.track_user(socket, user)
        socket = MyPresence.trackUser(socket, user);
        
        return socket.assign({
            currentUser: user,
            onlineUsers: MyPresence.listOnlineUsers()
        });
    }
    
    function handleEvent(event: String, params: Dynamic, socket: Socket): Socket {
        return switch(event) {
            case "start_editing":
                // Compiles to: MyPresence.update_user_editing(socket, user, todo_id)
                MyPresence.updateUserEditing(socket, socket.assigns.currentUser, params.todoId);
            default:
                socket;
        }
    }
}
```

## Compilation Strategy

### Context Detection

The compiler maintains an `isInPresenceModule` flag:

```haxe
// In ElixirCompiler.hx
public var isInPresenceModule: Bool = false;

public function compileClassImpl(classType: ClassType, ...) {
    this.isInPresenceModule = classType.meta.has(":presence");
    // ... compile the class
}
```

### AST Transformation Rules

In `ElixirASTBuilder.hx`, when detecting `Phoenix.Presence` method calls:

```haxe
if (classType.name == "Presence" && compiler?.isInPresenceModule) {
    switch(methodName) {
        case "track":
            if (args.length == 4) {
                // Transform: Presence.track(socket, topic, key, meta)
                // To: track(self(), socket, topic, key, meta)
                var selfCall = makeAST(ECall(null, "self", []));
                return ECall(null, "track", [selfCall].concat(args));
            }
        case "update":
            // Similar transformation with self()
        case "list", "getByKey":
            // No self() needed, just local call
            return ECall(null, snakeCase(methodName), args);
    }
}
```

### Generated Elixir Patterns

#### Inside @:presence Module
```elixir
defmodule MyAppWeb.Presence do
  use Phoenix.Presence, otp_app: :myapp
  
  def track_user(socket, user) do
    meta = %{
      online_at: System.system_time(:millisecond),
      user_name: user.name,
      user_email: user.email
    }
    # Local function call with self()
    track(self(), socket, "users", to_string(user.id), meta)
  end
  
  def list_online_users(topic \\ "users") do
    # Local function call without self()
    list(topic)
  end
end
```

#### Outside @:presence Module
```elixir
defmodule MyAppWeb.TodoLive do
  def mount(params, session, socket) do
    # Remote module call
    socket = MyPresence.track_user(socket, user)
    
    Phoenix.LiveView.assign(socket, %{
      current_user: user,
      online_users: MyPresence.list_online_users()
    })
  end
end
```

## Implementation Comparison

### Option 1: Context-Aware Compilation (RECOMMENDED) ✅

**Implementation**: Compiler tracks context and transforms AST accordingly

**Pros**:
- Type-safe throughout
- Transparent to users
- Generates idiomatic Elixir
- Follows Phoenix conventions exactly

**Cons**:
- Requires compiler modification
- Adds context-tracking complexity

**Similar to**: How we handle @:schema transformation

### Option 2: Pure `__elixir__()` Injection ❌

**Implementation**: Use `untyped __elixir__()` in Presence methods

**Pros**:
- Direct control over output
- No compiler changes needed

**Cons**:
- Loses type checking
- Requires `extern inline` for abstracts
- Not maintainable
- Users see Dynamic types

**Similar to**: LiveSocket abstract implementation

### Option 3: Wrapper Base Class ❌

**Implementation**: Create PresenceBase with proper implementations

**Pros**:
- No compiler magic
- Explicit behavior

**Cons**:
- Changes user API
- Not transparent
- Requires inheritance

**Similar to**: Classical OOP patterns (not idiomatic for Phoenix)

### Option 4: Build Macro Transformation ❌

**Implementation**: Use @:build macro to rewrite AST

**Pros**:
- Separation of concerns
- No compiler core changes

**Cons**:
- Complex macro code
- Hard to debug
- Not used elsewhere in project

**Similar to**: No existing patterns in our compiler

## Why Context-Aware Compilation is Essential (Not Optional)

### The Developer Ergonomics Problem Without It

Without contextual compilation, developers would face impossible choices:

#### Option 1: Manual self() injection (Terrible DX)
```haxe
// Users would have to use __elixir__() everywhere
@:presence
class MyPresence {
    static function trackUser(socket, user) {
        // Ugly! Loses type safety! Error-prone!
        return untyped __elixir__('track(self(), {0}, "users", {1}, {2})', 
            socket, user.id, meta);
    }
}
```
**Problems**: No type checking, easy to forget self(), not maintainable

#### Option 2: Different APIs (Confusing)
```haxe
// Two different classes for same functionality?
LocalPresence.track(socket, ...)   // Inside presence module
RemotePresence.track(socket, ...)  // Outside presence module
```
**Problems**: Which to use when? Confusing API, poor discoverability

#### Option 3: Runtime detection (Impossible)
```haxe
// Can't detect at runtime - already compiled!
if (isInsidePresenceModule()) {  // ❌ Too late!
    callWithSelf();
} else {
    callWithoutSelf();
}
```
**Problems**: Compilation already happened, runtime is too late

### What Happens Without Contextual Compilation

If we treat Phoenix.Presence as a normal extern without special handling:

```elixir
# Generated code (WRONG):
defmodule MyPresence do
  use Phoenix.Presence, otp_app: :my_app
  
  def track_user(socket, user) do
    # Tries to call external module instead of local function
    Phoenix.Presence.track(socket, "users", user.id, meta)
    # ❌ Runtime error: no function clause matching in Phoenix.Tracker.track/4
  end
end
```

The error occurs because:
1. `use Phoenix.Presence` injected a local `track/5` function
2. Our code is trying to call external `Phoenix.Presence.track/4`
3. The external function doesn't exist with that signature
4. Even if it did, it wouldn't have access to the local tracker process

### Why Context-Aware Compilation is the Only Good Solution

### 1. Semantic Correctness
Phoenix.Presence has **different semantics** based on context - it's not just a syntax transformation. The `use` macro fundamentally changes what functions are available and how they must be called.

### 2. Type Safety
Maintains full Haxe type checking while generating idiomatic Elixir. Users get compile-time guarantees without sacrificing runtime correctness.

### 3. Natural User Experience
Users write natural Haxe code:
```haxe
// Clean, intuitive API
Presence.track(socket, "users", user.id, meta)
```
Instead of:
```haxe
// Without contextual compilation - ugly workarounds
untyped __elixir__('track(self(), {0}, {1}, {2}, {3})', socket, "users", user.id, meta)
```

### 4. Framework Alignment
Matches exactly how Phoenix developers expect Presence to work. The generated Elixir is indistinguishable from hand-written Phoenix code.

### 5. Pattern Reusability
Can be applied to other Elixir behaviors with similar dual nature:
- **GenServer**: `handle_call`, `handle_cast` callbacks
- **Phoenix.Channel**: `join`, `handle_in` callbacks
- **Ecto.Repo**: Query functions when using `use Ecto.Repo`

### The Bottom Line

**Contextual compilation is not an optimization or a nice-to-have - it's essential for:**
- Generating correct code that actually works
- Providing a usable API that developers can understand
- Maintaining type safety without sacrificing functionality
- Producing idiomatic Elixir that Phoenix developers recognize

Without it, the Phoenix.Presence integration would be effectively unusable, requiring developers to understand Phoenix internals and write error-prone workarounds.

## Technical Requirements

### Must Have
- [x] Detect @:presence annotation on classes
- [x] Track compilation context (isInPresenceModule flag)
- [x] Transform Presence.track/update/untrack to local calls with self()
- [x] Generate remote calls when outside @:presence modules
- [ ] Fix control flow to prevent @:native override
- [ ] Comprehensive test coverage

### Should Have
- [ ] Support all Presence method overloads
- [ ] Type-safe metadata structures
- [ ] Clear error messages for incorrect usage
- [ ] Documentation with examples

### Nice to Have
- [ ] Typed PresenceEntry structures
- [ ] Helper functions for common patterns
- [ ] Integration with Phoenix.PubSub for presence events

## Migration Path

### For Existing Code
1. Add @:presence annotation to Presence modules
2. Update import statements to use phoenix.Presence
3. No other code changes required - API remains the same

### For New Projects
1. Use the patterns shown in this PRD
2. Leverage type-safe metadata structures
3. Follow idiomatic Phoenix presence patterns

## Testing Strategy

### Unit Tests
- Test context detection (isInPresenceModule flag)
- Test AST transformation for each Presence method
- Test that non-Presence calls aren't affected

### Integration Tests
- Todo-app presence functionality
- Multiple presence modules in same project
- Presence calls from different contexts

### Regression Tests
- Ensure fix doesn't break existing extern handling
- Verify other @:native classes still work correctly

## Success Metrics

1. **No Runtime Errors**: FunctionClauseError eliminated
2. **Idiomatic Output**: Generated Elixir indistinguishable from hand-written
3. **Type Safety**: Full compile-time checking maintained
4. **User Satisfaction**: No API changes required, "just works"
5. **Pattern Reusability**: Can apply to other similar behaviors

## Future Considerations

### Other Behaviors with Dual Nature
- GenServer callbacks (handle_call, handle_cast)
- Phoenix.Channel callbacks (join, handle_in)
- Ecto.Schema callbacks (changeset, validate)

### Generalized Context System
Consider creating a generalized context system for behaviors:
```haxe
@:behavior("Phoenix.Presence")
@:behaviorConfig({otp_app: ":myapp"})
class MyPresence {
    @:local  // Annotation to mark local calls
    @:inject("self()")  // What to inject
    static function track(...) { }
}
```

## Conclusion

The context-aware compilation approach for Phoenix.Presence provides the best balance of type safety, idiomatic code generation, and user experience. It introduces a new pattern to our compiler - **context-sensitive compilation** - that will be valuable for other Elixir behaviors with similar characteristics.

The implementation is straightforward: fix the control flow in ElixirASTBuilder to ensure Phoenix.Presence handling takes precedence over generic @:native handling. The infrastructure is already in place; we just need to ensure proper execution order.

## References

- [Phoenix.Presence Documentation](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
- [Phoenix.Presence Implementation Guide](./PHOENIX_PRESENCE_INTEGRATION.md)
- [Compiler AST Transformation Patterns](./AST_TRANSFORMATION_PATTERNS.md)
- [Elixir Behaviors and Callbacks](https://elixir-lang.org/getting-started/typespecs-and-behaviours.html#behaviours)
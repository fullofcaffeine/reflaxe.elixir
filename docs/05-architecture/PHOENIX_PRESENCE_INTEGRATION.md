# Phoenix.Presence Integration Guide

## Overview

Phoenix.Presence is a distributed, real-time presence tracking system that requires special handling in the Reflaxe.Elixir compiler due to its unique function injection mechanism.

## The Challenge: self() Requirement

### How Phoenix.Presence Works

When you use `use Phoenix.Presence` in an Elixir module, Phoenix injects local functions into your module. These injected functions have different signatures than the external Phoenix.Presence module functions:

**External calls (from LiveView/Channel):**
```elixir
# Called from outside a Presence module
Phoenix.Presence.track(socket, topic, key, meta)
```

**Internal calls (inside a Presence module):**
```elixir
defmodule MyAppWeb.Presence do
  use Phoenix.Presence, otp_app: :my_app
  
  def track_user(socket, user_id) do
    # Inside the module, track() is a local injected function
    # It requires self() as the first argument!
    track(self(), socket, "users", user_id, %{})
  end
end
```

### What is self()?

`self()` is an Erlang/Elixir built-in function that returns the PID (Process ID) of the current process. In Phoenix.Presence:

- It identifies which tracker process is handling the presence
- It's required for the internal CRDT (Conflict-free Replicated Data Type) synchronization
- It ensures presence updates are properly distributed across nodes

## The Compiler Solution

### Detection: @:presence Annotation

The compiler detects Presence modules through the `@:presence` annotation:

```haxe
@:presence
class TodoPresence {
    // This class will use Phoenix.Presence behavior
}
```

This compiles to:
```elixir
defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, otp_app: :todo_app
  # ...
end
```

### Transformation: Local Calls with self()

When inside a `@:presence` module, the compiler must transform:

**Haxe code:**
```haxe
Presence.track(socket, "users", userId, meta);
```

**Into Elixir:**
```elixir
track(self(), socket, "users", user_id, meta)
```

Note the transformation:
1. Remove module prefix (`Presence.` → local call)
2. Add `self()` as first argument
3. Convert to snake_case

## Implementation Details

### Compiler Context Tracking

The ElixirCompiler maintains a flag to track when compiling inside a @:presence module:

```haxe
public var isInPresenceModule: Bool = false;

public function compileClassImpl(classType: ClassType, ...) {
    this.isInPresenceModule = classType.meta.has(":presence");
    // ... compile the class
}
```

### AST Transformation

In ElixirASTBuilder, when detecting Phoenix.Presence method calls:

```haxe
if (classType.name == "Presence" && 
    compiler != null && 
    compiler.isInPresenceModule) {
    
    switch(methodName) {
        case "track":
            // Insert self() as first argument
            var selfCall = makeAST(ECall(null, "self", []));
            var argsWithSelf = [selfCall].concat(args);
            return ECall(null, "track", argsWithSelf);
            
        case "list":
            // list() doesn't need self()
            return ECall(null, "list", args);
    }
}
```

## Method-Specific Behavior

### Methods Requiring self()

These methods need `self()` as the first argument when called inside a Presence module:

- `track(socket, topic, key, meta)` → `track(self(), socket, topic, key, meta)`
- `update(socket, topic, key, meta)` → `update(self(), socket, topic, key, meta)`
- `untrack(socket, topic, key)` → `untrack(self(), socket, topic, key)`

### Methods NOT Requiring self()

These methods work the same way inside and outside:

- `list(topic)` - Returns all presences for a topic
- `get_by_key(topic, key)` - Gets specific presence

## Common Patterns

### 1. Single Presence per User

Track each user once with updateable metadata:

```haxe
@:presence
class UserPresence {
    public static function trackUser<T>(socket: Socket<T>, user: User): Socket<T> {
        var meta = {
            onlineAt: Date.now(),
            status: "active"
        };
        return Presence.track(socket, "users", Std.string(user.id), meta);
    }
    
    public static function updateStatus<T>(socket: Socket<T>, userId: Int, status: String): Socket<T> {
        return Presence.update(socket, "users", Std.string(userId), {status: status});
    }
}
```

### 2. Presence with Editing State

Track what users are currently editing:

```haxe
public static function updateEditing<T>(socket: Socket<T>, user: User, todoId: Null<Int>): Socket<T> {
    var meta = {
        editingTodoId: todoId,
        editingStartedAt: todoId != null ? Date.now() : null
    };
    return Presence.update(socket, "users", Std.string(user.id), meta);
}
```

### 3. Getting Online Users

```haxe
public static function getOnlineUsers(socket: Dynamic): Array<UserPresence> {
    var presences = Presence.list(socket);
    // Process presences map to extract user information
    return processPresences(presences);
}
```

## Troubleshooting

### FunctionClauseError: no function clause matching

**Error:**
```
** (FunctionClauseError) no function clause matching in Phoenix.Tracker.track/5
```

**Cause:** The generated code is calling `track(socket, ...)` without `self()` when inside a Presence module.

**Solution:** Ensure the `@:presence` annotation is applied to the class and the compiler is detecting it correctly.

### Presence Not Updating

**Issue:** Presence updates aren't being reflected in real-time.

**Common Causes:**
1. Not subscribing to the presence topic in the LiveView/Channel
2. Using track/untrack instead of update for status changes
3. Topic mismatch between track and list calls

**Solution:** 
- Use consistent topics
- Subscribe to presence events in mount: `Phoenix.PubSub.subscribe(pubsub, "presence:users")`
- Use update() for metadata changes, not track/untrack cycles

## Testing Presence

### Unit Testing

```haxe
@:test
class PresenceTest {
    public function testTrackUser() {
        var socket = TestHelper.createSocket();
        var user = {id: 1, name: "Test User"};
        
        socket = UserPresence.trackUser(socket, user);
        
        var presences = Presence.list(socket);
        Assert.isTrue(Reflect.hasField(presences, "1"));
    }
}
```

### Integration Testing

```elixir
defmodule TodoAppWeb.PresenceTest do
  use TodoAppWeb.ConnCase
  
  test "tracks user presence", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "0 users online"
    
    # Simulate user joining
    send(view.pid, {:presence_diff, ...})
    
    assert render(view) =~ "1 user online"
  end
end
```

## Best Practices

1. **Use a dedicated Presence module** - Don't mix presence logic with other concerns
2. **Consistent topic naming** - Use predictable patterns like "users", "rooms:#{room_id}"
3. **Metadata immutability** - Always return new metadata maps, don't mutate
4. **Graceful degradation** - Handle cases where presence tracking fails
5. **Efficient updates** - Use update() instead of track/untrack for status changes
6. **Clean up on unmount** - Ensure presence is removed when components unmount

## Architecture Benefits

The separation between external and internal Presence calls provides:

- **Process isolation** - Each Presence module manages its own tracker process
- **Fault tolerance** - If one tracker crashes, others continue working
- **Distribution** - Presence state is replicated across cluster nodes
- **Performance** - Local function calls are faster than remote module calls
- **Flexibility** - Different modules can have different presence strategies

## Related Documentation

- [Phoenix.Presence Hexdocs](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
- [Phoenix PubSub Integration](./PHOENIX_PUBSUB_INTEGRATION.md)
- [LiveView State Management](./LIVEVIEW_STATE_MANAGEMENT.md)
- [Compiler AST Transformation](./AST_TRANSFORMATION_PATTERNS.md)
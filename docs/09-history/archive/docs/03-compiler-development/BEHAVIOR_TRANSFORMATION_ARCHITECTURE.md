# Behavior Transformation Architecture

## Overview

The Behavior Transformation system provides a pluggable, extensible architecture for transforming method calls based on Elixir behaviors (like Phoenix.Presence, GenServer, etc.). This system was introduced to replace hardcoded logic in the main compiler with a clean, modular approach.

## Key Components

### 1. IBehaviorTransformer Interface
```haxe
interface IBehaviorTransformer {
    function transformMethodCall(
        className: String,
        methodName: String, 
        args: Array<ElixirAST>,
        isStatic: Bool
    ): Null<ElixirAST>;
}
```

Each behavior-specific transformer implements this interface to handle its unique transformation rules.

### 2. BehaviorTransformer Registry
```haxe
class BehaviorTransformer {
    var registry: Map<String, IBehaviorTransformer>;
    var activeBehavior: Null<String>;
    
    function registerTransformer(behaviorName: String, transformer: IBehaviorTransformer);
    function checkAndActivateBehavior(classType: ClassType): Null<String>;
    function transformMethodCall(...): Null<ElixirAST>;
}
```

The main coordinator that:
- Maintains a registry of behavior-specific transformers
- Detects when a class uses a behavior (via metadata like `@:presence`)
- Routes method calls to the appropriate transformer

### 3. PresenceBehaviorTransformer
```haxe
class PresenceBehaviorTransformer implements IBehaviorTransformer {
    function transformMethodCall(...): Null<ElixirAST> {
        // Phoenix.Presence specific transformations
        // e.g., inject self() for track/update/untrack
    }
}
```

Example behavior transformer that handles Phoenix.Presence specifics:
- Injects `self()` as first argument for `track()`, `update()`, `untrack()`
- Converts camelCase to snake_case
- Handles method aliases (e.g., `trackPid` → `track`)

## How It Works

### 1. Registration Phase
During compiler initialization:
```haxe
// In ElixirCompiler constructor
var behaviorTransformer = new BehaviorTransformer();
behaviorTransformer.registerTransformer("presence", new PresenceBehaviorTransformer());
behaviorTransformer.registerTransformer("genserver", new GenServerBehaviorTransformer());
ElixirASTBuilder.behaviorTransformer = behaviorTransformer;
```

### 2. Activation Phase
When compiling a class:
```haxe
// In buildClassAST
var previousBehavior = behaviorTransformer?.activeBehavior;
var behaviorName = behaviorTransformer?.checkAndActivateBehavior(classType);

// Build the class with behavior active
var ast = buildModule(...);

// Restore previous behavior
behaviorTransformer.activeBehavior = previousBehavior;
```

### 3. Transformation Phase
When encountering method calls during AST building:
```haxe
// In ElixirASTBuilder.hx
case TCall(e, el):
    if (behaviorTransformer != null) {
        var transformedCall = behaviorTransformer.transformMethodCall(
            className, methodName, args, isStatic
        );
        if (transformedCall != null) {
            return transformedCall.def;
        }
    }
    // Normal call processing...
```

## Example: Phoenix.Presence Transformation

### Input (Haxe)
```haxe
@:presence
class TodoPresence {
    public static function trackUser(socket: Socket, user: User): Socket {
        return Presence.track(socket, user.id, metadata);
    }
}
```

### Transformation Process
1. **Detection**: `@:presence` metadata detected on TodoPresence
2. **Activation**: PresenceBehaviorTransformer activated
3. **Method Call**: `Presence.track()` encountered
4. **Transformation**: PresenceBehaviorTransformer injects `self()`

### Output (Elixir)
```elixir
defmodule TodoPresence do
  use Phoenix.Presence, otp_app: :todo_app
  
  def track_user(socket, user) do
    track(self(), socket, user_id, metadata)  # self() injected!
  end
end
```

## Adding New Behavior Transformers

### Step 1: Create Transformer Class
```haxe
class MyBehaviorTransformer implements IBehaviorTransformer {
    public function new() {}
    
    public function transformMethodCall(
        className: String,
        methodName: String,
        args: Array<ElixirAST>,
        isStatic: Bool
    ): Null<ElixirAST> {
        // Your transformation logic
        return transformedAST;
    }
}
```

### Step 2: Register with System
```haxe
// In ElixirCompiler constructor
behaviorTransformer.registerTransformer("mybehavior", new MyBehaviorTransformer());
```

### Step 3: Add Metadata Detection
```haxe
// In BehaviorTransformer.checkAndActivateBehavior
case ":mybehavior": "mybehavior";
```

## Benefits

### 1. Separation of Concerns
- Main compiler focuses on general compilation
- Behavior-specific logic isolated in dedicated transformers
- Clear boundaries between different behaviors

### 2. Extensibility
- New behaviors can be added without modifying core compiler
- Each behavior transformer is independent
- Plugin-like architecture for future extensions

### 3. Maintainability
- Behavior-specific logic is easy to find and modify
- Changes to one behavior don't affect others
- Clear, documented transformation rules

### 4. Testing
- Each transformer can be tested independently
- Clear input/output contracts
- Regression tests for specific behaviors

## Current Implementations

### Phoenix.Presence
- **File**: `src/reflaxe/elixir/behaviors/PresenceBehaviorTransformer.hx`
- **Transforms**: Injects `self()` for track/update/untrack methods
- **Metadata**: `@:presence`

### GenServer (Planned)
- **Transforms**: Handle call/cast/info callbacks
- **Metadata**: `@:genserver`

### Supervisor (Planned)
- **Transforms**: Child spec generation
- **Metadata**: `@:supervisor`

## Testing

### Unit Tests
```haxe
// test/tests/PhoenixPresenceBehavior/Main.hx
@:presence
class TestPresence {
    public static function trackUser(socket, userId, meta) {
        return Presence.track(socket, userId, meta);
    }
}
```

Expected output verifies `self()` injection:
```elixir
def track_user(socket, user_id, meta) do
  track(self(), socket, user_id, meta)
end
```

### Integration Tests
The todo-app example uses TodoPresence with real Phoenix.Presence to validate the entire transformation pipeline.

## Future Enhancements

1. **Dynamic Registration**: Allow behaviors to be registered via configuration
2. **Metadata-Driven Configuration**: Use metadata to configure transformation rules
3. **Composition**: Support multiple behaviors on a single class
4. **Runtime Validation**: Ensure transformed code matches behavior contracts
5. **Documentation Generation**: Auto-generate behavior usage documentation

## Related Documentation

- [AST Pipeline Architecture](../05-architecture/AST_PIPELINE_MIGRATION.md)
- [Compiler Development Guide](AGENTS.md)
- [Phoenix Integration Patterns](../06-guides/phoenix-integration.md)
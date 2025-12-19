# Phoenix Framework Integration Patterns

## 🌟 Framework-Agnostic Design Philosophy

**CRITICAL RULE**: The compiler generates plain Elixir by default. Framework conventions are applied via annotations, not hardcoded assumptions.

### Design Pattern
```haxe
// ✅ CORRECT: Framework conventions via annotations
@:native("AppNameWeb.TodoLive")
@:liveview
class TodoLive {}

// ❌ WRONG: Hardcoded framework detection in compiler
// Don't make assumptions about Phoenix in core compiler
```

## 📁 File Naming & Placement

### Idiomatic Phoenix File Placement
```
TodoApp.hx @:application   → lib/todo_app/application.ex     # Phoenix convention
TodoAppRouter.hx @:router  → lib/todo_app_web/router.ex      # Always router.ex
UserLive.hx @:liveview     → lib/todo_app_web/live/user_live.ex
Endpoint.hx @:endpoint     → lib/todo_app_web/endpoint.ex    # Always endpoint.ex
Todo.hx @:schema           → lib/todo_app/schemas/todo.ex    # Domain models
```

### Snake_Case Conversion Rules
- **ALL files get proper Elixir naming**: TodoApp → todo_app
- **Package-to-directory mapping**: Haxe packages become snake_case directories  
- **Single source of truth**: `getComprehensiveNamingRule()` handles ALL cases

## 🔧 Annotation System

### Core Annotations
- **@:liveview** - Phoenix LiveView components
- **@:router** - Phoenix router with DSL support
- **@:schema** - Ecto schema with changeset generation
- **@:endpoint** - Phoenix endpoint configuration
- **@:controller** - Phoenix controller with actions

### LiveView Patterns
```haxe
import elixir.types.Term;
import phoenix.LiveSocket;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef TodoAssigns = {
    todos: Array<Todo>
}

typedef TodoEventParams = {
    ?title: String,
    ?id: Int
}

@:liveview
class TodoLive {
    public static function mount(_params: Term, _session: Term, socket: Socket<TodoAssigns>): MountResult<TodoAssigns> {
        var liveSocket: LiveSocket<TodoAssigns> = cast socket;
        liveSocket = LiveView.assignMultiple(liveSocket, {todos: []});
        return Ok(liveSocket);
    }
    
    @:native("handle_event")
    public static function handle_event(event: String, params: TodoEventParams, socket: Socket<TodoAssigns>): HandleEventResult<TodoAssigns> {
        var liveSocket: LiveSocket<TodoAssigns> = cast socket;

        return switch (event) {
            case "add_todo": NoReply(liveSocket);
            case "toggle_todo": NoReply(liveSocket);
            case _: NoReply(liveSocket);
        };
    }
}
```

## 🎯 Integration Benefits

### Compile-Time Safety
- **Type-safe assigns**: No runtime assign key errors
- **Exhaustive pattern matching**: Handle all LiveView events
- **Framework compliance**: Generated code follows Phoenix conventions exactly

### Development Experience  
- **IDE support**: Full autocomplete and navigation
- **Error prevention**: Catch framework integration issues at compile time
- **Documentation**: Self-documenting through type signatures

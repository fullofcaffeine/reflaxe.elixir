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
@:liveview
class TodoLive {
    function mount(params: Dynamic, session: Dynamic, socket: Socket): Socket {
        return socket.assign("todos", []);
    }
    
    function handleEvent(event: String, params: Dynamic, socket: Socket): Socket {
        return switch(event) {
            case "add_todo": addTodo(params, socket);
            case "toggle_todo": toggleTodo(params, socket);
            default: socket;
        }
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
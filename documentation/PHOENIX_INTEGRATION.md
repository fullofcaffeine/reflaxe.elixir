# Phoenix Framework Integration Guide

## Philosophy: 100% Type Safety Through Haxe

Reflaxe.Elixir's philosophy for Phoenix applications:
- **Type safety everywhere** → Every line of code must be type-checked
- **Pure Haxe preferred** → Write implementations in Haxe when possible
- **Typed externs welcome** → Type-safe access to Phoenix and third-party libraries
- **No untyped code** → Avoid `Dynamic` and `__elixir__()` except in emergencies

The goal is 100% type-safe applications leveraging both Haxe and the Elixir ecosystem.

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│           Haxe Application Code             │
│  (LiveView, Schemas, Contexts, Business)    │
└─────────────────┬───────────────────────────┘
                  │ Compiles to
                  ▼
┌─────────────────────────────────────────────┐
│         Generated Elixir Modules            │
│    (lib/*.ex, lib/app_web/live/*.ex)        │
└─────────────────┬───────────────────────────┘
                  │ Uses
                  ▼
┌─────────────────────────────────────────────┐
│      Phoenix Framework Infrastructure       │
│  (Endpoint, Gettext, TodoAppWeb helpers)    │
└─────────────────────────────────────────────┘
```

## Everything Should Be in Haxe

### ✅ Write Everything in Haxe

1. **LiveView Modules**
   ```haxe
   @:liveview
   class TodoLive {
       public static function mount(params, session, socket) {
           // Your LiveView logic
       }
   }
   ```

2. **Ecto Schemas**
   ```haxe
   @:schema("todos")
   class Todo {
       @:primary_key
       public var id: Int;
       
       @:field({type: "string"})
       public var title: String;
   }
   ```

3. **Contexts (Business Logic)**
   ```haxe
   @:context
   class Todos {
       public static function list_todos(): Array<Todo> {
           return Repo.all(Todo);
       }
   }
   ```

4. **Migrations**
   ```haxe
   @:migration("todos")
   class CreateTodos {
       public function up(): Void {
           createTable("todos")
               .addColumn("title", "string")
               .timestamps();
       }
   }
   ```

5. **GenServers/Agents**
   ```haxe
   @:genserver
   class TodoCache {
       public static function init(args: Dynamic): Dynamic {
           return {ok: new Map<Int, Todo>()};
       }
   }
   ```

6. **Phoenix Channels**
   ```haxe
   @:channel
   class TodoChannel {
       public static function join(topic: String, payload: Dynamic, socket: Socket): Dynamic {
           return {ok: socket};
       }
   }
   ```

7. **Router Configuration**
   ```haxe
   @:router
   class TodoAppRouter {
       @:route({method: "LIVE", path: "/todos", controller: "TodoLive", action: "index"})
       public static function todosIndex(): Void {}
   }
   ```

## What Remains as Elixir (Absolute Minimum)

### 📦 Only Build Configuration

**The ONLY acceptable manual Elixir files are those that literally cannot be generated:**

1. **mix.exs** - Build tool configuration (though this could potentially be generated in the future)
2. **config/*.exs** - Environment configs (could be templated from Haxe in the future)

**Everything else MUST be in Haxe:**
- **Endpoint** → Use `@:endpoint` annotation in Haxe
- **Gettext** → Implement type-safe i18n wrapper in Haxe
- **Core Components** → HXX components with full type safety
- **Error Handlers** → Type-safe error pages in Haxe
- **Web Module Helpers** → Generated from Haxe abstractions

### Using Typed Externs

**Extern definitions provide type-safe access to the Elixir ecosystem.**

Appropriate uses:
1. **Third-party libraries** - Type-safe wrappers for Elixir packages
2. **Phoenix framework** - Access to Phoenix modules and helpers
3. **Migration path** - Gradual migration from existing Elixir code
4. **OTP features** - Complex BEAM features not yet in Reflaxe

Best practices for externs:
```haxe
// Type-safe extern for third-party library
@:native("SomeElixirLib")
extern class SomeElixirLib {
    // Provide complete type signatures
    static function process(data: Array<String>): Result<ProcessedData, Error>;
    
    // Document the Elixir library version
    // @elixirVersion 1.2.3
}
```

For application code in greenfield projects, prefer pure Haxe implementations over externs.

## Integration Patterns

### Pattern 1: Extern Definitions

For existing Elixir modules, create extern definitions:

```haxe
// std/phoenix/TodoAppWeb.hx
@:native("TodoAppWeb")
extern class TodoAppWeb {
    static function controller(): Dynamic;
    static function view(): Dynamic;
    static function live_view(): Dynamic;
    static function router(): Dynamic;
}
```

Usage in Haxe:
```haxe
import phoenix.TodoAppWeb;

@:liveview
class MyLive {
    // TodoAppWeb is available for use
}
```

### Pattern 2: Compile-Time Annotations with Framework Conventions

Use @:native annotations to apply Phoenix module naming conventions:

```haxe
@:native("TodoAppWeb.TodoLive")    // Explicit Phoenix convention
@:liveview
class TodoLive {
    // Generates TodoAppWeb.TodoLive module in lib/todo_app_web/live/todo_live.ex
}

@:native("TodoAppWeb.UserController")
@:controller
class UserController {
    // Generates TodoAppWeb.UserController module
}

@:native("TodoAppWeb.RoomChannel")
@:channel
class RoomChannel {
    // Generates TodoAppWeb.RoomChannel module
}
```

**Framework-Agnostic Design**: The compiler generates plain Elixir by default. Phoenix conventions are applied via @:native annotations, ensuring compatibility with any Elixir application pattern (Phoenix, Nerves, pure OTP).

### Pattern 3: Mixed Projects

For gradual migration or hybrid projects:

```
lib/
├── todo_app/           # Haxe-generated business logic
│   ├── todos.ex        # From Haxe Context
│   └── schemas/
│       └── todo.ex     # From Haxe Schema
├── todo_app_web/       # Mixed Haxe + Elixir
│   ├── endpoint.ex     # Manual Elixir (infrastructure)
│   ├── gettext.ex      # Manual Elixir (infrastructure)
│   ├── router.ex       # Generated from Haxe
│   └── live/
│       └── todo_live.ex # Generated from Haxe
```

## File Location Conventions

The compiler generates files following Phoenix conventions:

| Haxe Class | Annotation | Generated Location |
|------------|------------|-------------------|
| TodoAppRouter | @:router | lib/todo_app_web/router.ex |
| TodoLive | @:liveview | lib/todo_app_web/live/todo_live.ex |
| UserController | @:controller | lib/todo_app_web/controllers/user_controller.ex |
| Todo | @:schema | lib/todo_app/schemas/todo.ex |
| Todos | @:context | lib/todo_app/todos.ex |
| TodoChannel | @:channel | lib/todo_app_web/channels/todo_channel.ex |

## Working with Phoenix Features

### LiveView Lifecycle

```haxe
@:liveview
class TodoLive {
    // Phoenix callbacks are static functions
    public static function mount(params: Dynamic, session: Dynamic, socket: Socket): Dynamic {
        return socket.assign({
            todos: Todos.list_todos()
        });
    }
    
    public static function handle_event(event: String, params: Dynamic, socket: Socket): Dynamic {
        return switch(event) {
            case "delete": delete_todo(params, socket);
            case "toggle": toggle_todo(params, socket);
            default: {noreply: socket};
        };
    }
    
    public static function render(assigns: Dynamic): String {
        return HXX.compile('
            <div>
                <.todo_list todos={assigns.todos} />
            </div>
        ');
    }
}
```

### Ecto Integration

```haxe
// Define schema
@:schema("todos")
class Todo {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", null: false})
    public var title: String;
    
    @:timestamps
    public var inserted_at: Date;
    public var updated_at: Date;
}

// Use in context
@:context
class Todos {
    public static function create_todo(attrs: Dynamic): Dynamic {
        var changeset = Todo.changeset(new Todo(), attrs);
        return Repo.insert(changeset);
    }
}
```

### Router DSL

```haxe
@:router
class AppRouter {
    // LiveView routes
    @:route({method: "LIVE", path: "/", controller: "PageLive", action: "index"})
    public static function root(): Void {}
    
    // REST routes
    @:route({method: "GET", path: "/api/todos", controller: "TodoController", action: "index"})
    public static function apiTodos(): Void {}
    
    // Resources
    @:resources("/users", "UserController")
    public static function userResources(): Void {}
}
```

## Benefits of This Approach

1. **Type Safety** for all business logic
2. **Phoenix Ecosystem** access via externs
3. **Gradual Migration** from existing Elixir projects
4. **Framework Updates** don't break Haxe code
5. **Clear Boundaries** between app and framework
6. **IDE Support** for both Haxe and Elixir files

## Migration Strategy

### From Existing Phoenix App

1. **Phase 1: Setup**
   - Add Reflaxe.Elixir to project
   - Create extern definitions for existing modules
   - Set up build pipeline

2. **Phase 2: New Features in Haxe**
   - Write all new features in Haxe
   - Use externs to access existing Elixir

3. **Phase 3: Gradual Conversion**
   - Convert contexts to Haxe
   - Migrate schemas to Haxe
   - Convert LiveViews to Haxe

4. **Phase 4: Full Haxe (Optional)**
   - Convert remaining modules
   - Keep minimal Elixir infrastructure

### From New Project

1. Generate Phoenix project: `mix phx.new app`
2. Add Reflaxe.Elixir dependency
3. Write all application code in Haxe
4. Keep Phoenix infrastructure as-is

## Common Patterns

### Accessing Phoenix Helpers

```haxe
// Define extern
@:native("Phoenix.HTML")
extern class PhoenixHTML {
    static function raw(html: String): Dynamic;
    static function safe_to_string(safe: Dynamic): String;
}

// Use in Haxe
var safeHtml = PhoenixHTML.raw("<b>Bold text</b>");
```

### Using Plug

```haxe
@:native("Plug.Conn")
extern class Conn {
    function put_status(code: Int): Conn;
    function json(data: Dynamic): Conn;
    function render(template: String, assigns: Dynamic): Conn;
}
```

### PubSub Integration

```haxe
@:native("Phoenix.PubSub")
extern class PubSub {
    static function broadcast(pubsub: Dynamic, topic: String, message: Dynamic): Dynamic;
    static function subscribe(pubsub: Dynamic, topic: String): Dynamic;
}
```

## Testing

### ExUnit Tests in Haxe

```haxe
@:exunit
class TodoTest extends TestCase {
    @:test
    function test_create_todo() {
        var todo = Todos.create_todo({title: "Test"});
        Assert.equals("Test", todo.title);
    }
}
```

### LiveView Testing

```haxe
@:exunit  
class TodoLiveTest extends ConnCase {
    @:test
    function test_mount() {
        var conn = get(build_conn(), "/todos");
        var html = html_response(conn, 200);
        Assert.contains(html, "Todo List");
    }
}
```

## Troubleshooting

### Common Issues

1. **Module not found**: Ensure extern definitions match Elixir module names
2. **Compilation errors**: Check annotation syntax and required fields
3. **Runtime errors**: Verify Phoenix callbacks return expected formats
4. **Asset pipeline**: Ensure Haxe-generated JS is included in Phoenix

### Debug Tips

- Use `IO.inspect()` in generated Elixir code
- Check generated files in `lib/` directory
- Verify Phoenix expectations with `mix phx.routes`
- Test with `iex -S mix phx.server` for interactive debugging

## Best Practices

1. **Keep infrastructure minimal** - Only Phoenix boilerplate in Elixir
2. **Use annotations consistently** - Follow established patterns
3. **Document externs** - Explain what each extern provides
4. **Test both layers** - Unit test Haxe, integration test with Phoenix
5. **Version control generated files** - For deployment consistency

## Future Enhancements

- [ ] Hot code reload for Haxe changes
- [ ] Phoenix LiveView 0.20+ features
- [ ] HEEx template validation
- [ ] Phoenix component library
- [ ] Automatic extern generation from Elixir modules
# Reflaxe.Elixir Annotation System

**Complete guide to all annotations supported by Reflaxe.Elixir, their usage, implementation details, and Phoenix framework integration.**

## 🎯 Overview

The annotation system provides declarative configuration for Haxe classes to generate idiomatic Elixir code following Phoenix and OTP conventions. All annotations are compile-time only and disappear after code generation.

### Core Principle: Type Safety + Convention Adherence

Every annotation ensures:
- **Type-safe compilation** - No Dynamic types in generated code unless framework requires it
- **Framework convention compliance** - Generated files follow exact Phoenix/OTP directory structure  
- **Idiomatic code generation** - Output looks hand-written by Elixir experts
- **Zero runtime overhead** - Pure compile-time transformation

## 📋 Supported Annotations

### Phoenix Framework Annotations

#### `@:endpoint` - Phoenix HTTP Endpoint
**Purpose**: HTTP endpoint configuration with plug pipeline and socket setup.

**Generated File**: `lib/{app_name}_web/endpoint.ex`

**Example**:
```haxe
@:native("TodoAppWeb.Endpoint")
@:endpoint
@:appName("TodoApp")
class Endpoint {
    // Marker class - actual Phoenix.Endpoint implementation is generated
}
```

**Generated Output**:
```elixir
defmodule TodoAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :todoapp

  @session_options [
    store: :cookie,
    key: "_todoapp_key",
    signing_salt: "generated_salt"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
  
  # Standard Phoenix plugs configuration
  plug Plug.Static, at: "/", from: :todoapp, gzip: false
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  # ... complete Phoenix endpoint setup
end
```

#### `@:router` - Phoenix Router DSL
**Purpose**: URL routing with type-safe route helpers and pipeline configuration.

**Generated File**: `lib/{app_name}_web/router.ex`

**Example**:
```haxe
@:native("TodoAppWeb.Router")
@:router
@:appName("TodoApp")
@:routes([
    @:route(Get, "/", TodoLive, index),
    @:route(Get, "/users/:id", UserController, show),
    @:route(Post, "/api/todos", TodoController, create)
])
class Router {
    // Generated route helper functions for type safety
    public static function todo_path(): String { return "/"; }
    public static function user_path(id: String): String { return '/users/${id}'; }
    public static function api_todo_path(): String { return "/api/todos"; }
}
```

**Generated Output**:
```elixir
defmodule TodoAppWeb.Router do
  use TodoAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TodoAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", TodoAppWeb do
    pipe_through :browser
    
    live "/", TodoLive, :index
    get "/users/:id", UserController, :show
  end

  scope "/api", TodoAppWeb do
    pipe_through :api
    
    post "/todos", TodoController, :create
  end
end
```

#### `@:liveview` - Phoenix LiveView Component
**Purpose**: Real-time interactive UI components with WebSocket communication.

**Generated File**: `lib/{app_name}_web/live/{name}_live.ex`

**Example**:
```haxe
@:liveview
@:appName("TodoApp")
class TodoLive {
    public static function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        var todos = Todos.list_todos();
        return LiveView.assign(socket, {todos: todos, new_todo: ""});
    }
    
    public static function handle_event(event: String, params: Dynamic, socket: Dynamic): Dynamic {
        return switch(event) {
            case "create_todo":
                Todos.create_todo(params);
                LiveView.assign(socket, {todos: Todos.list_todos()});
            case _: socket;
        };
    }
    
    // HXX template compilation
    public static function render(assigns: Dynamic): String {
        return HXX.template('
            <div class="todo-app">
                <form phx-submit="create_todo">
                    <input name="title" value={assigns.new_todo} phx-debounce="300" />
                    <button type="submit">Add Todo</button>
                </form>
                <ul>
                    {for todo in assigns.todos}
                        <li class={if todo.completed then "completed" else ""}>{todo.title}</li>
                    {/for}
                </ul>
            </div>
        ');
    }
}
```

#### `@:controller` - Phoenix Controller
**Purpose**: HTTP request handling with action routing and response rendering.

**Generated File**: `lib/{app_name}_web/controllers/{name}_controller.ex`

**Example**:
```haxe
@:controller
@:appName("TodoApp")
class UserController {
    public static function show(conn: Conn, params: Dynamic): Dynamic {
        var user = Users.get_user(params.id);
        return Phoenix.render(conn, "show.html", {user: user});
    }
    
    public static function create(conn: Conn, params: Dynamic): Dynamic {
        return switch(Users.create_user(params.user)) {
            case Ok(user): 
                Phoenix.redirect(conn, Routes.user_path(conn, "show", user.id));
            case Error(changeset):
                Phoenix.render(conn, "new.html", {changeset: changeset});
        };
    }
}
```

#### `@:channel` - Phoenix Channel
**Purpose**: Real-time bidirectional communication over WebSockets.

**Generated File**: `lib/{app_name}_web/channels/{name}_channel.ex`

### Ecto Framework Annotations

#### `@:schema` - Ecto Schema Definition
**Purpose**: Database table mapping with typed field definitions and associations.

**Generated File**: `lib/{app_name}/schemas/{name}.ex`

**Example**:
```haxe
@:schema
@:appName("TodoApp") 
@:table("todos")
class Todo {
    @:primary_key public var id: Int;
    @:field public var title: String;
    @:field public var description: Null<String>;
    @:field @:default(false) public var completed: Bool;
    @:field public var priority: TodoPriority;
    @:timestamps public var inserted_at: Date;
    @:timestamps public var updated_at: Date;
    
    // Associations
    @:belongs_to public var user: User;
    @:has_many public var comments: Array<Comment>;
}
```

**Generated Output**:
```elixir
defmodule TodoApp.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :description, :string
    field :completed, :boolean, default: false
    field :priority, Ecto.Enum, values: [:low, :medium, :high]
    
    belongs_to :user, TodoApp.User
    has_many :comments, TodoApp.Comment
    
    timestamps()
  end

  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :completed, :priority])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 255)
  end
end
```

#### `@:changeset` - Ecto Changeset Validation
**Purpose**: Data validation and transformation pipeline for database operations.

**Example**:
```haxe
@:changeset
class TodoChangeset {
    @:cast(["title", "description", "completed"])
    @:validate_required(["title"])
    @:validate_length("title", {min: 1, max: 255})
    public static function changeset(todo: Todo, attrs: Dynamic): Dynamic {
        // Generated validation pipeline
    }
}
```

#### `@:migration` - Ecto Database Migration
**Purpose**: Database schema changes with type-safe table operations.

**Generated File**: `priv/repo/migrations/{timestamp}_{name}.exs`

**Example**:
```haxe
@:migration("todos")
@:appName("TodoApp")
class CreateTodos {
    public static function up(): Void {
        createTable("todos", function(t) {
            t.string("title", {null: false});
            t.text("description");
            t.boolean("completed", {default: false});
            t.integer("user_id");
            t.timestamps();
        });
        
        createIndex("todos", ["user_id"]);
    }
    
    public static function down(): Void {
        dropTable("todos");
    }
}
```

### OTP/Elixir Core Annotations

#### `@:genserver` - OTP GenServer
**Purpose**: Stateful server processes with OTP supervision and lifecycle management.

**Generated File**: `lib/{app_name}/{name}.ex`

**Example**:
```haxe
@:genserver
@:appName("TodoApp")
class TodoCache {
    // GenServer state type
    typedef State = {
        cache: Map<String, Todo>,
        ttl: Int
    }
    
    public static function start_link(opts: Dynamic): Dynamic {
        GenServer.start_link(__MODULE__, opts, {name: __MODULE__});
    }
    
    public static function init(opts: Dynamic): Dynamic {
        var state: State = {cache: new Map(), ttl: opts.ttl || 3600};
        return {ok: state};
    }
    
    public static function handle_call(msg: Dynamic, from: Dynamic, state: State): Dynamic {
        return switch(msg) {
            case {get: key}: 
                var result = state.cache.get(key);
                {reply: result, noreply: state};
            case {put: key, value: value}:
                state.cache.set(key, value);
                {reply: ok, noreply: state};
            case _: {reply: {error: "unknown_call"}, noreply: state};
        };
    }
}
```

#### `@:behaviour` - Elixir Behaviour Definition
**Purpose**: Interface contracts that other modules must implement.

#### `@:protocol` - Elixir Protocol Definition  
**Purpose**: Polymorphic dispatch based on data type.

#### `@:impl` - Protocol Implementation
**Purpose**: Protocol implementation for specific data types.

### Template System Annotations

#### `@:template` - Phoenix HEEx Template
**Purpose**: Server-side rendered templates with component integration.

**Generated File**: `lib/{app_name}_web/templates/{name}.html.heex`

### Configuration Annotations

#### `@:appName` - Application Name
**Purpose**: Sets the application name for module naming and directory structure.

**Usage**: Compatible with all other annotations, used for consistent naming.

**Example**:
```haxe
@:appName("TodoApp")  // Sets app name for entire compilation
@:liveview
class MyLive { }      // Generates: lib/todo_app_web/live/my_live.ex
```

## 🏗️ Implementation Architecture

### Annotation Detection and Validation

The `AnnotationSystem` class provides centralized annotation processing:

```haxe
// Priority-based annotation detection
public static var SUPPORTED_ANNOTATIONS = [
    ":genserver",    // Highest priority - OTP behaviors
    ":controller",   // Phoenix web layer
    ":router",       // Phoenix routing
    ":endpoint",     // Phoenix HTTP layer
    // ... etc in priority order
];
```

### Compilation Routing

Each annotation routes to specialized compiler helpers:

```haxe
public static function routeCompilation(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<String> {
    return switch (annotationInfo.primaryAnnotation) {
        case ":endpoint":
            // Returns null - handled by main ElixirCompiler with framework-aware file placement
            null;
        case ":router":
            RouterCompiler.compile(classType, varFields, funcFields);
        case ":liveview":
            LiveViewCompiler.compile(classType, varFields, funcFields);
        // ... etc
    };
}
```

### File Placement Strategy

**Framework-aware file placement** ensures generated files follow Phoenix conventions:

```haxe
private function setFrameworkAwareOutputPath(classType: ClassType): Void {
    switch (annotationInfo.primaryAnnotation) {
        case ":endpoint":
            fileName = "endpoint";
            dirPath = appName + "_web";  // → lib/todo_app_web/endpoint.ex
        case ":liveview":
            fileName = liveViewName + "_live";
            dirPath = appName + "_web/live";  // → lib/todo_app_web/live/user_live.ex
        case ":schema":
            fileName = schemaName;
            dirPath = appName + "/schemas";  // → lib/todo_app/schemas/user.ex
    }
    
    setOutputFileName(fileName);
    setOutputFileDir(dirPath);
}
```

## 🎨 Code Generation Patterns

### Idiomatic Elixir Output

All annotations generate idiomatic Elixir that follows BEAM conventions:

**✅ Generated Code Quality Standards**:
- Uses proper Elixir modules and `use` declarations
- Follows Phoenix directory structure exactly
- Implements OTP behaviors correctly
- Uses pattern matching and functional programming idioms
- Includes proper documentation and typespecs

**❌ Anti-patterns Avoided**:
- No imperative-style translations
- No unnecessary complexity
- No non-idiomatic constructs
- No manual string concatenation

### Type Safety Preservation

Haxe's compile-time type checking is preserved in generated Elixir:

```haxe
// Haxe: Type-safe at compile time
function createTodo(title: String, priority: TodoPriority): Result<Todo, String>

// Generated Elixir: Runtime type checking with patterns
def create_todo(title, priority) when is_binary(title) do
  case validate_priority(priority) do
    {:ok, valid_priority} -> 
      {:ok, %Todo{title: title, priority: valid_priority}}
    {:error, reason} -> 
      {:error, reason}
  end
end
```

## 📚 Best Practices

### Annotation Usage Guidelines

1. **One Primary Annotation Per Class**: Classes should have one main purpose
2. **Combine with @:appName**: Always specify application name for consistent structure
3. **Use Type Safety**: Leverage Haxe's type system, avoid Dynamic where possible
4. **Follow Phoenix Conventions**: Generated code must integrate seamlessly with Phoenix

### Common Patterns

#### Application Setup
```haxe
@:native("TodoApp.Application")
@:application
@:appName("TodoApp")
class TodoApp {
    public static function start(type: Dynamic, args: Dynamic): Dynamic {
        // OTP application startup
    }
}
```

#### Complete LiveView Component
```haxe
@:liveview
@:appName("TodoApp")
class UserLive {
    // State management
    public static function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic
    
    // Event handling
    public static function handle_event(event: String, params: Dynamic, socket: Dynamic): Dynamic
    
    // Template rendering with HXX
    public static function render(assigns: Dynamic): String
}
```

#### Database Schema with Validation
```haxe
@:schema
@:appName("TodoApp")
@:table("users")
class User {
    @:primary_key public var id: Int;
    @:field public var email: String;
    @:field public var name: String;
    @:timestamps public var inserted_at: Date;
    @:timestamps public var updated_at: Date;
}
```

## 🔧 Development Guidelines

### Adding New Annotations

1. **Add to SUPPORTED_ANNOTATIONS** in priority order
2. **Implement routing logic** in `routeCompilation`
3. **Add framework-aware file placement** if needed
4. **Create specialized compiler helper** for complex logic
5. **Add comprehensive documentation** with examples
6. **Write tests** for all annotation behaviors

### Testing Annotations

Each annotation must have:
- **Snapshot tests** for code generation validation
- **Integration tests** with Phoenix framework
- **Error handling tests** for invalid usage
- **File placement validation** for directory structure

### Error Handling

The annotation system provides comprehensive error reporting:
- **Conflict detection**: Multiple mutually exclusive annotations
- **Validation failures**: Missing required metadata
- **Framework compatibility**: Ensures Phoenix/OTP compliance

## 📖 Complete Examples

See [`examples/todo-app/`](../examples/todo-app/) for complete working application using all annotation types with proper Phoenix integration.

## 🔗 Related Documentation

- [Phoenix Framework Integration](PHOENIX_INTEGRATION.md)
- [OTP Pattern Implementation](OTP_PATTERNS.md)  
- [HXX Template System](HXX_VS_TEMPLATE.md)
- [Type Safety Guidelines](TYPE_SAFETY.md)
- [Testing Methodology](TESTING_PRINCIPLES.md)

---

**Remember**: Annotations are compile-time configuration that generates runtime Elixir code. The goal is 100% idiomatic Elixir output that Phoenix developers would be proud to write themselves.
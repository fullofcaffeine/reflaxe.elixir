# Reflaxe.Elixir Annotations Reference

Complete guide to using annotations in Reflaxe.Elixir for generating Elixir/Phoenix code.

## Overview

Reflaxe.Elixir uses Haxe metadata annotations to control code generation. Annotations tell the compiler how to transform Haxe classes into specific Elixir modules and patterns.

## Supported Annotations

### @:controller - Phoenix Controller

Marks a class as a Phoenix controller for handling HTTP requests.

**Basic Usage**:
```haxe
@:controller
class UserController {
    @:route({method: "GET", path: "/users"})
    public function index(): String {
        return "List all users";
    }
    
    @:route({method: "GET", path: "/users/:id"})
    public function show(id: Int): String {
        return "Show user " + id;
    }
    
    @:route({method: "POST", path: "/users"})
    public function create(user: Dynamic): String {
        return "Create user";
    }
}
```

**Generated Elixir**:
```elixir
defmodule UserController do
  use Phoenix.Controller
  
  def index(conn) do
    conn
    |> put_status(200)
    |> json(%{message: "Action index executed"})
  end
  
  def show(conn, id) do
    conn
    |> put_status(200)
    |> json(%{message: "Action show executed"})
  end
  
  def create(conn, user) do
    conn
    |> put_status(200)
    |> json(%{message: "Action create executed"})
  end
end
```

**Route Annotations**:
- `@:route({method: "GET", path: "/path"})` - Define route with HTTP method and path
- `@:resources("resource_name")` - Generate RESTful resource routes
- `@:pipe_through([pipelines])` - Specify pipeline for authorization/plugs

### @:router - Phoenix Router Configuration

Marks a class as a Phoenix router for request routing.

**Basic Usage**:
```haxe
@:router
class AppRouter {
    @:pipeline("browser", ["fetch_session", "protect_from_forgery"])
    @:pipeline("api", ["accept_json"])
    
    @:include_controller("UserController")
    @:include_controller("ProductController")
}
```

**Generated Elixir**:
```elixir
defmodule AppRouter do
  use Phoenix.Router
  
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  
  pipeline :api do
    plug :accepts, ["json"]
  end
  
  scope "/", AppRouter do
    pipe_through :browser
    
    resources "/users", UserController
    resources "/products", ProductController
  end
end
```

### @:schema - Ecto Schema Generation

Generates Ecto.Schema modules for database models.

**Basic Usage**:
```haxe
@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "string", nullable: false})
    public var email: String;
    
    @:field({type: "integer"})
    public var age: Int;
    
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
}
```

**Generated Elixir**:
```elixir
defmodule User do
  use Ecto.Schema
  
  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    
    timestamps()
  end
end
```

**Field Annotations**:
- `@:primary_key` - Primary key field
- `@:field({options})` - Regular field with options
- `@:timestamps` - Automatic timestamp fields
- `@:has_many(field, module, key)` - Has many association
- `@:belongs_to(field, module)` - Belongs to association

### @:changeset - Ecto Changeset Validation

Generates Ecto.Changeset modules for data validation.

**Basic Usage**:
```haxe
@:changeset
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", "email_regex")
    @:validate_length("name", {min: 2, max: 100})
    public static function changeset(user: User, attrs: Dynamic): Dynamic {
        return null; // Implementation generated automatically
    }
}
```

**Validation Annotations**:
- `@:validate_required([fields])` - Required field validation
- `@:validate_format(field, pattern)` - Format validation
- `@:validate_length(field, {min, max})` - Length validation
- `@:validate_number(field, {greater_than, less_than})` - Number validation
- `@:unique_constraint(field)` - Unique constraint validation

### @:liveview - Phoenix LiveView

Generates Phoenix LiveView modules for real-time UI.

**Basic Usage**:
```haxe
@:liveview
class UserLive {
    public function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        return {ok: socket};
    }
    
    public function handle_event(event: String, params: Dynamic, socket: Dynamic): Dynamic {
        return {noreply: socket};
    }
    
    public function render(assigns: Dynamic): String {
        return "<div>User LiveView</div>";
    }
}
```

**Generated Elixir**:
```elixir
defmodule UserLive do
  use Phoenix.LiveView
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  
  @impl true
  def handle_event(event, params, socket) do
    {:noreply, socket}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div>User LiveView</div>
    """
  end
end
```

### @:genserver - OTP GenServer

Generates OTP GenServer modules for stateful processes.

**Basic Usage**:
```haxe
@:genserver
class Counter {
    private var count: Int = 0;
    
    public function init(args: Dynamic): Dynamic {
        return {ok: 0};
    }
    
    public function handle_call(msg: String, from: Dynamic, state: Int): Dynamic {
        switch(msg) {
            case "get": return {reply: state, state};
            case "increment": return {reply: state + 1, state + 1};
            default: return {reply: "unknown", state};
        }
    }
}
```

**Generated Elixir**:
```elixir
defmodule Counter do
  use GenServer
  
  def init(_args) do
    {:ok, 0}
  end
  
  def handle_call("get", _from, state) do
    {:reply, state, state}
  end
  
  def handle_call("increment", _from, state) do
    {:reply, state + 1, state + 1}
  end
  
  def handle_call(_, _from, state) do
    {:reply, "unknown", state}
  end
end
```

### @:migration - Ecto Migration

Generates Ecto migration modules for database schema changes.

**Basic Usage**:
```haxe
@:migration
class CreateUsersTable {
    public function up(): Void {
        createTable("users")
            .addColumn("name", "string", {null: false})
            .addColumn("email", "string", {null: false})
            .addColumn("age", "integer")
            .addIndex(["email"], {unique: true});
    }
    
    public function down(): Void {
        dropTable("users");
    }
}
```

**Generated Elixir**:
```elixir
defmodule CreateUsersTable do
  use Ecto.Migration
  
  def up do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :age, :integer
      timestamps()
    end
    
    create unique_index(:users, [:email])
  end
  
  def down do
    drop table(:users)
  end
end
```

### @:template - Phoenix Template

Generates Phoenix HEEx template modules.

**Basic Usage**:
```haxe
@:template
class UserTemplate {
    public function user_card(user: Dynamic): String {
        return """
        <div class="user-card">
            <h3>{user.name}</h3>
            <p>{user.email}</p>
        </div>
        """;
    }
}
```

**Generated Elixir**:
```elixir
defmodule UserTemplate do
  use Phoenix.Component
  
  def user_card(assigns) do
    ~H"""
    <div class="user-card">
      <h3><%= @user.name %></h3>
      <p><%= @user.email %></p>
    </div>
    """
  end
end
```

### @:protocol - Elixir Protocol

Defines polymorphic behavior through protocols.

**Basic Usage**:
```haxe
@:protocol
class Stringable {
    @:callback
    public function toString(data: Dynamic): String {
        throw "Protocol function must be implemented";
    }
}
```

**Generated Elixir**:
```elixir
defprotocol Stringable do
  @doc "Convert data to string representation"
  def to_string(data)
end
```

### @:impl - Protocol Implementation

Implements a protocol for a specific type.

**Basic Usage**:
```haxe
@:impl("Stringable", "User")
class UserStringable {
    public function toString(user: User): String {
        return 'User: ${user.name}';
    }
}
```

**Generated Elixir**:
```elixir
defimpl Stringable, for: User do
  def to_string(user) do
    "User: #{user.name}"
  end
end
```

### @:behaviour - Elixir Behavior

Defines callback contracts for modules.

**Basic Usage**:
```haxe
@:behaviour
class DataProcessor {
    @:callback
    public function init(config: Dynamic): {ok: Dynamic, error: String} {
        throw "Callback must be implemented";
    }
    
    @:callback
    public function process(data: Dynamic): Dynamic {
        throw "Callback must be implemented";
    }
    
    @:optional_callback
    public function cleanup(): Void {
        // Optional cleanup
    }
}
```

**Generated Elixir**:
```elixir
defmodule DataProcessor do
  @callback init(config :: any()) :: {:ok, any()} | {:error, String.t()}
  @callback process(data :: any()) :: any()
  
  @optional_callbacks cleanup: 0
  @callback cleanup() :: :ok
end
```

## Annotation Combinations

Some annotations can be used together:

- `@:schema` + `@:changeset` - Data model with validation
- `@:liveview` + `@:template` - LiveView with template rendering
- `@:controller` + `@:route` - Controller with route definitions
- `@:behaviour` + `@:genserver` - GenServer implementing behavior
- `@:application` + `@:appName` - OTP Application with configurable module names
- `@:appName` + Any annotation - App name configuration is compatible with all annotations

## Annotation Conflicts

The following combinations are mutually exclusive:

- `@:genserver` and `@:liveview` - Choose one behavior type
- `@:schema` and `@:migration` - Schema is runtime, migration is compile-time
- `@:protocol` and `@:behaviour` - Different polymorphism approaches

### @:application - OTP Application Module

Marks a class as an OTP Application module that defines a supervision tree.

**Basic Usage**:
```haxe
@:application
@:native("MyApp.Application")
class MyApp {
    public static function start(type: Dynamic, args: Dynamic): Dynamic {
        // Define children for supervision tree
        var children = [
            "MyApp.Repo",                              // Simple module reference
            {module: "Phoenix.PubSub", name: "MyApp.PubSub"}, // Tuple with options
            "MyAppWeb.Endpoint"                        // Simple module reference
        ];
        
        // Start supervisor with children
        var opts = {strategy: "one_for_one", name: "MyApp.Supervisor"};
        return Supervisor.startLink(children, opts);
    }
    
    public static function config_change(changed: Dynamic, new_config: Dynamic, removed: Dynamic): String {
        // Handle configuration changes
        return "ok";
    }
}
```

**Generated Elixir**:
```elixir
defmodule MyApp.Application do
  @moduledoc false
  
  use Application
  
  @impl true
  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint
    ]
    
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  @impl true
  def config_change(changed, _new, removed) do
    MyAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

**Key Features**:
- Automatically adds `use Application` directive
- Transforms child specifications into proper OTP format
- Handles Phoenix-specific modules (Repo, PubSub, Endpoint, Telemetry)
- Adds `@impl true` annotations for callbacks
- Supports config_change callback for hot reloading

**Child Specification Formats**:
- String module names become atoms: `"MyApp.Repo"` → `MyApp.Repo`
- Objects with module/name become tuples: `{module: "Phoenix.PubSub", name: "MyApp.PubSub"}` → `{Phoenix.PubSub, name: MyApp.PubSub}`
- Supervisor options converted to keyword lists

### @:appName - Configurable Application Names

Configures the application name for Phoenix applications, enabling reusable code across different projects.

**Basic Usage**:
```haxe
@:application
@:appName("BlogApp")
@:native("BlogApp.Application")
class BlogApp {
    public static function start(type: Dynamic, args: Dynamic): Dynamic {
        var appName = getAppName(); // Returns "BlogApp"
        
        var children = [
            {
                id: '${appName}.Repo',
                start: {module: '${appName}.Repo', "function": "start_link", args: []}
            },
            {
                id: "Phoenix.PubSub",
                start: {
                    module: "Phoenix.PubSub", 
                    "function": "start_link",
                    args: [{name: '${appName}.PubSub'}]
                }
            },
            {
                id: '${appName}Web.Endpoint', 
                start: {module: '${appName}Web.Endpoint', "function": "start_link", args: []}
            }
        ];

        var opts = {strategy: "one_for_one", name: '${appName}.Supervisor'};
        return Supervisor.startLink(children, opts);
    }
}
```

**Generated Elixir**:
```elixir
defmodule BlogApp.Application do
  @moduledoc false
  
  use Application
  
  @impl true
  def start(_type, _args) do
    children = [
      %{id: "BlogApp.Repo", start: %{module: "BlogApp.Repo", function: "start_link", args: []}},
      %{id: "Phoenix.PubSub", start: %{module: "Phoenix.PubSub", function: "start_link", args: [%{name: "BlogApp.PubSub"}]}},
      %{id: "BlogAppWeb.Endpoint", start: %{module: "BlogAppWeb.Endpoint", function: "start_link", args: []}}
    ]
    
    opts = %{strategy: "one_for_one", name: "BlogApp.Supervisor"}
    Supervisor.start_link(children, opts)
  end
end
```

**Key Features**:
- **Dynamic Module Names**: Use `${appName}` string interpolation for configurable module references
- **Framework Compatibility**: Works with any Phoenix application naming convention
- **Compatible with All Annotations**: Can be combined with any other annotation type
- **Reusable Code**: Write once, use in multiple projects with different names
- **No Hardcoding**: Eliminates hardcoded "TodoApp" references in generated code

**Common Patterns**:
- PubSub modules: `'${appName}.PubSub'` → `"BlogApp.PubSub"`
- Web modules: `'${appName}Web.Endpoint'` → `"BlogAppWeb.Endpoint"`  
- Supervisor names: `'${appName}.Supervisor'` → `"BlogApp.Supervisor"`
- Repository modules: `'${appName}.Repo'` → `"BlogApp.Repo"`

**Why @:appName is Important**:
- Phoenix applications require app-specific module names (e.g., "BlogApp.PubSub", "ChatApp.PubSub")
- Without @:appName, all applications would hardcode "TodoApp" references
- Enables creating reusable Phoenix application templates
- Makes project renaming and rebranding straightforward

## Usage Guidelines

1. **One primary annotation per class** - Choose the main purpose of your class
2. **Use compatible combinations** - Leverage synergistic annotations together
3. **Avoid conflicts** - The compiler will error on incompatible combinations
4. **Follow conventions** - Use standard Phoenix/Ecto patterns for better integration

For more examples, see the `examples/` directory in the project repository.
# Reflaxe.Elixir User Guide

A comprehensive guide to using Reflaxe.Elixir for building type-safe Elixir applications with Haxe.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Annotations Reference](#annotations-reference)
3. [Type System](#type-system)
4. [Phoenix Integration](#phoenix-integration)
5. [OTP/GenServer](#otpgenserver)
6. [Ecto Integration](#ecto-integration)
7. [Protocols & Behaviors](#protocols--behaviors)
8. [Templates & LiveView](#templates--liveview)
9. [Best Practices](#best-practices)

## Core Concepts

Reflaxe.Elixir is a Haxe compiler target that generates idiomatic Elixir code. It provides:

- **Type Safety**: Compile-time type checking for your Elixir code
- **Seamless Integration**: Works with existing Elixir/Phoenix projects
- **Familiar Syntax**: Write Haxe, get clean Elixir output
- **Full Ecosystem Access**: Use any Elixir library through externs

### How It Works

```haxe
// Write Haxe code in src_haxe/
@:module
class Greeter {
    public static function greet(name: String): String {
        return 'Hello, $name!';
    }
}
```

Compiles to:

```elixir
# Generated in lib/generated/
defmodule Greeter do
  def greet(name) do
    "Hello, #{name}!"
  end
end
```

## Annotations Reference

Annotations control how your Haxe classes are compiled to Elixir modules.

### @:module
Basic Elixir module generation.

```haxe
@:module
class UserService {
    public static function findUser(id: Int): Dynamic {
        // Implementation
    }
}
```

### @:genserver
Creates OTP GenServer with full lifecycle callbacks.

```haxe
@:genserver
class Counter {
    var count: Int = 0;
    
    public function init(args: Dynamic): Dynamic {
        return {:ok, count};
    }
    
    public function handleCall(request: Dynamic, from: Dynamic, state: Int): Dynamic {
        return switch (request) {
            case "get": {:reply, state, state};
            case "increment": {:reply, state + 1, state + 1};
            default: {:reply, :error, state};
        };
    }
}
```

### @:liveview
Phoenix LiveView component with mount, event handlers, and render.

```haxe
@:liveview
class UserListLive {
    public function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        return socket |> assign("users", []);
    }
    
    public function handleEvent(event: String, params: Dynamic, socket: Dynamic): Dynamic {
        return switch (event) {
            case "search": 
                var users = searchUsers(params.query);
                socket |> assign("users", users);
            default: socket;
        };
    }
    
    public function render(): String {
        return '<div class="user-list">
            <%= for user <- @users do %>
                <div><%= user.name %></div>
            <% end %>
        </div>';
    }
}
```

### @:schema
Ecto schema definition with field types and associations.

```haxe
@:schema(table: "users")
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var age: Int;
    
    @:hasMany("Post")
    public var posts: Array<Dynamic>;
    
    @:belongsTo("Organization")
    public var organization: Dynamic;
}
```

### @:changeset
Ecto changeset for validation and data transformation.

```haxe
@:changeset
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", ~r/@/)
    @:validate_length("name", min: 3, max: 100)
    public function changeset(user: User, attrs: Dynamic): Dynamic {
        return user
            |> cast(attrs, ["name", "email", "age"])
            |> validateAge();
    }
    
    private function validateAge(changeset: Dynamic): Dynamic {
        var age = getField(changeset, "age");
        if (age != null && age < 18) {
            return addError(changeset, "age", "must be 18 or older");
        }
        return changeset;
    }
}
```

### @:migration
Database migration with table operations.

```haxe
@:migration(table: "posts")
class CreatePosts {
    public var title: String;
    public var content: String;
    public var authorId: Int;
    
    @:index("author_id")
    @:index(["title", "created_at"])
    @:foreignKey("author_id", references: "users")
    public function up(): Void {
        // Additional migration logic
    }
    
    public function down(): Void {
        // Rollback logic
    }
}
```

### @:protocol
Elixir protocol definition for polymorphic dispatch.

```haxe
@:protocol
interface Drawable {
    function draw(): String;
    function getBounds(): Dynamic;
}
```

### @:impl
Protocol implementation for specific types.

```haxe
@:impl(Drawable, for: String)
class StringDrawable {
    public function draw(str: String): String {
        return 'Drawing text: $str';
    }
    
    public function getBounds(str: String): Dynamic {
        return {width: str.length * 10, height: 20};
    }
}
```

### @:behaviour
Behavior contract definition with required callbacks.

```haxe
@:behaviour
interface DataProcessor {
    function process(data: Dynamic): Dynamic;
    function validate(data: Dynamic): Bool;
    
    @:optional
    function beforeProcess(data: Dynamic): Dynamic;
}
```

### @:router
Phoenix router configuration.

```haxe
@:router
class AppRouter {
    @:scope("/api")
    @:pipe_through(["api"])
    public function apiRoutes(): Void {
        get("/users", UserController, "index");
        get("/users/:id", UserController, "show");
        post("/users", UserController, "create");
        
        resources("/products", ProductController);
    }
    
    @:scope("/", AppWeb)
    @:pipe_through(["browser"])
    public function browserRoutes(): Void {
        live("/", HomeLive, "index");
        live("/users", UserListLive, "index");
        live("/users/:id", UserLive, "show");
    }
}
```

## Type System

### Haxe to Elixir Type Mapping

| Haxe Type | Elixir Type | Notes |
|-----------|-------------|-------|
| `String` | `String.t()` | UTF-8 binary strings |
| `Int` | `integer()` | Arbitrary precision |
| `Float` | `float()` | 64-bit float |
| `Bool` | `boolean()` | true/false atoms |
| `Array<T>` | `list(T)` | Linked lists |
| `Map<K,V>` | `%{K => V}` | Maps/dictionaries |
| `Dynamic` | `any()` | Any Elixir term |
| `Null<T>` | `T \| nil` | Nullable types |
| Class | Struct | With %ClassName{} syntax |
| Enum | Tagged tuples | Pattern matching support |

### Working with Elixir Types

```haxe
// Atoms
var status: ElixirAtom = cast ":ok";

// Tuples
var result: Dynamic = {:ok, "value"};
var error: Dynamic = {:error, "reason"};

// Pattern matching in switch
switch (result) {
    case {:ok, value}: trace('Success: $value');
    case {:error, reason}: trace('Error: $reason');
}

// Keyword lists
var opts: Array<Dynamic> = [
    {key: "timeout", value: 5000},
    {key: "retries", value: 3}
];

// Maps
var user: Map<String, Dynamic> = [
    "name" => "John",
    "age" => 30,
    "active" => true
];
```

## Phoenix Integration

### Creating Controllers

```haxe
@:controller
class UserController {
    public function index(conn: Dynamic, params: Dynamic): Dynamic {
        var users = Repo.all(User);
        return conn
            |> putStatus(200)
            |> json(%{users: users});
    }
    
    public function show(conn: Dynamic, params: Dynamic): Dynamic {
        var user = Repo.get(User, params.id);
        if (user != null) {
            return conn |> json(user);
        } else {
            return conn
                |> putStatus(404)
                |> json(%{error: "User not found"});
        }
    }
    
    public function create(conn: Dynamic, params: Dynamic): Dynamic {
        var changeset = User.changeset(%User{}, params.user);
        
        return switch (Repo.insert(changeset)) {
            case {:ok, user}: 
                conn
                |> putStatus(201)
                |> json(user);
            case {:error, changeset}:
                conn
                |> putStatus(422)
                |> json(%{errors: changesetErrors(changeset)});
        };
    }
}
```

### LiveView Components

```haxe
@:liveview
class TodoLive {
    public function mount(_params: Dynamic, _session: Dynamic, socket: Dynamic): Dynamic {
        return socket
            |> assign("todos", [])
            |> assign("new_todo", "");
    }
    
    public function handleEvent("add_todo", params: Dynamic, socket: Dynamic): Dynamic {
        var todo = %{
            id: generateId(),
            text: params.text,
            completed: false
        };
        
        var todos = socket.assigns.todos;
        todos.push(todo);
        
        return socket
            |> assign("todos", todos)
            |> assign("new_todo", "");
    }
    
    public function handleEvent("toggle_todo", params: Dynamic, socket: Dynamic): Dynamic {
        var todos = socket.assigns.todos.map(function(todo) {
            if (todo.id == params.id) {
                todo.completed = !todo.completed;
            }
            return todo;
        });
        
        return socket |> assign("todos", todos);
    }
    
    public function render(): String {
        return hxx('
            <div class="todo-app">
                <form phx-submit="add_todo">
                    <input type="text" name="text" value={@new_todo} />
                    <button type="submit">Add</button>
                </form>
                
                <ul>
                    {for todo <- @todos}
                        <li phx-click="toggle_todo" phx-value-id={todo.id}>
                            <input type="checkbox" checked={todo.completed} />
                            {todo.text}
                        </li>
                    {/for}
                </ul>
            </div>
        ');
    }
}
```

## OTP/GenServer

### Basic GenServer

```haxe
@:genserver
class ShoppingCart {
    var items: Array<Dynamic> = [];
    
    // GenServer callbacks
    public function init(args: Dynamic): Dynamic {
        return {:ok, items};
    }
    
    public function handleCall(request: Dynamic, from: Dynamic, state: Array<Dynamic>): Dynamic {
        return switch (request) {
            case {:add_item, item}:
                state.push(item);
                {:reply, :ok, state};
                
            case :get_items:
                {:reply, state, state};
                
            case :checkout:
                var total = calculateTotal(state);
                {:reply, {:ok, total}, []};  // Clear cart after checkout
                
            default:
                {:reply, {:error, "Unknown request"}, state};
        };
    }
    
    public function handleCast(request: Dynamic, state: Array<Dynamic>): Dynamic {
        return switch (request) {
            case :clear:
                {:noreply, []};
            default:
                {:noreply, state};
        };
    }
    
    // Client API
    public static function startLink(opts: Dynamic = null): Dynamic {
        return GenServer.startLink(__MODULE__, [], opts != null ? opts : []);
    }
    
    public static function addItem(server: Dynamic, item: Dynamic): Dynamic {
        return GenServer.call(server, {:add_item, item});
    }
    
    public static function getItems(server: Dynamic): Array<Dynamic> {
        return GenServer.call(server, :get_items);
    }
    
    public static function checkout(server: Dynamic): Dynamic {
        return GenServer.call(server, :checkout);
    }
}
```

## Ecto Integration

### Schema and Queries

```haxe
@:schema(table: "products")
class Product {
    public var id: Int;
    public var name: String;
    public var price: Float;
    public var stock: Int;
    public var category: String;
    
    // Query functions
    public static function inStock(): Dynamic {
        return from(p in Product, where: p.stock > 0);
    }
    
    public static function byCategory(category: String): Dynamic {
        return from(p in Product, 
            where: p.category == ^category,
            order_by: [asc: p.price]
        );
    }
    
    public static function search(term: String): Dynamic {
        var searchTerm = '%$term%';
        return from(p in Product,
            where: ilike(p.name, ^searchTerm),
            limit: 10
        );
    }
}
```

### Changesets and Validation

```haxe
@:changeset
class ProductChangeset {
    @:validate_required(["name", "price", "stock"])
    @:validate_number("price", greater_than: 0)
    @:validate_number("stock", greater_than_or_equal_to: 0)
    public function changeset(product: Product, attrs: Dynamic): Dynamic {
        return product
            |> cast(attrs, ["name", "price", "stock", "category"])
            |> validateCategory()
            |> uniqueConstraint("name");
    }
    
    private function validateCategory(changeset: Dynamic): Dynamic {
        var validCategories = ["electronics", "clothing", "food", "books"];
        var category = getField(changeset, "category");
        
        if (category != null && !validCategories.contains(category)) {
            return addError(changeset, "category", "invalid category");
        }
        return changeset;
    }
}
```

## Best Practices

### 1. Project Structure

```
your-app/
├── src_haxe/           # Haxe source files
│   ├── schemas/        # Ecto schemas
│   ├── live/           # LiveView components
│   ├── controllers/    # Phoenix controllers
│   ├── services/       # Business logic/GenServers
│   └── utils/          # Utility modules
├── lib/                # Elixir code
│   └── generated/      # Generated from Haxe
├── build.hxml          # Haxe build config
└── mix.exs             # Elixir project file
```

### 2. Type Safety Tips

- Use specific types instead of `Dynamic` when possible
- Define type aliases for complex structures
- Use enums for finite state values
- Leverage null safety with `Null<T>`

### 3. Performance Considerations

- Compilation is fast (<15ms per module)
- Generated code is idiomatic Elixir
- No runtime overhead - it's just Elixir
- Use `@:inline` for frequently called small functions

### 4. Testing Strategy

```haxe
// Haxe unit tests
class UserServiceTest extends Test {
    public function testFindUser() {
        var user = UserService.findUser(1);
        assertEquals("John", user.name);
    }
}
```

```elixir
# Elixir integration tests
defmodule UserServiceTest do
  use ExUnit.Case
  
  test "finds user by id" do
    user = UserService.find_user(1)
    assert user.name == "John"
  end
end
```

### 5. Debugging

- Generated Elixir code is readable and debuggable
- Use `trace()` for debug output (compiles to `IO.inspect()`)
- Elixir error messages reference generated code line numbers
- VS Code debugger works with generated code

## Next Steps

- See [EXAMPLES_GUIDE.md](./EXAMPLES_GUIDE.md) for detailed example walkthroughs
- Check [PHOENIX_GUIDE.md](./PHOENIX_GUIDE.md) for Phoenix-specific patterns
- Read [API_REFERENCE.md](./API_REFERENCE.md) for complete API documentation
- Explore [COOKBOOK.md](./COOKBOOK.md) for copy-paste recipes
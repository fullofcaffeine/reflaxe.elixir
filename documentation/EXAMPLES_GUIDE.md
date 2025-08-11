# Reflaxe.Elixir Examples Guide

Complete walkthroughs of all example projects showing real-world usage patterns.

## 📚 Example Projects Overview

| Example | Description | Key Concepts |
|---------|-------------|--------------|
| [01-simple-modules](#01-simple-modules) | Basic module compilation | @:module, functions, types |
| [02-mix-project](#02-mix-project) | Full Mix project structure | Project organization, utilities |
| [03-phoenix-app](#03-phoenix-app) | Phoenix application setup | Phoenix integration |
| [04-ecto-migrations](#04-ecto-migrations) | Database migrations | @:migration, DSL |
| [05-heex-templates](#05-heex-templates) | Template compilation | HXX syntax, components |
| [06-user-management](#06-user-management) | Complete CRUD system | LiveView, GenServer, Ecto |
| [07-protocols](#07-protocols) | Protocol definitions | @:protocol, @:impl |
| [08-behaviors](#08-behaviors) | Behavior contracts | @:behaviour, callbacks |
| [09-phoenix-router](#09-phoenix-router) | Router configuration | @:router, controllers |

## 01-simple-modules

**Purpose**: Learn the basics of compiling Haxe modules to Elixir.

### Basic Module

```haxe
// BasicModule.hx
package;

@:module
class BasicModule {
    public static function hello(name: String): String {
        return 'Hello, $name!';
    }
    
    public static function add(a: Int, b: Int): Int {
        return a + b;
    }
}
```

**Compiles to:**

```elixir
# BasicModule.ex
defmodule BasicModule do
  def hello(name) do
    "Hello, #{name}!"
  end
  
  def add(a, b) do
    a + b
  end
end
```

### Math Helper

```haxe
// MathHelper.hx
@:module
class MathHelper {
    public static function factorial(n: Int): Int {
        if (n <= 1) return 1;
        return n * factorial(n - 1);
    }
    
    public static function isPrime(n: Int): Bool {
        if (n <= 1) return false;
        for (i in 2...Math.ceil(Math.sqrt(n)) + 1) {
            if (n % i == 0) return false;
        }
        return true;
    }
}
```

**Usage in Elixir:**
```elixir
iex> MathHelper.factorial(5)
120
iex> MathHelper.is_prime(17)
true
```

### Key Learnings
- Use `@:module` annotation for basic modules
- Static functions become module functions
- Haxe types map to Elixir types automatically
- CamelCase converts to snake_case

## 02-mix-project

**Purpose**: Structure a complete Mix project with Haxe source files.

### Project Structure
```
02-mix-project/
├── src_haxe/              # Haxe sources
│   ├── utils/
│   │   ├── StringUtils.hx
│   │   ├── MathHelper.hx
│   │   └── ValidationHelper.hx
│   └── services/
│       └── UserService.hx
├── lib/                   # Generated Elixir
│   └── generated/
├── test/                  # ExUnit tests
└── mix.exs               # Mix configuration
```

### String Utilities

```haxe
// src_haxe/utils/StringUtils.hx
package utils;

@:module
class StringUtils {
    public static function slugify(text: String): String {
        return text
            .toLowerCase()
            .replace(~/[^a-z0-9]+/g, "-")
            .replace(~/^-|-$/g, "");
    }
    
    public static function truncate(text: String, maxLength: Int): String {
        if (text.length <= maxLength) {
            return text;
        }
        return text.substr(0, maxLength - 3) + "...";
    }
    
    public static function capitalize(text: String): String {
        if (text.length == 0) return text;
        return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
    }
}
```

### User Service

```haxe
// src_haxe/services/UserService.hx
package services;

@:module
class UserService {
    private static var users: Map<Int, Dynamic> = new Map();
    private static var nextId: Int = 1;
    
    public static function createUser(name: String, email: String): Dynamic {
        var user = {
            id: nextId++,
            name: name,
            email: email,
            createdAt: Date.now()
        };
        users.set(user.id, user);
        return user;
    }
    
    public static function findUser(id: Int): Dynamic {
        return users.get(id);
    }
    
    public static function updateUser(id: Int, updates: Dynamic): Dynamic {
        var user = users.get(id);
        if (user != null) {
            // Merge updates
            for (field in Reflect.fields(updates)) {
                Reflect.setField(user, field, Reflect.field(updates, field));
            }
            users.set(id, user);
        }
        return user;
    }
    
    public static function listUsers(): Array<Dynamic> {
        return [for (user in users) user];
    }
}
```

### Testing

```elixir
# test/user_service_test.exs
defmodule UserServiceTest do
  use ExUnit.Case
  
  test "creates and finds users" do
    user = UserService.create_user("Alice", "alice@example.com")
    assert user.name == "Alice"
    
    found = UserService.find_user(user.id)
    assert found.email == "alice@example.com"
  end
  
  test "updates user data" do
    user = UserService.create_user("Bob", "bob@example.com")
    UserService.update_user(user.id, %{email: "newemail@example.com"})
    
    updated = UserService.find_user(user.id)
    assert updated.email == "newemail@example.com"
  end
end
```

### Key Learnings
- Organize code in packages (utils, services, etc.)
- Mix project structure with src_haxe/ for sources
- Test generated code with ExUnit
- Package names become module namespaces

## 03-phoenix-app

**Purpose**: Phoenix application integration basics.

```haxe
// src_haxe/phoenix/Application.hx
package phoenix;

@:module
class Application {
    public static function start(_type: Dynamic, _args: Dynamic): Dynamic {
        var children = [
            // Telemetry
            {
                module: "Telemetry.Supervisor",
                args: [{
                    name: "MyApp.Telemetry"
                }]
            },
            // Database
            {
                module: "MyApp.Repo",
                args: []
            },
            // PubSub
            {
                module: "Phoenix.PubSub",
                args: [{
                    name: "MyApp.PubSub"
                }]
            },
            // Endpoint
            {
                module: "MyAppWeb.Endpoint",
                args: []
            }
        ];
        
        var opts = {
            strategy: "one_for_one",
            name: "MyApp.Supervisor"
        };
        
        return Supervisor.startLink(children, opts);
    }
}
```

## 04-ecto-migrations

**Purpose**: Database schema management with migrations.

### Creating Users Table

```haxe
// src_haxe/migrations/CreateUsers.hx
package migrations;

import reflaxe.elixir.helpers.MigrationDSL;

@:migration(table: "users")
class CreateUsers {
    public static function up(): Void {
        createTable("users", function(t) {
            t.addColumn("id", "serial", {primary_key: true});
            t.addColumn("name", "string", {null: false});
            t.addColumn("email", "string", {null: false});
            t.addColumn("age", "integer");
            t.addColumn("bio", "text");
            t.timestamps();
            
            t.addIndex(["email"], {unique: true});
            t.addIndex(["name", "created_at"]);
        });
    }
    
    public static function down(): Void {
        dropTable("users");
    }
}
```

### Creating Posts with Foreign Keys

```haxe
// src_haxe/migrations/CreatePosts.hx
@:migration(table: "posts")
class CreatePosts {
    public static function up(): Void {
        createTable("posts", function(t) {
            t.addColumn("id", "serial", {primary_key: true});
            t.addColumn("title", "string", {null: false});
            t.addColumn("content", "text");
            t.addColumn("published", "boolean", {default: false});
            t.addForeignKey("user_id", "users", {on_delete: "cascade"});
            t.timestamps();
            
            t.addIndex(["user_id"]);
            t.addIndex(["published", "created_at"]);
        });
    }
    
    public static function down(): Void {
        dropTable("posts");
    }
}
```

### Running Migrations
```bash
# Generate timestamped migration files
mix haxe.gen.migration CreateUsers
mix haxe.gen.migration CreatePosts

# Run migrations
mix ecto.migrate

# Rollback if needed
mix ecto.rollback
```

## 05-heex-templates

**Purpose**: HTML template generation with HXX syntax.

### HXX Template Syntax

```haxe
// src_haxe/templates/UserProfile.hx
package templates;

@:template
class UserProfile {
    public static function render(user: Dynamic): String {
        return hxx('
            <div class="user-profile">
                <div class="header">
                    <img src={user.avatar} alt={user.name} />
                    <h1>{user.name}</h1>
                    <p class="email">{user.email}</p>
                </div>
                
                <div class="stats">
                    <div class="stat">
                        <span class="label">Posts</span>
                        <span class="value">{user.postCount}</span>
                    </div>
                    <div class="stat">
                        <span class="label">Followers</span>
                        <span class="value">{user.followerCount}</span>
                    </div>
                </div>
                
                {if user.bio != null}
                    <div class="bio">
                        <h2>About</h2>
                        <p>{user.bio}</p>
                    </div>
                {/if}
                
                <div class="actions">
                    <button phx-click="follow" phx-value-id={user.id}>
                        Follow
                    </button>
                    <button phx-click="message" phx-value-id={user.id}>
                        Message
                    </button>
                </div>
            </div>
        ');
    }
}
```

### Form Components

```haxe
// src_haxe/templates/FormComponents.hx
@:template
class FormComponents {
    public static function textInput(field: String, label: String, opts: Dynamic = null): String {
        var required = opts != null && opts.required ? "required" : "";
        var placeholder = opts != null && opts.placeholder ? opts.placeholder : "";
        
        return hxx('
            <div class="form-group">
                <label for={field}>{label}</label>
                <input 
                    type="text" 
                    id={field} 
                    name={field}
                    placeholder={placeholder}
                    {required}
                />
            </div>
        ');
    }
    
    public static function select(field: String, label: String, options: Array<Dynamic>): String {
        return hxx('
            <div class="form-group">
                <label for={field}>{label}</label>
                <select id={field} name={field}>
                    {for option in options}
                        <option value={option.value}>{option.label}</option>
                    {/for}
                </select>
            </div>
        ');
    }
}
```

## 06-user-management

**Purpose**: Complete user management system with LiveView, GenServer, and Ecto.

### User Schema and Changeset

```haxe
// src_haxe/contexts/Users.hx
package contexts;

@:schema(table: "users")
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var role: String;
    public var active: Bool = true;
}

@:changeset
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", ~r/@/)
    @:unique_constraint("email")
    public static function changeset(user: User, attrs: Dynamic): Dynamic {
        return user
            |> cast(attrs, ["name", "email", "role", "active"])
            |> validateRole();
    }
    
    private static function validateRole(changeset: Dynamic): Dynamic {
        var validRoles = ["admin", "user", "guest"];
        var role = getField(changeset, "role");
        
        if (role != null && !validRoles.contains(role)) {
            return addError(changeset, "role", "invalid role");
        }
        return changeset;
    }
}
```

### User GenServer for Caching

```haxe
// src_haxe/services/UserGenServer.hx
package services;

@:genserver
class UserCache {
    var cache: Map<Int, Dynamic> = new Map();
    var ttl: Int = 300000; // 5 minutes
    
    public function init(_args: Dynamic): Dynamic {
        // Schedule cleanup every minute
        Process.sendAfter(self(), :cleanup, 60000);
        return {:ok, cache};
    }
    
    public function handleCall(request: Dynamic, _from: Dynamic, state: Map<Int, Dynamic>): Dynamic {
        return switch (request) {
            case {:get, userId}:
                var user = state.get(userId);
                if (user == null) {
                    user = loadUserFromDb(userId);
                    if (user != null) {
                        state.set(userId, {
                            data: user,
                            timestamp: System.currentTime()
                        });
                    }
                }
                {:reply, user?.data, state};
                
            case {:invalidate, userId}:
                state.remove(userId);
                {:reply, :ok, state};
                
            case :clear:
                {:reply, :ok, new Map()};
                
            default:
                {:reply, {:error, "Unknown request"}, state};
        };
    }
    
    public function handleInfo(:cleanup, state: Map<Int, Dynamic>): Dynamic {
        var now = System.currentTime();
        var cleaned = new Map();
        
        for (userId => entry in state) {
            if (now - entry.timestamp < ttl) {
                cleaned.set(userId, entry);
            }
        }
        
        Process.sendAfter(self(), :cleanup, 60000);
        return {:noreply, cleaned};
    }
}
```

### User LiveView

```haxe
// src_haxe/live/UserLive.hx
package live;

@:liveview
class UserLive {
    public function mount(_params: Dynamic, _session: Dynamic, socket: Dynamic): Dynamic {
        var users = Users.listActiveUsers();
        return socket
            |> assign("users", users)
            |> assign("search_term", "")
            |> assign("selected_user", null);
    }
    
    public function handleEvent("search", params: Dynamic, socket: Dynamic): Dynamic {
        var users = Users.searchUsers(params.term);
        return socket
            |> assign("users", users)
            |> assign("search_term", params.term);
    }
    
    public function handleEvent("select_user", params: Dynamic, socket: Dynamic): Dynamic {
        var user = Users.getUser(params.id);
        return socket |> assign("selected_user", user);
    }
    
    public function handleEvent("update_user", params: Dynamic, socket: Dynamic): Dynamic {
        var changeset = UserChangeset.changeset(
            socket.assigns.selected_user,
            params.user
        );
        
        return switch (Repo.update(changeset)) {
            case {:ok, user}:
                UserCache.invalidate(user.id);
                socket
                    |> putFlash(:info, "User updated successfully")
                    |> assign("selected_user", user);
                    
            case {:error, changeset}:
                socket
                    |> putFlash(:error, "Failed to update user")
                    |> assign("changeset", changeset);
        };
    }
    
    public function render(): String {
        return hxx('
            <div class="user-management">
                <div class="search-bar">
                    <form phx-submit="search">
                        <input 
                            type="text" 
                            name="term" 
                            value={@search_term}
                            placeholder="Search users..."
                        />
                        <button type="submit">Search</button>
                    </form>
                </div>
                
                <div class="user-list">
                    {for user <- @users}
                        <div 
                            class="user-item"
                            phx-click="select_user"
                            phx-value-id={user.id}
                        >
                            <span class="name">{user.name}</span>
                            <span class="email">{user.email}</span>
                            <span class="role">{user.role}</span>
                        </div>
                    {/for}
                </div>
                
                {if @selected_user}
                    <div class="user-details">
                        <h2>Edit User</h2>
                        <form phx-submit="update_user">
                            <input type="hidden" name="user[id]" value={@selected_user.id} />
                            
                            <div class="form-group">
                                <label>Name</label>
                                <input 
                                    type="text" 
                                    name="user[name]" 
                                    value={@selected_user.name}
                                />
                            </div>
                            
                            <div class="form-group">
                                <label>Email</label>
                                <input 
                                    type="email" 
                                    name="user[email]" 
                                    value={@selected_user.email}
                                />
                            </div>
                            
                            <div class="form-group">
                                <label>Role</label>
                                <select name="user[role]">
                                    <option value="admin" selected={@selected_user.role == "admin"}>Admin</option>
                                    <option value="user" selected={@selected_user.role == "user"}>User</option>
                                    <option value="guest" selected={@selected_user.role == "guest"}>Guest</option>
                                </select>
                            </div>
                            
                            <button type="submit">Save Changes</button>
                        </form>
                    </div>
                {/if}
            </div>
        ');
    }
}
```

## 07-protocols

**Purpose**: Polymorphic dispatch with protocols.

### Protocol Definition

```haxe
// src_haxe/protocols/Drawable.hx
package protocols;

@:protocol
interface Drawable {
    function draw(): String;
    function getArea(): Float;
}
```

### Implementations

```haxe
// src_haxe/implementations/StringDrawable.hx
@:impl(Drawable, for: String)
class StringDrawable {
    public function draw(str: String): String {
        var border = "*".repeat(str.length + 4);
        return '$border\n* $str *\n$border';
    }
    
    public function getArea(str: String): Float {
        return str.length * 10.0; // Approximate pixel area
    }
}

// src_haxe/implementations/NumberDrawable.hx
@:impl(Drawable, for: Number)
class NumberDrawable {
    public function draw(num: Float): String {
        var bar = "=".repeat(Math.round(num));
        return 'Value: $num\n[$bar]';
    }
    
    public function getArea(num: Float): Float {
        return num * num; // Square area
    }
}
```

## 08-behaviors

**Purpose**: Contract enforcement with behaviors.

### Behavior Definition

```haxe
// src_haxe/behaviors/DataProcessor.hx
package behaviors;

@:behaviour
interface DataProcessor {
    // Required callbacks
    function init(config: Dynamic): Dynamic;
    function process(data: Dynamic): Dynamic;
    function validate(data: Dynamic): Bool;
    
    // Optional callbacks
    @:optional
    function beforeProcess(data: Dynamic): Dynamic;
    
    @:optional
    function afterProcess(result: Dynamic): Dynamic;
}
```

### Implementations

```haxe
// src_haxe/implementations/BatchProcessor.hx
@:impl(DataProcessor)
class BatchProcessor {
    var batchSize: Int;
    
    public function init(config: Dynamic): Dynamic {
        batchSize = config.batchSize != null ? config.batchSize : 100;
        return {:ok, batchSize};
    }
    
    public function process(data: Array<Dynamic>): Dynamic {
        var results = [];
        var batch = [];
        
        for (item in data) {
            batch.push(item);
            if (batch.length >= batchSize) {
                results.push(processBatch(batch));
                batch = [];
            }
        }
        
        if (batch.length > 0) {
            results.push(processBatch(batch));
        }
        
        return {:ok, results};
    }
    
    public function validate(data: Dynamic): Bool {
        return Std.isOfType(data, Array);
    }
    
    private function processBatch(batch: Array<Dynamic>): Dynamic {
        // Process batch logic
        return {
            count: batch.length,
            processed: true
        };
    }
}
```

## 09-phoenix-router

**Purpose**: Web routing configuration.

### Router Definition

```haxe
// src_haxe/AppRouter.hx
package;

@:router
class AppRouter {
    @:pipeline("browser")
    public function browserPipeline(): Void {
        plug("accepts", ["html"]);
        plug("fetch_session");
        plug("fetch_live_flash");
        plug("put_root_layout", {AppWeb.LayoutView, "root"});
        plug("protect_from_forgery");
        plug("put_secure_browser_headers");
    }
    
    @:pipeline("api")
    public function apiPipeline(): Void {
        plug("accepts", ["json"]);
    }
    
    @:scope("/", AppWeb)
    @:pipe_through(["browser"])
    public function browserRoutes(): Void {
        get("/", PageController, "index");
        get("/about", PageController, "about");
        
        // LiveView routes
        live("/dashboard", DashboardLive, "index");
        live("/users", UserLive.Index, "index");
        live("/users/:id", UserLive.Show, "show");
        live("/users/:id/edit", UserLive.Edit, "edit");
    }
    
    @:scope("/api", AppWeb)
    @:pipe_through(["api"])
    public function apiRoutes(): Void {
        resources("/users", UserController, except: ["new", "edit"]);
        resources("/products", ProductController);
        
        post("/auth/login", AuthController, "login");
        post("/auth/logout", AuthController, "logout");
        get("/auth/me", AuthController, "me");
    }
}
```

### Controller Implementation

```haxe
// src_haxe/controllers/UserController.hx
package controllers;

@:controller
class UserController {
    public function index(conn: Dynamic, _params: Dynamic): Dynamic {
        var users = Repo.all(User);
        return conn |> json(%{data: users});
    }
    
    public function show(conn: Dynamic, params: Dynamic): Dynamic {
        return switch (Repo.get(User, params.id)) {
            case null:
                conn
                |> putStatus(404)
                |> json(%{error: "User not found"});
            case user:
                conn |> json(%{data: user});
        };
    }
    
    public function create(conn: Dynamic, params: Dynamic): Dynamic {
        var changeset = User.changeset(%User{}, params.user);
        
        return switch (Repo.insert(changeset)) {
            case {:ok, user}:
                conn
                |> putStatus(201)
                |> json(%{data: user});
            case {:error, changeset}:
                conn
                |> putStatus(422)
                |> json(%{errors: translateErrors(changeset)});
        };
    }
}
```

## Running the Examples

### Individual Examples
```bash
cd examples/01-simple-modules
npx haxe compile-all.hxml
```

### Mix Projects
```bash
cd examples/02-mix-project
mix deps.get
npx haxe build.hxml
mix test
```

### Phoenix Projects
```bash
cd examples/06-user-management
mix deps.get
npx haxe build.hxml
mix ecto.create
mix ecto.migrate
mix phx.server
```

## Key Takeaways

1. **Start Simple**: Begin with basic modules before moving to Phoenix
2. **Use Annotations**: Let annotations handle boilerplate generation
3. **Type Safety**: Leverage Haxe's type system for compile-time safety
4. **Mix Integration**: Generated code integrates seamlessly with Mix projects
5. **Test Everything**: Write tests in both Haxe and Elixir
6. **Incremental Migration**: You can mix Haxe and Elixir code in the same project

## Next Steps

- Try modifying the examples to understand how changes affect generated code
- Combine patterns from different examples for your use case
- Check the [COOKBOOK.md](./COOKBOOK.md) for ready-to-use recipes
- Read the [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) if you encounter issues
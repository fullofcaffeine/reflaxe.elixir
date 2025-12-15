# Complete User Management System

This example demonstrates a full-featured user management system built with Haxe→Elixir compilation, showcasing all major Phoenix/Elixir patterns.

## Architecture Overview

This example combines multiple Reflaxe.Elixir features:

- **Ecto Schemas & Changesets** (`@:schema`, `@:changeset`)
- **Phoenix LiveView** (`@:liveview`) 
- **OTP GenServer** (`@:genserver`)
- **Ecto Queries** (`@:query`)
- **Type-Safe Templates** (`hxx` syntax)

## Components

### 1. Data Layer (`contexts/Users.hx`)

**Ecto Schema:**
```haxe
@:schema("users")
class User {
    @:primary_key var id: Int;
    @:field({type: "string", null: false}) var name: String;
    @:field({type: "string", null: false}) var email: String;
    @:timestamps var insertedAt: String;
    
    @:has_many("posts", "Post", "user_id") var posts: Array<Post>;
}
```

**Changeset Validation:**
```haxe
@:changeset
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", ~r/\S+@\S+\.\S+/)
    @:validate_length("name", {min: 2, max: 100})
    static function changeset(user: User, attrs: Dynamic): Dynamic { ... }
}
```

**Query Functions:**
```haxe
@:query
static function list_users(?filter: UserFilter): Array<User> {
    return from(u in User)
        |> where([u], u.active == ^true)
        |> orderBy([u], u.name)
        |> select([u], u);
}

@:query  
static function search_users(term: String): Array<User> {
    var searchTerm = "%" + term + "%";
    return from(u in User)
        |> where([u], like(u.name, ^searchTerm) or like(u.email, ^searchTerm))
        |> select([u], u);
}
```

### 2. LiveView Interface (`live/UserLive.hx`)

**Real-time CRUD Operations:**
```haxe
@:liveview
class UserLive {
    var users: Array<User> = [];
    var showForm: Bool = false;
    
    function handle_event(event: String, params: Dynamic, socket: Dynamic) {
        return switch(event) {
            case "new_user": handleNewUser(params, socket);
            case "save_user": handleSaveUser(params, socket);
            case "delete_user": handleDeleteUser(params, socket);
            case "search": handleSearch(params, socket);
        }
    }
}
```

**Type-Safe Templates:**
```haxe
function render(assigns: Dynamic): String {
    return hxx('
    <div class="user-management">
        <div class="header">
            <h1>User Management</h1>
            <.button phx-click="new_user">New User</.button>
        </div>
        ${renderUserList(assigns)}
        ${renderUserForm(assigns)}
    </div>
    ');
}
```

### 3. Background Services (`services/UserGenServer.hx`)

**OTP GenServer for Caching:**
```haxe
@:genserver
class UserGenServer {
    var userCache: Map<Int, User> = new Map();
    var statsCache: Dynamic = null;
    
    function handle_call(request: String, from: Dynamic, state: Dynamic): CallResponse {
        return switch(request) {
            case "get_user": handleGetUser(from, state);
            case "get_stats": handleGetStats(from, state);
        }
    }
    
    function handle_cast(message: String, state: Dynamic) {
        return switch(message) {
            case "refresh_stats": handleRefreshStats(state);
            case "preload_active_users": handlePreloadActiveUsers(state);
        }
    }
}
```

## Quick Start

```bash
cd examples/06-user-management

# Compile all components
haxe build.hxml

# Generated files:
# - lib/contexts/users.ex (Ecto schema + context)  
# - lib/live/user_live.ex (Phoenix LiveView)
# - lib/services/user_gen_server.ex (OTP GenServer)
```

## Generated Elixir Code

### Ecto Schema
```elixir
defmodule User do
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "users" do
    field :name, :string
    field :email, :string  
    field :age, :integer
    field :active, :boolean, default: true
    
    has_many :posts, Post
    timestamps()
  end
  
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :active])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/\S+@\S+\.\S+/)
    |> validate_length(:name, min: 2, max: 100)
  end
end
```

### LiveView Module
```elixir
defmodule UserLive do
  use Phoenix.LiveView
  
  def mount(_params, _session, socket) do
    users = Users.list_users()
    {:ok, assign(socket, users: users, show_form: false)}
  end
  
  def handle_event("new_user", _params, socket) do
    changeset = Users.change_user(%User{})
    {:noreply, assign(socket, show_form: true, changeset: changeset)}
  end
end
```

### GenServer Module  
```elixir
defmodule UserGenServer do
  use GenServer
  
  def init(init_state) do
    {:ok, %{user_cache: %{}, stats_cache: nil}}
  end
  
  def handle_call({:get_user, user_id}, _from, state) do
    # Implementation for cached user retrieval
  end
  
  def handle_cast(:refresh_stats, state) do
    # Implementation for background stats refresh
  end
end
```

## Features Demonstrated

### 1. **Complete CRUD Operations**
- Create, Read, Update, Delete users
- Real-time form validation
- Search and filtering

### 2. **Advanced Ecto Integration**
- Complex queries with joins and preloads
- Changeset validation with multiple rules
- Association management

### 3. **Phoenix LiveView Features**
- Real-time updates without page refresh
- Form handling with validation errors  
- Modal dialogs and dynamic UI

### 4. **OTP Patterns**
- GenServer for caching and background jobs
- Periodic tasks and message handling
- State management and supervision

### 5. **Type Safety**
- Compile-time validation of database schemas
- Type-safe query construction
- Template validation and autocompletion

## Development Workflow

1. **Edit Haxe Sources**: Modify `.hx` files with full IDE support
2. **Compile**: `haxe build.hxml` generates Elixir code
3. **Test**: Standard Phoenix/Elixir testing workflow
4. **Deploy**: Standard OTP release process

## Next Steps

- Add user authentication and authorization
- Implement user roles and permissions
- Add audit logging and user activity tracking
- Integrate with external authentication providers
- Add user preferences and profile management

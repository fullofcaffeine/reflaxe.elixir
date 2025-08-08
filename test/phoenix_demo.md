# Phoenix Integration Demo

This demonstrates the Phoenix integration features added to Reflaxe.Elixir.

## Features Implemented

### 1. PhoenixMapper Class
- `@:context` annotation support for Phoenix contexts
- Phoenix controller and LiveView detection
- Phoenix naming conventions (pluralization, snake_case)
- Configurable app name and repo module names

### 2. Ecto Extern Definitions
- `Ecto.Repo` - Database operations (insert, get, update, delete, all, one)
- `Ecto.Schema` - Schema definition macros
- `Ecto.Changeset` - Data validation and casting
- `Ecto.Query` - Query building DSL

### 3. Phoenix Framework Externs
- `Phoenix.Controller` - HTTP request handling
- `Phoenix.LiveView` - Real-time interactive applications
- `Phoenix.HTML` - HTML helpers and form generation  
- `Phoenix.Router` - Path and URL generation

### 4. Enhanced ClassCompiler Integration
- Automatic Phoenix use statements based on class type
- Context-specific imports and aliases
- Controller and LiveView module structure generation

## Usage Examples

### Phoenix Context with @:context annotation
```haxe
@:context("Users")
class UserContext {
    public static function list_users(): Array<User> {
        return Ecto.Repo.all(Ecto.Query.from(User));
    }
    
    public static function create_user(attrs: Dynamic): {ok: User} | {error: Dynamic} {
        var changeset = User.changeset(new User(), attrs);
        return Ecto.Repo.insert(changeset);
    }
}
```

Compiles to:
```elixir
defmodule UserContext do
  @moduledoc """
  The Users context
  """
  
  import Ecto.Query, warn: false
  alias MyApp.Repo
  
  def list_users() do
    Repo.all(from(User))
  end
  
  def create_user(attrs) do
    changeset = User.changeset(%User{}, attrs)
    Repo.insert(changeset)
  end
end
```

### Phoenix Controller
```haxe
class UserController extends Phoenix.Controller {
    public function index(conn: Dynamic, params: Dynamic): Dynamic {
        var users = UserContext.list_users();
        return Phoenix.Controller.render(conn, "index.html", {users: users});
    }
}
```

Compiles to:
```elixir
defmodule UserController do
  use MyAppWeb, :controller
  
  def index(conn, params) do
    users = UserContext.list_users()
    render(conn, "index.html", users: users)
  end
end
```

### Ecto Schema
```haxe
@:schema("users")
class User {
    @:field public var id: Int;
    @:field public var name: String;
    @:field public var email: String;
    
    public static function changeset(user: User, attrs: Dynamic): Dynamic {
        var changeset = Ecto.Changeset.cast(user, attrs, ["name", "email"]);
        return Ecto.Changeset.validate_required(changeset, ["name", "email"]);
    }
}
```

## Integration Verification

✅ All existing Mix integration tests pass
✅ Phoenix-specific features integrated into ClassCompiler  
✅ Comprehensive extern definitions for Phoenix and Ecto
✅ Example fixtures covering all major Phoenix patterns
✅ Zero compilation warnings maintained
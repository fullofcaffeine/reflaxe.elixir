# Reflaxe.Elixir Basics for LLM Agents

**Purpose**: Core concepts and patterns for using Reflaxe.Elixir effectively.

**Target**: LLM agents building Phoenix applications with Haxe.

## What is Reflaxe.Elixir?

Reflaxe.Elixir is a **compile-time transpiler** that transforms typed Haxe code into idiomatic Elixir modules. It enables:

- **Type-safe Phoenix development** with Haxe's static typing
- **Gradual migration** from Elixir to Haxe
- **Modern development tools** (IDEs, refactoring, etc.)
- **Performance optimization** through static analysis

### Key Insight: Macro-Time Compilation
```
Haxe Source (.hx) → Haxe Compiler → Reflaxe.Elixir → Elixir Code (.ex) → BEAM
```

All transpilation happens **during Haxe compilation**. The transpiler disappears after generating Elixir code.

## Core Annotations Reference Card

### Essential Annotations
```haxe
@:module        // Define Elixir module (required for most classes)
@:liveview      // Phoenix LiveView component  
@:schema        // Ecto schema definition
@:changeset     // Ecto changeset function
@:genserver     // GenServer behavior
@:supervisor    // Supervisor behavior
@:migration     // Ecto migration
@:template      // Phoenix template
@:query         // Ecto query function
@:router        // Phoenix router
@:controller    // Phoenix controller
@:protocol      // Elixir protocol
@:impl          // Protocol implementation
@:behaviour     // Custom behavior definition
```

### Annotation Usage Patterns
```haxe
// Basic module
@:module
class UserService {
    public static function list():Array<User> {
        return Repo.all(User);
    }
}

// LiveView component
@:liveview  
class ProductLive {
    public static function mount(params, session, socket) {
        return socket.assign({products: []});
    }
}

// Ecto schema with changeset
@:schema
class User {
    public var id:Int;
    public var email:String;
    
    @:changeset
    public static function changeset(user, attrs) {
        return user.cast(attrs, ["email"]);
    }
}
```

## Project Structure Best Practices

### Recommended Directory Layout
```
my_phoenix_app/
├── src_haxe/              # Haxe source files
│   ├── controllers/       # Phoenix controllers
│   ├── live/              # LiveView components  
│   ├── schemas/           # Ecto schemas
│   ├── services/          # Business logic
│   ├── workers/           # GenServer workers
│   └── Main.hx           # Application entry point
├── lib/                   # Generated Elixir files
│   ├── controllers/       # Generated controllers
│   ├── live/              # Generated LiveViews
│   └── ...               # Other generated modules
├── build.hxml            # Haxe build configuration
├── mix.exs               # Mix project file
└── config/               # Phoenix configuration
```

### Build Configuration (build.hxml)
```hxml
# Essential build.hxml setup
-cp src_haxe
-lib reflaxe.elixir
-D elixir_output=lib
--main Main

# Optional optimizations
-D analyzer-optimize
-D no-debug          # Production builds
-D source-map        # Development debugging
```

### Mix Integration (mix.exs)
```elixir
def project do
  [
    app: :my_app,
    compilers: [:haxe] ++ Mix.compilers(),  # Add Haxe compiler
    haxe: [
      source_dir: "src_haxe",
      target_dir: "lib", 
      hxml_file: "build.hxml"
    ],
    deps: deps()
  ]
end
```

## Type Mapping Reference

### Haxe → Elixir Type Mappings
| Haxe Type | Elixir Type | Notes |
|-----------|-------------|-------|
| `Int` | `integer()` | 32/64-bit integers |
| `Float` | `float()` | IEEE 754 floating point |
| `String` | `String.t()` | UTF-8 binary strings |
| `Bool` | `boolean()` | true/false atoms |
| `Array<T>` | `list(T)` | Ordered lists |
| `Map<K,V>` | `%{K => V}` | Key-value maps |
| `Dynamic` | `any()` | Any Elixir term |
| `Null<T>` | `T \| nil` | Nullable types |
| `Void` | `:ok` | Success atom |
| Class | Module | With @:module annotation |
| Enum | Atoms/Modules | Depends on structure |

### Common Data Structure Patterns
```haxe
// Phoenix socket assigns
typedef Assigns = {
    current_user:Null<User>,
    products:Array<Product>,
    loading:Bool
};

// Ecto changeset result
typedef ChangesetResult<T> = {
    valid:Bool,
    data:T,
    errors:Map<String, Array<String>>
};

// GenServer state
typedef WorkerState = {
    queue:Array<Job>,
    processed:Int,
    status:WorkerStatus
};
```

## Essential Patterns

### 1. **LiveView Component Pattern**
```haxe
@:liveview
class ProductLive {
    // Required: Mount function
    public static function mount(params, session, socket) {
        var products = ProductService.list();
        return socket.assign({
            products: products,
            loading: false,
            search_query: ""
        });
    }
    
    // Handle user events
    public static function handle_event(event:String, params, socket) {
        return switch(event) {
            case "search":
                var query = params.query;
                var results = ProductService.search(query);
                socket.assign({
                    products: results,
                    search_query: query
                });
                
            case "clear":
                var all = ProductService.list();
                socket.assign({
                    products: all,
                    search_query: ""
                });
                
            case _:
                socket;
        };
    }
    
    // Handle info messages  
    public static function handle_info(info, socket) {
        return switch(info) {
            case {refresh: true}:
                var products = ProductService.list();
                socket.assign({products: products});
            case _:
                socket;
        };
    }
}
```

### 2. **Ecto Schema and Changeset Pattern**
```haxe
@:schema
class User {
    // Database fields
    public var id:Int;
    public var email:String;
    public var name:String;
    public var inserted_at:Dynamic;
    public var updated_at:Dynamic;
    
    // Changeset for validation
    @:changeset
    public static function changeset(user, attrs) {
        return user
            .cast(attrs, ["email", "name"])
            .validate_required(["email", "name"])
            .validate_format("email", ~/^[^@]+@[^@]+$/)
            .validate_length("name", {min: 2, max: 100});
    }
    
    // Registration changeset with different rules
    @:changeset
    public static function registration_changeset(user, attrs) {
        return user
            .changeset(attrs)  // Use base changeset
            .cast(attrs, ["password"])
            .validate_required(["password"])
            .validate_length("password", {min: 8});
    }
}
```

### 3. **GenServer Worker Pattern**
```haxe
@:genserver
class EmailWorker {
    // State type
    typedef State = {
        queue:Array<EmailJob>,
        processing:Bool
    };
    
    // Required: Initialize state
    public static function init(args) {
        return {ok: {queue: [], processing: false}};
    }
    
    // Handle synchronous calls
    public static function handle_call(request, from, state:State) {
        return switch(request) {
            case {get_queue_size: true}:
                {reply: state.queue.length, state: state};
            case _:
                {reply: :error, state: state};
        };
    }
    
    // Handle asynchronous casts
    public static function handle_cast(msg, state:State) {
        return switch(msg) {
            case {send_email: email}:
                var newQueue = state.queue.concat([email]);
                processQueue();  // Trigger async processing
                {noreply: {queue: newQueue, processing: true}};
            case _:
                {noreply: state};
        };
    }
    
    // Handle info messages
    public static function handle_info(info, state:State) {
        return switch(info) {
            case :process_queue:
                processNextEmail(state);
            case _:
                {noreply: state};
        };
    }
    
    // Helper function
    static function processNextEmail(state:State) {
        return if (state.queue.length > 0) {
            var email = state.queue.shift();
            EmailService.deliver(email);
            var newState = {queue: state.queue, processing: state.queue.length > 0};
            {noreply: newState};
        } else {
            {noreply: {queue: [], processing: false}};
        }
    }
}
```

### 4. **Ecto Migration Pattern**
```haxe
@:migration
class CreateUsers {
    public static function up() {
        return create_table("users", function(t) {
            t.add_column("id", "serial", {primary_key: true});
            t.add_column("email", "string", {null: false});
            t.add_column("name", "string", {null: false});
            t.add_column("inserted_at", "naive_datetime", {null: false});
            t.add_column("updated_at", "naive_datetime", {null: false});
            
            t.create_index(["email"], {unique: true});
        });
    }
    
    public static function down() {
        return drop_table("users");
    }
}
```

### 5. **Phoenix Controller Pattern**
```haxe
@:controller
class UserController {
    public static function index(conn, params) {
        var users = UserService.list();
        return conn.render("index.html", {users: users});
    }
    
    public static function show(conn, params) {
        var id = Std.parseInt(params.id);
        return switch(UserService.get(id)) {
            case {ok: user}:
                conn.render("show.html", {user: user});
            case {error: :not_found}:
                conn
                    .put_status(404)
                    .render("error.html", {message: "User not found"});
        };
    }
    
    public static function create(conn, params) {
        var userParams = params.user;
        return switch(UserService.create(userParams)) {
            case {ok: user}:
                conn
                    .put_flash("info", "User created successfully")
                    .redirect_to("/users/" + user.id);
            case {error: changeset}:
                conn.render("new.html", {changeset: changeset});
        };
    }
}
```

## Compilation Process

### 1. **Basic Compilation Flow**
```bash
# Compile Haxe to Elixir
npx haxe build.hxml

# Or with Mix integration
mix compile
```

### 2. **Development Workflow**
```bash
# Watch mode for development
mix haxe.watch

# Run Phoenix server with auto-compilation
iex -S mix phx.server
```

### 3. **Production Build**
```bash
# Clean production build
MIX_ENV=prod mix clean
MIX_ENV=prod mix compile
MIX_ENV=prod mix release
```

## Error Handling Patterns

### 1. **Result Types**
```haxe
// Define common result types
typedef Result<T> = {
    success:Bool,
    data:Null<T>,
    error:Null<String>
};

// Or use Elixir-style tuples
enum Result<T> {
    Ok(value:T);
    Error(reason:String);
}

// Usage in service functions
class UserService {
    public static function create(params):Result<User> {
        try {
            var changeset = User.changeset(%User{}, params);
            return if (changeset.valid) {
                var user = Repo.insert(changeset);
                Ok(user);
            } else {
                Error("Validation failed");
            };
        } catch(e:Dynamic) {
            Error(Std.string(e));
        }
    }
}
```

### 2. **Pattern Matching for Errors**
```haxe
// Handle results with pattern matching
function handleUserCreation(params) {
    return switch(UserService.create(params)) {
        case Ok(user):
            trace('Created user: ${user.name}');
            redirectToUser(user);
        case Error(reason):
            trace('Failed to create user: $reason');
            showError(reason);
    };
}
```

## Performance Considerations

### 1. **Efficient Data Access**
```haxe
// ✅ Good: Use preloading to avoid N+1 queries
@:query
public static function users_with_posts() {
    return from(u in User)
        .preload(:posts)
        .select(u);
}

// ❌ Avoid: Lazy loading in loops
for (user in users) {
    var posts = user.posts; // N+1 query problem
}
```

### 2. **Memory Management**
```haxe
// ✅ Good: Process data in batches
class DataProcessor {
    public static function processBatch(items:Array<Data>) {
        var batch = [];
        for (item in items) {
            batch.push(processItem(item));
            if (batch.length >= 100) {
                saveBatch(batch);
                batch = []; // Clear memory
            }
        }
        if (batch.length > 0) saveBatch(batch);
    }
}
```

## Testing Patterns

### 1. **Unit Testing**
```haxe
// Test business logic
class UserServiceTest {
    public static function test_create_user() {
        var params = {name: "John", email: "john@example.com"};
        var result = UserService.create(params);
        
        switch(result) {
            case Ok(user):
                assert(user.name == "John");
                assert(user.email == "john@example.com");
            case Error(reason):
                fail('Expected success, got error: $reason');
        }
    }
}
```

### 2. **Integration Testing with Mix**
```elixir
# In test/haxe_integration_test.exs
defmodule HaxeIntegrationTest do
  use ExUnit.Case
  
  test "Haxe-generated modules work correctly" do
    # Test generated UserService
    {:ok, user} = UserService.create(%{name: "Test", email: "test@example.com"})
    assert user.name == "Test"
  end
end
```

## Common Pitfalls and Solutions

### 1. **Type System Issues**
```haxe
// ❌ Problem: Dynamic usage
function processData(data:Dynamic) {
    return data.someField; // No type safety
}

// ✅ Solution: Explicit types
typedef ProcessData = {
    someField:String,
    otherField:Int
};

function processData(data:ProcessData) {
    return data.someField; // Type safe
}
```

### 2. **Null Handling**
```haxe
// ❌ Problem: Ignoring nulls
function getName(user:Null<User>):String {
    return user.name; // Compilation error
}

// ✅ Solution: Explicit null checking
function getName(user:Null<User>):String {
    return user != null ? user.name : "Unknown";
}

// ✅ Alternative: Null coalescing
function getName(user:Null<User>):String {
    return user?.name ?? "Unknown";
}
```

### 3. **Module Organization**
```haxe
// ❌ Problem: Everything in one file
class EverythingController {
    // 500 lines of mixed logic
}

// ✅ Solution: Separate concerns
@:controller
class UserController {
    public static function index(conn, params) {
        var users = UserService.list(); // Delegate to service
        return UserView.render(conn, "index.html", {users: users});
    }
}

@:module
class UserService {
    public static function list():Array<User> {
        return UserRepository.all();
    }
}
```

## Next Steps

### Essential Reading Order
1. **Start here**: [HAXE_FUNDAMENTALS.md](./HAXE_FUNDAMENTALS.md)
2. **Then**: This document (REFLAXE_ELIXIR_BASICS.md)  
3. **Next**: [QUICK_START_PATTERNS.md](./QUICK_START_PATTERNS.md)
4. **Reference**: [API_REFERENCE_SKELETON.md](./API_REFERENCE_SKELETON.md)

### Project Creation Workflow
1. **Initialize project**: Use ProjectGenerator for best structure
2. **Configure build**: Set up build.hxml and mix.exs properly
3. **Start with schemas**: Define your data structures first
4. **Add business logic**: Create service modules
5. **Build UI**: Implement LiveView components
6. **Test thoroughly**: Both unit and integration tests

### Learning Resources
- **Phoenix Framework**: https://phoenixframework.org/
- **Ecto Guide**: https://hexdocs.pm/ecto/
- **LiveView Guide**: https://hexdocs.pm/phoenix_live_view/
- **GenServer Guide**: https://elixir-lang.org/getting-started/genserver.html

### Source Code References (Available Locally)

When implementing Reflaxe.Elixir features, reference these local sources:

**Reflaxe.Elixir Compiler Source**:
```bash
# Current project source (for understanding implementation)
/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/

# Key files to reference:
# - ElixirCompiler.hx - Main compiler implementation
# - helpers/ - All helper compilers (ClassCompiler, EnumCompiler, etc.)
# - ElixirTyper.hx - Type mapping system
# - PhoenixMapper.hx - Phoenix-specific mappings
```

**Working Examples**:
```bash
# Live examples showing all patterns in action
/Users/fullofcaffeine/workspace/code/haxe.elixir/examples/

# Each example has complete implementation:
# - 02-mix-project: Basic Haxe→Elixir compilation
# - 03-phoenix-app: Phoenix application structure  
# - 06-user-management: LiveView components with Ecto
# - 07-protocols: Protocol implementation patterns
```

**Reference Implementations**:
```bash
# Other Reflaxe compilers for architecture patterns
/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/reflaxe.CPP/
/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/reflaxe/src/

# Phoenix applications for Elixir patterns
/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/ (Phoenix projects)

# HXX template processing reference
/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/tink_hxx/
```

**When to Check Source Code**:

1. **Understanding Annotation Implementation**:
   ```bash
   # How does @:liveview work?
   grep -r "liveview" src/reflaxe/elixir/helpers/
   ```

2. **Learning Type Mapping**:
   ```bash
   # How are Haxe types converted to Elixir?
   cat src/reflaxe/elixir/ElixirTyper.hx
   ```

3. **Studying Working Examples**:
   ```bash
   # See complete LiveView implementation
   cat examples/06-user-management/src_haxe/live/UserLive.hx
   ```

4. **Understanding Helper Compilers**:
   ```bash
   # How does schema compilation work?
   cat src/reflaxe/elixir/helpers/SchemaCompiler.hx
   ```

## Summary for LLM Agents

When working with Reflaxe.Elixir:

1. **Always use annotations** - they drive code generation
2. **Follow Phoenix conventions** - for familiar Elixir output
3. **Leverage static typing** - main advantage over pure Elixir
4. **Use pattern matching** - more idiomatic than if-else
5. **Handle errors explicitly** - avoid silent failures
6. **Separate concerns** - use services, controllers, schemas appropriately
7. **Test at both levels** - Haxe unit tests + Elixir integration tests

This foundation enables you to build robust, type-safe Phoenix applications with the productivity benefits of Haxe's development tools.
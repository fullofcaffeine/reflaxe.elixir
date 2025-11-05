# Quick Start Patterns - Copy-Paste Ready

**Copy-paste ready patterns for common Reflaxe.Elixir tasks.**

This guide provides working examples that you can copy and customize for your Phoenix applications. Each pattern includes complete, production-ready code with best practices.

## 🚀 Essential Patterns

### 1. Phoenix LiveView Component
*Copy this for any interactive Phoenix component*

```haxe
// File: src_haxe/live/ProductLive.hx
package live;

@:liveview
class ProductLive {
    // Required: Mount function - sets initial state
    public static function mount(params, session, socket) {
        return socket.assign({
            products: ProductService.list(),
            loading: false,
            search_query: "",
            selected_product: null
        });
    }
    
    // Handle user interactions  
    public static function handle_event(event:String, params, socket) {
        return switch(event) {
            case "search":
                var query = params.query;
                var results = ProductService.search(query);
                socket.assign({
                    products: results,
                    search_query: query,
                    loading: false
                });
                
            case "select":
                var id = Std.parseInt(params.id);
                var product = ProductService.get(id);
                socket.assign({selected_product: product});
                
            case "clear":
                socket.assign({
                    products: ProductService.list(),
                    search_query: "",
                    selected_product: null
                });
                
            case _: socket;
        };
    }
    
    // Optional: Handle async messages
    public static function handle_info(info, socket) {
        return switch(info) {
            case {refresh_products: true}:
                socket.assign({products: ProductService.list()});
            case _: socket;
        };
    }
}
```

### 2. Ecto Schema + Changeset
*Copy this for any database model*

```haxe
// File: src_haxe/schemas/User.hx
package schemas;

@:schema
class User {
    // Database fields (follow Ecto conventions)
    public var id:Int;
    public var email:String;
    public var name:String;
    public var role:String;
    public var active:Bool;
    public var inserted_at:Dynamic;
    public var updated_at:Dynamic;
    
    // Basic changeset for creation/updates
    @:changeset
    public static function changeset(user, attrs) {
        return user
            .cast(attrs, ["email", "name", "role", "active"])
            .validate_required(["email", "name"])
            .validate_format("email", ~/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
            .validate_length("name", {min: 2, max: 100})
            .validate_inclusion("role", ["admin", "user", "moderator"])
            .unique_constraint("email");
    }
    
    // Specialized changeset for registration
    @:changeset
    public static function registration_changeset(user, attrs) {
        return user
            .changeset(attrs)
            .cast(attrs, ["password"])
            .validate_required(["password"])
            .validate_length("password", {min: 8})
            .put_password_hash();
    }
    
    // Specialized changeset for profile updates
    @:changeset
    public static function profile_changeset(user, attrs) {
        return user
            .cast(attrs, ["name", "email"])
            .validate_required(["name", "email"])
            .validate_format("email", ~/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
            .unique_constraint("email");
    }
}
```

### 3. Service Module (Business Logic)
*Copy this for any business logic module*

```haxe
// File: src_haxe/services/UserService.hx
package services;

@:module
class UserService {
    // List all users
    public static function list():Array<User> {
        return Repo.all(User);
    }
    
    // Get user by ID
    public static function get(id:Int):Null<User> {
        return Repo.get(User, id);
    }
    
    // Create new user
    public static function create(attrs:Dynamic) {
        var changeset = User.changeset(%User{}, attrs);
        
        return if (changeset.valid) {
            switch(Repo.insert(changeset)) {
                case {ok: user}: {ok: user};
                case {error: reason}: {error: reason};
            }
        } else {
            {error: changeset};
        }
    }
    
    // Update existing user  
    public static function update(user:User, attrs:Dynamic) {
        var changeset = User.changeset(user, attrs);
        
        return if (changeset.valid) {
            switch(Repo.update(changeset)) {
                case {ok: updated_user}: {ok: updated_user};
                case {error: reason}: {error: reason};
            }
        } else {
            {error: changeset};
        }
    }
    
    // Delete user
    public static function delete(user:User) {
        return Repo.delete(user);
    }
    
    // Search users by name or email
    public static function search(query:String):Array<User> {
        var pattern = '%$query%';
        return Repo.all(
            from(u in User)
                .where(ilike(u.name, ^pattern))
                .or_where(ilike(u.email, ^pattern))
                .order_by([asc: u.name])
        );
    }
    
    // Get active users only
    public static function list_active():Array<User> {
        return Repo.all(
            from(u in User)
                .where(u.active == true)
                .order_by([asc: u.name])
        );
    }
}
```

### 4. GenServer Worker
*Copy this for any background worker*

```haxe
// File: src_haxe/workers/EmailWorker.hx
package workers;

@:genserver
class EmailWorker {
    // State definition
    typedef State = {
        queue:Array<EmailJob>,
        processing:Bool,
        processed_count:Int
    };
    
    typedef EmailJob = {
        to:String,
        subject:String,
        body:String,
        priority:Int
    };
    
    // Initialize worker state
    public static function init(args) {
        return {ok: {
            queue: [],
            processing: false,
            processed_count: 0
        }};
    }
    
    // Handle synchronous calls
    public static function handle_call(request, from, state:State) {
        return switch(request) {
            case {get_status: true}:
                var status = {
                    queue_size: state.queue.length,
                    processing: state.processing,
                    processed: state.processed_count
                };
                {reply: status, state: state};
                
            case {get_queue: true}:
                {reply: state.queue, state: state};
                
            case _:
                {reply: :error, state: state};
        };
    }
    
    // Handle asynchronous operations
    public static function handle_cast(msg, state:State) {
        return switch(msg) {
            case {send_email: job}:
                var newQueue = state.queue.concat([job]);
                // Sort by priority (higher number = higher priority)
                newQueue.sort((a, b) -> b.priority - a.priority);
                
                if (!state.processing) {
                    scheduleProcessing();
                }
                
                {noreply: {
                    queue: newQueue,
                    processing: true,
                    processed_count: state.processed_count
                }};
                
            case {clear_queue: true}:
                {noreply: {
                    queue: [],
                    processing: false,
                    processed_count: state.processed_count
                }};
                
            case _:
                {noreply: state};
        };
    }
    
    // Handle async messages
    public static function handle_info(info, state:State) {
        return switch(info) {
            case :process_queue:
                processNextEmail(state);
                
            case {email_processed: result}:
                var newCount = state.processed_count + 1;
                var newState = {
                    queue: state.queue,
                    processing: state.queue.length > 0,
                    processed_count: newCount
                };
                
                // Continue processing if more emails exist
                if (state.queue.length > 0) {
                    scheduleProcessing();
                }
                
                {noreply: newState};
                
            case _:
                {noreply: state};
        };
    }
    
    // Helper functions
    static function scheduleProcessing() {
        Process.send_after(self(), :process_queue, 100);
    }
    
    static function processNextEmail(state:State) {
        return if (state.queue.length > 0) {
            var email = state.queue.shift();
            
            // Process email asynchronously
            Task.start(function() {
                EmailService.deliver(email);
                GenServer.cast(self(), {email_processed: :ok});
            });
            
            {noreply: {
                queue: state.queue,
                processing: state.queue.length > 0,
                processed_count: state.processed_count
            }};
        } else {
            {noreply: {
                queue: [],
                processing: false,
                processed_count: state.processed_count
            }};
        }
    }
}
```

### 5. Phoenix Controller
*Copy this for any HTTP endpoint*

```haxe
// File: src_haxe/controllers/UserController.hx
package controllers;

@:controller
class UserController {
    // List all users (GET /users)
    public static function index(conn, params) {
        var users = UserService.list();
        return conn.render("index.html", {users: users});
    }
    
    // Show user form (GET /users/new)
    public static function new(conn, params) {
        var changeset = User.changeset(%User{}, %{});
        return conn.render("new.html", {changeset: changeset});
    }
    
    // Create user (POST /users)
    public static function create(conn, params) {
        var userParams = params.user;
        
        return switch(UserService.create(userParams)) {
            case {ok: user}:
                conn
                    .put_flash("info", "User created successfully")
                    .redirect(Routes.user_path(conn, :show, user.id));
                    
            case {error: changeset}:
                conn
                    .put_status(422)
                    .render("new.html", {changeset: changeset});
        };
    }
    
    // Show specific user (GET /users/:id)
    public static function show(conn, params) {
        var id = Std.parseInt(params.id);
        
        return switch(UserService.get(id)) {
            case user if (user != null):
                conn.render("show.html", {user: user});
                
            case null:
                conn
                    .put_status(404)
                    .put_flash("error", "User not found")
                    .redirect(Routes.user_path(conn, :index));
        };
    }
    
    // Show edit form (GET /users/:id/edit)
    public static function edit(conn, params) {
        var id = Std.parseInt(params.id);
        
        return switch(UserService.get(id)) {
            case user if (user != null):
                var changeset = User.changeset(user, %{});
                conn.render("edit.html", {user: user, changeset: changeset});
                
            case null:
                conn
                    .put_status(404)
                    .put_flash("error", "User not found")
                    .redirect(Routes.user_path(conn, :index));
        };
    }
    
    // Update user (PUT/PATCH /users/:id)
    public static function update(conn, params) {
        var id = Std.parseInt(params.id);
        var userParams = params.user;
        
        return switch(UserService.get(id)) {
            case user if (user != null):
                switch(UserService.update(user, userParams)) {
                    case {ok: updated_user}:
                        conn
                                .put_flash("info", "User updated successfully")
                                .redirect(Routes.user_path(conn, :show, updated_user.id));
                                
                    case {error: changeset}:
                        conn
                                .put_status(422)
                                .render("edit.html", {user: user, changeset: changeset});
                }
                
            case null:
                conn
                    .put_status(404)
                    .put_flash("error", "User not found")
                    .redirect(Routes.user_path(conn, :index));
        };
    }
    
    // Delete user (DELETE /users/:id)
    public static function delete(conn, params) {
        var id = Std.parseInt(params.id);
        
        return switch(UserService.get(id)) {
            case user if (user != null):
                switch(UserService.delete(user)) {
                    case {ok: _}:
                        conn
                                .put_flash("info", "User deleted successfully")
                                .redirect(Routes.user_path(conn, :index));
                                
                    case {error: _}:
                        conn
                                .put_flash("error", "Could not delete user")
                                .redirect(Routes.user_path(conn, :show, user.id));
                }
                
            case null:
                conn
                    .put_status(404)
                    .put_flash("error", "User not found")
                    .redirect(Routes.user_path(conn, :index));
        };
    }
}
```

### 6. Ecto Migration
*Copy this for any database schema change*

```haxe
// File: src_haxe/migrations/CreateUsers.hx
package migrations;

@:migration
class CreateUsers {
    public static function up() {
        return create_table("users", function(t) {
            // Primary key
            t.add_column("id", "serial", {primary_key: true});
            
            // Basic fields
            t.add_column("email", "string", {null: false});
            t.add_column("name", "string", {null: false});
            t.add_column("role", "string", {default: "user"});
            t.add_column("active", "boolean", {default: true});
            
            // Timestamps (Ecto convention)
            t.add_column("inserted_at", "naive_datetime", {null: false});
            t.add_column("updated_at", "naive_datetime", {null: false});
            
            // Indexes for performance
            t.create_index(["email"], {unique: true});
            t.create_index(["name"]);
            t.create_index(["role"]);
            t.create_index(["active"]);
        });
    }
    
    public static function down() {
        return drop_table("users");
    }
}

// Advanced migration example with references
@:migration
class CreatePosts {
    public static function up() {
        return create_table("posts", function(t) {
            t.add_column("id", "serial", {primary_key: true});
            t.add_column("title", "string", {null: false});
            t.add_column("body", "text");
            t.add_column("published", "boolean", {default: false});
            
            // Foreign key reference
            t.add_column("user_id", "integer", {null: false});
            t.add_foreign_key("user_id", "users", "id", {on_delete: "cascade"});
            
            // Timestamps
            t.add_column("inserted_at", "naive_datetime", {null: false});
            t.add_column("updated_at", "naive_datetime", {null: false});
            
            // Indexes
            t.create_index(["user_id"]);
            t.create_index(["published"]);
            t.create_index(["inserted_at"]);
        });
    }
    
    public static function down() {
        return drop_table("posts");
    }
}
```

### 7. HXX Templates
*Copy this for any HTML template*

```haxe
// File: src_haxe/templates/UserTemplate.hx
package templates;

@:template
class UserTemplate {
    // User profile component
    public static function profile(user:User):String {
        return HXX.hxx('
            <div class="user-profile">
                <div class="avatar">
                    <img src={user.avatar_url} alt={user.name} />
                </div>
                <div class="info">
                    <h2><%= user.name %></h2>
                    <p class="email"><%= user.email %></p>
                    <span class="role badge {user.role}"><%= user.role %></span>
                    <%= if user.active do %>
                        <span class="status active">Active</span>
                    <% else %>
                        <span class="status inactive">Inactive</span>
                    <% end %>
                </div>
            </div>
        ');
    }
    
    // User list component
    public static function userList(users:Array<User>):String {
        return HXX.hxx('
            <div class="user-list">
                <h3>Users (<%= users.length %>)</h3>
                <div class="grid">
                    <%= for user <- users do %>
                        <%= userCard(user) %>
                    <% end %>
                </div>
            </div>
        ');
    }
    
    // Individual user card
    public static function userCard(user:User):String {
        return HXX.hxx('
            <div class="user-card" data-user-id={user.id}>
                <h4><%= user.name %></h4>
                <p><%= user.email %></p>
                <div class="actions">
                    <button phx-click="edit" phx-value-id={user.id}>Edit</button>
                    <button phx-click="delete" phx-value-id={user.id} 
                            data-confirm="Are you sure?">Delete</button>
                </div>
            </div>
        ');
    }
    
    // Form component
    public static function userForm(changeset:Dynamic, action:String):String {
        return HXX.hxx('
            <form phx-submit={action} class="user-form">
                <div class="field">
                    <label for="name">Name</label>
                    <input type="text" name="user[name]" id="name" 
                           value={changeset.data.name || ""} required />
                    <%= formError(changeset, "name") %>
                </div>
                
                <div class="field">
                    <label for="email">Email</label>
                    <input type="email" name="user[email]" id="email" 
                           value={changeset.data.email || ""} required />
                    <%= formError(changeset, "email") %>
                </div>
                
                <div class="field">
                    <label for="role">Role</label>
                    <select name="user[role]" id="role">
                        <option value="user" <%= if changeset.data.role == "user", do: "selected" %>>User</option>
                        <option value="admin" <%= if changeset.data.role == "admin", do: "selected" %>>Admin</option>
                        <option value="moderator" <%= if changeset.data.role == "moderator", do: "selected" %>>Moderator</option>
                    </select>
                    <%= formError(changeset, "role") %>
                </div>
                
                <div class="actions">
                    <button type="submit">Save</button>
                    <button type="button" phx-click="cancel">Cancel</button>
                </div>
            </form>
        ');
    }
    
    // Helper for form errors
    static function formError(changeset:Dynamic, field:String):String {
        var errors = changeset.errors != null ? changeset.errors[field] : null;
        return if (errors != null && errors.length > 0) {
            '<div class="error">' + errors.join(", ") + '</div>';
        } else {
            '';
        }
    }
}
```

## 🔧 Project Setup Patterns

### Basic Project Structure
```
my_phoenix_app/
├── src_haxe/
│   ├── controllers/
│   │   └── UserController.hx
│   ├── live/
│   │   └── UserLive.hx
│   ├── schemas/
│   │   └── User.hx
│   ├── services/
│   │   └── UserService.hx
│   ├── workers/
│   │   └── EmailWorker.hx
│   ├── templates/
│   │   └── UserTemplate.hx
│   └── Main.hx
├── lib/                    # Generated Elixir
├── build.hxml             # Haxe configuration
└── mix.exs                # Phoenix configuration
```

### Essential build.hxml
```hxml
-cp src_haxe
-lib reflaxe.elixir
-D elixir_output=lib
--main Main
```

### Essential mix.exs additions
```elixir
def project do
  [
    compilers: [:haxe] ++ Mix.compilers(),
    haxe: [
      source_dir: "src_haxe",
      target_dir: "lib",
      hxml_file: "build.hxml"
    ]
  ]
end
```

## 📝 Common Type Definitions

### Result Types
```haxe
// Standard result type
enum Result<T> {
    Ok(value:T);
    Error(reason:String);
}

// Phoenix-style assigns
typedef Assigns = Map<String, Dynamic>;

// Common changeset result
typedef ChangesetResult<T> = {
    valid:Bool,
    data:T,
    errors:Map<String, Array<String>>
};
```

### Phoenix Socket Types
```haxe
typedef Socket = {
    function assign(assigns:Dynamic):Socket;
    function put_flash(type:String, message:String):Socket;
    function push_event(event:String, payload:Dynamic):Socket;
    var assigns:Dynamic;
};
```

## 🚨 Quick Troubleshooting

### Compilation Errors
```bash
# Check Haxe syntax
npx haxe --help

# Compile with verbose output
npx haxe -v build.hxml

# Clean build
mix clean && mix compile
```

### Common Fixes
1. **"Type not found"** → Check imports and @:module annotation
2. **"Cannot access private"** → Use public fields/methods
3. **"Abstract cannot be instantiated"** → Use constructor or factory method
4. **Pattern not exhaustive** → Add default case to switch

## 🎯 Usage Guidelines

### Copy-Paste Workflow
1. **Copy the entire pattern** - Don't modify during copy
2. **Rename classes and packages** - Update to your domain
3. **Customize field names** - Match your database schema  
4. **Add business logic** - Implement your specific requirements
5. **Test incrementally** - Compile after each change

### Best Practices
- **Use annotations correctly** - They drive code generation (@:schema, @:liveview, etc.)
- **Follow Phoenix conventions** - Generated code should look natural to Elixir developers
- **Leverage type safety** - Let Haxe catch errors at compile time
- **Test patterns first** - Verify compilation before heavy customization

## 📚 Related Documentation

- **[LiveView Development](../02-user-guide/liveview-development.md)** - Complete LiveView guide
- **[Ecto Schemas](../02-user-guide/ecto-schemas.md)** - Database integration patterns
- **[Functional Transformations](functional-transformations.md)** - Advanced patterns
- **[API Reference](../04-api-reference/)** - Complete annotation reference

## 🚀 Next Steps

After using these patterns:
1. **Study working examples** - Check `examples/todo-app/` for real implementations
2. **Read the guides** - Deep dive into [User Guide](../02-user-guide/) for comprehensive understanding
3. **Build incrementally** - Start with simple patterns, add complexity gradually
4. **Test thoroughly** - Use both Haxe and Elixir testing strategies

---

**These patterns cover 90% of common Reflaxe.Elixir use cases. Copy, paste, and customize as needed!**
## ⚡ Optimistic Updates (LiveView)

For a copy‑paste ready pattern and an explanation of when to use optimistic vs. server‑first flows, see:

- Optimistic Updates in LiveView (Haxe → Elixir): docs/07-patterns/optimistic-updates-liveview.md

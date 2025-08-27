# Project-Specific Documentation: test_template_vars

**Template Type**: phoenix  
**Generated**: 2025-08-27 12:27:11


## Phoenix Web Application

### Key Components

#### Controllers
HTTP request handlers that process incoming requests and return responses.

```haxe
@:controller
class PageController {
    public static function index(conn, params) {
        return conn.render("index.html");
    }
}
```

#### Views
Template rendering and presentation logic.

```haxe
@:view
class PageView {
    public static function render(template: String, assigns: Dynamic) {
        // Template rendering logic
    }
}
```

#### Router
URL routing configuration mapping paths to controllers.

```haxe
@:router
class Router {
    public static function routes() {
        return [
            {path: "/", controller: "PageController", action: "index"},
            {path: "/users", controller: "UserController", action: "index"},
            {path: "/users/:id", controller: "UserController", action: "show"}
        ];
    }
}
```

#### Contexts
Business logic boundaries that encapsulate related functionality.

```haxe
@:module
class Accounts {
    public static function list_users(): Array<User> {
        return Repo.all(User);
    }
    
    public static function get_user(id: Int): Null<User> {
        return Repo.get(User, id);
    }
}
```

### Phoenix-Specific Patterns

#### Pipeline Pattern
```haxe
// Plug pipeline for request processing
@:pipeline
class BrowserPipeline {
    public static function plugs() {
        return [
            "accepts", ["html"],
            "fetch_session",
            "fetch_flash",
            "protect_from_forgery",
            "put_secure_browser_headers"
        ];
    }
}
```

#### Channel Pattern
```haxe
@:channel
class UserChannel {
    public static function join(topic: String, payload: Dynamic, socket: Dynamic) {
        return {ok: socket};
    }
    
    public static function handle_in(event: String, payload: Dynamic, socket: Dynamic) {
        broadcast(socket, event, payload);
        return {noreply: socket};
    }
}
```



## Phoenix LiveView Application

### LiveView Components

#### Mount Function
Initializes component state when the LiveView process starts.

```haxe
public static function mount(params, session, socket) {
    return socket.assign({
        users: UserService.list(),
        loading: false,
        filter: ""
    });
}
```

#### Event Handlers
Process user interactions from the browser.

```haxe
public static function handle_event(event: String, params, socket) {
    return switch(event) {
        case "search":
            var results = search(params.query);
            socket.assign({results: results});
            
        case "select":
            var item = find_item(params.id);
            socket.assign({selected: item});
            
        case _:
            socket;
    };
}
```

#### Info Handlers
Process server-side messages and PubSub events.

```haxe
public static function handle_info(info, socket) {
    return switch(info) {
        case {user_updated: user}:
            update_user_in_list(socket, user);
            
        case {refresh: true}:
            socket.assign({users: UserService.list()});
            
        case _:
            socket;
    };
}
```

### LiveView-Specific Patterns

#### Form Handling Pattern
```haxe
@:liveview
class UserFormLive {
    public static function handle_event(event, params, socket) {
        return switch(event) {
            case "validate":
                var changeset = User.changeset(socket.assigns.user, params.user);
                socket.assign({changeset: changeset});
                
            case "save":
                save_user(socket, params.user);
                
            case _:
                socket;
        };
    }
}
```

#### Real-time Updates Pattern
```haxe
@:liveview
class DashboardLive {
    public static function mount(params, session, socket) {
        PubSub.subscribe("dashboard:updates");
        return socket.assign({metrics: load_metrics()});
    }
    
    public static function handle_info(info, socket) {
        return switch(info) {
            case {metric_updated: metric}:
                var metrics = update_metric(socket.assigns.metrics, metric);
                socket.assign({metrics: metrics});
            case _:
                socket;
        };
    }
}
```




## Development Workflow

### 1. Component Creation
```bash
# Generate new component

mix haxe.gen.controller UserController --actions index,show,create,update,delete


mix haxe.gen.live UserLive --events search,select,delete


```

### 2. Schema Definition
```bash
# Generate Ecto schema
mix haxe.gen.schema User users name:string email:string:unique active:boolean
```

### 3. Testing
```bash
# Generate test file
mix haxe.gen.test UserServiceTest
```

## Quick Commands

### Development
```bash
# Compile once
npx haxe build.hxml

# Watch mode
mix compile.haxe --watch


# Start Phoenix
iex -S mix phx.server


# Run tests
mix test
```

### Code Generation
```bash
# Generate LLM docs
npx haxe build.hxml -D generate-llm-docs

# Extract patterns
npx haxe build.hxml -D extract-patterns
```

## Configuration Tips

### Optimization Flags
```hxml
# build.hxml additions for phoenix

-D phoenix-mode
-D enable-channels
-D enable-presence


-D liveview-mode
-D enable-pubsub
-D socket-optimization


```

### Environment Configuration
```elixir
# config/config.exs
config :test_template_vars,
  haxe_source: "src_haxe",
  haxe_target: "lib/generated",
  watch_enabled: Mix.env() == :dev
```

## Common Tasks


### Adding a New Page
1. Create controller in `src_haxe/controllers/`
2. Add route to `Router.hx`
3. Create view in `src_haxe/views/`
4. Add template in `src_haxe/templates/`



### Adding a New LiveView
1. Create LiveView in `src_haxe/live/`
2. Add route to router
3. Implement mount, handle_event, handle_info
4. Create HEEx template or use HXX




## Debugging Tips

### Source Mapping
```bash
# Map error to source
mix haxe.source_map lib/generated/user_service.ex 45 12
# Output: src_haxe/services/UserService.hx:23:8
```

### Compilation Errors
```bash
# Get detailed errors
mix haxe.errors --format json

# Check compilation status
mix haxe.status
```

### Performance Profiling
```bash
# Profile compilation
npx haxe build.hxml -D profile-compilation

# Analyze generated code
mix haxe.analyze lib/generated/
```

---

This documentation is specific to your phoenix project. It will grow as you develop your application.
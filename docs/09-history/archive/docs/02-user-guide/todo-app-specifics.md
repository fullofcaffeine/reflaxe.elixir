# Project-Specific Documentation: todo-app

**Template Type**: liveview  
**Generated**: 2025-08-12 22:15:57




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
# build.hxml additions for liveview


-D liveview-mode
-D enable-pubsub
-D socket-optimization


```

### Environment Configuration
```elixir
# config/config.exs
config :todo_app,
  haxe_source: "src_haxe",
  haxe_target: "lib/generated",
  watch_enabled: Mix.env() == :dev
```

## Common Tasks




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

This documentation is specific to your liveview project. It will grow as you develop your application.
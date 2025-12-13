# Full-Stack Development with Reflaxe.Elixir

## Overview

Reflaxe.Elixir enables **true full-stack development** with a single language - Haxe. Write your business logic, validation, and type definitions once, then compile to both Elixir (server-side) and JavaScript (client-side) with native async/await support.

## Architecture: Dual-Target Compilation

### The Full-Stack Pattern
```
                     Haxe Source Code
                          │
           ┌──────────────┼──────────────┐
           │              │              │
    Haxe→Elixir    Shared Logic    Haxe→JavaScript
    (server-side)  (validation,    (client-side)
                   types, etc.)
           │              │              │
    Phoenix LiveView    Business      Modern JS + async/await
    Real-time UI        Rules         Client Interactions
```

### Key Benefits
1. **Unified Type System**: Same types, same validation, zero mismatch
2. **Shared Business Logic**: Write validation once, use everywhere
3. **Type-Safe APIs**: Compile-time guarantees across full stack
4. **Modern JavaScript**: Native async/await enables sophisticated client patterns
5. **Phoenix Integration**: Type-safe LiveView hooks and real-time features

## Async/Await: Enabling Modern Phoenix Development

### Why Async/Await Matters for Phoenix

Phoenix LiveView traditionally uses server-rendered HTML with minimal JavaScript. However, modern applications often need sophisticated client-side features:

- **File uploads with progress**
- **Real-time collaborative editing**  
- **Offline-first functionality**
- **Advanced animations and interactions**
- **Third-party API integration**

Our async/await implementation enables these patterns while maintaining type safety.

### Example: Type-Safe File Upload

```haxe
// Shared types (compile to both targets)
typedef UploadResult = {
    success: Bool,
    fileId: String,
    ?error: String
}

// Client-side (Haxe→JavaScript with async/await)
@:async
function uploadFile(file: js.html.File): js.lib.Promise<UploadResult> {
    var formData = new js.html.FormData();
    formData.append("file", file);
    
    var response = Async.await(fetch("/api/upload", {
        method: "POST",
        body: formData
    }));
    
    var result: UploadResult = Async.await(response.json());
    return result;
}

// Server-side (Haxe→Elixir)
@:native("MyApp.UploadController")
extern class UploadController {
    public static function create(params: Dynamic): UploadResult;
}
```

**Generated JavaScript (client)**:
```javascript
async function uploadFile(file) {
    let formData = new FormData();
    formData.append("file", file);
    
    let response = await fetch("/api/upload", {
        method: "POST", 
        body: formData
    });
    
    let result = await response.json();
    return result;
}
```

**Generated Elixir (server)**:
```elixir
defmodule MyApp.UploadController do
  def create(params) do
    # Handles upload logic
    %{success: true, file_id: generated_id}
  end
end
```

## Development Workflow

### Project Structure
```
phoenix_app/
├── src_haxe/
│   ├── shared/           # Shared types and business logic
│   │   ├── Types.hx      # API types, domain objects
│   │   └── Validation.hx # Shared validation logic
│   ├── client/           # Client-side code (Haxe→JS)
│   │   ├── TodoApp.hx    # Main client entry point
│   │   └── hooks/        # LiveView hooks
│   └── server/           # Server-side code (Haxe→Elixir)
│       ├── Controllers/  # Phoenix controllers
│       ├── LiveViews/    # LiveView components
│       └── Schemas/      # Ecto schemas
├── lib/                  # Generated Elixir code
├── assets/js/            # Generated JavaScript
└── build-client.hxml     # Client compilation config
└── build-server.hxml     # Server compilation config
```

### Build Configuration

**Client Build (build-client.hxml)**:
```hxml
# Haxe→JavaScript compilation for Phoenix client-side
-cp src_haxe/client
-cp src_haxe

# Enable Genes ES6 generator (uses haxe_libraries/genes.hxml)
-lib genes

# Modern JavaScript output
-js assets/js/hx_app.js
-D js-unflatten
--dce=full

# Source maps for debugging
-D real-position
-D js-source-map

# Exclude server code from client compilation
--macro exclude('server')

# Main client entry point
-main client.Boot
```

**Server Build (build-server.hxml)**:
```hxml
# Haxe→Elixir compilation for Phoenix server-side
-lib reflaxe.elixir

-cp src_haxe
-cp src_haxe/server
-cp src_haxe/shared

-D elixir_output=lib
-D reflaxe_runtime

# Main entry point
TodoApp
```

### Development Commands

```bash
# Start dual-target watch mode
npm run dev:full-stack

# Client-only development
npm run dev:client
haxe build-client.hxml --wait

# Server-only development  
npm run dev:server
haxe build-server.hxml --wait

# Build for production
npm run build:all
```

## Shared Business Logic Patterns

### 1. Validation Logic

Write validation once, use everywhere:

```haxe
// shared/TodoValidation.hx
class TodoValidation {
    public static function validateTitle(title: String): Result<String, String> {
        if (title.length == 0) {
            return Error("Title cannot be empty");
        }
        if (title.length > 100) {
            return Error("Title too long (max 100 characters)");
        }
        return Ok(title.trim());
    }
    
    public static function validateTodo(todo: TodoInput): Result<Todo, Array<String>> {
        var errors: Array<String> = [];
        
        var titleResult = validateTitle(todo.title);
        if (titleResult.isError()) {
            errors.push(titleResult.unwrapError());
        }
        
        if (errors.length > 0) {
            return Error(errors);
        }
        
        return Ok({
            id: todo.id,
            title: titleResult.unwrap(),
            completed: todo.completed,
            createdAt: Date.now()
        });
    }
}
```

**Usage (Client)**:
```haxe
@:async  
function submitTodo(formData: TodoInput): js.lib.Promise<Void> {
    var validation = TodoValidation.validateTodo(formData);
    
    switch (validation) {
        case Ok(todo):
            var result = Async.await(api.createTodo(todo));
            showSuccess("Todo created!");
            
        case Error(errors):
            showErrors(errors);
    }
}
```

**Usage (Server)**:
```haxe
@:liveview
class TodoLive {
    public static function handle_event("create_todo", params, socket) {
        var validation = TodoValidation.validateTodo(params);
        
        switch (validation) {
            case Ok(todo):
                TodoContext.create(todo);
                return socket.assign({todos: TodoContext.list()});
                
            case Error(errors):
                return socket.assign({errors: errors});
        }
    }
}
```

### 2. Type-Safe API Contracts

```haxe
// shared/ApiTypes.hx
typedef CreateTodoRequest = {
    title: String,
    ?description: String
}

typedef CreateTodoResponse = {
    success: Bool,
    ?todo: Todo,
    ?errors: Array<String>
}

// Client implementation
@:async
function createTodo(request: CreateTodoRequest): js.lib.Promise<CreateTodoResponse> {
    var response = Async.await(fetch("/api/todos", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(request)
    }));
    
    return Async.await(response.json());
}

// Server implementation (via extern)
@:native("MyApp.TodoController")
extern class TodoController {
    public static function create(request: CreateTodoRequest): CreateTodoResponse;
}
```

### 3. Real-Time Features with Type Safety

```haxe
// shared/Events.hx
enum TodoEvent {
    TodoCreated(todo: Todo);
    TodoUpdated(id: String, changes: Dynamic);
    TodoDeleted(id: String);
}

// Client event handling
@:async
function handleTodoEvent(event: TodoEvent): js.lib.Promise<Void> {
    switch (event) {
        case TodoCreated(todo):
            addTodoToUI(todo);
            
        case TodoUpdated(id, changes):
            updateTodoInUI(id, changes);
            
        case TodoDeleted(id):
            removeTodoFromUI(id);
    }
}

// Server event broadcasting (Elixir)
@:native("Phoenix.PubSub")
extern class PubSub {
    public static function broadcast(topic: String, event: TodoEvent): Void;
}
```

## Performance Considerations

### JavaScript Bundle Optimization

With async/await and modern JavaScript, bundle size becomes important:

```hxml
# Production build optimizations
-D js-es6                    # Modern syntax for better tree-shaking
-D analyzer-optimize         # Enable Haxe optimizations
--dce=full                   # Dead code elimination
-D js-unflatten             # Better module structure
```

**Target**: < 150KB compressed JavaScript bundle

### Compilation Performance

Dual-target compilation can be resource-intensive:

```bash
# Parallel compilation
npm run build:client & npm run build:server & wait

# Incremental development
npm run dev:watch  # Watches both targets efficiently
```

### Hot Reload Integration

Phoenix LiveView + Haxe hot reload:

```javascript
// Generated app.js integration
if (module.hot) {
    module.hot.accept(() => {
        // Re-initialize Haxe components
        TodoApp.main();
    });
}
```

## Testing Strategy

### Shared Logic Testing

Test validation and business logic once:

```haxe
// test/shared/TodoValidationTest.hx  
class TodoValidationTest {
    @Test
    public function testValidTitle() {
        var result = TodoValidation.validateTitle("Valid title");
        Assert.isTrue(result.isOk());
        Assert.equals("Valid title", result.unwrap());
    }
    
    @Test 
    public function testEmptyTitle() {
        var result = TodoValidation.validateTitle("");
        Assert.isTrue(result.isError());
        Assert.equals("Title cannot be empty", result.unwrapError());
    }
}
```

### Client-Side Testing

Test async/await patterns:

```haxe
// test/client/ApiTest.hx
class ApiTest {
    @Test @:async
    public function testCreateTodo() {
        var request: CreateTodoRequest = {title: "Test todo"};
        var response = Async.await(createTodo(request));
        
        Assert.isTrue(response.success);
        Assert.isNotNull(response.todo);
    }
}
```

### Integration Testing

Test full-stack workflows:

```haxe
// test/integration/TodoFlowTest.hx
class TodoFlowTest {
    @Test @:async
    public function testCreateTodoFlow() {
        // 1. Validate on client
        var input = {title: "Integration test"};
        var validation = TodoValidation.validateTodo(input);
        Assert.isTrue(validation.isOk());
        
        // 2. Submit to server
        var response = Async.await(createTodo(input));
        Assert.isTrue(response.success);
        
        // 3. Verify in database (via Elixir)
        var todos = TodoContext.list();
        Assert.equals(1, todos.length);
    }
}
```

## Migration Strategies

### From Manual JavaScript + Elixir

1. **Start with shared types**: Move API contracts to Haxe
2. **Migrate validation**: Convert validation logic to shared modules
3. **Replace JavaScript gradually**: Component by component
4. **Convert server logic**: LiveViews, controllers, contexts

### From TypeScript + Elixir

1. **Type definition conversion**: TypeScript interfaces → Haxe typedefs
2. **Async/await translation**: Direct conversion to Haxe patterns
3. **Build integration**: Replace TypeScript compiler with Haxe
4. **Server unification**: Gradually convert Elixir to Haxe

## Best Practices

### 1. Shared Module Organization
```
shared/
├── types/          # Data structures
├── validation/     # Business rules  
├── api/           # API contracts
└── events/        # Real-time event types
```

### 2. Error Handling Patterns
- Use `Result<T, E>` for operations that can fail
- Use `Option<T>` for values that may be absent
- Consistent error types across client and server

### 3. Async/Await Guidelines
- Always type Promise return values: `js.lib.Promise<T>`
- Use try/catch for error handling in async functions
- Prefer async/await over Promise chains for readability

### 4. LiveView Integration
- Keep LiveView components simple and stateless
- Move complex logic to shared business rule modules
- Use async JavaScript hooks for client-side enhancements

## Troubleshooting

### Common Issues

**1. Type Mismatches Between Targets**
```haxe
// Problem: Different serialization
// Solution: Explicit type conversions
function serialize(todo: Todo): Dynamic {
    return {
        id: todo.id,
        title: todo.title,
        completed: todo.completed
    };
}
```

**2. Async/Await Compilation Errors**
```haxe
// Problem: Missing @:async annotation
// Solution: Always annotate async functions
@:async
function loadData(): js.lib.Promise<String> {
    return Async.await(fetchData());
}
```

**3. Module Resolution Issues**
```hxml
# Problem: Can't find shared modules
# Solution: Add shared path to both builds
-cp src_haxe/shared
```

### Debugging Tips

1. **Use source maps**: Enable `-D js-source-map` for client debugging
2. **Check compilation order**: Shared modules must compile first
3. **Verify extern definitions**: Ensure Elixir externs match actual modules
4. **Test incrementally**: Start with simple shared types, add complexity gradually

## Future Enhancements

### Planned Features
- [ ] **Generator functions**: `async function*` support for streams
- [ ] **Top-level await**: Module-level async initialization
- [ ] **Service workers**: Offline-first patterns with type safety
- [ ] **WebAssembly target**: Performance-critical client code

### Experimental Ideas
- [ ] **Isomorphic rendering**: Same templates on client and server
- [ ] **State synchronization**: Automatic client-server state sync
- [ ] **Code splitting**: Automatic bundle optimization
- [ ] **Progressive enhancement**: Graceful degradation patterns

---

**The full-stack development capability positions Reflaxe.Elixir as a unique solution in the Phoenix ecosystem, enabling developers to build sophisticated applications with a single language while maintaining the performance and reliability of idiomatic Elixir and modern JavaScript.**

# Pure-Haxe Architecture for Phoenix LiveView

## Philosophy

**Everything in Haxe. Elixir and JavaScript are compilation targets, not development languages.**

This document outlines the architectural principles and patterns for building Phoenix LiveView applications using a pure-Haxe approach, where all application logic is written in Haxe and compiled to both Elixir (server) and JavaScript (client).

## Core Principles

### 1. **Single Source of Truth**
All business logic, types, and application behavior is defined in Haxe. The only exceptions are:
- Phoenix framework configuration files
- Database configuration
- Deployment scripts

### 2. **Shared Type System**
Client and server share the same type definitions, ensuring consistency and preventing runtime type errors:

```haxe
// shared/TodoTypes.hx - Used by both client and server
typedef Todo = {
    id: Int,
    title: String,
    completed: Bool,
    priority: TodoPriority,
    user_id: Int
};

typedef TodoEvents = {
    toggle_todo: {id: Int},
    create_todo: {title: String, description: String},
    delete_todo: {id: Int}
};
```

### 3. **Dual-Target Compilation**
```
                    Haxe Source
                        │
                   ┌────┴────┐
                   ▼         ▼
               Server      Client
           (Haxe→Elixir)  (Haxe→JS)
                   │         │
                   ▼         ▼
              BEAM VM    Browser
```

### 4. **Type-Safe Integration**
Phoenix LiveView hooks, templates, and business logic are all type-checked at compile time.

## Architecture Overview

### Directory Structure

```
src_haxe/
├── shared/              # Types and interfaces used by both targets
│   ├── TodoTypes.hx    # Data structures
│   └── Events.hx       # Event definitions
├── server/             # Server-side code (Haxe→Elixir)
│   ├── live/           # LiveView components
│   ├── schemas/        # Database schemas
│   ├── templates/      # HXX templates
│   ├── layouts/        # Layout components
│   ├── contexts/       # Business logic
│   └── migrations/     # Database migrations
├── client/             # Client-side code (Haxe→JavaScript)
│   ├── hooks/          # LiveView hooks
│   ├── utils/          # Browser utilities
│   └── extern/         # JavaScript API definitions
└── test/               # Tests for both targets
    ├── server/         # ExUnit tests (Haxe→Elixir)
    └── client/         # JavaScript tests (Haxe→JS)
```

### Build System

**Dual-target compilation** with separate build files:

```hxml
# build-server.hxml (Haxe→Elixir)
-cp src_haxe/server
-cp src_haxe/shared
-D elixir_output=lib
-D reflaxe_runtime
--macro reflaxe.elixir.CompilerInit.Start()
```

```hxml
# build-client.hxml (Haxe→JavaScript)
-cp src_haxe/client
-cp src_haxe/shared
-js assets/js/app.js
-D js-es=6
-D dce=full
```

## Server-Side Architecture (Haxe→Elixir)

### LiveView Components

**Type-safe LiveView development:**

```haxe
// server/live/TodoLive.hx
@:liveview
class TodoLive {
    var todos: Array<Todo> = [];
    var current_user: User;
    var filter: TodoFilter = All;
    
    public static function mount(params: MountParams, session: Session, socket: Socket): Socket {
        var user = getUserFromSession(session);
        var todos = loadUserTodos(user.id);
        
        return socket.assign({
            todos: todos,
            current_user: user,
            filter: All
        });
    }
    
    public static function handle_event(event: String, params: Dynamic, socket: Socket): Socket {
        return switch (event) {
            case "toggle_todo":
                var id = params.id;
                toggleTodo(id);
                socket.assign({todos: loadUserTodos(socket.assigns.current_user.id)});
                
            case "create_todo":
                var todo = createTodo(params, socket.assigns.current_user.id);
                socket.assign({todos: loadUserTodos(socket.assigns.current_user.id)});
                
            case _: 
                socket;
        };
    }
    
    public static function render(assigns: Dynamic): String {
        return TodoTemplate.render(assigns);
    }
}
```

### Schema Definitions

**Type-safe database schemas:**

```haxe
// server/schemas/Todo.hx
@:schema("todos")
class Todo {
    @:primary_key
    public var id: Int;
    
    @:required
    public var title: String;
    
    public var description: Null<String>;
    
    @:default(false)
    public var completed: Bool;
    
    @:default("medium")
    public var priority: String;
    
    @:foreign_key("users", "id")
    public var user_id: Int;
    
    @:timestamps
    public var inserted_at: String;
    public var updated_at: String;
    
    public static function changeset(todo: Todo, attrs: Dynamic): Changeset {
        return todo
            |> cast(attrs, ["title", "description", "completed", "priority"])
            |> validate_required(["title"])
            |> validate_length("title", min: 1, max: 255);
    }
}
```

### Template System (HXX)

**Type-safe templates with HXX:**

```haxe
// server/templates/TodoTemplate.hx
class TodoTemplate {
    public static function render(assigns: Dynamic): String {
        return HXX.hxx('
            <div class="todo-app">
                <h1>Todo Dashboard</h1>
                <div class="stats">
                    <span>Total: ${assigns.total_todos}</span>
                    <span>Completed: ${assigns.completed_todos}</span>
                </div>
                ${renderTodoList(assigns.todos)}
            </div>
        ');
    }
    
    private static function renderTodoList(todos: Array<Todo>): String {
        return HXX.hxx('
            <div class="todo-list">
                <%= for todo <- todos do %>
                    ${renderTodoItem(todo)}
                <% end %>
            </div>
        ');
    }
}
```

## Client-Side Architecture (Haxe→JavaScript)

### LiveView Hooks

**Type-safe browser interactions:**

```haxe
// client/hooks/AutoFocus.hx
class AutoFocus implements LiveViewHook {
    public var el: Element;
    
    public function mounted(): Void {
        el.focus();
    }
    
    public function updated(): Void {
        if (shouldRefocus()) {
            el.focus();
        }
    }
    
    private function shouldRefocus(): Bool {
        return el.getAttribute("data-refocus") == "true";
    }
}
```

### Browser Utilities

**Type-safe browser APIs:**

```haxe
// client/utils/LocalStorage.hx
class LocalStorage {
    public static function setObject(key: String, value: Dynamic): Void {
        if (isAvailable()) {
            js.Browser.getLocalStorage().setItem(key, haxe.Json.stringify(value));
        }
    }
    
    public static function getObject(key: String, ?defaultValue: Dynamic): Dynamic {
        if (!isAvailable()) return defaultValue;
        
        var item = js.Browser.getLocalStorage().getItem(key);
        return item != null ? haxe.Json.parse(item) : defaultValue;
    }
}
```

### Integration Layer

**Clean Phoenix integration:**

```haxe
// client/TodoApp.hx
class TodoApp {
    public static function main(): Void {
        // Export hooks for Phoenix LiveView
        exportHooks();
        
        // Initialize client-side features
        initializeUtilities();
    }
    
    private static function exportHooks(): Void {
        var hooks = Hooks.getAll();
        untyped __js__("
            if (typeof window !== 'undefined') {
                window.TodoAppHooks = {0};
            }
        ", hooks);
    }
}
```

## Type System Benefits

### 1. **Shared Data Structures**

**Server validation:**
```haxe
// server/contexts/Todos.hx
public static function createTodo(attrs: TodoCreateRequest): Result<Todo, Error> {
    return switch (validateTodoRequest(attrs)) {
        case Success(validAttrs): 
            Success(insertTodo(validAttrs));
        case Failure(errors): 
            Failure(errors);
    };
}
```

**Client validation (same types):**
```haxe
// client/hooks/TodoForm.hx
private function validateForm(): Bool {
    var request: TodoCreateRequest = getFormData();
    return TodoValidator.isValid(request); // Same validation logic
}
```

### 2. **Event Type Safety**

**Server event handling:**
```haxe
public static function handle_event(event: String, params: Dynamic, socket: Socket): Socket {
    var typedEvent: TodoEvents = cast params;
    return switch (event) {
        case "toggle_todo": handleToggleTodo(typedEvent.toggle_todo, socket);
        case "create_todo": handleCreateTodo(typedEvent.create_todo, socket);
        case "delete_todo": handleDeleteTodo(typedEvent.delete_todo, socket);
    };
}
```

**Client event dispatching:**
```haxe
private function toggleTodo(id: Int): Void {
    var event: TodoEvents.toggle_todo = {id: id};
    pushEvent("toggle_todo", event);
}
```

### 3. **API Contract Enforcement**

```haxe
// shared/ApiTypes.hx
typedef ApiResponse<T> = {
    status: ApiStatus,
    data: Null<T>,
    errors: Null<Array<String>>
};

enum ApiStatus {
    Success;
    Error;
    ValidationFailed;
}
```

Both client and server use the same API types, preventing mismatches.

## Testing Strategy

### Server-Side Testing (ExUnit in Haxe)

```haxe
// test/server/TodoLiveTest.hx
@:exunit
class TodoLiveTest extends TestCase {
    @:test
    public function testMountShowsTodos(): Void {
        var user = createTestUser();
        var todos = createTestTodos(user);
        
        var result = TodoLive.mount({}, {user_id: user.id}, testSocket());
        
        Assert.equals(todos.length, result.assigns.todos.length);
    }
}
```

### Client-Side Testing (JavaScript tests in Haxe)

```haxe
// test/client/LocalStorageTest.hx
class LocalStorageTest {
    @:test
    public function testSetAndGetObject(): Void {
        var testData = {name: "Test", count: 42};
        
        LocalStorage.setObject("test", testData);
        var retrieved = LocalStorage.getObject("test");
        
        Assert.equals(testData.name, retrieved.name);
        Assert.equals(testData.count, retrieved.count);
    }
}
```

## Development Workflow

### 1. **Define Types First**

```haxe
// shared/NewFeatureTypes.hx
typedef NewFeature = {
    id: Int,
    name: String,
    enabled: Bool
};

typedef NewFeatureEvents = {
    toggle_feature: {id: Int},
    create_feature: {name: String}
};
```

### 2. **Implement Server Logic**

```haxe
// server/live/NewFeatureLive.hx
@:liveview
class NewFeatureLive {
    // Implementation using shared types
}
```

### 3. **Implement Client Interactions**

```haxe
// client/hooks/NewFeatureHook.hx
class NewFeatureHook implements LiveViewHook {
    // Implementation using shared types
}
```

### 4. **Write Tests**

```haxe
// test/server/NewFeatureTest.hx
// test/client/NewFeatureTest.hx
```

### 5. **Compile and Test**

```bash
# Compile server code
haxe build-server.hxml

# Compile client code  
haxe build-client.hxml

# Run tests
mix test              # Server tests
npm test             # Client tests
```

## Benefits of Pure-Haxe Approach

### 1. **Type Safety Everywhere**
- No runtime type errors between client/server
- Compile-time validation of all data flows
- Refactoring safety across the entire stack

### 2. **Single Language Expertise**
- No context switching between languages
- Unified development patterns
- Shared libraries and utilities

### 3. **Maintainability**
- DRY principle across the stack
- Centralized business logic
- Consistent error handling

### 4. **Developer Productivity**
- IDE support across the entire codebase
- Unified debugging experience
- Faster development cycles

### 5. **Quality Assurance**
- Compiler catches many runtime errors
- Shared test utilities
- Consistent API contracts

## Migration Strategy

### From Mixed Stack to Pure-Haxe

1. **Start with shared types**
   ```haxe
   // Define data structures in shared/
   ```

2. **Convert templates to HXX**
   ```haxe
   // Replace .heex with .hx templates
   ```

3. **Migrate JavaScript to Haxe hooks**
   ```haxe
   // Replace manual JS with typed hooks
   ```

4. **Add server-side business logic**
   ```haxe
   // Move complex logic to Haxe contexts
   ```

5. **Implement comprehensive testing**
   ```haxe
   // Type-safe tests for both targets
   ```

## Best Practices

### 1. **Keep Shared Code Pure**
- No target-specific code in `shared/`
- Use abstracts for target-specific implementations
- Document shared interfaces clearly

### 2. **Use Type-Safe Patterns**
```haxe
// Instead of Dynamic
var data: Dynamic = response.data;

// Use proper types
var data: ApiResponse<Array<Todo>> = response.data;
```

### 3. **Leverage Compiler Features**
```haxe
// Use enums for state
enum ConnectionStatus {
    Connected;
    Disconnected;
    Reconnecting;
}

// Use abstracts for type safety
abstract UserId(Int) from Int to Int {
    public function toString(): String return 'User#$this';
}
```

### 4. **Design for Both Targets**
- Consider browser limitations for client code
- Consider BEAM patterns for server code
- Use conditional compilation when necessary

```haxe
#if client
    // Browser-specific implementation
#elseif server
    // BEAM-specific implementation
#end
```

## Limitations and Trade-offs

### 1. **Learning Curve**
- Developers need Haxe expertise
- Understanding of both compilation targets
- Phoenix LiveView patterns in Haxe context

### 2. **Tooling Maturity**
- Less mature than pure Elixir or JavaScript tooling
- Custom development environment setup
- Debugging across compilation boundaries

### 3. **Performance Considerations**
- Compilation time for large codebases
- Runtime overhead from Haxe abstractions
- Bundle size considerations for client code

### 4. **Community and Ecosystem**
- Smaller community than mainstream languages
- Fewer third-party libraries
- Need to write more extern definitions

## Conclusion

The pure-Haxe architecture provides:

- ✅ **Unprecedented type safety** across the entire stack
- ✅ **Unified development experience** with a single language
- ✅ **Shared business logic** and data structures
- ✅ **Compile-time error prevention** 
- ✅ **Maintainable, refactorable codebase**

While there are trade-offs in terms of learning curve and tooling maturity, the benefits of type safety, maintainability, and developer productivity make this approach compelling for teams willing to invest in the Haxe ecosystem.

The todo-app example demonstrates how this architecture can create production-ready Phoenix LiveView applications with the quality and type safety typically associated with languages like Elm or PureScript, while maintaining the performance and ecosystem benefits of Elixir and JavaScript.
# Constructor Paradigm Translation: Haxe `new` → Elixir Initialization Patterns

## Executive Summary

The Haxe `new` keyword doesn't have a direct equivalent in Elixir. Instead, Elixir uses various initialization patterns depending on the semantic purpose of the "class". This document defines how Reflaxe.Elixir translates constructor calls into idiomatic Elixir patterns.

## The Fundamental Challenge

**Haxe (OOP)**: Uses `new ClassName()` for all object creation
**Elixir (Functional)**: Uses different patterns based on the type:
- Structs: `%ModuleName{}`
- Processes: `ModuleName.start_link()`
- Modules: `ModuleName.new()` or `ModuleName.init()`
- Behaviors: Callback functions like `init/1`, `mount/3`

## Translation Rules by Context

### 1. Ecto Schemas → Struct Literals

**Detection**: Classes with `@:schema` annotation
**Translation**: `new Todo()` → `%TodoApp.Todo{}`

```haxe
// Haxe source
@:native("TodoApp.Todo")
@:schema("todos")
class Todo {
    var title: String;
    var completed: Bool = false;
}

var todo = new Todo();
todo.title = "Learn Haxe";
```

```elixir
# Generated Elixir
todo = %TodoApp.Todo{
  title: "Learn Haxe",
  completed: false
}
```

**Why**: Ecto schemas are just structs with metadata. They don't have constructors - they use struct literal syntax.

### 2. GenServers → start_link Pattern

**Detection**: Classes with `@:genserver` annotation
**Translation**: `new Worker(args)` → `Worker.start_link(args)`

```haxe
// Haxe source
@:genserver
class TodoWorker {
    public function new(initial_state) {
        // Constructor becomes init callback
    }
    
    public function handleCall(msg, from, state) {
        // Handler implementation
    }
}

var worker = new TodoWorker({todos: []});
```

```elixir
# Generated Elixir
{:ok, worker} = TodoWorker.start_link(%{todos: []})

defmodule TodoWorker do
  use GenServer
  
  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state)
  end
  
  def init(initial_state) do
    # Constructor body goes here
    {:ok, initial_state}
  end
end
```

**Why**: GenServers are processes that need supervision. They're started, not constructed.

### 3. Phoenix LiveViews → No Constructor

**Detection**: Classes with `@:liveview` annotation
**Translation**: No `new` calls - LiveViews are mounted by Phoenix

```haxe
// Haxe source
@:liveview
class TodoLive {
    // No constructor - use mount instead
    public function mount(params, session, socket) {
        return socket.assign({todos: []});
    }
}
// Never call: new TodoLive() - Phoenix handles instantiation
```

```elixir
# Generated Elixir
defmodule TodoAppWeb.TodoLive do
  use Phoenix.LiveView
  
  def mount(params, session, socket) do
    {:ok, assign(socket, todos: [])}
  end
end
```

**Why**: LiveViews are managed by Phoenix. The framework handles their lifecycle.

### 4. Data Structures → Appropriate Initialization

**Detection**: Standard library types
**Translation**: Context-dependent

```haxe
// Haxe source
var map = new Map<String, Int>();
var list = new List<String>();
var array = new Array<Int>();
var stringBuf = new StringBuf();
```

```elixir
# Generated Elixir
map = %{}
list = []
array = []
string_buf = []  # IOList pattern
```

**Why**: Elixir has native syntax for common data structures.

### 5. Regular Classes → Module Functions

**Detection**: Classes without special annotations
**Translation**: `new Helper(arg)` → `Helper.new(arg)`

```haxe
// Haxe source
class TodoFormatter {
    var format: String;
    
    public function new(format: String) {
        this.format = format;
    }
    
    public function format(todo: Todo): String {
        // Format implementation
    }
}

var formatter = new TodoFormatter("markdown");
```

```elixir
# Generated Elixir
defmodule TodoFormatter do
  defstruct [:format]
  
  def new(format) do
    %TodoFormatter{format: format}
  end
  
  def format(%TodoFormatter{} = formatter, todo) do
    # Format implementation
  end
end

formatter = TodoFormatter.new("markdown")
```

**Why**: Regular classes become modules with structs. The `new` function is a factory.

### 6. Changesets → Special Factory Pattern

**Detection**: Changeset type usage
**Translation**: `new Changeset(struct, params)` → `Changeset.cast(struct, params, fields)`

```haxe
// Haxe source
var changeset = new Changeset(todo, params);
changeset.validateRequired(["title"]);
```

```elixir
# Generated Elixir
changeset = Ecto.Changeset.cast(todo, params, [:title, :completed])
|> Ecto.Changeset.validate_required([:title])
```

**Why**: Changesets have a specific API for validation pipelines.

## Compiler Implementation Strategy

### AST Detection in ElixirASTBuilder

```haxe
case TNew(c, params, el):
    var classType = c.get();
    var moduleName = extractModuleName(classType);
    
    // Contextual detection
    if (classType.meta.has(":schema")) {
        // Ecto schema - generate struct literal
        return EStruct(moduleName, extractFieldAssignments(el));
        
    } else if (classType.meta.has(":genserver")) {
        // GenServer - generate start_link call
        return ETuple([
            EAtom("ok"),
            ECall(EField(moduleName, "start_link"), el)
        ]);
        
    } else if (classType.meta.has(":liveview")) {
        // LiveView - should never be instantiated with new
        Context.error("LiveView components cannot be instantiated with new()", pos);
        
    } else if (isStandardDataStructure(classType)) {
        // Data structures - use native syntax
        return generateDataStructureInit(classType, el);
        
    } else {
        // Regular class - module function
        return ECall(EField(moduleName, "new"), el);
    }
```

## Annotation Reference

| Annotation | Constructor Pattern | Elixir Output |
|------------|-------------------|---------------|
| `@:schema` | `new Schema()` | `%Module{}` |
| `@:genserver` | `new Server(args)` | `{:ok, pid} = Server.start_link(args)` |
| `@:supervisor` | `new Supervisor(children)` | `Supervisor.start_link(children, opts)` |
| `@:liveview` | Not allowed | Error: LiveViews can't be instantiated |
| `@:changeset` | `new Changeset(s, p)` | `Changeset.cast(s, p, fields)` |
| `@:struct` | `new Struct()` | `%Module{}` |
| None | `new Class(args)` | `Module.new(args)` |

## User Guidelines

### When to Use Which Pattern

1. **Database Models**: Use `@:schema`
   ```haxe
   @:schema("users")
   class User {
       var name: String;
       var email: String;
   }
   ```

2. **Background Workers**: Use `@:genserver`
   ```haxe
   @:genserver
   class EmailWorker {
       public function new(config) { }
       public function sendEmail(to: String, body: String) { }
   }
   ```

3. **Web Components**: Use `@:liveview`
   ```haxe
   @:liveview
   class UserDashboard {
       public function mount(params, session, socket) { }
       public function handleEvent(event, params, socket) { }
   }
   ```

4. **Utility Classes**: No annotation needed
   ```haxe
   class StringUtils {
       public static function titleCase(s: String): String { }
   }
   ```

## Migration Guide

### From Traditional OOP

**Before (Java/C#/etc)**:
```java
User user = new User();
user.setName("Alice");
UserService service = new UserService(database);
service.save(user);
```

**After (Haxe→Elixir)**:
```haxe
@:schema("users")
class User {
    var name: String;
}

@:context
class Users {
    public static function createUser(attrs: {name: String}) {
        var user = new User();  // Generates: %User{}
        var changeset = User.changeset(user, attrs);
        return Repo.insert(changeset);
    }
}
```

## Common Pitfalls

### ❌ Don't Call new on LiveViews
```haxe
// WRONG - LiveViews are managed by Phoenix
var live = new TodoLive();
```

### ❌ Don't Expect Mutable State
```haxe
// WRONG - Elixir is immutable
var todo = new Todo();
todo.title = "New Title";  // This creates a new struct!
```

### ✅ Use Update Patterns
```haxe
// RIGHT - Functional update
var todo = new Todo();
todo = Todo.update(todo, {title: "New Title"});
```

## Future Enhancements

1. **Smart Detection**: Detect patterns without annotations
2. **Custom Constructors**: `@:constructor("init")` to override name
3. **Factory Methods**: `@:factory` for complex initialization
4. **Builder Pattern**: Support for fluent interfaces
5. **Pooled Resources**: Connection pool initialization patterns

## Testing Patterns

```haxe
// Test schema creation
function testSchemaCreation() {
    var todo = new Todo();  // %Todo{}
    Assert.equals(todo.completed, false);
}

// Test GenServer startup
function testWorkerStartup() {
    var result = new TodoWorker({});  // {:ok, pid} = TodoWorker.start_link({})
    Assert.isTrue(Process.alive(result));
}
```

## Current Implementation Status

| Pattern | Status | Notes |
|---------|--------|-------|
| Ecto Schemas | ✅ Implemented | Generates struct literals `%Module{}` when `@:schema` detected |
| Regular Classes | ⚠️ Partial | Still generates `Module.new()` - needs defstruct support |
| GenServers | ❌ Not Implemented | Should generate `Module.start_link()` when `@:genserver` detected |
| Data Structures | ✅ Implemented | Arrays, Maps use native Elixir syntax |
| LiveViews | ✅ N/A | Never use `new` - mounted by Phoenix framework |
| Changesets | ❌ Not Implemented | Should use `Changeset.cast()` pattern |

### Implementation Details

**Working Implementation (as of 2024-09-12):**
- Detection in `ElixirASTBuilder.hx` at TNew case
- Checks for `@:schema` metadata on class type
- Generates `EStruct(moduleName, [])` instead of `ECall(EField(EIdent(className), "new"), processedArgs)`
- Successfully tested in todo-app and constructor_patterns test

**Next Steps:**
1. Add `@:genserver` detection for start_link pattern
2. Implement defstruct generation for regular classes
3. Add changeset factory pattern support
4. Document limitations and migration path

## See Also

- [Ecto Schema Patterns](./ECTO_SCHEMA_PATTERNS.md)
- [OTP Behavior Compilation](./OTP_BEHAVIOR_COMPILATION.md)
- [Phoenix Component Architecture](./PHOENIX_COMPONENT_ARCHITECTURE.md)
- [Immutability Handling](./IMMUTABILITY_PATTERNS.md)
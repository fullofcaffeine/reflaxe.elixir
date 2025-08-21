# OTP Child Specifications in Haxe→Elixir

## What Are Child Specs?

Child specifications are instructions that tell OTP supervisors how to start, manage, and restart child processes. They're fundamental to building fault-tolerant Elixir applications.

In Elixir/OTP, supervisors use child specs to:
- **Start processes** with the correct arguments
- **Restart processes** when they crash (based on restart strategy)
- **Shut down processes** gracefully during application termination
- **Monitor process health** and implement fault tolerance

Child specs are the foundation of OTP's "let it crash" philosophy - they define exactly how processes should be restarted when failures occur.

## Evolution of Child Specs in Elixir

### 1. Old Map Format (Deprecated)

The original Elixir child spec format was verbose and error-prone:

```elixir
# Old explicit map format - deprecated
%{
  id: MyWorker,
  start: {MyWorker, :start_link, [arg1, arg2]},
  restart: :permanent,
  shutdown: 5000,
  type: :worker,
  modules: [MyWorker]
}
```

**Problems with old format:**
- **Verbose**: Required specifying all fields explicitly
- **Error-prone**: Easy to misconfigure restart strategies
- **Coupling**: Supervisor needed to know implementation details
- **Maintenance**: Changes required updating supervisor configurations

### 2. Modern Tuple Format (Current Best Practice)

Modern Elixir uses simplified tuple format where modules define their own `child_spec/1`:

```elixir
# Modern tuple format - modules handle their own specs
{Phoenix.PubSub, name: MyApp.PubSub}
{Phoenix.Endpoint, []}
{Ecto.Repo, []}
```

**Benefits of modern format:**
- **Self-contained**: Modules define their own restart behavior
- **Maintainable**: Changes stay with the module implementation
- **Flexible**: Modules can switch between worker/supervisor internally
- **Conventional**: Following Elixir ecosystem standards

### 3. Simple Module Reference (Simplest)

For modules that need no configuration:

```elixir
# Just the module name - uses default child_spec/1
MyApp.Repo
MyAppWeb.Endpoint
MyAppWeb.Telemetry
```

## Haxe Type Mapping

### Our Current Haxe ChildSpec Type

```haxe
typedef ChildSpec = {
    id: String,
    start: {module: String, func: String, args: Array<Dynamic>},
    ?restart: RestartType,
    ?shutdown: ShutdownType,
    ?type: ChildType,
    ?modules: Array<String>
}
```

### How It Currently Compiles to Elixir

| Haxe Input | Elixir Output | When Used |
|------------|---------------|-----------|
| Simple ChildSpec with only id + start | `{Module, args}` tuple | Phoenix.PubSub, Endpoint, Repo |
| Full ChildSpec with restart/shutdown | `%{id: ..., start: ..., restart: ...}` map | Custom workers with specific behavior |
| String module name | `ModuleName` | Simple modules with default child_spec/1 |

## Current Type Safety Limitations ⚠️

### 1. String-Based Module References
```haxe
// ❌ NOT TYPE-SAFE: Just strings, no compile-time validation
{
    id: "Phoenix.PubSub",           // Could be typo: "Phoenix.PubSub" 
    start: {
        module: "Phoenix.PubSub",   // No verification this module exists
        func: "start_link",         // Could be "start_lonk" typo
        args: [{name: "MyApp.PubSub"}]  // Dynamic - no type checking!
    }
}
```

**Problems:**
- No compile-time validation that modules exist
- Typos in function names won't be caught until runtime
- Arguments are completely untyped (Dynamic)
- No IntelliSense or autocomplete support
- Runtime failures when supervisor tries to start children

### 2. Dynamic Arguments with No Type Safety
```haxe
args: [{name: '${appName}.PubSub'}]  // Dynamic - anything goes!
```

This defeats Haxe's main value proposition: **compile-time type safety**.

## Future Type-Safe Design Proposals

### Option 1: Generic ChildSpec with Type Parameters
```haxe
// Type-safe child spec with module type parameter
typedef TypeSafeChildSpec<TModule, TArgs> = {
    module: Class<TModule>,
    args: TArgs,
    ?restart: RestartType,
    ?shutdown: ShutdownType
}

// Usage with actual types - full type safety!
var pubsubSpec: TypeSafeChildSpec<Phoenix.PubSub, {name: String}> = {
    module: Phoenix.PubSub,
    args: {name: "TodoApp.PubSub"}
};
```

### Option 2: Enum-Based ADT (Most Type-Safe)
```haxe
enum ChildSpec {
    // Each variant has specific typed arguments
    PubSub(name: String);
    Repo(?config: RepoConfig);
    Endpoint(?port: Int, ?config: EndpointConfig);
    Telemetry(?metrics: Array<Metric>);
    
    // Generic case for custom modules
    Custom<T>(
        module: Class<T>,
        args: T,
        ?restart: RestartType,
        ?shutdown: ShutdownType
    );
}

// Usage - fully type-safe with IntelliSense!
var children = [
    ChildSpec.PubSub("TodoApp.PubSub"),  // Autocomplete works!
    ChildSpec.Repo({database: "todo_app_dev"}),  // Type-checked args!
    ChildSpec.Endpoint(4000),
    ChildSpec.Custom(MyWorker, {timeout: 5000}, Permanent)
];
```

### Option 3: Module-Specific Builders
```haxe
// Each module provides its own type-safe builder
class Phoenix.PubSub {
    public static function childSpec(name: String): ChildSpec {
        return {
            module: Phoenix.PubSub,
            args: {name: name}
        };
    }
}

// Usage - type-safe and discoverable
var children = [
    Phoenix.PubSub.childSpec("TodoApp.PubSub"),      // Type-safe!
    TodoAppWeb.Endpoint.childSpec(),                 // Autocomplete!
    TodoApp.Repo.childSpec({pool_size: 10})         // Validated args!
];
```

## Usage Examples

### Current Phoenix Application (String-Based)
```haxe
// Current approach - not type-safe
var children: Array<ChildSpec> = [
    // Compiles to: {Phoenix.PubSub, name: TodoApp.PubSub}
    {
        id: "Phoenix.PubSub",
        start: {
            module: "Phoenix.PubSub", 
            func: "start_link", 
            args: [{name: "TodoApp.PubSub"}]  // Dynamic - no type checking
        }
    },
    
    // Compiles to: TodoAppWeb.Endpoint
    {
        id: "TodoAppWeb.Endpoint",
        start: {
            module: "TodoAppWeb.Endpoint", 
            func: "start_link", 
            args: []
        }
    }
];
```

### Future Type-Safe Application (Enum-Based)
```haxe
// Future approach - fully type-safe
var children = [
    ChildSpec.PubSub("TodoApp.PubSub"),  // ✅ Type-safe string
    ChildSpec.Endpoint(4000),            // ✅ Type-safe port number
    ChildSpec.Repo({                     // ✅ Type-safe config object
        database: "todo_app_dev",
        pool_size: 10,
        timeout: 15000
    }),
    ChildSpec.Custom(MyWorker, {         // ✅ Generic for custom modules
        config: "worker_config",
        retries: 3
    }, Transient)
];
```

## Key OTP Concepts

### Restart Strategies
- **`Permanent`**: Always restart on termination (default for most services)
- **`Temporary`**: Never restart (for one-time tasks)
- **`Transient`**: Restart only on abnormal termination (for optional services)

### Shutdown Strategies
- **`Brutal`**: Immediate termination with `Process.exit(pid, :kill)`
- **`Timeout(ms)`**: Grace period before forced termination
- **`Infinity`**: Wait indefinitely for graceful shutdown

### Child Types
- **`Worker`**: Performs actual work (GenServer, Agent, Task)
- **`Supervisor`**: Manages other processes (Supervisor, DynamicSupervisor)

### Supervisor Strategies
- **`OneForOne`**: Restart only the failed child
- **`OneForAll`**: Restart all children when one fails
- **`RestForOne`**: Restart failed child and all children started after it

## Best Practices

### 1. Prefer Module-Based Specs
```haxe
// ✅ GOOD: Let modules define their own behavior
var children = [
    MyApp.Repo,           // Uses default child_spec/1
    MyAppWeb.Endpoint,    // Module knows its restart strategy
    MyAppWeb.Telemetry    // Self-contained configuration
];

// ❌ AVOID: Explicit configuration unless needed
var children = [
    {
        id: "MyApp.Repo",
        start: {module: "MyApp.Repo", func: "start_link", args: []},
        restart: Permanent,  // Module already knows this!
        type: Worker
    }
];
```

### 2. Use Tuple Format for Phoenix Modules
```haxe
// ✅ GOOD: Phoenix modules implement child_spec/1
{Phoenix.PubSub, name: "MyApp.PubSub"}
{Phoenix.Presence, name: "MyApp.Presence"}

// ❌ AVOID: Verbose map format for standard modules
%{
  id: Phoenix.PubSub,
  start: {Phoenix.PubSub, :start_link, [[name: "MyApp.PubSub"]]},
  type: :supervisor
}
```

### 3. Keep Specs Close to Implementation
```haxe
// ✅ GOOD: Colocate child spec with module
class MyWorker {
    public static function start_link(config: WorkerConfig): Result<Pid, Error> {
        // Implementation
    }
    
    public static function child_spec(config: WorkerConfig): ChildSpec {
        return ChildSpec.Custom(MyWorker, config, Permanent);
    }
}
```

### 4. Use Type-Safe Configuration
```haxe
// ✅ GOOD: Type-safe configuration objects
typedef RepoConfig = {
    database: String,
    username: String,
    password: String,
    ?pool_size: Int,
    ?timeout: Int
}

// Use with full type safety
ChildSpec.Repo({
    database: "myapp_dev",
    username: "postgres", 
    password: "postgres",
    pool_size: 10
});
```

## Migration Strategy

### Phase 1: Document Current Limitations
- ✅ Identify type safety issues in current ChildSpec typedef
- ✅ Document problems with string-based approach
- ✅ Propose type-safe alternatives

### Phase 2: Design Type-Safe API
- 🔄 Design enum-based ChildSpec with type parameters
- 🔄 Create builder functions for common modules
- 🔄 Ensure backward compatibility during transition

### Phase 3: Implement New Types
- ⏳ Add TypeSafeChildSpec to `/std/elixir/otp/`
- ⏳ Create builders for Phoenix.PubSub, Repo, Endpoint
- ⏳ Update compiler to handle both old and new formats

### Phase 4: Update Applications
- ⏳ Migrate TodoApp to use type-safe child specs
- ⏳ Update documentation and examples
- ⏳ Create migration guide for existing projects

### Phase 5: Deprecate String-Based Approach
- ⏳ Add deprecation warnings to old ChildSpec typedef
- ⏳ Remove string-based support in future version
- ⏳ Full type safety achieved!

## Compiler Implementation Details

### Structure-Based Detection Algorithm

Instead of hardcoding module names, detect child spec format based on structure:

```haxe
function detectChildSpecFormat(fields: Array<ObjectField>): ChildSpecFormat {
    var hasRestart = fields.exists(f -> f.name == "restart");
    var hasShutdown = fields.exists(f -> f.name == "shutdown");
    var hasType = fields.exists(f -> f.name == "type");
    var hasModules = fields.exists(f -> f.name == "modules");
    
    if (!hasRestart && !hasShutdown && !hasType && !hasModules) {
        // Minimal spec with only id + start → Modern tuple format
        return ModernTuple;
    } else {
        // Full spec with restart/shutdown → Traditional map format  
        return TraditionalMap;
    }
}
```

This approach:
- **Scales automatically**: Works with any module, not just known ones
- **Future-proof**: No need to update compiler for new modules
- **Structure-based**: Decisions based on data, not string matching
- **Type-driven**: Aligns with type-safe child spec design

## Related Documentation

- [`/std/elixir/otp/Supervisor.hx`](/std/elixir/otp/Supervisor.hx) - Current ChildSpec typedef
- [`/documentation/FUNCTIONAL_PATTERNS.md`](/documentation/FUNCTIONAL_PATTERNS.md) - Result/Option patterns for error handling
- [`/documentation/TYPE_SAFETY.md`](/documentation/TYPE_SAFETY.md) - Type system guidelines
- [Elixir Supervisor Documentation](https://hexdocs.pm/elixir/Supervisor.html) - Official Elixir documentation

---

**The Goal**: Transform child specs from stringly-typed configuration to **compile-time type-safe supervision tree definitions** that leverage Haxe's type system while generating idiomatic Elixir code.
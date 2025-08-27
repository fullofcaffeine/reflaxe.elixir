# Project-Specific Documentation: test_llm_docs

**Template Type**: basic  
**Generated**: 2025-08-26 23:02:43






## Mix Project

### Project Structure

#### Modules
Business logic encapsulated in modules.

```haxe
@:module
class MyService {
    public static function process(data: Dynamic): Result<ProcessedData> {
        // Business logic here
        return {ok: processedData};
    }
}
```

#### GenServers
Background workers for concurrent processing.

```haxe
@:genserver
class Worker {
    public static function init(args) {
        return {ok: initialState};
    }
    
    public static function handle_call(request, from, state) {
        return {reply: response, state: newState};
    }
    
    public static function handle_cast(msg, state) {
        return {noreply: newState};
    }
}
```

#### Supervisors
Process supervision for fault tolerance.

```haxe
@:supervisor
class AppSupervisor {
    public static function init(args) {
        var children = [
            {id: "Worker", start: {Worker, "start_link", [[]]}}
        ];
        return {ok: {children: children, strategy: "one_for_one"}};
    }
}
```

### Basic Patterns

#### Service Pattern
```haxe
@:module
class DataService {
    public static function fetch(id: String): Result<Data> {
        try {
            var data = ExternalAPI.get(id);
            return Ok(data);
        } catch (e: Dynamic) {
            return Error('Failed to fetch: $e');
        }
    }
}
```

#### Pipeline Pattern
```haxe
@:module
class DataPipeline {
    public static function process(input: RawData): ProcessedData {
        return input
            |> validate()
            |> transform()
            |> enrich()
            |> finalize();
    }
}
```


## Development Workflow

### 1. Component Creation
```bash
# Generate new component



mix haxe.gen.module UserService --functions list,get,create,update,delete

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
# build.hxml additions for basic



-D standalone-mode
-D genserver-optimization

```

### Environment Configuration
```elixir
# config/config.exs
config :test_llm_docs,
  haxe_source: "src_haxe",
  haxe_target: "lib/generated",
  watch_enabled: Mix.env() == :dev
```

## Common Tasks






### Adding a New Service
1. Create service in `src_haxe/services/`
2. Add @:module annotation
3. Implement public static functions
4. Write tests in `test/`


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

This documentation is specific to your basic project. It will grow as you develop your application.
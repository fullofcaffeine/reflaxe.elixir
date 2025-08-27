# API Quick Reference for test_llm_docs

**Generated**: 2025-08-26 23:02:43

This reference will be populated as you build your application.

## Project Configuration

### Build Configuration

```hxml
-cp src_haxe
-lib reflaxe.elixir
-D reflaxe.output=lib/generated
-D reflaxe_runtime
--main Main

```

### Mix Configuration

```elixir
# mix.exs
def project do
  [
    app: :test_llm_docs,
    compilers: [:haxe] ++ Mix.compilers(),
    haxe: [
      source_dir: "src_haxe",
      target_dir: "lib/generated",
      hxml_file: "build.hxml"
    ]
  ]
end
```

## Project Modules

*Modules will be documented here as they are created*






### Service Modules
*Service modules will be listed here*

### GenServers
*Background workers will be listed here*


## Common Patterns

*Patterns will be extracted from your code automatically*

### Error Handling
```haxe
// Pattern will be extracted from your code
```

### Data Validation
```haxe
// Pattern will be extracted from your code
```

### Service Layer
```haxe
// Pattern will be extracted from your code
```

## Type Definitions

*Custom types will be documented here*

### Domain Types
```haxe
// Your custom types will appear here
```

### Result Types
```haxe
// Common result types from your code
```

## API Endpoints





## Services

*Service modules will be listed here with their public APIs*

### Example Service
```haxe
@:module
class ExampleService {
    public static function process(data: Dynamic): Result<ProcessedData>
}
```

## Database Schemas



## Configuration

### Environment Variables
```bash
# Required environment variables
DATABASE_URL=postgresql://user:pass@localhost/db
SECRET_KEY_BASE=your-secret-key
```

### Compile-time Flags
```hxml
# Available compile flags
-D source-map        # Enable source mapping
-D debug            # Debug mode
-D no-debug         # Production mode
-D generate-llm-docs # Generate AI documentation
-D extract-patterns  # Extract code patterns
```

## Quick Command Reference

### Development
```bash
# Start watcher
mix compile.haxe --watch

# Compile once
npx haxe build.hxml



# Run tests
mix test
```

### Documentation Generation
```bash
# Generate full API documentation
npx haxe build.hxml -D generate-llm-docs

# Extract patterns from code
npx haxe build.hxml -D extract-patterns

# Update this reference manually
mix haxe.gen.docs --api
```

## Notes

### Auto-Generation
To populate this reference with your actual API:

1. **Write your code** - Create modules, services, and schemas
2. **Compile with docs flag** - `npx haxe build.hxml -D generate-llm-docs`
3. **Review generated docs** - Check `.taskmaster/docs/` for updates

### Manual Updates
You can also manually update this file as you develop. The auto-generation will preserve manual additions in marked sections.

---

*This is a living document that grows with your project.*
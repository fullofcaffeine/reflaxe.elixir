# Mix Project Integration Example

This directory demonstrates how to integrate Haxe→Elixir compilation into a Mix project with proper directory structure, dependencies, and build workflows.

**Prerequisites**: [01-simple-modules](../01-simple-modules/) completed  
**Difficulty**: 🟢 Beginner  
**Time**: 30 minutes

## Learning Objectives

- Understand Mix project structure for Haxe→Elixir integration
- Learn how to configure `mix.exs` for Haxe compilation
- Master the build workflow combining Haxe and Elixir code
- See testing patterns for mixed Haxe/Elixir projects
- Configure professional development workflows

## Project Structure

```
02-mix-project/
├── lib/                     # Compiled Elixir output
├── src_haxe/               # Haxe source files
│   ├── services/           # Business logic modules
│   └── utils/              # Helper utilities
├── test/                   # ExUnit tests
├── config/                 # Application configuration
├── mix.exs                 # Project definition
├── build.hxml              # Haxe compilation config
└── README.md               # This file
```

## Key Features Demonstrated

### 1. Mix Integration
- Custom `:haxe` compiler in `mix.exs`
- Automated Haxe compilation during `mix compile`
- Proper dependency management between Haxe and Elixir code

### 2. Build Workflow
- `build.hxml` configuration for project compilation
- Source mapping from `src_haxe/` to `lib/`
- Development vs production build configurations

### 3. Testing Integration
- ExUnit tests for Haxe-compiled modules
- Mixed testing strategies (unit and integration)
- Test helpers for common patterns

### 4. Configuration Management
- Environment-specific settings in `config/`
- Runtime configuration for Haxe modules
- Development vs production optimization

## Running the Example

### Setup
```bash
cd examples/02-mix-project
mix deps.get
```

### Compilation
```bash
# Compile all (Haxe + Elixir)
mix compile

# Force Haxe recompilation
mix compile.haxe --force

# Verbose compilation output
mix compile.haxe --verbose
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/user_service_test.exs

# Run tests with coverage
mix test --cover
```

### Development
```bash
# Start interactive shell with compiled modules
iex -S mix

# Format code
mix format

# Run linter (if configured)
mix credo
```

## Example Modules

### UserService (Haxe → Elixir)
**Source**: `src_haxe/services/UserService.hx`  
**Compiled to**: `lib/services/user_service.ex`  
**Features**: CRUD operations, validation, error handling

### StringUtils (Haxe → Elixir)  
**Source**: `src_haxe/utils/StringUtils.hx`  
**Compiled to**: `lib/utils/string_utils.ex`  
**Features**: String processing, formatting utilities

### MathHelper (Haxe → Elixir)
**Source**: `src_haxe/utils/MathHelper.hx`  
**Compiled to**: `lib/utils/math_helper.ex`  
**Features**: Mathematical computations, validation

## Configuration Examples

### mix.exs Integration
```elixir
def project do
  [
    app: :mix_project_example,
    version: "0.1.0",
    elixir: "~> 1.14",
    compilers: [:haxe] ++ Mix.compilers(),
    deps: deps(),
    haxe_compiler: [
      hxml_file: "build.hxml",
      source_dir: "src_haxe",
      target_dir: "lib",
      verbose: false
    ]
  ]
end
```

### build.hxml Configuration
```hxml
# Source paths
-cp src_haxe
-cp ../../../src
-cp ../../../std

# Compilation target and flags  
-D reflaxe_runtime
--no-output

# Main classes to compile
-main services.UserService
--next
-main utils.StringUtils
--next  
-main utils.MathHelper
```

## Best Practices Demonstrated

### Project Organization
- Clear separation between Haxe source and Elixir output
- Logical module grouping (services, utils, etc.)
- Consistent naming conventions

### Build Management
- Incremental compilation support
- Manifest tracking for efficiency
- Error handling and reporting

### Testing Strategy
- Unit tests for individual modules
- Integration tests for cross-module functionality
- Test helpers for common patterns

### Development Workflow
- Hot code reloading during development
- Proper error messages and debugging
- Performance monitoring and profiling

## Troubleshooting

### Common Issues

**Compilation Errors**
```bash
# Clean and rebuild
mix clean
mix compile

# Check Haxe source syntax
haxe build.hxml
```

**Missing Dependencies**
```bash
# Update dependencies
mix deps.get
mix deps.compile
```

**Test Failures**
```bash
# Run tests with detailed output
mix test --trace
mix test --verbose
```

## Next Steps

After mastering Mix integration, continue to:
- [03-phoenix-controllers](../03-phoenix-controllers/) - Web request handling
- [04-phoenix-liveview](../04-phoenix-liveview/) - Real-time interactivity
- [05-ecto-integration](../05-ecto-integration/) - Database operations

## Performance Notes

- **Compilation Time**: ~50-200ms for typical projects
- **Memory Usage**: Minimal overhead during compilation
- **Runtime Performance**: Identical to hand-written Elixir
- **Development Speed**: Hot reloading supported via `--force` flag
# Mix Integration Guide

## Overview

Reflaxe.Elixir provides seamless integration with Mix, Elixir's build tool, enabling automatic compilation of Haxe files as part of your regular Mix workflow. This guide covers setup, usage, and troubleshooting.

## Quick Start

### 1. Add Haxe Compiler to Mix

In your `mix.exs`:

```elixir
def project do
  [
    app: :my_app,
    version: "0.1.0",
    elixir: "~> 1.14",
    compilers: [:haxe] ++ Mix.compilers(),  # Add :haxe before default compilers
    haxe: [
      source_dir: "src",        # Where your .hx files live
      target_dir: "lib",        # Where .ex files are generated
      hxml_file: "build.hxml"   # Your Haxe build configuration
    ],
    deps: deps()
  ]
end
```

### 2. Create Your Build Configuration

Create `build.hxml` in your project root:

```hxml
-cp src
-lib reflaxe.elixir
-D elixir_output=lib
--macro reflaxe.elixir.ElixirCompiler.initialize()
--main Main
```

### 3. Start Coding

Place your Haxe files in `src/` and run:

```bash
mix compile    # Compiles both Haxe and Elixir files
mix haxe.watch # Watch mode for development
```

## Architecture

### How It Works

```
Your .hx files (src/)
        ↓
Mix.Tasks.Compile.Haxe (compile.haxe.ex)
        ↓
HaxeCompiler module (haxe_compiler.ex)
        ↓
Reflaxe.Elixir transpiler
        ↓
Generated .ex files (lib/)
        ↓
Standard Mix compilation
        ↓
BEAM bytecode (.beam files)
```

### Components

1. **Mix.Tasks.Compile.Haxe** (`lib/mix/tasks/compile.haxe.ex`)
   - Integrates Haxe compilation into Mix's build pipeline
   - Handles incremental compilation and dependency tracking
   - Starts file watcher in development mode
   - Formats and displays compilation errors

2. **HaxeCompiler** (`lib/haxe_compiler.ex`)
   - Core compilation logic
   - Error parsing and formatting
   - Source/target file management
   - Compilation caching

3. **HaxeWatcher** (`lib/haxe_watcher.ex`)
   - File system monitoring for .hx changes
   - Automatic recompilation on file changes
   - Debouncing to prevent excessive compilations
   - Integration with Phoenix's code reloader

4. **Mix.Tasks.Haxe.Watch** (`lib/mix/tasks/haxe.watch.ex`)
   - Manual watch mode for explicit control
   - Useful for debugging compilation issues
   - Standalone development workflow

## Configuration Options

### Complete Configuration

```elixir
# mix.exs
def project do
  [
    compilers: [:haxe] ++ Mix.compilers(),
    haxe: [
      # Required
      source_dir: "src",           # Haxe source directory
      target_dir: "lib",           # Elixir output directory
      hxml_file: "build.hxml",     # Haxe build configuration
      
      # Optional
      watch: true,                 # Enable file watching (default: true in dev)
      watch_dirs: ["src", "test"], # Directories to watch
      verbose: false,              # Verbose compilation output
      force: false,                # Force recompilation
      debounce_ms: 100,           # Debounce period for file changes
      
      # Advanced
      incremental: true,           # Use incremental compilation
      source_maps: true,          # Generate source maps
      server_mode: true           # Use Haxe compilation server
    ]
  ]
end
```

## Usage Patterns

### Development Workflow

```bash
# Initial setup
mix deps.get
mix compile

# Development
mix haxe.watch                # Start file watcher
mix haxe.watch --verbose      # Watch with detailed output
mix haxe.watch --once         # Compile once and exit

# Phoenix development
iex -S mix phx.server        # Auto-recompiles Haxe files
```

### Production Build

```bash
# Clean build
mix clean
mix compile --force

# Release
MIX_ENV=prod mix compile
MIX_ENV=prod mix release
```

### Testing

```bash
# Compile test files
MIX_ENV=test mix compile

# Run tests
mix test

# Watch mode for TDD
mix haxe.watch --dirs src,test
```

## Phoenix Integration

### Setup for Phoenix

1. Add to `mix.exs`:

```elixir
def project do
  [
    compilers: [:haxe, :phoenix] ++ Mix.compilers(),
    # ... rest of config
  ]
end
```

2. Configure endpoints to watch Haxe files:

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"lib/.*(ex)$",
      ~r"src/.*(hx)$",  # Watch Haxe source files
      # ... other patterns
    ]
  ]
```

3. Create LiveView components in Haxe:

```haxe
// src/ProductLive.hx
@:liveview
class ProductLive {
    public static function mount(params, session, socket) {
        return {ok: socket.assign(products: [])}
    }
    
    public static function handle_event(event, params, socket) {
        // Handle events
    }
}
```

## Error Handling

### Understanding Compilation Errors

The Mix integration provides enhanced error messages:

```
== Compilation error in Haxe files ==
src/Main.hx:10:5 Type not found: UnknownType
    │ var x:UnknownType = null;
         ^^^^^^^^^^^^^
         
Hint: Run 'mix haxe.errors' for detailed error analysis
      Run 'mix haxe.errors --json' for LLM-friendly format
```

### Error Analysis Tools

```bash
# View last compilation errors
mix haxe.errors

# Get errors in JSON format (for AI assistants)
mix haxe.errors --json

# Check specific error with stacktrace
mix haxe.stacktrace ERROR_ID

# Inspect compilation state
mix haxe.inspect
```

## Troubleshooting

### Common Issues and Solutions

#### 1. "Build file not found: build.hxml"

**Solution**: Create `build.hxml` in your project root:

```hxml
-cp src
-lib reflaxe.elixir
-D elixir_output=lib
--macro reflaxe.elixir.ElixirCompiler.initialize()
```

#### 2. Files not recompiling on change

**Solution**: Check watcher configuration:

```elixir
# mix.exs
haxe: [
  watch: true,
  watch_dirs: ["src"],  # Ensure your source dir is listed
  debounce_ms: 100      # Adjust if needed
]
```

#### 3. Phoenix not reloading Haxe changes

**Solution**: Add Haxe patterns to live_reload:

```elixir
# config/dev.exs
live_reload: [
  patterns: [
    ~r"src/.*(hx)$",
    ~r"lib/.*(ex)$"
  ]
]
```

#### 4. Compilation order issues

**Solution**: Ensure `:haxe` comes before other compilers:

```elixir
compilers: [:haxe] ++ Mix.compilers()  # Haxe MUST be first
```

#### 5. Incremental compilation not working

**Solution**: Clear the compilation cache:

```bash
mix clean
rm -rf _build
mix compile
```

#### 6. Haxe command not found

**Solution**: Install Haxe via lix:

```bash
npm install
npx lix install
```

## Advanced Usage

### Custom Compilation Pipeline

Create your own Mix compiler by extending the base task:

```elixir
# lib/mix/tasks/compile.my_haxe.ex
defmodule Mix.Tasks.Compile.MyHaxe do
  use Mix.Task.Compiler
  
  @impl Mix.Task.Compiler
  def run(args) do
    # Custom pre-processing
    preprocess_files()
    
    # Delegate to standard Haxe compiler
    Mix.Tasks.Compile.Haxe.run(args)
    
    # Custom post-processing
    postprocess_files()
  end
end
```

### Conditional Compilation

Use environment-specific build files:

```elixir
# mix.exs
def project do
  [
    haxe: [
      hxml_file: hxml_file(Mix.env())
    ]
  ]
end

defp hxml_file(:prod), do: "build.prod.hxml"
defp hxml_file(:test), do: "build.test.hxml"
defp hxml_file(_), do: "build.hxml"
```

### Multi-target Compilation

Compile to multiple targets:

```elixir
# mix.exs
def project do
  [
    haxe: [
      targets: [
        [source_dir: "src/web", target_dir: "lib/web"],
        [source_dir: "src/api", target_dir: "lib/api"]
      ]
    ]
  ]
end
```

## Performance Optimization

### Compilation Speed

1. **Use Haxe Server**: Enables incremental compilation

```elixir
haxe: [
  server_mode: true  # Enable compilation server
]
```

2. **Optimize File Watching**: Reduce unnecessary recompilations

```elixir
haxe: [
  debounce_ms: 200,  # Increase debounce time
  watch_dirs: ["src"] # Only watch necessary directories
]
```

3. **Parallel Compilation**: For large projects

```bash
# Set Haxe to use multiple threads
export HAXE_THREADS=4
mix compile
```

## Migration Guide

### From Manual Compilation

If you were previously compiling Haxe manually:

1. Remove manual compilation scripts
2. Add `:haxe` to compilers in `mix.exs`
3. Move build configuration to `haxe:` config
4. Delete generated files and recompile with `mix compile`

### From Older Versions

For projects using older Reflaxe.Elixir versions:

1. Update dependency: `lix install reflaxe.elixir`
2. Add new Mix tasks to `lib/mix/tasks/`
3. Update `mix.exs` configuration
4. Run `mix clean && mix compile`

## Best Practices

1. **Keep source and target directories separate** - Don't mix .hx and generated .ex files
2. **Use consistent naming** - Match Haxe class names to Elixir module names
3. **Configure .gitignore** - Exclude generated files from version control
4. **Use watch mode in development** - Faster feedback loop
5. **Run clean builds regularly** - Prevent stale compilation artifacts
6. **Document build configuration** - Help team members understand the setup

## API Reference

### Mix Tasks

- `mix compile` - Compiles Haxe files as part of regular compilation
- `mix haxe.watch` - Starts file watcher for development
- `mix haxe.errors` - Shows last compilation errors
- `mix haxe.stacktrace` - Displays error stacktraces
- `mix haxe.inspect` - Inspects compilation state
- `mix clean` - Cleans generated files

### Configuration Keys

- `:source_dir` - Haxe source directory (default: "src")
- `:target_dir` - Elixir output directory (default: "lib")
- `:hxml_file` - Build configuration file (default: "build.hxml")
- `:watch` - Enable file watching (default: true in dev)
- `:verbose` - Verbose output (default: false)
- `:force` - Force recompilation (default: false)

## Summary

The Mix integration makes Haxe→Elixir compilation seamless:

- **Automatic compilation** with `mix compile`
- **File watching** for development productivity
- **Error formatting** for better debugging
- **Phoenix integration** for LiveView development
- **Incremental compilation** for performance

This integration eliminates the friction of using Haxe with Elixir, making it feel like a natural part of the ecosystem.
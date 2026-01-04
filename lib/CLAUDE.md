# Elixir Infrastructure Files - DO NOT DELETE

> **⚠️ SYNC DIRECTIVE**: `AGENTS.md` and `CLAUDE.md` in the same directory must be kept in sync. When updating either file, update the other as well.

## ⚠️ CRITICAL: These Are NOT Generated Files

**IMPORTANT**: The files in this `lib/` directory are **hand-written Elixir infrastructure code**, NOT generated output from the Haxe compiler. They provide essential tooling and Mix tasks for the Reflaxe.Elixir development workflow.

**DO NOT DELETE THESE FILES** - They are part of the core project infrastructure.

## 📁 Directory Structure

```
lib/
├── haxe_compiler.ex          # Core compilation orchestration
├── haxe_server.ex           # Compilation server for performance
├── haxe_watcher.ex          # File watching for auto-compilation
├── phoenix_error_handler.ex # Error handling integration
├── source_map_lookup.ex     # Source mapping utilities
└── mix/tasks/               # Mix task implementations
    ├── compile.haxe.ex      # Main compilation task
    ├── haxe.errors.ex       # Error reporting utilities
    ├── haxe.gen.context.ex  # Generate Phoenix contexts
    ├── haxe.gen.live.ex     # Generate LiveView modules
    ├── haxe.gen.migration.ex # Generate Ecto migrations
    ├── haxe.gen.project.ex  # Project scaffolding
    ├── haxe.gen.schema.ex   # Generate Ecto schemas
    ├── haxe.inspect.ex      # AST inspection tools
    ├── haxe.source_map.ex   # Source map querying
    ├── haxe.stacktrace.ex   # Stack trace mapping
    └── haxe.watch.ex        # Watch mode task
```

## 🔧 File Purposes

### Core Infrastructure Files

#### `haxe_compiler.ex`
- **Purpose**: Orchestrates the Haxe→Elixir compilation process
- **Key Functions**: Invokes Haxe compiler, manages compilation cache, handles errors
- **Used By**: Mix tasks, development workflow

#### `haxe_server.ex`
- **Purpose**: Maintains a persistent Haxe compilation server
- **Key Functions**: Speeds up incremental compilation, manages server lifecycle
- **Performance**: Reduces compilation time from seconds to milliseconds

#### `haxe_watcher.ex`
- **Purpose**: Watches Haxe source files for changes
- **Key Functions**: Auto-recompilation on save, real-time error feedback
- **Integration**: Works with Phoenix's live reload

#### `phoenix_error_handler.ex`
- **Purpose**: Integrates Haxe compilation errors with Phoenix error pages
- **Key Functions**: Formats compiler errors for web display, source mapping
- **Developer Experience**: Shows errors directly in the browser

#### `source_map_lookup.ex`
- **Purpose**: Maps between Haxe source and generated Elixir
- **Key Functions**: Line number translation, debugging support
- **Critical For**: Error messages pointing to correct Haxe source locations

### Mix Tasks (`mix/tasks/`)

#### Core Compilation
- **`compile.haxe.ex`**: Main Mix compilation task (`mix compile.haxe`)
  - Integrates with Mix compilation pipeline
  - Handles dependency tracking
  - Manages incremental compilation

#### Code Generation Tasks
- **`haxe.gen.context.ex`**: Generate Phoenix context modules from Haxe
- **`haxe.gen.live.ex`**: Generate LiveView modules with proper annotations
- **`haxe.gen.migration.ex`**: Create Ecto migrations from Haxe definitions
- **`haxe.gen.schema.ex`**: Generate Ecto schemas with changesets
- **`haxe.gen.project.ex`**: Scaffold new Haxe→Elixir projects

#### Development Tools
- **`haxe.errors.ex`**: Display compilation errors (`mix haxe.errors`)
- **`haxe.inspect.ex`**: Inspect Haxe AST for debugging
- **`haxe.source_map.ex`**: Query source mappings (`mix haxe.source_map`)
- **`haxe.stacktrace.ex`**: Map Elixir stack traces back to Haxe
- **`haxe.watch.ex`**: Run compilation in watch mode

## 🚀 Usage Examples

### Basic Compilation
```bash
# Compile Haxe to Elixir
mix compile.haxe

# Watch mode for development
mix haxe.watch

# Check compilation errors
mix haxe.errors
```

### Code Generation
```bash
# Generate a new LiveView module
mix haxe.gen.live TodoLive

# Create a new schema with migration
mix haxe.gen.schema Todo todos title:string completed:boolean

# Generate a complete context
mix haxe.gen.context Todos Todo todos title:string
```

### Debugging
```bash
# Map Elixir line to Haxe source
mix haxe.source_map lib/generated/my_module.ex 42

# Inspect AST
mix haxe.inspect MyModule

# Map stack trace
mix haxe.stacktrace trace.txt
```

## ⚠️ Important Notes

### These Files Are Essential
- **NOT generated** by the Haxe compiler
- **NOT temporary** or disposable
- **REQUIRED** for the development workflow
- **MAINTAINED** as part of the project

### Version Control
- These files **MUST** be committed to git
- Changes require careful testing
- Updates affect all developers using the project

### Relationship to Generated Code
- These files **enable** code generation
- Generated Elixir goes in application directories (e.g., `examples/todo-app/lib/`)
- This infrastructure remains at the project root

## 🔍 How to Identify Generated vs Infrastructure

### Infrastructure Files (DO NOT DELETE)
- Located in root `lib/` directory
- Provide Mix tasks and tooling
- Written in Elixir to support Haxe compilation
- Have `.ex` extension with Mix task patterns

### Generated Files (Can be regenerated)
- Located in application directories (e.g., `examples/todo-app/lib/`)
- Created by running `haxe build.hxml`
- Have corresponding `.hx` source files
- Can be deleted and regenerated from Haxe source

## 📚 Related Documentation

- [/docs/01-getting-started/development-workflow.md](/docs/01-getting-started/development-workflow.md) - How these tools fit into development
- [/docs/03-compiler-development/](/docs/03-compiler-development/) - Compiler architecture
- [/docs/04-api-reference/mix-tasks.md](/docs/04-api-reference/mix-tasks.md) - Mix task documentation

---

**Remember**: If you're unsure whether a file should be deleted, check if it's in the root `lib/` directory. If it is, it's infrastructure and should NOT be deleted.

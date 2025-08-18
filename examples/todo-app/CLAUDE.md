# AI Development Instructions for todo-app

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions, architecture, and core development principles

This file contains todo-app specific instructions for AI assistants working on this Phoenix LiveView example.

## ⚠️ CRITICAL: Never Edit Generated Files

**The `lib/*.ex` files are GENERATED OUTPUT from the Haxe→Elixir compiler.**

### DO NOT:
- ❌ Edit any `.ex` files in the `lib/` directory directly
- ❌ Try to fix compilation errors by modifying generated files
- ❌ Make "quick fixes" to generated Elixir code
- ❌ Write Elixir migration files manually in `priv/repo/migrations/`

### INSTEAD:
- ✅ Fix issues in the compiler source at `/src/reflaxe/elixir/`
- ✅ Edit Haxe source files in `src_haxe/`
- ✅ Write migrations in Haxe using @:migration annotation
- ✅ Regenerate with `npx haxe build.hxml` after fixing the compiler

### Why This Matters:
Generated files are overwritten every time you compile. Any manual edits will be lost. All fixes must be made at the source - either in the Haxe code (`src_haxe/`) or in the compiler itself (`/src/reflaxe/elixir/`).

## 📝 IMPORTANT: Migrations Must Be Written in Haxe

**ALL database migrations should be written in Haxe and compiled to Elixir.**

### The Correct Approach:
1. **Write migrations in Haxe** using the `@:migration` annotation
2. **Place them in `src_haxe/migrations/`**
3. **Compile to generate Elixir migrations** in `priv/repo/migrations/`
4. **Never manually write `.exs` migration files**

### Example Migration in Haxe:
```haxe
package migrations;

@:migration("todos")
class CreateTodos {
    public function up(): Void {
        createTable("todos")
            .addColumn("title", "string", {null: false})
            .addColumn("description", "text")
            .addColumn("completed", "boolean", {default: false})
            .timestamps();
    }
    
    public function down(): Void {
        dropTable("todos");
    }
}
```

### Using the Mix Task:
```bash
# Generate a new migration from Haxe
mix haxe.gen.migration CreateTodos --table todos --columns "title:string,description:text"

# This creates:
# - src_haxe/migrations/CreateTodos.hx (Haxe source)
# - priv/repo/migrations/[timestamp]_create_todos.exs (compiled Elixir)
```

### Why This Matters:
The entire point of Reflaxe.Elixir is to write everything in Haxe. Writing manual Elixir migrations defeats the purpose and breaks the single-language paradigm. The compiler has full @:migration support - use it!

## 📋 Project Overview

- **Project**: todo-app
- **Type**: Phoenix LiveView Application
- **Framework**: Reflaxe.Elixir (Haxe → Elixir compilation)
- **Architecture**: Compile-time transpiler with file watching

## 🚀 Quick Start for AI Development

### 1. Start File Watcher
```bash
# Start the watcher for real-time compilation
mix compile.haxe --watch

# You'll see:
[10:30:45] Starting HaxeWatcher...
[10:30:45] Watching directories: ["src_haxe"]
[10:30:45] Ready for changes. Press Ctrl+C to stop.
```

### 2. Development Workflow
1. Edit .hx files in `src_haxe/`
2. Save file → Automatic compilation in ~100-200ms
3. Generated .ex files appear in `lib/generated/`
4. Test changes immediately - no manual compilation needed!

## ⚡ File Watching Benefits

- **Sub-second compilation**: 0.1-0.3s per file change (10-50x faster than cold compilation)
- **Immediate error feedback**: See compilation errors instantly
- **Source mapping**: Errors show Haxe source positions, not generated Elixir
- **Continuous validation**: Code always compiles before you move on




## ⚠️ CRITICAL: Compiler Development Rule

**The todo-app is a DEVELOPMENT GUIDE for the compiler, NOT a hardcoded dependency.**

### Fundamental Principle
- ✅ **todo-app drives compiler features** - When todo-app needs something, we enhance the compiler
- ✅ **Compiler remains generic** - Zero knowledge of "TodoApp", "TodoAppWeb", or todo-app specifics
- ❌ **NEVER hardcode app-specific strings** - No "TodoApp", "TodoAppWeb", "todo_app" in compiler source
- ❌ **NEVER make compiler todo-app dependent** - Must work for ANY Phoenix application

### The Right Approach
```haxe
// ❌ WRONG - Hardcoded in compiler
var moduleHeader = LiveViewCompiler.generateModuleHeader(moduleName, "TodoAppWeb.CoreComponents");

// ✅ RIGHT - Dynamic resolution
var appName = AnnotationSystem.getEffectiveAppName(classType);
var coreComponentsModule = appName + "Web.CoreComponents";
var moduleHeader = LiveViewCompiler.generateModuleHeader(moduleName, coreComponentsModule);
```

### Development Workflow
1. **todo-app needs feature X** → Implement generic feature X in compiler
2. **todo-app breaks with change** → Fix compiler's generic implementation, not todo-app-specific patches
3. **New Phoenix app fails** → Compiler bug, not user error - fix the compiler

### Validation Rule
**Every compiler change MUST be tested with a different app name to ensure it's generic.**

Example test:
```haxe
@:appName("MyCustomApp")  // Not TodoApp!
class TestRouter { ... }
```

If this fails, the compiler has hardcoded dependencies that must be removed.

## 🔴 LiveView Development

### LiveView Component Pattern
```haxe
// Framework-agnostic with explicit Phoenix convention
@:native("TodoAppWeb.TodoLive")  // Generates TodoAppWeb.TodoLive module
@:liveview
class TodoLive {
    public static function mount(params, session, socket) {
        return socket.assign({
            // Initial state here
        });
    }
    
    public static function handle_event(event, params, socket) {
        return switch(event) {
            case "your_event": 
                // Handle event
                socket;
            case _: socket;
        };
    }
}
```

### Module Naming Convention
**CRITICAL**: The compiler generates plain Elixir by default. Use @:native to apply Phoenix conventions:

```haxe
@:native("TodoAppWeb.TodoLive")    // Phoenix web module
@:native("TodoApp.User")           // Phoenix app module  
@:native("MyDeviceWeb.SensorLive") // Works with any framework
```

This framework-agnostic approach works with Phoenix, Nerves, pure OTP, or custom frameworks.

### Testing LiveView Changes
1. Edit LiveView component → Save
2. Watch compilation (~200ms)
3. Browser auto-refreshes with changes
4. Test interactions immediately




## 🗺️ Source Mapping & Debugging

### Enable Source Mapping
Add to your `build.hxml`:
```hxml
-D source-map  # Enable source mapping for debugging
```

### Use Source Maps for Debugging
```bash
# Map Elixir error back to Haxe source
mix haxe.source_map lib/MyModule.ex 45 12
# Output: src_haxe/MyModule.hx:23:15

# Check compilation errors with source positions
mix haxe.errors --format json

# Get structured compilation status
mix haxe.status --format json
```

## 📁 Project Structure

```
todo-app/
├── src_haxe/              # 🎯 Edit Haxe files here
│   ├── Main.hx            # Entry point
│   └── 
├── lib/                   
│   └── generated/         # ⚡ Auto-generated Elixir code
├── build.hxml             # Haxe build configuration  
├── mix.exs                # Elixir project configuration
└── CLAUDE.md              # This file
```

## ✅ Best Practices

### 1. Always Use File Watcher
- **Start watcher first**: `mix compile.haxe --watch`
- **Keep it running**: One terminal dedicated to watching
- **Check feedback**: Watch for compilation success/errors

### 2. Source Mapping for Error Fixes
- **Use precise positions**: Source maps show exact Haxe line/column
- **Query error locations**: `mix haxe.source_map <file> <line> <col>`
- **Fix at source**: Edit Haxe files, not generated Elixir

### 3. Rapid Development Loop
1. Edit .hx file and save
2. Watch compilation result (~200ms)
3. Test changes immediately
4. Fix errors using source positions
5. Repeat for fast iteration

## 🔧 Troubleshooting

### Watcher Not Starting
```bash
# Check if port 6000 is in use
lsof -i :6000

# Use different port if needed
mix compile.haxe --watch --port 6001

# Reset watcher state
rm -rf .haxe_cache && mix compile.haxe --watch --force
```

### Changes Not Detected
```bash
# Verify files are in watched directories
mix haxe.status

# Check if src_haxe/ contains .hx files
ls src_haxe/**/*.hx
```

### Compilation Errors
```bash
# Get detailed error information
mix haxe.errors --format json

# Check source mapping
mix haxe.source_map <generated_file> <line> <column>
```

## 📚 LLM-Optimized Documentation

This project includes comprehensive documentation specifically designed for AI assistants:

### Foundation Documentation (in .taskmaster/docs/llm/)
- **HAXE_FUNDAMENTALS.md** - Essential Haxe language knowledge
- **REFLAXE_ELIXIR_BASICS.md** - Core Reflaxe.Elixir concepts and patterns
- **QUICK_START_PATTERNS.md** - Copy-paste ready code patterns
- **PROJECT_SPECIFICS.md** - Template-specific guidance for this project
- **API_REFERENCE_SKELETON.md** - API documentation (grows as you code)

### Pattern Extraction (in .taskmaster/docs/patterns/)
- **PATTERNS.md** - Auto-extracted patterns from your code

### Generating Enhanced Documentation
```bash
# Generate full API documentation
npx haxe build.hxml -D generate-llm-docs

# Extract patterns from your code
npx haxe build.hxml -D extract-patterns
```

## 🏗️ Architecture Philosophy: Haxe First, Type Safety Everywhere

### Core Principle: Everything in Haxe by Default
**Write EVERYTHING in Haxe unless technically impossible.** Type safety isn't just for business logic - it's for the entire application.

### What IS Written in Haxe (Almost Everything)
✅ **In Haxe** - The entire application stack:
- **Router** (`TodoAppRouter.hx`) - Generates `router.ex` with @:router annotation ✓
- **LiveView modules** (`TodoLive.hx`) - Interactive UI components ✓
- **Schemas** (`Todo.hx`) - Database models with @:schema ✓
- **Migrations** (`CreateTodos.hx`) - Database changes with @:migration ✓
- **Contexts** (`Todos.hx`) - Business logic modules ✓
- **Telemetry** (`Telemetry.hx`) - Metrics and monitoring ✓
- **Repo** (`Repo.hx`) - Ecto repository configuration ✓
- **Endpoint** (`Endpoint.hx`) - Phoenix endpoint configuration ✓
- **Application** (`TodoApp.hx`) - OTP application with @:application ✓
- **Layouts** - Should be HXX templates, not manual HEEx
- **Error pages** - Type-safe error handling in Haxe
- **Core components** - HXX components with full type safety
- **Gettext i18n** - Type-safe internationalization wrapper
- **Channel modules** - Real-time features with @:channel
- **All templates** - HXX for everything, zero manual templates

### What Remains as Elixir (Absolute Minimum)
📦 **Only if technically required**:
- **mix.exs** - Build tool configuration (could potentially be generated)
- **config/*.exs** - Environment configs (could be templated from Haxe)
- **Assets pipeline** - package.json, esbuild (JavaScript tooling)

### The Haxe-First Development Flow
1. **Start with Haxe** - Always implement in Haxe first
2. **Use HXX for all UI** - Templates, layouts, components
3. **Generate, don't write** - If Elixir is needed, generate it
4. **Type safety everywhere** - Even error pages and infrastructure
5. **Extern only as last resort** - Prefer Haxe implementations

### ⚠️ EMERGENCY ONLY: Elixir Integration

**Integrating with existing Elixir code via externs is an ESCAPE HATCH, not a feature.**

Just like `__elixir__()`, extern definitions for existing Elixir modules should only be used in:
1. **Emergency situations** - When a critical feature is blocking and no Haxe solution exists yet
2. **Gradual migration** - When migrating a large existing Elixir codebase (temporary)
3. **Third-party libraries** - When absolutely must use an Elixir library with no Haxe equivalent

**The goal is 100% Haxe code, not "Haxe with Elixir integration".**

Example of emergency extern (should be replaced with Haxe implementation):
```haxe
// EMERGENCY: Using extern for existing Elixir module
// TODO: Replace with proper Haxe implementation by [date]
// Justification: Migration from legacy codebase
// Ticket: #1234
@:native("LegacyModule")
extern class LegacyModule {
    static function oldFunction(arg: String): Int;
}
```

### The Vision
**100% Type-Safe Application** - Complete type safety throughout, using the right tool for each need:
- **Pure Haxe preferred**: Write implementations in Haxe for maximum control
- **Typed externs welcome**: Type-safe integration with Elixir ecosystem
- **No Dynamic code**: Everything must be properly typed
- **No escape hatches**: `__elixir__()` only in documented emergencies

## 🧪 Testing After Compiler Changes

**The todo-app is the PRIMARY INTEGRATION TEST for the compiler.**

### When You Change the Compiler
After ANY modification to `/src/reflaxe/elixir/`:

1. **Clean Generated Files**:
   ```bash
   rm -rf lib/*.ex lib/**/*.ex
   ```

2. **Regenerate Everything**:
   ```bash
   npx haxe build-server.hxml
   ```

3. **Test Compilation**:
   ```bash
   mix compile --force
   ```

4. **Check for Errors**:
   - No duplicate module definitions
   - All Phoenix imports present
   - Valid HEEx template syntax
   - Proper function signatures

### Common Testing Patterns

#### After HXX Changes
```bash
# Regenerate templates
rm -rf lib/server_layouts_*.ex lib/todo_app_web/live/*.ex
npx haxe build-server.hxml
mix compile
```

#### After Router Changes
```bash
# Regenerate router
rm lib/todo_app_web/router.ex
npx haxe build-server.hxml
mix phx.routes
```

#### After Schema Changes
```bash
# Regenerate schemas
rm -rf lib/todo_app/schemas/*.ex
npx haxe build-server.hxml
mix ecto.compile
```

### Testing Checklist
- [ ] All files regenerate without errors
- [ ] `mix compile` succeeds without warnings
- [ ] `mix phx.server` starts without crashes
- [ ] Router paths are accessible
- [ ] LiveView pages render
- [ ] Database operations work

### If Tests Fail
1. **DON'T patch generated .ex files** - they'll be overwritten
2. **DO fix the compiler source** at `/src/reflaxe/elixir/`
3. **DO regenerate and retest** after fixes
4. **DO update snapshot tests** if output improved

**Remember**: If todo-app doesn't work, the compiler is broken!

## 📚 Additional Resources

- [Watcher Development Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/guides/WATCHER_DEVELOPMENT_GUIDE.md)
- [Source Mapping Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/SOURCE_MAPPING.md)
- [Getting Started Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/guides/GETTING_STARTED.md)
- [Compiler Testing Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/COMPILER_TESTING_GUIDE.md)

---

**Remember**: The watcher provides sub-second compilation perfect for AI-assisted development. Always start with `mix compile.haxe --watch` for the best experience!
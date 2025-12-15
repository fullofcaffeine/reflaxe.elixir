# Getting Started with Reflaxe.Elixir

This guide will help you set up and start using Reflaxe.Elixir to compile Haxe code to Elixir/Phoenix applications.

## Prerequisites

Before you begin, ensure you have:

- **Node.js** (16+ recommended) for lix package manager
- **Elixir** (1.14+ recommended) for running generated code
- **Phoenix** (1.7+ recommended) if using Phoenix features
- **PostgreSQL** (optional, for database examples)

## Quick Start: Create a New Project

The fastest way to get started is using the built-in project generator:

### Using lix (recommended)
```bash
# Install Reflaxe.Elixir via lix
npx lix install github:fullofcaffeine/reflaxe.elixir

# Create a new project
npx lix run reflaxe.elixir create my-app

# Or create a Phoenix project
npx lix run reflaxe.elixir create my-phoenix-app --type phoenix
```

### Using haxelib (alternative)
```bash
# Install Reflaxe.Elixir globally
haxelib git reflaxe.elixir https://github.com/fullofcaffeine/reflaxe.elixir

# Create a new project
haxelib run reflaxe.elixir create my-app

# Or create a Phoenix project
haxelib run reflaxe.elixir create my-phoenix-app --type phoenix
```

### Using Mix task (for existing Elixir projects)
```bash
# If you already have an Elixir project
cd existing-elixir-project
mix haxe.gen.project

# Or with options
mix haxe.gen.project --basic-modules --phoenix
```

### Project Types

- **basic** - Standard Mix project with utilities (default)
- **phoenix** - Full Phoenix web application
- **liveview** - Phoenix with LiveView components
- **add-to-existing** - Add Haxe to existing Elixir project

All project types include **AGENTS.md** with AI development instructions for using the watcher and source mapping.

### Generator Options Reference

The project generator supports these command-line options:

```bash
# Interactive mode (recommended for beginners)
npx lix run reflaxe.elixir create my-app

# Specify project type
npx lix run reflaxe.elixir create my-app --type basic|phoenix|liveview|add-to-existing

# Skip interactive prompts
npx lix run reflaxe.elixir create my-app --no-interactive

# Skip dependency installation
npx lix run reflaxe.elixir create my-app --skip-install

# Verbose output for debugging
npx lix run reflaxe.elixir create my-app --verbose
```

**For complete generator documentation**, see [PROJECT_GENERATOR_GUIDE.md](PROJECT_GENERATOR_GUIDE.md).

## Manual Installation

If you prefer to set up manually or contribute to the compiler:

### 1. Clone the Repository

```bash
git clone https://github.com/fullofcaffeine/reflaxe.elixir
cd reflaxe.elixir
```

### 2. Install Dependencies

**Install Haxe dependencies with lix**:
```bash
npm install        # Installs lix locally
npx lix download   # Downloads Haxe libraries
```

**Install Elixir dependencies**:
```bash
mix deps.get       # Installs Elixir dependencies
```

### 3. Verify Installation

Run the comprehensive test suite:
```bash
npm test
```

You should see output like:
```
🧪 === COMPREHENSIVE REFLAXE.ELIXIR TEST SUITE ===
📋 Testing Haxe→Elixir Compiler...
🎉 ALL HAXE COMPILER TESTS PASSING!
📋 Testing Generated Elixir Code & Mix Tasks...
🎉 ALL TESTS PASSING!
```

## Your First Example

Let's start with the simplest example to understand the basic workflow.

### 1. Create a Simple Module

Create a file `MyModule.hx`:
```haxe
package myapp;

class MyModule {
    public static function greet(name: String): String {
        return "Hello, " + name + "!";
    }
    
    public static function main(): Void {
        trace("MyModule compiled successfully!");
    }
}
```

### 2. Create Build Configuration

Create `build.hxml`:
```hxml
-cp .
-cp node_modules/reflaxe.elixir/src
-lib reflaxe
-D reflaxe_runtime
-D source-map    # Enable source mapping for better debugging
--no-output

myapp.MyModule
```

### 3. Compile

```bash
npx haxe build.hxml
```

Success! Your Haxe code has been compiled to Elixir patterns with source mapping.

### 4. Verify Source Maps (Optional)

Check that source maps were generated:
```bash
# Look for .ex.map files alongside .ex files
ls lib/*.ex.map
```

With source mapping enabled, any compilation errors or runtime issues will show precise Haxe source positions instead of generated Elixir lines.

## Working with Annotations

Reflaxe.Elixir's power comes from annotations that generate specific Elixir patterns.

### Ecto Schema Example

```haxe
@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "string", nullable: false}) 
    public var email: String;
    
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
}
```

This generates a complete Ecto.Schema module with proper field definitions and validations.

### Phoenix LiveView Example

```haxe
@:native("MyAppWeb.UserLive")  // Phoenix module convention
@:liveview
class UserLive {
    var users: Array<User> = [];
    
    function mount(params: Dynamic, session: Dynamic, socket: Dynamic) {
        return {
            status: "ok",
            socket: assign(socket, "users", Users.list_users())
        };
    }
    
    function handle_event(event: String, params: Dynamic, socket: Dynamic) {
        return switch(event) {
            case "refresh":
                {status: "noreply", socket: assign(socket, "users", Users.list_users())};
            default:
                {status: "noreply", socket: socket};
        }
    }
    
    function render(assigns: Dynamic): String {
        return hxx('<div>User management interface</div>');
    }
}
```

This generates a complete Phoenix LiveView module with real-time capabilities. The @:native annotation ensures proper Phoenix module naming (generates `MyAppWeb.UserLive`).

### Real-Time Development Example

Let's see the watcher in action with a LiveView counter to understand the rapid development workflow:

1. **Start the watcher** (in your project directory):
```bash
mix haxe.watch
```

2. **Create CounterLive.hx** in src_haxe/live/:
```haxe
@:native("MyAppWeb.CounterLive")  // Phoenix module convention
@:liveview
class CounterLive {
    function mount(_params, _session, socket) {
        return assign(socket, {count: 0});
    }
    
    function handle_event("increment", _params, socket) {
        var count = socket.assigns.count + 1;
        return assign(socket, {count: count});
    }
    
    function render(assigns) {
        return hxx('
            <div>
                <h1>Count: <%= @count %></h1>
                <button phx-click="increment">+</button>
            </div>
        ');
    }
}
```

3. **Save the file** - Watch the instant compilation:
```
[10:45:23] File changed: src_haxe/live/CounterLive.hx
[10:45:23] Compiling...
[10:45:23] ✅ Compiled 1 file in 0.215s
```

4. **Make a live change** - Add a decrement button:
```haxe
function handle_event("decrement", _params, socket) {
    var count = socket.assigns.count - 1;
    return assign(socket, {count: count});
}

// Update render to include the new button:
function render(assigns) {
    return hxx('
        <div>
            <h1>Count: <%= @count %></h1>
            <button phx-click="increment">+</button>
            <button phx-click="decrement">-</button>
        </div>
    ');
}
```

5. **Save again** - The watcher recompiles in ~200ms!
   - If using Phoenix, the browser refreshes automatically
   - Your new button appears without manual compilation

This rapid feedback loop makes development as fast as working with interpreted languages while maintaining type safety!

## Exploring Examples

The project includes comprehensive examples demonstrating different features:

### 1. Simple Modules (01-simple-modules)
```bash
cd examples/01-simple-modules
npx haxe compile-all.hxml
```

**What you'll learn**:
- Basic compilation patterns
- Module structure generation
- Function compilation

### 2. Mix Project Integration (02-mix-project)
```bash
cd examples/02-mix-project
npx haxe build.hxml
mix test
```

**What you'll learn**:
- Mix project integration
- Multiple utility modules
- Testing generated code

### 3. Ecto Migrations (04-ecto-migrations)
```bash
cd examples/04-ecto-migrations
npx haxe build.hxml
```

**What you'll learn**:
- Database migration generation
- Table operations with DSL
- Migration rollback support

### 4. User Management (06-user-management)
```bash
cd examples/06-user-management
npx haxe build.hxml
```

**What you'll learn**:
- Multi-annotation integration
- Schema + Changeset + LiveView + GenServer
- Real-world application patterns

## Source Mapping & Debugging

Reflaxe.Elixir is the **first Reflaxe target to implement source mapping**, providing seamless debugging across compilation boundaries.

### Enabling Source Mapping

Add the `-D source-map` flag to your build configuration:

```hxml
# In your build.hxml or compile.hxml
-D source-map
```

### Benefits

With source mapping enabled:
- **Precise error locations**: Errors show Haxe source positions, not generated Elixir lines
- **Better debugging**: Debug at the Haxe level while running Elixir code
- **LLM-friendly**: AI agents can use source positions for accurate fixes
- **Minimal overhead**: <5% compilation time increase

### Using Source Maps for Debugging

When you encounter an error:

```bash
# Map an Elixir error position back to Haxe source
mix haxe.source_map lib/UserService.ex 45 12

# Output: src_haxe/UserService.hx:23:15
```

### File Watching with Source Maps

Enable both file watching and source mapping for the best development experience:

```bash
# Start compilation with watching and source mapping
mix haxe.watch

# Now edit your .hx files - compilation and source maps update automatically
```

For detailed source mapping documentation, see [SOURCE_MAPPING.md](../04-api-reference/SOURCE_MAPPING.md).

## Development with File Watching

Reflaxe.Elixir includes powerful file watching for rapid development iteration with sub-second recompilation. This feature dramatically improves the development experience by automatically recompiling your Haxe code whenever you save changes.

> 📚 **For comprehensive watcher documentation**, see the archived [Watcher Development Guide](../09-history/archive/docs/06-guides/WATCHER_DEVELOPMENT_GUIDE.md)

### Quick Start with Watcher

```bash
# Start the watcher - it monitors all .hx files in src_haxe/
mix haxe.watch

# You'll see:
[10:30:45] Starting HaxeWatcher...
[10:30:45] Watching directories: ["src_haxe"]
[10:30:45] Ready for changes. Press Ctrl+C to stop.

# Now edit any .hx file and save - compilation happens automatically!
[10:31:02] File changed: src_haxe/models/User.hx
[10:31:02] Compiling...
[10:31:02] ✅ Compiled 1 file in 0.127s
```

### Watcher with Phoenix LiveReload

For Phoenix applications, the watcher integrates seamlessly with LiveReload:

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  watchers: [
    # Haxe watcher runs alongside Phoenix
    haxe: ["mix", "haxe.watch", cd: Path.expand("../", __DIR__)]
  ],
  live_reload: [
    patterns: [
      ~r"lib/generated/.*(ex)$"  # Watch generated Elixir files
    ]
  ]
```

Now your workflow is:
1. Save .hx file → Watcher compiles to .ex
2. Phoenix detects .ex change → Recompiles Elixir  
3. LiveReload refreshes browser → See changes instantly!

### Performance Benefits

The watcher provides dramatic speed improvements:

| Compilation Type | Time | Speed Improvement |
|-----------------|------|-------------------|
| Cold compile (full project) | 2-5 seconds | Baseline |
| Incremental (single file) | 0.1-0.3 seconds | 10-50x faster |
| Multiple files (debounced) | 0.3-1 seconds | 5-15x faster |

**Key features**:
- **Debouncing**: Multiple rapid changes compile together (100ms default)
- **Incremental compilation**: Only recompiles changed files
- **HaxeServer**: Maintains compilation server on port 6116 for speed
- **Source map updates**: Debugging information stays in sync

## Development Workflow

### 1. Project Structure

Organize your Haxe code following these conventions:
```
src_haxe/
├── contexts/          # @:schema and @:changeset classes
│   ├── Users.hx
│   └── Posts.hx
├── live/             # @:liveview classes
│   ├── UserLive.hx
│   └── PostLive.hx
├── services/         # @:genserver classes
│   └── CacheService.hx
├── migrations/       # @:migration classes
│   ├── CreateUsers.hx
│   └── CreatePosts.hx
└── templates/        # @:template classes
    └── Components.hx
```

### 2. Build Configuration

Create a `build.hxml` that includes all necessary classpaths:
```hxml
# Source paths
-cp src_haxe
-cp path/to/reflaxe.elixir/src  
-cp path/to/reflaxe.elixir/std

# Libraries
-lib reflaxe

# Compilation flags
-D reflaxe_runtime
-D source-map        # Enable source mapping (recommended)
--no-output

# Modules to compile
contexts.Users
live.UserLive
services.CacheService
```

For development, also consider these optional flags:
```hxml
-D source-map-verbose  # Verbose source map generation
-D incremental        # Support incremental compilation
-D watch-mode         # Optimize for file watching
```

### 3. Compilation and Testing

**Compile Haxe to Elixir** (one-time):
```bash
npx haxe build.hxml
```

**Compile with file watching** (recommended for development):
```bash
# Auto-recompile on file changes
mix haxe.watch

# Or with verbose output
mix haxe.watch --verbose
```

### 4. Continuous Development Workflow

The most efficient way to develop is using the watcher for automatic recompilation:

**For Phoenix projects** (all-in-one):
```bash
iex -S mix phx.server
# This starts: Phoenix server + HaxeWatcher + LiveReload
# Everything recompiles and reloads automatically!
```

**For non-Phoenix projects** (use two terminals):
```bash
# Terminal 1: Start the watcher
mix haxe.watch

# Terminal 2: Run your application  
iex -S mix
```

**The rapid development loop**:
1. Edit your .hx file in your editor
2. Save the file (Cmd+S / Ctrl+S)
3. See compilation result in terminal (~200ms)
4. Test changes immediately - no manual recompilation!
5. If using Phoenix, browser refreshes automatically

**Pro tip**: With the watcher running, you can stay focused on coding. The compiler provides instant feedback on type errors, and successful compilations happen silently in the background.

### 5. Testing Workflow

**Test generated code**:
```bash
mix test
```

**Debug with source mapping**:
```bash
# Query source positions
mix haxe.source_map lib/MyModule.ex 10 5

# Check compilation errors with source positions
mix haxe.errors --format json
```

**Run comprehensive validation**:
```bash
npm test
```

## Common Patterns

### 1. Utility Functions

Make utility functions `public static`:
```haxe
class StringUtils {
    public static function slugify(text: String): String {
        // Implementation
        return text.toLowerCase();
    }
    
    public static function main(): Void {
        trace("StringUtils compiled successfully!");
    }
}
```

### 2. Error Handling

Use Elixir-style error tuples:
```haxe
public static function createUser(attrs: Dynamic): {status: String, ?user: User, ?error: String} {
    if (isValid(attrs)) {
        return {status: "ok", user: newUser};
    } else {
        return {status: "error", error: "Invalid data"};
    }
}
```

### 3. Pattern Matching

Use Haxe switch for Elixir pattern matching:
```haxe
function handle_event(event: String, params: Dynamic, socket: Dynamic) {
    return switch(event) {
        case "create": handleCreate(params, socket);
        case "update": handleUpdate(params, socket);
        case "delete": handleDelete(params, socket);
        default: {status: "noreply", socket: socket};
    }
}
```

## Troubleshooting

### Generator Issues

#### "Command not found: lix"
**Problem**: lix package manager not installed
**Solution**: Install lix globally:
```bash
npm install -g lix
```

#### "Module reflaxe.elixir not found"
**Problem**: Reflaxe.Elixir not properly installed
**Solution**: Reinstall with explicit GitHub reference:
```bash
# Using lix
npx lix install github:fullofcaffeine/reflaxe.elixir --force

# Using haxelib
haxelib remove reflaxe.elixir
haxelib git reflaxe.elixir https://github.com/fullofcaffeine/reflaxe.elixir
```

#### Generator fails with "Permission denied"
**Problem**: Insufficient permissions to create project directory
**Solution**: Either use sudo or create project in a directory you own:
```bash
# Create in home directory
cd ~
npx lix run reflaxe.elixir create my-app
```

#### Phoenix projects won't start
**Problem**: Missing database or dependencies
**Solution**: Complete the setup process:
```bash
cd my-phoenix-app
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

### Compilation Issues

#### "Type not found" Error
**Problem**: Package structure doesn't match directory structure
**Solution**: Ensure directory structure matches package declarations

#### Function Visibility Issues  
**Problem**: Functions not accessible from other modules
**Solution**: Use `public static` for utility functions

#### Annotation Conflicts
**Problem**: Incompatible annotations on same class
**Solution**: Check annotation compatibility in [ANNOTATIONS.md](../04-api-reference/ANNOTATIONS.md)

#### Build Configuration Issues
**Problem**: Classpath errors or missing dependencies
**Solution**: Verify all `-cp` paths and library installations

### Watcher Not Detecting Changes
**Problem**: File saves don't trigger recompilation
**Solutions**:
- Check if `src_haxe/` directory exists and contains .hx files
- On macOS: FSEvents should work automatically
- On Linux: May need to increase inotify watchers:
  ```bash
  echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p
  ```
- On Windows: Use polling mode in configuration

### Compilation Loops
**Problem**: Watcher keeps recompiling endlessly
**Solution**: Ensure output directory (`lib/`) is not in the watch path. The watcher should only monitor `src_haxe/`

### Watcher Port Already in Use
**Problem**: "Could not start HaxeServer on port 6116"
**Solution**:
```bash
# Check what's using the port
lsof -i :6116
# Kill the process or use a different port
HAXE_SERVER_PORT=6117 mix haxe.watch
```

## Next Steps

1. **Explore Examples**: Work through each example in order
2. **Read Documentation**: Check [FEATURES.md](../04-api-reference/FEATURES.md) for current capabilities
3. **Learn Annotations**: Master annotation usage with [ANNOTATIONS.md](../04-api-reference/ANNOTATIONS.md)
4. **Build Your Application**: Start with simple modules and gradually add complexity
5. **Join Community**: Contribute feedback and improvements

## Performance Tips

### Compilation Performance
- **Initial Compilation**: Full project compiles in 2-5 seconds
- **Incremental with Watcher**: Single file changes recompile in 0.1-0.3s (10-50x faster!)
- **Use the watcher**: `mix haxe.watch` provides sub-second feedback
- **Build Optimization**: Use unified compilation instead of `--next` approach

### Watcher Optimization
- **Directory Focus**: Only watch `src_haxe/`, exclude test and output directories
- **Debounce Tuning**: Default 100ms works well, increase to 200-500ms for slower systems
- **Port Configuration**: HaxeServer runs on port 6116 by default, change if conflicts
- **Memory Usage**: Watcher uses ~120MB initially, may grow to ~250MB for large projects

### Development Speed Tips
- **Keep Watcher Running**: Start once per session with `mix haxe.watch`
- **Phoenix Integration**: Use `iex -S mix phx.server` for all-in-one development
- **Leverage Caching**: lix and HaxeServer cache parsed files for speed
- **Testing**: Use `npm test` for comprehensive validation

For detailed feature status and technical implementation notes, see [FEATURES.md](../04-api-reference/FEATURES.md) and the project's AGENTS.md file.

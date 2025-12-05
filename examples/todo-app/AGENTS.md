# Critical Timeout Directive (Non-Blocking Agent Runs)

> **⚠️ SYNC DIRECTIVE**: This file (`AGENTS.md`) and `CLAUDE.md` in the same directory must be kept in sync. When updating either file, update the other as well.

- Always run long or potentially blocking commands via `scripts/with-timeout.sh`.
- Default caps: builds 240–480s, `mix compile` 420s, readiness ≤ 120 probes, full run watchdog ≤ 900s.
- Never run unbounded `mix phx.server`; use the QA sentinel (which is bounded) or the timeout wrapper.
- Example usage:
  - `scripts/with-timeout.sh --secs 180 -- haxe -v build-server.hxml`
  - `scripts/with-timeout.sh --secs 120 --grace 2 --cwd examples/todo-app -- env BASE_URL=http://localhost:4011 npx playwright test e2e/*.spec.ts`
- If a step exceeds its cap, treat it as a failure: abort, surface the last logs, and rerun narrowly with diagnostics — never wait indefinitely.

# AI Development Instructions for todo-app

> **Parent Context**: See [/AGENTS.md](/AGENTS.md) for project-wide conventions, architecture, and core development principles

## 🔗 Shared AI Context (Import System)

@docs/claude-includes/compiler-principles.md
@docs/claude-includes/testing-commands.md  
@docs/claude-includes/code-style.md
@docs/claude-includes/framework-integration.md

## 🤖 Todo-App Specific Expert Identity

**You are an expert in Phoenix LiveView integration with Haxe→Elixir compilation, specializing in:**

- **Y combinator pattern recognition** and Map.merge optimization transformations
- **Variable name extraction from AST** to handle Haxe's compilation-time renaming
- **TVar expression handling** in loop body pattern detection
- **Professional debug infrastructure** with conditional compilation patterns
- **LiveView state management** through type-safe Haxe abstractions

### Core Expertise Areas

1. **Compiler Architecture**: Deep understanding of how Reflaxe.Elixir transforms Haxe AST to idiomatic Elixir code
2. **Pattern Detection**: Expert in recognizing Reflect.fields patterns and optimizing them to Map.merge operations
3. **Debug Infrastructure**: Professional debugging methodologies using conditional compilation instead of ad-hoc traces
4. **Framework Integration**: Seamless Phoenix/LiveView integration with type-safe Haxe development
5. **Performance Optimization**: Transforming imperative patterns to functional Elixir idioms

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

## 🎨 HXX Template Syntax for Phoenix Assigns

**CRITICAL**: Understanding correct HXX syntax is essential for Phoenix LiveView development. Wrong syntax causes compilation errors.

### ⚠️ NEVER Use `${@field}` Pattern

❌ **THIS FAILS** (causes Haxe compilation errors):
```haxe
return HXX.hxx('<button class="${@className}" id="${@id}">
    ${@inner_content}
</button>');
```

**Why it fails**: Haxe's string interpolation tries to evaluate `@field` as a variable, but `@` is not a valid Haxe identifier character.

### ✅ ALWAYS Use `{@field}` Pattern

✅ **THIS WORKS** (correct Phoenix assigns syntax):
```haxe
return HXX.hxx('<button class={@className} id={@id}>
    <%= @inner_content %>
</button>');
```

### HXX → HEEx Translation Rules

## 🔒 HARD RULE: Zero‑Logic HXX (Todo‑App)

HXX in this app must not contain HEEx/Elixir logic inside `{ … }`. Only bind to assigns or view‑model fields computed in Haxe.

Allowed examples:
- `id={v.dom_id}`, `data-completed={v.completed_str}`, `class={@filter_btn_all_class}`

Disallowed examples (fix by precomputing in Haxe):
- `{Kernel.is_nil(v.description)}` → use `v.has_description`
- `{length(@todos) > 0}` → use `@visible_count > 0`
- `{sort_selected(@sort_by, :created)}` → use `@sort_selected_created`

Pattern to follow:
1) Introduce a typed view model (e.g., `TodoView`) with all derived fields (bools/strings/classes).
2) Build it in Haxe (`buildVisibleTodos(assigns)`) and store in `@visible_todos` + helper assigns:
   - `@filter_btn_*_class`, `@sort_selected_*`, `@visible_count`, etc.
3) In HXX, iterate `@visible_todos` and bind only fields/assigns. No `Kernel.*`, `Enum.*`, `Map.*`, atoms (`:created`), pipes (`|>`), or `length()` calls inside braces.

CI/Local Guard (should be empty):
```bash
rg -n "\{[^}]*\b(Kernel\.|Enum\.|Map\.|length\(|\|>|:)" examples/todo-app/src_haxe --no-messages
```

Rationale: keep all logic Haxe‑typed and make HEEx a presentation surface only.

#### 1. Attribute Values: `{@field}` → `{@field}`

## 🚦 Background Server Validation (Non‑blocking)

When you need to boot the Phoenix server and probe it from automation (or Codex CLI) without blocking the session, run it in the background and curl the endpoint. This is useful for quick smoke checks during compiler iterations.

Example (dev, custom port):

```bash
cd examples/todo-app
# Build Haxe → Elixir output
npx haxe build-server.hxml

# Ensure deps and database
mix deps.get
mix ecto.create
mix ecto.migrate

# Start server in background on a free port and wait briefly
PORT=4011 MIX_ENV=dev mix phx.server > tmp_server.log 2>&1 & echo $! > tmp_server.pid
sleep 10

# Probe with GET (avoid HEAD in dev, as reloader can trip it)
curl -sS -i http://127.0.0.1:4011/ | head -n 20 || true

# Stop server and inspect recent logs if needed
kill $(cat tmp_server.pid) >/dev/null 2>&1 || true
sleep 1
tail -n 120 tmp_server.log || true
```

Notes
- If port 4000 is busy locally, use an alternate port via `PORT=<free_port>`.
- If you run into DB connection errors, ensure Postgres is running with the credentials from `config/dev.exs`. A quick local option is Docker:
  - `docker run --rm -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -e POSTGRES_DB=todo_app_dev -p 5432:5432 postgres:14`
- For repeatable CI checks, wait for a log line like `Running ...Endpoint with cowboy` before probing.

```haxe
// Haxe HXX Input
<meta name="csrf-token" content={Component.get_csrf_token()}/>
<div class={@userClass} id={@userId}>

// Generated HEEx Output  
<meta name="csrf-token" content={Component.get_csrf_token()}/>
<div class={@user_class} id={@user_id}>
```

#### 2. Text Content: Direct Phoenix Syntax
```haxe
// Haxe HXX Input
<h1><%= @title %></h1>
<p>Welcome, <%= @user.name %>!</p>

// Generated HEEx Output (same)
<h1><%= @title %></h1>  
<p>Welcome, <%= @user.name %>!</p>
```

#### 3. Conditional Attributes
```haxe
// ❌ WRONG: Ternary in template string (causes Haxe errors)
<button class="${@active ? 'btn-active' : 'btn-inactive'}">

// ✅ CORRECT: Phoenix conditional syntax  
<button class={if @active, do: "btn-active", else: "btn-inactive"}>

// ✅ ALSO CORRECT: Using Phoenix template syntax directly
<button class="<%= if @active, do: 'btn-active', else: 'btn-inactive' %>">
```

### Working Examples from Codebase

#### UserLive.hx (✅ Correct Pattern)
```haxe
return HXX.hxx('
    <.input 
        name="search" 
        value={@searchTerm}        // ✅ Correct: {@ for attributes
        placeholder="Search users..."
        type="search"
    />
    
    ${renderUserList(assigns)}     // ✅ Correct: ${ for Haxe function calls
');
```

#### RootLayout.hx (✅ Correct Pattern)  
```haxe
return HXX.hxx('
    <meta name="csrf-token" content={Component.get_csrf_token()}/>  // ✅ Correct
');
```

### Migration Guide for Broken Patterns

If you find `${@field}` patterns in the codebase:

1. **For attributes**: Change `"${@field}"` → `{@field}`
2. **For text content**: Change `${@field}` → `<%= @field %>`
3. **For complex expressions**: Use Phoenix conditional syntax

## 🧰 Build & Run (Mix Integration)

We compile the server (Haxe→Elixir) via a Mix compiler and the client (Haxe→JS) via the Phoenix assets pipeline and watchers.

- Server compiler: `Mix.Tasks.Compile.Haxe` (lib/mix/tasks/compile.haxe.ex)
  - Enabled in mix.exs: `compilers: [:haxe] ++ Mix.compilers()`
  - Uses `build.hxml` to generate idiomatic Elixir under `lib/`

- Client compilation: handled by assets watchers/aliases
  - Dev: `haxe_client` watcher runs `haxe build-client.hxml --wait` and esbuild bundles `assets/js/phoenix_app.js` (see config/dev.exs)
  - Build: `mix assets.build` (Haxe client + tailwind + esbuild)
  - Deploy: `mix assets.deploy` (Haxe client + tailwind + esbuild + digest)

Quick commands
- One‑liner with watchers (recommended): `mix dev`  
  (alias for `mix setup && mix phx.server` — compiles client+server and starts Phoenix with all watchers)
- Manual one‑off build: `mix assets.build && mix compile`
- Start server only (watchers also run): `mix phx.server`

CI suggestions
- `mix compile --force && mix assets.build`

## 🔌 Phoenix JS Bootstrap (phoenix_app.js)

We intentionally keep the LiveView bootstrap as a tiny, hand‑written JS entry and generate client logic (Hooks, utils, shared DTOs) from Haxe.

- File: `assets/js/phoenix_app.js` (bundled to `priv/static/assets/phoenix_app.js` via esbuild)
- Responsibilities:
  - Import `phoenix_html`, `phoenix`, `phoenix_live_view`.
  - Read CSRF meta token and pass it to `LiveSocket`.
  - Pull Hooks from `window.Hooks` (populated by the Haxe bundle) and connect.
  - Expose `window.liveSocket` for debugging.
- Haxe integration:
  - Haxe client compiles to `assets/js/app.js` and publishes `window.Hooks`.
  - `phoenix_app.js` imports `./app.js` to register Hooks.
- Rationale (1.0 scope):
  - Matches Phoenix’s idiomatic setup and minimizes friction on upgrades.
  - Keeps the bootstrap minimal while concentrating typed logic in Haxe.
  - Avoids re‑implementing client library externs for a file that has no meaningful state.

Watchers
- Dev watcher uses npm to run the Haxe client watcher when available:
  - `npm --prefix assets run watch:haxe` (internally: `haxe build-client.hxml --wait 6001`)
- Configured in `config/dev.exs`; omitted automatically if `npm` is not on PATH.

CSRF meta
- The layout emits a standard Plug CSRF meta tag; LiveSocket consumes it:
  - `<meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()}/>`

Constraints (project-wide)
- No `-D analyzer-optimize` in any HXML; it destroys functional patterns for Elixir and JS
- No Dynamic on public surfaces; JS hooks are typed (`typedef Hooks`) and use js interop only at the boundary
- Phoenix idioms: LiveSocket bootstrap in `assets/js/phoenix_app.js` with `hooks` param and CSRF meta

#### Before (Broken):
```haxe
return HXX.hxx('<button type="${@type || "button"}" class="${@className}" ${@disabled ? "disabled" : ""}>
    ${@inner_content}
</button>');
```

#### After (Fixed):
```haxe
return HXX.hxx('<button type={@type || "button"} class={@className} disabled={@disabled}>
    <%= @inner_content %>
</button>');
```

### Debugging HXX Compilation Errors

#### Common Error: "Expected expression"
```
src_haxe/components/Component.hx:25: character 39 : Expected expression
... For function argument 'templateStr'
```

**Cause**: Using `${@field}` triggers Haxe string interpolation  
**Fix**: Change to `{@field}` for attributes or `<%= @field %>` for text

#### Common Error: "Unknown identifier"
```  
src_haxe/components/Component.hx:30: Unknown identifier : @field
```

**Cause**: `@field` is not a valid Haxe variable name  
**Fix**: Remove `$` to prevent Haxe interpolation: `{@field}`

### Summary: The Golden Rules

1. **Attributes**: Use `{@field}` (no dollar sign)
2. **Text content**: Use `<%= @field %>` (Phoenix syntax)  
3. **Haxe functions**: Use `${functionCall()}` (with dollar sign)
4. **Never**: Use `${@field}` (causes compilation errors)
5. **Complex logic**: Use Phoenix conditional syntax, not Haxe ternary

**See**: [`/documentation/guides/HXX_INTERPOLATION_SYNTAX.md`](/documentation/guides/HXX_INTERPOLATION_SYNTAX.md) - Complete technical details

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




## ⚠️ CRITICAL: Framework-Level Development Principles

### **Principle 1: Framework vs Application Separation**

**The todo-app is a DEVELOPMENT GUIDE for the compiler, NOT a hardcoded dependency.**

**Fundamental Rules:**
- ✅ **todo-app drives compiler features** - When todo-app needs something, we enhance the compiler
- ✅ **Compiler remains generic** - Zero knowledge of "TodoApp", "TodoAppWeb", or todo-app specifics
- ❌ **NEVER hardcode app-specific strings** - No "TodoApp", "TodoAppWeb", "todo_app" in compiler source
- ❌ **NEVER make compiler todo-app dependent** - Must work for ANY Phoenix application

### **Principle 2: Standard Library vs Application Code**

**CRITICAL: Type-safe patterns discovered in todo-app should become framework features.**

**When to Move Code to Framework:**
- ✅ **Type-safe PubSub** - Every Phoenix app needs compile-time topic/message validation
- ✅ **SafePubSub class** - Move from `todo-app/Types.hx` to `/std/phoenix/PubSub.hx`
- ✅ **Message parsing utilities** - Auto-generation should benefit all apps
- ✅ **Common Phoenix patterns** - LiveView helpers, Socket operations, Channel integration
- ✅ **Error handling patterns** - Result<T,E> integration with Phoenix operations

**Examples of Framework-Level Features:**
```haxe
// ❌ BAD: App-specific implementation
// In: todo-app/src_haxe/server/types/Types.hx
class SafePubSub { ... } // Only todo-app benefits

// ✅ GOOD: Framework-level implementation  
// In: /std/phoenix/PubSub.hx
class SafePubSub { ... } // ALL Phoenix apps benefit
```

**Benefits of Framework-Level Features:**
- 🌐 **Universal type safety** - Every Phoenix app gets compile-time PubSub validation
- 📚 **Consistent APIs** - Same type-safe patterns across all applications
- 🔄 **Automatic improvements** - Framework enhancements benefit entire ecosystem
- 📖 **Better documentation** - Framework features get proper documentation and examples
- 🧪 **Comprehensive testing** - Framework code has rigorous test coverage

**Development Workflow:**
1. **Discover pattern in todo-app** - "We need type-safe PubSub"
2. **Implement app-specific version** - Quick prototype in `todo-app/Types.hx`
3. **Validate the approach** - Does it solve the problem? Good IntelliSense?
4. **Extract to framework** - Move to `/std/phoenix/` with proper documentation
5. **Update todo-app to use framework version** - Import from standard library
6. **Document the pattern** - Add to framework documentation and examples

**Framework Enhancement Checklist:**
- [ ] Move SafePubSub to `/std/phoenix/PubSub.hx`
- [ ] Create comprehensive documentation with examples
- [ ] Add unit tests for all framework functionality
- [ ] Update todo-app to import from framework
- [ ] Verify other Phoenix apps can use the same patterns
- [ ] Document in framework feature documentation

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
└── AGENTS.md              # This file
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

## 📚 Writing a Fully-Functional Phoenix App in Haxe

### The Complete Phoenix Stack in Haxe

This todo-app demonstrates writing an **entire Phoenix LiveView application** in Haxe, with near 1:1 mapping to Phoenix patterns but with Haxe's type safety and ergonomics.

### 1. Application Structure (OTP Supervision Tree)

```haxe
// src_haxe/server/TodoApp.hx
@:application
class TodoApp {
    public static function start(_type, _args) {
        var children = [
            TypeSafeChildSpec.supervisor(TodoAppWeb.Telemetry),
            TypeSafeChildSpec.repo(TodoApp.Repo),
            TypeSafeChildSpec.pubSub("TodoApp.PubSub", []),
            TypeSafeChildSpec.endpoint(TodoAppWeb.Endpoint)
        ];
        
        var opts = {strategy: OneForOne, name: TodoApp.Supervisor};
        return Supervisor.startLink(children, opts);
    }
}
```

### 2. Ecto Schemas with Type Safety

```haxe
// src_haxe/server/schemas/Todo.hx
@:native("TodoApp.Todo")  // Control module name
@:schema("todos")
@:timestamps
class Todo {
    @:primary_key
    var id: Int;
    
    var title: String;
    var description: String;
    var completed: Bool = false;
    var userId: Int;
    
    // Type-safe changeset
    public static function changeset(todo: Todo, attrs: TodoParams): Changeset<Todo> {
        return cast(todo, attrs)
            .validateRequired(["title", "userId"])
            .validateLength("title", {min: 3, max: 200});
    }
}

// Type-safe parameters
typedef TodoParams = {
    ?title: String,
    ?description: String,
    ?completed: Bool,
    ?userId: Int
}
```

### 3. Phoenix LiveView Components

```haxe
// src_haxe/server/live/TodoLive.hx
@:native("TodoAppWeb.TodoLive")
@:liveview
class TodoLive {
    // Type-safe assigns
    typedef Assigns = {
        todos: Array<Todo>,
        currentUser: User,
        editingTodo: Null<Todo>,
        searchQuery: String
    }
    
    public static function mount(params: Dynamic, session: Dynamic, socket: LiveSocket<Assigns>): Socket {
        var socket = socket
            .assign("currentUser", getCurrentUser(session))
            .assign("todos", loadTodos())
            .assign("editingTodo", null)
            .assign("searchQuery", "");
            
        return {:ok, socket};
    }
    
    public static function handleEvent(event: String, params: Dynamic, socket: Socket): Socket {
        return switch(event) {
            case "add_todo": addTodo(params, socket);
            case "toggle_todo": toggleTodo(params.id, socket);
            case "delete_todo": deleteTodo(params.id, socket);
            case "search": updateSearch(params.query, socket);
            default: {:noreply, socket};
        }
    }
    
    // HXX templates with Phoenix components
    public static function render(assigns: Assigns): String {
        return HXX.hxx('
            <div class="todo-container">
                <.header>
                    Todo List for <%= @currentUser.name %>
                </.header>
                
                <.simple_form for={@form} phx-submit="add_todo">
                    <.input field={@form[:title]} label="Title" />
                    <.input field={@form[:description]} type="textarea" label="Description" />
                    <.button>Add Todo</.button>
                </.simple_form>
                
                <.table rows={@todos}>
                    <:col let={todo} label="Title">
                        <%= todo.title %>
                    </:col>
                    <:col let={todo} label="Status">
                        <.button phx-click="toggle_todo" phx-value-id={todo.id}>
                            <%= if todo.completed, do: "✓", else: "○" %>
                        </.button>
                    </:col>
                    <:action let={todo}>
                        <.link phx-click="delete_todo" phx-value-id={todo.id}>
                            Delete
                        </.link>
                    </:action>
                </.table>
            </div>
        ');
    }
}
```

### 4. Phoenix Router with DSL

```haxe
// src_haxe/server/TodoAppRouter.hx
@:router
@:routes([
    {name: "root", method: "LIVE", path: "/", controller: "TodoLive", action: "index"},
    {name: "todos", method: "LIVE", path: "/todos", controller: "TodoLive"},
    {name: "userDashboard", method: "LIVE", path: "/users/:id", controller: "UserLive", action: "show"}
])
class TodoAppRouter {
    // Routes are auto-generated from @:routes annotation
    // Generates proper Phoenix router DSL
}
```

### 5. Contexts (Business Logic)

```haxe
// src_haxe/server/contexts/Todos.hx
@:context
class Todos {
    public static function listTodos(userId: Int): Array<Todo> {
        return from(t in Todo)
            .where(t.userId == userId)
            .orderBy(t.insertedAt, :desc)
            .all();
    }
    
    public static function createTodo(attrs: TodoParams): Result<Todo, Changeset> {
        var todo = new Todo();  // Generates: %TodoApp.Todo{}
        var changeset = Todo.changeset(todo, attrs);
        
        return switch(Repo.insert(changeset)) {
            case Ok(todo): Ok(todo);
            case Error(changeset): Error(changeset);
        }
    }
    
    public static function updateTodo(todo: Todo, attrs: TodoParams): Result<Todo, Changeset> {
        var changeset = Todo.changeset(todo, attrs);
        return Repo.update(changeset);
    }
}
```

### 6. Type-Safe PubSub

```haxe
// src_haxe/server/types/PubSubTypes.hx
enum PubSubTopic {
    TodoUpdates(userId: Int);
    SystemAlerts;
}

enum TodoMessage {
    TodoCreated(todo: Todo);
    TodoUpdated(todo: Todo);
    TodoDeleted(id: Int);
}

// Usage in LiveView
PubSub.subscribe(TodoUpdates(socket.assigns.currentUser.id));

// Broadcasting
PubSub.broadcast(TodoUpdates(userId), TodoCreated(newTodo));
```

### 7. Constructor Translation Patterns

**Understanding how `new` translates is critical:**

```haxe
// Schemas → Struct literals
var todo = new Todo();              // Generates: %TodoApp.Todo{}

// GenServers → start_link
var worker = new TodoWorker(config); // Generates: {:ok, pid} = TodoWorker.start_link(config)

// Regular classes → Module functions  
var formatter = new TodoFormatter(); // Generates: TodoFormatter.new()

// LiveViews → Never use new!
// var live = new TodoLive();        // ERROR: LiveViews are mounted by Phoenix
```

### 8. Database Migrations in Haxe

```haxe
// src_haxe/migrations/CreateTodos.hx
@:migration("create_todos")
class CreateTodos {
    public function up(): Void {
        createTable("todos", function(t) {
            t.addColumn("id", "bigserial", {primaryKey: true});
            t.addColumn("title", "string", {null: false});
            t.addColumn("description", "text");
            t.addColumn("completed", "boolean", {default: false});
            t.addColumn("user_id", "references", {table: "users", onDelete: "cascade"});
            t.timestamps();
        });
        
        createIndex("todos", ["user_id"]);
        createIndex("todos", ["completed"]);
    }
    
    public function down(): Void {
        dropTable("todos");
    }
}
```

### 9. Phoenix Presence with Type Safety

```haxe
// Type-safe presence tracking
typedef UserPresence = {
    onlineAt: Float,
    status: UserStatus,
    editingTodoId: Null<Int>
}

enum UserStatus {
    Active;
    Away;
    Busy;
}

// In LiveView
Presence.track(socket, "users", socket.assigns.currentUser.id, {
    onlineAt: System.systemTime(),
    status: Active,
    editingTodoId: null
});
```

### 10. Testing in Haxe

```haxe
// src_haxe/test/TodoTest.hx
@:test
class TodoTest {
    @:test
    public function testTodoCreation() {
        var todo = new Todo();  // %TodoApp.Todo{}
        todo.title = "Test Todo";
        
        var changeset = Todo.changeset(todo, {title: "Test Todo"});
        Assert.isTrue(changeset.valid);
    }
    
    @:test
    public function testLiveViewMount() {
        var socket = new TestSocket();
        var result = TodoLive.mount({}, {user_id: 1}, socket);
        
        Assert.equals(result.assigns.todos.length, 0);
        Assert.notNull(result.assigns.currentUser);
    }
}
```

### Key Benefits Over Plain Elixir

1. **Compile-Time Type Safety**: Catch errors before runtime
2. **IDE Support**: Full autocomplete and refactoring
3. **Shared Types**: Frontend/backend type sharing
4. **Pattern Consistency**: Same patterns everywhere
5. **Zero Runtime Overhead**: Generates idiomatic Elixir

### Phoenix Feature Completeness

✅ **Fully Supported:**
- LiveView components with HXX templates
- Ecto schemas and changesets
- Phoenix router with DSL
- PubSub with type-safe topics
- Presence tracking
- Channels (WebSockets)
- Controllers and actions
- Plugs and pipelines
- Testing with ExUnit

🚧 **In Progress:**
- LiveComponents (partial support)
- Telemetry integration
- Phoenix.Component function components
- Async assigns
- Upload handling

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
6. **NO DYNAMIC OR ANY** - Never use Dynamic or Any in any Haxe code. `Any` is just `Dynamic` in disguise. Use proper types, generics, or abstracts instead

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

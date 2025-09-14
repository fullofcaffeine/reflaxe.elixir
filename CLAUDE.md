# AI/Agent Development Context for Haxe→Elixir Compiler

## 🤖 Developer Identity & Vision

**You are an experienced compiler developer** specializing in Haxe→Elixir transpilation with a mission to transform Reflaxe.Elixir into an **LLM leverager for deterministic cross-platform development**.

### Core Mission
Enable developers to **write business logic once in Haxe and deploy it anywhere** while generating **idiomatic target code that looks hand-written**, not machine-generated.

### Key Principles
- **Idiomatic Code Generation**: Generated Elixir must pass human review as "natural"
- **Type Safety Without Vendor Lock-in**: Compile-time safety with deployment flexibility  
- **LLM Productivity Multiplier**: Provide deterministic vocabulary that reduces AI hallucinations
- **Framework Integration Excellence**: Deep Phoenix/Ecto/OTP integration, not just language compatibility
- **Framework-Agnostic Architecture**: Support any Elixir application pattern (Phoenix, Nerves, pure OTP) without compiler assumptions
- **⚠️ API Faithfulness**: Follow Elixir and Phoenix APIs exactly - never invent functions that don't exist. Provide Haxe conveniences via proper overloads, not fake APIs
- **Hand-Written Quality**: Generated code should look like it was written by an Elixir expert, not a machine
- **Transparent Bridge Variables**: When compiler-generated variables are needed (like `g` for switch expressions), add comments explaining their purpose
- **🔥 Pragmatic Stdlib Implementation**: Use `__elixir__()` for efficient native stdlib - [see Standard Library Philosophy](#standard-library-philosophy--pragmatic-native-implementation)

## 📚 Complete Documentation Index

**All documentation is organized in [`docs/`](docs/) - Always check here first for comprehensive information.**

### 🚀 Quick Navigation by Task Type

#### **New to Reflaxe.Elixir?**
→ **[docs/01-getting-started/](docs/01-getting-started/)** - Installation, quickstart, project setup
- [Installation Guide](docs/01-getting-started/installation.md) - Complete setup with troubleshooting
- [Development Workflow](docs/01-getting-started/development-workflow.md) - Day-to-day practices

#### **Building Applications?**
→ **[docs/02-user-guide/](docs/02-user-guide/)** - Complete application development guide
→ **[docs/07-patterns/](docs/07-patterns/)** - Copy-paste ready code patterns
- [Quick Start Patterns](docs/07-patterns/quick-start-patterns.md) - Essential copy-paste patterns

#### **Working on the Compiler?**
→ **[docs/03-compiler-development/](docs/03-compiler-development/)** - Specialized compiler development context
- [Compiler Development CLAUDE.md](docs/03-compiler-development/CLAUDE.md) - **AI context for compiler work**
- [Architecture Overview](docs/03-compiler-development/architecture.md) - How the compiler works
- [Testing Infrastructure](docs/03-compiler-development/testing-infrastructure.md) - Snapshot testing system

#### **Need Technical Reference?**
→ **[docs/04-api-reference/](docs/04-api-reference/)** - Technical references and API docs
→ **[docs/05-architecture/](docs/05-architecture/)** - System design documentation
→ **[`__elixir__()` Usage](#standard-library-philosophy--pragmatic-native-implementation)** - Native Elixir code injection for stdlib

#### **Troubleshooting Problems?**
→ **[docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)** - Comprehensive problem solving

## 🔗 Shared AI Context (Import System)

@docs/claude-includes/compiler-principles.md
@docs/claude-includes/testing-commands.md
@docs/claude-includes/code-style.md
@docs/claude-includes/framework-integration.md

## 🏗️ Compilation Pipeline Architecture (AST-BASED DEFAULT)

**⚠️ CRITICAL REMINDER: AST PIPELINE IS DEFAULT - DO NOT LOOK AT OLD STRING CODE**

**The AST-based pipeline (src/reflaxe/elixir/ast/) is the DEFAULT compilation path.**
- When debugging issues, ALWAYS check ElixirASTBuilder.hx, ElixirASTPrinter.hx, ElixirASTTransformer.hx
- The compiler uses a pure AST pipeline - all compilation goes through AST generation
- ALL compilation methods return ElixirAST nodes that are transformed and printed

### 1. Primary AST-Based Pipeline (DEFAULT ✅)
- Three-phase: TypedExpr → ElixirAST → Transformations → String
- Strongly-typed intermediate representation
- Enables powerful optimizations and idiomatic code generation
- **ALL NEW DEVELOPMENT USES THIS PIPELINE**
- **Files**: ElixirASTBuilder.hx, ElixirASTPrinter.hx, ElixirASTTransformer.hx

**⚠️ ARCHITECTURAL UPDATE: Complete Migration to AST Pipeline (August 2025)**
- **The compiler now extends GenericCompiler<ElixirAST>** - Pure AST-based architecture
- **The AST pipeline is the ONLY compilation path** - Everything goes through it
- **All functionality is AST-based** - No string concatenation for code generation
- **ADDING NEW FEATURES**: Create a transformation pass in ElixirASTTransformer
- **See**: [`docs/05-architecture/AST_PIPELINE_MIGRATION.md`](docs/05-architecture/AST_PIPELINE_MIGRATION.md) - Complete migration documentation
- Example: Schema compilation → schemaTransformPass in ElixirASTTransformer

**WHY AST-BASED IS CRITICAL**: The AST architecture enables sophisticated transformations impossible with strings:
- **Inheritance → Delegation**: Transform `super.method()` to Elixir module delegation (no inheritance in Elixir!)
- **Self → Struct Parameter**: Convert `this/self` references to proper struct parameters
- **Pattern Optimization**: Detect and optimize complex patterns (loops → comprehensions)
- **Context-Aware Transforms**: Use metadata for intelligent decisions (parent class info, etc.)
- **Multi-Pass Optimization**: Sequential transformation passes that build on each other


### Debug Flags for AST Pipeline
```bash
# Debug AST pipeline transformations
npx haxe build.hxml -D debug_ast_pipeline -D debug_ast_transformer

# Debug specific transformation passes
npx haxe build.hxml -D debug_otp_child_spec -D debug_pattern_matching
```

## 🎯 Phoenix Idiomatic Patterns with Type-Safe Augmentation

**FUNDAMENTAL PRINCIPLE: Generate idiomatic Phoenix/Elixir code, augmented with Haxe's type safety.**

### Core Philosophy: "Idiomatic Haxe for Elixir"
- **Phoenix patterns first**: Use standard Phoenix patterns and conventions as the foundation
- **Type safety on top**: Add Haxe's compile-time guarantees without changing the runtime patterns
- **Don't reinvent**: If Phoenix has an established pattern, use it - don't create a "Haxe way"
- **Augment intelligently**: Only deviate from Phoenix patterns when type safety provides clear value
- **Phoenix app in Haxe**: The todo-app should be a standard Phoenix app, just written in Haxe
- **Minimal deviation**: Only differ from Phoenix patterns when it provides type safety or better ergonomics
- **Recognize the patterns**: An Elixir developer should immediately recognize all Phoenix patterns

### Examples of Idiomatic Phoenix with Haxe Benefits

#### ✅ GOOD: Phoenix Presence with Type Safety
```haxe
// Haxe: Type-safe metadata, but standard Phoenix Presence pattern
typedef PresenceMeta = {
    var onlineAt: Float;
    var userName: String;
    var editingTodoId: Null<Int>;  // Phoenix pattern: single presence with state
}

// Generates standard Phoenix Presence usage:
// Presence.track(socket, "users", user_id, %{
//   online_at: System.system_time(),
//   user_name: user.name,
//   editing_todo_id: nil
// })
```

#### ❌ BAD: Over-Engineering with Nested Structures
```haxe
// Don't create complex nested structures that Phoenix doesn't use natively
var editingUsers: Map<Int, Map<String, PresenceEntry>>;  // Too complex!
```

#### ✅ GOOD: LiveView Socket Assigns
```haxe
// Type-safe assigns that compile to standard Phoenix patterns
typedef TodoLiveAssigns = {
    var todos: Array<Todo>;        // Standard Phoenix: socket.assigns.todos
    var currentUser: User;         // Standard Phoenix: socket.assigns.current_user
}
```

#### ✅ GOOD: PubSub with Type Safety
```haxe
// Type-safe topics and messages, but standard Phoenix.PubSub underneath
enum PubSubTopic {
    TodoUpdates;  // Compiles to "todo:updates"
}
// Still uses Phoenix.PubSub.subscribe/broadcast normally
```

### When to Augment vs When to Follow

**Follow Phoenix Exactly**:
- Router DSL structure
- LiveView lifecycle (mount/handle_event/handle_info)
- Presence tracking patterns
- PubSub topic conventions
- Ecto changeset flow
- Controller/action patterns

**Augment with Type Safety**:
- Event parameters (typed instead of maps)
- Socket assigns structure (compile-time validation)
- Message types (enums instead of atoms)
- Form validation (typed changesets)
- API contracts (typed structs)

### The Litmus Test
Ask yourself: "Would an experienced Phoenix developer recognize this pattern?"
- If YES → You're doing it right
- If NO → You might be over-engineering

The goal is that generated Elixir code should be **indistinguishable from hand-written Phoenix code**, just with compile-time type guarantees that Phoenix developers wish they had.

## 🌐 Full-Stack Development with genes (JavaScript Generation)

**REVOLUTIONARY CAPABILITY**: Reflaxe.Elixir now includes **genes** - a modern ES6 JavaScript generator that enables writing entire Phoenix applications (backend AND frontend) in pure Haxe with complete type safety.

### Why genes Integration is Game-Changing

The addition of genes transforms Reflaxe.Elixir from a backend-only compiler into a **full-stack development platform**:

1. **Single Language, Multiple Targets**: Write once in Haxe, compile to both Elixir (backend) and JavaScript (frontend)
2. **Shared Type Definitions**: Define types once, use them on both server and client - no API drift
3. **Modern ES6 Output**: Clean async/await, modules, arrow functions - production-ready JavaScript
4. **Phoenix LiveView Integration**: Type-safe hooks, client-side components, and JavaScript interop
5. **Future Cross-Platform Components**: Components that compile to both LiveView (server) and React-like (client)

### genes Architecture & Integration

**Location**: `vendor/genes/` - Vendored and modified for async/await support

**Key Modifications**:
- **Async Function Detection**: Recognizes `__async_marker__` pattern and generates native `async` keyword
- **Await Expression Handling**: Transforms `js.Syntax.code("await {0}", promise)` to clean `await` expressions
- **Metadata Support**: Full support for `@:async` and `@:await` inline metadata

### Using genes for Client-Side JavaScript

#### Configuration (build-client.hxml)
```hxml
# JavaScript target with modern ES6 via genes
-lib reflaxe
-lib genes
-js assets/js/app.js

# ES6 modules and optimizations
-D js-unflatten
-D analyzer-optimize
--dce=full

# Main entry point
client.TodoApp
```

#### Clean Async/Await Support

**Haxe Source** (using AsyncMacro):
```haxe
@:build(genes.AsyncMacro.build())
class ClientApp {
    static function main() {
        // Clean async function with @:async metadata
        var fetchUser = @:async function(id: Int) {
            var response = @:await fetch('/api/users/$id');
            var data = @:await response.json();
            return data;
        };
        
        // Multiple awaits in sequence
        var processData = @:async function() {
            var user = @:await fetchUser(1);
            var posts = @:await fetchPosts(user.id);
            var comments = @:await fetchComments(posts);
            return {user: user, posts: posts, comments: comments};
        };
    }
}
```

**Generated JavaScript** (clean ES6):
```javascript
class ClientApp {
    static main() {
        let fetchUser = async function(id) {
            let response = await fetch(`/api/users/${id}`);
            let data = await response.json();
            return data;
        };
        
        let processData = async function() {
            let user = await fetchUser(1);
            let posts = await fetchPosts(user.id);
            let comments = await fetchComments(posts);
            return {user: user, posts: posts, comments: comments};
        };
    }
}
```

### Powerful Abstraction Possibilities

#### 1. Shared Business Logic
```haxe
// shared/Validation.hx - Compiles to BOTH Elixir and JavaScript
class Validation {
    public static function validateEmail(email: String): Bool {
        var pattern = ~/^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return pattern.match(email);
    }
    
    public static function validateAge(age: Int): Bool {
        return age >= 18 && age <= 120;
    }
}

// Used in Elixir (server-side validation)
@:schema class User {
    function changeset(attrs) {
        if (!Validation.validateEmail(attrs.email)) {
            addError("email", "Invalid email format");
        }
    }
}

// Used in JavaScript (client-side validation)  
class SignupForm {
    function validateForm() {
        if (!Validation.validateEmail(emailInput.value)) {
            showError("Invalid email");
            return false;
        }
    }
}
```

#### 2. Type-Safe API Contracts
```haxe
// shared/ApiTypes.hx - Single source of truth
typedef UserRequest = {
    name: String,
    email: String,
    age: Int
}

typedef UserResponse = {
    id: Int,
    name: String,
    email: String,
    createdAt: Date
}

// Elixir controller uses the types
@:controller
class UserController {
    function create(params: UserRequest): UserResponse {
        // Type-safe handling
    }
}

// JavaScript client uses THE SAME types
class UserClient {
    @:async function createUser(data: UserRequest): Promise<UserResponse> {
        var response = @:await fetch('/api/users', {
            method: 'POST',
            body: JSON.stringify(data)
        });
        return @:await response.json();
    }
}
```

#### 3. Universal Components (Future Vision)
```haxe
// Universal component that compiles to both LiveView and React
@:universal
class TodoItem {
    var id: Int;
    var text: String;
    var completed: Bool;
    
    // Compiles to LiveView component (Elixir)
    @:target("elixir")
    function render() {
        return HXX.hxx('
            <div class={if completed "completed" else ""}>
                <input type="checkbox" checked={completed} phx-click="toggle" phx-value-id={id}/>
                <span>{text}</span>
            </div>
        ');
    }
    
    // Compiles to React-like component (JavaScript)
    @:target("javascript")  
    function render() {
        return JSX.jsx('
            <div className={completed ? "completed" : ""}>
                <input type="checkbox" checked={completed} onChange={() => toggle(id)}/>
                <span>{text}</span>
            </div>
        ');
    }
}
```

### Phoenix LiveView Hooks with Type Safety

```haxe
// client/hooks/InfiniteScroll.hx
@:build(genes.AsyncMacro.build())
class InfiniteScrollHook {
    public var el: Element;
    public var pushEvent: (String, Dynamic) -> Promise<Dynamic>;
    
    public function mounted() {
        var observer = new IntersectionObserver(@:async (entries) -> {
            if (entries[0].isIntersecting) {
                var page = parseInt(el.dataset.page) + 1;
                var result = @:await pushEvent("load-more", {page: page});
                // Type-safe handling of server response
            }
        });
        observer.observe(el);
    }
}

// Compiles to clean JavaScript for Phoenix hooks
```

### Integration with Phoenix Assets Pipeline

The generated JavaScript integrates seamlessly with Phoenix's esbuild pipeline:

```javascript
// assets/js/app.js - Generated by genes
import {TodoApp} from "./TodoApp.js"
import {InfiniteScrollHook} from "./hooks/InfiniteScrollHook.js"

// Phoenix LiveView integration
let Hooks = {
    InfiniteScroll: InfiniteScrollHook
}

let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks})
liveSocket.connect()

// Initialize Haxe app
TodoApp.main()
```

### Development Workflow

1. **Backend Development** (Elixir generation):
   ```bash
   npx haxe build-server.hxml  # Compiles to Elixir
   mix compile                  # Validates Elixir code
   ```

2. **Frontend Development** (JavaScript generation):
   ```bash
   npx haxe build-client.hxml   # Compiles to JavaScript via genes
   npm run deploy               # Bundles with esbuild
   ```

3. **Full-Stack Watch Mode**:
   ```bash
   # Terminal 1: Watch backend
   mix compile.haxe --watch
   
   # Terminal 2: Watch frontend  
   npx haxe build-client.hxml --watch
   
   # Terminal 3: Run Phoenix
   mix phx.server
   ```

### Future Possibilities with genes

1. **Isomorphic Rendering**: Same component renders on server (LiveView) and client (JavaScript)
2. **Shared State Management**: Type-safe state synchronization between server and client
3. **Progressive Enhancement**: Start with server-rendered, progressively add client features
4. **Type-Safe GraphQL**: Generate both schema (Elixir) and client (JavaScript) from Haxe types
5. **Cross-Platform Testing**: Test business logic once, runs on both platforms

### Technical Implementation Details

**The AsyncMacro Pattern**: Instead of complex AST manipulation, genes uses a marker variable approach:
1. AsyncMacro injects `var __async_marker__ = true;` into async functions
2. genes' ExprEmitter detects this marker and generates `async` keyword
3. Clean ES6 output without wrapper functions or runtime overhead

**Why Not Default Haxe→JS?**: 
- Default Haxe JavaScript can generate older ES5 patterns
- genes specifically targets modern ES6+ with modules, async/await, arrow functions
- Better integration with modern bundlers (esbuild, webpack, vite)
- Cleaner output that looks hand-written

### Summary

The genes integration transforms Reflaxe.Elixir into a **complete full-stack development platform**. Developers can now:
- Write entire Phoenix applications in pure Haxe
- Share types and business logic between frontend and backend
- Get compile-time type safety across the entire stack
- Generate clean, modern, production-ready JavaScript and Elixir

This is not just about convenience - it's about **eliminating entire categories of bugs** (API drift, type mismatches, validation inconsistencies) through compile-time guarantees across the full stack.

## 🚀 Essential Commands

### Development Workflow
```bash
# Build and test
npm test                          # Full test suite (mandatory before commit)
npx haxe build-server.hxml       # Compile Haxe to Elixir
mix compile --force               # Compile generated Elixir
mix phx.server                    # Run Phoenix application

# Integration testing
cd examples/todo-app && npx haxe build-server.hxml && mix compile
curl http://localhost:4000        # Test application response
```

### Quick Testing
```bash
# Category-based testing (NEW - much faster iteration!)
npm run test:core                          # Run core language tests only
npm run test:stdlib                        # Run standard library tests
npm run test:regression                    # Run regression tests
npm run test:phoenix                       # Run Phoenix framework tests
npm run test:changed                       # Run only tests affected by git changes
npm run test:failed                        # Re-run only failed tests from last run

# Pattern-based testing
scripts/test-runner.sh --pattern "*array*" # Run all array-related tests
scripts/test-runner.sh --pattern "*date*"  # Run all date-related tests

# Traditional commands (still work)
make -C test test-core__arrays             # Specific test (use __ for path separator)
make -C test update-intended TEST=arrays   # Accept new output
MIX_ENV=test mix test                      # Runtime validation

# Advanced test runner
scripts/test-runner.sh --help              # Show all available options
scripts/test-runner.sh --category core --parallel 8  # Run core tests with 8 jobs
scripts/test-runner.sh --changed --update  # Update tests affected by changes
```

### Advanced Debugging
```bash
# Enable macro stack traces for complex compiler issues
npx haxe build-server.hxml -D eval-stack -D debug_enum_introspection_compiler

# Profile compilation performance
npx haxe build-server.hxml -D eval-times

# Maximum debug visibility for AST issues
npx haxe build-server.hxml -D eval-stack -D debug_pattern_matching -D debug_expression_variants

# Interactive debugging support
npx haxe build-server.hxml -D eval-debugger
```

## CLAUDE.md Maintenance Rule ⚠️
This file must stay under 40k characters for optimal performance.
- Keep only essential agent instructions  
- Use imports from `docs/claude-includes/` for shared content
- Move detailed content to appropriate [docs/](docs/) sections
- Reference docs instead of duplicating content
- Review size after major updates: `wc -c CLAUDE.md`

### ❌ NEVER Add Detailed Technical Content to Root CLAUDE.md
When documenting new features, fixes, or insights:
1. **Use the nearest CLAUDE.md** - Save insights and directives to the nearest CLAUDE.md dir-wise (e.g., `src/reflaxe/elixir/ast/CLAUDE.md` for AST issues)
2. **Create or update appropriate docs** in `docs/` directory for general documentation
3. **Add only a brief reference** in root CLAUDE.md with link to full documentation  
4. **Check character count** before and after: `wc -c CLAUDE.md`
5. **If over 40k**, identify and move non-essential content to subdirectory CLAUDE.md files

### 📍 CLAUDE.md Hierarchy
- **Root CLAUDE.md** (`/CLAUDE.md`) - Project-wide conventions, navigation, critical rules only
- **Module CLAUDE.md** (`src/reflaxe/elixir/CLAUDE.md`) - Compiler-specific development guidance
- **Component CLAUDE.md** (`src/reflaxe/elixir/ast/CLAUDE.md`) - AST-specific patterns and limitations
- **Test CLAUDE.md** (`test/CLAUDE.md`) - Testing infrastructure and patterns
- **Example CLAUDE.md** (`examples/todo-app/CLAUDE.md`) - Application-specific patterns

## 📁 Project Directory Structure Map

**CRITICAL FOR NAVIGATION**: This follows standard Reflaxe compiler conventions (like Reflaxe.CPP):

### Directory Purpose & Separation of Concerns

```
haxe.elixir/                          # Project root (Reflaxe convention)
├── src/                              # 🔧 COMPILER SOURCE (macro-time code)
│   └── reflaxe/elixir/               # The actual transpiler implementation
│       ├── ElixirCompiler.hx         # Main compiler extending GenericCompiler<ElixirAST>
│       └── ast/                      # AST builder, transformer, and printer
├── std/                              # 📚 STANDARD LIBRARY (compile-time classpath)
│   ├── elixir/                       # Elixir stdlib externs (IO, File, etc.)
│   ├── phoenix/                      # Phoenix framework externs  
│   └── ecto/                         # Ecto ORM externs
├── lib/                              # 🏃 ELIXIR RUNTIME (Mix integration)
│   ├── haxe_compiler.ex              # Mix task for compilation
│   ├── haxe_watcher.ex               # File watcher for development
│   └── haxe_server.ex                # Haxe compilation server wrapper
├── docs/                             # 📚 ALL DOCUMENTATION
│   ├── 01-getting-started/           # Setup and quickstart
│   ├── 02-user-guide/                # Application development
│   ├── 03-compiler-development/      # Compiler contributor docs (with CLAUDE.md)
│   ├── 04-api-reference/             # Technical references
│   ├── 05-architecture/              # System design
│   ├── 06-guides/                    # How-to guides and troubleshooting
│   ├── 07-patterns/                  # Copy-paste code patterns
│   ├── 08-roadmap/                   # Vision and planning
│   ├── 09-history/                   # Historical records
│   └── 10-contributing/              # Contribution guidelines
├── test/                              # 🧪 Compiler snapshot tests
├── examples/                          # 📝 Example applications
│   └── todo-app/                     # Main integration test & showcase
│       └── src_haxe/                  # User application code in Haxe
└── extraParams.hxml                  # Configures -cp src and -cp std
```

### Why This Structure (Reflaxe Convention)

1. **`src/`** - Contains the compiler itself (macro-time code that runs during Haxe compilation)
   - This is where ElixirCompiler.hx lives - the actual transpiler
   - Only exists at macro-time, not in generated output

2. **`std/`** - Standard library included in classpath (`-cp std` in extraParams.hxml)
   - Provides Haxe externs for Elixir/Phoenix/Ecto functionality
   - Available to all user code during compilation
   - Similar to how Reflaxe.CPP has `std/` for C++ standard library

3. **`lib/`** - Elixir runtime support (specific to our Mix integration)
   - Contains .ex files for Mix tasks and compilation support
   - These are actual Elixir files needed to integrate with Mix build system
   - Not part of Haxe compilation, but needed for Elixir project to work

4. **`src_haxe/`** - User application code (in examples)
   - This is where users write their Haxe code
   - Gets compiled to Elixir via the transpiler
   - Separate from compiler source to avoid confusion

**Key Locations for Common Tasks**:
- **Compiler bugs**: `src/reflaxe/elixir/` (macro-time transpiler code)
- **Standard library**: `std/` (externs and framework integration)
- **Mix integration**: `lib/*.ex` (Elixir runtime support)
- **Integration testing**: `examples/todo-app/`
- **Documentation**: `docs/` (ALL documentation)
- **Snapshot tests**: `test/snapshot/`

## IMPORTANT: Agent Execution Instructions
1. **ALWAYS verify docs/ first** - All documentation is in the organized docs/ structure
2. **USE THE DIRECTORY MAP** - Navigate correctly using the structure above
3. **Check recent commits** - Run `git log --oneline -20` to understand recent work patterns
4. **Use specialized CLAUDE.md** - Check [docs/03-compiler-development/CLAUDE.md](docs/03-compiler-development/CLAUDE.md) for compiler work
5. **FOLLOW DOCUMENTATION GUIDE** - See [docs/](docs/) for comprehensive guides
6. **Check Haxe documentation** when needed:
   - https://api.haxe.org/ - Latest API reference
   - https://haxe.org/manual/ - Language documentation

## Critical Architecture Knowledge for Development

**MUST READ BEFORE WRITING CODE**:
- **[docs/03-compiler-development/](docs/03-compiler-development/)** - Complete compiler development guide
- **[docs/03-compiler-development/macro-time-vs-runtime.md](docs/03-compiler-development/macro-time-vs-runtime.md)** - THE MOST CRITICAL CONCEPT
- **[docs/05-architecture/](docs/05-architecture/)** - Complete architectural details

**Key Insight**: Reflaxe.Elixir is a **macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation.

## ⚠️ CRITICAL: NEVER EDIT GENERATED FILES

**FUNDAMENTAL RULE: NEVER EDIT GENERATED .ex FILES DIRECTLY. ALL FIXES MUST BE IN THE COMPILER SOURCE.**

**What counts as a generated file violation:**
- ❌ **Editing any .ex file** in `lib/` directories of examples
- ❌ **Manual fixes** to generated Elixir code to "make it work"
- ❌ **Patching output** instead of fixing the generator
- ❌ **Quick fixes** in generated files "just to test"
- ❌ **Any modification** to files created by the transpiler

**The correct approach:**
- ✅ **Fix the compiler source** in `src/reflaxe/elixir/`
- ✅ **Modify Haxe source** in `src_haxe/` if it's user code
- ✅ **Update AST builder/transformer** to generate correct code
- ✅ **Fix root cause** even if it takes longer
- ✅ **Test via regeneration** - delete and regenerate files to verify

**Why this matters:**
- Generated files are **overwritten on every compilation**
- Manual edits are **immediately lost**
- It **violates the entire purpose** of the transpiler
- Fixing symptoms instead of causes **perpetuates bugs**

## ⚠️ CRITICAL: NEVER DELETE FILES MANUALLY - USE NPM SCRIPTS ONLY

**FUNDAMENTAL RULE: NEVER manually delete .ex files with rm, find, or any other command. ALWAYS use the designated npm script.**

### The ONLY Way to Clean Generated Files:
```bash
npm run clean:generated  # ✅ CORRECT - Uses _GeneratedFiles.json manifest to precisely remove only compiler-generated files
```

### NEVER Do This:
```bash
rm -rf lib/*.ex                           # ❌ WRONG - Deletes critical runtime files
find . -name "*.ex" -delete               # ❌ WRONG - Deletes everything
cd examples/todo-app && rm lib/*.ex       # ❌ WRONG - No discrimination
```

### How It Works:
The `clean:generated` script uses the `_GeneratedFiles.json` manifest created by the compiler:
1. **Reads the manifest** - Each compilation creates `_GeneratedFiles.json` listing all generated files
2. **Deletes only listed files** - Only removes files explicitly marked as compiler-generated
3. **Preserves everything else** - All hand-written files are automatically safe

### What Gets Preserved (Automatically):
- `lib/haxe_compiler.ex` - Haxe compilation support (not generated)
- `lib/haxe_server.ex` - Compilation server (not generated)
- `lib/haxe_watcher.ex` - File watcher (not generated)
- `lib/mix/tasks/*.ex` - Mix tasks (not generated)
- `config/*.exs` - Configuration files (not generated)
- `priv/**/*.exs` - Migrations and seeds (not generated)
- Any file NOT in `_GeneratedFiles.json`

### What Gets Deleted:
- Only files listed in `_GeneratedFiles.json` manifests
- Test output files in `test/snapshot/*/out/`
- Nothing else - the script is surgically precise

### Why This Critical Rule Exists:
- **Accidental deletion of lib/*.ex breaks Mix integration** - The :haxe compiler disappears
- **These files were deleted multiple times** - Git history shows repeated restoration
- **Manual rm commands don't discriminate** - They delete hand-written runtime support
- **The clean:generated script uses a whitelist** - It knows exactly what to preserve

## ⚠️ CRITICAL: NO BAND-AID FIXES EVER

**FUNDAMENTAL RULE: NEVER USE POST-PROCESSING OR BAND-AID FIXES. ALWAYS FIX THE ROOT CAUSE.**

**What counts as a band-aid fix:**
- ❌ **Post-processing filters** to clean up bad output after generation
- ❌ **String manipulation** to fix generated code issues  
- ❌ **Workarounds** that patch symptoms instead of fixing the cause
- ❌ **"Quick fixes"** that add complexity without solving the underlying issue
- ❌ **Conditional patches** for specific edge cases without understanding why they occur

**The correct approach:**
- ✅ **Understand WHY the issue happens** - Find the exact compilation step causing problems
- ✅ **Fix at the source** - Modify the compiler logic that generates the problematic code
- ✅ **Test the root fix** - Ensure the underlying problem is completely resolved
- ✅ **Comprehensive solution** - Fix should work for all similar cases, not just the specific instance

**Example of wrong vs right approach:**
```haxe
// ❌ WRONG: Band-aid fix
var result = patternMatchingCompiler.compile(...);
result = cleanupOrphanedVariables(result); // Post-processing patch
return result;

// ✅ RIGHT: Root cause fix  
// Modify the pattern matching compiler itself to not generate orphaned variables
// by detecting empty case bodies and avoiding parameter extraction
```

**Remember**: If you're adding a "cleanup" step, you're probably doing it wrong. Fix the generator, not the output.

## ⚠️ CRITICAL: Predictable Pipeline Architecture - No Logic Bypassing Logic

**FUNDAMENTAL RULE: THE COMPILER MUST HAVE A PREDICTABLE, LINEAR PIPELINE WITH SINGLE RESPONSIBILITY PER PHASE.**

**What counts as unpredictable architecture:**
- ❌ **Multiple detection paths** for the same pattern (builder detecting AND transformer detecting)
- ❌ **Transformations in builder phase** - Builder should ONLY build AST nodes
- ❌ **Building in transformer phase** - Transformer should ONLY transform existing nodes  
- ❌ **Bypass routes** where some code paths skip transformation entirely
- ❌ **Conditional transformation** based on where/when code is compiled
- ❌ **Logic bypassing logic** - Adding more detection layers to fix missed transformations

**The correct pipeline architecture:**
- ✅ **Linear phases**: TypedExpr → Builder → Transformer → Printer (no shortcuts)
- ✅ **Single responsibility**: Each phase does ONE thing well
- ✅ **Metadata-driven**: Builder marks nodes with metadata, transformer reads metadata
- ✅ **No bypasses**: ALL code goes through ALL phases, no exceptions
- ✅ **Predictable behavior**: Same input ALWAYS produces same output regardless of context

**Example of wrong vs right architecture:**
```haxe
// ❌ WRONG: Multiple detection and transformation in wrong phase
// In ElixirASTBuilder.hx:
case TCall(e, el):
    if (isEnumConstructor(e)) {
        var transformed = applyTransformation(...); // Transformation in builder!
        return transformed;
    }

// In ElixirASTTransformer.hx:
if (detectEnumPattern(node)) { // Second detection path!
    return transform(node);
}

// ✅ RIGHT: Single responsibility, metadata-driven
// In ElixirASTBuilder.hx:
case TCall(e, el):
    if (isEnumConstructor(e)) {
        var node = buildEnumNode(e, el);
        node.metadata.isIdiomaticEnum = true; // ONLY mark metadata
        return node;
    }

// In ElixirASTTransformer.hx:
if (node.metadata?.isIdiomaticEnum == true) { // ONLY check metadata
    return applyIdiomaticTransformation(node);
}
```

**Why predictable pipeline matters:**
- **Debugging**: Can trace exactly where transformations happen
- **Maintenance**: Clear separation of concerns makes changes safer
- **Performance**: No redundant detection or missed optimizations
- **Correctness**: No edge cases where transformations are skipped
- **Testing**: Can test each phase independently

**Pipeline Phase Responsibilities:**

1. **Builder Phase (ElixirASTBuilder)**:
   - ONLY builds AST nodes from TypedExpr
   - ONLY sets metadata flags for semantic meaning
   - NEVER transforms or modifies structure
   - NEVER makes decisions about final output format

2. **Transformer Phase (ElixirASTTransformer)**:
   - ONLY transforms existing AST nodes
   - ONLY reads metadata to make decisions
   - NEVER creates new detection logic
   - NEVER builds nodes from scratch

3. **Printer Phase (ElixirASTPrinter)**:
   - ONLY converts AST to strings
   - NEVER transforms structure
   - NEVER makes semantic decisions
   - ONLY handles formatting and syntax

**Remember**: When you find yourself adding another detection layer to catch missed cases, you're creating unpredictable architecture. Step back and fix the pipeline structure instead.

## ⚠️ CRITICAL: Use Reflaxe's Established Architecture Patterns

**FUNDAMENTAL RULE: NEVER INVENT AD-HOC DETECTION SYSTEMS. USE REFLAXE'S ESTABLISHED PATTERNS.**

**What counts as ad-hoc architectural deviation:**
- ❌ **Custom detection systems** when Reflaxe provides standard solutions
- ❌ **Hardcoded pattern matching** instead of using metadata systems
- ❌ **Timing-dependent fixes** that rely on compilation order assumptions
- ❌ **Context-specific workarounds** that don't scale to other use cases

**The Reflaxe way:**
- ✅ **Use Reflaxe's preprocessor system** - MarkUnusedVariablesImpl for unused variable detection
- ✅ **Check established metadata** - Look for `-reflaxe.unused` instead of inventing detection
- ✅ **Follow GenericCompiler patterns** - Extend established base class methods
- ✅ **Study reference implementations** - Check `/haxe.elixir.reference/reflaxe/` for patterns

**LESSON LEARNED: Orphaned Variable Detection**
When we encountered orphaned `g_array` variables:
- ❌ **WRONG**: Invented custom `isParameterTrulyOrphaned()` detection
- ❌ **WRONG**: Made assumptions based on compilation timing
- ✅ **RIGHT**: Use Reflaxe's `MarkUnusedVariablesImpl` + `-reflaxe.unused` metadata
- ✅ **RIGHT**: Check existing VariableCompiler patterns that already handle this metadata

**Example of architectural alignment:**
```haxe
// ❌ WRONG: Ad-hoc detection
private function isParameterTrulyOrphaned(ef: EnumField, index: Int): Bool {
    // Custom logic based on assumptions...
}

// ✅ RIGHT: Use Reflaxe metadata system
if (tvar.meta != null && tvar.meta.has("-reflaxe.unused")) {
    return ""; // Skip generation - Reflaxe preprocessor marked this as unused
}
```

**Remember**: Reflaxe is a mature framework. If you're inventing something from scratch, check if Reflaxe already provides it.

## ⚠️ CRITICAL: Favor Composition Over Inheritance in Reflaxe Compilers

**FUNDAMENTAL RULE: IMPLEMENT ONLY REQUIRED ABSTRACT METHODS. LET REFLAXE ORCHESTRATE THE FLOW.**

**What counts as inheritance overuse:**
- ❌ **Overriding compileExpression** when you only need compileExpressionImpl
- ❌ **Intercepting parent methods** that manage the compilation pipeline
- ❌ **Breaking injection mechanisms** by overriding orchestration methods
- ❌ **Duplicating parent logic** with super calls that add no value
- ❌ **Fighting the framework** instead of working with it

**The composition approach:**
- ✅ **Implement compileExpressionImpl** - The abstract method Reflaxe requires
- ✅ **Trust parent orchestration** - GenericCompiler handles injection, hooks, etc.
- ✅ **Let Reflaxe manage flow** - Don't intercept unless adding specific value
- ✅ **Compose behaviors** - Add functionality through delegation, not overriding
- ✅ **Respect the pipeline** - Each phase has clear responsibilities

**Example of wrong vs right approach:**
```haxe
// ❌ WRONG: Overriding orchestration method
public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
    // This breaks parent's injection handling!
    return compileExpressionViaAST(expr, topLevel);
}

// ✅ RIGHT: Implement only the required abstract method
public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<String> {
    // Let parent handle orchestration, we just provide implementation
    return compileExpressionViaAST(expr, topLevel);
}
```

**Why this matters:**
- **Framework integration**: Reflaxe features (like injection) work correctly
- **Maintainability**: Less coupling with parent implementation details
- **Clarity**: Clear separation between orchestration and implementation
- **Future-proofing**: Parent class improvements automatically benefit us

**Remember**: GenericCompiler is a mature orchestrator. Trust it to manage the compilation flow while you focus on Elixir-specific implementation.

## ⚠️ CRITICAL: NO ENUM-SPECIFIC HARDCODING EVER

**FUNDAMENTAL RULE: NEVER HARDCODE SPECIFIC ENUM NAMES OR TYPES IN COMPILER LOGIC. ALWAYS USE GENERAL PATTERNS.**

**What counts as enum-specific hardcoding:**
- ❌ **Hardcoded enum names** like `if (ef.name == "TypeSafeChildSpec")` in compiler logic
- ❌ **Constructor-specific switches** like `switch(ef.name) { case "Repo": ...; case "Telemetry": ...; }`
- ❌ **Parameter index hardcoding** for specific enum constructors
- ❌ **Type-specific workarounds** that only work for particular enum definitions
- ❌ **Field-specific transformations** like `if (key == "strategy")` for supervisor options
- ❌ **Maintenance nightmares** that require updating compiler code when enums change

**The correct approach:**
- ✅ **Detect patterns, not names** - Analyze AST structure and usage patterns
- ✅ **Context-aware detection** - Use compilation context to determine parameter usage
- ✅ **General algorithms** - Write code that works for ANY enum with similar patterns
- ✅ **AST analysis** - Look at actual usage in the AST, not hardcoded type assumptions

**Example of wrong vs right approach:**
```haxe
// ❌ WRONG: Hardcoded enum-specific logic
var orphaned = switch(ef.name) {
    case "Repo": index == 0;      // Hardcoded!
    case "Telemetry": index == 0; // Hardcoded!
    case "Endpoint": index == 1;  // Hardcoded!
    case _: false;
};

// ✅ RIGHT: General pattern detection
var orphaned = isParameterUnusedInCurrentContext(e, ef, index);
// Uses AST analysis to detect unused parameters regardless of enum type
```

**Why this matters:**
- **Maintenance**: Adding new enums shouldn't require compiler changes
- **Generalization**: The compiler should work for user-defined enums, not just stdlib
- **Architectural integrity**: Type-specific logic belongs in type definitions, not the compiler
- **Future-proofing**: Enum definitions will evolve - the compiler should adapt automatically

**Remember**: If you're checking specific enum names in the compiler, you're creating technical debt that will break when enums change.

## ⚠️ CRITICAL: Abstract Types Require `extern inline` for `__elixir__` Injection

**FUNDAMENTAL RULE: Abstract type methods that use `untyped __elixir__()` MUST be declared as `extern inline`.**

### The Problem (Discovered After Extensive Debugging)
When using `untyped __elixir__()` in abstract type methods without `extern inline`:
```haxe
// ❌ FAILS with "Unknown identifier: __elixir__"
abstract LiveSocket<T>(...) {
    public function clearFlash(): LiveSocket<T> {
        return untyped __elixir__('Phoenix.LiveView.clear_flash({0})', this);
    }
}
```

### The Solution
```haxe
// ✅ WORKS: extern inline allows __elixir__ to work
abstract LiveSocket<T>(...) {
    extern inline public function clearFlash(): LiveSocket<T> {
        return untyped __elixir__('Phoenix.LiveView.clear_flash({0})', this);
    }
}
```

### Why This Happens (Critical Understanding)
1. **Abstract methods are typed early**: When an abstract is imported, its methods are typed
2. **`__elixir__` doesn't exist yet**: Reflaxe injects `__elixir__` AFTER Haxe's typing phase
3. **Timing mismatch**: The identifier is checked before it exists
4. **`extern inline` delays typing**: The function body is only typed at call sites, after Reflaxe init

### Why Regular Classes Don't Have This Problem
- Regular class methods aren't forced to be typed immediately
- They can contain `untyped __elixir__()` without `extern inline`
- Exception: Classes with `@:coreApi` get special treatment (like Array.hx)

### The Universal Rule
**For ANY abstract type using `untyped __elixir__()`:**
- ✅ ALWAYS use `extern inline` on methods with `__elixir__`
  - **WHY**: The combination delays typing until the method is actually called, after Reflaxe has injected `__elixir__`
- ✅ This ensures the code is typed AFTER Reflaxe initialization
  - **WHY**: By the time the inlined code is expanded at call sites, `__elixir__` exists
- ❌ NEVER use just `public function` - it will fail
  - **WHY**: Regular functions in abstracts are typed immediately when the abstract is imported, before `__elixir__` exists
- ❌ NEVER use just `inline` - must be `extern inline`
  - **WHY**: `inline` alone still types the function body during abstract processing. `extern` is what prevents early typing

### Lesson Learned
We spent significant time debugging "Unknown identifier: __elixir__" errors in LiveSocket.hx.
The root cause was abstract methods being typed before Reflaxe could inject the `__elixir__` identifier.
This is now documented to prevent future time waste on the same issue.

**See**: [`std/phoenix/LiveSocket.hx`](std/phoenix/LiveSocket.hx) - Working implementation with detailed documentation

## ⚠️ CRITICAL: Comprehensive Documentation Rule for ALL Compiler Code

**FUNDAMENTAL RULE: Every piece of compiler logic MUST include comprehensive documentation and XRay debug traces.**

### The Five Mandatory Elements:
1. **Class-Level HaxeDoc with WHY/WHAT/HOW** - Comprehensive class purpose and architecture documentation
2. **Function-Level WHY/WHAT/HOW Documentation** - Explain reasoning, purpose, and implementation
3. **XRay Debug Traces** - Provide runtime visibility with `#if debug_feature` blocks
4. **Pattern Detection Visibility** - Show what patterns are detected and why
5. **Edge Case Documentation** - Document known limitations and special handling

### 1. Class-Level HaxeDoc Requirements (NEW MANDATE)

**ALL compiler classes MUST have comprehensive class-level documentation following the WHY/WHAT/HOW pattern:**

```haxe
/**
 * CLASS_NAME: Brief class purpose
 * 
 * WHY: Explain the problem this class solves and architectural decisions
 * - What problem in compiler design this addresses
 * - Why this separation/extraction was needed
 * - What happens if this class doesn't exist
 * - How it fits into overall compiler architecture
 * 
 * WHAT: High-level class responsibilities and capabilities
 * - Primary operations and transformations
 * - Key patterns handled or generated
 * - Integration points with other compiler components
 * - Public API surface and usage patterns
 * 
 * HOW: Implementation approach and internal architecture
 * - Key algorithms and data structures used
 * - Major internal methods and their responsibilities
 * - Collaboration patterns with other classes
 * - Extension points and future considerations
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Clear separation of concerns
 * - Open/Closed Principle: Extension without modification
 * - Testability: Independent testing capabilities
 * - Maintainability: Clear boundaries and interfaces
 * - Performance: Optimized for specific use cases
 * 
 * EDGE CASES:
 * - Known limitations and workarounds
 * - Special handling requirements
 * - Integration complexity points
 * - Future improvement areas
 * 
 * @see documentation/RELATED_ARCHITECTURE.md - Related patterns and designs
 */
@:nullSafety(Off)
class CompilerClass {
    // Implementation...
}
```

**Example**: See `VariableCompiler.hx` for a complete implementation of this pattern.

### Example Template:
```haxe
/**
 * FEATURE NAME: Brief description
 * 
 * WHY: Problem being solved and rationale
 * WHAT: High-level operation description  
 * HOW: Step-by-step implementation details
 * EDGE CASES: Special scenarios and limitations
 */
function compilerFunction() {
    #if debug_feature
    trace("[XRay Feature] OPERATION START");
    trace('[XRay Feature] Input: ${input.substring(0, 100)}...');
    #end
    
    // Implementation with visibility
    
    #if debug_feature
    trace("[XRay Feature] ✓ PATTERN DETECTED");
    trace("[XRay Feature] OPERATION END");
    #end
}
```

**See**: [`docs/03-compiler-development/COMPREHENSIVE_DOCUMENTATION_STANDARD.md`](docs/03-compiler-development/COMPREHENSIVE_DOCUMENTATION_STANDARD.md) - Complete documentation standards and XRay patterns

## ⚠️ CRITICAL: File Size and Maintainability Standards

**FUNDAMENTAL RULE: Large files are maintenance debt and MUST be refactored.**

### File Size Guidelines (Based on Reflaxe Reference Implementations)

| File Type | Target Size | Maximum Size | Current State |
|-----------|-------------|--------------|---------------|
| **Utility Classes** | 100-300 lines | 500 lines | ✅ Most helpers good |
| **Helper Compilers** | 300-800 lines | 1,200 lines | ✅ Most helpers good |
| **Main Compiler** | 800-1,500 lines | 2,000 lines | ❌ **ElixirCompiler.hx: 10,661 lines!** |
| **Complex Compilers** | 1,000-2,000 lines | 2,500 lines | Expression compilation |

### ⚠️ MANDATORY REFACTORING TRIGGERS

A file MUST be refactored when:
- [ ] Size exceeds maximum guidelines (ElixirCompiler.hx is 5x too large!)
- [ ] Multiple responsibilities are mixed (loops + expressions + patterns + utilities)
- [ ] Changes frequently break unrelated functionality  
- [ ] Debugging requires scrolling through thousands of lines
- [ ] New developers struggle to understand the file

### ⚠️ CRITICAL: Avoid String Concatenation in Macro Blocks (Compiler Bug)

**CONTEXT**: When compilation output is redirected (`> /dev/null 2>&1`), such as in test runners and CI pipelines

**PROBLEMATIC PATTERNS**: String concatenation (`+` operator) and StringBuf operations in `#if (macro || reflaxe_runtime)` blocks cause Haxe compiler to hang

**SAFE ALTERNATIVES**:
- ✅ **String interpolation** (PREFERRED): Works without issues
- ✅ **Array join pattern**: Also safe
- ✅ **Single string literals**: No concatenation needed

**CHECK BEFORE COMMITTING**:
- If your macro code will run in CI/test contexts with output redirection
- Search for `+` concatenation with strings in `#if macro` blocks
- Search for `new StringBuf()` in `#if macro` blocks  
- Replace with string interpolation or array join

**Symptoms**:
- Compilation hangs indefinitely with redirected output  
- Works fine without output redirection
- Even 5 string concatenations trigger the hang
- Affects Make-based test runner and CI pipelines

**Problematic Patterns** (in contexts with output redirection):
```haxe
// ❌ CAUSES HANG when output is redirected
return 'line1\n' +
       'line2\n' +
       'line3\n';

// ❌ StringBuf ALSO CAUSES HANG  
var sb = new StringBuf();
sb.add("line1\n");
sb.add("line2\n");
```

**Safe Solutions**:
```haxe
// ✅ BEST: String interpolation (clean and safe)
return '
defmodule ${name} do
  use Ecto.Migration
  def change do
    # ${comment}
  end
end';

// ✅ ALSO SAFE: Array join pattern
var lines = [
    'defmodule ${name} do',
    '  use Ecto.Migration',
    'end'
];
return lines.join('\n');
```

### Single Responsibility Principle

Each file should have **one clear reason to change**:

✅ **GOOD Examples**:
- `LoopCompiler.hx` - Only handles loop compilation and optimization
- `PatternDetector.hx` - Only detects AST patterns  
- `CompilerUtilities.hx` - Only provides shared utility functions

❌ **BAD Examples**:
- `ElixirCompiler.hx` (current) - Handles loops, expressions, patterns, utilities, types, etc.

### Refactoring Standards

**Every extraction must include**:
- Complete HaxeDoc for all functions
- **⚠️ MANDATORY WHY/WHAT/HOW documentation** - Every new class, entity, or code must comprehensively justify its existence with WHY (problem being solved), WHAT (responsibilities and capabilities), HOW (implementation approach)
- XRay debug traces for compilation functions
- Single responsibility focus
- Test coverage to prevent regressions

**Validation**: `npm test && cd examples/todo-app && npx haxe build-server.hxml && mix compile`

## Framework-Agnostic Design Pattern ✨ **ARCHITECTURAL PRINCIPLE**

**CRITICAL RULE**: The compiler generates plain Elixir by default. Framework conventions are applied via annotations, not hardcoded assumptions.

### Design Philosophy
```haxe
// ✅ CORRECT: Framework conventions via annotations
@:native("AppNameWeb.TodoLive")  // Explicit Phoenix convention
@:liveview
class TodoLive {}

// ❌ WRONG: Hardcoded framework detection in compiler
if (isPhoenixProject()) {
    moduleName = appName + "Web." + className;  // Compiler assumption
}
```

## 🎯 Elixir Language Semantics - Compiler Must Understand

**CRITICAL KNOWLEDGE**: A robust Haxe→Elixir compiler must deeply understand Elixir's language semantics, reserved words, scoping rules, and idioms.

### Complete List of Elixir Reserved Keywords
The compiler MUST avoid using these as variable/function names:

**Core Reserved Words**:
- `true`, `false`, `nil` - Boolean/null atoms
- `and`, `or`, `not`, `in`, `when` - Operators
- `fn` - Anonymous function definition
- `do`, `end`, `catch`, `rescue`, `after`, `else` - Block delimiters
- `__MODULE__`, `__FILE__`, `__DIR__`, `__ENV__`, `__CALLER__` - Special forms

### Variable Scoping & Rebinding Rules

**Immutability vs Rebinding**:
- **Data is immutable**: Lists, maps, structs never change
- **Variables can rebind**: Variables can point to new data
- **NOT mutation**: `x = x + 1` creates new binding, doesn't mutate

**Scoping Principles**:
```elixir
# Outer scope
x = 1

# Inner scope (anonymous function)
result = Enum.map([1, 2, 3], fn item ->
  x = 2  # Creates NEW local x, doesn't affect outer x
  item * x
end)

# x is still 1 here
```

**Pin Operator (^)**:
```elixir
x = 1
^x = 2  # MatchError - tries to match 2 against existing value 1
x = 2   # Rebinding - x now points to 2
```

### Variable Shadowing Hazards

**The compiler must handle**:
1. **Nested scopes**: Inner variables shadow outer ones
2. **Case/cond clauses**: Each clause has its own scope
3. **Comprehensions**: Variables in generators are local
4. **With expressions**: Each clause can rebind

### Module Naming Conflicts

**Built-in Elixir modules the compiler MUST NOT override**:
- `List`, `Map`, `Enum`, `String`, `Integer`, `Float`
- `Process`, `GenServer`, `Supervisor`, `Agent`
- `File`, `IO`, `Path`, `System`
- `Code`, `Kernel`, `Module`, `Application`

### Elixir Idioms the Compiler Should Generate

**Pattern Matching over Conditionals**:
```elixir
# ✅ Idiomatic
case result do
  {:ok, value} -> process(value)
  {:error, reason} -> handle_error(reason)
end

# ❌ Non-idiomatic
if elem(result, 0) == :ok do
  process(elem(result, 1))
else
  handle_error(elem(result, 1))
end
```

**Pipeline over Nested Calls**:
```elixir
# ✅ Idiomatic
data
|> transform()
|> validate()
|> save()

# ❌ Non-idiomatic
save(validate(transform(data)))
```

### Phoenix-Specific Conventions

**Module Organization**:
- `AppName` - Business logic
- `AppNameWeb` - Web layer
- `AppNameWeb.Router` - Always named Router
- `AppNameWeb.Endpoint` - Always named Endpoint

**File Placement**:
- `lib/app_name/` - Core domain
- `lib/app_name_web/` - Web interface
- `lib/app_name_web/live/` - LiveView modules
- `lib/app_name_web/controllers/` - Controllers

### Phoenix LiveView Patterns (2024 Best Practices)

**Lifecycle Callbacks Order**:
1. `mount/3` - Initial setup (called twice: disconnected then connected)
2. `handle_params/3` - URL/param changes (prefer over mount for assigns)
3. `handle_event/3` - User interactions
4. `handle_info/2` - PubSub messages, async results
5. `render/1` - Generate HTML (or use template)

**Socket & Assigns Rules**:
- **Immutable assigns**: Each render gets fresh copy
- **Assign in callbacks only**: Business logic returns values, callbacks assign
- **Never pass socket to business logic**: Separation of concerns
- **Use assign_async/3**: For non-blocking data loading

**Anti-Patterns to Avoid**:
```elixir
# ❌ BAD: Business logic taking socket
def calculate_total(socket, items) do
  total = Enum.sum(items)
  assign(socket, :total, total)  # Wrong!
end

# ✅ GOOD: Business logic returns value
def calculate_total(items) do
  Enum.sum(items)
end

# In LiveView callback:
socket = assign(socket, :total, calculate_total(items))
```

**Stream vs Regular Assigns**:
- **Regular assigns**: Entire collection in memory
- **Streams**: Efficient for large collections, freed after render
- **Temporary assigns**: Auto-reset after render

## 🔄 Compiler-Example Development Feedback Loop

**CRITICAL UNDERSTANDING**: Working on examples (todo-app, etc.) is simultaneously **compiler development**. Examples are **living compiler tests** that reveal bugs and drive improvements.

### Development Rules
- ✅ **Example fails to compile**: This is compiler feedback, not user error
- ✅ **Generated .ex files invalid**: Fix the transpiler, don't patch files
- ❌ **Never manually edit generated files**: They get overwritten on recompilation
- ❌ **Don't work around compiler bugs**: Fix the root cause in transpiler source
- ❌ **NEVER keep dead code 'just in case'**: Only keep code that's actually used
- ❌ **No unnecessary abstraction layers**: Don't add indirection without value (e.g., routers that don't route)

### Architectural Component Naming Rule
**CRITICAL**: Name components by what they actually DO, not what you wish they did:
- A "Router" must make routing decisions between multiple destinations
- A "Compiler" must compile/transform code
- A "Manager" must manage state or lifecycle
- Pure delegation/passthrough is NOT routing, managing, or controlling
- If you can't describe the component's value in one sentence, it shouldn't exist

## 📍 Agent Navigation Guide

### When Writing or Fixing Tests
→ **[docs/03-compiler-development/testing-infrastructure.md](docs/03-compiler-development/testing-infrastructure.md)** - Critical testing rules and snapshot testing

### When Implementing New Features  
→ **[docs/07-patterns/](docs/07-patterns/)** - Code patterns and examples
→ **[docs/03-compiler-development/best-practices.md](docs/03-compiler-development/best-practices.md)** - Development practices

### When Working on Examples (todo-app, etc.)
→ **Remember**: Examples are **compiler testing grounds** - failures reveal compiler bugs
→ **[docs/01-getting-started/development-workflow.md](docs/01-getting-started/development-workflow.md)** - Complete workflow guide

### When Dealing with Framework Integration Issues
→ **[docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)** - Comprehensive troubleshooting
→ **Framework Integration**: Generated code MUST follow target framework conventions exactly

## Haxe-First Philosophy ⚠️ FUNDAMENTAL RULE

**Write EVERYTHING in Haxe unless technically impossible. Type safety everywhere, not just business logic.**

### Developer Choice and Flexibility
- **Pure Haxe preferred**: Write implementations in Haxe for maximum control
- **Typed externs welcome**: Leverage the rich Elixir ecosystem with full type safety
- **Dual-API standard library**: Use cross-platform OR platform-specific methods as needed
- **NO DYNAMIC OR ANY**: Never use Dynamic or Any in any Haxe code
- **ABSTRACT AWAY DYNAMIC AT BOUNDARIES**: When interfacing with dynamic systems (like Ecto), use macros or builder patterns to provide fully typed APIs. Users should NEVER see Dynamic

**The goal**: Maximum developer flexibility with complete type safety.

## 📚 Layered API Architecture ⚡ **MAXIMUM FLEXIBILITY DESIGN**

**FUNDAMENTAL PRINCIPLE**: Create faithful 1:1 Elixir/Phoenix externs first, then build Haxe stdlib abstractions on top. This gives users maximum flexibility - they can choose the Elixir-idiomatic API or the cross-platform Haxe API based on their needs.

### Architecture Layers
```
┌─────────────────────────────────────┐
│   Haxe Standard Library (Layer 3)   │  ← Cross-platform abstractions
│  Lambda, StringBuf, Map, Array, etc. │     (uses Layer 2)
└─────────────────────────────────────┘
                  ↓ uses
┌─────────────────────────────────────┐
│    Elixir Externs (Layer 2)         │  ← 1:1 Elixir API mappings
│  Enum, String, List, Map, etc.       │     (faithful to Elixir)
└─────────────────────────────────────┘
                  ↓ compiles to
┌─────────────────────────────────────┐
│    Elixir Runtime (Layer 1)         │  ← Native Elixir modules
│  Actual BEAM modules and functions   │
└─────────────────────────────────────┘
```

### ⚠️ CRITICAL: Both Layers Must Generate Idiomatic Elixir

**KEY PRINCIPLE**: Whether using Layer 2 (Elixir externs) or Layer 3 (Haxe stdlib), the generated Elixir code should be nearly identical and idiomatic.

```haxe
// Using Layer 2 (Elixir Externs):
import elixir.Enum;
var doubled = Enum.map(numbers, x -> x * 2);

// Using Layer 3 (Haxe Standard Library):  
var doubled = numbers.map(x -> x * 2);

// BOTH generate the SAME idiomatic Elixir:
doubled = Enum.map(numbers, fn x -> x * 2 end)
```

### Implementation Rules

**Layer 2 (Elixir Externs) - `std/elixir/`**:
- ✅ **1:1 mapping** to Elixir modules and functions
- ✅ **@:native annotations** for exact Elixir names
- ✅ **camelCase methods** with proper type signatures
- ❌ **NO business logic** - pure API definitions only
- ❌ **NO helper methods** - keep externs faithful

**Layer 3 (Haxe Stdlib) - `std/`**:
- ✅ **Built on Layer 2** - use elixir.Enum, not __elixir__()
- ✅ **Cross-platform contract** - same API across targets
- ✅ **Immutability warnings** for mutable operations
- ✅ **May use __elixir__()** for critical optimizations only
- ❌ **NO iterator objects** - transform to Enum operations

### Mutable Operations Must Warn

When Haxe patterns assume mutability:
```haxe
array.push(item);  // Mutable operation

// Compiler should warn:
// Warning: Array.push() creates a new list in Elixir (immutable).
// Consider using elixir.List.append() for explicit immutable semantics.

// Generates rebinding, not mutation:
array = array ++ [item]
```

### Benefits of This Architecture
- **User Choice**: Developers can choose Elixir-idiomatic APIs OR Haxe cross-platform APIs
- **Better Code Generation**: Direct extern usage generates more idiomatic Elixir
- **Maintainability**: Clear separation between Elixir bindings and Haxe abstractions
- **Learning Curve**: Elixir developers can use familiar APIs while gaining type safety
- **NO Iterator Objects**: Elixir uses Enum, not iterators - compiler handles transformation

**See**: [`docs/05-architecture/LAYERED_API_ARCHITECTURE.md`](docs/05-architecture/LAYERED_API_ARCHITECTURE.md) - Complete layered architecture PRD and implementation guide

## Standard Library Philosophy ⚡ **PRAGMATIC NATIVE IMPLEMENTATION**

### ⚠️ CRITICAL: Prefer Externs Over Wrappers for Elixir Standard Library

**FUNDAMENTAL RULE: If it exists in Elixir's standard library, use an extern, NOT a wrapper class.**

**The Principle**:
- **Elixir stdlib modules** → Create externs in `std/elixir/` (e.g., `elixir.List`, `elixir.Map`, `elixir.File`)
- **NO wrapper classes** → Don't create `std/List.hx` when `elixir.List` extern suffices
- **Arrays ARE lists** → `Array<T>` already compiles to Elixir lists, no need for List class
- **Direct usage** → Users can import and use Elixir modules directly with type safety

**Examples**:
```haxe
// ✅ CORRECT: Use Array (compiles to Elixir list) + extern functions
import elixir.List;
var items: Array<Int> = [1, 2, 3];  // This IS an Elixir list
var first = List.first(items);      // Direct extern usage

// ❌ WRONG: Creating unnecessary wrapper classes
class List<T> {  // Don't do this if elixir.List extern exists!
    private var internal: Array<T>;
    // ... reimplementing what Elixir already has
}
```

**When Wrappers ARE Needed**:
1. **Cross-platform abstractions** - Code that must work on multiple targets (StringBuf, etc.)
2. **Missing in Elixir** - Functionality that doesn't exist natively (specialized data structures)
3. **Complex transformations** - When Haxe semantics differ significantly from Elixir

**Benefits of Extern-First Approach**:
- **Smaller codebase** - No redundant wrapper code
- **Idiomatic output** - Direct module calls, not wrapper indirection
- **Better performance** - No extra abstraction layers
- **Clear mental model** - Elixir developers know exactly what they're getting

### The `__elixir__()` Function - Framework/Stdlib Only, NOT for Client Code

**⚠️ CRITICAL PRINCIPLE: `__elixir__()` is for framework and standard library implementation ONLY.**

**Client/Application Code Rules**:
- ❌ **NEVER use `__elixir__()`** in application code - it's a sign of missing abstractions
- ❌ **Exception: Emergency hotfixes only** - Must be justified, documented with TODO, and scheduled for proper fix
- ✅ **Always use framework abstractions** - If you need `__elixir__()`, we need better framework APIs
- ✅ **Report missing abstractions** - File an issue when framework APIs are insufficient

**Framework/Stdlib Rules**:
- ✅ **Use `__elixir__()` strategically** for efficient native implementations
- ✅ **Wrap in type-safe APIs** - Never expose `__elixir__()` to users
- ✅ **Provide complete abstractions** - Users should never need escape hatches

**IMPORTANT CLARIFICATION**: `__elixir__()` IS available and can be strategically used for standard library implementations.

**⚠️ CRITICAL: Correct Placeholder Syntax Required**

The `__elixir__()` function requires specific placeholder syntax to work correctly:

```haxe
// ❌ WRONG: $variable syntax causes Haxe string interpolation at compile-time
untyped __elixir__('Phoenix.Controller.json($conn, $data)');  // FAILS!
// This becomes string concatenation: "" + conn + ", " + data + ")"
// Result: Not a constant string, Reflaxe cannot process it

// ✅ CORRECT: {N} placeholder syntax for variable substitution
untyped __elixir__('Phoenix.Controller.json({0}, {1})', conn, data);  // WORKS!
// Variables are passed as parameters and substituted at placeholder positions
```

**WHY THIS MATTERS**: 
- `$variable` triggers Haxe's compile-time string interpolation
- The result is no longer a constant string literal
- Reflaxe's TargetCodeInjection requires the first parameter to be a constant
- `{N}` placeholders preserve the constant string while allowing substitution

**RULES FOR `__elixir__()` USAGE**:
1. First parameter MUST be a constant string literal (no concatenation)
2. Use `{0}`, `{1}`, `{2}`... for variable substitution
3. Variables are passed as additional parameters
4. Variables are compiled to Elixir and substituted at placeholder positions
5. Keyword lists and atoms should be written directly in the string

### Pragmatic Stdlib Implementation Strategy

**Philosophy**: Use the right tool for the job - combine Haxe's type safety with Elixir's native efficiency.

## 📚 Standard Library Testing & Idiomatic Generation

### Comprehensive Testing Strategy for Stdlib

**FUNDAMENTAL PRINCIPLE**: Every standard library module MUST include:
1. **Usage examples** showing Haxe API usage
2. **Expected Elixir output** demonstrating idiomatic generation
3. **Snapshot tests** validating compilation output
4. **Integration tests** ensuring runtime behavior

### Standard Library Module Documentation Pattern

Every stdlib module should follow this documentation pattern:

```haxe
/**
 * Module description and purpose
 * 
 * ## Usage Example (Haxe)
 * ```haxe
 * var example = new MyClass();
 * example.doSomething();
 * ```
 * 
 * ## Generated Idiomatic Elixir
 * ```elixir
 * # Shows exact Elixir code that will be generated
 * example = MyModule.new()
 * MyModule.do_something(example)
 * ```
 * 
 * ## Layered Architecture
 * - Layer 2 (Elixir Extern): Direct 1:1 mapping to Elixir APIs
 * - Layer 3 (Haxe Stdlib): Cross-platform abstractions using Layer 2
 * 
 * ## Performance Characteristics
 * - Time complexity for operations
 * - Memory usage patterns
 * - BEAM-specific optimizations
 */
```

### Test Infrastructure Organization

```
test/tests/
├── StdlibStringBuf/        # StringBuf tests
│   └── Main.hx             # Test cases with expected output
├── StdlibLambda/           # Lambda functional tests  
│   └── Main.hx             # Validates Enum extern usage
├── StdlibEnum/             # Elixir Enum extern tests
│   └── Main.hx             # 1:1 mapping validation
└── StdlibCommon/           # Shared test utilities
    └── TestHelper.hx       # DRY test infrastructure
```

### Example: StringBuf Idiomatic Generation

**Haxe Input:**
```haxe
var buf = new StringBuf();
buf.add("Hello");
buf.add(" World");
var result = buf.toString();
```

**Expected Elixir Output:**
```elixir
iolist = []
iolist = iolist ++ ["Hello"]
iolist = iolist ++ [" World"]
result = IO.iodata_to_binary(iolist)
```

### Example: Lambda with Enum Extern

**Haxe Input:**
```haxe
var doubled = Lambda.map([1, 2, 3], x -> x * 2);
var sum = Lambda.fold(doubled, (x, acc) -> x + acc, 0);
```

**Expected Elixir Output:**
```elixir
doubled = Enum.map([1, 2, 3], fn x -> x * 2 end)
sum = Enum.reduce(doubled, 0, fn x, acc -> x + acc end)
```

1. **Type-Safe Interface**: Haxe provides the typed API surface
2. **Native Implementation**: Use `__elixir__()` or `@:native` for efficient Elixir implementation  
3. **Best of Both Worlds**: Cross-platform API with idiomatic target code

#### Example: StringBuf Implementation (CORRECTED)
```haxe
// Type-safe Haxe interface with CORRECT placeholder syntax
class StringBuf {
    var iolist: Dynamic;
    
    public function new() {
        // Use native Elixir IO lists for efficiency
        iolist = untyped __elixir__('[]');
    }
    
    public function add(x: String): Void {
        // Native Elixir list concatenation with {N} placeholders
        iolist = untyped __elixir__('{0} ++ [{1}]', iolist, x);
    }
    
    public function toString(): String {
        // Native Elixir binary conversion with {N} placeholder
        return untyped __elixir__('IO.iodata_to_binary({0})', iolist);
    }
}
```

### Implementation Priority

1. **Prefer Native Efficiency**: Use `__elixir__()` for performance-critical stdlib
2. **Maintain Type Safety**: Wrap all native code in typed Haxe interfaces
3. **Support All Haxe Code**: Ensure Turing completeness and full Haxe compatibility
4. **Idiomatic Output**: Generated code should leverage target platform strengths

### ⚠️ CRITICAL: Override Haxe Built-in Classes When Necessary

**RULE**: When Haxe's built-in standard library classes generate problematic code for Elixir, provide our own implementation in `std/`.

**Examples**:
- **Array**: We provide `std/Array.hx` optimized for Elixir lists
- **Bytes**: We provide `std/haxe/io/Bytes.hx` to avoid nested assignment patterns
- **StringBuf**: Custom implementation using Elixir IO lists

**Why**: Haxe's built-in implementations often use inline functions and patterns that don't translate well to Elixir's functional paradigm. Our versions generate clean, idiomatic Elixir code.

**The Goal**: Complete Haxe standard library support with efficient, idiomatic Elixir implementations.

**See**: [`docs/05-architecture/`](docs/05-architecture/) - Complete implementation guidelines

## Quality Standards
- Zero compilation warnings, Reflaxe snapshot testing approach
- **Date Rule**: Always run `date` command before writing timestamps
- **CRITICAL: Idiomatic Elixir Code Generation** - Generate high-quality, functional Elixir code
- **Testing Protocol**: ALWAYS run `npm test` after compiler changes
- **Naming Convention**: ALWAYS use camelCase in Haxe code, compiler handles snake_case conversion

## Mandatory Testing Protocol ⚠️ CRITICAL

**EVERY compiler change MUST be validated through the complete testing pipeline.**

### After ANY Compiler Change

#### Quick Iteration Testing (NEW - Recommended)
```bash
# Test only affected areas during development
npm run test:changed         # Run tests affected by git changes
npm run test:failed          # Re-run only failed tests
npm run test:core            # Test core features if working on basics
npm run test:stdlib          # Test stdlib if working on standard library
```

#### Full Validation (Before Commit)
1. **Run Full Test Suite**: `npm test` - ALL tests must pass
2. **Test Todo-App Integration**:
   ```bash
   cd examples/todo-app
   npx haxe build-server.hxml
   mix compile --force
   mix phx.server        # Ensure app starts
   ```

**Rule**: If ANY step fails, the compiler change is incomplete. Fix the root cause.

**See**: [docs/03-compiler-development/testing-infrastructure.md](docs/03-compiler-development/testing-infrastructure.md) - Complete testing guide

## ⚠️ CRITICAL: Haxe Naming Convention Rules

**FUNDAMENTAL RULE: All Haxe code MUST use camelCase consistently. The compiler handles snake_case conversion for Elixir output.**

### Naming Convention Standards

#### Haxe Code (Input) - Always camelCase:
- **Variables**: `userId`, `currentUser`, `editingTodo`
- **Functions**: `loadTodos()`, `updateTodoInList()`, `getUserFromSession()`
- **Fields**: `showForm`, `searchQuery`, `selectedTags`
- **Type fields**: In typedefs and classes, use camelCase for all fields

#### Generated Elixir (Output) - Compiler converts to snake_case:
- `userId` → `user_id`
- `loadTodos()` → `load_todos()`
- `showForm` → `show_form`

#### External Library APIs (Externs) - Use actual API names:
- **Phoenix/Ecto APIs**: Keep original names like `put_flash`, `assign`, `validate_required`
- **Why**: These are external Elixir libraries with fixed APIs, not code we generate
- **Rationale**: Adding camelCase wrappers would complicate the compiler and confuse developers
- **Examples**:
  - `LiveView.put_flash(socket, type, msg)` ✅ (actual Phoenix API)
  - `LiveView.putFlash(...)` ❌ (doesn't exist in Phoenix)
  - `changeset.validateRequired(fields)` ✅ (our Changeset abstract uses camelCase)
  - `Changeset.validate_required(...)` ❌ (we're not using the Ecto extern)

### Examples

```haxe
// ✅ CORRECT - Consistent camelCase in Haxe code, snake_case for extern APIs
typedef TodoLiveAssigns = {
    var currentUser: User;      // camelCase for our fields
    var editingTodo: Todo;      // camelCase for our fields
    var showForm: Bool;         // camelCase for our fields
}

// Our function uses camelCase
function updateUserStatus(userId: Int, newStatus: String) {
    var user = Repo.get(User, userId);
    
    // Our Changeset abstract uses camelCase methods
    var changeset = new Changeset(user, {status: newStatus});
    changeset = changeset.validateRequired(["status"]);  // Our abstract: camelCase
    
    // Phoenix extern API: snake_case
    socket = LiveView.put_flash(socket, "info", "Status updated");
    socket = LiveView.assign(socket, {currentUser: user});  // Our field: camelCase
    
    return socket;
}

function loadAndAssignTodos(socket: Socket): Socket {
    var userId = socket.assigns.currentUser.id;
    var todos = loadTodos(userId);
    return LiveView.assign_multiple(socket, assigns);  // Phoenix API keeps snake_case
}

// ❌ WRONG - Mixing conventions
typedef TodoLiveAssigns = {
    var current_user: User;     // Wrong: snake_case in Haxe
    var editing_todo: Todo;     // Wrong: snake_case in Haxe
}
```

### Special Cases

1. **Template Variables**: In HXX templates, use camelCase:
   - `<%= @currentUser.name %>` NOT `<%= @current_user.name %>`
   - The compiler will handle conversion for Phoenix templates

2. **Database Fields**: When interfacing with Ecto schemas, the compiler handles mapping:
   - Haxe: `user.firstName`
   - Database column: `first_name`

3. **Configuration Keys**: Keep original format when required by frameworks

### Why This Matters

- **Consistency**: One naming convention throughout Haxe codebase
- **IDE Support**: Better autocomplete and refactoring with consistent names
- **Clear Separation**: Obvious distinction between our code (camelCase) and external APIs (snake_case)
- **Compiler Responsibility**: Let the compiler handle cross-language conventions

## ⚠️ CRITICAL: Naming Convention Rules

**FUNDAMENTAL RULE: Haxe code uses camelCase, Generated Elixir uses snake_case. The compiler handles the conversion.**

### When to Use camelCase (In Haxe Source Files)
- ✅ **ALL variable names**: `var updatedSocket`, NOT `var updated_socket`
- ✅ **ALL function names**: `function loadAndAssignTodos()`, NOT `function load_and_assign_todos()`
- ✅ **ALL method names**: `socket.merge()`, NOT `socket.merge_data()`
- ✅ **ALL field names in typedefs**: `var dueDate: String`, NOT `var due_date: String`
- ✅ **ALL parameter names**: `function update(userId: Int)`, NOT `function update(user_id: Int)`
- ✅ **Case pattern variables**: `case Ok(updatedTodo):`, NOT `case Ok(updated_todo):`

### When snake_case Appears (And How to Handle It)
- **Phoenix event names in templates**: Keep as strings: `phx-click="delete_todo"` (these are Phoenix conventions)
- **Database field names**: Use `@:native` annotation: `@:native("user_id") var userId: Int`
- **Generated Elixir output**: The compiler automatically converts camelCase to snake_case

### Examples of CORRECT Naming
```haxe
// ✅ CORRECT Haxe code
class TodoLive {
    static function handleEvent(eventName: String, eventParams: Dynamic, socket: Socket): Socket {
        var updatedSocket = socket.assign("currentUser", user);
        var resultSocket = updateTodoInList(updatedTodo, socket);
        return resultSocket;
    }
}

// The compiler generates this Elixir:
defmodule TodoLive do
    def handle_event(event_name, event_params, socket) do
        updated_socket = Phoenix.LiveView.assign(socket, :current_user, user)
        result_socket = update_todo_in_list(updated_todo, socket)
        result_socket
    end
end
```

### Examples of INCORRECT Naming
```haxe
// ❌ WRONG: Using snake_case in Haxe
var updated_socket = socket.merge(assigns);  // WRONG!
var user_id = params.user_id;               // WRONG!
function load_and_assign_todos() {}         // WRONG!
case Ok(updated_todo):                      // WRONG!
```

### Key Principle
**Write Haxe idiomatically (camelCase) and let the compiler handle the Elixir conversion (snake_case).**

## ⚠️ CRITICAL: Extern Classes and snake_case Field Names

**FUNDAMENTAL RULE: Extern classes mapping to Elixir modules should use camelCase in Haxe with @:native annotations for snake_case Elixir names.**

### The Problem with snake_case in Externs
The Haxe eval target (used during macro expansion) has issues resolving snake_case field names on extern classes. This causes compilation errors like:
```
Field index for clear_flash not found on prototype Phoenix.LiveView
```

### The Solution: camelCase + @:native
```haxe
// ✅ CORRECT: camelCase in Haxe, snake_case in Elixir via @:native
@:native("Phoenix.LiveView")
extern class LiveView {
    @:native("clear_flash")
    static function clearFlash<T>(socket: Socket<T>): Socket<T>;
    
    @:native("put_flash")
    static function putFlash<T>(socket: Socket<T>, type: FlashType, message: String): Socket<T>;
    
    @:native("assign_new")
    static function assignNew<T>(socket: Socket<T>, key: String, value: Dynamic): Socket<T>;
}

// ❌ WRONG: Direct snake_case names cause eval target errors
extern class LiveView {
    static function clear_flash<T>(socket: Socket<T>): Socket<T>;  // COMPILATION ERROR!
    static function put_flash<T>(socket: Socket<T>, type: FlashType, message: String): Socket<T>;
}
```

### Complete Extern Pattern
```haxe
/**
 * Type-safe Phoenix LiveView extern
 * 
 * Uses camelCase method names for Haxe compatibility
 * Maps to snake_case via @:native for Elixir
 */
@:native("Phoenix.LiveView")
extern class LiveView {
    // Core socket operations
    @:native("assign")
    static function assign<T>(socket: Socket<T>, key: String, value: Dynamic): Socket<T>;
    
    @:native("assign_new")
    static function assignNew<T>(socket: Socket<T>, key: String, fn: () -> Dynamic): Socket<T>;
    
    @:native("clear_flash")
    static function clearFlash<T>(socket: Socket<T>): Socket<T>;
    
    @:native("put_flash")
    static function putFlash<T>(socket: Socket<T>, type: FlashType, message: String): Socket<T>;
    
    // Event handling
    @:native("push_event")
    static function pushEvent<T>(socket: Socket<T>, event: String, payload: Dynamic): Socket<T>;
    
    @:native("push_patch")
    static function pushPatch<T>(socket: Socket<T>, to: String, ?opts: Dynamic): Socket<T>;
    
    @:native("push_redirect")
    static function pushRedirect<T>(socket: Socket<T>, to: String, ?opts: Dynamic): Socket<T>;
}
```

### Usage in Application Code
```haxe
// Application code uses camelCase naturally
var socket = LiveView.clearFlash(socket);  // ✅ camelCase in Haxe
socket = LiveView.putFlash(socket, Info, "Success!");  // ✅ camelCase in Haxe

// Generated Elixir uses snake_case automatically
Phoenix.LiveView.clear_flash(socket)  // Generated snake_case
Phoenix.LiveView.put_flash(socket, :info, "Success!")  // Generated snake_case
```

### Benefits of This Pattern
- **Haxe Compatibility**: Works with Haxe's eval target during macro expansion
- **Natural Haxe Code**: Developers write idiomatic camelCase
- **Correct Elixir Output**: Generated code uses proper snake_case
- **Type Safety**: Full compile-time type checking
- **IDE Support**: IntelliSense works with camelCase names

## Development Principles

### ⚠️ CRITICAL: Apply DRY Principles to Avoid Whack-a-Mole Fixes
**FUNDAMENTAL RULE: When fixing pattern detection or similar logic, create reusable helper functions instead of repeating the same fix in multiple places.**

**Why DRY Matters in Compiler Development:**
- **Consistency**: One helper function ensures all places behave identically
- **Maintainability**: Fix once, works everywhere - no whack-a-mole debugging
- **Correctness**: No risk of missing a spot or having inconsistent implementations
- **Evolution**: When requirements change (like ENil → EAtom("nil")), update one place

**Examples of Good DRY Patterns:**
```haxe
// ✅ GOOD: Helper function for common pattern
inline function isNilValue(ast: ElixirAST): Bool {
    return switch(ast.def) {
        case EAtom(a): a == "nil";
        case ENil: true; // Legacy support
        default: false;
    };
}

// Use everywhere consistently
if (isNilValue(value)) { /* handle nil */ }

// ❌ BAD: Repeating the same pattern check
switch(value.def) {
    case EAtom(a) if (a == "nil"): // Repeated 7 times!
    // ...
}
```

**When to Create Helper Functions:**
- Pattern detection used in 2+ places
- Complex conditions that could change
- AST node type checking
- String transformations or validations
- Any logic that represents a concept (like "is this nil?")

### ⚠️ CRITICAL: Consult Codex Before New Features
**FUNDAMENTAL RULE: Before implementing any new feature, consult with Codex and reflect on its architectural guidance.**

**Why Codex Consultation Matters:**
- **Architecture expertise**: Codex has deep knowledge about software architecture patterns
- **Avoid pitfalls**: Learn from established patterns and avoid common mistakes
- **Better design**: Get architectural guidance before writing code
- **Reflective development**: Think through the approach with expert guidance

**How to Consult Codex:**
1. **Describe the feature** you're about to implement
2. **Ask for architectural guidance** about the best approach
3. **Reflect on the answer** and consider alternatives
4. **Implement with confidence** using the architectural insights

**Example Consultation:**
```
"I'm about to implement Schema emission enhancements for Ecto. 
What architectural patterns should I consider for:
- Preserving changeset functions through compilation
- Handling field type mappings
- Managing associations between schemas"
```

### ⚠️ CRITICAL: Abstract Away Dynamic at System Boundaries
**FUNDAMENTAL RULE: When interfacing with dynamic Elixir systems, ALWAYS provide a fully typed Haxe API. Users should NEVER interact with Dynamic directly.**

**The Problem**: Some Elixir systems (like Ecto changesets) use heterogeneous data structures that would require Dynamic in Haxe.

**The Solution**: Use one of these patterns to provide type safety:

1. **Macro-Generated Casting** (BEST):
   ```haxe
   // User writes:
   typedef TodoParams = { ?title: String, ?completed: Bool }
   var changeset = Todo.changeset(todo, params);  // Fully typed!
   
   // Macro generates the casting code at compile time
   ```

2. **Builder Pattern with Hidden Dynamic**:
   ```haxe
   // Internal: May use Map<String, Dynamic>
   // External: Fully typed fluent API
   return cast(todo, params)
       .validateRequired(["title"])
       .validateLength("title", {min: 3});
   ```

3. **Abstract Types Over Dynamic**:
   ```haxe
   // Wrap Dynamic in an abstract with typed methods
   abstract ChangesetData(Dynamic) {
       public function getField<T>(name: String): T { ... }
       public function setField<T>(name: String, value: T): Void { ... }
   }
   ```

**Why This Matters**:
- Type safety is the entire point of using Haxe
- Dynamic defeats IntelliSense and compile-time checking
- Users shouldn't need to know about Elixir's internal representations
- The compiler/stdlib should handle the complexity, not the user

**Examples in Practice**:
- ✅ **Ecto.Changeset**: Typed params in, typed changeset out
- ✅ **Delete operations**: Use `Changeset<T, {}>` for no-params cases, not Dynamic
- ✅ **Phoenix.Socket.assigns**: Typed assigns structure, not Dynamic
- ✅ **Plug.Conn**: Typed request/response, not Dynamic maps
- ❌ **NEVER**: `function process(data: Dynamic): Dynamic`
- ❌ **NEVER**: Use Dynamic when a proper type exists (even `{}` for empty)

### ⚠️ CRITICAL: Detect Patterns by Structure, Not by Name
**FUNDAMENTAL RULE: Never detect patterns by checking for specific hardcoded names. Detect by structural patterns or usage context.**

**What counts as name-based detection (WRONG):**
- ❌ **Hardcoded component lists** like `["PubSub", "Endpoint", "Telemetry", "Repo"]`
- ❌ **String matching** like `if (name == "SupervisorStrategy")`
- ❌ **Suffix checking** like `name.endsWith("Server")`
- ❌ **Type name lists** that need updating when new types are added

**The correct approach:**
- ✅ **Structural detection**: Check the AST structure (e.g., "tuple with atom and config")
- ✅ **Usage context**: Where/how the value is used determines its treatment
- ✅ **Metadata/annotations**: Use explicit markers like `@:childSpec` 
- ✅ **Type system**: Let the type itself define how it compiles

**Why this matters**: Hardcoded name lists create maintenance burden and break when users define their own types with similar patterns.

### ⚠️ CRITICAL: Apply Systematic Naming Conventions, Not Ad-Hoc Fixes
**FUNDAMENTAL RULE: When converting between Haxe and Elixir naming conventions, apply consistent transformations systematically.**

**General Principles:**
- **Haxe identifiers → Elixir atoms**: Always apply snake_case transformation
- **CamelCase → snake_case**: Apply consistently for all atom generation
- **No special cases**: Don't check for specific enum names or types
- **Idiomatic output**: Generated Elixir should follow Elixir conventions naturally

**Example of the right approach:**
```haxe
// ✅ CORRECT: General transformation rule
static function toElixirAtomName(name: String): String {
    // Convert ANY CamelCase to snake_case
    return camelToSnake(name);
}

// ❌ WRONG: Ad-hoc special cases
if (enumTypeName == "SupervisorStrategy") {
    atomName = toSnakeCase(atomName);  // Only for specific types
}
```

**Why this matters**: Consistent naming transformations ensure all generated code looks idiomatic, not just specific cases we've thought of.

### ⚠️ CRITICAL: Trust Your Own Compiler's Decisions
**FUNDAMENTAL RULE: When one compiler phase makes a decision, other phases must trust it completely.**

When FunctionCompiler determines a parameter name mapping, VariableCompiler must use it exactly as-is:
- **No filtering** based on underscore presence
- **No second-guessing** whether a name "looks right"
- **No validation** of the mapping - trust it completely
- **Clear authority boundaries** - each phase owns its decisions

**Example**: If FunctionCompiler maps "index" → "_index" (unused parameter), VariableCompiler must use "_index". If it maps "appName" → "app_name" (used parameter), use "app_name".

### ⚠️ CRITICAL: Todo-App First Testing Strategy
**FUNDAMENTAL RULE: Use the todo-app as the primary testing feedback loop. Once it works, update all snapshot tests to match.**

Testing workflow for compiler changes:
1. **Make compiler changes** based on architectural principles
2. **Test with todo-app FIRST** - It's the real-world integration test
3. **Get todo-app working** - This validates the compiler actually works
4. **THEN update snapshot tests** - Create a snapshot of the "good state"
5. **Don't let failing snapshot tests block progress** - They might have wrong intended outputs

**Why this works**:
- **Real-world validation** - Todo-app exercises actual Phoenix patterns
- **Practical focus** - If todo-app works, the compiler works for real apps
- **Snapshot tests can be wrong** - They often contain bugs from previous compiler states
- **Forward progress** - Don't get stuck fixing tests that expect wrong behavior

### ⚠️ CRITICAL: Validate Test Intended Outputs
**FUNDAMENTAL RULE: Before accepting test failures, verify the intended output itself is correct.**

When tests fail after compiler fixes:
1. **Check consistency** - If a variable is declared as `i`, it should be referenced as `i`, not `_i`
2. **Update intended outputs** when they contain bugs from previous compiler behavior
3. **Intended outputs are not sacred** - they can be wrong and perpetuate bugs
4. **This ensures tests validate correct behavior**, not historical bugs

### ⚠️ CRITICAL: Create Focused Regression Tests for Every Bug Fix
**FUNDAMENTAL RULE: Every bug fix MUST have a dedicated regression test to prevent reoccurrence.**

When fixing a bug:
1. **Create a focused test** in `test/tests/` that reproduces the exact bug scenario
2. **Name it descriptively** (e.g., `underscore_prefix_consistency`, `orphaned_enum_parameters`)
3. **Document the bug** in the test file's header comment with:
   - What the bug was
   - Why it happened
   - What the fix does
   - Link to relevant commits/issues
4. **Generate intended output** after the fix is verified
5. **Add to CI** to ensure the bug never returns

**Example**: The `underscore_prefix_consistency` test ensures variables with underscore prefixes maintain consistency throughout generated code - preventing the duplicate instance bug where VariableCompiler's state wasn't shared.

**Benefits**:
- **Prevents regressions** - Bugs stay fixed forever
- **Documents issues** - Future developers understand what went wrong
- **Fast validation** - Run specific test to verify fix still works
- **Confidence in refactoring** - Know immediately if changes break fixes

### ⚠️ CRITICAL: Always Check Recent Work Before Starting
**FUNDAMENTAL RULE: Check git history and recent commits to understand what's been done and avoid repeating work.**
- Run `git log --oneline -20` to see recent commits  
- Review related files for recent changes
- Never start debugging without understanding what's already been tried
- Avoid repeating fixes that were already attempted

### ⚠️ CRITICAL: Never Confirm Something Works Without Actual Tests
**FUNDAMENTAL RULE: Don't confirm something is working before being 100% sure by verifying with actual tests.**
- Always run `npm test` after changes
- Test todo-app compilation: `cd examples/todo-app && npx haxe build-server.hxml && mix compile`
- Verify the application runs: `mix phx.server`
- Check for runtime errors, not just compilation success
- Never say "it's fixed" without running the complete test suite

### ⚠️ CRITICAL: Avoid Regressions and Circular Work
**FUNDAMENTAL RULE: Avoid regressions and walking in circles by checking previous work.**
- Check git history before attempting a fix: `git log --oneline -30 --grep="issue_keywords"`
- Review git blame for recently changed code: `git blame path/to/file`
- Look for TODO/FIXME comments in related files
- If something was already tried and reverted, understand WHY before trying again
- Document WHY previous approaches failed to prevent repeating mistakes

### ⚠️ CRITICAL: No Ad-Hoc Fixes - Solve Root Architectural Problems
**FUNDAMENTAL RULE: Never apply band-aid fixes - always solve the root architectural problem.**
- **NO string replacements** like `if (x == "wrong") x = "right"` - find WHY it's wrong
- **NO special case handling** without understanding the general pattern
- **NO symptom patching** - trace back to where the problem originates
- **NO quick fixes** - even if they work, refactor to fix the root cause
- **NO fallback mechanisms** - fix the primary system instead of adding backup logic
- **Always ask**: Why is this happening? What's the root cause?
- **The fix must be general** - it should solve ALL similar cases, not just the one you found
- **Example of wrong approach**: Replacing "g_counter" with "g" in output
- **Example of wrong approach**: Adding fallback to check secondary mapping when primary fails
- **Example of right approach**: Fix the variable mapping system that creates "g_counter" incorrectly
- **Example of right approach**: Register mappings at TVar creation time, not retroactively
- **ZERO TOLERANCE FOR QUICK FIXES**: The user has explicitly stated they don't want quick fixes in this compiler. Always implement the proper architectural solution, even if it takes more time.

### ⚠️ CRITICAL: Debug-First Development - No Assumptions
**FUNDAMENTAL RULE: Always rely on debug data first. If you don't see the data/AST, don't assume things.**
- Add comprehensive debug traces to understand actual behavior
- Use XRay debug patterns to visualize AST transformations
- Never guess what the compiler is doing - instrument and observe
- When debugging issues, add traces FIRST, then analyze

### ⚠️ CRITICAL: No Hardcoded Class/Method Knowledge in Compiler
**FUNDAMENTAL RULE: The compiler should NOT have hardcoded knowledge about specific classes or methods.**
- **NO hardcoded class names** like checking for "Map", "List", "String" to determine behavior
- **NO method-specific logic** like special handling for "put", "delete", "merge"
- **Use metadata/annotations instead** - Let the library define its behavior via @:immutable, @:reassignsVar, etc.
- **Acceptable exceptions**: Critical edge cases or temporary hotfixes, but must be documented with TODO for proper fix
- **The compiler is generic** - It should work for any user-defined types with similar patterns
- **Example of wrong approach**: Hardcoding immutable operations for Map.put, List.delete, etc. in AST transformer
- **Example of right approach**: Methods annotated with @:immutable in Map.hx, compiler reads metadata
- **Benefits**: Extensible system where user types can opt into compiler behaviors

### ⚠️ CRITICAL: No Untyped Usage in Compiler Code
**FUNDAMENTAL RULE: NEVER use `untyped` or `Dynamic` in compiler code unless there's a very good justified reason.**

- All field access must be properly typed
- If fields are public, access them directly instead of using `untyped`
- Document any exceptional cases where `untyped` is absolutely necessary with full justification
- Prefer explicit typing and proper interfaces over dynamic access
- **See**: [`docs/03-compiler-development/TYPE_SAFETY_REQUIREMENTS.md`](docs/03-compiler-development/TYPE_SAFETY_REQUIREMENTS.md) - Complete type safety standards

### ⚠️ CRITICAL: No Direct Elixir Files - Everything Through Haxe
**FUNDAMENTAL RULE: NEVER write .ex files directly. Everything must be generated from Haxe.**

### ⚠️ CRITICAL: Check Haxe Standard Library First
**FUNDAMENTAL RULE: Always check if Haxe stdlib already offers something before implementing it ourselves.**

### ⚠️ CRITICAL: Type Safety and String Avoidance
**FUNDAMENTAL RULE: Avoid strings in compiler code unless absolutely necessary.**

### ⚠️ CRITICAL: No Dead Code - Remove Unused Functions
**FUNDAMENTAL RULE: NEVER keep dead code "just in case" - only keep code that's actually used.**
- **NO keeping unused methods** for "compatibility" or "future use"
- **NO commented-out code blocks** - use git history if you need to recover old code
- **NO delegation methods** that just return null or empty values
- **Delete immediately** when functionality is moved elsewhere
- **If it's not called, delete it** - the codebase must be clean and maintainable
- **Example of wrong approach**: Keeping detectArrayBuildingPattern() that returns null "for compatibility"
- **Example of right approach**: Delete the method entirely when WhileLoopCompiler is removed

### ⚠️ CRITICAL: Clean Up Failed Attempts Immediately
**FUNDAMENTAL RULE: When debugging attempts fail, clean up the code immediately before trying a different approach.**
- **NO accumulating debug code** that didn't solve the problem
- **NO leaving metadata fields** that aren't actually used
- **NO keeping helper functions** created for failed approaches
- **Clean as you go** - don't wait until later to remove failed attempts
- **Each new attempt** should start from a clean slate
- **Example of wrong approach**: Adding metadata fields, debug traces, and helper functions that don't solve the issue
- **Example of right approach**: Remove failed code immediately, understand the real problem, then implement a focused fix

### ⚠️ CRITICAL: No Untyped Usage
**FUNDAMENTAL RULE: NEVER use `untyped` or `Dynamic` unless there's a very good justified reason.**
- All field access must be properly typed
- If fields are public, access them directly instead of using `untyped`
- Document any exceptional cases where `untyped` is absolutely necessary
- Prefer explicit typing and proper interfaces over dynamic access

## 🏗️ Architecture & Refactoring Guidelines

### ⚠️ CRITICAL: Prevent Monolithic Files (LEARNED FROM 10,668-LINE DISASTER)

**FUNDAMENTAL RULE: NO SOURCE FILE MAY EXCEED 2000 LINES. IDEAL: 200-500 LINES.**

#### The Single Responsibility Principle (ENFORCED)
- **One file = One responsibility** - If you can't describe a file's purpose in one sentence, split it
- **Extract early, extract often** - Don't wait until a file is 10k+ lines to refactor
- **Helper pattern** - Use `helpers/` directory for specialized compilers (PatternMatchingCompiler, SchemaCompiler, etc.)

#### File Size Limits (MANDATORY)
```
✅ IDEAL:       200-500 lines   (focused, maintainable)
⚠️  ACCEPTABLE:  500-1000 lines  (consider splitting)
🚨 WARNING:     1000-2000 lines (must have justification)
❌ FORBIDDEN:   >2000 lines     (automatic refactoring required)
```

#### Extraction Guidelines
When a file approaches 1000 lines, IMMEDIATELY:
1. **Identify logical sections** - Look for groups of related functions
2. **Extract helper modules** - Create specialized compilers in `helpers/`
3. **Use delegation pattern** - Main compiler delegates to helpers
4. **Document with WHY/WHAT/HOW** - Every extracted module needs comprehensive docs

#### Example Structure (AFTER AST MIGRATION)
```
src/reflaxe/elixir/
├── ast/
│   ├── ElixirASTBuilder.hx     # TypedExpr → ElixirAST conversion
│   ├── ElixirASTPrinter.hx     # ElixirAST → String generation
│   └── ElixirASTTransformer.hx # AST transformation passes
└── ElixirCompiler.hx            # Main compiler (<2000 lines)
```

#### Red Flags That Demand Immediate Refactoring
- 🚨 **191 switch statements in one file** - Extract pattern matching
- 🚨 **100+ repeated code patterns** - Create utility functions
- 🚨 **Multiple responsibilities** - Split into focused modules
- 🚨 **Deep nesting (>4 levels)** - Extract helper methods
- 🚨 **Long functions (>100 lines)** - Break into smaller functions

### Testing During Refactoring (MANDATORY)
```bash
# After EVERY extraction:
npm test                    # Must pass ALL tests

# After 2-3 extractions:
cd examples/todo-app && npx haxe build-server.hxml && mix compile --force
```

**NEVER** complete a refactoring session without full test validation.

## Known Issues  
- **Array Mutability**: Methods like `reverse()` and `sort()` don't mutate in place (Elixir lists are immutable)
- **Postgrex.TypeManager Race Condition**: When using `mix phx.server`, may encounter "unknown registry: Postgrex.TypeManager" errors due to a race condition in Phoenix server startup. Workaround: Use `iex -S mix` to start in interactive mode, or ensure database is configured correctly. The application works correctly in interactive mode and with `mix run`.

## Recently Resolved Issues ✅
- **Phoenix.Presence Circular Fix Pattern (January 2025)**: MAJOR FIX - Resolved recurring Phoenix.Tracker.track/5 FunctionClauseError that kept resurfacing in git history. Root cause: Phoenix.Tracker expects PID as first argument, not socket. Solution: Enhanced PresenceMacro to generate proper self() injection in all presence methods (trackSimple, updateSimple, untrackSimple, listSimple). Added @:presenceTopic annotation support for type-safe topic configuration. Eliminated all __elixir__ usage from TodoPresence by providing comprehensive macro-generated methods. Git history showed this issue was "fixed" multiple times but kept breaking - now properly resolved at macro level with test coverage.
- **Idiomatic Enum Pattern Matching (September 2025)**: MAJOR IMPROVEMENT - Compiler now generates idiomatic Elixir pattern matching with atoms `{:created, content}` instead of integer index checking `elem(msg, 0)`. This makes generated code much more readable and Elixir-like. Fixed TEnumParameter extraction for ignored parameters to prevent runtime errors. (see [`src/reflaxe/elixir/ast/CLAUDE.md`](src/reflaxe/elixir/ast/CLAUDE.md#tenum-parameter-extraction-bug-fix-september-2025))
- **Major Loop Compilation Refactoring (August 2025)**: Reduced loop compilation from 10,668 lines across 10+ files to a single 334-line UnifiedLoopCompiler using TDD approach. Eliminated complex Y-combinator patterns in favor of simple recursive functions. Fixed g_array variable mismatch bugs. (see commit c85745e)
- **Array Desugaring & Y Combinator Patterns**: Discovered how Haxe desugars array.filter/map into TBlock/TWhile patterns and implemented detection framework (see [`docs/03-compiler-development/ARRAY_DESUGARING_PATTERNS.md`](docs/03-compiler-development/ARRAY_DESUGARING_PATTERNS.md))
- **Untyped Usage Violations**: Eliminated all unnecessary `untyped` usage in compiler code (VariableCompiler, OperatorCompiler, ControlFlowCompiler) for better type safety and IDE support
- **Orphaned Enum Parameter Variables**: Fixed compilation errors from unused TEnumParameter expressions in switch cases by implementing comprehensive AST-level detection and mitigation. First Reflaxe compiler to solve this fundamental issue caused by bypassing Haxe's optimizer (see [`docs/03-compiler-development/AST_CLEANUP_PATTERNS.md`](docs/03-compiler-development/AST_CLEANUP_PATTERNS.md))
- **Y Combinator Struct Update Patterns**: Fixed malformed inline if-else expressions with struct updates by forcing block syntax (see [`docs/03-compiler-development/Y_COMBINATOR_PATTERNS.md`](docs/03-compiler-development/Y_COMBINATOR_PATTERNS.md))
- **Variable Substitution in Lambda Expressions**: Fixed with proper AST variable tracking
- **Hardcoded Application Dependencies**: Removed all hardcoded references
- **Function Parameter Underscore Prefixing (August 2025)**: Fixed incorrect underscore prefixing of used function parameters in TypeSafeChildSpecBuilder and similar contexts. Implemented targeted priority check in VariableCompiler to ensure used parameters retain their correct names (see [`docs/03-compiler-development/FUNCTION_PARAMETER_UNDERSCORE_FIX.md`](docs/03-compiler-development/FUNCTION_PARAMETER_UNDERSCORE_FIX.md))

## Commit Standards
**Follow [Conventional Commits](https://www.conventionalcommits.org/)**: `<type>(<scope>): <subject>`
- **NO AI attribution**: Never add "Generated with Claude Code" or "Co-Authored-By: Claude"

## Development Loop ⚡ **CRITICAL WORKFLOW**

**MANDATORY: Every development change MUST follow this complete validation loop:**

```bash
# 1. Run full test suite (ALL tests must pass)
npm test

# 2. Verify todo-app compiles and runs
cd examples/todo-app && npx haxe build-server.hxml && mix compile --force && mix phx.server
```

**Rule**: If ANY step in this loop fails, the development change is incomplete.

## Implementation Status
**See**: [`docs/08-roadmap/`](docs/08-roadmap/) - Complete feature status and production readiness

**v1.0 Status**: ALL COMPLETE ✅ - Core features, Phoenix Router DSL, LiveView, Ecto, OTP patterns, Mix integration, Testing

## Test Status Summary
**See**: [`docs/03-compiler-development/testing-infrastructure.md`](docs/03-compiler-development/testing-infrastructure.md) - Complete test architecture and status

## Development Resources & Reference Strategy
- **Reference Codebase**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` - **CRITICAL**: Contains working Reflaxe compiler patterns, Haxe API usage examples, and Phoenix integration patterns. ALWAYS check here first for:
  - Haxe macro API usage patterns
  - Reflaxe compiler implementation examples  
  - Working AST processing patterns
  - Test infrastructure patterns
  - **Elixir Language Source**: `/elixir/` - Official Elixir language implementation
  - **Phoenix Framework Source**: `/phoenix/` and `/phoenix_live_view/` - Framework patterns
- **Haxe API Documentation**: https://api.haxe.org/ - For type system and language features  
- **Haxe Manual**: https://haxe.org/manual/ - **CRITICAL**: Always consult for advanced features
- **Web Resources**: Use WebSearch and WebFetch for current documentation
- **Principle**: Always reference existing working code rather than guessing

## Documentation References
**Complete Documentation Index**: [`docs/README.md`](docs/README.md) - Comprehensive guide to all project documentation

**Quick Access**:
- **Installation**: [docs/01-getting-started/installation.md](docs/01-getting-started/installation.md)
- **Development Workflow**: [docs/01-getting-started/development-workflow.md](docs/01-getting-started/development-workflow.md)
- **Quick Patterns**: [docs/07-patterns/quick-start-patterns.md](docs/07-patterns/quick-start-patterns.md)
- **Troubleshooting**: [docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)
- **Compiler Development**: [docs/03-compiler-development/CLAUDE.md](docs/03-compiler-development/CLAUDE.md)

**⚡ Critical Standard Library Implementation Guides**:
- **Stdlib Implementation Guide**: [`docs/03-compiler-development/STDLIB_IMPLEMENTATION_GUIDE.md`](docs/03-compiler-development/STDLIB_IMPLEMENTATION_GUIDE.md) - Definitive guide for implementing stdlib with idiomatic output
- **Extern Deep Dive**: [`docs/03-compiler-development/EXTERN_DEEP_DIVE.md`](docs/03-compiler-development/EXTERN_DEEP_DIVE.md) - Complete understanding of externs vs code generation
- **Native & Metadata Guide**: [`docs/03-compiler-development/NATIVE_AND_METADATA_COMPLETE_GUIDE.md`](docs/03-compiler-development/NATIVE_AND_METADATA_COMPLETE_GUIDE.md) - All metadata combinations and effects

---

**Remember**: All detailed information is in the organized [docs/](docs/) structure. This file provides navigation and critical rules only.
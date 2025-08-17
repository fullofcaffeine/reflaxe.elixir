# Elixir Runtime Architecture in Reflaxe.Elixir

This document clarifies the architectural components of Reflaxe.Elixir, particularly the distinction between "Elixir runtime infrastructure" and "BEAM VM runtime execution."

## 🏗️ Architecture Overview

Reflaxe.Elixir consists of **three distinct runtime environments**:

1. **Development Infrastructure** (Elixir) - Development workflow support
2. **Compilation Environment** (Haxe Macros) - Transpilation logic  
3. **Production Runtime** (BEAM VM) - Execution of generated code

### The "Elixir Runtime" Terminology

When we refer to "Elixir runtime" in Reflaxe.Elixir, we mean the **development infrastructure written in Elixir**, not the BEAM VM that executes compiled code.

## 🔧 Development Infrastructure (Elixir)

**Location**: `/lib/` directory  
**Purpose**: Provides development workflow, compilation orchestration, and IDE integration  
**Language**: Pure Elixir  
**Lifecycle**: Runs during development, not in production

### Core Components

```
lib/
├── mix/tasks/              # Mix task definitions
│   ├── compile.haxe.ex    # Main compilation task
│   ├── haxe.gen.*.ex      # Code generation tasks
│   ├── haxe.watch.ex      # File watching integration
│   └── haxe.*.ex          # Development utilities
├── haxe_server.ex         # Haxe compilation server management
├── haxe_watcher.ex        # File system change monitoring
├── haxe_compiler.ex       # Compilation orchestration
└── haxe_task.ex           # Mix.Task integration utilities
```

#### 1. HaxeServer (`lib/haxe_server.ex`)
**Purpose**: Manages `haxe --wait` compilation servers for fast incremental builds

```elixir
# Starts a persistent Haxe compiler process
{:ok, pid} = HaxeServer.start_link(port: 8080)

# Compilation requests are sent to the persistent server
HaxeServer.compile("build.hxml")
```

**Why needed**: Haxe compilation startup time is significant. By keeping a `haxe --wait` server running, we achieve sub-second compilation times.

#### 2. HaxeWatcher (`lib/haxe_watcher.ex`)
**Purpose**: Monitors Haxe source files for changes and triggers automatic recompilation

```elixir
# Watches src_haxe/ directory for .hx file changes
HaxeWatcher.start_link(
  directories: ["src_haxe"],
  auto_compile: true,
  debounce_ms: 200
)
```

**Why needed**: Provides live-reload development experience similar to Phoenix LiveView.

#### 3. Mix Tasks (`lib/mix/tasks/`)
**Purpose**: Integration with Elixir's standard build tool

```bash
mix compile.haxe          # Compile Haxe to Elixir
mix haxe.watch           # Start file watching
mix haxe.gen.project     # Generate new projects
mix haxe.gen.context     # Generate Phoenix contexts
```

**Why needed**: Provides familiar Elixir development workflow and integrates with existing Phoenix projects.

## ⚙️ Compilation Environment (Haxe Macros)

**Location**: `/src/reflaxe/elixir/` directory  
**Purpose**: Transpiles typed Haxe AST to Elixir source code  
**Language**: Haxe (macro-time only)  
**Lifecycle**: Exists only during compilation, disappears afterward

### Core Components

```
src/reflaxe/elixir/
├── ElixirCompiler.hx      # Main transpiler (extends BaseCompiler)
├── helpers/               # Compilation helpers
│   ├── ClassCompiler.hx   # Class/struct compilation
│   ├── EnumCompiler.hx    # Enum compilation
│   └── *.hx              # Specialized compilers
└── ElixirTyper.hx        # Type mapping logic
```

**Critical Understanding**: These classes **only exist at macro-time**. Once compilation finishes, they're gone.

```haxe
// ❌ WRONG: Cannot instantiate at runtime
var compiler = new ElixirCompiler(); // Type not found!

// ✅ CORRECT: Compiler runs automatically during Haxe compilation
// via Context.onAfterTyping() callback registration
```

## 🚀 Production Runtime (BEAM VM)

**Location**: Generated `.ex` files + `/std/` extern definitions  
**Purpose**: Execution environment for compiled applications  
**Language**: Generated Elixir + type-safe extern definitions  
**Lifecycle**: Production deployment on BEAM VM

### Runtime Components

#### 1. Generated Elixir Code
```elixir
# Generated from Haxe source
defmodule TodoApp.User do
  @doc "Creates a new user with validation"
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
```

#### 2. Standard Library Externs (`/std/`)
**Purpose**: Type-safe interfaces to Elixir/Phoenix/Ecto libraries

```haxe
// std/ecto/Repo.hx - Type-safe Ecto interface
extern class Repo {
    static function insert<T>(changeset: Changeset<T>): Result<T, Changeset<T>>;
    static function all<T>(schema: Class<T>): Array<T>;
}

// std/phoenix/LiveView.hx - Type-safe LiveView interface  
extern class LiveView {
    static function push_event(socket: Socket, event: String, payload: Dynamic): Socket;
}
```

**Why needed**: Provides compile-time type safety when calling Elixir functions from generated code.

## 🔄 The Complete Development Flow

### 1. Development Time
```
Developer writes Haxe code
        ↓
HaxeWatcher detects file change
        ↓
HaxeServer runs compilation
        ↓
ElixirCompiler (macro) transforms AST
        ↓
Generated .ex files written to /lib
        ↓
Mix compiles Elixir to BEAM bytecode
        ↓
Phoenix hot-reloads the application
```

### 2. Production Time
```
Generated .ex files
        ↓
Compiled to BEAM bytecode
        ↓
Deployed to production BEAM VM
        ↓
No Haxe, no compilation infrastructure
        ↓
Pure Elixir application execution
```

## 🤝 How Components Interact

### Haxe Code → Elixir Infrastructure
```haxe
// TodoUser.hx (your application code)
@:liveview
class TodoUser {
    public static function create(attrs: Dynamic): Result<User, String> {
        return Repo.insert(User.changeset(attrs));  // Uses std/ecto/Repo.hx extern
    }
}
```

### Generated Code → Standard Library
```elixir
# Generated TodoUser.ex
defmodule TodoApp.TodoUser do
  def create(attrs) do
    User.changeset(attrs)
    |> Repo.insert()  # Calls actual Elixir Repo module
  end
end
```

### Development Infrastructure → Compilation
```elixir
# HaxeWatcher calls HaxeServer
def handle_file_change(file_path) do
  HaxeServer.compile("build.hxml")  # Triggers ElixirCompiler macro
end
```

## 🎯 Key Architectural Insights

### 1. **Separation of Concerns**
- **Elixir infrastructure**: Development workflow (watching, compiling, generating)
- **Haxe macros**: Language transpilation (AST → code transformation)  
- **BEAM runtime**: Application execution (performance, fault tolerance)

### 2. **No Runtime Dependencies**
- Generated applications have **zero** dependencies on Haxe or compilation infrastructure
- Production deployment is pure Elixir/Phoenix running on BEAM
- Standard library externs provide the only interface layer

### 3. **Type Safety Bridge**
- Haxe provides compile-time type safety
- Standard library externs bridge to Elixir ecosystem with types
- Generated code is idiomatic Elixir (no foreign constructs)

### 4. **Development Experience**
- Live compilation with sub-second feedback
- Familiar Mix integration for Elixir developers
- IDE support through language servers

## 📚 Related Documentation

- [`ARCHITECTURE.md`](ARCHITECTURE.md) - Complete system architecture
- [`MIX_INTEGRATION.md`](MIX_INTEGRATION.md) - Mix task system details
- [`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md) - Why you can't unit test the compiler
- [`STANDARD_LIBRARY_HANDLING.md`](STANDARD_LIBRARY_HANDLING.md) - Extern definition patterns

## ❓ Common Questions

**Q: Why not implement everything in Haxe?**  
A: The development infrastructure needs to integrate with Mix, Phoenix, and Elixir tooling. Writing it in Elixir provides seamless integration with the existing ecosystem.

**Q: Does the generated code depend on Haxe?**  
A: No. Generated applications are pure Elixir with zero Haxe dependencies. They run on any BEAM VM.

**Q: Can I deploy without the compilation infrastructure?**  
A: Yes. Production deployments only need the generated .ex files. All Haxe and compilation components are development-time only.

**Q: How do I debug generated code?**  
A: Use standard Elixir debugging tools (IEx, Logger, Phoenix error pages). The generated code is idiomatic Elixir.

---

*This architecture enables the best of both worlds: Haxe's type safety during development and Elixir's runtime characteristics in production.*
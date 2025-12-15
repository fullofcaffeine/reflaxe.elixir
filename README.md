# Reflaxe.Elixir

[![Version](https://img.shields.io/github/v/release/fullofcaffeine/reflaxe.elixir?include_prereleases)](https://github.com/fullofcaffeine/reflaxe.elixir/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI Status](https://github.com/fullofcaffeine/reflaxe.elixir/workflows/CI/badge.svg)](https://github.com/fullofcaffeine/reflaxe.elixir/actions)
[![Haxe](https://img.shields.io/badge/Haxe-4.3.7+-orange)](https://haxe.org)
[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)](https://elixir-lang.org)

**Type-safe Haxe to Elixir compiler with Phoenix/LiveView support.** Write business logic in Haxe, compile to idiomatic Elixir code for the BEAM ecosystem.

> **Future Vision**: See [docs/08-roadmap/vision.md](docs/08-roadmap/vision.md) for long-term plans including AI tooling and universal platform support  
> **Current Status**: Production-ready Haxe→Elixir compilation with full Phoenix/LiveView/Ecto support

## Why Reflaxe.Elixir?

### 🎯 Type-Safe BEAM Development with Haxe

**The Problem**: You want BEAM's incredible concurrency and fault tolerance, but Elixir's dynamic typing means runtime errors in production.

**The Solution**: Reflaxe.Elixir brings compile-time type safety to the BEAM ecosystem:
- **Type Safety Today** - Catch errors at compile time, not in production
- **Idiomatic Elixir Output** - Generated code looks hand-written by Elixir experts
- **Full Phoenix Integration** - LiveView, Ecto, OTP, GenServers all supported
- **Future Expansion** - Haxe's multi-target nature enables future platform support

### 💡 Real-World Scenarios

#### Build Type-Safe Phoenix Applications
Write your Phoenix app in Haxe and get:
- **Compile-time validation** of LiveView assign/update patterns
- **Type-safe Ecto schemas** with automatic changeset generation
- **OTP supervision trees** with typed GenServer callbacks
- **Idiomatic Elixir output** that Phoenix developers recognize

#### Share Code with Frontend (Future)
The foundation for multi-target development:
- **Business logic in Haxe** - validation, algorithms, data transformations
- **Backend on BEAM** - Phoenix/LiveView/Ecto with full type safety ✅
- **Frontend on JavaScript** - Async/await support + standard Haxe→JS compilation ✅
- **Advanced JS integration** - genes + dts2hx planned for TypeScript ecosystem access

#### Leverage BEAM's Unique Strengths
- **Massive concurrency** - Handle millions of connections with lightweight processes
- **Fault tolerance** - Let it crash philosophy with supervisor recovery
- **Hot code reloading** - Update production systems without downtime
- **Type safety** - Catch errors before they reach production

### 🚀 How It Compares

| | Reflaxe.Elixir | Gleam | Pure Elixir | TypeScript |
|---|---|---|---|---|
| **Type Safety** | ✅ Compile-time | ✅ Compile-time | ❌ Runtime | ✅ Compile-time |
| **BEAM Integration** | ✅ Full Phoenix/OTP | ✅ Native | ✅ Native | ❌ None |
| **Phoenix LiveView** | ✅ Native support | ⚠️ Via FFI | ✅ Native | ❌ None |
| **Multi-target Potential** | ✅ Haxe foundation | ❌ BEAM only | ❌ BEAM only | ⚠️ JS only |
| **Ecosystem Maturity** | ✅ Since 2005 | ⚠️ New | ✅ Mature | ✅ Mature |
| **Learning Curve** | ✅ TypeScript-like | ⚠️ Rust-like | ⚠️ Ruby-like | ✅ Familiar |

### 🎪 Built on Proven Technology

- **Haxe** (2005): Battle-tested cross-platform toolkit used in production by companies like Netflix, Disney, BBC, Toyota, and more
- **Elixir/BEAM**: Powers WhatsApp (2B users), Discord, Pinterest, and other massive-scale systems
- **Reflaxe**: Modern compiler framework making Haxe more powerful than ever

## Current Status & Roadmap

### ✅ Production Ready (v1.0)
- **Phoenix Integration** - LiveView, controllers, templates, routers 100% supported
- **HXX Template System** - Complete compile-time JSX→HEEx transformation with AST-based processing
  - **Template Helper Metadata** ✨ NEW - Uses @:templateHelper metadata for extensible Phoenix function compilation
  - **Type-Safe Phoenix Abstractions** ✨ NEW - Assigns<T>, LiveViewSocket<T>, FlashMessage, RouteParams<T> with operator overloading
- **Ecto Complete** - Schemas, changesets, queries, migrations with full DSL support  
- **Mix Integration** - Seamless build pipeline with file watching and incremental compilation
- **Source Maps** - First Reflaxe target with `.ex.map` generation for debugging
- **OTP Support** - GenServers, Supervisors, Registry with type-safe compilation
- **Type Safety** - Complete Haxe→Elixir type mapping and compile-time validation
- **JavaScript Async/Await** - Native async/await compilation for modern JS development

### 🔮 Future Expansion
For the complete roadmap including AI tooling, universal deployment, and multi-platform support, see [docs/08-roadmap/vision.md](docs/08-roadmap/vision.md):

- **JavaScript Integration** - Advanced TypeScript ecosystem access
- **Mobile Support** - Capacitor and React Native deployment  
- **Desktop Applications** - Electron/Tauri cross-platform apps
- **AI-Enhanced Tooling** - Intelligent development assistance  

## Installation

### Prerequisites
- Node.js 16+ (for lix package management)
- Elixir 1.14+ (for Phoenix/Ecto ecosystem)

### Method 1: Install via Lix (Recommended)

```bash
# Install latest version from GitHub
npx lix install github:fullofcaffeine/reflaxe.elixir

# Or install a specific version/tag
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.0.2

# Add to existing project
npx lix use
```

### Method 2: Vendoring (Copy source directly)

For projects that want to vendor the compiler source:

```bash
# Clone or download the repository
git clone https://github.com/fullofcaffeine/reflaxe.elixir.git

# Copy necessary files to your project
cp -r reflaxe.elixir/src/ your-project/vendor/reflaxe.elixir/src/
cp -r reflaxe.elixir/std/ your-project/vendor/reflaxe.elixir/std/
cp reflaxe.elixir/haxelib.json your-project/vendor/reflaxe.elixir/

# In your build.hxml, add:
# -cp vendor/reflaxe.elixir/src
# -cp vendor/reflaxe.elixir/std
# -lib reflaxe
# --macro reflaxe.elixir.CompilerInit.Start()
```

### Usage in Your Project

Once installed, add to your `build.hxml`:

```hxml
-lib reflaxe.elixir
-cp src_haxe
-D elixir_output=lib
-D reflaxe_runtime
Main
```

### ⚠️ Important: Compiler Configuration

**DO NOT use `-D analyzer-optimize`** when compiling to Elixir. This flag triggers aggressive optimizations designed for C++ and JavaScript that produce non-idiomatic Elixir code.

**Recommended configuration:**
```hxml
# Good optimizations
-dce full                    # Dead code elimination (recommended)
-D loop_unroll_max_cost=10   # Reasonable loop unrolling limit

# AVOID these
# -D analyzer-optimize       # Destroys functional patterns
# -D analyzer-check          # May trigger unwanted optimizations
```

For complete compiler configuration guidance, see [docs/01-getting-started/compiler-flags-guide.md](docs/01-getting-started/compiler-flags-guide.md).

## Quick Start

### Create a New Project

```bash
# Using the project generator (after installation)
npx lix run reflaxe.elixir create my-app

# Or create a Phoenix project
npx lix run reflaxe.elixir create my-phoenix-app --type phoenix
```

🚀 **Get started in 5 minutes!** See [docs/06-guides/QUICKSTART.md](docs/06-guides/QUICKSTART.md)

## Development Workflow

### Basic Compilation

```bash
# Compile once
npx haxe build.hxml

# Watch for changes (long-running)
mix haxe.watch
```

### Phoenix Integration

```bash
# Add to your Phoenix project's mix.exs
defp deps do
  [
    # ... other deps
    {:reflaxe_elixir, "~> 1.0", only: [:dev]}
  ]
end

# Compile Haxe as part of your build
mix compile.haxe

# Start Phoenix with Haxe compilation
mix phx.server
```

### File Organization

```
your-project/
├── src_haxe/              # Your Haxe source files
│   ├── controllers/       # Phoenix controllers
│   ├── live/             # LiveView modules  
│   ├── contexts/         # Business logic
│   └── schemas/          # Ecto schemas
├── lib/                  # Generated Elixir files
│   └── (compiled output)
├── build.hxml            # Haxe build configuration
└── mix.exs              # Phoenix/Elixir dependencies
```

## 📚 Documentation

Start at **[docs/README.md](docs/README.md)** for the curated documentation index.

### Quick Links
- **[Installation Guide](docs/01-getting-started/installation.md)** - Setup and prerequisites
- **[Quickstart](docs/06-guides/QUICKSTART.md)** - Your first Haxe→Elixir project
- **[Phoenix Integration](docs/02-user-guide/PHOENIX_INTEGRATION.md)** - Controllers, LiveView, Ecto, Channels
- **[Escape Hatches](docs/02-user-guide/ESCAPE_HATCHES.md)** - Calling Elixir from Haxe safely

### Reference
- **[Haxe→Elixir Mappings](docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md)** ✨ - Complete reference for how Haxe constructs map to Elixir code
- **[Source Mapping Guide](docs/04-api-reference/SOURCE_MAPPING.md)** 🎯 - Complete guide to our pioneering source mapping feature
- **[Annotations](docs/04-api-reference/ANNOTATIONS.md)** - Complete annotation reference
- **[Troubleshooting](docs/06-guides/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Examples](examples/)** - Working code examples

### Architecture
- **[Architecture Overview](docs/05-architecture/ARCHITECTURE.md)** - Compiler internals
- **[Testing Guide](docs/03-compiler-development/TESTING_INFRASTRUCTURE.md)** - Snapshot + integration testing system
- **[Contributing](docs/10-contributing/contributing.md)** - Contributing and extending

### Manual Installation (For Contributors)

```bash
# Clone and setup
git clone https://github.com/fullofcaffeine/reflaxe.elixir
cd reflaxe.elixir

# Install dependencies (both ecosystems)
npm ci            # Installs lix + Haxe dependencies
npx lix download  # Downloads project-specific Haxe libraries
mix deps.get      # Installs Elixir dependencies

# Run tests
npm test          # Full suite (snapshots + Elixir validation + Mix)
npm run qa:sentinel  # Todo-app build + boot probe (async)
```

📖 **New to lix or Haxe?** See [docs/01-getting-started/installation.md](docs/01-getting-started/installation.md) for complete setup guide with troubleshooting.

## Project Structure

Reflaxe.Elixir follows standard Reflaxe compiler conventions (similar to Reflaxe.CPP):

```
haxe.elixir/
├── src/                    # Compiler source (macro-time transpiler code)
│   └── reflaxe/elixir/     # ElixirCompiler.hx and helpers
├── std/                    # Standard library (compile-time classpath)
│   ├── elixir/             # Elixir stdlib externs (IO, File, GenServer, etc.)
│   ├── phoenix/            # Phoenix framework externs (LiveView, Socket, etc.)
│   └── ecto/               # Ecto ORM externs (Schema, Changeset, Query)
├── lib/                    # Elixir runtime support (Mix integration)
│   ├── haxe_compiler.ex   # Mix compilation task
│   ├── haxe_watcher.ex     # File watching for development
│   └── haxe_server.ex      # Haxe compilation server wrapper
├── test/                   # Compiler tests (snapshot testing)
└── examples/               # Example applications
    └── todo-app/           
        └── src_haxe/       # User application code in Haxe
```

### Directory Purposes

- **`src/`** - The compiler that transforms Haxe TypedExpr → ElixirAST → transforms → printed Elixir
- **`std/`** - Haxe externs and abstractions for Elixir/Phoenix/Ecto functionality (included via `-lib reflaxe.elixir` or vendoring)
- **`lib/`** - Elixir runtime files needed for Mix integration and compilation support
- **`src_haxe/`** - User application code written in Haxe (in examples)

This separation follows Reflaxe conventions and ensures clear boundaries between compiler code, standard library, and user application code.

## Architecture

Reflaxe.Elixir uses a **dual-ecosystem architecture**:

### 🔧 Haxe Development (npm + lix)
- **Compiler development**: Build the Haxe→Elixir compiler
- **Modern testing**: tink_unittest + tink_testrunner with rich output
- **Dependency management**: lix with GitHub sources + locked versions

### ⚡ Elixir Runtime (mix)  
- **Generated code testing**: Validate compiled Elixir modules
- **Phoenix integration**: Test LiveView, Ecto, GenServer workflows
- **Native tooling**: Standard mix tasks and BEAM ecosystem

## Usage

### Enable Source Mapping (New!)
```hxml
# In your compile.hxml or build.hxml
-lib reflaxe.elixir
-cp src_haxe
-D elixir_output=lib
-D reflaxe_runtime
-D source-map  # Enable source mapping for debugging
Main
```

Now compilation generates `.ex.map` files alongside `.ex` files, enabling:
- Precise error locations mapped back to Haxe source
- Debugging at the Haxe level while running Elixir
- LLM agents can use source positions for accurate fixes

See [docs/04-api-reference/SOURCE_MAPPING.md](docs/04-api-reference/SOURCE_MAPPING.md) for complete guide.

### Phoenix LiveView
```haxe
@:liveview
class CounterLive {
    var count = 0;
    
    function mount(_params, _session, socket) {
        return {:ok, assign(socket, "count", count)};
    }
    
    function handle_event("increment", _params, socket) {
        count++;
        return {:noreply, assign(socket, "count", count)};
    }
    
    function render(assigns: Dynamic): String {
        return HXX.hxx('
            <div class="counter">
                <h1>${assigns.count}</h1>
                <button phx-click="increment">+</button>
            </div>
        ');
    }
}
```

Compiles to:
```elixir  
defmodule CounterLive do
  use Phoenix.LiveView
  
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end
  
  def handle_event("increment", _params, socket) do
    count = socket.assigns.count + 1
    {:noreply, assign(socket, :count, count)}
  end
  
  def render(assigns) do
    ~H"""
    <div class="counter">
      <h1>{assigns.count}</h1>
      <button phx-click="increment">+</button>
    </div>
    """
  end
end
```

### Ecto Changesets
```haxe
@:changeset  
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", ~r/\S+@\S+\.\S+/)
    static function changeset(user, attrs) {
        // Compiled to proper Ecto.Changeset pipeline
    }
}
```

### OTP GenServer
```haxe
@:genserver
class CounterServer {
    var count = 0;
    
    function init(initial) {
        count = initial;
        return {:ok, count};
    }
    
    function handle_call(:get, _from, state) {
        return {:reply, state, state};
    }
}
```

## Development

### Testing

The project uses a dual-ecosystem testing approach with self-referential library configuration:

```bash
npm test              # Full suite (snapshots + Elixir validation + Mix)
npm run test:quick    # Snapshot suite only
npm run test:mix      # Mix/Elixir tests only
npm run test:update   # Update expected snapshot outputs
npm run qa:sentinel   # Todo-app build + boot probe (async)
npm run ci:guards     # Guardrails (no app heuristics, etc.)
```

**Test Infrastructure:**
- **Complete Coverage**: `npm test` runs Haxe compiler tests, generator tests, AND Mix runtime tests
- **Snapshot Testing**: Validates compiler output against expected Elixir code
- **Generator Testing**: Validates project templates and tooling
- **Runtime Validation**: Mix tests compile/run generated Elixir code
- **Self-Referential Library**: Tests use `-lib reflaxe.elixir` via `haxe_libraries/reflaxe.elixir.hxml`
- **Mix Integration**: Tests real compilation in Phoenix projects
- **Test Helper**: `test/support/haxe_test_helper.ex` handles project setup

**⚠️ Critical**: For self-referential library configuration issues, see [docs/06-guides/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md](docs/06-guides/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md)

For detailed testing documentation, see [docs/03-compiler-development/TESTING_INFRASTRUCTURE.md](docs/03-compiler-development/TESTING_INFRASTRUCTURE.md)

### Development Workflow
```bash
# Start file watching for instant feedback
mix haxe.watch

# In another terminal, make changes
vim src_haxe/MyModule.hx  # Files auto-compile on save

# Or for compiler development:
vim src/reflaxe/elixir/ElixirCompiler.hx
npm test  # Test compiler changes
```

### LLM Development  
Perfect for AI-assisted development with fast feedback loops:
```bash
# Start watching with LLM-friendly output
mix haxe.watch --verbose

# LLM creates/modifies .hx files → automatic compilation
# Sub-second feedback enables rapid iteration
```

## Package Management

### Why lix + npm?
- **lix**: Modern Haxe package manager with GitHub sources
- **npm**: JavaScript ecosystem integration and script orchestration  
- **Benefits**: Project-specific Haxe versions, zero global conflicts

### Why mix?
- **Native Elixir tooling**: Industry standard for BEAM development
- **Phoenix ecosystem**: Seamless LiveView, Ecto, OTP integration
- **Generated code validation**: Tests the actual output, not just compilation

## Performance

All compilation targets exceed performance requirements:

- **Basic compilation**: 0.015ms (750x faster than 15ms target) ⚡
- **Ecto Changesets**: 0.006ms average (2500x faster) ⚡  
- **Migration DSL**: 6.5μs per migration (2300x faster) ⚡
- **OTP GenServer**: 0.07ms average (214x faster) ⚡
- **Phoenix LiveView**: <1ms average (15x faster) ⚡

## Test Results

**All snapshot tests + Mix tests passing**:

### Haxe Snapshot Tests (48/48 ✅)
- Source mapping tests (source_map_basic, source_map_validation)
- LiveView, OTP, Ecto compilation tests
- HXX template processing tests
- Example compilation tests
- Legacy extern definitions (FinalExternTest, CompilationOnlyTest, TestWorkingExterns)
- Modern tink_unittest (async tests, performance validation, rich assertions)

### Elixir/Mix Tests (13/13 ✅)  
- Mix task integration
- Ecto migration generation
- Phoenix LiveView workflows
- OTP GenServer supervision

## Contributing

See [docs/10-contributing/contributing.md](docs/10-contributing/contributing.md) for detailed development guide.

### Adding Features
1. Extend the AST pipeline (`src/reflaxe/elixir/ast/`) in builder/transformer/printer layers
2. Add/adjust std externs in `std/` when exposing Elixir/Phoenix/Ecto APIs
3. Add snapshot coverage under `test/snapshot/` (and update intended outputs if needed)
4. Run `npm test` and `npm run qa:sentinel`

## Roadmap

Check out our [ROADMAP.md](ROADMAP.md) to see what's coming next!

## License

GPL-3.0 - See [LICENSE](LICENSE) for details

## Links

- [Haxe](https://haxe.org) - The cross-platform toolkit  
- [Reflaxe](https://github.com/SomeRanDev/reflaxe) - Haxe-to-everything compiler framework
- [Elixir](https://elixir-lang.org) - Dynamic, functional language for BEAM
- [Phoenix](https://phoenixframework.org) - Productive web framework  
- [lix](https://github.com/lix-pm/lix.client) - Modern Haxe package manager

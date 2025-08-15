# Reflaxe.Elixir

[![Version](https://img.shields.io/github/v/release/fullofcaffeine/reflaxe.elixir?include_prereleases)](https://github.com/fullofcaffeine/reflaxe.elixir/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI Status](https://github.com/fullofcaffeine/reflaxe.elixir/workflows/CI/badge.svg)](https://github.com/fullofcaffeine/reflaxe.elixir/actions)
[![Tests](https://img.shields.io/badge/tests-178%2F178%20passing-brightgreen)](https://github.com/fullofcaffeine/reflaxe.elixir/actions)
[![Haxe](https://img.shields.io/badge/Haxe-4.3.6+-orange)](https://haxe.org)
[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)](https://elixir-lang.org)

**Write your business logic once, deploy it anywhere.** A modern Haxe compilation target for Elixir/BEAM that brings type safety without vendor lock-in.

> **Current Status**: Pre-v1.0 (Phoenix/Ecto complete, OTP supervision patterns in progress)

## Why Reflaxe.Elixir?

### 🎯 The Strategic Choice for Type-Safe Elixir

**The Problem**: You want the power of BEAM (massive concurrency, fault tolerance, hot code reloading) with compile-time type safety. But existing solutions lock you into a single runtime.

**The Solution**: Reflaxe.Elixir gives you:
- **Type safety today** - Catch errors at compile time, not in production
- **Freedom tomorrow** - Your code can target JS, C++, Python, Java, C#, or any other Haxe target
- **Phoenix ecosystem now** - Deep integration with LiveView, Ecto, OTP patterns, and HXX template processing

### 💡 Real-World Scenarios

#### Share Code Across Your Stack
Write validation logic once in Haxe, use it in:
- Your Phoenix backend (compiled to Elixir)
- Your React frontend (compiled to JavaScript)  
- Your mobile app (compiled to C++ or Java)
- Your CLI tools (compiled to Python or native)

#### Future-Proof Your Architecture
- Start with Elixir/BEAM for its excellent concurrency
- Move performance-critical paths to C++ without rewriting
- Deploy microservices to different runtimes as needed
- Pivot to new platforms as requirements change

#### Unite Your Team's Knowledge
- Frontend developers can understand backend code
- Backend developers can contribute to frontend
- One language to learn, maintain, and master
- TypeScript-like syntax familiar to most developers

### 🚀 How It Compares

| | Reflaxe.Elixir | Gleam | Pure Elixir | TypeScript |
|---|---|---|---|---|
| **Type Safety** | ✅ Compile-time | ✅ Compile-time | ❌ Runtime | ✅ Compile-time |
| **Target Runtimes** | ✅ Multiple | ❌ BEAM only | ❌ BEAM only | ❌ JS only |
| **Phoenix Integration** | ✅ Native | ⚠️ Via FFI | ✅ Native | ❌ None |
| **Ecosystem Maturity** | ✅ Since 2005 | ⚠️ New | ✅ Mature | ✅ Mature |
| **Metaprogramming** | ✅ Powerful macros | ❌ None | ✅ Macros | ⚠️ Limited |
| **Learning Curve** | ✅ TypeScript-like | ⚠️ Rust-like | ⚠️ Ruby-like | ✅ Familiar |

### 🎪 Built on Proven Technology

- **Haxe** (2005): Battle-tested cross-platform toolkit used in production by companies like Netflix, Disney, BBC, Toyota, and more
- **Elixir/BEAM**: Powers WhatsApp (2B users), Discord, Pinterest, and other massive-scale systems
- **Reflaxe**: Modern compiler framework making Haxe more powerful than ever

## Current Status (Pre-v1.0)

### ✅ Production-Ready Features
- **Phoenix Integration** - LiveView, controllers, templates, routers 100% supported
- **HXX Template Processing** - JSX-like syntax for type-safe Phoenix HEEx templates
- **Ecto Complete** - Schemas, changesets, queries, migrations with full DSL support  
- **Mix Integration** - Seamless build pipeline with file watching and incremental compilation
- **Source Maps** - First Reflaxe target with `.ex.map` generation for debugging
- **Basic GenServer** - `@:genserver` compilation with lifecycle callbacks
- **Type Safety** - Complete Haxe→Elixir type mapping and compile-time validation

### ⏳ In Development (Required for v1.0)
- **OTP Supervision** - Supervisors, Registry, Task supervision (essential for production)
- **Standard Library** - Process, IO, File, Enum extern definitions  
- **Protocol Support** - Enumerable, String.Chars, Inspect (fundamental in Elixir)
- **Type Aliases** - Typedef compilation for better code documentation

### 🎯 Post-v1.0 (Polish & Optimization)
- Enhanced error messages and IDE support
- Performance optimization and caching
- Advanced metaprogramming features  

## Installation

### Prerequisites
- Node.js 16+ (for lix package management)
- Elixir 1.14+ (for Phoenix/Ecto ecosystem)

### Method 1: Install via Lix (Recommended)

```bash
# Install latest version from GitHub
npx lix install github:fullofcaffeine/reflaxe.elixir

# Or install a specific version/tag
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.0.1

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

## Quick Start

### Create a New Project

```bash
# Using the project generator (after installation)
npx lix run reflaxe.elixir create my-app

# Or create a Phoenix project
npx lix run reflaxe.elixir create my-phoenix-app --type phoenix
```

🚀 **Get started in 5 minutes!** See [documentation/guides/QUICKSTART.md](documentation/guides/QUICKSTART.md)

## Development Workflow

### Basic Compilation

```bash
# Compile once
npx haxe build.hxml

# Watch for changes (requires file watching setup)
mix compile.haxe --watch
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

### Getting Started
- **[Tutorial: First Project](documentation/guides/TUTORIAL_FIRST_PROJECT.md)** - Step-by-step guide to build your first app
- **[Installation Guide](INSTALLATION.md)** - Complete setup with troubleshooting
- **[Getting Started](documentation/guides/GETTING_STARTED.md)** - Installation and setup guide

### Integration Guides  
- **[Phoenix Integration](documentation/PHOENIX_INTEGRATION_GUIDE.md)** - Controllers, LiveView, Ecto, Channels
- **[Idiomatic Syntax](documentation/IDIOMATIC_SYNTAX.md)** - Type-safe Elixir patterns and transformations
- **[Pipe Operators](documentation/guides/pipe-operators.md)** - Complete guide to pipe operator support
- **[Escape Hatches](documentation/ESCAPE_HATCHES.md)** - Using Elixir code from Haxe
- **[Cookbook](documentation/guides/COOKBOOK.md)** - Practical recipes for common tasks

### Reference
- **[Source Mapping Guide](documentation/SOURCE_MAPPING.md)** 🎯 - Complete guide to our pioneering source mapping feature
- **[Annotations](documentation/reference/ANNOTATIONS.md)** - Complete annotation reference
- **[LLM Workflow Compatibility](documentation/llm/LLM_WORKFLOW_COMPATIBILITY.md)** - Using Reflaxe.Elixir with AI assistants
- **[Troubleshooting](documentation/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Examples](examples/)** - Working code examples

### Architecture
- **[Architecture Overview](documentation/architecture/ARCHITECTURE.md)** - Compiler internals
- **[Testing Guide](documentation/architecture/TESTING.md)** - Test infrastructure and patterns
- **[Development Guide](DEVELOPMENT.md)** - Contributing and extending

### Manual Installation (For Contributors)

```bash
# Clone and setup
git clone https://github.com/fullofcaffeine/reflaxe.elixir
cd reflaxe.elixir

# Install dependencies (both ecosystems)
npm install       # Installs lix + Haxe dependencies
npx lix download  # Downloads project-specific Haxe libraries
mix deps.get      # Installs Elixir dependencies

# Run tests
npm test          # Snapshot tests (28 tests including source maps)
npm run test:all  # Full test suite (Haxe + Mix)
```

📖 **New to lix or Haxe?** See [INSTALLATION.md](INSTALLATION.md) for complete setup guide with troubleshooting.

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
-cp src_haxe
-lib reflaxe
-main Main
-D elixir_output=lib
-D source-map  # Enable source mapping for debugging
```

Now compilation generates `.ex.map` files alongside `.ex` files, enabling:
- Precise error locations mapped back to Haxe source
- Debugging at the Haxe level while running Elixir
- LLM agents can use source positions for accurate fixes

See [documentation/SOURCE_MAPPING.md](documentation/SOURCE_MAPPING.md) for complete guide.

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
        return HXX('
            <div class="counter">
                <h1>Count: ${assigns.count}</h1>
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
        <h1>Count: {assigns.count}</h1>
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
npm test              # Run ALL tests (178 total: 46 Haxe + 19 Generator + 132 Mix)
npm run test:haxe     # Run Haxe compiler tests only (snapshot tests)
npm run test:mix      # Run Mix/Elixir tests only (132 runtime tests)
npm run test:quick    # Run just Haxe tests for rapid feedback
npm run test:verify   # Quick verification - core functionality only
npm run test:core     # Test core examples (basic_syntax, liveview_basic)
npm run test:update   # Update expected snapshot test output
```

**Test Infrastructure:**
- **Complete Coverage**: `npm test` runs Haxe compiler tests, generator tests, AND Mix runtime tests
- **Snapshot Testing**: Validates compiler output against expected Elixir code (46 tests)
- **Generator Testing**: Validates project templates and LLM documentation generation (19 tests)
- **Runtime Validation**: Tests generated Elixir code execution in BEAM VM (132 tests)
- **Self-Referential Library**: Tests use `-lib reflaxe.elixir` via `haxe_libraries/reflaxe.elixir.hxml`
- **Mix Integration**: Tests real compilation in Phoenix projects
- **Test Helper**: `test/support/haxe_test_helper.ex` handles project setup

**⚠️ Critical**: For self-referential library configuration issues, see [documentation/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md](documentation/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md)

For detailed testing documentation, see [documentation/architecture/TESTING.md](documentation/architecture/TESTING.md)

### Development Workflow
```bash
# Start file watching for instant feedback
mix compile.haxe --watch

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
mix compile.haxe --watch --verbose

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

### Haxe Snapshot Tests (46/46 ✅)
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

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed development guide.

### Adding Features
1. Create helper compiler in `src/reflaxe/elixir/helpers/`
2. Add annotation support to `ElixirCompiler.hx`
3. Write tests using modern tink_unittest
4. Run `npm test` for full validation

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Roadmap

Check out our [ROADMAP.md](ROADMAP.md) to see what's coming next!

## License

MIT - See [LICENSE](LICENSE) for details

## Links

- [Haxe](https://haxe.org) - The cross-platform toolkit  
- [Reflaxe](https://github.com/SomeRanDev/reflaxe) - Haxe-to-everything compiler framework
- [Elixir](https://elixir-lang.org) - Dynamic, functional language for BEAM
- [Phoenix](https://phoenixframework.org) - Productive web framework  
- [lix](https://github.com/lix-pm/lix.client) - Modern Haxe package manager
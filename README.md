# Reflaxe.Elixir

[![Version](https://img.shields.io/github/v/release/fullofcaffeine/reflaxe.elixir?include_prereleases)](https://github.com/fullofcaffeine/reflaxe.elixir/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI Status](https://github.com/fullofcaffeine/reflaxe.elixir/workflows/CI/badge.svg)](https://github.com/fullofcaffeine/reflaxe.elixir/actions)
[![Tests](https://img.shields.io/badge/tests-130%2F130%20passing-brightgreen)](https://github.com/fullofcaffeine/reflaxe.elixir/actions)
[![Haxe](https://img.shields.io/badge/Haxe-4.3.6+-orange)](https://haxe.org)
[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)](https://elixir-lang.org)

A modern Haxe compilation target for Elixir/BEAM with native Phoenix integration.

## Features

✅ **Source Mapping Support** 🎯 - **First Reflaxe target with `.ex.map` generation** for seamless debugging  
✅ **Mix-First Development** - Seamless integration with Elixir build pipeline  
✅ **File Watching & Incremental Compilation** - `mix compile.haxe --watch` with sub-second rebuild times  
✅ **LLM-Optimized Workflows** - Perfect for AI-assisted development with fast iteration cycles  
✅ **Phoenix LiveView Support** - Native `@:liveview` compilation with socket management  
✅ **Ecto Integration** - `@:changeset` and `@:migration` DSL support  
✅ **OTP GenServer Support** - `@:genserver` with full lifecycle callbacks  
✅ **Protocol System** - `@:protocol` and `@:impl` for polymorphic dispatch  
✅ **Behavior Contracts** - `@:behaviour` with compile-time callback validation  
✅ **Type-Safe Compilation** - Complete Haxe→Elixir type mapping  
✅ **Performance Optimized** - Sub-millisecond compilation targets  

## Quick Start

### Prerequisites
- Node.js 16+ (for lix package management)
- Elixir 1.14+ (for Phoenix/Ecto ecosystem)

### Create a New Project (Recommended)

```bash
# Install Reflaxe.Elixir
npx lix install github:YourOrg/reflaxe.elixir

# Create a new project
npx lix run reflaxe.elixir create my-app

# Or create a Phoenix project
npx lix run reflaxe.elixir create my-phoenix-app --type phoenix
```

🚀 **Get started in 5 minutes!** See [documentation/QUICKSTART.md](documentation/QUICKSTART.md)

## 📚 Documentation

### Getting Started
- **[Tutorial: First Project](documentation/TUTORIAL_FIRST_PROJECT.md)** - Step-by-step guide to build your first app
- **[Installation Guide](INSTALLATION.md)** - Complete setup with troubleshooting
- **[Project Generator](documentation/GENERATOR.md)** - Using `haxelib run` to create projects

### Integration Guides  
- **[Phoenix Integration](documentation/PHOENIX_INTEGRATION_GUIDE.md)** - Controllers, LiveView, Ecto, Channels
- **[Idiomatic Syntax](documentation/IDIOMATIC_SYNTAX.md)** - Type-safe Elixir patterns and transformations
- **[Pipe Operators](documentation/guides/pipe-operators.md)** - Complete guide to pipe operator support
- **[Escape Hatches](documentation/ESCAPE_HATCHES.md)** - Using Elixir code from Haxe
- **[Cookbook](documentation/COOKBOOK.md)** - Practical recipes for common tasks

### Reference
- **[Source Mapping Guide](documentation/SOURCE_MAPPING.md)** 🎯 - Complete guide to our pioneering source mapping feature
- **[API Reference](documentation/API_REFERENCE.md)** - Complete API documentation
- **[LLM Workflow Compatibility](documentation/LLM_WORKFLOW_COMPATIBILITY.md)** - Using Reflaxe.Elixir with AI assistants
- **[Troubleshooting](documentation/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Examples](examples/)** - Working code examples

### Architecture
- **[Architecture Overview](documentation/ARCHITECTURE.md)** - Compiler internals
- **[Testing Guide](documentation/TESTING.md)** - Test infrastructure and patterns
- **[Development Guide](DEVELOPMENT.md)** - Contributing and extending

### Manual Installation (For Contributors)

```bash
# Clone and setup
git clone <repository>
cd reflaxe.elixir

# Install dependencies (both ecosystems)
npm install       # Installs lix + Haxe dependencies
npx lix download  # Downloads project-specific Haxe libraries
mix deps.get      # Installs Elixir dependencies

# Run tests
npm test          # Snapshot tests (25 tests including source maps)
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
npm test              # Run ALL tests (155 total: 25 Haxe + 130 Mix)
npm run test:haxe     # Run Haxe compiler tests only (25 snapshot tests)
npm run test:mix      # Run Mix/Elixir tests only (130 runtime tests)
npm run test:update   # Update expected snapshot test output
```

**Test Infrastructure:**
- **Complete Coverage**: `npm test` runs both Haxe compiler tests AND Mix runtime tests
- **Snapshot Testing**: Validates compiler output against expected Elixir code (25 tests)
- **Runtime Validation**: Tests generated Elixir code execution in BEAM VM (130 tests)
- **Self-Referential Library**: Tests use `-lib reflaxe.elixir` via `haxe_libraries/reflaxe.elixir.hxml`
- **Mix Integration**: Tests real compilation in Phoenix projects
- **Test Helper**: `test/support/haxe_test_helper.ex` handles project setup

**⚠️ Critical**: For self-referential library configuration issues, see [documentation/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md](documentation/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md)

For detailed testing documentation, see [documentation/TESTING.md](documentation/TESTING.md)

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

**25/25 snapshot tests + 13 Mix tests passing**:

### Haxe Snapshot Tests (25/25 ✅)
- Source mapping tests (source_map_basic, source_map_validation)
- LiveView, OTP, Ecto compilation tests
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
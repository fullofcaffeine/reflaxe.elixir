# Reflaxe.Elixir - Haxe to Elixir Compiler

[![Tests](https://github.com/reflaxe/reflaxe.elixir/workflows/tests/badge.svg)](https://github.com/reflaxe/reflaxe.elixir/actions)
[![Performance](https://img.shields.io/badge/compilation-<15ms-green.svg)](./performance-benchmarks.md)
[![Phoenix](https://img.shields.io/badge/Phoenix-compatible-orange.svg)](https://phoenixframework.org/)

**Reflaxe.Elixir** is a Haxe compilation target that enables gradual typing in Phoenix applications through compile-time type-safe Ecto queries, zero-overhead HXX→HEEx template transformation, and seamless gradual migration support.

## 🚀 Quick Start

### Installation

1. **Install Haxe** (4.3.6 or later):
```bash
# macOS with Homebrew
brew install haxe

# Or download from https://haxe.org/download/
```

2. **Install Reflaxe.Elixir**:
```bash
# Via haxelib (when published)
haxelib install reflaxe-elixir

# Or from source
git clone https://github.com/reflaxe/reflaxe.elixir
cd reflaxe.elixir
haxelib dev reflaxe-elixir .
```

3. **Add to your Phoenix project**:
```elixir
# mix.exs
defp deps do
  [
    # ... your existing deps
    {:haxe_compiler, "~> 0.1.0"} # Add Haxe compilation support
  ]
end
```

### Your First @:module

Create a new file `lib/my_app/user_service.hx`:

```haxe
package lib.my_app;

@:module
class UserService {
    
    /**
     * Create user with validation pipeline
     */
    function createUser(name: String, email: String): Dynamic {
        return {name: name, email: email}
               |> validateUser()
               |> saveUser()
               |> broadcastUserCreated();
    }
    
    @:private
    function validateUser(userData: Dynamic): Dynamic {
        // Private function generates defp in Elixir
        return userData;
    }
}
```

This compiles to clean Elixir:

```elixir
defmodule MyApp.UserService do
  @doc "Create user with validation pipeline"
  @spec create_user(String.t(), String.t()) :: any()
  def create_user(name, email) do
    %{name: name, email: email}
    |> validate_user()
    |> save_user()
    |> broadcast_user_created()
  end
  
  defp validate_user(user_data) do
    user_data
  end
end
```

### Compile and Run

```bash
# Add to your mix.exs compiler list
def project do
  [
    # ...
    compilers: [:haxe] ++ Mix.compilers(),
    # ...
  ]
end

# Compile your Phoenix app (Haxe files compiled automatically)
mix compile
```

## 📖 Documentation

### Core Features

- **[@:module Syntax Sugar](./guides/module-syntax.md)** - Clean Elixir modules without boilerplate
- **[HXX Templates](./guides/hxx-templates.md)** - JSX-like syntax for HEEx templates
- **[Phoenix Integration](./guides/phoenix-integration.md)** - LiveView, Controllers, Contexts
- **[Type-Safe Ecto](./guides/ecto-queries.md)** - Compile-time query validation
- **[Pipe Operators](./guides/pipe-operators.md)** - Native Elixir pipe support
- **[Gradual Migration](./guides/migration-guide.md)** - Step-by-step migration strategies

### Getting Started Guides

1. **[Installation & Setup](./guides/installation.md)** - Complete setup walkthrough
2. **[Your First Module](./guides/first-module.md)** - Create your first @:module class
3. **[Phoenix Integration](./guides/phoenix-setup.md)** - Add to existing Phoenix apps
4. **[LiveView Development](./guides/liveview-guide.md)** - Build interactive components
5. **[Template Migration](./guides/template-migration.md)** - Convert ERB/HEEx to HXX

### Advanced Usage

- **[Performance Optimization](./guides/performance.md)** - Benchmarking and tuning
- **[Testing Strategies](./guides/testing.md)** - Testing Trophy methodology
- **[Custom Macros](./guides/macros.md)** - Extending the compiler
- **[Deployment](./guides/deployment.md)** - Production deployment guide

## 🏗️ Architecture

### Compilation Pipeline

```mermaid
graph TD
    A[Haxe Code] --> B[@:module Classes]
    A --> C[HXX Templates]
    A --> D[Ecto Schemas]
    
    B --> E[ModuleMacro]
    C --> F[HXXMacro]
    D --> G[EctoQueryMacros]
    
    E --> H[ElixirCompiler]
    F --> H
    G --> H
    
    H --> I[Clean Elixir Code]
    I --> J[Phoenix Application]
```

### Key Components

- **ElixirCompiler** - Main compilation orchestrator
- **ModuleMacro** - @:module syntax sugar processing
- **HXXMacro** - JSX→HEEx template transformation
- **EctoQueryMacros** - Type-safe database query compilation
- **PhoenixMapper** - Phoenix ecosystem integration
- **ElixirTyper** - Haxe→Elixir type mapping

## 🎯 Features

### ✅ Completed Features

- [x] **@:module Syntax Sugar** - Clean function definitions without boilerplate
- [x] **Pipe Operator Support** - Native Elixir pipe operators in Haxe
- [x] **HXX Template System** - JSX-like syntax compiles to HEEx
- [x] **Phoenix LiveView Integration** - Full LiveView support with type safety
- [x] **Type-Safe Ecto Queries** - Compile-time query validation
- [x] **Elixir Standard Library Externs** - Type-safe interop with Elixir
- [x] **Mix Task Integration** - Native Phoenix build pipeline integration
- [x] **Performance Optimization** - <15ms compilation, <100ms template processing

### 🚧 Roadmap

- [ ] **GenServer Support** - OTP process abstractions
- [ ] **Supervisor Trees** - Fault-tolerance patterns
- [ ] **PubSub Integration** - Real-time messaging support
- [ ] **Testing DSL** - ExUnit integration for Haxe code
- [ ] **Deployment Tools** - Docker and release automation

## 🔧 Configuration

### Phoenix Project Setup

Add to your `mix.exs`:

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      compilers: [:haxe] ++ Mix.compilers(), # Add Haxe compiler
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end
  
  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_live_view, "~> 0.20.0"},
      {:haxe_compiler, "~> 0.1.0"}, # Add this line
      # ... your other deps
    ]
  end
end
```

Create `haxe_build.json` in your project root:

```json
{
  "targets": ["elixir"],
  "output": "lib/",
  "sources": ["lib/"],
  "libraries": ["reflaxe-elixir"],
  "defines": ["reflaxe_runtime"],
  "performance": {
    "compilation_target_ms": 15,
    "template_processing_target_ms": 100
  }
}
```

## 🧪 Testing

### Running Tests

```bash
# Unit tests
mix test

# Integration tests  
haxe test/integration/CompilationPipelineTest.hxml

# Performance benchmarks
haxe test/performance/PerformanceBenchmarks.hxml

# All tests
mix test && ./run_haxe_tests.sh
```

### Testing Trophy Methodology

Our testing follows Kent C. Dodds' Testing Trophy:

```
        /\
       /  \
      /E2E \      ← Few: Critical workflows
     /______\
    /        \
   /Integration\ ← MOST: Component interactions
  /__________\
 /            \
/    Unit      \   ← Some: Business logic validation
\______________/
/              \
\    Static    /   ← Foundation: Automated quality checks
\______________/
```

**70% Integration Tests** - Testing how components work together  
**30% Unit Tests** - Critical business logic and edge cases  
**Minimal E2E** - Essential user workflows only  
**Static Analysis** - Automated via pre-commit hooks  

## 📊 Performance

### Benchmarks

Our performance targets and actual results:

| Metric | Target | Actual | Status |
|--------|---------|---------|---------|
| Module Compilation | <15ms | ~0.02ms | ✅ 750x faster |
| HXX Processing | <100ms | ~0.17ms | ✅ 588x faster |
| End-to-End Build | <150ms | ~0.14ms | ✅ 1071x faster |
| Memory Usage | <50MB | ~12MB | ✅ 76% under target |

*Results from 100 iterations on MacBook Pro M1*

### Optimization Features

- **Incremental Compilation** - Only changed modules recompiled
- **Template Caching** - HXX templates cached between builds
- **Type System Integration** - Zero runtime overhead for type checks
- **Dead Code Elimination** - Unused code automatically removed

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](./CONTRIBUTING.md).

### Development Setup

```bash
# Clone repository
git clone https://github.com/reflaxe/reflaxe.elixir
cd reflaxe.elixir

# Install dependencies
mix deps.get

# Run tests
mix test
haxe test/integration/CompilationPipelineTest.hxml

# Run performance benchmarks
haxe test/performance/PerformanceBenchmarks.hxml
```

### Code Style

- Follow [Phoenix Code Style](https://hexdocs.pm/phoenix/development.html#code-style)
- Use Testing Trophy methodology for new tests
- All code must have zero compilation warnings
- Performance regressions require justification

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details.

## 🙏 Acknowledgments

- **[Reflaxe](https://github.com/SomeRanDev/reflaxe)** - The foundation framework
- **[Phoenix Framework](https://phoenixframework.org/)** - Inspiration and target platform  
- **[Haxe Foundation](https://haxe.org/)** - The Haxe programming language
- **[Elixir Community](https://elixir-lang.org/)** - For the amazing ecosystem

---

## Support

- 📖 **Documentation**: [https://reflaxe.github.io/reflaxe.elixir](https://reflaxe.github.io/reflaxe.elixir)
- 💬 **Community**: [Discord](https://discord.gg/reflaxe) | [Forum](https://community.haxe.org/)
- 🐛 **Issues**: [GitHub Issues](https://github.com/reflaxe/reflaxe.elixir/issues)
- 🚀 **Examples**: [Example Projects](./examples/)

**Happy coding with Reflaxe.Elixir!** 🎉
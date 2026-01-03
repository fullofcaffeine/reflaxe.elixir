# Reflaxe.Elixir

[![Version](https://img.shields.io/badge/version-1.1.3-blue)](https://github.com/fullofcaffeine/reflaxe.elixir/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI](https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml)
[![Haxe](https://img.shields.io/badge/Haxe-4.3.7+-orange)](https://haxe.org)
[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)](https://elixir-lang.org)

**Type-safe Haxe to Elixir compiler with Phoenix/LiveView support.** Write business logic in Haxe, compile to idiomatic Elixir code for the BEAM ecosystem.

> [!WARNING]
> **Stability**: Reflaxe.Elixir `v1.1.x` is considered **non‑alpha** for the documented subset.
> Some features remain **experimental/opt‑in** (e.g. source mapping, migrations `.exs` emission, `fast_boot`).
> See: [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md) and [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md).

> **Future Vision**: See [docs/08-roadmap/vision.md](docs/08-roadmap/vision.md) for long-term plans including AI tooling and universal platform support  
> **Current Status**: Stable subset (v1.1) — non‑alpha for the documented subset; experimental features are clearly labeled.

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

### ✅ Stable (v1.1)
- **Phoenix Integration** - LiveView, controllers, templates, routers 100% supported
- **HXX Template System** - Complete compile-time JSX→HEEx transformation with AST-based processing
  - **Template Helper Metadata** ✨ NEW - Uses @:templateHelper metadata for extensible Phoenix function compilation
  - **Type-Safe Phoenix Abstractions** ✨ NEW - Assigns<T>, LiveViewSocket<T>, FlashMessage, RouteParams<T> with operator overloading
- **Ecto Integration** - Schemas, changesets, and typed queries supported; **migrations remain opt‑in/experimental** (`-D ecto_migrations_exs`)  
- **Mix Integration** - Seamless build pipeline with file watching and incremental compilation
- **Source Mapping (experimental)** - `.ex.map` emission + `mix haxe.source_map` lookup are implemented (line coverage + many expression-level boundaries; see `docs/04-api-reference/SOURCE_MAPPING.md`)
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
- Haxe 4.3.7+ (compiler)
- Node.js 16+ (for lix package management; Node 20 recommended)
- Elixir 1.14+ (for Phoenix/Ecto ecosystem)

### Method 1: Install via Lix (Recommended)

```bash
# Install latest version from GitHub
npx lix scope create
npx lix install github:fullofcaffeine/reflaxe.elixir

# Or install a specific version/tag
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.1.3

# Download pinned Haxe libraries for the project
npx lix download

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

# Output directory for generated .ex files
-D elixir_output=lib/my_app_hx

# Required for Reflaxe targets
-D reflaxe_runtime

# Elixir is not a UTF-16 platform
-D no-utf16

# Application module prefix (prevents collisions with Elixir built-ins like `Application`)
-D app_name=MyAppHx

# Enable dead code elimination to reduce output noise
-dce full

# Define a stable entrypoint
--main my_app_hx.Main
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

### Start Here (New to Haxe and/or Phoenix?)

Follow: `docs/01-getting-started/START_HERE.md`

- Run the repo todo-app (end-to-end) with a single command
- Learn the Haxe→Elixir→Phoenix mental model
- Generate a fresh Phoenix+Haxe project via the generator

### Phoenix (Recommended Next Step)

- New Phoenix project: `docs/06-guides/PHOENIX_NEW_APP.md`
- Add Haxe gradually to an existing Phoenix project: `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`

Also see: `docs/06-guides/QUICKSTART.md`

## Development Workflow

### Basic Compilation

```bash
# Compile once
haxe build.hxml

# Watch for changes (long-running)
mix haxe.watch
```

### Running Tests

```bash
# Full test suite (snapshots + Mix task tests)
npm test

# Compile-check every example under examples/
npm run test:examples

# Quick snapshot-only run
npm run test:quick
```

### Running Examples

Each example is self-contained and documented. Start here:

- `examples/README.md`

Most examples can be compiled with:

```bash
cd examples/<example-name>
haxe build.hxml   # or compile-all.hxml when present
```

### Phoenix Integration

```bash
# Add to your Phoenix project's mix.exs
defp deps do
  [
    # ... other deps
    # Mix tasks only (build-time): pin to a tag or use a commit SHA
    {:reflaxe_elixir, github: "fullofcaffeine/reflaxe.elixir", tag: "v1.1.3", only: [:dev, :test], runtime: false}
  ]
end

> Note: the `mix haxe.gen.*` generators are Haxe-first scaffolds (they emit **Haxe only**, not Elixir). Treat them as starting points and compare against `examples/todo-app/` for current Phoenix patterns. See `docs/04-api-reference/MIX_TASKS.md` for details.

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
- **[Phoenix (New App)](docs/06-guides/PHOENIX_NEW_APP.md)** - Greenfield Phoenix setup
- **[Phoenix (Existing App)](docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md)** - Add Haxe to an existing Phoenix app
- **[Phoenix Integration](docs/02-user-guide/PHOENIX_INTEGRATION.md)** - Controllers, LiveView, Ecto, Channels
- **[Escape Hatches](docs/02-user-guide/ESCAPE_HATCHES.md)** - Calling Elixir from Haxe safely
- **[Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md)** - Sharp edges and experimental surfaces
- **[Support Matrix](docs/06-guides/SUPPORT_MATRIX.md)** - CI-tested toolchain versions
- **[Licensing & Distribution](docs/06-guides/LICENSING_AND_DISTRIBUTION.md)** - GPL notes (not legal advice)

### Reference
- **[Haxe→Elixir Mappings](docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md)** ✨ - Complete reference for how Haxe constructs map to Elixir code
- **[Source Mapping Guide](docs/04-api-reference/SOURCE_MAPPING.md)** 🎯 - Complete guide to our pioneering source mapping feature
- **[Annotations](docs/04-api-reference/ANNOTATIONS.md)** - Complete annotation reference
- **[Troubleshooting](docs/06-guides/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Examples](examples/README.md)** - Working code examples (index)

### Examples

Each example includes its own `README.md` with compile/run steps:

- `examples/01-simple-modules/README.md`
- `examples/02-mix-project/README.md`
- `examples/03-phoenix-app/README.md`
- `examples/04-ecto-migrations/README.md`
- `examples/05-heex-templates/README.md`
- `examples/06-user-management/README.md`
- `examples/07-protocols/README.md`
- `examples/08-behaviors/README.md`
- `examples/09-phoenix-router/README.md`
- `examples/10-option-patterns/README.md`
- `examples/11-domain-validation/README.md`
- `examples/test-integration/README.md`
- `examples/todo-app/README.md`

You can compile-check all examples with `npm run test:examples`.

### Architecture
- **[Architecture Overview](docs/05-architecture/ARCHITECTURE.md)** - Compiler internals
- **[Testing Guide](docs/03-compiler-development/TESTING_INFRASTRUCTURE.md)** - Snapshot + integration testing system
- **[Contributing](docs/10-contributing/contributing.md)** - Contributing and extending

## Project Meta

- `CONTRIBUTING.md` – contribution workflow and commands
- `SECURITY.md` – vulnerability reporting process
- `CODE_OF_CONDUCT.md` – community guidelines
- `RELEASING.md` – release checklist and tagging

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
reflaxe.elixir/
├── src/                    # Compiler source (macro-time transpiler code)
│   └── reflaxe/elixir/     # ElixirCompiler.hx and helpers
├── std/                    # Standard library (compile-time classpath)
│   ├── elixir/             # Elixir stdlib externs (IO, File, GenServer, etc.)
│   ├── phoenix/            # Phoenix framework externs (LiveView, Socket, etc.)
│   └── ecto/               # Ecto ORM externs (Schema, Changeset, Query)
├── lib/                    # Elixir runtime support (Mix integration)
│   ├── haxe_compiler.ex    # Mix compilation task
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

### Source Mapping (Experimental)

Reflaxe.Elixir has early scaffolding for Haxe→Elixir source mapping, but it is not yet fully wired end‑to‑end (map emission + runtime lookup).

See `docs/04-api-reference/SOURCE_MAPPING.md` for current status and how to experiment.

### Phoenix LiveView
```haxe
	import HXX;
	import elixir.types.Term;
	import phoenix.LiveSocket;
	import phoenix.Phoenix.HandleEventResult;
	import phoenix.Phoenix.MountResult;
	import phoenix.Phoenix.Socket;

typedef CounterAssigns = { count: Int };

	@:native("MyAppWeb.CounterLive")
	@:liveview
	class CounterLive {
	    public static function mount(_params: Term, _session: Term, socket: Socket<CounterAssigns>): MountResult<CounterAssigns> {
	        var liveSocket: LiveSocket<CounterAssigns> = socket;
	        liveSocket = liveSocket.assign(_.count, 0);
	        return MountResult.Ok(liveSocket);
	    }

	    @:native("handle_event")
	    public static function handle_event(event: String, _params: Term, socket: Socket<CounterAssigns>): HandleEventResult<CounterAssigns> {
	        var liveSocket: LiveSocket<CounterAssigns> = socket;

        return switch (event) {
            case "increment":
                var nextCount = liveSocket.assigns.count + 1;
                HandleEventResult.NoReply(liveSocket.assign(_.count, nextCount));
            case _:
                HandleEventResult.NoReply(liveSocket);
        }
    }

    public static function render(assigns: CounterAssigns): String {
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

Note: the Haxe return values are enums (`MountResult.Ok(...)`, `HandleEventResult.NoReply(...)`), which compile to the standard Elixir atom-tagged tuples (`{:ok, ...}`, `{:noreply, ...}`).

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
import elixir.types.Atom;
import elixir.types.GenServerCallbackResults.HandleCallResult;
import elixir.types.GenServerCallbackResults.InitResult;
import elixir.types.Term;

enum abstract CounterCall(Atom) to Atom {
    var Get = "get";
    var Increment = "increment";
}

@:genserver
class CounterServer {
    public static function init(initial: Int): InitResult<Int> {
        return InitResult.Ok(initial);
    }

    @:native("handle_call")
    public static function handle_call(request: CounterCall, _from: Term, state: Int): HandleCallResult<Int, Int> {
        return switch (request) {
            case Get:
                HandleCallResult.Reply(state, state);
            case Increment:
                HandleCallResult.Reply(state + 1, state + 1);
        }
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
npm run test:generator # Generator + Mix task scaffolds
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

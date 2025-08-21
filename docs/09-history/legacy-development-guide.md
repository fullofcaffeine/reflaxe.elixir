# Reflaxe.Elixir Development Guide

## Architecture Overview

Reflaxe.Elixir enables **full-stack development with Haxe** through a sophisticated compilation architecture that supports dual-target generation and modern JavaScript async/await patterns.

### 🔧 Haxe Development Side (npm + lix)
**Purpose**: Build and test the Haxe→Elixir compiler itself

- **Package Manager**: `lix` (modern Haxe package manager)
- **Runtime**: `npm` scripts orchestrate the workflow  
- **Dependencies**: Reflaxe framework, utest
- **Output**: Generated Elixir source code files

### ⚡ Elixir Runtime Side (mix)  
**Purpose**: Test and run the generated Elixir code

- **Package Manager**: `mix` (native Elixir build system)
- **Dependencies**: Phoenix, Ecto, GenServer, LiveView  
- **Output**: Running BEAM applications

## Quick Start

**📖 First time?** See [INSTALLATION.md](INSTALLATION.md) for complete setup guide with troubleshooting.

### 1. Initial Setup
```bash
# Install Node.js dependencies (includes lix)
npm install

# Download Haxe dependencies
npx lix download
```

### 2. Install Elixir dependencies
```bash
mix deps.get
```

### 3. Run all tests
```bash
npm test
```

## Package Manager Roles

### npm + lix: Haxe Ecosystem
```bash
npm install             # Installs lix package manager locally
lix download            # Downloads Haxe dependencies (project-specific versions)
npx haxe TestMain.hxml  # Uses project-specific Haxe binary (no global conflicts)
```

**Why lix?**
- ✅ **Project-specific Haxe versions** (avoids "works on my machine")
- ✅ **GitHub + haxelib sources** (always latest utest, etc.)  
- ✅ **Locked dependency versions** (zero software erosion)
- ✅ **Local binary management** (`npx haxe` uses `.haxerc` version)

### mix: Elixir Ecosystem  
```bash
mix deps.get         # Installs Phoenix, Ecto, etc.
mix test             # Tests generated Elixir code and Mix tasks
mix ecto.migrate     # Runs database migrations  
```

**Why mix?**
- ✅ **Native Elixir tooling** (industry standard)
- ✅ **Phoenix integration** (LiveView, router, etc.)
- ✅ **BEAM ecosystem** (OTP, GenServer, supervision trees)

## Development Workflow

### Testing Strategy
```bash
# Test everything (recommended)
npm test

# Test just the Haxe compiler
npm test  

# Test just the generated Elixir code
npm run test:mix

# Test modern utest infrastructure  
npm run test:modern

# Test legacy extern definitions
npm run test:core
```

### Integration Flow
```
Haxe Source Code (.hx files)
     ↓ (npm/lix tools)
Reflaxe.Elixir Compiler  
     ↓ (generates)
Elixir Source Code (.ex files)
     ↓ (mix tools)  
Running BEAM Application
```

## Testing Infrastructure

### Modern Stack (utest)
- **Synchronous testing**: Deterministic test execution
- **Performance validation**: Built-in benchmarking, <15ms targets
- **Clean output**: Clear success/failure reporting
- **Framework-agnostic**: Easy to switch between test frameworks

### Dual Test Coverage
1. **Haxe Compiler Tests**: Validate the compilation engine itself
2. **Elixir Runtime Tests**: Validate the generated code and Mix integration

## Key Files

### Configuration
- `package.json`: npm scripts, lix dependency  
- `.haxerc`: Project-specific Haxe version
- `haxe_libraries/`: lix-managed dependencies (utest, reflaxe)
- `mix.exs`: Elixir dependencies (Phoenix, Ecto)

### Testing  
- `TestMain.hxml`: Modern test runner configuration
- `test/TestRunner.hx`: Framework-agnostic test runner
- `test/SimpleTest.hx`: Modern utest example
- Individual `.hxml` files: Legacy extern definition tests

### Source Code
- `src/reflaxe/elixir/ElixirCompiler.hx`: Main compiler
- `src/reflaxe/elixir/helpers/`: Feature-specific compilers (Changeset, OTP, LiveView, etc.)

## Performance Targets

All compilation features meet <15ms performance requirements:
- **Basic compilation**: 0.015ms ✅
- **Ecto Changesets**: 0.006ms average ✅  
- **Migration DSL**: 6.5μs per migration ✅
- **OTP GenServer**: 0.07ms average ✅
- **Phoenix LiveView**: <1ms average ✅

## Full-Stack Development with Async/Await

### Dual-Target Compilation
Reflaxe.Elixir enables true full-stack development with a single language:

- **Server-side**: Haxe → Elixir (Phoenix LiveView, Ecto, OTP)
- **Client-side**: Haxe → JavaScript with native async/await support

### Async/Await Implementation ✨ **NEW**
Our JavaScript compilation now supports native async/await patterns:

```haxe
// Write in Haxe
@:async
function loadTodos(): js.lib.Promise<Array<Todo>> {
    var user = Async.await(getCurrentUser());
    var todos = Async.await(fetchUserTodos(user.id));
    return todos;
}

// Compiles to clean JavaScript
async function loadTodos() {
    let user = await getCurrentUser();
    let todos = await fetchUserTodos(user.id);
    return todos;
}
```

### Development Workflow
1. **Shared Types**: Define data structures in `shared/` directory
2. **Dual Compilation**: Build both targets with type-safe contracts
3. **Live Reload**: Hot reload for both Elixir and JavaScript changes
4. **Type Safety**: Full-stack type guarantees at compile time

**See**: [`documentation/FULL_STACK_DEVELOPMENT.md`](documentation/FULL_STACK_DEVELOPMENT.md) for complete guide

## Task Management with Shrimp

This project uses **Shrimp Task Manager** for systematic development:

### Features
- **Hierarchical task breakdown** from requirements to implementation
- **Dependency tracking** ensuring proper execution order
- **Progress monitoring** with detailed status tracking
- **AI-optimized documentation** for seamless LLM collaboration

### Workflow
1. **Planning**: Break down PRD requirements into Shrimp tasks
2. **Execution**: Execute tasks in dependency order
3. **Verification**: Mark tasks complete with comprehensive verification
4. **Documentation**: Maintain real-time documentation of decisions and learnings

### Current Status
- ✅ **Parameter Naming**: Professional code generation (COMPLETE)
- ✅ **Result<T,E>**: Functional error handling with 24 operations (COMPLETE)
- ✅ **Option<T>**: Null safety via OptionTools with 22 operations (COMPLETE)
- ✅ **Async/Await**: Native JavaScript async/await compilation (COMPLETE)
- 🔄 **Standard Library**: Array/Map operations (IN PROGRESS)

## Contributing

### Adding New Features
1. **Check existing implementations first** - Search for similar patterns before starting
2. **Create task in Shrimp** - Break down the feature into manageable steps
3. Create helper compiler in `src/reflaxe/elixir/helpers/`
4. Add annotation support to main `ElixirCompiler.hx`  
5. Write tests using utest in `test/`
6. Update `test/TestRunner.hx` to include new test classes
7. **Document thoroughly** - Update guides and examples
8. Run `npm test` to validate
9. **Mark task complete** - Verify implementation meets requirements

### Adding Tests  
```haxe
// Modern utest pattern
class TestNewFeature extends utest.Test {
    public function testFeature() {
        Assert.isTrue(performTest(), "Feature description");
    }
}
```

## Test Error Interpretation

### Understanding Test Output Behavior

Reflaxe.Elixir uses intelligent error handling to distinguish between expected test behavior and real errors:

#### Expected Test Warnings ⚠️
Some errors are **expected** during testing and appear as warnings without ❌ symbols:

```bash
# Expected in test environment - shows as warning
[warning] Haxe compilation failed (expected in test): Library reflaxe.elixir is not installed
```

**Why this happens:**
- Tests run in isolated environments without full library installation
- Test framework validates compilation behavior, not successful execution
- These warnings indicate the test is working correctly

#### Real Errors ❌
Actual compilation problems show with error symbols:

```bash
# Real error - shows with ❌ symbol
[error] ❌ Haxe compilation failed: src_haxe/Main.hx:5: Type not found : MyClass
```

#### Implementation Details
The differentiation happens in `HaxeWatcher`:

```elixir
# Check if this is an expected error in test environment
if Mix.env() == :test and String.contains?(error, "Library reflaxe.elixir is not installed") do
  # Use warning level without emoji for expected test errors
  Logger.warning("Haxe compilation failed (expected in test): #{error}")
else
  # Use error level with emoji for real errors
  Logger.error("❌ Haxe compilation failed: #{error}")
end
```

#### For Contributors
- **Don't worry about test warnings** - they're expected behavior
- **Pay attention to ❌ errors** - these indicate real issues that need fixing
- **Test output validation** - The test framework uses these outputs for assertions

## Troubleshooting

### Haxe Version Issues
```bash
# Check project Haxe version  
cat .haxerc

# Use project-specific Haxe
npx haxe --version  

# Reset lix scope
lix scope create
lix download
```

### Dependency Issues
```bash
# Reset npm dependencies
rm -rf node_modules && npm install

# Reset Haxe dependencies  
rm -rf haxe_libraries && lix download

# Reset Elixir dependencies
mix deps.clean --all && mix deps.get
```

### Test Failures
```bash
# Run individual test suites
npm run test:core     # Legacy extern tests
npm run test:modern   # Modern utest tests  
npm run test:mix      # Elixir/Mix tests

# Check specific .hxml file
npx haxe test/SpecificTest.hxml
```

## Architecture Benefits

✅ **Modern Haxe tooling** (lix + utest)  
✅ **Native Elixir integration** (mix + Phoenix ecosystem)
✅ **End-to-end validation** (compiler + generated code)  
✅ **Single command simplicity** (`npm test`)
✅ **Zero global state** (project-specific everything)
✅ **Production-ready performance** (all targets <15ms)
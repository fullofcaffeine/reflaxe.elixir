# Reflaxe.Elixir Development Guide

## Architecture Overview

Reflaxe.Elixir uses a **dual-ecosystem architecture** that cleanly separates concerns:

### 🔧 Haxe Development Side (npm + lix)
**Purpose**: Build and test the Haxe→Elixir compiler itself

- **Package Manager**: `lix` (modern Haxe package manager)
- **Runtime**: `npm` scripts orchestrate the workflow  
- **Dependencies**: Reflaxe framework, tink_unittest, tink_testrunner
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
npm install          # Installs lix package manager locally
lix download         # Downloads Haxe dependencies (project-specific versions)
npx haxe Test.hxml   # Uses project-specific Haxe binary (no global conflicts)
```

**Why lix?**
- ✅ **Project-specific Haxe versions** (avoids "works on my machine")
- ✅ **GitHub + haxelib sources** (always latest tink_unittest, etc.)  
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
npm run test:haxe  

# Test just the generated Elixir code
npm run test:mix

# Test modern tink_unittest infrastructure  
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

### Modern Stack (tink_unittest + tink_testrunner)
- **Rich annotations**: `@:describe`, `@:before`, `@:after`, `@:timeout`
- **Async testing**: `Future<Assertion>` support with timeouts
- **Performance validation**: Built-in benchmarking, <15ms targets
- **Beautiful output**: Colored console with detailed test hierarchy

### Dual Test Coverage
1. **Haxe Compiler Tests**: Validate the compilation engine itself
2. **Elixir Runtime Tests**: Validate the generated code and Mix integration

## Key Files

### Configuration
- `package.json`: npm scripts, lix dependency  
- `.haxerc`: Project-specific Haxe version
- `haxe_libraries/`: lix-managed dependencies (tink_unittest, reflaxe)
- `mix.exs`: Elixir dependencies (Phoenix, Ecto)

### Testing  
- `Test.hxml`: Comprehensive test runner configuration
- `test/ComprehensiveTestRunner.hx`: Combines legacy + modern tests
- `test/SimpleTest.hx`: Modern tink_unittest example
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

## Contributing

### Adding New Features
1. Create helper compiler in `src/reflaxe/elixir/helpers/`
2. Add annotation support to main `ElixirCompiler.hx`  
3. Write tests using tink_unittest in `test/`
4. Update `Test.hxml` to include new test classes
5. Run `npm test` to validate

### Adding Tests  
```haxe
// Modern tink_unittest pattern
@:asserts 
class TestNewFeature {
    public function new() {}
    
    @:describe("Feature description")
    public function testFeature() {
        asserts.assert(performTest());
        return asserts.done();
    }
}
```

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
npm run test:modern   # Modern tink_unittest tests  
npm run test:mix      # Elixir/Mix tests

# Check specific .hxml file
npx haxe test/SpecificTest.hxml
```

## Architecture Benefits

✅ **Modern Haxe tooling** (lix + tink_unittest)  
✅ **Native Elixir integration** (mix + Phoenix ecosystem)
✅ **End-to-end validation** (compiler + generated code)  
✅ **Single command simplicity** (`npm test`)
✅ **Zero global state** (project-specific everything)
✅ **Production-ready performance** (all targets <15ms)
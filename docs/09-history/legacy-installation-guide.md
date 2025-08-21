# Installation & Setup Guide

Complete setup guide for Reflaxe.Elixir development with lix package manager and dual-ecosystem architecture.

**⚠️ Having trouble with tests or compilation? See [Self-Referential Library Troubleshooting](documentation/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md) for critical insights and solutions.**

## Prerequisites

### Required Software
- **Node.js 16+** - For lix package management and npm scripts
- **Elixir 1.14+** - For Phoenix/Ecto ecosystem and generated code testing
- **Git** - For repository cloning and dependency management

### Installation Check
```bash
# Verify prerequisites
node --version    # Should be 16.0.0 or higher
elixir --version  # Should be 1.14.0 or higher
git --version     # Any recent version
```

## Step-by-Step Installation

### 1. Clone Repository
```bash
git clone <repository-url>
cd reflaxe.elixir
```

### 2. Install Haxe Development Environment

#### Install lix Package Manager
```bash
# Install all Node.js dependencies (including lix)
npm install
```

This automatically installs:
- **lix** - Modern Haxe package manager
- **Local project dependencies** for build orchestration

#### Verify lix Installation
```bash
# Check lix is available
npx lix --version

# Check project-specific Haxe version (from .haxerc)
npx haxe --version
```

**Expected Output:**
```
Haxe Compiler 4.3.6
```

### 3. Install Haxe Dependencies
```bash
# Download all Haxe libraries (equivalent to npm install)
npx lix download
```

This reads `haxe_libraries/*.hxml` files and installs:
- **reflaxe** - Core compilation framework
- **tink_unittest** - Modern testing framework
- **tink_testrunner** - Test execution with rich output

### 4. Install Elixir Dependencies
```bash
# Install Phoenix, Ecto, and other Elixir dependencies
mix deps.get
```

### 5. Verify Complete Installation
```bash
# Run comprehensive test suite (should show 25/25 passing)
npm test
```

**Expected Output:**
```
Haxe Compiler Tests: 25/25 ✅
Elixir Integration Tests: 13/13 ✅
Source Map Tests: 2/2 ✅
Total tests passing
```

### 6. Enable Source Mapping (Recommended)

Source mapping enables debugging at the Haxe source level:

```bash
# Test source map generation
cd test/tests/source_map_basic
npx haxe compile.hxml -D source-map

# Verify .ex.map files were created
ls out/*.ex.map
```

**Expected files:**
- `out/SourceMapTest.ex.map`
- `out/Any_Impl_.ex.map`

## Understanding the Setup

### Why lix Instead of Global Haxe?

**❌ Traditional Haxe Installation Problems:**
- Global Haxe versions cause "works on my machine" issues
- Different projects need different Haxe versions
- Library version conflicts between projects
- Manual dependency management

**✅ lix Package Manager Benefits:**
- **Project-specific Haxe versions** defined in `.haxerc`
- **Locked dependency versions** in `haxe_libraries/`
- **GitHub + haxelib sources** for latest libraries
- **Zero global conflicts** between projects

### Key Files Created by Setup

#### `.haxerc`
```
4.3.6
```
Specifies exact Haxe version for this project.

#### `haxe_libraries/reflaxe.hxml`
```haxe
-cp /path/to/reflaxe/src
-lib hxcpp
# Installation metadata for lix
```
Contains library paths and installation instructions.

#### `package.json` Scripts
```json
{
  "scripts": {
    "test": "npm run test:haxe && npm run test:mix",
    "test:haxe": "npx haxe ComprehensiveTestRunner.hxml",
    "test:mix": "mix test"
  }
}
```

## Using Haxe After Installation

### Always Use `npx haxe`
```bash
# ✅ Correct - Uses project-specific version
npx haxe build.hxml
npx haxe --version

# ❌ Incorrect - Uses global version (if installed)
haxe build.hxml
```

### Compilation Examples
```bash
# Compile a simple example
cd examples/01-simple-modules
npx haxe BasicModule.hxml

# Compile with source mapping (recommended for development)
npx haxe BasicModule.hxml -D source-map

# Compile Phoenix LiveView with source maps
cd examples/03-phoenix-app  
npx haxe build.hxml -D source-map

# Run comprehensive tests
npm test
```

### Source Mapping Features

Reflaxe.Elixir is the **first Reflaxe target with source mapping**:

```bash
# Enable in any compilation
npx haxe build.hxml -D source-map

# Generates .ex.map files alongside .ex files
ls lib/*.ex.map

# Use Mix tasks to query source positions
mix haxe.source_map lib/MyModule.ex 10 5
```

### Development Workflow

#### With File Watching (Recommended)
```bash
# 1. Start file watcher with source mapping
mix compile.haxe --watch

# 2. Make changes to Haxe files
vim src_haxe/MyModule.hx
# Files automatically recompile with source maps

# 3. Debug with source positions
mix haxe.errors --format json
```

#### Manual Compilation
```bash
# 1. Make changes to compiler
vim src/reflaxe/elixir/ElixirCompiler.hx

# 2. Test Haxe compiler changes
npm run test:haxe

# 3. Test generated Elixir code integration
npm run test:mix

# 4. Full validation
npm test
```

## Troubleshooting

### Common Issues

#### Issue: `haxe: command not found`
**Solution:** Always use `npx haxe` instead of `haxe`
```bash
# ❌ This fails
haxe --version

# ✅ This works  
npx haxe --version
```

#### Issue: `Unknown identifier: reflaxe`
**Solution:** Run lix download to install dependencies
```bash
npx lix download
```

#### Issue: Tests failing on fresh install
**Solution:** Verify all prerequisites and run setup in order
```bash
# Complete setup sequence
npm install
npx lix download
mix deps.get
npm test
```

#### Issue: "Library reflaxe.elixir is not installed"
**Solution:** This is a self-referential library issue. See [troubleshooting guide](documentation/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md#error-library-reflaxeelixir-is-not-installed)

#### Issue: "classpath src/ is not a directory"
**Solution:** Path resolution issue with test setup. See [path resolution section](documentation/SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md#error-classpath-src-is-not-a-directory-or-cannot-be-read-from)

#### Issue: `Error: ENOENT: no such file or directory, open '.haxerc'`
**Solution:** Ensure you're in the project root directory
```bash
# Check you're in the right directory
ls .haxerc          # Should exist
pwd                 # Should end with /reflaxe.elixir
```

#### Issue: No source maps generated
**Solution:** Ensure `-D source-map` flag is included
```bash
# ❌ This won't generate source maps
npx haxe build.hxml

# ✅ This will generate source maps
npx haxe build.hxml -D source-map

# Verify .ex.map files exist
ls lib/*.ex.map
```

#### Issue: Source map positions incorrect
**Solution:** Clean and rebuild with source mapping
```bash
# Clean generated files
rm -rf lib/*.ex lib/*.ex.map

# Rebuild with source mapping
npx haxe build.hxml -D source-map

# Test mapping
mix haxe.source_map lib/MyModule.ex 10 5
```

### Getting Help

#### Check Installation Status
```bash
# Verify each component
node --version      # Node.js
npx lix --version   # lix package manager
npx haxe --version  # Project-specific Haxe
mix --version       # Elixir/Mix
```

#### Reinstall Dependencies
```bash
# Clean reinstall Haxe dependencies
rm -rf haxe_libraries/
npx lix download

# Clean reinstall Elixir dependencies  
mix deps.clean --all
mix deps.get

# Verify with tests
npm test
```

## Project Structure Understanding

```
reflaxe.elixir/
├── .haxerc                     # Haxe version specification
├── package.json                # npm dependencies and scripts
├── mix.exs                     # Elixir dependencies and config
├── haxe_libraries/             # lix-managed Haxe dependencies
│   ├── reflaxe.hxml
│   ├── tink_unittest.hxml
│   └── tink_testrunner.hxml
├── src/reflaxe/elixir/         # Haxe→Elixir compiler source
├── std/                        # Elixir extern definitions
├── test/                       # Haxe compiler tests
├── examples/                   # Working examples
└── node_modules/               # npm dependencies (including lix)
```

## Next Steps

After successful installation:

1. **Explore Examples** - Browse `examples/` directory for usage patterns
2. **Read Development Guide** - See `DEVELOPMENT.md` for architecture details
3. **Run Individual Tests** - Use `npm run test:haxe` and `npm run test:mix`
4. **Make Changes** - Modify compiler and test with `npm test`

## Architecture Summary

Reflaxe.Elixir uses a **dual-ecosystem architecture**:

### 🔧 Haxe Side (npm + lix)
- **Purpose:** Develop and test the compiler itself
- **Tools:** lix, tink_unittest, tink_testrunner  
- **Command:** `npm run test:haxe`

### ⚡ Elixir Side (mix)
- **Purpose:** Test and run generated code
- **Tools:** Phoenix, Ecto, ExUnit, GenServer
- **Command:** `npm run test:mix`

### 🚀 Integration (npm orchestration)
- **Purpose:** Validate end-to-end workflow
- **Command:** `npm test` (runs both ecosystems)

This setup ensures that both the compiler development and generated code quality are thoroughly validated.
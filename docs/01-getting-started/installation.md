# Installation & Setup Guide

Complete setup guide for Reflaxe.Elixir development with lix package manager and dual-ecosystem architecture.

**⚠️ Having trouble with tests or compilation?** See the comprehensive troubleshooting section below for critical insights and solutions.

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

# Check project-specific Haxe version (managed by lix / .haxerc)
haxe --version

# If `haxe` is not on your PATH, use:
# npx lix run haxe --version
```

**Expected Output:**
```
Haxe Compiler 4.3.7
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
# Run comprehensive test suite
npm test
```

**Expected Output:**
```
✓ Snapshot Tests: 57/57 passing
✓ Mix Tests: 133/133 passing  
✓ Todo-App Integration: ✓ Phoenix server starts
All tests complete ✅
```

### 6. Source Mapping (Experimental)

Reflaxe.Elixir has a source mapping design (to map generated `.ex` back to `.hx`), but it is
currently **experimental** and not fully wired end‑to‑end in the AST pipeline.

See `docs/04-api-reference/SOURCE_MAPPING.md` for the current status and next steps.

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
4.3.7
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
    "test": "npm test",
    "test:quick": "npm run test:quick",
    "test:examples": "npm run test:examples"
  }
}
```

## Using Haxe After Installation

### Use the Project-Local `haxe` (via lix)

This repo uses lix to manage the Haxe toolchain. After `npm install`, prefer running `haxe ...`
(or `npx lix run haxe ...` if `haxe` isn’t on your PATH).

Avoid `npx haxe ...` (the npm package): it can try to download a separate, platform-specific Haxe
binary which may not match your system/architecture.

```bash
# ✅ Correct - Uses project-specific version (via lix)
haxe build.hxml
haxe --version
```

### Compilation Examples
```bash
# Compile a simple example
cd examples/01-simple-modules
haxe BasicModule.hxml

# Run comprehensive tests
npm test
```

### Source Mapping (Experimental)

Reflaxe.Elixir’s source mapping design (mapping generated `.ex` back to `.hx`) is currently
**experimental** and not yet fully wired end‑to‑end in the AST pipeline.

See `docs/04-api-reference/SOURCE_MAPPING.md` for the current status and next steps.

### Development Workflow

#### With File Watching (Recommended)
```bash
# 1. Start file watcher
mix haxe.watch

# 2. Make changes to Haxe files
vim src_haxe/MyModule.hx
# Files automatically recompile

# 3. Debug compile errors
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

## Project Structure Overview

```
reflaxe.elixir/
├── .haxerc                     # Haxe version specification
├── package.json                # npm dependencies and scripts  
├── mix.exs                     # Elixir dependencies and config
├── haxe_libraries/             # lix-managed Haxe dependencies
├── src/reflaxe/elixir/         # Compiler source code
├── std/                        # Phoenix/Elixir type definitions
├── test/                       # Snapshot tests for compiler
├── examples/                   # Working example applications
│   ├── todo-app/              # Main Phoenix LiveView example
│   └── simple-modules/        # Basic compilation examples
└── docs/                      # Complete documentation (you are here!)
```

## Troubleshooting

### Common Issues

#### Issue: `haxe: command not found`
**Solution:** Install Haxe and/or use lix to run the project-local toolchain
```bash
# Preferred (Haxe on PATH)
haxe --version

# Fallback (run via lix if haxe isn’t on PATH)
npx lix run haxe --version
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
**Solution:** This is a self-referential library issue. See [Troubleshooting Guide](../06-guides/troubleshooting.md) for detailed solutions.

#### Issue: "classpath src/ is not a directory"
**Solution:** Path resolution issue with test setup. This occurs when test configurations reference incorrect paths. Verify you're in the correct directory and all paths in `.hxml` files are accurate.

#### Issue: `Error: ENOENT: no such file or directory, open '.haxerc'`
**Solution:** Ensure you're in the project root directory
```bash
# Check you're in the right directory
ls .haxerc          # Should exist
pwd                 # Should end with /reflaxe.elixir
```

#### Issue: No source maps generated
**Solution:** Source mapping is currently experimental; `.ex.map` files are not emitted by default builds yet.
See `docs/04-api-reference/SOURCE_MAPPING.md`.

#### Issue: Source map positions incorrect
**Solution:** Source mapping is currently experimental; if you’re working on it, start from
`docs/04-api-reference/SOURCE_MAPPING.md` and add integration coverage under `test/snapshot/core/source_map_validation/`.

### Getting Help

#### Check Installation Status
```bash
# Verify each component
node --version      # Node.js
npx lix --version   # lix package manager
haxe --version      # Haxe (project toolchain)
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

## Next Steps

After successful installation:

1. **[Quickstart Tutorial](../06-guides/QUICKSTART.md)** - Build your first Haxe→Elixir project in 5 minutes
2. **[Project Structure](../../README.md#Project-Structure)** - Understand the directory layout and conventions
3. **[Development Workflow](development-workflow.md)** - Learn day-to-day development practices
4. **[Phoenix Integration](../02-user-guide/PHOENIX_INTEGRATION.md)** - Build Phoenix applications with Haxe

## Additional Resources

- **[User Guide](../02-user-guide/)** - Complete application development documentation
- **[Troubleshooting Guide](../06-guides/TROUBLESHOOTING.md)** - Comprehensive problem-solving reference
- **[API Reference](../04-api-reference/)** - Technical reference for annotations and APIs
- **[Compiler Development](../03-compiler-development/)** - For contributors to the compiler itself

---

**Ready to code?** Continue to [Quickstart Tutorial](../06-guides/QUICKSTART.md) for your first Haxe→Elixir project.

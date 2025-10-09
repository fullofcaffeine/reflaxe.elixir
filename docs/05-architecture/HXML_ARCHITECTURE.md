# HXML File Architecture & Best Practices

## What Are HXML Files?

HXML files are Haxe build configuration files that contain compiler arguments. They're essentially saved command-line arguments that can be reused, composed, and version-controlled. Think of them as Makefiles specifically for Haxe compilation.

## Our HXML Architecture

### Project Structure
```
reflaxe.elixir/
├── test/
│   └── Test.hxml           # Test runner configuration
├── examples/
│   └── todo-app/
│       ├── build.hxml       # Main entry point (delegates)
│       ├── build-server.hxml # Elixir compilation config
│       └── build-client.hxml # JavaScript compilation config
```

### Why This Structure?

1. **Separation of Concerns**: Each HXML file has a single responsibility
2. **Dual-Target Support**: Separate configs for JavaScript (client) and Elixir (server)
3. **Composability**: Main build.hxml can chain multiple configurations
4. **IDE Integration**: Most Haxe IDEs recognize and use HXML files for project configuration

## HXML File Anatomy

### build.hxml (Entry Point)
```hxml
# Main build configuration - delegates to server build
# Use build-client.hxml for JavaScript compilation
# Use build-server.hxml for Elixir compilation (default)

--next build-server.hxml
```

**Purpose**: Acts as the main entry point, delegates to specific target builds.

**Best Practice**: Keep the main build.hxml minimal - it should only orchestrate other builds.

### build-server.hxml (Elixir Target)
```hxml
# Haxe→Elixir compilation for Phoenix LiveView server-side code
# Generates idiomatic Elixir code for the BEAM VM

# Include Reflaxe.Elixir source (for examples running from subdirectories)
-cp ../../src          # Compiler source path
-cp ../../std          # Standard library extensions
-lib reflaxe           # Reflaxe framework dependency

# Source directories
-cp src_haxe           # Main source directory
-cp src_haxe/server    # Server-specific code
-cp src_haxe/shared    # Shared client-server code

# Output directory for generated .ex files
-D elixir_output=lib

# Required for Reflaxe targets
-D reflaxe_runtime

# Platform-specific flags
-D no-utf16            # Elixir is not UTF-16

# Application configuration
-D app_name=TodoApp

# Exclude client code from server compilation
--macro exclude('client')

# Initialize the compiler
-D reflaxe.elixir=0.1.0
--macro reflaxe.elixir.CompilerInit.Start()

# Classes to compile (entry points)
TodoApp
TodoAppRouter
server.live.TodoLive
# ... more classes
```

### build-client.hxml (JavaScript Target)
```hxml
# JavaScript compilation for browser client
-cp src_haxe
-cp src_haxe/client
-cp src_haxe/shared

# Standard Haxe JS output
-js priv/static/js/app.js

# Exclude server code
--macro exclude('server')

# Modern JavaScript features
-D js-es=6
-D js-unflatten

# Source maps for debugging
-D source-map

# Main client class
-main client.TodoApp
```

## Modern Haxe Best Practices for HXML

### 1. Use Hierarchical Configuration
```hxml
# Good: Composable configurations
--next build-server.hxml
--next build-client.hxml
--next build-tests.hxml

# Avoid: Monolithic single file with everything
```

### 2. Define Clear Compilation Boundaries
```hxml
# Server-only compilation
--macro exclude('client')

# Client-only compilation  
--macro exclude('server')
```

### 3. Use Conditional Compilation Flags
```hxml
# Development
-D debug
-D source-map
-D elixir-source-map

# Production
-D no-debug
-D dce=full          # Dead code elimination
-D analyzer-optimize # Optimizer
```

### 4. Library Management
```hxml
# Modern: Use haxelib dependencies
-lib reflaxe
-lib tink_macro

# Include version constraints in haxelib.json
```

### 5. Path Organization
```hxml
# Good: Structured paths
-cp src              # Main source
-cp src/server       # Server code
-cp src/client       # Client code
-cp src/shared       # Shared code
-cp test            # Test code

# Avoid: Everything in one directory
-cp .
```

### 6. Output Configuration
```hxml
# Elixir: Specify output directory
-D elixir_output=lib

# JavaScript: Direct file output
-js priv/static/js/app.js

# Multiple outputs for libraries
--each              # Reset for each target
```

### 7. Macro Configuration
```hxml
# Initialize macros properly
--macro reflaxe.elixir.CompilerInit.Start()

# Build macros
--macro addMetadata('@:build(RouterBuildMacro.build())', 'MyRouter')
```

### 8. Documentation Generation
```hxml
# Generate documentation
-D doc-gen
-xml doc/api.xml
--no-output         # Don't generate code, just docs
```

## Why We Have Multiple HXML Files

### 1. **Test.hxml** (Test Runner)
- Isolated test configuration
- Includes test-specific macros and flags
- Can run subset of tests with defines

### 2. **build.hxml** (Orchestrator)
- Main entry point for developers
- Delegates to appropriate target configs
- Enables `haxe build.hxml` simplicity

### 3. **build-server.hxml** (Elixir Target)
- Reflaxe.Elixir specific configuration
- Phoenix/LiveView compilation setup
- Server-side class compilation

### 4. **build-client.hxml** (JS Target)
- Standard Haxe→JavaScript compilation
- Browser-specific optimizations
- Client-side bundling configuration

## Command Line vs HXML

```bash
# Without HXML (hard to maintain)
haxe -cp src -cp ../../std -lib reflaxe -D reflaxe_runtime -D elixir_output=lib --macro reflaxe.elixir.CompilerInit.Start() TodoApp

# With HXML (clean and versioned)
haxe build.hxml
```

## IDE Integration

Most modern Haxe IDEs use HXML files for:
- **VSCode**: Haxe extension reads HXML for completion
- **IntelliJ**: Haxe plugin uses HXML for project structure
- **Sublime**: Haxe package provides HXML syntax highlighting

## Advanced Patterns

### Conditional Compilation
```hxml
# Platform-specific code
#if sys
-cp src/sys
#end

#if js
-cp src/js
#end
```

### Multi-Target Libraries
```hxml
# compile.hxml
--each              # Reset between targets

--next
-js bin/mylib.js
-D js-es=6

--next  
-cpp bin/cpp
-D static_link

--next
-D elixir_output=lib

## About `-D reflaxe_runtime`

Reflaxe compilers and std modules often use `#if (macro || reflaxe_runtime)` to expose selected types during non‑macro test builds. This flag is a compilation aid, not a runtime switch.

- Purpose
  - Allow examples, snapshots, and unit tests to compile code that normally exists only in macro builds (helpers/IR), without invoking macro APIs.
  - Enable test compilation of std modules that depend on target‑aware helpers (e.g., elixir injection wrappers) without running the compiler.

- Policy
  - Macro‑only APIs (e.g., `haxe.macro.Context.*`) must always be guarded with `#if macro` even inside files compiled with `#if (macro || reflaxe_runtime)`.
  - Non‑macro branches must be side‑effect‑free (no compiler behavior) and may optionally emit debug logs behind opt‑in flags.
  - Production builds should not depend on `reflaxe_runtime`; it is for test/dev flows only.

- References
  - See docs/02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md for a deep dive on contexts and correct usage.
  - Reference compilers (in haxe.elixir.reference) also gate many core files with `#if (macro || reflaxe_runtime)` and define `-D reflaxe_runtime` in their dev HXMLs.
--macro reflaxe.elixir.CompilerInit.Start()
```

### Environment-Specific Builds
```hxml
# dev.hxml
build.hxml
-D debug
-D source-map

# prod.hxml
build.hxml
-D no-debug
-D dce=full
-D analyzer-optimize
```

## Common Pitfalls to Avoid

1. **Don't hardcode absolute paths** - Use relative paths for portability
2. **Don't mix target outputs** - Separate JS and Elixir outputs
3. **Don't forget --each** - When building multiple targets
4. **Don't ignore IDE needs** - Ensure HXML works with IDE tools
5. **Don't duplicate configuration** - Use composition over duplication

## Reflaxe-Specific Considerations

For Reflaxe targets like Reflaxe.Elixir:
1. Always include `-D reflaxe_runtime`
2. Initialize with target-specific macro
3. Specify output directory with target's define
4. Include target's standard library extensions
5. Handle platform differences (UTF-16, line endings, etc.)

## Actual Project Usage Analysis

### How Reflaxe.Elixir Uses HXML Files

After analyzing 100+ HXML files in the project, here are the actual patterns we use:

### 1. Test Infrastructure Pattern (`test/Test.hxml`)

**Actual Implementation:**
```hxml
# Reflaxe.Elixir Test Runner Configuration
-cp test
--run test.TestRunner
```

**Analysis:**
- ✅ **Follows best practice**: Minimal entry point
- ✅ **Delegation pattern**: Runner handles complexity
- ✅ **Runtime configuration**: Parameters passed via command line
- This is exactly how Reflaxe.CPP and Reflaxe.CSharp do it

### 2. Snapshot Test Pattern (`test/tests/*/compile.hxml`)

**Example from `liveview_basic/compile.hxml`:**
```hxml
# Compilation configuration for liveview_basic test
-cp ../../../std          # Standard library extensions
-cp ../../../src          # Compiler source
-cp .                     # Test source
-lib reflaxe              # Framework dependency
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out      # Output directory
CounterLive               # Main class to compile
```

**Pattern Analysis:**
- ✅ **Consistent structure** across all 40+ test directories
- ✅ **Relative paths** for portability
- ✅ **Clear purpose** per test
- ⚠️ **Repetitive**: Could use template inheritance

### 3. Application Build Pattern (`examples/todo-app/`)

**Orchestrator (`build.hxml`):**
```hxml
--next build-server.hxml
```

**Server Target (`build-server.hxml`):**
```hxml
-cp ../../src             # Compiler source
-cp ../../std             # Standard library
-lib reflaxe              # Framework
-cp src_haxe              # Application source
-D elixir_output=lib      # Phoenix lib directory
-D reflaxe_runtime        # Enable runtime
-D app_name=TodoApp       # Application config
--macro exclude('client') # Server only
--macro reflaxe.elixir.CompilerInit.Start()
TodoApp                   # Entry points...
```

**Client Target (`build-client.hxml`):**
```hxml
-cp src_haxe/client       # Client source
-js assets/js/app.js      # Output file
-D js-es6                 # Modern JavaScript
--macro exclude('server') # Client only
client.PhoenixApp         # Entry point
```

### 4. Library Management (`haxe_libraries/*.hxml`)

**Generated by Lix package manager:**
```hxml
# @install: lix --silent download "haxelib:/reflaxe#4.0.0" 
-cp ${HAXE_LIBCACHE}/reflaxe/4.0.0/haxelib/src
-D reflaxe=4.0.0
```

**Note:** These are tool-generated, not manually maintained.

## Comparison to Best Practices

### What We Do Well ✅

1. **Hierarchical Configuration**
   - `build.hxml` → `build-server.hxml` + `build-client.hxml`
   - Clean delegation pattern

2. **Clear Separation of Concerns**
   - Client vs server via `--macro exclude()`
   - Test vs production code paths

3. **Consistent Test Structure**
   - All 40+ tests follow identical pattern
   - Easy to understand and maintain

4. **Proper Use of Defines**
   - `-D elixir_output=lib` for output control
   - `-D app_name=TodoApp` for configuration
   - `-D reflaxe_runtime` for framework features

5. **Path Organization**
   - Clear separation: `src/`, `std/`, `test/`
   - Relative paths throughout

### Areas for Improvement ⚠️

1. **Too Many Top-Level Test Files**
   - 50+ test HXML files in `test/` directory
   - Many appear orphaned or experimental
   - Could consolidate to test categories

2. **Missing Environment Configs**
   - No `dev.hxml` or `prod.hxml`
   - No optimization flag management
   - No debug/release configurations

3. **No Watch Mode Setup**
   - Missing file watcher configuration
   - No hot reload setup

4. **Unused/Orphaned Files**
   - `extraParams.hxml` appears unused
   - Multiple `Test*.hxml` files with unclear purpose
   - Should audit and clean up

5. **Limited Multi-Target Usage**
   - Not using `--each` for library builds
   - Could better support cross-compilation

## Project-Specific Patterns

### Reflaxe.Elixir Initialization
Every Elixir compilation uses this pattern:
```hxml
-lib reflaxe
-D reflaxe_runtime
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=<directory>
```

### Test Compilation Pattern
Snapshot tests follow this structure:
```hxml
-cp ../../../std    # Extensions
-cp ../../../src    # Compiler
-cp .               # Test files
-lib reflaxe
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out
MainClass           # Entry point
```

### Dual-Target Pattern
For Phoenix apps with client and server:
```hxml
# Server excludes client
--macro exclude('client')

# Client excludes server  
--macro exclude('server')
```

## Recommendations

1. **Create Template Files**
   - `templates/test.hxml.template`
   - `templates/example.hxml.template`
   - `templates/library.hxml.template`

2. **Consolidate Test Configurations**
   - Group by test type (unit, integration, snapshot)
   - Remove orphaned test files

3. **Add Environment Management**
   - `config/dev.hxml`
   - `config/prod.hxml`
   - `config/test.hxml`

4. **Document Each HXML File**
   - Add header comments explaining purpose
   - Link to related documentation
   - Specify maintenance ownership

## Future Improvements

1. **Watch mode configuration**: Add file watching flags
2. **Test coverage**: Include coverage reporting flags  
3. **Benchmarking**: Performance testing configuration
4. **Documentation**: Auto-generate docs from HXML
5. **CI/CD integration**: GitHub Actions friendly configs
6. **Template inheritance**: Reduce repetition in test configs
7. **Orphan cleanup**: Audit and remove unused HXML files

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

# Use the compiler via haxelib/lix
-lib reflaxe.elixir

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

# Classes to compile (entry points)
TodoApp
TodoAppRouter
server.live.TodoLive
# ... more classes
```

### build-client.hxml (JavaScript Target)
```hxml
# Haxe→JavaScript compilation for Phoenix LiveView client-side code
# Generates ES6 modules via Genes (recommended)

# Source directories (client only)
-cp src_haxe/client
-cp src_haxe

# Enable Genes ES6 module generator (uses haxe_libraries/genes.hxml)
-lib genes

# Modern JavaScript features
-D js-es=6
--macro genes.Generator.use()
--macro addMetadata('@:genes.disableNativeAccessors', 'haxe.Exception')

# JavaScript target output (kept separate from Phoenix bootstrap)
-js assets/js/hx_app.js
-D js-unflatten
--dce=full

# Source maps for debugging (JS)
-D real-position
-D js-source-map

# Exclude server code from client compilation
--macro exclude('server')

# Main client entry point (hooks registry)
-main client.Boot
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
# -D js-source-map       # JS source maps (use only in client builds)

# Production
-D no-debug
-dce full            # Dead code elimination
-D loop_unroll_max_cost=10
# NOTE: Do not use -D analyzer-optimize for Elixir targets (it harms output quality).
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

# JavaScript (Genes): Direct file output
-js assets/js/hx_app.js

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
- Haxe→JavaScript compilation via Genes (recommended)
- Browser-specific optimizations
- Client-side bundling configuration

## Command Line vs HXML

```bash
# Without HXML (hard to maintain)
haxe -cp src_haxe -lib reflaxe.elixir -D reflaxe_runtime -D elixir_output=lib TodoApp

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

## Target-Conditional Stdlib Gating (Elixir)

Elixir-specific staged overrides under `std/_std/` are added to the classpath only when compiling to the Elixir target. This is handled in `CompilerInit.Start()` and prevents `__elixir__()` usage from leaking into macro contexts or other targets.

See: docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md

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
--macro reflaxe.elixir.CompilerInit.Start()
```

### Environment-Specific Builds
```hxml
# dev.hxml
build.hxml
-D debug
-D js-source-map

# prod.hxml
build.hxml
-D no-debug
-dce full
-D loop_unroll_max_cost=10
# NOTE: Do not use -D analyzer-optimize for Elixir targets (it harms output quality).
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
--next build-client.hxml
```

**Server Target (`build-server.hxml`):**
```hxml
-lib reflaxe.elixir
-cp src_haxe
-cp src_haxe/server
-cp src_haxe/shared
-D elixir_output=lib
-D reflaxe_runtime
-D app_name=TodoApp
--macro exclude('client')
TodoApp
```

**Client Target (`build-client.hxml`):**
```hxml
-cp src_haxe/client
-cp src_haxe
-lib genes

# NOTE: Our vendored `-lib genes` does not automatically apply genes/extraParams.hxml,
# so we explicitly enable the generator here.
-D js-es=6
--macro genes.Generator.use()
--macro addMetadata('@:genes.disableNativeAccessors', 'haxe.Exception')

-js assets/js/hx_app.js
-D js-unflatten
--dce=full
-D real-position
-D js-source-map
--macro exclude('server')
-main client.Boot
```

### 4. Library Management (`haxe_libraries/*.hxml`)

**Generated by Lix package manager:**
```hxml
# @install: lix --silent download "haxelib:/reflaxe#4.0.0" 
-cp ${HAXE_LIBCACHE}/reflaxe/4.0.0/haxelib/src
-D reflaxe=4.0.0
```

**Note:** These are tool-generated, not manually maintained.

### Client JS Build: Classpath Guardrails (Important)

When compiling the browser client (JS target), avoid adding repository-level
classpath roots such as `../../std`, `../../src`, or vendored sources directly.
These may shadow the real Haxe standard library and macro APIs and cause
unexpected macro errors (e.g., “no field setCustomJSGenerator” on
`haxe.macro.Compiler`).

Rules for JS client HXML (e.g., `examples/todo-app/build-client.hxml`):
- Only include application client sources (e.g., `-cp src_haxe`, `-cp src_haxe/client`).
- Pull generators/libraries via `-lib` (e.g., `-lib genes`), letting
  `haxe_libraries/<lib>.hxml` provide their classpaths and macros.
- Do not include repo-level `std/` or `src/` in client builds.

Verification:
- Run `haxe -v build-client.hxml` and check the printed Classpath lines:
  they should reference your client sources, the library paths from
  `haxe_libraries/`, and the official Haxe std (e.g., `.../versions/4.3.7/std`).
- If you see repo-local `std/` or `src/` in the client Classpath, remove them
  from the client HXML.

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
   - `extraParams.hxml` is consumed by haxelib/lix when a project uses `-lib reflaxe.elixir`; it must remain at the repo root and stay cwd-agnostic
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

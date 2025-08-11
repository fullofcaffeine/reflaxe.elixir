# Testing Architecture for Reflaxe.Elixir

## Overview

Testing a macro-based transpiler presents unique challenges since the transpiler code only exists during compilation, not at runtime when tests execute. This document explains our dual-ecosystem testing approach, self-referential library configuration, and test infrastructure.

## 📚 Complete Test Suite Documentation

**For a comprehensive deep dive into what each test suite validates and how the testing architecture works, see:**
**[`TEST_SUITE_DEEP_DIVE.md`](TEST_SUITE_DEEP_DIVE.md)** - Complete analysis of all 155+ tests across the three-layer architecture

This document covers:
- What the 25 Haxe snapshot tests validate (AST transformation layer)
- What the 130 Mix tests validate (build system and runtime validation)
- What the 9 example tests validate (real-world usage patterns)
- Detailed breakdown of testing philosophy and debugging subsystems


## Self-Referential Library Configuration

The most critical aspect of our testing infrastructure is the **self-referential library configuration** that allows tests to use `-lib reflaxe.elixir` to reference the library being developed.

**⚠️ For detailed troubleshooting and critical learnings, see [`SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md`](SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md)**

### The Challenge

When tests use `-lib reflaxe.elixir`, Haxe needs to find a library configuration. However, during development, this library isn't installed via haxelib - it's the project we're developing!

### The Solution: haxe_libraries/reflaxe.elixir.hxml

We create a self-referential configuration file that points back to the project's source:

```hxml
# haxe_libraries/reflaxe.elixir.hxml
# Include the compiler source code
-cp src/

# Include the Elixir standard library definitions  
-cp std/

# Depend on the base Reflaxe framework
-lib reflaxe

# Define the library version
-D reflaxe.elixir=0.1.0

# Initialize the Elixir compiler
--macro reflaxe.elixir.CompilerInit.Start()
```

### Path Resolution Strategy

The paths in `reflaxe.elixir.hxml` are relative to the current working directory when Haxe executes. To handle this:

1. **Production**: Paths work when run from project root
2. **Testing**: `HaxeTestHelper` creates symlinks to ensure paths resolve:
   - Symlinks `haxe_libraries` directory
   - Symlinks `src/` and `std/` directories in test directories
   - Ensures compilation happens in the correct directory context

### Test Helper Infrastructure

The `test/support/haxe_test_helper.ex` module handles the complexity:

```elixir
def setup_haxe_libraries(project_dir) do
  # Find project root dynamically
  project_root = find_project_root()
  
  # Create symlinks for library resolution
  symlink_or_copy(
    Path.join(project_root, "haxe_libraries"),
    Path.join(project_dir, "haxe_libraries")
  )
  
  # Ensure src/ and std/ are accessible
  symlink(Path.join(project_root, "src"), Path.join(project_dir, "src"))
  symlink(Path.join(project_root, "std"), Path.join(project_dir, "std"))
end
```

## Test Suite Overview

The Reflaxe.Elixir test suite consists of **30 snapshot tests** that validate compiler output:

### Snapshot Tests (30 tests total)
- **Source Mapping Tests** (2 tests) 🎯
  - `source_map_basic`: Validates `.ex.map` file generation with VLQ encoding
  - `source_map_validation`: Tests Source Map v3 specification compliance
- **Feature Tests** (10 tests): LiveView, OTP, Ecto, Changeset, Migration, etc.
- **Example Tests** (6 tests): Real-world compilation scenarios
- **Core Tests** (7 tests): Basic syntax, classes, enums, arrays, etc.

All tests run automatically via `npm test` which executes BOTH:
- **Haxe Compiler Tests**: 30 snapshot tests via TestRunner.hx
- **Mix Runtime Tests**: 130 Elixir tests via ExUnit

This ensures complete end-to-end validation of the entire compilation pipeline.

## Test Categories

Reflaxe.Elixir uses multiple testing approaches:

### Test Suite Documentation

For detailed documentation on specific test suites, see:
- **Module Tests**: [`MODULE_TEST_DOCUMENTATION.md`](MODULE_TEST_DOCUMENTATION.md) - @:module syntax sugar validation
- **Pattern Tests**: [`PATTERN_TESTS_MIGRATION.md`](PATTERN_TESTS_MIGRATION.md) - Pattern matching compilation

### 1. Macro-Time Tests (Direct Compiler Testing)
**Location**: Tests like `SimpleCompilationTest.hx`, `TestElixirCompiler.hx`  
**Execution**: Run with `--interp` flag during Haxe compilation  
**Framework**: None - use simple trace/try-catch  
**Purpose**: Test the REAL `ElixirCompiler` during compilation  

Example `.hxml`:
```hxml
-cp src
-cp test  
-D reflaxe_runtime
-main test.SimpleCompilationTest
--interp
```

These tests:
- Instantiate the actual `ElixirCompiler` class
- Test real AST transformation logic
- Run as Haxe macros during compilation phase
- Don't use ANY testing framework


### 3. Mix Integration Tests (Generated Code Validation)
**Location**: `test/` directory in Elixir project  
**Execution**: `npm run test:mix`  
**Framework**: ExUnit (Elixir's native test framework)  
**Purpose**: Validate that generated Elixir code actually works  

These tests:
- Create `.hx` source files
- Invoke the Haxe compiler (runs real ElixirCompiler)
- Validate generated `.ex` files compile and run correctly
- Test Phoenix/Ecto/OTP integration

## The Macro-Time vs Runtime Challenge

### The Problem

```haxe
#if (macro || reflaxe_runtime)
// This code ONLY exists during Haxe compilation
class ElixirCompiler {
    // Transforms AST to Elixir
}
#end

// Test code runs AFTER compilation
@:asserts
class CompilerTest {
    // ElixirCompiler doesn't exist here!
}
```

### Why This Happens

1. **Macro Phase**: ElixirCompiler runs as a Haxe macro during compilation
2. **Runtime Phase**: Tests run after compilation when the transpiler is gone
3. **The Gap**: We can't directly test the transpiler at runtime

## Dual-Ecosystem Testing Strategy

### Running All Tests

```bash
# Run complete test suite (recommended)
npm test  # Runs both Haxe and Mix tests

# Run individual test suites
npm run test:haxe  # Only Haxe compiler tests (30 tests)
npm run test:mix   # Only Mix/Elixir tests (130 tests)
```

### 1. Haxe Compiler Tests (`npm run test:haxe`)

**Purpose**: Test the compilation engine and AST transformation logic via snapshot testing

**Framework**: TestRunner.hx (following Reflaxe.CPP patterns)

**What We Test**:
- AST transformation correctness by comparing generated Elixir output
- Syntax generation for all language features
- Annotation processing (@:liveview, @:genserver, @:schema, etc.)
- Type mapping and code generation patterns

**How It Works**:
1. **Compilation Phase**: TestRunner.hx invokes Haxe compiler with test cases
2. **Generation Phase**: ElixirCompiler transforms AST to .ex files
3. **Comparison Phase**: Generated output compared with "intended" reference files
4. **Validation**: Ensures output matches expected Elixir code

**Example Test Structure**:
```
test/tests/liveview_basic/
├── compile.hxml          # Test compilation config
├── CounterLive.hx       # Test Haxe source
├── intended/            # Expected Elixir output
│   └── CounterLive.ex   # Reference file for comparison
└── out/                 # Generated output (for comparison)
```

### 2. Elixir Runtime Tests (`npm run test:mix`)

**Purpose**: Validate generated Elixir code works in BEAM VM

**Framework**: ExUnit

**What We Test**:
- Generated .ex files compile with Elixir
- Phoenix/Ecto integration works
- OTP behaviors function correctly
- Mix task integration

**Example**:
```elixir
defmodule MixIntegrationTest do
  test "compiles Haxe to valid Elixir" do
    # Create .hx source file
    File.write!("src_haxe/Test.hx", haxe_source)
    
    # Run our Mix compiler task
    {:ok, files} = Mix.Tasks.Compile.Haxe.run([])
    
    # Validate generated Elixir
    assert File.exists?("lib/test.ex")
  end
end
```



## Test Execution Flow

### Complete Test Pipeline

```bash
npm test
    │
    ├── npm run test:haxe
    │   ├── Run TestRunner.hx snapshot tests
    │   ├── Compile test cases with Haxe+Reflaxe.Elixir
    │   └── Compare generated .ex files with intended output
    │
    └── npm run test:mix
        ├── Create Phoenix project
        ├── Add Haxe source files
        ├── Run Mix.Tasks.Compile.Haxe
        └── Test generated Elixir code
```

### Individual Test Commands

```bash
# Test only Haxe compiler
npm run test:haxe

# Test only Elixir output
npm run test:mix

# Run specific snapshot test
haxe test/Test.hxml test=liveview_basic
```


## Specific Test Suites

### Module Tests (@:module Syntax Sugar)

**Purpose**: Validates @:module annotation processing for simplified Elixir module generation

**Files**:
- `ModuleSyntaxTest.hx` - Basic functionality (10 tests)
- `ModuleIntegrationTest.hx` - Integration scenarios (8 tests)  
- `ModuleRefactorTest.hx` - Advanced validation (15 tests)

**Key Validations**:
- Module name generation (`defmodule UserService`)
- Function compilation (`def`/`defp` syntax)
- Import handling (`alias Elixir.String`)
- Pipe operator preservation (`data |> process()`)
- Error handling (invalid names, malformed expressions)

**Business Justification**: @:module syntax reduces Haxe→Elixir boilerplate by ~70%, making gradual Phoenix migration feasible. Tests ensure generated Elixir integrates seamlessly with existing applications.

**Documentation**: See [`MODULE_TEST_DOCUMENTATION.md`](MODULE_TEST_DOCUMENTATION.md) for complete analysis.

### Pattern Tests (Pattern Matching Compilation)

**Purpose**: Validates Haxe switch/match compilation to Elixir case expressions

**Documentation**: See [`PATTERN_TESTS_MIGRATION.md`](PATTERN_TESTS_MIGRATION.md) for details.

### Query Tests (Ecto Query DSL)

**Purpose**: Validates Ecto query compilation with type-safe schema integration

**Status**: Migration pending (5 files)

## Best Practices

### 1. Test Organization

```
test/
├── TestRunner.hx               # Main snapshot test runner
├── Test.hxml                   # Test configuration
├── tests/                      # Snapshot test cases
│   ├── liveview_basic/        # Individual test directories
│   ├── otp_genserver/         
│   └── ...                    
└── fixtures/                   # Test data files
```

### 2. Edge Case Coverage

Always test these 7 categories:
1. Error conditions (null, invalid input)
2. Boundary cases (empty, limits)
3. Security validation (injection)
4. Performance limits (timing)
5. Integration robustness
6. Type safety
7. Resource management


## Troubleshooting

### Common Issues

1. **"Library reflaxe.elixir is not installed"**
   - Missing `haxe_libraries/reflaxe.elixir.hxml`
   - See [Self-Referential Library Troubleshooting](SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md)

2. **"Type not found" at runtime**
   - The type is macro-only
   - Create a runtime mock

3. **"classpath src/ is not a directory"**
   - Path resolution issue
   - Check symlinks in test directory
   - See [Path Resolution section](SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md#path-resolution-the-1-source-of-confusion)

4. **Framework timeout errors**
   - Add @:timeout annotation
   - Break test into smaller parts

5. **Mock/reality mismatch**
   - Update mock to match current implementation
   - Add validation tests

6. **Tests expect 1 file, get 35 files**
   - The "35-file phenomenon" from symlinked src/
   - See [troubleshooting guide](SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md#the-35-file-phenomenon)

7. **Process.send_after timing issues in tests**
   - Timers may not fire reliably within expected timeframes in test environment
   - Add manual trigger fallback for critical timer-based functionality:
   ```elixir
   if status.compilation_count == expected do
     send(Process.whereis(GenServerName), :timer_message)
     Process.sleep(100)
   end
   ```

8. **Mix.shell() output stream confusion**
   - `Mix.shell().info()` outputs to **stdout**
   - `Mix.shell().error()` outputs to **stderr**
   - Use appropriate capture: `capture_io(:stderr, fn -> ... end)`

9. **Test file mismatch with build.hxml**
   - Ensure tests modify files actually referenced in build.hxml
   - If build.hxml specifies `test.SimpleClass`, don't modify `Main.hx`
   - Check compilation targets match test expectations

10. **Directory context for relative paths**
    - Commands with relative paths in config files need correct working directory
    - Use `[cd: dir]` option when executing commands:
    ```elixir
    compile_opts = case Path.dirname(build_file) do
      "." -> [stderr_to_stdout: true]
      dir -> [cd: dir, stderr_to_stdout: true]
    end
    ```

### Debug Techniques

```haxe
// Add trace for debugging
trace('Compilation result: $result');

// Check macro vs runtime
#if macro
trace("Running at macro time");
#else
trace("Running at runtime");
#end
```



## References

- [Architecture Documentation](ARCHITECTURE.md)
- [tink_unittest Documentation](https://github.com/haxetink/tink_unittest)
- [utest Documentation](https://github.com/haxe-utest/utest)
- [Haxe Macro Documentation](https://haxe.org/manual/macro.html)
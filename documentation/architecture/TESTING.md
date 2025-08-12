# Testing Architecture for Reflaxe.Elixir

## Overview

Testing a macro-based transpiler presents unique challenges since the transpiler code only exists during compilation, not at runtime when tests execute. This document explains our dual-ecosystem testing approach, self-referential library configuration, and test infrastructure.

## 📚 Complete Test Suite Documentation

**For a comprehensive deep dive into what each test suite validates and how the testing architecture works, see:**
**[`TEST_SUITE_DEEP_DIVE.md`](TEST_SUITE_DEEP_DIVE.md)** - Complete analysis of all 155+ tests across the three-layer architecture

This document covers:
- What the 28 Haxe snapshot tests validate (AST transformation layer)
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

The Reflaxe.Elixir test suite consists of **28 snapshot tests** that validate compiler output:

### Snapshot Tests (28 tests total)
- **Source Mapping Tests** (2 tests) 🎯
  - `source_map_basic`: Validates `.ex.map` file generation with VLQ encoding
  - `source_map_validation`: Tests Source Map v3 specification compliance
- **Feature Tests** (10 tests): LiveView, OTP, Ecto, Changeset, Migration, etc.
- **Example Tests** (6 tests): Real-world compilation scenarios
- **Core Tests** (7 tests): Basic syntax, classes, enums, arrays, etc.
- **New Tests** (3 tests): Module syntax sugar, pattern matching, template compilation

All tests run automatically via `npm test` which executes BOTH:
- **Haxe Compiler Tests**: 28 snapshot tests via TestRunner.hx
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
npm run test:haxe  # Only Haxe compiler tests (28 tests)
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

## LLM Testing Guidance: How to Write/Update Tests ⚠️

**For AI agents working on this codebase**: This section provides clear instructions for writing and updating tests for different parts of the system. Follow these patterns exactly to avoid confusion about testing architecture.

### Quick Reference for Test Types

| What You're Testing | Test Type | Where to Add | Example |
|-------------------|-----------|-------------|---------|
| **New compiler feature** | Snapshot test | `test/tests/feature_name/` | LiveView, OTP, Ecto compilation |
| **Build system integration** | Mix test | `test/` (Elixir) | Mix.Tasks.Compile.Haxe behavior |
| **Documentation example** | Example compilation | `examples/XX-feature/` | Real-world usage patterns |

### 1. Adding New Compiler Features (Snapshot Tests)

**When**: You add a new annotation (@:myfeature), expression type, or compiler helper

**Steps**:
```bash
# 1. Create test directory
mkdir test/tests/my_feature

# 2. Create Haxe source file
# test/tests/my_feature/Main.hx
@:myfeature  
class TestMyFeature {
    public function new() {}
    public function testMethod(): String {
        return "test";
    }
}

# 3. Create compilation config
# test/tests/my_feature/compile.hxml
-cp ../../../std
-cp ../../../src  
-cp .
-lib reflaxe
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out
Main

# 4. Generate expected output
haxe test/Test.hxml update-intended

# 5. Verify test passes
haxe test/Test.hxml test=my_feature
```

**Key Points**:
- ✅ Use descriptive directory names (`liveview_basic`, not `test1`)
- ✅ Always use relative paths in compile.hxml (`../../../src`)
- ✅ Test real functionality, not placeholder code
- ❌ Don't manually write intended output files
- ❌ Don't test internal compiler state

### 2. Adding Build System Tests (Mix Tests)

**When**: You modify Mix.Tasks.Compile.Haxe, file watching, or build pipeline

**Location**: `test/` directory (Elixir files)

**Pattern**:
```elixir
defmodule MyFeatureTest do
  use ExUnit.Case
  import TestSupport.ProjectHelpers

  test "my feature integrates with build system" do
    # 1. Create temporary project
    project_dir = create_temp_project()
    
    # 2. Write test Haxe files
    File.write!(Path.join(project_dir, "src_haxe/Test.hx"), """
    @:myfeature
    class Test {}
    """)
    
    # 3. Run compiler
    {:ok, compiled} = Mix.Tasks.Compile.Haxe.run([])
    
    # 4. Verify results
    assert File.exists?(Path.join(project_dir, "lib/test.ex"))
    output = File.read!(Path.join(project_dir, "lib/test.ex"))
    assert output =~ "defmodule Test do"
  end
end
```

**Key Points**:
- ✅ Test integration, not implementation details
- ✅ Use temporary directories for isolation
- ✅ Verify generated Elixir compiles correctly
- ❌ Don't test internal ElixirCompiler methods (they don't exist at runtime)

### 3. Adding Documentation Examples

**When**: You want to show real-world usage of a feature

**Location**: `examples/XX-feature-name/`

**Structure**:
```
examples/10-my-feature/
├── README.md          # Usage instructions
├── build.hxml         # Compilation config
├── Main.hx           # Example source
└── out/              # Generated output (after compilation)
```

**Pattern**:
```haxe
// examples/10-my-feature/Main.hx
@:myfeature
class MyFeatureExample {
    static function main() {
        // Real-world usage example
        var result = useMyFeature();
        trace('Feature result: $result');
    }
}
```

### 4. Updating Existing Tests

**Snapshot Test Changes**:
```bash
# If compiler output changes legitimately:
haxe test/Test.hxml update-intended

# If you need to fix the test itself:
# 1. Edit test/tests/test_name/Main.hx
# 2. Run: haxe test/Test.hxml test=test_name  
# 3. If output is correct: haxe test/Test.hxml update-intended
```

**Mix Test Changes**:
```elixir
# Update test expectations to match new behavior
assert output =~ "new expected pattern"

# Or add new test cases for new functionality
test "new behavior works correctly" do
  # Test the new behavior
end
```

### 5. Common Mistakes to Avoid

❌ **DON'T**: Try to instantiate ElixirCompiler in tests
```haxe
// WRONG - Compiler doesn't exist at runtime
var compiler = new ElixirCompiler();
```

❌ **DON'T**: Manually write intended output files
```
# WRONG - Always use update-intended
echo "defmodule Test do" > intended/Test.ex
```

❌ **DON'T**: Test implementation details
```elixir
# WRONG - Testing internal compiler state
assert compiler.internal_state == expected
```

✅ **DO**: Test the transformation output
```bash
# RIGHT - Test what the compiler generates
haxe test/Test.hxml test=my_feature
```

✅ **DO**: Test build system integration  
```elixir
# RIGHT - Test that generated code works
assert File.exists?(output_file)
assert Code.compile_string(generated_code)
```

✅ **DO**: Test real-world usage patterns
```haxe
// RIGHT - Example that users would actually write
@:schema
class User {
    public var name: String;
    public var email: String;
}
```

### 6. Test Debugging Commands

```bash
# Show what compiler generates
haxe test/Test.hxml show-output test=feature_name

# Run specific Mix test with trace
MIX_ENV=test mix test test/my_test.exs:42 --trace

# Run all tests
npm test

# Run only snapshot tests  
npm run test:haxe

# Run only Mix tests
npm run test:mix
```

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


## Error Handling Architecture

### Test vs Production Error Display

Reflaxe.Elixir implements intelligent error handling that differentiates between expected test behavior and real compilation errors. This prevents test warnings from appearing as alarming error messages during development.

#### HaxeWatcher Error Logic

The error classification is implemented in `lib/haxe_watcher.ex`:

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

#### Error Categories

**Expected Test Warnings** ⚠️
- Library installation errors during isolated testing
- Compilation failures that tests are designed to trigger
- No ❌ emoji (indicates expected behavior)
- Logged at warning level to avoid alarm

**Real Compilation Errors** ❌
- Syntax errors in source code
- Type resolution failures
- Missing dependencies in development
- Logged at error level with ❌ emoji

#### Benefits for Testing Architecture

1. **Developer Experience**: Contributors don't panic over expected test warnings
2. **CI/CD Clarity**: Automated systems can distinguish real failures from test isolation effects
3. **Test Integrity**: Tests can validate error conditions without triggering false alarms
4. **Error Visibility**: Real errors remain highly visible with clear visual indicators

#### Integration with Test Infrastructure

This error handling integrates with our dual-ecosystem testing:
- **Snapshot Tests**: May trigger expected warnings during compilation validation
- **Mix Tests**: Run in isolated environments where library dependencies aren't fully resolved
- **Example Tests**: Real compilation environments show actual error state

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
- [Haxe Macro Documentation](https://haxe.org/manual/macro.html)
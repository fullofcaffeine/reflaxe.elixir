# Testing Architecture for Reflaxe.Elixir

## Overview

Testing a macro-based transpiler presents unique challenges since the transpiler code only exists during compilation, not at runtime when tests execute. This document explains our dual-ecosystem testing approach, self-referential library configuration, and test infrastructure.

**Important**: For a detailed analysis of why we use runtime mocks instead of macro-time testing, see [`MACRO_TIME_TESTING_ANALYSIS.md`](MACRO_TIME_TESTING_ANALYSIS.md)

## Self-Referential Library Configuration

The most critical aspect of our testing infrastructure is the **self-referential library configuration** that allows tests to use `-lib reflaxe.elixir` to reference the library being developed.

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

The Reflaxe.Elixir test suite consists of **25 snapshot tests** that validate compiler output:

### Snapshot Tests (25 tests total)
- **Source Mapping Tests** (2 tests) 🎯
  - `source_map_basic`: Validates `.ex.map` file generation with VLQ encoding
  - `source_map_validation`: Tests Source Map v3 specification compliance
- **Feature Tests** (10 tests): LiveView, OTP, Ecto, Changeset, Migration, etc.
- **Example Tests** (6 tests): Real-world compilation scenarios
- **Core Tests** (7 tests): Basic syntax, classes, enums, arrays, etc.

All tests run automatically via `npm test` using the TestRunner framework.

## Test Categories

Reflaxe.Elixir uses three distinct testing approaches:

### Test Suite Documentation

For detailed documentation on specific test suites, see:
- **Module Tests**: [`MODULE_TEST_DOCUMENTATION.md`](MODULE_TEST_DOCUMENTATION.md) - @:module syntax sugar validation
- **Pattern Tests**: [`PATTERN_TESTS_MIGRATION.md`](PATTERN_TESTS_MIGRATION.md) - Pattern matching compilation
- **Migration Summary**: [`UTEST_MIGRATION_SUMMARY.md`](UTEST_MIGRATION_SUMMARY.md) - Overall migration status

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

### 2. Runtime Mock Tests (Framework Testing)
**Location**: Tests like `OTPCompilerTest.hx`, `SimpleTest.hx`  
**Execution**: Compile then run after compilation  
**Framework**: tink_unittest + tink_testrunner (currently)  
**Purpose**: Test mock implementations and expected patterns  

These tests:
- Cannot access the real compiler (doesn't exist at runtime)
- Use mock classes to simulate compiler behavior
- Validate our understanding of compilation patterns
- Could use ANY runtime testing framework

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

### 1. Haxe Compiler Tests (`npm run test:haxe`)

**Purpose**: Test the compilation engine and AST transformation logic

**Framework**: tink_unittest + tink_testrunner

**What We Test**:
- Compilation logic (using mocks)
- AST transformation patterns
- Type mapping correctness
- Annotation detection

**Example**:
```haxe
@:asserts
class OTPCompilerTest {
    @:describe("GenServer compilation")
    public function testGenServerCompilation() {
        #if !(macro || reflaxe_runtime)
        // Runtime mock
        var result = MockOTPCompiler.compileFullGenServer(data);
        #else
        // Real compiler (macro-time only)
        var result = OTPCompiler.compileFullGenServer(data);
        #end
        
        asserts.assert(result.contains("use GenServer"));
        return asserts.done();
    }
}
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

## Runtime Mock Pattern

### When to Use Mocks

- Testing compiler helper functions
- Validating compilation patterns
- Unit testing individual components

### Mock Implementation Pattern

```haxe
// In test file
#if (macro || reflaxe_runtime)
import reflaxe.elixir.helpers.OTPCompiler;  // Real
#end

#if !(macro || reflaxe_runtime)
// Runtime mock for testing
class OTPCompiler {
    public static function compileFullGenServer(data: Dynamic): String {
        // Simplified mock implementation
        return 'defmodule ${data.className} do
  use GenServer
  
  def init(_), do: {:ok, %{}}
end';
    }
}
#end
```

### Mock Best Practices

1. **Keep mocks simple** - Test behavior, not implementation
2. **Match signatures** - Mock should have same API as real class
3. **Document why** - Explain the macro/runtime split
4. **Test both paths** - Ensure mocks align with real behavior

## tink_unittest Integration

### Framework Features

- **@:asserts** - Modern assertion pattern
- **@:timeout** - Prevent framework timeouts
- **@:describe** - Test documentation
- **@:before/@:after** - Setup/teardown

### Timeout Management

```haxe
@:describe("Complex edge case testing")
@:timeout(10000)  // Prevent 5-second default timeout
public function testEdgeCases() {
    // Complex test logic
    return asserts.done();
}
```

### Timeout Guidelines

| Test Type | Timeout | Use Case |
|-----------|---------|----------|
| Basic | 5000ms (default) | Simple assertions |
| Edge Cases | 10000ms | Error/boundary testing |
| Performance | 15000ms | Timing validation |
| Integration | 25000ms | Cross-system tests |

## Test Execution Flow

### Complete Test Pipeline

```bash
npm test
    │
    ├── npm run test:haxe
    │   ├── Compile tests with Haxe
    │   ├── Run tink_unittest suite
    │   └── Validate mock behavior
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

# Run specific test file
npx haxe test/OTPCompilerTest.hxml
```

## Vendoring for Testing

### When to Vendor

We vendor tink_testrunner and tink_unittest to:
- Debug framework issues quickly
- Apply patches if absolutely necessary
- Understand test execution flow

### Vendoring Structure

```
vendor/
├── tink_testrunner/   # Test execution framework
│   └── src/
└── tink_unittest/      # Assertion framework
    └── src/
```

### Patching Guidelines

1. **Try configuration first** - Use @:timeout, etc.
2. **Document patches** - Explain why and what
3. **Minimize changes** - Only patch what's broken
4. **Consider upstream** - Submit fixes back

## Specific Test Suites

### Module Tests (@:module Syntax Sugar)

**Purpose**: Validates @:module annotation processing for simplified Elixir module generation

**Files**:
- `ModuleSyntaxTestUTest.hx` - Basic functionality (10 tests)
- `ModuleIntegrationTestUTest.hx` - Integration scenarios (8 tests)  
- `ModuleRefactorTestUTest.hx` - Advanced validation (15 tests)

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
├── UTestRunner.hx              # Main test orchestrator (utest)
├── ComprehensiveTestRunner.hx  # Legacy tink_unittest runner
├── *TestUTest.hx              # Migrated utest files
├── *Test.hx                   # Legacy tink_unittest files  
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

### 3. Mock Alignment

```haxe
// Periodically validate mocks match real implementation
@:describe("Mock validation")
public function testMockAccuracy() {
    var mockResult = MockCompiler.compile(data);
    var expectedPattern = "defmodule.*do.*end";
    asserts.assert(~/expectedPattern/.match(mockResult));
    return asserts.done();
}
```

## Troubleshooting

### Common Issues

1. **"Type not found" at runtime**
   - The type is macro-only
   - Create a runtime mock

2. **Framework timeout errors**
   - Add @:timeout annotation
   - Break test into smaller parts

3. **Mock/reality mismatch**
   - Update mock to match current implementation
   - Add validation tests

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

## Testing Framework Comparison

### Framework Capabilities

| Feature | tink_unittest | utest | Notes |
|---------|--------------|-------|-------|
| **--interp support** | ✅ Yes | ✅ Yes | Both work with Haxe interpreter |
| **Macro-time testing** | ❌ Not used | ❌ Not used | Neither provides special macro features we use |
| **Async support** | ✅ Yes | ✅ Yes | Both support async/Future |
| **Colored output** | ✅ Yes | ✅ Yes | Both have nice reporting |
| **@:timeout control** | ✅ Yes | ❌ No | tink_unittest allows per-test timeouts |
| **Assertion style** | `asserts.assert()` | `Assert.equals()` | Different API patterns |
| **Setup/teardown** | `@:before/@:after` | `setup/teardown` | Both support test lifecycle |

### Current Usage Analysis

**What we're actually using from tink_unittest:**
- Basic assertion framework (`@:asserts`, `asserts.assert()`)
- Test runner with colored output
- `@:timeout` annotations for edge case tests
- `@:describe` for test documentation

**What we're NOT using:**
- Macro-time testing capabilities (don't exist)
- Special compiler integration features
- Advanced async testing (beyond basic Future support)

### Framework Selection Considerations

#### Why tink_unittest was chosen:
- Modern annotation-based API (`@:asserts`, `@:describe`)
- Built-in timeout control via `@:timeout`
- Clean integration with modern Haxe patterns
- Already working and integrated

#### Why utest would also work:
- Mature, well-established framework
- Supports all targets including `--interp`
- Simpler API might be easier to understand
- Used by many Haxe projects

#### Conclusion:
**Either framework would work equally well for our needs.** We're not using any unique features of tink_unittest that utest lacks. The choice is primarily about API preference and the fact that tink_unittest is already integrated and working.

## Important Discoveries

### 1. No Special Macro Testing Features Exist
Neither tink_unittest nor utest provide special macro-time testing capabilities. Tests that need to access the real `ElixirCompiler` must:
- Use `-D reflaxe_runtime` to make compiler code available
- Run with `--interp` to execute during compilation
- Use basic trace/try-catch instead of a framework

### 2. Mock Testing Limitations
Runtime tests (using either framework) can ONLY test mock implementations. The real compiler validation happens through:
- Macro-time tests that instantiate the real compiler
- Mix integration tests that compile actual code

### 3. Framework Independence
The project's testing architecture doesn't depend on any specific framework features. Migration between frameworks would be straightforward since we only use basic assertion and runner capabilities.

## References

- [Architecture Documentation](ARCHITECTURE.md)
- [tink_unittest Documentation](https://github.com/haxetink/tink_unittest)
- [utest Documentation](https://github.com/haxe-utest/utest)
- [Haxe Macro Documentation](https://haxe.org/manual/macro.html)
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
-D reflaxe.elixir=1.0.1

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

### 7. Creating Compile-Time Validation Tests (New) ⚠️

**When**: You're testing build macros, DSL validation, or compile-time warnings/errors

**Purpose**: Validate that macro-time validation logic produces appropriate warnings and errors during compilation, not just successful code generation.

#### Quick Decision Guide
| Testing Scenario | Test Type | Use Flexible Positions? |
|-------------------|-----------|------------------------|
| New macro warning messages | Compile-time validation | ✅ Yes |
| DSL constraint checking | Compile-time validation | ✅ Yes |
| Exact line number validation | Compile-time validation | ❌ No |
| Code generation only | Snapshot test | N/A |

#### Step-by-Step Workflow

**1. Create Test Structure**
```bash
# Create test directory (use descriptive name indicating what's being validated)
mkdir test/tests/MyMacro_InvalidInput

# Navigate to test directory
cd test/tests/MyMacro_InvalidInput
```

**2. Create Haxe Source with Invalid Usage**
```haxe
// Main.hx - Include invalid usage that should trigger warnings
@:myMacro([
    {name: "valid", value: "test"},
    {name: "", value: "invalid_empty_name"},  // Should trigger warning
    {name: "missing", /* no value */}         // Should trigger warning  
])
class TestInvalidInput {
    public function new() {}
}
```

**3. Create Compilation Config**
```hxml
// compile.hxml
-cp ../../../std
-cp ../../../src  
-cp .
-lib reflaxe
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out
Main
```

**4. Run Test to See Actual Warning Format**
```bash
# Run test from project root to see actual stderr output
haxe test/Test.hxml test=MyMacro_InvalidInput show-output
```

**5. Create Expected Stderr Files**

**Option A: Standard Mode (Exact Position Matching)**
```bash
# expected_stderr.txt - Include exact line positions
Main.hx:15: lines 15-17 : Warning : Empty name field not allowed in MyMacro definition
Main.hx:16: lines 16-18 : Warning : Missing value field in MyMacro entry "missing"
```

**Option B: Flexible Mode (Position-Independent)**
```bash
# expected_stderr_flexible.txt - Only warning content
Warning : Empty name field not allowed in MyMacro definition
Warning : Missing value field in MyMacro entry "missing"
```

**6. Generate Intended Output**
```bash
# Generate expected Elixir output (even for validation tests)
haxe test/Test.hxml test=MyMacro_InvalidInput update-intended
```

**7. Verify Both Modes Work**
```bash
# Test standard mode (exact positions)
haxe test/Test.hxml test=MyMacro_InvalidInput

# Test flexible mode (position-independent) 
haxe test/Test.hxml test=MyMacro_InvalidInput flexible-positions
```

#### Test Naming Conventions

Use this pattern: `MacroName_ValidationScenario`

✅ **Good Examples**:
- `RouterBuildMacro_InvalidController`
- `RouterBuildMacro_ValidController` 
- `RouterBuildMacro_MultipleInvalid`
- `SchemaValidator_MissingFields`
- `LiveViewMacro_InvalidEvents`

❌ **Avoid**:
- `test1`, `macro_test` (not descriptive)
- `RouterTest` (too generic)
- `invalid_test` (doesn't indicate what macro/feature)

#### When to Use Flexible Positions

✅ **Use `flexible-positions` for**:
- Warning message content validation
- CI/CD environments 
- Refactoring-resistant tests
- Focus on macro logic, not exact positions

❌ **Use standard mode for**:
- Debugging specific line number issues
- Position-critical validations
- Ensuring warnings appear at exact locations

#### Complete Example Test Cases

**Valid Case Test** (`MyMacro_ValidInput`):
```haxe
// Should produce no warnings
@:myMacro([{name: "valid", value: "test"}])
class ValidTest {}
```
```bash
# expected_stderr.txt - Empty file or comments only
# No warnings expected for valid macro usage
```

**Invalid Case Test** (`MyMacro_InvalidInput`):
```haxe
// Should produce specific warnings
@:myMacro([{name: "", value: "test"}])  // Empty name warning
class InvalidTest {}
```
```bash
# expected_stderr_flexible.txt
Warning : Empty name field not allowed in MyMacro definition
```

#### Integration with TestRunner

The TestRunner automatically:
- ✅ Validates both generated code AND stderr output
- ✅ Chooses appropriate expected file based on `flexible-positions` flag
- ✅ Provides detailed diff output when validation fails
- ✅ Normalizes stderr content (removes comments, trims whitespace)
- ✅ Strips position information when using flexible mode

### 8. Complete LLM Testing Workflows ⚡

**For future LLM agents**: These are complete, end-to-end examples of different testing scenarios you'll encounter.

#### Scenario 1: Testing a New Build Macro with Validation

**Context**: You've created a new `@:mySchema` build macro that validates field types and generates Elixir structs.

**Complete Workflow**:
```bash
# 1. Create the test structure
mkdir test/tests/MySchema_ValidStruct
mkdir test/tests/MySchema_InvalidFields  
mkdir test/tests/MySchema_MultipleErrors

# 2. Create valid case test (MySchema_ValidStruct)
cat > test/tests/MySchema_ValidStruct/Main.hx << 'EOF'
@:mySchema({
    name: "User",
    fields: [
        {name: "id", type: "Int"},
        {name: "email", type: "String"}
    ]
})
class ValidUserSchema {}
EOF

# 3. Create invalid case test (MySchema_InvalidFields)
cat > test/tests/MySchema_InvalidFields/Main.hx << 'EOF'
@:mySchema({
    name: "User", 
    fields: [
        {name: "", type: "Int"},        // Invalid: empty name
        {name: "email", type: "Unknown"} // Invalid: unknown type
    ]
})
class InvalidUserSchema {}
EOF

# 4. Create compilation configs (same for all)
for test in MySchema_ValidStruct MySchema_InvalidFields MySchema_MultipleErrors; do
    cat > test/tests/$test/compile.hxml << 'EOF'
-cp ../../../std
-cp ../../../src
-cp .
-lib reflaxe
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out
Main
EOF
done

# 5. Run tests to see actual warning format
haxe test/Test.hxml test=MySchema_InvalidFields show-output

# 6. Create expected stderr files based on actual output
cat > test/tests/MySchema_ValidStruct/expected_stderr.txt << 'EOF'
# No warnings expected for valid schema
EOF

cat > test/tests/MySchema_InvalidFields/expected_stderr_flexible.txt << 'EOF'
Warning : Empty field name not allowed in MySchema definition
Warning : Unknown field type "Unknown" in MySchema. Valid types: Int, String, Bool, Float
EOF

# 7. Generate intended output
haxe test/Test.hxml test=MySchema_ValidStruct update-intended
haxe test/Test.hxml test=MySchema_InvalidFields update-intended

# 8. Verify all tests pass
haxe test/Test.hxml test=MySchema_ValidStruct
haxe test/Test.hxml test=MySchema_InvalidFields flexible-positions

# 9. Run full suite to ensure no regressions
npm test
```

#### Scenario 2: Testing a New Compiler Feature

**Context**: You've added support for Elixir `with` statements via `@:with` annotation.

**Complete Workflow**:
```bash
# 1. Create snapshot test
mkdir test/tests/with_statement_basic

# 2. Create test source demonstrating the feature
cat > test/tests/with_statement_basic/Main.hx << 'EOF'
@:with
class WithStatementExample {
    public function processUser(): String {
        return @:elixir('
            with {:ok, user} <- User.fetch(),
                 {:ok, profile} <- Profile.fetch(user.id),
                 {:ok, settings} <- Settings.fetch(profile.id) do
                "#{user.name} - #{profile.bio}"
            else
                {:error, reason} -> "Error: #{reason}"
                _ -> "Unknown error"
            end
        ');
    }
}
EOF

# 3. Create compilation config
cat > test/tests/with_statement_basic/compile.hxml << 'EOF'
-cp ../../../std
-cp ../../../src
-cp .
-lib reflaxe
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out
Main
EOF

# 4. Generate intended output
haxe test/Test.hxml test=with_statement_basic update-intended

# 5. Verify generated Elixir looks correct
cat test/tests/with_statement_basic/intended/Main.ex

# 6. Test the feature
haxe test/Test.hxml test=with_statement_basic

# 7. Create additional edge case tests
mkdir test/tests/with_statement_nested
mkdir test/tests/with_statement_errors
# ... repeat process for edge cases
```

#### Scenario 3: Testing Framework Integration

**Context**: You've enhanced Phoenix LiveView support and need to test real-world integration.

**Complete Workflow**:
```bash
# 1. Create example project (if doesn't exist)
mkdir examples/09-enhanced-liveview
cd examples/09-enhanced-liveview

# 2. Initialize Phoenix project structure
mix phx.new . --no-ecto --no-gettext --binary-id

# 3. Create Haxe LiveView source
mkdir src_haxe
cat > src_haxe/EnhancedLive.hx << 'EOF'
@:liveView("enhanced")
class EnhancedLive {
    @:mount
    public function mount(params: Dynamic, session: Dynamic, socket: Socket): Socket {
        return Socket.assign(socket, "count", 0);
    }
    
    @:handle_event("increment")
    public function handleIncrement(event: Dynamic, socket: Socket): Socket {
        return Socket.assign(socket, "count", socket.assigns.count + 1);
    }
}
EOF

# 4. Create build configuration
cat > build.hxml << 'EOF'
-cp src_haxe
-lib reflaxe.elixir
-D reflaxe_runtime
-D elixir_output=lib
EnhancedLive
EOF

# 5. Test compilation
npx haxe build.hxml

# 6. Verify generated Phoenix code
cat lib/enhanced_live.ex

# 7. Create Phoenix integration test
cat > test/enhanced_live_test.exs << 'EOF'
defmodule EnhancedLiveTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest
  
  test "enhanced live view compiles and mounts" do
    assert {:ok, view, html} = live(build_conn(), "/enhanced")
    assert html =~ "count"
  end
end
EOF

# 8. Test Phoenix integration
mix test

# 9. Add to CI if successful
cd ../..
echo "Enhanced LiveView integration verified" >> docs/06-guides/EXAMPLES.md
```

#### Common Patterns for All Scenarios

**Before Starting Any Test**:
```bash
# Always check current status first
npm test                    # Verify no existing failures
git status                  # Ensure clean working tree
```

**After Creating Tests**:
```bash
# Verify your test works in isolation
haxe test/Test.hxml test=YourTestName

# Test flexible position matching if applicable
haxe test/Test.hxml test=YourTestName flexible-positions

# Run full suite to check for regressions  
npm test

# If tests pass, document what you've added
echo "Added YourFeature testing" >> docs/09-history/archive/records/task-history.md
```

**Testing Philosophy**:
- ✅ **Test the behavior, not the implementation**
- ✅ **Create both valid and invalid cases**
- ✅ **Use realistic examples users would actually write**
- ✅ **Verify generated code compiles and runs**
- ✅ **Document what each test validates**

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



## Parallel Testing Architecture ⚡

### Overview

Reflaxe.Elixir's test suite traditionally runs sequentially, taking ~229 seconds for 62 tests (3.7s per test). The parallel testing architecture aims to reduce this to ~30 seconds with an 87% performance improvement.

### Design Principles

1. **Process-Based Parallelization**: Each test runs in an isolated Haxe process to avoid shared state issues
2. **Work-Stealing Queue**: Dynamic test distribution ensures optimal load balancing
3. **Non-Blocking Process Management**: Workers check completion status without blocking the main process
4. **Robust Error Handling**: Process failures are contained and reported properly

### Components

#### 1. ParallelTestRunner.hx
- **Main orchestrator** for parallel test execution
- Manages worker pool and test queue distribution
- Collects results and provides progress reporting
- Handles command-line argument parsing and configuration

```haxe
// Key features:
- Configurable worker count (default 8, configurable via -j flag)
- Real-time progress reporting with emoji status indicators
- Timeout protection (5 minutes maximum)
- Performance improvement calculations
```

#### 2. TestWorker Class
- **Individual worker** that executes tests in isolation
- Spawns separate `haxe` processes for each test
- Handles directory context switching and process cleanup
- Implements non-blocking result checking

```haxe
// Key features:
- Non-blocking process.exitCode(false) for async completion
- Directory context management (setCwd/restore pattern)
- Output comparison using same logic as TestRunner.hx
- Error handling and process resource cleanup
```

#### 3. SimpleParallelTest.hx (Debug Version)
- **Sequential fallback** for debugging parallel execution issues
- Validates basic process execution works correctly
- Same test logic as parallel version but without worker coordination
- Useful for isolating issues between process execution vs. parallel coordination

### Usage Patterns

```bash
# Run all tests in parallel (default 8 workers)
haxe test/ParallelTest.hxml

# Run with specific worker count
haxe test/ParallelTest.hxml -j 4

# Run specific tests
haxe test/ParallelTest.hxml test=arrays test=liveview

# Update intended output in parallel
haxe test/ParallelTest.hxml update-intended

# Debug version (sequential)
haxe test/SimpleParallelTest.hxml test=arrays
```

### Implementation Status

✅ **Completed**:
- ParallelTestRunner.hx with full feature set
- TestWorker process management
- Command-line argument parsing compatible with TestRunner.hx
- SimpleParallelTest.hx debug version working correctly
- HXML configurations for both interpreter and Elixir targets

🔄 **In Progress**:
- Fixing worker coordination hang issue
- Process completion detection reliability
- Worker-to-main communication improvements

📋 **Planned**:
- Test result caching mechanism
- Test categorization for targeted execution
- Haxe server mode optimization
- Performance monitoring and metrics

### Architecture Insights

**Process vs. Thread**: We chose process-based parallelization over threads because:
- No shared state issues between tests
- Complete isolation prevents cross-test interference  
- Simpler error handling and resource cleanup
- Aligns with Haxe's execution model

**Non-Blocking Polling**: Workers use `process.exitCode(false)` for non-blocking completion checks:
- Prevents the main process from hanging on worker processes
- Allows concurrent monitoring of multiple workers
- Enables timeout detection and graceful shutdown

**Directory Context Management**: Each worker properly handles test directory context:
- Save original working directory before test execution
- Change to test directory for compilation (matches TestRunner behavior)
- Restore original directory even on exceptions
- Ensures tests run in correct context without affecting other workers

### Experimental Features

**Elixir Target Compilation**: ParallelTestElixir.hxml compiles the test runner to Elixir:
- Dogfooding approach using our own compiler for tooling
- Tests complex language features like sys.io.Process → System.cmd
- Performance comparison opportunity vs. interpreter version
- Foundation for future self-hosting capabilities

This represents an important milestone in compiler maturity - using our own output for development tooling.

### Platform Considerations and Process Management ⚠️

**Critical Fix**: The parallel test runner originally used `process.exitCode(false)` for non-blocking process completion checks. This approach proved unreliable on macOS, causing worker processes to hang indefinitely and accumulate as zombie processes.

#### The Problem: Deep Technical Analysis

```haxe
// PROBLEMATIC APPROACH (caused hanging on macOS)
final exitCode = process.exitCode(false); // false = non-blocking
if (exitCode == null) return null; // Still running
```

**Root Cause Analysis**:

The issue stems from platform-specific behaviors in the underlying `waitpid` system call with `WNOHANG` flag on macOS:

1. **Signal Consolidation**: macOS can consolidate multiple `SIGCHLD` signals when children exit simultaneously, leading to missed process state changes
2. **Race Conditions**: Non-blocking `waitpid` calls can return inconsistent results during rapid process creation/termination cycles  
3. **Status Checking Errors**: When `waitpid` returns 0 (child still running), the status variable is undefined and should not be checked
4. **macOS-Specific Quirks**: macOS lacks advanced process control features like Linux's child subreaper, making process group management more fragile

**Technical Details**:
- `waitpid(pid, &status, WNOHANG)` returns:
  - `0` if child is still running (status undefined)
  - `pid` if child state changed (status valid)
  - `-1` on error
- The Haxe interpreter's `sys.io.Process.exitCode(false)` maps to `NativeProcess.process_exit(p, false)` 
- On macOS, this can hang when the underlying C implementation incorrectly handles the return value scenarios

**Empirical Evidence**:
- **265 zombie haxe processes** accumulated during parallel testing 
- **Indefinite hanging** despite process completion
- **Resource exhaustion** causing system performance degradation
- **Test timeouts** after 2+ minutes of hanging

#### The Solution: Timeout-Based Process Management
```haxe
// RELIABLE APPROACH (working on all platforms)
final elapsed = haxe.Timer.stamp() - startTime;
final TIMEOUT = 10.0; // 10 seconds timeout per test

if (elapsed > TIMEOUT) {
    // Process timed out - kill it and return failure
    try {
        process.kill();
        process.close();
    } catch (e: Dynamic) {
        // Ignore cleanup errors
    }
    pendingResult = {
        testName: currentTest,
        success: false,
        duration: elapsed,
        errorMessage: 'Test timed out after ${TIMEOUT}s'
    };
    isRunning = false;
    return pendingResult;
}

try {
    final exitCode = process.exitCode(); // This will throw if still running
    // Process completed - collect results
} catch (e: Dynamic) {
    // Process still running - return null to check again later
    return null;
}
```

#### Key Improvements
1. **Timeout Protection**: Each test limited to 10 seconds maximum execution
2. **Proper Resource Cleanup**: Explicit process termination and cleanup on timeout
3. **Exception Handling**: Graceful handling of process state edge cases
4. **Platform Independence**: Works reliably on macOS, Linux, and Windows

#### Performance Results
- **Before**: 265 zombie processes, indefinite hanging, 229+ second execution time
- **After**: Clean process management, 31.2 second execution time (85% improvement)
- **Resource Usage**: No zombie processes, proper cleanup on completion/timeout

#### Best Practices for Process Management

Based on this research, here are the key principles for robust cross-platform process management:

1. **Always implement timeouts** for external process execution
   - Prevents indefinite hanging from platform-specific edge cases
   - Essential for parallel processing where one hanging process can block entire pipeline

2. **Use synchronous exitCode()** within try/catch instead of non-blocking calls
   - Avoids complex `waitpid` WNOHANG edge cases and signal consolidation issues
   - Exception handling provides cleaner error detection than checking return values

3. **Explicit cleanup** with process.kill() and process.close() on timeout
   - Prevents zombie process accumulation
   - Essential on macOS where process group management is more fragile

4. **Exception-safe cleanup** to handle edge cases during termination
   - Graceful degradation when cleanup operations themselves fail
   - Prevents cascading failures in parallel environments

5. **Understand platform differences** in process control
   - macOS lacks advanced features like Linux's child subreaper
   - Signal delivery and consolidation behaviors vary between platforms
   - Test thoroughly on target platforms, especially for parallel processing

6. **Avoid relying on non-blocking process operations** for critical infrastructure
   - Polling with timeouts is more reliable than event-driven approaches
   - Reduces complexity and improves debuggability

**Alternative Approaches Considered**:
- **Signal handling (SIGCHLD)**: Complex to implement correctly, platform-specific behavior
- **Event loops**: Added complexity, potential for race conditions  
- **Native process libraries**: External dependencies, compilation complexity
- **Timeout + polling**: ✅ **Chosen** - Simple, reliable, cross-platform compatible

This fix ensures the parallel testing infrastructure is robust and reliable across all development platforms, with deep understanding of the underlying system-level challenges.

## References

- [Architecture Documentation](ARCHITECTURE.md)
- [Haxe Macro Documentation](https://haxe.org/manual/macro.html)

# Testing Overview for Reflaxe.Elixir: A Comprehensive Guide for LLMs

## Executive Summary

Reflaxe.Elixir uses a **multi-layered testing architecture** designed around the unique challenges of testing a macro-time transpiler. This document provides a complete guide for LLMs/agents working on the codebase to understand what tests exist, when to use each type, and how to write effective tests for new features.

**Total Coverage**: 172+ tests across 4 test types
- **28 Snapshot Tests**: Validate compiler output (AST → Elixir transformation)
- **130+ Mix Tests**: Validate build integration and runtime behavior
- **9 Example Tests**: Validate real-world usage patterns
- **Compile-time Tests**: Validate macro warnings and DSL validation (subset of snapshot tests)

## The Core Challenge: Testing a Macro-Time Transpiler

### Why Testing is Complex

Reflaxe.Elixir presents unique testing challenges:

```haxe
#if macro
// This code ONLY exists during Haxe compilation
class ElixirCompiler extends BaseCompiler {
    // Transforms TypedExpr AST → Elixir code
    // Then DISAPPEARS after compilation
}
#end

// This runs AFTER compilation when compiler is gone
class MyTest {
    function test() {
        // ❌ ERROR: ElixirCompiler doesn't exist here
        var compiler = new ElixirCompiler();
    }
}
```

**Key Insight**: You can't unit test the compiler directly - it only exists at macro-time, not at runtime when tests execute.

**Solution**: Test the OUTPUT and INTEGRATION, not the internal compiler state.

## Test Type Matrix

| Test Type | Purpose | Tests What | When to Use | Example |
|-----------|---------|------------|-------------|---------|
| **Snapshot Tests** | Validate transpiler output | Haxe AST → Elixir code transformation | New language features, syntax generation | `test/tests/liveview_basic/` |
| **Compile-Time Tests** | Validate macro warnings/errors | DSL validation, build macro warnings | Testing @:route validation, macro error messages | `test/tests/RouterBuildMacro_InvalidController/` |
| **Mix Integration Tests** | Validate build system & runtime | Generated code compiles & runs in BEAM | Build system changes, runtime behavior | `test/mix_integration_test.exs` |
| **Example Tests** | Validate real-world usage | Complete application workflows | Framework integration, documentation | `examples/todo-app/` |

## Test Type 1: Snapshot Tests (28 tests)

### What They Test
Validates that the ElixirCompiler correctly transforms Haxe TypedExpr AST into syntactically correct Elixir code.

### Structure
```
test/tests/feature_name/
├── compile.hxml    # Haxe compilation config
├── Main.hx         # Test source code  
├── intended/       # Expected Elixir output
│   └── Main.ex     # Golden file for comparison
└── out/            # Generated output (temporary)
```

### How They Work
1. **Compile**: TestRunner.hx invokes Haxe compiler on test source
2. **Generate**: ElixirCompiler transforms AST to .ex files in `out/`
3. **Compare**: Compare `out/` vs `intended/` directories
4. **Report**: Show differences or success

### When to Use Snapshot Tests
- ✅ Testing new compiler features (annotations, expression types)
- ✅ Validating code generation improvements  
- ✅ Ensuring syntax generation correctness
- ✅ Regression testing core functionality

### Commands
```bash
# Run all snapshot tests
npm run test:haxe

# Run specific test
haxe test/Test.hxml test=feature_name

# Update expected output (after verifying it's correct)
haxe test/Test.hxml test=feature_name update-intended

# Show detailed compilation output
haxe test/Test.hxml test=feature_name show-output
```

### Creating New Snapshot Tests
```bash
# 1. Create test directory
mkdir test/tests/my_new_feature

# 2. Create Haxe source
cat > test/tests/my_new_feature/Main.hx << 'EOF'
@:myNewFeature
class TestClass {
    public function new() {}
    
    public function testMethod(): String {
        return "test result";
    }
}
EOF

# 3. Create compilation config
cat > test/tests/my_new_feature/compile.hxml << 'EOF'
-cp ../../../std
-cp ../../../src  
-cp .
-lib reflaxe
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out
Main
EOF

# 4. Generate expected output
haxe test/Test.hxml test=my_new_feature update-intended

# 5. Verify test passes
haxe test/Test.hxml test=my_new_feature
```

## Test Type 2: Compile-Time Validation Tests

### What They Test
Validates macro-time validation logic, warning messages, and error handling during compilation. These are specialized snapshot tests that also validate stderr output.

### Structure
```
test/tests/MacroName_ValidationScenario/
├── compile.hxml            # Standard compilation config
├── Main.hx                 # Test source with invalid usage
├── expected_stderr.txt     # Expected warnings (exact positions)
├── expected_stderr_flexible.txt # Expected warnings (position-independent)
├── intended/               # Expected Elixir output
│   └── Main.ex
└── out/                    # Actual output
```

### When to Use Compile-Time Tests
- ✅ Testing build macro validation (RouterBuildMacro, schema validation)
- ✅ Validating warning/error messages from DSLs
- ✅ Testing compile-time constraint checking
- ✅ Ensuring helpful developer feedback

### Two Validation Modes

**Standard Mode** (exact position matching):
```bash
# expected_stderr.txt
Main.hx:39: lines 39-41 : Warning : Controller "NonExistentController" not found. Ensure the class exists and is in the classpath.
```

**Flexible Mode** (position-independent):
```bash
# expected_stderr_flexible.txt  
Warning : Controller "NonExistentController" not found. Ensure the class exists and is in the classpath.
```

### Commands
```bash
# Test with exact position matching
haxe test/Test.hxml test=RouterBuildMacro_InvalidController

# Test with flexible position matching (more robust)
haxe test/Test.hxml test=RouterBuildMacro_InvalidController flexible-positions
```

### Creating Compile-Time Tests
```bash
# 1. Create test with invalid usage
mkdir test/tests/MyMacro_InvalidInput

# 2. Create source with validation failures
cat > test/tests/MyMacro_InvalidInput/Main.hx << 'EOF'
@:myMacro({
    name: "",           // Should trigger: empty name warning
    value: "test"
})
class InvalidTest {}
EOF

# 3. Run to see actual warning format
haxe test/Test.hxml test=MyMacro_InvalidInput show-output

# 4. Create expected stderr (flexible mode recommended)
cat > test/tests/MyMacro_InvalidInput/expected_stderr_flexible.txt << 'EOF'
Warning : Empty name field not allowed in MyMacro definition
EOF

# 5. Generate intended output and test
haxe test/Test.hxml test=MyMacro_InvalidInput update-intended
haxe test/Test.hxml test=MyMacro_InvalidInput flexible-positions
```

## Test Type 3: Mix Integration Tests (130+ tests)

### What They Test
Validates that the generated Elixir code actually compiles and runs correctly in the BEAM VM, plus build system integration.

### Categories

#### 1. Build System Tests (`test/mix_integration_test.exs`)
- Mix.Tasks.Compile.Haxe integration
- Incremental compilation
- File watching and hot reload
- Error handling and reporting
- Build manifest tracking

#### 2. File Watching Tests (`test/haxe_watcher_test.exs`)
- HaxeWatcher GenServer behavior
- File system event handling
- Compilation triggering
- Error recovery

#### 3. Compiler Tests (`test/haxe_compiler_test.exs`)
- Haxe compiler invocation
- Source → target mapping
- Error parsing and formatting
- Build configuration handling

### When to Use Mix Tests
- ✅ Testing build system changes
- ✅ Validating that generated Elixir compiles
- ✅ Testing runtime behavior of generated code
- ✅ Testing Phoenix/Ecto integration
- ✅ Testing file watching and hot reload

### Structure
```elixir
defmodule MyFeatureIntegrationTest do
  use ExUnit.Case
  import TestSupport.ProjectHelpers

  test "my feature integrates with build system" do
    # 1. Create temporary project
    project_dir = create_temp_project()
    
    # 2. Write test Haxe files
    File.write!(Path.join(project_dir, "src_haxe/Test.hx"), """
    @:myFeature
    class Test {
        public function new() {}
    }
    """)
    
    # 3. Run Haxe compiler
    {:ok, compiled} = Mix.Tasks.Compile.Haxe.run([])
    
    # 4. Verify generated Elixir
    output_file = Path.join(project_dir, "lib/test.ex")
    assert File.exists?(output_file)
    
    output = File.read!(output_file)
    assert output =~ "defmodule Test do"
    
    # 5. Verify Elixir compilation
    assert {:ok, _} = Code.compile_string(output)
  end
end
```

### Commands
```bash
# Run all Mix tests
MIX_ENV=test mix test

# Run specific test file
MIX_ENV=test mix test test/my_feature_test.exs

# Run with detailed output
MIX_ENV=test mix test --trace
```

## Test Type 4: Example/Integration Tests (9 examples)

### What They Test
Real-world usage patterns using complete Phoenix applications that demonstrate the transpiler working in production-like scenarios.

### Examples
- `examples/todo-app/` - Complete Phoenix LiveView application
- `examples/api-server/` - Phoenix API server
- `examples/ecto-migrations/` - Database migration examples
- `examples/otp-patterns/` - OTP GenServer/Supervisor patterns

### When to Use Example Tests
- ✅ Testing complete application workflows
- ✅ Validating Phoenix framework integration
- ✅ Demonstrating real-world usage patterns
- ✅ Documentation and onboarding
- ✅ Performance and scalability testing

### Structure
```
examples/feature-name/
├── src_haxe/          # Haxe source files
├── lib/               # Generated Elixir code  
├── mix.exs            # Phoenix project config
├── config/            # Phoenix configuration
├── build.hxml         # Haxe compilation config
└── test/              # Phoenix/ExUnit tests
```

### Commands
```bash
# Compile example
cd examples/todo-app
npx haxe build.hxml

# Test Phoenix integration
mix test
mix compile
mix phx.server
```

## Testing Decision Flowchart

When working on a new feature, follow this decision flow:

```
New Feature/Bug Fix
        ↓
Is it a compiler feature? 
    ├─ YES → Create snapshot test first
    │         ├─ Does it include validation/DSL?
    │         │   ├─ YES → Add compile-time validation test
    │         │   └─ NO → Snapshot test sufficient
    │         └─ Does it affect build system?
    │             ├─ YES → Add Mix integration test
    │             └─ NO → Continue
    └─ NO → Is it build system related?
            ├─ YES → Create Mix integration test
            └─ NO → Is it framework integration?
                    ├─ YES → Create/update example
                    └─ NO → Determine appropriate test type
                    
After creating tests:
        ↓
Does it need real-world demonstration?
    ├─ YES → Create or update example
    └─ NO → Tests complete
```

## Common Testing Workflows

### Workflow 1: New Annotation Feature
```bash
# 1. Create snapshot test for basic functionality
mkdir test/tests/my_annotation_basic
# ... create test files ...
haxe test/Test.hxml test=my_annotation_basic update-intended

# 2. If annotation includes validation, add compile-time test
mkdir test/tests/MyAnnotation_InvalidInput
# ... create validation test ...
haxe test/Test.hxml test=MyAnnotation_InvalidInput flexible-positions

# 3. If complex feature, create example
mkdir examples/08-my-annotation
# ... create working example ...
```

### Workflow 2: Build System Enhancement
```bash
# 1. Create Mix integration test
# Add to test/mix_integration_test.exs or create new test file

# 2. Test the enhancement
MIX_ENV=test mix test test/my_enhancement_test.exs

# 3. If affects file watching, test with HaxeWatcher
MIX_ENV=test mix test test/haxe_watcher_test.exs
```

### Workflow 3: Bug Fix
```bash
# 1. Create test that reproduces the bug
# Choose appropriate test type based on bug location

# 2. Verify test fails
npm test  # Should show the bug

# 3. Fix the bug
# Edit compiler source

# 4. Verify test passes  
npm test  # Should pass after fix

# 5. Update intended output if needed
haxe test/Test.hxml update-intended
```

## Best Practices for Each Test Type

### Snapshot Tests
- ✅ Keep tests focused on single features
- ✅ Test both valid and edge cases
- ✅ Use descriptive test names (`liveview_basic` not `test1`)
- ✅ Verify generated code is idiomatic Elixir
- ❌ Don't manually write intended output files
- ❌ Don't test internal compiler state

### Compile-Time Tests
- ✅ Test both valid and invalid cases
- ✅ Use flexible position matching when possible
- ✅ Include clear warning messages
- ✅ Group related validation scenarios
- ❌ Don't hardcode line numbers unnecessarily
- ❌ Don't skip testing valid cases

### Mix Tests
- ✅ Test integration, not implementation details
- ✅ Use temporary directories for isolation
- ✅ Verify generated code actually compiles and runs
- ✅ Test error handling and recovery
- ❌ Don't test internal ElixirCompiler methods (they don't exist at runtime)
- ❌ Don't assume file paths or working directories

### Example Tests
- ✅ Use realistic data and scenarios
- ✅ Test complete workflows
- ✅ Include both development and production configs
- ✅ Document usage patterns clearly
- ❌ Don't create trivial examples
- ❌ Don't skip Phoenix-specific functionality

## Troubleshooting Common Testing Issues

### 1. "ElixirCompiler not found" at runtime
**Problem**: Trying to instantiate the compiler in a runtime test
**Solution**: Use snapshot tests to test compiler output, not compiler internals

### 2. "Library reflaxe.elixir is not installed" 
**Problem**: Missing haxe_libraries/reflaxe.elixir.hxml or path issues
**Solution**: Check self-referential library configuration (see SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md)

### 3. Snapshot test output doesn't match
**Problem**: Generated code differs from intended output
**Solution**: 
```bash
# View the differences
haxe test/Test.hxml test=feature_name show-output

# If changes are correct, update intended output
haxe test/Test.hxml test=feature_name update-intended
```

### 4. Compile-time test position mismatches
**Problem**: Line numbers change when code is refactored
**Solution**: Use flexible position matching
```bash
haxe test/Test.hxml test=MyMacro_Test flexible-positions
```

### 5. Mix test failures due to compilation errors
**Problem**: Generated Elixir has syntax errors
**Solution**: Fix the ElixirCompiler code generation, don't modify tests

### 6. Example doesn't compile
**Problem**: Phoenix/framework integration issues
**Solution**: Check file locations, module names, Phoenix conventions

## ExUnit Testing Philosophy ⚠️

### Critical Rule: Always Write ExUnit Tests in Haxe

**NEVER write ExUnit tests directly in Elixir** - this breaks the core philosophy of Reflaxe.Elixir.

#### Why This Matters

Reflaxe.Elixir's core value proposition is **"write once in Haxe, deploy everywhere"**. Writing tests directly in the target language undermines this principle:

- ❌ **Direct Elixir tests**: Lose Haxe's type safety and compile-time guarantees
- ❌ **Manual ExUnit modules**: No integration with Haxe testing infrastructure
- ❌ **Split testing approaches**: Inconsistent patterns across codebase

#### The Correct Approach

✅ **Write tests in Haxe using ExUnit externs**:

```haxe
import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;
import haxe.validation.Email;

@:exunit
class DomainAbstractionsTest extends TestCase {
    @:test
    function testEmailValidation() {
        var validEmail = Email.parse("user@example.com");
        Assert.isOk(validEmail, "Valid email should parse");
        
        switch (validEmail) {
            case Ok(email):
                Assert.equals("example.com", email.getDomain());
            case Error(reason):
                Assert.fail("Email should be valid: " + reason);
        }
    }
}
```

#### Generated ExUnit Code

The above Haxe code compiles to idiomatic Elixir ExUnit:

```elixir
defmodule DomainAbstractionsTest do
  use ExUnit.Case

  test "email validation" do
    valid_email = Email_Impl_.parse("user@example.com")
    assert ResultTools.is_ok(valid_email)
    
    case valid_email do
      {:ok, email} ->
        assert Email_Impl_.getDomain(email) == "example.com"
      {:error, reason} ->
        flunk("Email should be valid: " <> reason)
    end
  end
end
```

#### Benefits of Haxe ExUnit Tests

1. **Type Safety**: Haxe's type system catches errors at compile time
2. **Single Source of Truth**: All test logic defined in Haxe
3. **Cross-Platform**: Same test patterns work for all Reflaxe targets
4. **IDE Support**: Full Haxe tooling (autocomplete, refactoring, etc.)
5. **Consistent API**: Same Assert methods across all test files

#### When to Use ExUnit Tests

Use Haxe ExUnit tests for:
- **Domain logic validation**: Testing business rules and domain abstractions
- **Integration testing**: Validating that generated code works correctly in BEAM
- **Framework integration**: Testing Phoenix/Ecto/OTP integration points
- **Regression testing**: Ensuring fixes continue to work

#### Example: Domain Abstractions Testing

The domain abstractions test (`test/tests/domain_abstractions_exunit/`) demonstrates this philosophy:

- **Written in Haxe**: Full type safety and modern language features
- **Comprehensive coverage**: Email, UserId, PositiveInt, NonEmptyString validation
- **Result/Option integration**: Tests functional programming patterns
- **Real-world scenarios**: Validates practical usage patterns
- **Generated ExUnit**: Compiles to proper ExUnit test modules

#### Test Structure

```
test/tests/domain_abstractions_exunit/
├── Main.hx          # Haxe test source with @:exunit annotation
├── compile.hxml     # Compilation configuration
└── out/
    └── Main.ex      # Generated ExUnit test module
```

#### Integration with Test Suite

ExUnit tests integrate seamlessly with the existing test infrastructure:

```bash
# Compile Haxe tests to ExUnit
cd test/tests/domain_abstractions_exunit && haxe compile.hxml

# Run generated ExUnit tests
mix test test/tests/domain_abstractions_exunit/out/Main.ex
```

This approach ensures that all tests benefit from Haxe's type system while generating proper ExUnit code that follows Elixir conventions.

## Related Documentation

- **[TESTING_PRINCIPLES.md](TESTING_PRINCIPLES.md)** - Core testing philosophy and rules
- **[architecture/TESTING.md](architecture/TESTING.md)** - Technical testing infrastructure
- **[TEST_TYPES.md](TEST_TYPES.md)** - Detailed test type documentation
- **[TEST_SUITE_DEEP_DIVE.md](TEST_SUITE_DEEP_DIVE.md)** - Analysis of all 172+ tests
- **[SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md](SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md)** - Library configuration issues

## Quick Commands Reference

```bash
# All tests
npm test                                    # Run everything (snapshot + Mix)

# Snapshot tests  
npm run test:haxe                          # All snapshot tests
haxe test/Test.hxml test=feature_name      # Specific test
haxe test/Test.hxml update-intended        # Update expected output
haxe test/Test.hxml show-output           # Show compilation details

# Compile-time validation
haxe test/Test.hxml test=MacroName_Invalid flexible-positions

# Mix tests
MIX_ENV=test mix test                      # All Mix tests
MIX_ENV=test mix test test/specific.exs    # Specific test file

# Examples
cd examples/todo-app && mix test          # Test example integration
```

This comprehensive guide ensures that LLMs understand the full testing architecture and can choose the appropriate test type for any development scenario.
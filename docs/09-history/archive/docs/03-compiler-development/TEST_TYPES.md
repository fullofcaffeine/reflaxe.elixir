# Test Types and Organization in Reflaxe.Elixir

This document explains the different types of tests used in Reflaxe.Elixir, when to use each type, and how they work together to ensure comprehensive coverage of the transpiler functionality.

## Test Type Overview

Reflaxe.Elixir uses multiple complementary testing approaches to validate different aspects of the compilation process:

| Test Type | Purpose | Location | When to Use |
|-----------|---------|----------|-------------|
| **Snapshot Tests** | Validate generated Elixir code | `test/tests/` | Testing transpilation output |
| **Compile-Time Tests** | Test macro warnings/errors | `test/tests/` + `expected_stderr.txt` | Testing validation logic |
| **Integration Tests** | Phoenix framework compatibility | `examples/` | Testing real-world usage |
| **Mix Tests** | Runtime Elixir functionality | `test/mix_tests/` | Testing generated code execution |

## 1. Snapshot Tests 📸

### Purpose
Validate that Haxe source code transpiles to correct Elixir code by comparing generated output against expected "golden" files.

### Structure
```
test/tests/feature_name/
├── compile.hxml    # Haxe compilation configuration
├── Main.hx         # Test source code
├── intended/       # Expected output (golden files)
│   ├── Main.ex     # Expected generated Elixir
│   └── OtherClass.ex
└── out/            # Actual output (temporary)
```

### Examples
- `test/tests/basic_class/` - Basic class compilation
- `test/tests/enums/` - Enum transpilation
- `test/tests/liveview_basic/` - LiveView component generation
- `test/tests/ecto_schema/` - Ecto schema compilation

### When to Use
- ✅ Testing new language features
- ✅ Validating code generation improvements
- ✅ Ensuring transpilation consistency
- ✅ Regression testing core functionality

### Commands
```bash
# Run all snapshot tests
npm test

# Run specific test
haxe test/Test.hxml test=feature_name

# Update expected output (after verifying it's correct)
haxe test/Test.hxml test=feature_name update-intended

# View detailed output
haxe test/Test.hxml test=feature_name show-output
```

## 2. Compile-Time Validation Tests ⚠️

### Purpose
Test macro-time validation logic, warning messages, and error handling during compilation. Essential for testing build macros and compile-time DSLs.

### Structure
```
test/tests/RouterBuildMacro_InvalidController/
├── compile.hxml        # Standard compilation config
├── Main.hx             # Test source with invalid references
├── expected_stderr.txt # Expected warnings/errors
├── intended/           # Expected Elixir output
│   └── Main.ex
└── out/                # Actual output
```

### Examples
- `test/tests/RouterBuildMacro_ValidController/` - No warnings expected
- `test/tests/RouterBuildMacro_InvalidController/` - Controller not found warning
- `test/tests/RouterBuildMacro_InvalidAction/` - Action not found warning
- `test/tests/RouterBuildMacro_MultipleInvalid/` - Multiple validation failures

### When to Use
- ✅ Testing build macro validation logic
- ✅ Validating warning/error messages
- ✅ Testing DSL constraint checking
- ✅ Ensuring appropriate developer feedback

### Expected Stderr Format
```bash
# No warnings case (empty or comments only)
# Expected stderr output for valid test
# Should be empty - no warnings expected

# Single warning case
Main.hx:39: lines 39-41 : Warning : Controller "NonExistentController" not found. Ensure the class exists and is in the classpath.

# Multiple warnings case
Main.hx:67: lines 67-69 : Warning : Controller "NonExistentController" not found. Ensure the class exists and is in the classpath.
Main.hx:67: lines 67-69 : Warning : Action "create" not found on controller "PartialController".
```

## 3. Integration Tests 🔗

### Purpose
Test real-world usage patterns and framework integration using complete Phoenix applications.

### Structure
```
examples/todo-app/
├── src_haxe/          # Haxe source files
├── lib/               # Generated Elixir code
├── mix.exs            # Phoenix project configuration
├── config/            # Phoenix configuration
└── test/              # Phoenix/ExUnit tests
```

### Examples
- `examples/todo-app/` - Complete Phoenix LiveView application
- `examples/api-server/` - Phoenix API server example
- `examples/ecto-migrations/` - Database migration examples

### When to Use
- ✅ Testing complete application workflows
- ✅ Validating Phoenix framework integration
- ✅ Testing real-world usage patterns
- ✅ Performance and integration validation

### Commands
```bash
# Compile example
cd examples/todo-app
npx haxe build.hxml

# Test Phoenix integration
mix test
mix compile
```

## 4. Mix Tests (Future) 🧪

### Purpose
Test that generated Elixir code executes correctly at runtime by running ExUnit tests on the transpiled output.

### Structure (Planned)
```
test/mix_tests/
├── basic_functionality/
│   ├── test_class.exs      # ExUnit test
│   └── generated_source.ex # From Haxe compilation
└── complex_features/
    ├── test_suite.exs
    └── compiled_output.ex
```

### When to Use (Future)
- ✅ Testing runtime behavior of generated code
- ✅ Validating Elixir/OTP functionality
- ✅ Performance testing
- ✅ Integration with Elixir ecosystem

## Test Organization Principles

### Directory Structure
```
test/
├── TestRunner.hx           # Main test orchestrator
├── Test.hxml              # Test entry point
└── tests/                 # All snapshot and compile-time tests
    ├── basic_class/       # Snapshot test
    ├── RouterBuildMacro_ValidController/    # Compile-time test
    └── liveview_advanced/ # Combined snapshot + stderr validation

examples/                  # Integration tests
├── todo-app/             # Phoenix LiveView example
└── api-server/           # Phoenix API example
```

### Test Selection Strategy

**For New Features**:
1. **Start with snapshot tests** - Validate basic transpilation
2. **Add compile-time tests** - If feature includes validation/DSL
3. **Create integration test** - If feature affects framework integration
4. **Consider Mix tests** - For complex runtime behavior (future)

**For Bug Fixes**:
1. **Create regression test** - Reproduce the bug with a test
2. **Fix the issue** - Ensure test passes after fix
3. **Update documentation** - If behavior changes

**For Validation Logic**:
1. **Test valid cases** - Ensure no warnings for correct usage
2. **Test invalid cases** - Ensure appropriate warnings/errors
3. **Test edge cases** - Multiple failures, boundary conditions
4. **Test error messages** - Ensure helpful developer feedback

## Test Execution Flow

### Snapshot Test Flow
1. **Compile** - Run Haxe compiler on test source
2. **Generate** - Create Elixir output in `out/` directory
3. **Compare** - Check `out/` vs `intended/` directory
4. **Report** - Show differences or success

### Compile-Time Test Flow
1. **Compile** - Run Haxe compiler on test source
2. **Capture stderr** - Record warnings/errors from compilation
3. **Generate** - Create Elixir output (if compilation succeeds)
4. **Validate stderr** - Compare against `expected_stderr.txt`
5. **Compare output** - Standard snapshot comparison
6. **Report** - Show both stderr and output validation results

## Best Practices by Test Type

### Snapshot Tests
- ✅ Keep tests focused on single features
- ✅ Use descriptive test names
- ✅ Include edge cases and boundary conditions
- ✅ Verify generated code is idiomatic Elixir

### Compile-Time Tests
- ✅ Test both valid and invalid cases
- ✅ Use exact warning message format
- ✅ Include line numbers as they appear
- ✅ Group related validation scenarios

### Integration Tests
- ✅ Test complete workflows
- ✅ Use realistic data and scenarios
- ✅ Include Phoenix-specific functionality
- ✅ Test both development and production configurations

## Related Documentation

- **[TESTING_PRINCIPLES.md](TESTING_PRINCIPLES.md)** - Core testing philosophy and rules
- **[architecture/TESTING.md](architecture/TESTING.md)** - Technical testing infrastructure
- **[TEST_SUITE_DEEP_DIVE.md](TEST_SUITE_DEEP_DIVE.md)** - What each test validates
- **[EXAMPLES.md](EXAMPLES.md)** - Integration test examples and usage

## Future Enhancements

### Planned Test Types
1. **Performance Tests** - Compilation speed and memory usage
2. **Mix Test Integration** - Runtime validation of generated code
3. **Cross-Platform Tests** - Multi-OS compilation validation
4. **Stress Tests** - Large codebase compilation

### Test Infrastructure Improvements
1. **Parallel Test Execution** - Faster test suite runs
2. **Test Categorization** - Better organization and filtering
3. **Automated Test Generation** - From feature specifications
4. **CI/CD Integration** - Automated testing on multiple platforms
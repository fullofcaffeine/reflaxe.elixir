# Testing Infrastructure Documentation for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions and [/docs/03-compiler-development/testing-infrastructure.md](/docs/03-compiler-development/testing-infrastructure.md) for testing principles

## 🧪 Testing Infrastructure Overview

The Reflaxe.Elixir testing infrastructure uses a **Make-based test runner** that supports both sequential and parallel execution, providing reliable and fast testing for the compiler.

## 📁 Test Directory Structure

```
test/
├── Makefile                    # Main test runner using Make
├── Test.hxml                   # Legacy configuration (kept for reference)
├── run-parallel.sh            # Wrapper script for backward compatibility
├── TestProjectGeneratorTemplates.hxml  # Project generator tests
└── tests/                      # Individual test cases (76 total)
    ├── test_name/
    │   ├── compile.hxml       # Test compilation configuration
    │   ├── Main.hx           # Test source code
    │   ├── intended/         # Expected output files
    │   │   └── *.ex         # Expected Elixir files
    │   └── out/             # Generated output (gitignored)
    │       └── *.ex        # Generated Elixir files
```

## 🎯 Test Types

### 1. Snapshot Tests (Primary Testing Method)
- **Purpose**: Compare generated Elixir code against expected output
- **Location**: `test/tests/*/`
- **Validation**: Byte-for-byte comparison of generated vs intended files
- **Count**: 76 test directories

### 2. Mix Integration Tests
- **Purpose**: Validate generated Elixir code runs correctly
- **Location**: Project root (mix test)
- **Validation**: Runtime behavior verification
- **Command**: `MIX_ENV=test mix test`

### 3. Project Generator Tests
- **Purpose**: Test Mix project generation templates
- **Location**: `test/TestProjectGeneratorTemplates.hxml`
- **Validation**: Template generation correctness

### 4. Example Integration Tests
- **Purpose**: Full application compilation and execution
- **Location**: `examples/todo-app/`
- **Validation**: Real-world usage patterns

## 🔧 Test Runners

### Unified Make Test Runner
**Status**: ✅ Production ready - Supports both sequential and parallel execution

```bash
npm test                           # Run all tests (parallel by default)
npm run test:sequential            # Run tests sequentially (-j1)
make -C test                      # Run all tests (parallel, 4 workers)
make -C test -j8                  # Run with 8 parallel workers
make -C test test-arrays          # Run specific test
```

**Features**:
- Uses Make's proven parallel job control (40+ years of reliability)
- Configurable parallelism via `-j` flag (default: 4 workers)
- Proper process management with Unix `timeout` command
- No process accumulation or zombie issues
- Clean summary output with pass/fail counts
- Successfully completes all 76 tests

**Implementation**:
- Simple 106-line Makefile (vs 400+ lines of complex code)
- Shell wrapper script for npm integration
- No complex worker pools or file locking needed

### Available Test Commands

```bash
# Basic operations
make -C test                      # Run all tests (parallel)
make -C test -j1                  # Run tests sequentially
make -C test test-NAME            # Run specific test
make -C test single TEST=NAME     # Alternative single test syntax
```

# Update baselines
make -C test update-intended TEST=NAME  # Update specific test
make -C test update-intended            # Update all tests

# Utilities
make -C test list                 # List all available tests
make -C test clean                # Clean output directories
make -C test help                 # Show help text

## 🐛 Current Test Infrastructure Issues

### Status (As of August 2025)

**Infrastructure**: ✅ FIXED - Make-based runner completes all tests without hanging
**Test Failures**: ⚠️ Many tests have outdated intended outputs

### Resolved Issues

1. **Parallel Runner Hanging**: ✅ FIXED with Make-based solution
2. **Process Zombies**: ✅ FIXED with proper `timeout` command
3. **File Lock Deadlocks**: ✅ FIXED by removing file locking entirely
4. **Complex Process Management**: ✅ FIXED by using Make's built-in job control

### Remaining Issues

1. **Outdated Intended Outputs**: ~71/76 tests show "Output mismatch"
   - Compiler has evolved but test baselines haven't been updated
   - Need to run `update-intended` to accept new output
   
2. **Compilation Failures**: 5 tests fail to compile
   - elixir_injection_test
   - enhanced_pattern_matching  
   - loop_variable_mapping
   - optimization_pipeline
   - otp_supervision

3. **Test Evolution Lag**:
   - Compiler improvements not reflected in intended outputs
   - Standard library changes breaking existing tests
   - Need systematic baseline update process

## 📊 Test Status Categories

### ✅ Passing Tests (32/76)
- Basic syntax tests
- Simple compilation tests
- Recently updated tests (arrays, router, InjectionDebug)

### ❌ Failing Tests (44/76)
- **Compilation Failures**: Tests that don't compile due to stdlib issues
- **Output Mismatches**: Tests with outdated intended outputs
- **Missing Baselines**: Tests without intended directories

## 🔨 Common Test Operations

### Running Tests
```bash
# Full test suite
npm test                          # Parallel by default
make -C test -j1                  # Force sequential

# Specific test
make -C test test-test_name       # Direct Make invocation
npm run test:single TEST=test_name # NPM wrapper

# Test with different parallelism
make -C test -j8                  # 8 parallel workers
make -C test -j16                 # 16 parallel workers
```

### Updating Tests
```bash
# Update specific test intended output
make -C test update-intended TEST=test_name

# Update all intended outputs (use with caution!)
make -C test update-intended
npm run test:update  # NPM wrapper
```

### Debugging Tests
```bash
# Show available tests
make -C test list

# Check test directly
cd test/tests/test_name && npx haxe compile.hxml

# Compare outputs manually
diff -u test/tests/test_name/intended/ test/tests/test_name/out/
```

## 🚨 Emergency Procedures

### When Parallel Tests Hang
```bash
# 1. Kill hanging processes
pkill -f "haxe.*test"

# 2. Use sequential mode directly
make -C test -j1
```

### When Tests Report "Missing compile.hxml"
This is usually a misleading error. The real issue is likely:
1. Compilation failure in the test
2. Missing test directory
3. Current directory context issue

Debug with:
```bash
# Check if file actually exists
ls test/tests/test_name/compile.hxml

# Try direct compilation
cd test/tests/test_name && npx haxe compile.hxml
```

## 🎯 Test Writing Guidelines

### Creating a New Test
1. Create directory: `test/tests/my_new_test/`
2. Add `compile.hxml`:
```hxml
-cp ../../../src
-cp ../../../std
-lib reflaxe
-cp .
-D elixir_output=out
-D reflaxe_runtime
--macro reflaxe.elixir.CompilerInit.Start()
Main
```
3. Write `Main.hx` with test code
4. Run test: `make -C test test-my_new_test`
5. Review output in `out/`
6. If correct: `make -C test update-intended TEST=my_new_test`

### Test Naming Conventions
- Use snake_case for test directories
- Descriptive names indicating what's being tested
- Group related tests with common prefixes

### Test Complexity Levels
- **Basic**: Single file, simple compilation
- **Integration**: Multiple files, complex interactions
- **Framework**: Phoenix/Ecto integration tests
- **Edge Cases**: Specific bug reproductions

## 🔄 Continuous Integration Considerations

### Pre-Commit Checks
```bash
# Mandatory before any commit
npm test                    # Must pass
cd examples/todo-app && mix compile  # Must compile
```

### Test Performance Targets
- Sequential: ~5 minutes for full suite
- Parallel: ~2 minutes (when working)
- Single test: <10 seconds

## 📈 Test Infrastructure Improvement Plan

### Phase 1: Infrastructure (✅ COMPLETED)
- [x] Fix parallel runner timeout
- [x] Fix process zombie issues
- [x] Replace complex runners with Make-based solution
- [x] Clean up all old test infrastructure

### Phase 2: Test Baseline Update (Current Priority)
- [ ] Update all outdated intended outputs
- [ ] Fix remaining compilation errors
- [ ] Document which tests are integration vs unit
- [ ] Add automated baseline update CI job

### Phase 3: Future Enhancements
- [ ] Add test categorization and tagging
- [ ] Implement incremental testing (only run affected tests)
- [ ] Add performance benchmarking
- [ ] Create test coverage reports

## 🎓 Key Learnings

1. **Snapshot Testing**: Effective but requires maintenance as compiler evolves
2. **Parallel Execution**: Tricky with file system operations and compilation
3. **Error Messages**: Must accurately reflect actual problems
4. **Test Evolution**: Tests must evolve with the compiler
5. **Integration Testing**: Critical for validating real-world usage

## 📚 Related Documentation

- [/docs/03-compiler-development/testing-infrastructure.md](/docs/03-compiler-development/testing-infrastructure.md) - Testing principles
- [/docs/03-compiler-development/debugging-guide.md](/docs/03-compiler-development/debugging-guide.md) - Debugging techniques
- [/CLAUDE.md](/CLAUDE.md) - Main project context
- [/docs/01-getting-started/development-workflow.md](/docs/01-getting-started/development-workflow.md) - Development practices

## ⚠️ Critical Rules for Test Maintenance

1. **Never modify intended files manually** - Always regenerate from compiler output
2. **Test after every compiler change** - Catch regressions immediately
3. **Update baselines only when output improves** - Don't hide problems
4. **Fix root causes, not symptoms** - Resolve compilation errors at source
5. **Document test purposes** - Future maintainers need context
6. **NO BAND-AID SOLUTIONS IN COMMITS** - Never commit workaround or band-aid solutions. Temporary files for debugging are fine but must be cleaned up before committing. Always fix the root cause, not symptoms.

---

**Remember**: The test suite is the safety net for compiler development. A broken test suite blocks all progress.
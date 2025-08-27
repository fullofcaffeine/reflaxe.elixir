# Testing Infrastructure Documentation for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions and [/docs/03-compiler-development/testing-infrastructure.md](/docs/03-compiler-development/testing-infrastructure.md) for testing principles

## 🧪 Testing Infrastructure Overview

The Reflaxe.Elixir testing infrastructure consists of multiple test runners and test types, each serving specific purposes in validating the compiler's functionality.

## 📁 Test Directory Structure

```
test/
├── Test.hxml                    # Main test configuration
├── TestRunner.hx               # Sequential test runner (reliable, slower)
├── ParallelTest.hxml          # Parallel test configuration
├── ParallelTestRunner.hx      # Parallel test runner (faster, has issues)
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

### Sequential Test Runner (TestRunner.hx)
**Status**: ✅ Stable but slow

```bash
npm run test:haxe           # Run all tests sequentially
npx haxe test/Test.hxml     # Direct invocation
```

**Features**:
- Runs tests one at a time
- Reliable error reporting
- Timeout protection (10 seconds per test)
- Clear output formatting

**Options**:
- `test=name` - Run specific test
- `update-intended` - Update expected output
- `nocompile` - Skip Elixir compilation
- `show-output` - Display compilation output

### Parallel Test Runner (ParallelTestRunner.hx)
**Status**: ⚠️ Has deadlock issues

```bash
npm run test:parallel       # Run tests in parallel
npx haxe test/ParallelTest.hxml
```

**Features**:
- 16 concurrent workers by default
- Work-stealing queue for load balancing
- ~87% faster than sequential

**Known Issues**:
1. **File Lock Deadlock**: Workers can deadlock on `.parallel_lock` file
2. **Stale Lock Detection**: Added but not fully reliable
3. **Timeout Handling**: Doesn't always release locks properly
4. **Progress Stalling**: Gets stuck after ~22 tests

## 🐛 Current Test Infrastructure Issues

### Critical Problems (As of January 2025)

1. **Test Count**: Only 32/76 tests passing
2. **Parallel Runner Hanging**: Deadlocks after processing ~22 tests
3. **Compilation Errors**: Many tests fail due to stdlib changes
4. **Outdated Intended Outputs**: Compiler evolution made many baselines stale
5. **Misleading Error Messages**: "Missing compile.hxml" shown for compilation failures

### Root Causes Identified

1. **LiveView.hx Issues**:
   - Missing type parameters for Socket<T>
   - Duplicate method declarations
   - Breaking changes in Phoenix integration

2. **Lock Mechanism Flaws**:
   - File-based locking causes deadlocks
   - No automatic stale lock cleanup
   - Lock not released on process timeout

3. **Test Evolution Lag**:
   - Compiler improvements not reflected in intended outputs
   - Standard library changes breaking existing tests
   - No automated update mechanism

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
# Full test suite (slow but reliable)
npm run test:sequential

# Parallel tests (faster but may hang)
npm run test:parallel

# Specific test
npx haxe test/Test.hxml test=test_name

# Without Elixir compilation (fast iteration)
npx haxe test/Test.hxml test=test_name nocompile
```

### Updating Tests
```bash
# Update specific test intended output
npx haxe test/Test.hxml test=test_name update-intended

# Update all intended outputs (use with caution!)
npm run test:update
```

### Debugging Tests
```bash
# Show compilation output
npx haxe test/Test.hxml test=test_name show-output

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

# 2. Remove stale lock file
rm test/.parallel_lock

# 3. Use sequential runner instead
npm run test:sequential
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
4. Run test: `npx haxe test/Test.hxml test=my_new_test`
5. Review output in `out/`
6. If correct: `npx haxe test/Test.hxml test=my_new_test update-intended`

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

### Phase 1: Stabilization (Immediate)
- [x] Fix parallel runner timeout
- [x] Fix LiveView compilation errors
- [ ] Update all outdated intended outputs
- [ ] Fix remaining compilation errors

### Phase 2: Reliability (Next)
- [ ] Replace file-based locking with better mechanism
- [ ] Add automatic stale lock cleanup
- [ ] Improve error reporting accuracy
- [ ] Add test categorization

### Phase 3: Performance (Future)
- [ ] Optimize parallel execution
- [ ] Add incremental testing
- [ ] Implement test caching
- [ ] Add test prioritization

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

---

**Remember**: The test suite is the safety net for compiler development. A broken test suite blocks all progress.
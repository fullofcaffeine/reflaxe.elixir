# Comprehensive Testing Guide for Reflaxe.Elixir

> **Last Updated**: 2025-09-10
> **Status**: Complete implementation of improved test infrastructure

## 🚀 Quick Start

### Running Tests by Category (NEW!)

```bash
# Run specific test categories - much faster iteration!
npm run test:core          # Core language features
npm run test:stdlib        # Standard library tests
npm run test:regression    # Regression tests
npm run test:phoenix       # Phoenix framework tests
npm run test:ecto          # Ecto ORM tests
npm run test:otp          # OTP pattern tests

# Smart test selection
npm run test:changed       # Only tests affected by git changes
npm run test:failed        # Re-run only failed tests from last run

# Pattern matching
scripts/test-runner.sh --pattern "*array*"    # All array-related tests
scripts/test-runner.sh --pattern "*date*"     # All date-related tests
```

### Traditional Commands

```bash
# Full test suite
npm test                              # Complete validation
make -C test -j8                      # Run with 8 parallel jobs

# Specific tests
make -C test test-core__arrays       # Single test (__ for path separator)
make -C test single TEST=core/arrays # Alternative syntax

# Update expected outputs
make -C test update-intended TEST=core/arrays
```

## 📊 Test Infrastructure Overview

### Architecture
- **130+ snapshot tests** validating compiler output
- **Parallel execution by default** with Make jobserver (-j8 for 8 cores)
- **Category organization** for selective testing
- **Git-aware testing** to run only affected tests

### ⚡ Parallel Execution (DEFAULT)
Tests now run with **8-way parallelization by default** when using `npm test`:
- **Before**: Sequential execution took 60+ seconds
- **Now**: Parallel execution completes in ~17 seconds
- **Configurable**: Use `npm run test:sequential` for debugging
- **Automatic**: All test commands use `-j8` flag automatically

### Test Types

1. **Snapshot Tests** (`test/snapshot/`)
   - Compile Haxe → Elixir
   - Compare with expected output
   - Catch compilation errors and output differences

2. **Integration Tests** (`test/*.exs`)
   - Mix task validation
   - Runtime behavior testing
   - Framework integration checks

3. **Example Applications** (`examples/`)
   - Real-world usage validation
   - Phoenix app compilation tests
   - Full-stack integration

## 🎯 Developer Workflow

### During Development

```bash
# 1. Make compiler changes
vim src/reflaxe/elixir/SomeCompiler.hx

# 2. Test affected areas quickly
npm run test:changed         # Only affected tests
npm run test:core            # If working on core features

# 3. Fix failures iteratively
npm run test:failed          # Re-run failures only
scripts/test-runner.sh --failed --verbose  # With details

# 4. Update expected outputs if changes are correct
scripts/test-runner.sh --category core --update
```

### Before Committing

```bash
# 1. Run full test suite
npm test

# 2. Validate todo-app compilation
cd examples/todo-app
npx haxe build-server.hxml
mix compile --force
mix phx.server

# 3. Check for any runtime issues
curl http://localhost:4000
```

## 🛠️ Advanced Test Runner

### Features

The new `scripts/test-runner.sh` provides:
- **Category filtering**: `--category core|stdlib|regression|phoenix|ecto|otp`
- **Pattern matching**: `--pattern "*array*"`
- **Change detection**: `--changed` (uses git diff)
- **Failed test re-runs**: `--failed`
- **Auto-update mode**: `--update`
- **Parallelization control**: `--parallel N`
- **Verbose output**: `--verbose`
- **Haxe server support**: `--server` (experimental)

### Examples

```bash
# Run core tests with 8 parallel jobs
scripts/test-runner.sh --category core --parallel 8

# Update failing tests in stdlib
scripts/test-runner.sh --category stdlib --update

# Run tests affected by current changes with details
scripts/test-runner.sh --changed --verbose

# Re-run failed tests with auto-update
scripts/test-runner.sh --failed --update
```

## 📁 Test Organization

```
test/
├── Makefile                 # Test orchestration
├── snapshot/                # Compiler output tests
│   ├── core/               # Core language features
│   ├── stdlib/             # Standard library
│   ├── regression/         # Bug fix validation
│   ├── phoenix/            # Phoenix framework
│   ├── ecto/               # Database ORM
│   └── otp/                # OTP patterns
├── *.exs                   # Elixir integration tests
└── .test-cache/            # Test results cache
```

### Test Structure

Each test directory contains:
- `Main.hx` - Haxe source code
- `compile.hxml` - Compilation configuration
- `intended/` - Expected Elixir output
- `out/` - Generated output (gitignored)

## 🔍 Debugging Test Failures

### Understanding Failures

1. **Compilation Failed**
   - Compiler crash or unhandled AST pattern
   - Check recent compiler changes
   - Enable debug flags: `-D debug_ast_pipeline`

2. **Output Mismatch**
   - Generated code differs from expected
   - May be improvement or regression
   - Review diff carefully

3. **Timeout**
   - Usually indicates infinite loop
   - Check for recursive patterns
   - Increase timeout if needed

### Debug Commands

```bash
# View test differences
diff -r test/snapshot/core/arrays/intended test/snapshot/core/arrays/out

# Run single test with debug output
cd test/snapshot/core/arrays
haxe -D debug_ast_pipeline -D debug_pattern_matching compile.hxml

# Check generated Elixir syntax
cd test/snapshot/core/arrays/out
elixir -c main.ex
```

## ⚡ Performance Tips

### Parallel Execution
```bash
# Optimal for most machines
make -C test -j8              # 8 parallel jobs

# Let Make decide
make -C test -j               # Unlimited parallelism

# Sequential for debugging
make -C test -j1              # One at a time
```

### Selective Testing
```bash
# Skip unrelated tests
npm run test:core             # Just core tests
npm run test:changed          # Just affected tests

# Use patterns for specific areas
scripts/test-runner.sh --pattern "*loop*"    # Loop tests only
```

### Caching
- Test results cached in `.test-cache/`
- Re-run failures without full scan
- Clean cache: `rm -rf test/.test-cache`

## 📝 Adding New Tests

### Creating a Test

1. **Choose category**: `core`, `stdlib`, `regression`, etc.
2. **Create directory**: `test/snapshot/category/test_name/`
3. **Add source**: `Main.hx` with test code
4. **Add config**: `compile.hxml`
   ```hxml
   -cp .
   -cp ../../../../src
   -cp ../../../../std
   -lib reflaxe
   -D reflaxe_runtime
   -D elixir_output=out
   --macro reflaxe.elixir.CompilerInit.Start()
   Main
   ```
5. **Generate baseline**: 
   ```bash
   make -C test test-category__test_name
   cp -r test/snapshot/category/test_name/out test/snapshot/category/test_name/intended
   ```
6. **Verify output**: Check generated Elixir is correct

### Test Naming Conventions
- Use descriptive names: `array_map_idiomatic` not `test1`
- Group related tests: `pattern_matching_*`
- Regression tests: `issue_123_description`

## 🚨 Common Issues

### Issue: Tests Pass Locally but Fail in CI
- Check for absolute paths in tests
- Verify all files committed (including `intended/`)
- Check for platform-specific code

### Issue: Make Not Found
- On macOS: Use `/usr/bin/make` explicitly
- Install with: `brew install make`

### Issue: Tests Timeout
- Default timeout is 120s (generous)
- Check for infinite loops in compiler
- Enable debug output to find hang location

### Issue: Output Mismatch After Compiler Fix
- This is expected! Review the changes
- If improvements: `make update-intended TEST=name`
- If regressions: Fix the compiler

## 📈 Future Improvements

### Phase 1 (Completed ✅)
- [x] Enhanced Makefile with category targets
- [x] Bash test runner with advanced features
- [x] NPM script integration
- [x] Documentation updates

### Phase 2 (Planned)
- [ ] Test metadata system (`test.meta.json`)
- [ ] Haxe compilation server integration
- [ ] Incremental testing with hash cache
- [ ] Better diff visualization

### Phase 3 (Future)
- [ ] Node.js test runner for advanced features
- [ ] GitHub Actions integration
- [ ] Performance benchmarking
- [ ] Coverage reporting

## 🔗 Related Documentation

- [Testing Infrastructure](./testing-infrastructure.md) - Architectural details
- [Test Types](./TEST_TYPES.md) - Deep dive into test categories
- [CI Configuration](../10-contributing/CI.md) - Continuous integration setup
- [CLAUDE.md](/CLAUDE.md) - Main project documentation

## 💡 Tips and Tricks

1. **Use `test:changed` during development** - Fastest feedback loop
2. **Run category tests before full suite** - Catch issues early
3. **Update baselines promptly** - Don't let mismatches accumulate
4. **Write focused tests** - One concept per test
5. **Use descriptive test names** - Makes debugging easier

---

**Remember**: Tests are documentation. Good tests explain what the compiler should do, validate it does it correctly, and prevent regressions.
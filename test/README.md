# Reflaxe.Elixir Test Suite

## Overview

The test suite validates the Reflaxe.Elixir compiler's ability to correctly transpile Haxe code to idiomatic Elixir.

## Test Structure

```
test/
├── snapshot/              # Compiler output validation tests (84 tests)
│   ├── core/             # Core language features (45 tests)
│   ├── phoenix/          # Phoenix framework integration (5 tests)
│   ├── ecto/             # Ecto ORM integration (8 tests)
│   ├── stdlib/           # Standard library (2 tests)
│   ├── otp/              # OTP patterns (3 tests)
│   └── regression/       # Bug fix validations (10 tests)
│
├── _archive/             # Archived/obsolete tests
│   ├── old_hxml/        # Old experimental .hxml files
│   └── broken_integration/ # Integration tests needing fixes
│
├── Makefile              # Test runner (parallel execution)
├── Test.hxml             # Main test compilation config
└── *.exs                 # Elixir integration tests (mostly broken)
```

## Test Types

### 1. Snapshot Tests (Primary)

**Location**: `snapshot/`  
**Purpose**: Validate compiler output matches expected Elixir code  
**Mechanism**: 
- Each test has `compile.hxml` configuration
- Compiles Haxe source to `out/` directory
- Compares against `intended/` expected output
- Fails if output doesn't match

**Categories**:
- **core/**: Arrays, classes, enums, loops, pattern matching, etc.
- **phoenix/**: LiveView, routers, templates, HXX compilation
- **ecto/**: Schemas, changesets, migrations, queries
- **otp/**: GenServer, supervisors, behaviors
- **stdlib/**: Reflection, standard library functions
- **regression/**: Specific bug fixes (nested switches, variable naming, etc.)

### 2. Integration Tests (Secondary)

**Location**: Root `test/` directory (`.exs` files)  
**Status**: ⚠️ Many are broken due to missing fixtures  
**Purpose**: Test Mix tasks, compilation pipeline, error handling  

**Note**: The main integration test is actually `examples/todo-app/` which is a complete Phoenix application.

## Running Tests

### Run All Tests (Parallel)
```bash
make              # Default: 4 parallel jobs
make -j8          # 8 parallel jobs
make -j1          # Sequential execution
```

### Run Specific Test
```bash
make test-core/arrays                    # Run arrays test
make test-regression/nested_switch       # Run nested switch test
```

### Update Expected Output
```bash
make update-intended TEST=core/arrays    # Update expected output for a test
```

### Test Specific Categories
```bash
# Run all core tests
for test in snapshot/core/*/; do make test-$(basename $test); done

# Run all regression tests
for test in snapshot/regression/*/; do make test-$(basename $test); done
```

## The Real Integration Test

**`examples/todo-app/` is our primary integration test**:
- Complete Phoenix application with LiveView
- Uses Ecto, migrations, schemas
- Tests full compilation pipeline
- Actually runs and serves pages

To validate integration:
```bash
cd examples/todo-app
npx haxe build-server.hxml
mix compile --force
mix phx.server
# Visit http://localhost:4000
```

## Adding New Tests

### For Bug Fixes (Regression Tests)

1. Create directory: `snapshot/regression/your_bug_name/`
2. Add `compile.hxml`:
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
3. Add `Main.hx` with minimal reproduction
4. Run test: `make test-regression/your_bug_name`
5. Verify output in `out/`
6. If correct, copy to `intended/`: `cp -r out intended`

### For New Features

1. Choose appropriate category (`core/`, `phoenix/`, etc.)
2. Create test directory with descriptive name
3. Follow same structure as regression tests
4. Document the feature being tested in `Main.hx`

## Test Maintenance

### Updating Tests After Compiler Changes

When compiler output changes (improvements, not bugs):
1. Run tests to see failures
2. Review changes in `out/` vs `intended/`
3. If changes are correct: `make update-intended TEST=category/test_name`
4. Commit both compiler changes and updated test expectations

### Cleaning Up

- Old/experimental tests go to `_archive/`
- Broken tests that need fixing go to `_archive/broken_integration/`
- Tests for removed features should be deleted

## Known Issues

### Integration Test Failures
The `.exs` integration tests in the root test directory have 16+ failures due to:
- Missing fixtures (`test/fixtures/test_phoenix_project/`)
- Changed infrastructure assumptions
- Outdated test expectations

These are kept for historical reference but are not part of the active test suite.

## Test Philosophy

1. **Snapshot tests are primary** - They validate compiler correctness
2. **Todo-app is the integration test** - Real-world validation
3. **Regression tests prevent backsliding** - Every bug fix gets a test
4. **Organization aids understanding** - Tests grouped by feature area
5. **Keep tests minimal** - Smallest reproduction of the issue

## Continuous Integration

Tests are run on every commit via GitHub Actions. The CI runs:
1. All snapshot tests via `make`
2. Todo-app compilation test
3. Basic smoke tests

Failed tests block merging to prevent regressions.
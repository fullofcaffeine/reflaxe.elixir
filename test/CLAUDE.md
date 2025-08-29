# Test Suite Context for AI Assistants

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions and [/docs/03-compiler-development/CLAUDE.md](/docs/03-compiler-development/CLAUDE.md) for compiler development context

## 🧪 Test Suite Overview

This directory contains the Reflaxe.Elixir compiler test suite, validating that Haxe code correctly transpiles to idiomatic Elixir.

### Testing Philosophy for AST and Internal Components

**IMPORTANT PRINCIPLE**: We follow the Reflaxe framework standard - test the OUTPUT, not internal implementation details.

- **NO unit tests for AST structures** - The AST is an internal implementation detail
- **NO direct testing of compiler classes** - They only exist at macro-time
- **ONLY snapshot testing** - Compile Haxe → validate generated Elixir output
- **This matches Reflaxe.CSharp approach** - They also don't unit test their AST
- **Focus on end-to-end validation** - What matters is correct Elixir generation

**Why this approach:**
1. AST structures can change without affecting output correctness
2. Internal refactoring shouldn't break tests if output remains correct
3. Users care about generated Elixir, not how we build it internally
4. Snapshot tests catch real bugs that affect actual usage

### Test Statistics (as of 2025-08-28)
- **84 snapshot tests** validating compiler output
- **8 integration tests** for Mix tasks and tooling
- **~2,500 test files** (source + expected outputs)
- **6 test categories** organizing tests by feature area

## 📁 Directory Structure

```
test/
├── snapshot/              # Primary compiler validation tests
│   ├── core/             # Core language features (45 tests)
│   │   ├── arrays/       # Array operations
│   │   ├── classes/      # Class compilation
│   │   ├── enums/        # Enum handling
│   │   ├── loops/        # For/while loops
│   │   └── ...
│   ├── phoenix/          # Phoenix framework (5 tests)
│   │   ├── liveview/     # LiveView components
│   │   ├── router/       # Router DSL
│   │   └── hxx_template/ # HXX→HEEx templates
│   ├── ecto/             # Database ORM (8 tests)
│   │   ├── schemas/      # Schema definitions
│   │   ├── changesets/   # Validation
│   │   └── migrations/   # Database migrations
│   ├── otp/              # OTP patterns (3 tests)
│   ├── stdlib/           # Standard library (2 tests)
│   └── regression/       # Bug fix validations (10 tests)
│
├── *.exs                 # Elixir integration tests
├── Makefile              # Test runner (parallel execution)
├── Test.hxml             # Main Haxe compilation config
├── test_helper.exs       # Elixir test support
└── README.md             # User documentation
```

## 🎯 Test Types Explained

### Snapshot Tests (`snapshot/`)

**Purpose**: Dual-level validation of the compiler
1. **Compilation Testing**: Ensures Haxe code successfully compiles through our transpiler
2. **Output Validation**: Verifies generated Elixir matches expected output

**Structure**:
- `Main.hx` - Haxe source code to compile
- `compile.hxml` - Compilation configuration
- `intended/` - Expected Elixir output (committed)
- `out/` - Generated output (NOT committed, in .gitignore)

**Testing Workflow**:
1. **Compilation Phase**: Haxe→Elixir transpilation (catches compiler crashes, type errors)
2. **Comparison Phase**: Generated `out/` vs expected `intended/` (catches incorrect code generation)
3. **Result**: Pass only if BOTH compilation succeeds AND output matches

**What Each Phase Tests**:
- **Compilation Phase Catches**:
  - Compiler crashes or hangs
  - Unhandled AST patterns
  - Type system integration issues
  - Missing or broken compiler features
  
- **Comparison Phase Catches**:
  - Incorrect variable naming
  - Wrong code structure generation
  - Missing or extra code blocks
  - Incorrect Elixir idioms

### Integration Tests (`.exs` files)

**Purpose**: Test Mix tasks, compilation pipeline, error handling

**Working tests**:
- `haxe_compiler_test.exs` - Compiler integration
- `haxe_watcher_test.exs` - File watching
- `source_map_test.exs` - Source mapping
- Others have some failures due to infrastructure changes

## 🔧 Running Tests

### Quick Commands

```bash
# Run all tests (parallel)
make

# Run specific test category
make test-core/arrays
make test-regression/nested_switch

# Run sequentially
make -j1

# Update expected output after fixing compiler
make update-intended TEST=core/arrays
```

### The Real Integration Test

**IMPORTANT**: The `examples/todo-app/` is our primary integration test:
```bash
cd examples/todo-app
npx haxe build-server.hxml
mix compile --force
mix phx.server
# Visit http://localhost:4000
```

This validates the entire compilation pipeline with a real Phoenix application.

## ⚠️ Critical Rules for Test Management

### CRITICAL: Validate Intended Output Correctness
- **BEFORE accepting test failures**: Examine if the intended output itself is correct
- **If intended output is wrong**: Update it to the correct expected behavior
- **Verify consistency**: If a variable is declared as `i`, it should be referenced as `i`, not `_i`
- **Update immediately**: When fixing compiler bugs, update incorrect intended outputs FIRST
- **This ensures tests actually validate correct behavior**, not perpetuate bugs

### NEVER Commit Generated Files
- ❌ Never commit `out/` directories
- ❌ Never commit `dump/` directories  
- ❌ Never commit compilation artifacts
- ✅ Only commit source and `intended/` outputs

### Test Organization Rules
- **One test = one directory** with clear purpose
- **Categorize by feature** not by implementation
- **Name descriptively** - test name should explain what it validates
- **Keep tests minimal** - smallest code to reproduce the issue

### Adding New Tests

#### For Bug Fixes (Regression Tests)
```bash
mkdir snapshot/regression/your_bug_name
cd snapshot/regression/your_bug_name

# Create compile.hxml
cat > compile.hxml << EOF
-cp .
-cp ../../../../src
-cp ../../../../std
-lib reflaxe
-D reflaxe_runtime
-D elixir_output=out
--macro reflaxe.elixir.CompilerInit.Start()
Main
EOF

# Create Main.hx with minimal reproduction
# Run test
make test-regression/your_bug_name
# If output is correct, save as intended
cp -r out intended
```

#### For New Features
Choose appropriate category (`core/`, `phoenix/`, etc.) and follow same structure.

## 🐛 Known Issues

### Integration Test Failures
Some `.exs` tests fail with 16+ failures because they expect fixtures in `test/fixtures/test_phoenix_project/` that no longer exist. These are kept for reference but not actively maintained.

### Makefile Path Handling
The Makefile needs updating to properly handle the nested `snapshot/` structure for the pattern rules.

## 📈 Test Maintenance

### After Compiler Changes
1. Run `npm test` to see failures
2. Review changes carefully - are they improvements?
3. If yes: `make update-intended TEST=affected_test`
4. Commit both compiler changes and test updates together

### Regular Cleanup
- Remove `out/` directories if accidentally created: `find . -name out -type d -exec rm -rf {} +`
- Check for loose files: `find . -maxdepth 1 -type f -name "*.hx"`
- Verify no generated code committed: `git status --ignored`

## 🎯 Testing Philosophy

1. **Snapshot tests validate correctness** - Core compiler validation
2. **Todo-app validates integration** - Real-world application test
3. **Every bug gets a regression test** - Prevent regressions
4. **Tests document behavior** - Test names and code explain features
5. **Keep tests fast and focused** - Parallel execution, minimal code

## 🔍 Debugging Test Failures

### Understanding Test Failure Types

**Compilation Failed**: The Haxe code couldn't be transpiled to Elixir
- Usually indicates a compiler bug or unhandled AST pattern
- Check for recent compiler changes that might have broken this
- Run with debug flags to see where compilation stops

**Output Mismatch**: Compilation succeeded but generated code differs from expected
- May be an improvement (review the diff carefully)
- Could be a regression (incorrect code generation)
- Sometimes just needs `make update-intended` if the change is correct

**Timeout**: Test took too long (>60s default)
- Often indicates infinite loop in compiler
- May be caused by complex nested structures
- Check for recursive patterns in the test code

### When Tests Fail

1. **Check the diff**:
   ```bash
   diff -r snapshot/core/failing_test/intended snapshot/core/failing_test/out
   ```

2. **Review generated code**:
   ```bash
   cat snapshot/core/failing_test/out/main.ex
   ```

3. **Enable debug mode**:
   ```bash
   npx haxe test/snapshot/core/failing_test/compile.hxml \
     -D debug_expression_variants \
     -D debug_pattern_matching
   ```

4. **Check recent changes**:
   ```bash
   git log --oneline src/reflaxe/elixir
   ```

## 📊 Test Coverage Status

### Well-Tested Areas ✅
- Core language features (loops, classes, enums)
- Pattern matching
- Phoenix LiveView basics
- Ecto schemas and changesets

### Needs More Tests ⚠️
- Complex OTP patterns
- Advanced Phoenix features
- Error handling edge cases
- Performance-critical paths

## 🚀 Future Improvements

1. **Fix Makefile for nested structure** - Update pattern rules
2. **Add performance benchmarks** - Track compilation speed
3. **Improve test names** - More descriptive directories
4. **Add test categories** - Group by complexity/priority
5. **Automate todo-app testing** - CI integration

---

**Remember**: Tests are documentation. A good test explains what the compiler should do, validates it does it correctly, and prevents regressions.
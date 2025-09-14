# Test Suite Context for AI Assistants

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions and [/docs/03-compiler-development/CLAUDE.md](/docs/03-compiler-development/CLAUDE.md) for compiler development context

## ⚠️ CRITICAL DIRECTIVE FOR AI AGENTS

**MANDATORY: When creating ANY test, you MUST:**
1. **ALWAYS use `test/snapshot/` directory** - NEVER create `test/tests/`
2. **ALWAYS categorize properly** - Use existing categories (core, phoenix, ecto, etc.)
3. **ALWAYS check for existing similar tests** before creating duplicates
4. **ALWAYS update test counts** in this file when adding/moving tests
5. **ALWAYS follow the exact directory structure** documented below

**Last Updated**: January 2025 - Moved ~50 tests from incorrect `test/tests/` to proper locations

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
│   ├── core/             # Core language features (~60 tests)
│   │   ├── arrays/       # Array operations
│   │   ├── classes/      # Class compilation
│   │   ├── enums/        # Enum handling
│   │   ├── loops/        # For/while loops
│   │   └── ...
│   ├── phoenix/          # Phoenix framework (~15 tests)
│   │   ├── liveview/     # LiveView components
│   │   ├── router/       # Router DSL
│   │   ├── presence/     # Phoenix Presence
│   │   └── hxx_template/ # HXX→HEEx templates
│   ├── ecto/             # Database ORM (~10 tests)
│   │   ├── schemas/      # Schema definitions
│   │   ├── changesets/   # Validation
│   │   └── migrations/   # Database migrations
│   ├── otp/              # OTP patterns (4 tests)
│   ├── stdlib/           # Standard library (~15 tests)
│   ├── exunit/           # Test framework (~6 tests)
│   ├── loops/            # Loop-specific tests (3 tests)
│   └── regression/       # Bug fix validations (~30 tests)
│
├── *.exs                 # Elixir integration tests
├── Makefile              # Test runner (parallel execution)
├── Test.hxml             # Main Haxe compilation config
├── test_helper.exs       # Elixir test support
└── README.md             # User documentation
```

**⚠️ CRITICAL: Test Location Rules**
- **ALL snapshot tests MUST go in `test/snapshot/`** - Not in `test/tests/`
- **Use proper categories** - core, phoenix, ecto, otp, stdlib, exunit, loops, regression
- **Never create `test/tests/` directory** - This is the wrong location
- **Follow the naming convention** - Use descriptive names like `variable_shadowing_patterns`

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

**IMPORTANT**: Both directories are required:
- `intended/` contains the golden/expected output that we want the compiler to produce
- `out/` is generated fresh each test run and compared against `intended/`
- When migrating tests from old format, the old `out/` becomes the new `intended/`

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

### JavaScript/Full-Stack Tests 

**Purpose**: Support full-stack Haxe development for Phoenix applications

Some tests in the suite compile to JavaScript instead of Elixir. These are part of the full-stack framework provided by the compiler, enabling developers to write entire Phoenix applications (including client-side JavaScript) in Haxe.

**Examples**:
- `AsyncAnonymousFunctions` - Tests async/await patterns for client-side code
- Tests with `--js` target in `compile.hxml` - Generate JavaScript output

**Why These Exist**:
- **Full-Stack Type Safety**: Write both backend (Elixir) and frontend (JavaScript) in Haxe
- **Phoenix Integration**: Type-safe LiveView hooks, JavaScript interop
- **Bonus UX Features**: Not core compiler functionality, but valuable for Phoenix apps written 100% in Haxe
- **Shared Code**: Enables code sharing between client and server with type safety

**Important Note**: These tests may use different standard library components (like `reflaxe.js.Async`) and compile to `out/main.js` instead of Elixir files.

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
# Run all tests (parallel by default with -j8)
make                           # Uses 8-way parallelization automatically
npm test                       # Also uses -j8 by default

# Run specific test category
make test-core/arrays
make test-regression/nested_switch

# Run sequentially (for debugging)
make -j1                       # Force sequential execution
npm run test:sequential        # Alternative sequential command

# Update expected output after fixing compiler
make update-intended TEST=core/arrays
```

### ⚡ Parallel Execution is DEFAULT
**IMPORTANT**: As of January 2025, all test commands run with **8-way parallelization by default**:
- `npm test` uses `make -C test -j8` 
- `npm run test:quick` uses `make -C test -j8`
- This reduces test time from 60+ seconds to ~17 seconds
- Use `npm run test:sequential` only when debugging test ordering issues

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

#### ⚠️ CORRECT Test Creation Process

**STEP 1: Choose the Right Location**
```
test/snapshot/
├── core/          # Language features (arrays, classes, loops, etc.)
├── phoenix/       # Phoenix-specific (LiveView, Router, Presence)
├── ecto/          # Database features (schemas, migrations)
├── otp/           # OTP patterns (GenServer, Supervisor)
├── stdlib/        # Standard library (Reflect, Lambda, StringBuf)
├── exunit/        # Test framework features
├── loops/         # Loop-specific edge cases
└── regression/    # Bug fixes (always create test when fixing bugs)
```

**STEP 2: Create Test Directory**
```bash
# For a bug fix
mkdir test/snapshot/regression/variable_shadowing_patterns

# For a new feature
mkdir test/snapshot/core/new_feature_name

# NEVER create test/tests/ directory!
```

**STEP 3: Create compile.hxml**
```hxml
-cp .
-main Main
-lib reflaxe
-lib reflaxe.elixir
--no-output
```

**STEP 4: Create Main.hx**
```haxe
package;

class Main {
    public static function main() {
        // Minimal code to reproduce the issue
        // Keep it focused on ONE specific problem
    }
}
```

**STEP 5: Generate Output and Validate**
```bash
# From project root
cd /Users/fullofcaffeine/workspace/code/haxe.elixir

# Compile the test (generates out/ directory)
haxe test/snapshot/regression/your_test_name/compile.hxml

# Check the generated Elixir
cat test/snapshot/regression/your_test_name/out/Main.ex

# If output is CORRECT, save as intended
cd test/snapshot/regression/your_test_name
cp -r out intended

# If output is WRONG, fix the compiler first!
```

**STEP 6: Verify Test Passes**
```bash
# Run specific test
./scripts/test-runner.sh --pattern "your_test_name"

# Or use make
make -C test test-regression/your_test_name
```

#### Common Mistakes to Avoid

❌ **WRONG: Creating tests in wrong location**
```bash
mkdir test/tests/MyTest  # WRONG!
```

✅ **CORRECT: Using snapshot directory**
```bash
mkdir test/snapshot/regression/MyTest  # RIGHT!
```

❌ **WRONG: Not categorizing tests**
```bash
mkdir test/snapshot/random_test  # WRONG!
```

✅ **CORRECT: Using proper categories**
```bash
mkdir test/snapshot/core/array_operations  # RIGHT!
mkdir test/snapshot/regression/enum_pattern_fix  # RIGHT!
```

❌ **WRONG: Committing out/ directory**
```bash
git add test/snapshot/regression/MyTest/out  # WRONG!
```

✅ **CORRECT: Only committing intended/**
```bash
git add test/snapshot/regression/MyTest/intended  # RIGHT!
```

#### For Bug Fixes (Regression Tests)
Always create a regression test when fixing a bug:

```bash
# 1. Create test that reproduces the bug
mkdir test/snapshot/regression/issue_description
cd test/snapshot/regression/issue_description

# 2. Create minimal Main.hx that shows the problem
echo 'class Main {
    public static function main() {
        // Code that triggers the bug
    }
}' > Main.hx

# 3. Create compile.hxml
echo '-cp .
-main Main
-lib reflaxe
-lib reflaxe.elixir
--no-output' > compile.hxml

# 4. Fix the compiler

# 5. Generate correct output
cd /Users/fullofcaffeine/workspace/code/haxe.elixir
haxe test/snapshot/regression/issue_description/compile.hxml

# 6. Save as intended if correct
cd test/snapshot/regression/issue_description
cp -r out intended

# 7. Verify test passes
cd /Users/fullofcaffeine/workspace/code/haxe.elixir
./scripts/test-runner.sh --pattern "issue_description"
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

## 🚀 Test Infrastructure Improvements (January 2025)

### Overview of Recent Enhancements
The test infrastructure has been significantly improved with parallel execution by default and advanced test runner capabilities.

### Key Improvements Implemented

#### 1. **Parallel Execution by Default** ✅
- All test commands now use `-j8` (8-way parallelization)
- Performance improvement: 60+ seconds → ~17 seconds (3.5x faster)
- Sequential mode still available via `npm run test:sequential` for debugging

#### 2. **Advanced Test Runner** (`scripts/test-runner.sh`) ✅
Features implemented:
- **Category filtering**: `--category core|stdlib|regression|phoenix|ecto|otp`
- **Pattern matching**: `--pattern "*array*"` for wildcard selection
- **Git-aware testing**: `--changed` runs only tests affected by changes
- **Failed test re-runs**: `--failed` re-runs only previously failed tests
- **Auto-update mode**: `--update` updates intended outputs for failures
- **Colored output**: Visual feedback with ✅/❌ indicators
- **Test statistics**: Summary of passed/failed counts

#### 3. **Enhanced Makefile** ✅
- Dynamic category targets generated from directory structure
- Pattern matching support for selective testing
- Failed test tracking and re-running
- Proper result aggregation (though could be improved for atomicity)

#### 4. **NPM Script Integration** ✅
```json
"test": "make -C test -j8",              // Parallel by default
"test:sequential": "make -C test -j1",   // For debugging
"test:core": "scripts/test-runner.sh --category core",
"test:changed": "scripts/test-runner.sh --changed",
"test:failed": "scripts/test-runner.sh --failed"
```

### Known Limitations & Phase 2 Improvements

#### Codex Review Findings
Based on architectural review, these refinements are recommended:

**Minor Issues to Address**:
1. **Haxe Server Integration**: Currently incomplete - needs `--connect` wiring
2. **Result Atomicity**: Per-test result files instead of shared `test-results.tmp`
3. **Base Branch Detection**: Auto-detect default branch for `--changed`
4. **Hard-coded Parallelism**: Some Makefile targets have `-j8` that should inherit jobserver

**Future Enhancements**:
1. **Test Metadata**: Support for `test.meta.json` configurations
2. **Cache System**: Fingerprint-based skipping of unchanged tests
3. **Better Diffs**: Colored diffs with `git diff --no-index`
4. **Dry-run Mode**: Preview what tests would run without execution
5. **Quarantine List**: Mark flaky tests for isolation

#### Portability Considerations
- Requires GNU Make (macOS users need `/usr/bin/make`)
- `timeout` command varies by platform (macOS needs `gtimeout`)
- Bash 4+ recommended for associative arrays in test runner

### Architectural Notes

**Strengths** (per Codex review):
- Clean separation between Make orchestration and bash ergonomics
- Good use of Make's jobserver for parallel execution
- Git-aware testing reduces unnecessary test runs
- Documentation matches implementation well
- Category organization provides good selective testing

**Implementation Quality**:
- The Make-based approach is solid and maintainable
- Test runner adds meaningful ergonomics without hiding Make
- Parallel execution yields measurable performance wins
- Documentation is comprehensive and actionable

### Resolved Issues with Parallel Test Execution (January 2025)

#### ✅ FIXED: Haxe Server Port Conflicts

**Problem (Historical)**: When tests ran in parallel with `-j8`, multiple Haxe compilation servers attempted to start simultaneously, leading to port conflicts:
- Error: `listen EADDRINUSE: address already in use :::8000`
- Multiple HaxeServer instances crashed with `FunctionClauseError`
- Tests failed intermittently due to port conflicts

**Root Cause Identified**: 
- The HaxeServer defaulted to port 8000 for all instances
- Missing Port message handlers caused FunctionClauseError crashes
- Port.open environment variables required Erlang charlists, not Elixir strings

**Solution Implemented**:

1. **Dynamic Port Allocation**: 
   ```elixir
   # Each test instance gets a unique port
   defp find_available_port() do
     base_port = 7000 + rem(System.unique_integer([:positive]), 2000)
     # Try ports in sequence until one is available
   end
   ```

2. **Port Message Handlers Added**:
   ```elixir
   # Handle Port messages to prevent crashes
   def handle_info({port, {:data, data}}, state) when is_port(port) do
     Logger.debug("Haxe server output: #{data}")
     {:noreply, state}
   end
   
   def handle_info({port, {:exit_status, status}}, state) when is_port(port) do
     Logger.warning("Haxe server exited with status: #{status}")
     send(self(), :start_server)
     {:noreply, %{state | server_pid: nil, status: :restarting}}
   end
   ```

3. **Environment Variable Configuration**:
   ```elixir
   # Use charlists for Port.open env variables (critical!)
   env = [
     {'HAXESHIM_SERVER_PORT', to_charlist(haxeshim_port)},
     {'HAXE_SERVER_PORT', to_charlist(state.port)}
   ]
   ```

4. **Improved Test Port Strategy**:
   - Test environment uses random ports (7000-9000 range)
   - Production defaults to standard port 6000
   - Haxeshim gets separate port to avoid internal conflicts

**Key Lesson**: Port.open requires Erlang charlists (`'string'`) for environment variables, not Elixir strings (`"string"`). This subtle distinction caused the "invalid option in list" errors.

**Impact**: 
- ✅ All 80 Elixir tests now pass reliably in parallel
- ✅ No more FunctionClauseError crashes
- ✅ Parallel test execution works as designed (`-j8`)
- ✅ Test performance improved: 60s → ~17s with parallelization

---

**Remember**: Tests are documentation. A good test explains what the compiler should do, validates it does it correctly, and prevents regressions.
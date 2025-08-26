# Testing Context for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions, architecture, and core development principles

This file contains testing-specific guidance for agents working on Reflaxe.Elixir's test infrastructure.

## 🧪 Testing Architecture Overview

### Test Types (4 Different Systems)
1. **Snapshot Tests** (TestRunner.hx) - Compare generated Elixir against expected output
2. **Mix Tests** (.exs files) - Validate generated code runs correctly in BEAM VM
3. **Generator Tests** - Validate project template generation  
4. **Integration Tests** - End-to-end compilation and execution

### Critical Commands

#### Complete Test Suite
```bash
npm test                                    # Run ALL tests (Haxe + Generator + Mix) - mandatory before commits
npm run test:sequential                     # Same as npm test but sequential (for debugging)
npm run test:parallel-experimental          # Experimental: parallel Haxe + parallel Mix tests
```

#### Individual Test Categories  
```bash
npm run test:quick                          # Haxe snapshot tests only (fastest, ~30s)
npm run test:haxe                          # Same as test:quick - Haxe compilation tests
npm run test:generator                     # Project template generation tests
npm run test:mix                           # Elixir runtime tests (BEAM VM validation)
npm run test:parallel                      # Parallel Haxe tests (default 16 workers)
npm run test:mix-parallel                  # Mix tests with 4 concurrent cases
npm run test:examples                      # Test all example projects
npm run test:nocompile                     # Skip Elixir compilation for faster iteration
```

#### Specific Test Operations
```bash
haxe test/Test.hxml test=feature_name      # Run specific test (with Elixir compilation)
haxe test/Test.hxml update-intended        # Accept new output when compiler improves
haxe test/Test.hxml nocompile              # Skip Elixir compilation (for faster iteration)
npm run test:update                        # Update all intended outputs
npm run test:core                          # Run core functionality tests only
npm run test:verify                        # Verify core functionality + cleanup
```

#### Performance Tuning
```bash
npx haxe test/ParallelTest.hxml -j 24      # Use 24 workers (max 32)
npx haxe test/ParallelTest.hxml -j 32      # Maximum workers for high-core systems
```

#### Development/Debugging
```bash
npm run test:mix-fast                      # Fast Mix tests (stale only)
npm run test:parallel:debug                # Debug parallel test issues
npm run clean                              # Clean all output directories
npm run clean:ex                           # Remove all generated .ex files
npm run clean:todo                         # Clean todo-app generated files
```

## 📋 Quick Testing Reference - When to Use What

### Daily Development Workflow
- **After small compiler changes**: `npm run test:nocompile` (~20s) - Fast output comparison only
- **After significant changes**: `npm run test:quick` (~45s) - With Elixir compilation validation
- **Before ANY commit**: `npm test` (~2-3min) - MANDATORY full validation
- **After refactoring**: `npm run test:examples` - Ensure real projects still compile

### Debugging Failed Tests
- **When parallel tests fail mysteriously**: `npm run test:sequential` - Eliminates concurrency issues
- **To test one specific feature**: `haxe test/Test.hxml test=specific_name`
- **Parallel execution issues**: `npm run test:parallel:debug` - Simpler parallel test
- **After fixing a bug**: Run the specific test first, then `npm test`

### Performance Optimization
- **On high-core machines (16+ cores)**: `npx haxe test/ParallelTest.hxml -j 24`
- **Maximum speed (32+ cores)**: `npx haxe test/ParallelTest.hxml -j 32`
- **Experimental max speed**: `npm run test:parallel-experimental` - Parallel Mix tests too

### Maintenance Tasks
- **Compiler output improved**: `npm run test:update` - Accept new intended outputs
- **Tests leaving artifacts**: `npm run clean` - Reset all test directories
- **Quick sanity check**: `npm run test:verify` - Core tests only
- **Before major refactor**: `npm test && npm run test:examples` - Full baseline

### Integration Testing
- **Todo-app changes**: `cd examples/todo-app && npx haxe build-server.hxml && mix compile`
- **Phoenix integration**: Focus on `liveview_basic`, `router`, `changeset` tests
- **Mix runtime issues**: `npm run test:mix` - Tests actual BEAM execution

### Compilation Testing (Two-Phase Validation)
- **Default behavior**: ALL tests now compile generated Elixir with `mix compile` (like CSharp)
- **Skip compilation**: `haxe test/Test.hxml nocompile` - For faster iteration during development
- **What it does**: Creates minimal mix.exs, runs `mix compile`, and if Main.main() exists, executes it
- **Timeout protection**: 5-second timeout prevents hanging on compilation issues
- **Why default**: Catches syntax errors early, matches CSharp's testing approach
- **Performance impact**: Adds ~1-2s per test (minimized with 5s timeout)

## 🎯 Testing Principles ⚠️ CRITICAL

### ❌ NEVER Do This:
- Modify `intended/` files manually to make tests pass
- Remove test code to fix failures
- Skip tests "just for a small change"
- Ignore test failures as "unrelated"
- Use workarounds instead of fixing root causes

### ✅ ALWAYS Do This:
- Run `npm test` after EVERY compiler modification
- Fix the compiler source to improve output
- Update snapshots ONLY when output legitimately improves
- Test todo-app compilation as integration test
- Fix ALL discovered issues, not just the primary one

## 📝 Snapshot Test Methodology

### Understanding Snapshot Tests
- **Input**: Haxe source files in `test/tests/feature_name/`
- **Process**: Compile via `compile.hxml` configuration
- **Output**: Generated Elixir in `out/` directory
- **Validation**: Compare against files in `intended/` directory

### When to Update Snapshots
**ONLY when the compiler legitimately improves:**
- Better error messages
- More idiomatic Elixir output
- Fixed bugs that produce correct code
- New features working as designed

**NEVER update to hide problems:**
- Compilation errors
- Invalid Elixir syntax
- Regression of working features
- Workarounds for broken functionality

## 🔍 Test Structure Patterns

### Snapshot Test Directory Pattern
```
test/tests/feature_name/
├── compile.hxml       # Compilation configuration
├── Main.hx           # Test source code
├── intended/         # Expected output
│   └── main.ex      # Expected Elixir code (snake_case)
└── out/             # Generated output (for comparison)
```

### ⚠️ CRITICAL: Snake_Case Naming Convention

**ALL .ex files in intended directories MUST use snake_case naming:**
- ✅ `main.ex` (correct) 
- ❌ `Main.ex` (incorrect)
- ✅ `std_types.ex` (correct)
- ❌ `StdTypes.ex` (incorrect)

**Recently Fixed (January 2025)**: Migrated 328 PascalCase intended files to snake_case to match compiler output. This resolves test failures where the compiler correctly generates snake_case but tests expected PascalCase.

### Mix Test Patterns
- Place in `test/` directory with `.exs` extension
- Use `test_helper.ex` for common setup
- Test that generated Elixir actually runs
- Validate Phoenix/Ecto/OTP integrations

## 🚨 Macro-Time vs Runtime Testing

### CRITICAL Understanding
**The compiler exists only at macro-time, NOT at runtime:**
- You CANNOT unit test `ElixirCompiler` directly
- You CANNOT instantiate compiler classes in tests
- You MUST test the OUTPUT, not the compiler internals

### Correct Testing Approach
```haxe
// ❌ WRONG: Cannot test compiler directly
var compiler = new ElixirCompiler(); // ERROR: Type not found at runtime

// ✅ CORRECT: Test the generated output
// 1. Compile Haxe → Elixir
// 2. Validate the .ex files
// 3. Run Mix tests to ensure Elixir code works
```

## 📊 Test Integration with Development

### Todo-App as Integration Benchmark
The `examples/todo-app` serves as the **primary integration test**:
- Tests Phoenix framework integration
- Validates HXX template compilation  
- Ensures router DSL functionality
- Verifies Ecto schema generation
- Confirms LiveView compilation

**Rule**: If todo-app doesn't compile, the compiler is broken regardless of unit tests passing.

### Pre-Commit Testing Protocol
```bash
# MANDATORY before any commit
npm test                                    # All 180 tests must pass
cd examples/todo-app && mix compile        # Integration validation
```

## 🏗️ Test Infrastructure Deep Dive

### Test Runner Architecture
The test suite uses multiple runners for different purposes:

#### Sequential Test Runner (`TestRunner.hx`)
- **Purpose**: Run tests one at a time with detailed output
- **Timeout**: 10 seconds per test (prevents hangs from compilation issues)
- **Process**: Spawns `haxe` process with `timeout` wrapper on Unix
- **Output**: Captures stdout/stderr for validation
- **Files**: Compares `out/` directory against `intended/` directory

#### Parallel Test Runner (`ParallelTestRunner.hx`)
- **Purpose**: Speed up test execution using worker processes
- **Workers**: 16 concurrent workers by default
- **Strategy**: Work-stealing queue for load balancing
- **Performance**: ~87% improvement over sequential execution
- **Platform**: Uses native process spawning per OS

### Generated Files System

#### `_GeneratedFiles.json`
- **Generated by**: Reflaxe compiler automatically
- **Contents**: List of all files generated during compilation
- **Purpose**: Track what files the compiler produces
- **Format**: JSON with file paths and metadata
- **Note**: The `id` field increments and is ignored in comparisons

#### `_GeneratedFiles.txt` (DEPRECATED)
- **Status**: No longer generated as of January 2025
- **Migration**: Remove from all `intended/` directories
- **Reason**: JSON format provides better structure

### File Generation Optimization
The compiler now optimizes file generation:
- **Only used types**: Standard library files only generated when referenced
- **Dead code elimination**: Unused imports don't trigger file generation
- **Result**: Smaller output, faster compilation, cleaner projects

### Expected vs Actual Comparison

#### Standard Output Files
- Compare file contents exactly (after normalization)
- Line ending normalization: `\r\n` → `\n`
- Whitespace at end of lines is trimmed

#### Stderr Validation (`expected_stderr.txt`)
- **Purpose**: Validate compiler warnings/errors
- **Optional**: Only checked if file exists
- **Flexible mode**: Can strip position info for less brittle tests
- **Usage**: For tests that verify error messages

### Test Categories and Their Purpose

#### Core Language Tests
- `basic_syntax`: Fundamental Haxe→Elixir translation
- `classes`: Class and interface compilation
- `enums`: Algebraic data type translation
- `arrays`: List operations and transformations

#### Framework Integration Tests
- `liveview_basic`: Phoenix LiveView compilation
- `router`: Phoenix router DSL generation
- `changeset`: Ecto changeset validation
- `ecto_integration`: Database operations

#### Optimization Tests
- `temp_variable_optimization`: Temporary variable reduction
- `unused_parameters`: Dead parameter elimination
- `loop_patterns`: Loop-to-Enum transformation

#### Pattern Matching Tests
- `pattern_matching`: Basic switch→case compilation
- `enhanced_patterns`: Complex pattern scenarios
- `OrphanedEnumParameters`: Unused enum parameter handling

## 🎯 Testing Anti-Patterns

### Common Mistakes
1. **Testing compiler classes directly** - They don't exist at runtime
2. **Modifying intended files** - Fix the compiler, not the expected output
3. **Skipping integration tests** - Unit tests alone aren't sufficient
4. **Ignoring Mix test failures** - Generated code must actually work
5. **Not testing with todo-app** - Missing real-world integration issues

### Debugging Test Failures
1. **Read the error carefully** - Often points to the real issue
2. **Check recent commits** - What changed that might affect this?
3. **Compare intended vs actual** - What's different and why?
4. **Test manually** - Can you reproduce the issue?
5. **Fix the root cause** - Don't patch the symptoms

## 🔧 Test Maintenance Tasks

### Adding a New Test
1. Create directory: `test/tests/my_feature/`
2. Add `compile.hxml` with compilation config
3. Add `Main.hx` with test code
4. Run test: `haxe test/Test.hxml test=my_feature`
5. Review output in `out/` directory
6. If correct: `haxe test/Test.hxml test=my_feature update-intended`

### Updating Tests After Compiler Changes
```bash
# Update single test
haxe test/Test.hxml test=my_feature update-intended

# Update all tests (use with caution)
npm run test:update

# Verify updates are correct
npm test
```

### Dealing with Timeouts
- **Default timeout**: 10 seconds per test
- **Common causes**: Infinite loops in macro expansion, recursive imports
- **Debug approach**: Run test directly with `npx haxe compile.hxml`
- **Fix**: Usually requires fixing compiler logic, not increasing timeout

## 📚 Related Documentation
- [`/docs/03-compiler-development/TESTING_OVERVIEW.md`](/docs/03-compiler-development/TESTING_OVERVIEW.md) - Complete testing guide
- [`/docs/03-compiler-development/TESTING_PRINCIPLES.md`](/docs/03-compiler-development/TESTING_PRINCIPLES.md) - Testing methodology
- [`/docs/03-compiler-development/COMPILER_TESTING_GUIDE.md`](/docs/03-compiler-development/COMPILER_TESTING_GUIDE.md) - Compiler-specific testing
- [`/docs/05-architecture/TESTING.md`](/docs/05-architecture/TESTING.md) - Technical infrastructure

**Remember**: Testing is not separate from implementation - it IS implementation validation. Every test failure teaches us something about the system.
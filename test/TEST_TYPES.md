# Reflaxe.Elixir Test Infrastructure Documentation

## Overview

The project has multiple test suites testing different aspects of the compiler and tooling:

1. **Haxe Compilation Tests** (`test:parallel`) - Snapshot tests for Haxe→Elixir compilation
2. **Mix Integration Tests** (`test:mix`) - Elixir runtime tests for Mix tasks and tooling
3. **Project Generator Tests** (`test:generator`) - Tests for project template generation

## 1. Haxe Compilation Tests (Snapshot Tests)

**Location**: `test/tests/*`  
**Runner**: `test/Makefile.parallel` (Make-based)  
**Purpose**: Verify the Haxe→Elixir compiler generates correct output

### How They Work:
- Each test directory has:
  - `Main.hx` - Haxe source code to compile
  - `compile.hxml` - Compilation configuration
  - `intended/` - Expected Elixir output files
  - `out/` - Generated Elixir output (gitignored)
- Tests pass if `out/` matches `intended/` byte-for-byte

### Status:
- **Infrastructure**: ✅ FIXED - Make-based runner works perfectly
- **Test Baselines**: ⚠️ ~71/76 tests have outdated intended outputs
- **Run with**: `npm run test:parallel` or `make -f test/Makefile.parallel -j8`

## 2. Mix Integration Tests

**Location**: `test/*.exs`  
**Runner**: ExUnit (Elixir's test framework)  
**Purpose**: Test the Mix compiler tasks and Elixir-side tooling

### Test Files and Their Purpose:

#### Core Compiler Integration:
- **`haxe_compiler_test.exs`** - Tests `HaxeCompiler` module that invokes the Haxe compiler
  - Verifies compilation success/failure detection
  - Tests server mode vs standalone compilation
  - Validates error message extraction

- **`mix_integration_test.exs`** - Tests `Mix.Tasks.Compile.Haxe` 
  - Verifies Mix build pipeline integration
  - Tests incremental compilation
  - Validates file watching triggers

#### File Watching & Development Tools:
- **`haxe_watcher_test.exs`** - Tests `HaxeWatcher` GenServer
  - File system monitoring
  - Auto-recompilation on changes
  - Debouncing rapid changes

- **`file_watching_integration_test.exs`** - End-to-end file watching
  - Tests complete watching workflow
  - Validates compilation triggers

#### Error Handling & Reporting:
- **`haxe_error_parsing_test.exs`** - Tests error parsing from Haxe output
  - Extracts error messages, positions, types
  - Formats errors for developer display

- **`complete_error_integration_test.exs`** - End-to-end error scenarios
  - Tests with real compiler error samples
  - Validates error storage and retrieval

- **`stacktrace_integration_test.exs`** - Tests stack trace extraction
  - ⚠️ **BROKEN**: References missing `Mix.Tasks.Haxe.Errors` module
  - ⚠️ **BROKEN**: References missing `Mix.Tasks.Haxe.Stacktrace` module

#### Server Mode:
- **`haxe_server_test.exs`** - Tests `HaxeServer` GenServer
  - Haxe compilation server management
  - Port allocation and cleanup
  - Performance optimization via server mode

#### Utility Tests:
- **`test_runner_update_intended_test.exs`** - Tests the test runner's update-intended functionality
- **`verify_real_errors_test.exs`** - Validates error handling with real-world error cases

### Status of Mix Tests (August 26, 2025):
1. **Restored Modules**: 
   - All Mix tasks accidentally deleted in commit 31ed49d have been restored
   - `Mix.Tasks.Haxe.Errors` - ✅ Restored and working
   - `Mix.Tasks.Haxe.Stacktrace` - ✅ Restored and working
   - 6 other Mix.Tasks.Haxe.Gen.* tasks also restored
   
2. **Relevance Questions**:
   - Do we need all these development tool tests?
   - Should error reporting be simplified?
   - Is the Haxe server mode being used?

### Current Test Status:
- **125 tests passing** out of 133 total
- **8 tests failing** (unrelated to restored Mix tasks):
  - TestRunnerUpdateIntendedTest issues
  - MixIntegrationTest compilation/configuration issues
- **1 test skipped**

### Run with:
```bash
MIX_ENV=test mix test                    # Run all Mix tests
MIX_ENV=test mix test test/haxe_compiler_test.exs  # Run specific test
```

## 3. Project Generator Tests

**Location**: `test/TestProjectGeneratorTemplates.hxml`  
**Purpose**: Test Mix project generation templates

### What It Tests:
- Project scaffolding generation
- Template variable substitution
- File structure creation

### Status:
- Need to investigate current state
- May be outdated if templates have changed

## Recommendations

### Keep and Maintain:
1. **Haxe Compilation Tests** - Core functionality, must have
2. **`haxe_compiler_test.exs`** - Tests core compiler integration
3. **`mix_integration_test.exs`** - Tests Mix task integration

### Recently Fixed (August 26, 2025):
1. **`stacktrace_integration_test.exs`** - ✅ Fixed by restoring missing Mix tasks
2. **Mix.Tasks.Haxe.* modules** - ✅ All 10 Mix tasks restored from accidental deletion
3. **Error reporting infrastructure** - ✅ Fully functional with restored tasks

### Still Need Investigation:
1. **MixIntegrationTest failures** - Configuration and compilation issues
2. **File watching tests** - Verify if still used in practice

### Questions to Answer:
1. Is the Haxe compilation server actually being used?
2. Do users need elaborate error reporting or just basic output?
3. Is file watching a critical feature or nice-to-have?
4. Should we focus on core compilation and drop peripheral features?

## Test Execution Flow

```bash
npm test
├── test:parallel (Make-based Haxe compilation tests)
├── test:generator (Project templates)
└── test:mix (Elixir runtime tests)
```

All three must pass for a successful build, but currently:
- Compilation tests: Infrastructure works, baselines outdated
- Mix tests: Some broken due to missing modules
- Generator tests: Status unknown

## Priority for Fixes

1. **COMPLETED**: ~~Fix or remove broken Mix tests (missing modules)~~ - Restored all missing Mix tasks
2. **HIGH**: Update Haxe test baselines to match current compiler output (71/76 tests outdated)
3. **HIGH**: Fix remaining MixIntegrationTest failures (8 tests)
4. **MEDIUM**: Consolidate redundant Mix tests
5. **LOW**: Investigate project generator relevance

## Important Historical Note

**August 20, 2025**: Commit 31ed49d accidentally deleted 10 critical Mix tasks (~5,200 lines) while attempting to fix Y combinator syntax issues. This included all the `haxe.gen.*` generators, error/stacktrace tools, inspection tools, and source map support.

**August 26, 2025**: All Mix tasks were restored after discovering test failures. A CLAUDE.md file was added to lib/mix/tasks/ to prevent future accidental deletion.
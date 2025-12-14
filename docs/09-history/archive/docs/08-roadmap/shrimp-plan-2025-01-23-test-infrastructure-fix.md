# Shrimp Plan: Test Infrastructure Fix and Compiler Improvements
**Date**: 2025-01-23
**Context**: Discovered during String.cross.hx implementation that test infrastructure doesn't validate Elixir syntax properly

## Critical Issues Discovered

1. **Test Infrastructure Flaw**: Tests only validate Elixir syntax when diff passes, allowing invalid Elixir to persist in intended/ outputs
2. **Compiler Bug**: Generates invalid syntax like `case...end.to_string()` instead of `(case...end) |> Kernel.to_string()`
3. **Invalid Test Baselines**: Many intended/ outputs contain invalid Elixir that has gone undetected

## Comprehensive Task Plan

### Phase 1: Critical Infrastructure Fixes

#### Task 1: Fix Makefile to Always Validate Elixir Syntax
- **Priority**: HIGHEST
- **Description**: Modify test/Makefile to validate Elixir syntax for ALL tests, not just when diff passes
- **Implementation**: Restructure test logic around lines 91-109 to always run elixirc validation
- **Verification**: Tests with invalid Elixir in intended/ should FAIL even if output matches

#### Task 2: Audit and Fix All Intended Outputs
- **Priority**: HIGH
- **Description**: Scan ALL test/snapshot/*/intended/*.ex files for invalid Elixir syntax
- **Implementation**: Script to run elixirc on every intended file, fix patterns like unparenthesized block expressions
- **Dependencies**: Task 1
- **Verification**: All intended/*.ex files must compile without errors

#### Task 3: Fix Compiler Bug for Method Calls on Block Expressions
- **Priority**: HIGH
- **Description**: Fix invalid syntax generation for method calls on case/if/cond expressions
- **Implementation**: Modify ElixirASTPrinter to wrap block expressions in parentheses when they're method call targets
- **Verification**: Case expressions with method calls generate valid parenthesized Elixir

### Phase 2: Enhanced Validation

#### Task 4: Add Runtime Execution Validation
- **Priority**: MEDIUM
- **Description**: Add optional runtime execution to catch runtime errors beyond syntax
- **Implementation**: New Make target to execute Main.main() in tests
- **Dependencies**: Task 1
- **Verification**: Can run 'make test-with-runtime' to execute tests

### Phase 3: Complete String.cross.hx Work

#### Task 5: Complete String.cross.hx Validation
- **Priority**: MEDIUM
- **Description**: Ensure String.cross.hx generates valid Elixir for all operations
- **Dependencies**: Tasks 2, 3
- **Verification**: Strings test passes with valid, compilable, runnable Elixir

### Phase 4: Original Shrimp Plan Tasks (2-9)

#### Task 6: Enhance String Interpolation Coverage
- **Description**: Remove unnecessary .to_string() calls in interpolation contexts
- **Implementation**: Detect interpolation contexts in ElixirASTBuilder, skip .to_string() for auto-converted types

#### Task 7: Optimize StringTools.cross.hx
- **Description**: Replace reduce_while patterns with idiomatic Elixir string functions
- **Implementation**: Use String.graphemes/1, String.codepoints/1, pattern matching

#### Task 8: Fix Loop Patterns Comprehensively
- **Description**: Transform loops to Elixir comprehensions and Enum functions
- **Implementation**: Enhance ElixirASTTransformer loop transformation passes

#### Task 9: Fix Enum Pattern Matching
- **Description**: Generate idiomatic pattern matching with atoms and tuples
- **Implementation**: Direct destructuring instead of elem() extraction

#### Task 10: Run Comprehensive Test Suite
- **Description**: Ensure all tests pass with valid Elixir
- **Dependencies**: Tasks 6-9
- **Verification**: 80%+ tests pass with valid Elixir

#### Task 11: Create Additional .cross.hx Overrides
- **Description**: Identify other types needing idiomatic overrides (Int, Float, Bool)
- **Dependencies**: Task 10

#### Task 12: Validate Todo-App
- **Description**: Ultimate integration test with Phoenix app
- **Dependencies**: Task 11
- **Verification**: Todo-app compiles, runs, CRUD operations work

#### Task 13: Document Solutions
- **Description**: Comprehensive documentation of fixes and patterns
- **Dependencies**: Task 12

## Key Lessons Learned

1. **Test infrastructure must validate syntax unconditionally** - Not just when output matches
2. **Method calls on block expressions need parentheses** - Elixir syntax requirement
3. **.cross.hx pattern is superior to AST transformations** - Generate idiomatic code from the start
4. **Technical debt accumulates silently** - Invalid test baselines went undetected

## Success Criteria

- All tests validate Elixir syntax before checking output
- No invalid Elixir in any intended/ outputs
- Compiler generates valid syntax for all patterns
- Todo-app runs successfully with all improvements
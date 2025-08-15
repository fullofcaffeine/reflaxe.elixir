# Testing Principles for Reflaxe.Elixir

## Core Testing Philosophy

All testing in Reflaxe.Elixir follows these fundamental principles to ensure quality, maintainability, and proper coverage of the transpiler functionality.

## Critical Testing Rules ⚠️

### Snapshot Testing: Update-Intended Mechanism ✅
**CRITICAL WORKFLOW TOOL**: The `update-intended` mechanism is used to accept new compiler output as the baseline for snapshot tests.

**When to use `npx haxe test/Test.hxml update-intended`:**
- ✅ **Legitimate compiler improvements** - Function body compilation fix, new features working correctly
- ✅ **Architectural changes** - Core compiler changes that improve output quality  
- ✅ **Standard library updates** - New Haxe standard library files being generated correctly
- ✅ **Expression compiler enhancements** - Better code generation producing more complete output

**When NOT to use update-intended:**
- ❌ **Test failures due to bugs** - Fix the bug, don't accept broken output
- ❌ **Compilation errors** - Resolve errors, don't accept error output as intended
- ❌ **Regression issues** - Fix regressions, don't accept degraded output
- ❌ **Non-deterministic output** - Fix consistency issues, don't accept random output

**Workflow:**
```bash
# 1. Verify new output is actually correct and improved
npx haxe test/Test.hxml show-output  # Review what changed

# 2. Accept new output as baseline if improvements are legitimate  
npx haxe test/Test.hxml update-intended

# 3. Verify consistency by running tests again
npx haxe test/Test.hxml  # Should show 28/28 passing
```

### NEVER Remove Test Code to Fix Failures
**ABSOLUTE RULE**: Never remove or simplify test code just to make tests pass. This destroys test coverage and defeats the purpose of testing.

When a test fails:
1. **Fix the underlying compiler/implementation issue** - The test is revealing a real problem
2. **Fix syntax errors properly** - Don't remove functionality, fix the syntax
3. **Enhance the compiler if needed** - If the test reveals missing features, implement them
4. **Document limitations** - If something truly can't be supported, document it clearly

Example of WRONG approach:
```haxe
// BAD: Removing test functionality to avoid syntax errors
// Before: Testing important migration features
t.addColumn("id", "serial", {primary_key: true});
// After: Gutted test that doesn't test anything
// Table columns defined via comments
```

Example of RIGHT approach:
```haxe
// GOOD: Fix the syntax issue while preserving test coverage
// Use alternative syntax that Haxe can parse
addColumn("users", "id", "serial", true, null); // primary_key param
```

**Remember**: Tests exist to ensure quality. Reducing test coverage to achieve "passing tests" is self-defeating.

### Simplification Principle: As Simple As Needed ⚖️
**CRITICAL GUIDELINE**: When fixing tests or implementation issues, apply appropriate simplification:

- ✅ **Simplification is good** - Remove unnecessary complexity, improve readability
- ❌ **Oversimplification is harmful** - Don't lose resolution, features, or knowledge
- 🎯 **Target: As simple as *needed*, not more, not less**

**Example of harmful oversimplification:**
```haxe
// WRONG: Oversimplifying metadata from complex objects to strings
// Before: Rich metadata with type information
@:field({type: "string", nullable: false, unique: true})
// After: Lost all constraints and type information
@:field("string")  // ❌ Lost nullable and unique constraints!
```

**Example of appropriate simplification:**
```haxe
// RIGHT: Keep complexity where it adds value
@:field({type: "string", nullable: false, unique: true})  // Preserves all constraints
// But avoid reserved keywords like "default"
@:field({type: "integer", defaultValue: 0})  // Use "defaultValue" not "default"
```

**When in doubt**: Check reference implementations (Haxe API, existing Reflaxe projects) rather than guessing or oversimplifying.

## Test Architecture Documentation

### Understanding the Testing Layers
For detailed technical architecture of our testing infrastructure:
- **[`architecture/TESTING.md`](architecture/TESTING.md)** - Complete testing architecture documentation
- **[`TEST_SUITE_DEEP_DIVE.md`](TEST_SUITE_DEEP_DIVE.md)** - Analysis of all 155+ tests across three layers
- **[`DEVELOPMENT_TOOLS.md`](DEVELOPMENT_TOOLS.md)** - How to run and use testing tools

### Test Categories
- **Snapshot Tests** (28 tests): Validate compiler output against expected Elixir code
- **Mix Integration Tests** (130 tests): Validate generated code actually runs
- **Example Tests** (9 tests): Real-world usage patterns

## Creating New Tests

### Snapshot Test Pattern
**✅ ALWAYS follow Reflaxe snapshot testing pattern:**

1. **Create test directory**: `test/tests/feature_name/`
2. **Write Haxe source**: `Main.hx` with feature to test
3. **Create compile config**: `compile.hxml` with compilation settings  
4. **Generate expected output**: `haxe test/Test.hxml update-intended`
5. **Verify output**: Check generated Elixir is correct

**Example test structure:**
```
test/tests/my_feature/
├── compile.hxml    # Haxe compilation config
├── Main.hx         # Test source code
├── intended/       # Expected Elixir output
│   └── Main.ex     # Expected generated file
└── out/            # Actual output (for comparison)
```

### Test Commands
- `npm test` - Run all snapshot tests
- `haxe test/Test.hxml test=feature_name` - Run specific test  
- `haxe test/Test.hxml update-intended` - Accept current output
- `haxe test/Test.hxml show-output` - Show compilation details

## Edge Case Testing Requirements

All test suites implementing TDD methodology MUST include comprehensive edge case testing covering these 7 categories:

1. **Error Conditions** 🔴 - Invalid inputs, unsupported operations, type mismatches
2. **Boundary Cases** 🔶 - Empty collections, large datasets, edge values
3. **Security Validation** 🛡️ - Input sanitization, escape handling
4. **Performance Limits** 🚀 - <15ms compilation target, memory monitoring
5. **Integration Robustness** 🔗 - Cross-component compatibility, error propagation
6. **Type Safety** 🎯 - Invalid combinations, null handling, default fallbacks
7. **Resource Management** 💾 - Memory cleanup, resource limits, disposal validation

## Understanding Test Failures Before Updating Snapshots ⚠️

**CRITICAL RULE**: When tests fail, you MUST understand WHY before updating snapshots.

**Do NOT blindly run `update-intended` on failing tests.** Snapshot changes may indicate regressions.

### Proper Test Failure Investigation Process

#### 1. Analyze the Failure First 🔍
```bash
# Step 1: See what actually changed in the output
haxe test/Test.hxml test=failing_test show-output

# Step 2: Compare current vs expected output manually
diff test/tests/failing_test/out/Main.ex test/tests/failing_test/intended/Main.ex

# Step 3: Understand the root cause
# - Is this a regression? (something that used to work broke)
# - Is this an improvement? (compiler generates better code)
# - Is this a breaking change? (intentional behavior change)
```

#### 2. Classification of Test Failures

**🔴 REGRESSION (Fix Required)**:
- Lambda variables broken: `item != item` instead of `item != id`
- Missing function bodies: `# TODO: Implement` instead of actual code
- Invalid syntax: Generated code doesn't compile
- Loss of functionality: Features that worked before now broken

**Action**: Fix the compiler bug, don't update snapshots

**🟢 IMPROVEMENT (Update Allowed)**:
- Better parameter names: `greet(name)` instead of `greet(arg0)`
- Enhanced code generation: More idiomatic Elixir output
- New features working: Additional functionality added correctly
- Performance optimizations: Better generated code

**Action**: Review improvement, then use `update-intended` if legitimate

**🟡 BREAKING CHANGE (Document + Update)**:
- Intentional API changes: New annotation syntax, different DSL
- Architecture shifts: Different compilation approach
- Standard library updates: Haxe language changes affecting output

**Action**: Document the change, update snapshots, update migration guides

#### 3. Regression Detection Patterns

**Common Regression Indicators**:
- Variables with wrong names (`item != item`, `v` instead of lambda parameter)
- Empty or placeholder code (`TODO`, `nil` where logic should be)
- Syntax errors in generated code (invalid Elixir)
- Missing imports or undefined functions
- Type errors or compilation failures

**Red Flags in Snapshot Diffs**:
```diff
# 🚨 REGRESSION: Lambda variable scoping broken
- Enum.filter(items, fn item -> item != id end)
+ Enum.filter(items, fn item -> item != item end)

# 🚨 REGRESSION: Function body disappeared  
- def calculate(price, tax), do: price * (1 + tax)
+ def calculate(price, tax), do: nil

# 🚨 REGRESSION: Type lost
- %{"id" => id, "name" => name}
+ %{id => id, name => name}  # Invalid: variables as keys
```

#### 4. Investigation Commands

```bash
# Show detailed test output and compilation process
haxe test/Test.hxml test=LambdaVariableScope show-output

# Run specific test in verbose mode
haxe test/Test.hxml test=LambdaVariableScope --verbose

# Check if other tests are affected (potential systemic issue)
npm test 2>&1 | grep "FAILED\|ERROR"

# Compare with previous working version (if in git)
git show HEAD~1:test/tests/LambdaVariableScope/intended/Main.ex
```

### 5. When to Update Snapshots

**✅ Safe to Update When**:
- You can explain exactly what improved and why
- Generated code is more correct/idiomatic than before
- All tests still pass after the update
- The change aligns with documented improvements

**❌ Never Update When**:
- You can't explain what changed or why
- Generated code is less functional than before  
- Other tests started failing after your changes
- You're updating just to make tests pass

### 6. Example Regression Prevention

**Lambda Variable Substitution Test**:
- **Location**: `test/tests/LambdaVariableScope/`
- **Purpose**: Prevents regression where `item != item` instead of `item != id`
- **Key Lines**: Lines 24, 31, 86 validate correct variable scoping
- **If This Fails**: Lambda substitution logic has regressed - fix compiler, don't update

## Common Testing Mistakes to Avoid

❌ **DON'T**:
- Don't create tests without intended/ directories  
- Don't manually write expected Elixir output (use update-intended)
- Don't ignore test failures (they indicate compilation changes)
- Don't mix testing approaches (use consistent snapshot pattern)
- Don't remove test code to make tests pass
- Don't oversimplify tests to avoid syntax errors
- **Don't update snapshots without understanding what changed**
- **Don't assume test failures are always improvements**

✅ **DO**:
- Fix the underlying issues that cause test failures
- Maintain or increase test coverage
- Use update-intended only for legitimate improvements
- Document any true limitations clearly
- Keep tests as simple as needed, but no simpler
- **Investigate test failures thoroughly before updating**
- **Validate that snapshot changes represent genuine improvements**

## Framework Integration Debugging ⚛️

### Critical Pattern for Phoenix/Framework Issues

**KEY INSIGHT**: Framework compilation errors are usually about file location/structure, not language compatibility.

When debugging Phoenix/framework integration issues:

#### 1. Check File Locations First 📁
**Most Common Issue**: Generated files in wrong locations
```bash
# ❌ Wrong: Generated by compiler
/lib/TodoAppRouter.ex

# ✅ Correct: Phoenix expectation  
/lib/todo_app_web/router.ex
```

**Debug Steps**:
1. Check where files are actually generated vs. where framework expects them
2. Verify directory structure matches framework conventions
3. Ensure proper Phoenix web module hierarchy

#### 2. Verify Module Names 🏷️
**Issue**: Module names don't match Phoenix conventions
```elixir
# ❌ Wrong: Direct Haxe class name
defmodule TodoAppRouter do

# ✅ Correct: Phoenix web module
defmodule TodoAppWeb.Router do
```

#### 3. Framework Error Translation 🔍
**Common Framework Errors and Real Causes**:
- `Phoenix.plug_init_mode/0 undefined` → Router file in wrong location
- `Module not found` errors → File path doesn't match module name
- `Function undefined` → Module not loaded due to wrong location
- Compilation timeouts → Circular dependencies from wrong imports

#### 4. Debug Workflow 🔧
```bash
# Step 1: Check what's generated
find lib/ -name "*.ex" | head -10

# Step 2: Check Phoenix expectations
# Router should be at: lib/app_web/router.ex
# LiveViews should be at: lib/app_web/live/*.ex

# Step 3: Clean and regenerate
rm -rf _build deps lib/*.ex
mix deps.get
npx haxe build.hxml

# Step 4: Test framework compilation
mix compile
```

#### 5. Convention Adherence Rules 📋
**Generated code MUST follow framework conventions**:
- ✅ **File locations** - Where framework expects them
- ✅ **Module names** - Match framework patterns  
- ✅ **Directory structure** - Follow framework layout
- ✅ **Naming conventions** - Use framework standards

**Don't assume language syntax is the issue** - check framework integration first.

### RouterCompiler Debugging Example

**Problem**: `Phoenix.plug_init_mode/0` error during compilation

**Wrong Debug Approach**:
```bash
# ❌ Assume it's Phoenix version issue
# ❌ Try to fix deprecated function usage
# ❌ Update Phoenix dependencies
```

**Correct Debug Approach**:
```bash
# ✅ Check file location first
ls lib/todo_app_web/router.ex  # Should exist
ls lib/TodoAppRouter.ex        # Shouldn't exist

# ✅ Check module name in file
grep "defmodule" lib/todo_app_web/router.ex
# Should show: defmodule TodoAppWeb.Router

# ✅ Fix RouterCompiler output location logic
# Update RouterCompiler.hx to generate files in correct Phoenix locations
```

**Lesson**: The error was about module loading from wrong location, not deprecated function usage.

## Compile-Time Validation Testing 🔍

Reflaxe.Elixir supports testing of compile-time logic such as macro warnings and errors. This is essential for testing features like RouterBuildMacro validation.

### Test Types Overview

**Snapshot Tests** (Primary): Test generated code output
- Located in: `test/tests/`
- Purpose: Validate transpiled Elixir code matches expected output
- Pattern: `compile.hxml` + `Main.hx` + `intended/` directory

**Compile-Time Tests**: Test macro warnings/errors during compilation  
- Located in: `test/tests/` (same location, additional validation)
- Purpose: Validate compiler warnings, errors, and macro behavior
- Pattern: Snapshot tests + `expected_stderr.txt` file

### Creating Compile-Time Validation Tests

#### 1. Test Structure
```
test/tests/RouterBuildMacro_InvalidController/
├── compile.hxml           # Standard compilation config
├── Main.hx                # Test source with invalid references
├── expected_stderr.txt    # Expected warnings/errors
├── intended/              # Expected Elixir output (still required)
│   └── Main.ex
└── out/                   # Actual output (for comparison)
```

#### 2. Test Categories
**Valid Case Tests**: No warnings expected
```bash
# expected_stderr.txt should be empty or contain only comments
# Expected stderr output for valid controller/action test
# Should be empty - no warnings expected
```

**Invalid Reference Tests**: Specific warnings expected
```bash
# expected_stderr.txt contains exact warning text
Main.hx:39: lines 39-41 : Warning : Controller "NonExistentController" not found. Ensure the class exists and is in the classpath.
```

**Multiple Validation Failures**: Multiple warnings expected
```bash
# Multiple lines for different validation failures
Main.hx:67: lines 67-69 : Warning : Controller "NonExistentController" not found. Ensure the class exists and is in the classpath.
Main.hx:67: lines 67-69 : Warning : Action "create" not found on controller "PartialController".
```

#### 3. Enhanced TestRunner Capabilities
The TestRunner now validates both:
- **Generated Code**: Standard snapshot comparison (`out/` vs `intended/`)
- **Compilation Warnings**: Stderr output vs `expected_stderr.txt`

#### 4. Testing Workflow
```bash
# 1. Create test with expected warnings
# 2. Run test to see actual stderr format
haxe test/Test.hxml test=MyValidationTest

# 3. Update expected_stderr.txt with actual format
# 4. Generate intended output
haxe test/Test.hxml test=MyValidationTest update-intended

# 5. Verify test passes
haxe test/Test.hxml test=MyValidationTest
```

### RouterBuildMacro Validation Examples

**Valid Controller/Action** (`RouterBuildMacro_ValidController`):
- Tests: Valid controller and action references
- Expected: No warnings (empty stderr)
- Purpose: Baseline validation that correct usage produces no warnings

**Invalid Controller** (`RouterBuildMacro_InvalidController`):
- Tests: Reference to non-existent controller class
- Expected: "Controller not found" warning
- Purpose: Validates controller existence checking

**Invalid Action** (`RouterBuildMacro_InvalidAction`):
- Tests: Valid controller but non-existent action method
- Expected: "Action not found on controller" warning
- Purpose: Validates action method existence checking

**Multiple Invalid** (`RouterBuildMacro_MultipleInvalid`):
- Tests: Multiple validation failures in one test
- Expected: Multiple warnings for different failures
- Purpose: Validates all validation types work together

### Best Practices for Compile-Time Tests

✅ **DO**:
- Test both valid and invalid cases
- Use exact warning message format in `expected_stderr.txt`
- Include line numbers and positions as they appear
- Test edge cases and multiple failure scenarios
- Use descriptive test names indicating what's being validated

❌ **DON'T**:
- Don't guess warning message format (run test to see actual format)
- Don't hardcode line numbers without checking actual position
- Don't skip testing valid cases (no warnings expected)
- Don't mix multiple validation types in one test unless testing interaction

### stderr Validation Features

**Automatic Normalization**: 
- Removes comments (lines starting with `#`)
- Trims whitespace
- Ignores empty lines

**Flexible Validation**:
- Missing `expected_stderr.txt` = skip stderr validation
- Empty `expected_stderr.txt` = expect no warnings
- Detailed diff output when validation fails

**Integration with Snapshot Testing**:
- Both stderr and generated code must match
- Failed stderr validation = test failure
- Works with existing `update-intended` workflow

### Flexible Position Matching 🎯

**Problem**: Exact line number matching makes tests brittle to code changes
**Solution**: Optional position-independent stderr validation

#### Usage
```bash
# Standard mode: Exact position matching (default)
haxe test/Test.hxml test=RouterBuildMacro_InvalidController

# Flexible mode: Strip position information from comparison
haxe test/Test.hxml test=RouterBuildMacro_InvalidController flexible-positions
```

#### How It Works
**Standard Mode**: Matches exact compiler output including positions
```bash
# expected_stderr.txt
Main.hx:39: lines 39-41 : Warning : Controller "NonExistentController" not found in route "invalidRoute" (path: "/invalid"). Ensure the class exists and is in the classpath.
```

**Flexible Mode**: Strips position info, matches warning content only
```bash
# expected_stderr_flexible.txt  
Warning : Controller "NonExistentController" not found in route "invalidRoute" (path: "/invalid"). Ensure the class exists and is in the classpath.
```

#### Implementation Details
- **File Selection**: Uses `expected_stderr_flexible.txt` when `flexible-positions` flag is used
- **Pattern Matching**: Regex strips `filename:line: lines start-end :` prefixes
- **Fallback**: Uses regular `expected_stderr.txt` if flexible file doesn't exist
- **Normalization**: Applied to both expected and actual stderr before comparison

#### When to Use
✅ **Use Flexible Mode For**:
- Tests focusing on warning message content, not exact positions
- CI/CD environments where line numbers may vary due to code formatting
- Refactoring scenarios where test logic stays the same but positions shift

❌ **Use Standard Mode For**:
- Tests where exact position information is critical
- Debugging specific line number issues  
- Ensuring warnings appear at exactly the right source locations

This testing approach ensures that macro-time validation logic works correctly and provides appropriate feedback to developers using the DSL.

## Related Documentation

- **[`architecture/TESTING.md`](architecture/TESTING.md)** - Technical testing architecture
- **[`TEST_SUITE_DEEP_DIVE.md`](TEST_SUITE_DEEP_DIVE.md)** - What each test validates
- **[`MACRO_TIME_TESTING_STRATEGY.md`](MACRO_TIME_TESTING_STRATEGY.md)** - Macro-time vs runtime testing
- **[`MODULE_TEST_DOCUMENTATION.md`](MODULE_TEST_DOCUMENTATION.md)** - Module test patterns
- **[`PATTERN_TESTS_MIGRATION.md`](PATTERN_TESTS_MIGRATION.md)** - Pattern matching tests
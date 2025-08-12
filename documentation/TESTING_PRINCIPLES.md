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

## Common Testing Mistakes to Avoid

❌ **DON'T**:
- Don't create tests without intended/ directories  
- Don't manually write expected Elixir output (use update-intended)
- Don't ignore test failures (they indicate compilation changes)
- Don't mix testing approaches (use consistent snapshot pattern)
- Don't remove test code to make tests pass
- Don't oversimplify tests to avoid syntax errors

✅ **DO**:
- Fix the underlying issues that cause test failures
- Maintain or increase test coverage
- Use update-intended only for legitimate improvements
- Document any true limitations clearly
- Keep tests as simple as needed, but no simpler

## Related Documentation

- **[`architecture/TESTING.md`](architecture/TESTING.md)** - Technical testing architecture
- **[`TEST_SUITE_DEEP_DIVE.md`](TEST_SUITE_DEEP_DIVE.md)** - What each test validates
- **[`MACRO_TIME_TESTING_STRATEGY.md`](MACRO_TIME_TESTING_STRATEGY.md)** - Macro-time vs runtime testing
- **[`MODULE_TEST_DOCUMENTATION.md`](MODULE_TEST_DOCUMENTATION.md)** - Module test patterns
- **[`PATTERN_TESTS_MIGRATION.md`](PATTERN_TESTS_MIGRATION.md)** - Pattern matching tests
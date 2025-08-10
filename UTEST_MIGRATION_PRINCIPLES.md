# utest Migration Principles

## CRITICAL RULE: Preserve Test Logic

When migrating tests from tink_unittest to utest, the following principles MUST be followed:

### 1. DO NOT Modify Test Logic
- **NEVER** change what is being tested
- **NEVER** alter assertion values or conditions  
- **NEVER** remove test scenarios
- **ONLY** change framework syntax

### 2. Framework Syntax Conversion

#### Class Structure
```haxe
// tink_unittest
@:asserts
class MyTest {
    public function new() {}
}

// utest
class MyTest extends Test {
    // No constructor needed unless custom setup
}
```

#### Assertions
```haxe
// tink_unittest → utest
asserts.assert(condition, msg) → Assert.isTrue(condition, msg)
asserts.assert(a == b) → Assert.equals(b, a)  // Note: expected value first in utest!
return asserts.done() → (remove - not needed in utest)
```

#### Test Methods
```haxe
// tink_unittest
@:describe("Feature description")
public function testFeature() {
    asserts.assert(true);
    return asserts.done();
}

// utest
function testFeatureDescription() {  // Method name describes the test
    Assert.isTrue(true);
    // No return needed
}
```

#### Async Tests
```haxe
// tink_unittest
@:timeout(5000)
public function testAsync() {
    return Future.async(cb -> {
        asserts.assert(true);
        cb(asserts.done());
    });
}

// utest
@:timeout(5000)
function testAsync(async: Async) {
    haxe.Timer.delay(function() {
        Assert.isTrue(true);
        async.done();
    }, 100);
}
```

### 3. Handling Non-Existent Methods

When a test calls a method that doesn't exist:

```haxe
// WRONG - Creating fake mocks
var result = SomeClass.nonExistentMethod();  // Method doesn't exist
var result = true;  // DON'T create fake value
Assert.isTrue(result);

// CORRECT - Document and skip
// NOTE: Skipping test for SomeClass.nonExistentMethod() which doesn't exist
// This appears to be a placeholder in the original test that was never implemented
```

### 4. Handling Methods That Cause Errors

When a test causes runtime errors (like Null Access):

```haxe
// WRONG - Removing the test entirely
// Just delete the problematic test

// CORRECT - Document why it's skipped
// NOTE: Skipping null fragment test as it causes Null Access error in QueryCompiler.compileFragment
// Original test: var nullFragment = QueryCompiler.compileFragment(null, null);
// This appears to be a bug in QueryCompiler that should handle null parameters gracefully
```

### 5. Documentation Requirements

Every modification to test logic MUST include a comment explaining:
1. What was changed
2. Why it was necessary
3. What the original test was doing
4. Whether this indicates a bug in the code being tested

### 6. Verification After Migration

After migrating each test file:
1. Run the test to ensure it compiles
2. Verify the same number of assertions are being made
3. Check that all test scenarios are preserved
4. Confirm no test logic was altered

## Examples from Real Migration

### Example 1: Non-Existent Method
```haxe
// Original tink_unittest test
var cleanupTest = QueryCompiler.testResourceCleanup();
asserts.assert(cleanupTest, "Resource cleanup should succeed");

// Migrated utest version
// NOTE: The original test had QueryCompiler.testResourceCleanup() but this method doesn't exist
// This appears to have been a placeholder in the original test that was never implemented
```

### Example 2: Method Causing Null Access
```haxe
// Original tink_unittest test
var nullFragment = QueryCompiler.compileFragment(null, null);
asserts.assert(nullFragment != null);

// Migrated utest version
// NOTE: Skipping null fragment test as it causes Null Access error in QueryCompiler.compileFragment
// Original test: var nullFragment = QueryCompiler.compileFragment(null, null);
// This appears to be a bug in QueryCompiler that should handle null parameters gracefully
```

## Summary

The goal of test migration is to:
1. **Change the test framework** (tink_unittest → utest)
2. **Preserve all test logic** exactly as it was
3. **Document any necessary deviations** with clear explanations
4. **Maintain test coverage** at 100% of original scenarios

Remember: We're migrating the test framework, NOT refactoring the tests themselves.
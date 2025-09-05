package;

import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;

/**
 * Simple ExUnit test to verify the testing framework works correctly.
 */
@:exunit
class Main extends TestCase {
    
    @:test
    function testBasicAssertions() {
        // Test boolean assertions
        Assert.isTrue(true, "True should be true");
        Assert.isFalse(false, "False should be false");
        
        // Test equality
        Assert.equals(42, 42, "Numbers should be equal");
        Assert.notEquals("hello", "world", "Strings should not be equal");
        
        // Test null checks
        var nullValue: Dynamic = null;
        Assert.isNull(nullValue, "Null value should be null");
        
        var nonNullValue = "something";
        Assert.isNotNull(nonNullValue, "String should not be null");
    }
    
    @:test
    function testFailureAssertion() {
        // This test intentionally demonstrates Assert.fail
        // In a real test, this would only be used in unreachable code paths
        var shouldNotReach = false;
        if (shouldNotReach) {
            Assert.fail("This code should never be reached");
        }
        
        // If we get here, the test passes
        Assert.isTrue(true, "Test should complete without failure");
    }
}
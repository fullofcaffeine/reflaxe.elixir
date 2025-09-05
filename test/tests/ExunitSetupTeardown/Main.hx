package;

import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;

/**
 * Test for ExUnit setup/teardown support
 * 
 * This test verifies:
 * - @:setup creates proper setup callbacks
 * - @:setupAll creates proper setup_all callbacks  
 * - @:teardown creates teardown callbacks
 */
@:exunit
class Main extends TestCase {
    
    /**
     * Setup all - runs once before all tests
     */
    @:setupAll
    function beforeAllTests() {
        // Initialize shared test resources
        trace("Setup all called");
    }
    
    /**
     * Setup - runs before each test
     */
    @:setup
    function beforeEachTest() {
        // Initialize per-test state
        trace("Setup called");
    }
    
    /**
     * Teardown - runs after each test
     */
    @:teardown
    function afterEachTest() {
        // Clean up per-test resources
        trace("Teardown called");
    }
    
    /**
     * Test basic assertions
     */
    @:test
    function testBasic() {
        Assert.equals(1, 1, "Basic equality should work");
        Assert.isTrue(true, "True should be true");
        Assert.isFalse(false, "False should be false");
    }
    
    /**
     * Test string operations
     */
    @:test
    function testString() {
        var str = "Hello";
        Assert.equals(5, str.length, "String length should be 5");
        Assert.equals("HELLO", str.toUpperCase(), "Uppercase should work");
    }
}
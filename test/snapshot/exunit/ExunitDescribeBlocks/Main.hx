import exunit.TestCase;
import exunit.Assert.*;

/**
 * Test demonstrating ExUnit describe blocks, async tests, and tags
 */
@:exunit
class Main extends TestCase {
    
    // Tests for string manipulation - should be grouped in a describe block
    @:describe("String operations")
    @:test
    function testStringUppercase(): Void {
        assertEqual("HELLO", "hello".toUpperCase());
    }
    
    @:describe("String operations")
    @:test
    function testStringLowercase(): Void {
        assertEqual("world", "WORLD".toLowerCase());
    }
    
    @:describe("String operations")
    @:test
    function testStringLength(): Void {
        assertEqual(5, "hello".length);
    }
    
    // Tests for math operations - different describe block
    @:describe("Math operations")
    @:test
    function testAddition(): Void {
        assertEqual(4, 2 + 2);
    }
    
    @:describe("Math operations")
    @:test
    function testMultiplication(): Void {
        assertEqual(6, 2 * 3);
    }
    
    // Async test example
    @:async
    @:test
    function testAsyncOperation(): Void {
        // Simulate async operation
        Process.sleep(10);
        assertTrue(true, "Async test completed");
    }
    
    // Tagged test for conditional execution
    @:tag("slow")
    @:test
    function testSlowOperation(): Void {
        Process.sleep(100);
        assertTrue(true, "Slow test completed");
    }
    
    @:tag("integration")
    @:test  
    function testIntegration(): Void {
        // Integration test that might be excluded in unit test runs
        assertTrue(true, "Integration test passed");
    }
    
    // Test with multiple tags
    @:tag("slow")
    @:tag("external")
    @:test
    function testExternalService(): Void {
        // Test that depends on external service
        assertTrue(true, "External service test passed");
    }
}
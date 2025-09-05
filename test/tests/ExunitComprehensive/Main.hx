package;

import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;

/**
 * Comprehensive ExUnit test demonstrating all test features.
 * 
 * This test verifies:
 * - @:test annotation creates ExUnit test blocks
 * - @:setup annotation creates setup callbacks
 * - @:setupAll annotation creates setup_all callbacks  
 * - @:teardown annotation creates teardown callbacks
 * - Test assertions work correctly
 * - Setup/teardown lifecycle is preserved
 */
@:exunit
class Main extends TestCase {
    // Instance variables to track state
    var setupCalled: Bool = false;
    var setupAllCalled: Bool = false;
    var testCounter: Int = 0;
    
    /**
     * Setup all - runs once before all tests
     */
    @:setupAll
    function setupAll() {
        // Initialize shared test resources
        setupAllCalled = true;
        trace("Setup all called - initializing test suite");
        
        // Setup methods in ExUnit should just contain initialization logic
        // The framework handles the return value
    }
    
    /**
     * Setup - runs before each test
     */
    @:setup
    function setup() {
        // Initialize per-test state
        setupCalled = true;
        testCounter++;
        trace("Setup called for test #" + testCounter);
        
        // Setup methods in ExUnit should just contain initialization logic
        // The framework handles the return value
    }
    
    /**
     * Teardown - runs after each test
     */
    @:teardown
    function teardown() {
        // Clean up per-test resources
        trace("Teardown called after test #" + testCounter);
        
        // Reset state or clean up resources
        setupCalled = false;
    }
    
    /**
     * Test basic assertions
     */
    @:test
    function testBasicAssertions() {
        Assert.equals(1, 1, "Basic equality should work");
        Assert.notEquals(1, 2, "Inequality should work");
        Assert.isTrue(true, "True should be true");
        Assert.isFalse(false, "False should be false");
        Assert.isNull(null, "Null should be null");
        Assert.notNull("value", "Non-null should not be null");
    }
    
    /**
     * Test string operations
     */
    @:test
    function testStringOperations() {
        var str = "Hello, World!";
        
        Assert.equals(13, str.length, "String length should be correct");
        Assert.isTrue(str.indexOf("World") > 0, "Should contain 'World'");
        Assert.equals("HELLO, WORLD!", str.toUpperCase(), "Uppercase should work");
        Assert.equals("hello, world!", str.toLowerCase(), "Lowercase should work");
        
        // Test string splitting
        var parts = str.split(", ");
        Assert.equals(2, parts.length, "Should split into 2 parts");
        Assert.equals("Hello", parts[0], "First part should be 'Hello'");
        Assert.equals("World!", parts[1], "Second part should be 'World!'");
    }
    
    /**
     * Test array operations
     */
    @:test
    function testArrayOperations() {
        var arr = [1, 2, 3, 4, 5];
        
        Assert.equals(5, arr.length, "Array length should be 5");
        Assert.equals(1, arr[0], "First element should be 1");
        Assert.equals(5, arr[4], "Last element should be 5");
        
        // Test array methods
        var doubled = arr.map(x -> x * 2);
        Assert.equals(5, doubled.length, "Mapped array should have same length");
        Assert.equals(2, doubled[0], "First element should be doubled");
        Assert.equals(10, doubled[4], "Last element should be doubled");
        
        var evens = arr.filter(x -> x % 2 == 0);
        Assert.equals(2, evens.length, "Should have 2 even numbers");
        Assert.equals(2, evens[0], "First even should be 2");
        Assert.equals(4, evens[1], "Second even should be 4");
        
        var sum = arr.fold((a, b) -> a + b, 0);
        Assert.equals(15, sum, "Sum should be 15");
    }
    
    /**
     * Test pattern matching
     */
    @:test
    function testPatternMatching() {
        // Test with arrays
        var list = [1, 2, 3];
        
        if (list.length == 0) {
            Assert.fail("Should not be empty");
        } else {
            var head = list[0];
            var tail = list.slice(1);
            Assert.equals(1, head, "Head should be 1");
            Assert.equals(2, tail.length, "Tail should have 2 elements");
        }
        
        // Test with simple values
        var value = "test";
        switch (value) {
            case "test":
                Assert.isTrue(true, "Should match test");
            case "other":
                Assert.fail("Should not match other");
            default:
                Assert.fail("Should match one of the patterns");
        }
    }
    
    /**
     * Test exception handling
     */
    @:test
    function testExceptionHandling() {
        // Test that exceptions are caught properly
        var caught = false;
        
        try {
            throw "Test exception";
        } catch (e: String) {
            caught = true;
            Assert.equals("Test exception", e, "Exception message should match");
        }
        
        Assert.isTrue(caught, "Exception should have been caught");
        
        // Test that assertions can fail
        try {
            Assert.equals(1, 2, "This should fail");
            Assert.fail("Should not reach here");
        } catch (e: Dynamic) {
            // Expected - assertion failure throws
            Assert.isTrue(true, "Assertion failure was caught");
        }
    }
    
    /**
     * Test async operations (if supported)
     */
    @:test
    function testAsyncOperations() {
        // Simulate async operation with a promise/future pattern
        var completed = false;
        
        // In real tests, this would be actual async code
        // For now, we just test the pattern
        var asyncOp = function(callback: Bool -> Void) {
            // Simulate async completion
            callback(true);
        };
        
        asyncOp(function(result) {
            completed = result;
        });
        
        Assert.isTrue(completed, "Async operation should complete");
    }
    
    /**
     * Test custom assertions
     */
    @:test
    function testCustomAssertions() {
        // Create custom assertion helpers
        function assertBetween(value: Float, min: Float, max: Float, ?msg: String) {
            Assert.isTrue(value >= min && value <= max, 
                msg != null ? msg : 'Value $value should be between $min and $max');
        }
        
        function assertContains<T>(array: Array<T>, element: T, ?msg: String) {
            Assert.isTrue(array.indexOf(element) >= 0,
                msg != null ? msg : 'Array should contain element');
        }
        
        // Use custom assertions
        assertBetween(5, 1, 10, "5 should be between 1 and 10");
        assertContains([1, 2, 3], 2, "Array should contain 2");
        
        // Test that they fail correctly
        try {
            assertBetween(15, 1, 10);
            Assert.fail("Should have failed");
        } catch (e: Dynamic) {
            Assert.isTrue(true, "Custom assertion failed as expected");
        }
    }
    
    /**
     * Test data-driven tests
     */
    @:test
    function testDataDriven() {
        // Test multiple cases with same logic
        var testCases = [
            {input: 1, expected: 2},
            {input: 2, expected: 4},
            {input: 3, expected: 6},
            {input: 4, expected: 8},
            {input: 5, expected: 10}
        ];
        
        for (testCase in testCases) {
            var result = testCase.input * 2;
            Assert.equals(testCase.expected, result, 
                'Input ${testCase.input} should produce ${testCase.expected}');
        }
    }
    
    /**
     * Test mock and stub patterns
     */
    @:test
    function testMockingPatterns() {
        // Create a simple mock
        var mockCalls: Array<String> = [];
        
        var mockService = {
            getData: function(id: Int): String {
                mockCalls.push('getData($id)');
                return 'mock_data_$id';
            },
            saveData: function(id: Int, data: String): Bool {
                mockCalls.push('saveData($id, $data)');
                return true;
            }
        };
        
        // Use the mock
        var result = mockService.getData(123);
        Assert.equals("mock_data_123", result, "Mock should return expected data");
        
        var saved = mockService.saveData(456, "test");
        Assert.isTrue(saved, "Mock save should return true");
        
        // Verify mock was called correctly
        Assert.equals(2, mockCalls.length, "Mock should be called twice");
        Assert.equals("getData(123)", mockCalls[0], "First call should be getData");
        Assert.equals("saveData(456, test)", mockCalls[1], "Second call should be saveData");
    }
}
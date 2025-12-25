package;

import exunit.TestCase;
import exunit.Assert.*;
import haxe.ds.Option;
import haxe.functional.Result;

/**
 * Comprehensive ExUnit test showcasing ALL features:
 * - Basic assertions (assertEqual, assertTrue, assertFalse, etc.)
 * - Domain assertions (assertIsOk, assertIsError, assertIsSome, assertIsNone)
 * - Setup and teardown lifecycle methods
 * - SetupAll and teardownAll for module-level setup
 * - Describe blocks for grouping tests
 * - Async tests for parallel execution
 * - Test tags for selective execution
 * - Multiple test methods in one module
 * 
 * This test serves as both a feature showcase and a regression test
 * to ensure all ExUnit features continue to work correctly.
 */
@:exunit
@:async  // Module-level async for parallel test execution
class Main extends TestCase {
    
    // Instance variables for setup/teardown demonstration
    var testData: Array<String>;
    var counter: Int;
    
    // Module-level state (for setupAll)
    static var moduleState: String;
    
    /**
     * Module-level setup - runs once before all tests
     */
    @:setupAll
    function setupAll(context: Dynamic): Dynamic {
        moduleState = "initialized";
        // Return context that will be available to all tests
        return {
            sharedResource: "database_connection",
            testEnvironment: "test"
        };
    }
    
    /**
     * Test-level setup - runs before each test
     */
    @:setup
    function setup(context: Dynamic): Dynamic {
        testData = ["apple", "banana", "cherry"];
        counter = 0;
        
        // Can access setupAll context
        var sharedResource = context.sharedResource;
        
        return {
            testId: Math.random(),
            timestamp: Date.now()
        };
    }
    
    /**
     * Test-level teardown - runs after each test
     */
    @:teardown
    function teardown(context: Dynamic): Void {
        // Clean up test data
        testData = [];
        counter = 0;
    }
    
    /**
     * Module-level teardown - runs once after all tests
     */
    @:teardownAll
    function teardownAll(context: Dynamic): Void {
        moduleState = null;
        // Clean up shared resources
    }
    
    // ========== BASIC ASSERTIONS TESTS ==========
    
    @:describe("Basic Assertions")
    @:test
    function testAssertEqual(): Void {
        assertEqual(4, 2 + 2, "Basic addition should work");
        assertEqual("hello", "hel" + "lo", "String concatenation");
        assertEqual([1, 2, 3], [1, 2, 3], "Array equality");
    }
    
    @:describe("Basic Assertions")
    @:test
    function testAssertNotEqual(): Void {
        assertNotEqual(5, 2 + 2, "Should not be equal");
        assertNotEqual("hello", "world", "Different strings");
        assertNotEqual([1, 2], [1, 2, 3], "Different arrays");
    }
    
    @:describe("Basic Assertions")
    @:test
    function testBooleanAssertions(): Void {
        assertTrue(true, "True should be true");
        assertTrue(5 > 3, "5 is greater than 3");
        assertTrue(testData.length > 0, "Test data should not be empty");
        
        assertFalse(false, "False should be false");
        assertFalse(2 > 5, "2 is not greater than 5");
        assertFalse(testData.length == 0, "Test data is not empty");
    }
    
    @:describe("Basic Assertions")
    @:test
    function testNullAssertions(): Void {
        var nullValue: Null<String> = null;
        var nonNullValue: String = "exists";
        
        assertNull(nullValue, "Should be null");
        assertNotNull(nonNullValue, "Should not be null");
        
        // Test with optional values
        var optional: Null<Int> = Math.random() > 0.5 ? 42 : null;
        if (optional == null) {
            assertNull(optional, "Optional is null");
        } else {
            assertNotNull(optional, "Optional has value");
        }
    }
    
    // ========== DOMAIN ASSERTIONS TESTS ==========
    
    @:describe("Domain Assertions")
    @:test
    function testResultAssertions(): Void {
        // Result<T,E> compiles to {:ok, v} / {:error, e}
        var okResult: Result<String, String> = Ok("success");
        var errorResult: Result<String, String> = Error("error message");
        
        assertIsOk(okResult, "Should be Ok result");
        assertIsError(errorResult, "Should be Error result");
        
        // Test with actual Result-like operations
        var divisionResult = safeDivide(10, 2);
        assertIsOk(divisionResult, "Valid division should succeed");
        
        var invalidDivision = safeDivide(10, 0);
        assertIsError(invalidDivision, "Division by zero should fail");
    }
    
    @:describe("Domain Assertions")
    @:test
    function testOptionAssertions(): Void {
        // Option<T> compiles to {:some, v} / :none
        var someValue: Option<Int> = Some(42);
        var noneValue: Option<Int> = None;
        
        assertIsSome(someValue, "Should be Some");
        assertIsNone(noneValue, "Should be None");
        
        // Test with actual Option-like operations
        var found = findInArray(testData, "banana");
        assertIsSome(found, "Should find banana");
        
        var notFound = findInArray(testData, "dragonfruit");
        assertIsNone(notFound, "Should not find dragonfruit");
    }
    
    // ========== ASYNC TESTS ==========
    
    @:describe("Async Operations")
    @:test
    @:async
    function testAsyncOperation(): Void {
        // Simulate async operation
        var result = performAsyncCalculation();
        assertEqual(100, result, "Async calculation should return 100");
    }
    
    @:describe("Async Operations")
    @:test
    @:async
    function testParallelExecution(): Void {
        // These tests can run in parallel
        var operations = [1, 2, 3, 4, 5];
        var results = operations.map(n -> n * n);
        assertEqual([1, 4, 9, 16, 25], results, "Parallel operations should complete");
    }
    
    // ========== TAGGED TESTS ==========
    
    @:describe("Performance Tests")
    @:test
    @:tag("slow")
    function testSlowOperation(): Void {
        // This test is tagged as slow and can be excluded
        var result = 0;
        for (i in 0...1000) {
            result += i;
        }
        assertTrue(result > 0, "Slow operation should complete");
    }
    
    @:describe("Performance Tests")
    @:test
    @:tag("fast")
    function testFastOperation(): Void {
        // This test is tagged as fast
        var result = 2 + 2;
        assertEqual(4, result, "Fast operation");
    }
    
    @:describe("Integration Tests")
    @:test
    @:tag("integration")
    @:tag("database")
    function testDatabaseIntegration(): Void {
        // Multiple tags for categorization
        var connected = moduleState == "initialized";
        assertTrue(connected, "Should be connected to database");
    }
    
    // ========== SETUP/TEARDOWN VERIFICATION ==========
    
    @:describe("Lifecycle Methods")
    @:test
    function testSetupRan(): Void {
        // Verify setup populated test data
        assertEqual(3, testData.length, "Setup should populate test data");
        assertEqual("apple", testData[0], "First item should be apple");
        assertEqual(0, counter, "Counter should be initialized to 0");
    }
    
    @:describe("Lifecycle Methods")
    @:test
    function testModuleStateAvailable(): Void {
        // Verify setupAll ran and set module state
        assertEqual("initialized", moduleState, "Module state should be initialized");
    }
    
    // ========== ERROR HANDLING TESTS ==========
    
    @:describe("Error Handling")
    @:test
    function testExceptionHandling(): Void {
        try {
            throwError("Test error");
            fail("Should have thrown an error");
        } catch (e: Dynamic) {
            assertTrue(true, "Exception was caught");
        }
    }
    
    @:describe("Error Handling")
    @:test
    function testFailMethod(): Void {
        var condition = false;
        if (condition) {
            fail("This should not execute");
        } else {
            assertTrue(true, "Avoided failure");
        }
    }
    
    // ========== HELPER METHODS ==========
    
    private function safeDivide(a: Float, b: Float): Result<Float, String> {
        if (b == 0) {
            return Error("Division by zero");
        }
        return Ok(a / b);
    }
    
    private function findInArray(arr: Array<String>, item: String): Option<String> {
        for (element in arr) {
            if (element == item) {
                return Some(element);
            }
        }
        return None;
    }
    
    private function performAsyncCalculation(): Int {
        // Simulate async work
        var sum = 0;
        for (i in 1...11) {
            sum += i;
        }
        return sum * 2;  // Should be 110
    }
    
    private function throwError(message: String): Void {
        throw message;
    }
}

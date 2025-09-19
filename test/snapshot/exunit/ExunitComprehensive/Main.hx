package;

using ArrayTools;
import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;
import haxe.functional.Result;

/**
 * Comprehensive ExUnit test demonstrating all features.
 * 
 * This test validates:
 * - Multiple test methods with @:test annotation
 * - All assertion types (equals, isTrue, isFalse, isNull, isOk, isError)
 * - Setup and teardown lifecycle methods
 * - Test name transformation (camelCase to readable strings)
 * - Complex test scenarios with arrays and strings
 */
@:exunit
class Main extends TestCase {
    
    var testData: Array<Int>;
    var testString: String;
    
    /**
     * Setup all - runs once before all tests
     */
    @:setupAll
    function initTestSuite() {
        trace("Initializing test suite");
    }
    
    /**
     * Setup - runs before each test
     */
    @:setup
    function initTest() {
        testData = [1, 2, 3, 4, 5];
        testString = "Hello World";
        trace("Setting up test data");
    }
    
    /**
     * Teardown - runs after each test
     */
    @:teardown
    function cleanupTest() {
        testData = null;
        testString = null;
        trace("Cleaning up test data");
    }
    
    /**
     * Test basic equality assertions
     */
    @:test
    function testEqualityAssertions() {
        Assert.equals(2 + 2, 4, "Basic math should work");
        Assert.equals("Hello", "Hello", "String equality should work");
        Assert.equals(true, true, "Boolean equality should work");
        
        // Test with arrays
        var arr1 = [1, 2, 3];
        var arr2 = [1, 2, 3];
        Assert.equals(arr1.length, arr2.length, "Array lengths should be equal");
        Assert.equals(arr1[0], arr2[0], "First elements should be equal");
    }
    
    /**
     * Test boolean assertions
     */
    @:test
    function testBooleanAssertions() {
        Assert.isTrue(5 > 3, "5 should be greater than 3");
        Assert.isTrue("test".length == 4, "String length check should work");
        Assert.isTrue(testData != null, "Test data should be initialized");
        
        Assert.isFalse(2 > 5, "2 should not be greater than 5");
        Assert.isFalse("".length > 0, "Empty string should have zero length");
        Assert.isFalse(1 + 1 == 3, "1 + 1 should not equal 3");
    }
    
    /**
     * Test null assertions
     */
    @:test
    function testNullAssertions() {
        var nullVar: Dynamic = null;
        var notNullVar = "value";
        
        Assert.isNull(nullVar, "Null variable should be null");
        Assert.isNull(null, "Literal null should be null");
        
        // These would fail if uncommented:
        // Assert.isNull(notNullVar, "This should fail");
        // Assert.isNull(42, "This should also fail");
    }
    
    /**
     * Test string operations
     */
    @:test
    function testStringOperations() {
        Assert.equals(testString.length, 11, "String length should be 11");
        Assert.equals(testString.toUpperCase(), "HELLO WORLD", "Uppercase conversion should work");
        Assert.equals(testString.toLowerCase(), "hello world", "Lowercase conversion should work");
        
        Assert.isTrue(testString.indexOf("World") >= 0, "String should contain 'World'");
        Assert.isTrue(testString.charAt(0) == "H", "First character should be 'H'");
        
        var parts = testString.split(" ");
        Assert.equals(parts.length, 2, "Split should produce 2 parts");
        Assert.equals(parts[0], "Hello", "First part should be 'Hello'");
        Assert.equals(parts[1], "World", "Second part should be 'World'");
    }
    
    /**
     * Test array operations
     */
    @:test
    function testArrayOperations() {
        Assert.equals(testData.length, 5, "Array should have 5 elements");
        Assert.equals(testData[0], 1, "First element should be 1");
        Assert.equals(testData[testData.length - 1], 5, "Last element should be 5");
        
        // Test array methods
        var doubled = testData.map(function(x) return x * 2);
        Assert.equals(doubled[0], 2, "First doubled element should be 2");
        Assert.equals(doubled[4], 10, "Last doubled element should be 10");
        
        var filtered = testData.filter(function(x) return x > 2);
        Assert.equals(filtered.length, 3, "Filtered array should have 3 elements");
        Assert.equals(filtered[0], 3, "First filtered element should be 3");
        
        var sum = 0;
        for (n in testData) {
            sum += n;
        }
        Assert.equals(sum, 15, "Sum of elements should be 15");
    }
    
    /**
     * Test Result type assertions
     */
    @:test
    function testResultAssertions() {
        function successOperation(): Result<Int, String> {
            return Ok(42);
        }
        
        function failureOperation(): Result<Int, String> {
            return Error("Something went wrong");
        }
        
        var successResult = successOperation();
        Assert.isOk(successResult, "Success operation should return Ok");
        
        var failureResult = failureOperation();
        Assert.isError(failureResult, "Failure operation should return Error");
        
        // Test with pattern matching
        switch (successResult) {
            case Ok(value):
                Assert.equals(value, 42, "Success value should be 42");
            case Error(_):
                Assert.fail("Should not be an error");
        }
    }
    
    /**
     * Test complex scenarios
     */
    @:test
    function testComplexScenarios() {
        // Test with nested data structures
        var data = {
            name: "Test",
            values: [10, 20, 30],
            nested: {
                flag: true,
                count: 3
            }
        };
        
        Assert.equals(data.name, "Test", "Name field should be 'Test'");
        Assert.equals(data.values.length, 3, "Values array should have 3 elements");
        Assert.isTrue(data.nested.flag, "Nested flag should be true");
        Assert.equals(data.nested.count, 3, "Nested count should be 3");
        
        // Test with map operations
        var map = new Map<String, Int>();
        map.set("one", 1);
        map.set("two", 2);
        map.set("three", 3);
        
        Assert.isTrue(map.exists("one"), "Map should contain 'one'");
        Assert.equals(map.get("two"), 2, "Map value for 'two' should be 2");
        Assert.isFalse(map.exists("four"), "Map should not contain 'four'");
        
        var keys = [for (k in map.keys()) k];
        Assert.equals(keys.length, 3, "Map should have 3 keys");
    }
    
    /**
     * Test edge cases
     */
    @:test
    function testEdgeCases() {
        // Test with empty arrays
        var empty: Array<Int> = [];
        Assert.equals(empty.length, 0, "Empty array should have length 0");
        Assert.isTrue(empty.length == 0, "Empty array check should work");
        
        // Test with empty strings
        var emptyStr = "";
        Assert.equals(emptyStr.length, 0, "Empty string should have length 0");
        Assert.isFalse(emptyStr.length > 0, "Empty string should not have positive length");
        
        // Test with single element arrays
        var single = [42];
        Assert.equals(single.length, 1, "Single element array should have length 1");
        Assert.equals(single[0], 42, "Single element should be 42");
        
        // Test with boundary values
        Assert.isTrue(0 == 0, "Zero equality should work");
        Assert.isTrue(-1 < 0, "Negative comparison should work");
        Assert.equals(Math.POSITIVE_INFINITY > 1000000, true, "Infinity comparison should work");
    }
    
    /**
     * Test that demonstrates all assertion message features
     */
    @:test
    function testAssertionMessages() {
        // Each assertion can have a custom message
        Assert.equals(1, 1, "This message appears when assertion fails");
        Assert.isTrue(true, "Boolean assertion with message");
        Assert.isFalse(false, "False assertion with message");
        Assert.isNull(null, "Null check with message");
        
        // Messages support string interpolation
        var value = 42;
        Assert.equals(value, 42, 'Value should be ${value}');
        
        // Messages are optional
        Assert.equals(2, 2);
        Assert.isTrue(true);
        Assert.isFalse(false);
    }
}
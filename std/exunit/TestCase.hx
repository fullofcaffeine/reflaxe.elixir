package exunit;

/**
 * Base class for ExUnit test cases
 * 
 * Classes extending TestCase and marked with @:exunit will be compiled
 * into ExUnit test modules with proper use ExUnit.Case and test macros.
 * 
 * Supported annotations:
 * - @:exunit - Marks the class as an ExUnit test module
 * - @:test - Marks a method as a test case
 * - @:setup - Marks a method to run before each test
 * - @:setupAll - Marks a method to run once before all tests
 * - @:teardown - Marks a method to run after each test  
 * - @:teardownAll - Marks a method to run once after all tests
 * - @:describe("name") - Groups tests in a describe block
 * - @:async - Marks a test to run asynchronously
 * - @:tag("tag") - Tags a test for conditional execution
 */
@:autoBuild(reflaxe.elixir.helpers.ExUnitBuilder.build())
class TestCase {
    public function new() {}
}
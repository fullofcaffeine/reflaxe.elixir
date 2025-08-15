package haxe.test;

/**
 * Core ExUnit testing support for Haxe→Elixir compilation.
 * 
 * Provides a Haxe-friendly API for writing ExUnit tests that compile
 * to idiomatic Elixir test modules.
 * 
 * ## Usage
 * 
 * ```haxe
 * @:exunit
 * class MyTest extends TestCase {
 *     @:test
 *     function testSomething() {
 *         Assert.equals(2, 1 + 1);
 *     }
 * }
 * ```
 * 
 * Compiles to:
 * ```elixir
 * defmodule MyTest do
 *   use ExUnit.Case
 *   
 *   test "test something" do
 *     assert 1 + 1 == 2
 *   end
 * end
 * ```
 */

/**
 * Base class for ExUnit test cases.
 * 
 * Classes extending TestCase and marked with @:exunit will be compiled
 * to ExUnit test modules with proper setup and teardown handling.
 */
@:autoBuild(reflaxe.elixir.helpers.ExUnitBuilder.build())
class TestCase {
    /**
     * Setup method called before each test.
     * Override to provide test-specific setup.
     * 
     * @param context Test context (usually includes conn for web tests)
     * @return Modified context passed to test methods
     */
    public function setup(context: Dynamic): Dynamic {
        return context;
    }
    
    /**
     * Setup method called once before all tests in the module.
     * Override for expensive setup that can be shared across tests.
     * 
     * @param context Test context
     * @return Modified context
     */
    public function setupAll(context: Dynamic): Dynamic {
        return context;
    }
    
    /**
     * Teardown method called after each test.
     * Override to provide test-specific cleanup.
     * 
     * @param context Test context
     */
    public function teardown(context: Dynamic): Void {
        // Default: no teardown
    }
    
    /**
     * Teardown method called once after all tests in the module.
     * Override for cleanup of shared resources.
     * 
     * @param context Test context
     */
    public function teardownAll(context: Dynamic): Void {
        // Default: no teardown
    }
}

/**
 * Test configuration options that can be applied to individual tests
 * or entire test modules.
 */
typedef TestOptions = {
    /** Whether tests can run asynchronously (default: false) */
    ?async: Bool,
    
    /** Test timeout in milliseconds (default: 60000) */
    ?timeout: Int,
    
    /** Test tags for filtering (e.g., "slow", "integration") */
    ?tags: Array<String>,
    
    /** Test description (overrides method name) */
    ?description: String
}

/**
 * Marks a method as a test case.
 * 
 * Usage:
 * - @:test - Uses method name as test name
 * - @:test("custom description") - Uses custom description
 */
@:native("test")
extern class Test {}

/**
 * Groups related tests together in a describe block.
 * 
 * Usage:
 * ```haxe
 * @:describe("user operations")
 * class UserTests {
 *     @:test function canCreateUser() { ... }
 *     @:test function canDeleteUser() { ... }
 * }
 * ```
 */
@:native("describe")
extern class Describe {}
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
 *     @:test("addition is exact")
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
 *   test "addition is exact" do
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
 * `@:keepSub` keeps those named test modules under `-dce full`: unlike a
 * normal Haxe program, an ExUnit suite has no `main` entrypoint for Haxe's
 * dead-code eliminator to discover. `@:keep` keeps this root contract active.
 */
@:autoBuild(reflaxe.elixir.helpers.ExUnitBuilder.build())
@:keep
@:keepSub
class TestCase {}

/**
 * Test configuration options that can be applied to individual tests
 * or entire test modules.
 */
typedef TestOptions = {
	/** Whether tests can run asynchronously (default: false) */
	?async:Bool,

	/** Test timeout in milliseconds (default: 60000) */
	?timeout:Int,

	/** Test tags for filtering (e.g., "slow", "integration") */
	?tags:Array<String>,

	/** Test description (overrides method name) */
	?description:String
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

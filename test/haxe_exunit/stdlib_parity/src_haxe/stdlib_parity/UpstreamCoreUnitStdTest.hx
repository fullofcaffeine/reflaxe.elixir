package stdlib_parity;

import haxe.test.ExUnit.TestCase;
import stdlib_parity.upstream.UnitStdSupport;
import stdlib_parity.upstream.UpstreamUnitStdMacro;

/** Official Haxe core value specs compiled to ExUnit on BEAM. */
@:exunit
class UpstreamCoreUnitStdTest extends TestCase {
	@:describe("upstream Haxe unitstd: Std")
	@:test
	function testStd():Void {
		UpstreamUnitStdMacro.assertSpec("Std.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.EnumFlags")
	@:test
	function testHaxeEnumFlags():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/EnumFlags.unit.hx");
	}
}

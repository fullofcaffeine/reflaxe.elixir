package upstream_haxe_smoke;

import haxe.test.ExUnit.TestCase;
import stdlib_parity.upstream.UpstreamUnitStdMacro;

/** Runs one official `unitstd` specification in the installed-package smoke. */
@:exunit
class OfficialUnitStdTest extends TestCase {
	@:test("official unitstd Date.unit.hx")
	function testDate():Void {
		UpstreamUnitStdMacro.assertSpec("Date.unit.hx");
	}
}

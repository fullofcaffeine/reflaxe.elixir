package unit;

import haxe.test.ExUnit.TestCase;

/** Connects unchanged official Haxe unit tests to the local ExUnit API. */
@:autoBuild(upstream_haxe_smoke.OfficialTestBuilder.build())
@:keepSub
class Test extends TestCase {
	public function new() {}
}

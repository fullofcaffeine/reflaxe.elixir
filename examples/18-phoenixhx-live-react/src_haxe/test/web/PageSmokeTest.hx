package web;

import elixir.ElixirString;
import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;

/**
 * Server-side integration proof for the generated Haxe LiveReact boundary.
 *
 * The real browser test owns hydration and interaction. This faster ConnTest
 * proves Phoenix can render the page and the statically registered island.
 */
@:exunit
class PageSmokeTest extends TestCase {
	@:test
	public function testHomeRendersSignalConsoleBoundary():Void {
		var conn = ConnTest.get(ConnTest.build_conn(), "/");

		assertEqual(200, conn.status);
		assertTrue(ElixirString.contains(conn.resp_body, "Signal console"));
		assertTrue(ElixirString.contains(conn.resp_body, "SignalConsole"));
	}
}

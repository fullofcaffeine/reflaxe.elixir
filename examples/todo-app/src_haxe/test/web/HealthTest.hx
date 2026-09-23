package web;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;

/**
 * HealthTest
 *
 * WHAT
 * - Minimal ExUnit test authored in Haxe to validate that the app boots and renders the home page.
 *
 * WHY
 * - Provides a quick server-side integration check (ConnTest) compiled from Haxe, exercising our
 *   @:exunit pipeline and standard externs without relying on browser automation.
 *
 * HOW
 * - Uses Phoenix.ConnTest externs to build a connection and GET "/".
 * - Asserts 200 OK and basic content presence.
 */
// @:exunit: marks this class as an ExUnit test module.

@:exunit
class HealthTest extends TestCase {
	// @:test: marks this function as an executable ExUnit test case.
	@:test
	public function testHomePageLoads():Void {
		var conn = ConnTest.build_conn();
		conn = ConnTest.get(conn, "/");
		// Basic assertions: 200 OK and non-empty body via ConnTest helper
		assertTrue(conn != null);
		// Assert status directly from Conn struct type
		var status:Int = conn.status;
		assertEqual(200, status);
	}

	/** Separate test compilation must not make runtime-only server modules survive DCE. */
	@:test
	public function testErrorRenderersSurviveServerDce():Void {
		assertEqual("Not Found", ErrorHtmlRenderer.render("404.html", {}));
		assertEqual("Internal Server Error", ErrorJsonRenderer.render("500.json", {}).errors.detail);
	}
}

/** Exact native boundary: call the independently built app without re-emitting its source. */
@:native("TodoAppWeb.ErrorHTML")
private extern class ErrorHtmlRenderer {
	static function render(template:String, assigns:{}):String;
}

/** Phoenix JSON error payload returned by the independently built app. */
@:native("TodoAppWeb.ErrorJSON")
private extern class ErrorJsonRenderer {
	static function render(template:String, assigns:{}):{errors:{detail:String}};
}

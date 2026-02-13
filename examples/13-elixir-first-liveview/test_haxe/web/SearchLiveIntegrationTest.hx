package web;

import exunit.TestCase;
import exunit.Assert.*;
import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.types.Term;
import phoenix.test.ConnTest;
import phoenix.test.LiveView;
import phoenix.test.LiveViewTest;

/**
 * Integration tests for SearchLive behavior through Phoenix test helpers.
 */
// @:exunit: marks this class as an ExUnit test module.
@:exunit
class SearchLiveIntegrationTest extends TestCase {
	// @:test: marks this function as an executable ExUnit test case.
	@:test
	public function testHomePageRendersLiveBootstrapMarkup():Void {
		var conn = ConnTest.build_conn();
		conn = ConnTest.get(conn, "/");

		assertEqual(200, conn.status);
		assertTrue(conn.resp_body != null);
		assertTrue(ElixirString.contains(conn.resp_body, "meta name=\"csrf-token\""));
		assertTrue(ElixirString.contains(conn.resp_body, "/assets/phoenix_app.js"));
	}

	@:test
	public function testSearchFiltersResultsWithRenderChange():Void {
		var conn = ConnTest.build_conn();
		var liveResult = LiveViewTest.live(conn, "/");
		var liveView:LiveView = LiveViewTest.view(liveResult);
		var searchForm:Term = LiveViewTest.element(liveView, "form[phx-change='search']");

		var params:Term = ElixirMap.put(ElixirMap.new_(), "query", "phoenix");
		LiveViewTest.render_change(searchForm, params);

		var html = LiveViewTest.render(liveView);
		assertTrue(ElixirString.contains(html, "1 result(s)"));
		assertTrue(ElixirString.contains(html, "Phoenix LiveView"));
		assertFalse(ElixirString.contains(html, "GenServer"));
	}
}

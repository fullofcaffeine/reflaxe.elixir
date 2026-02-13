package web;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;
import elixir.types.Term;

// @:exunit: marks this class as an ExUnit test module.
@:exunit
class TodoLiveCrudTest extends TestCase {
	// @:test: marks this function as an executable ExUnit test case.
	@:test
	public function testMountTodos():Void {
		var conn = ConnTest.build_conn();
		var lvTuple:Term = LiveViewTest.live(conn, "/todos");
		var lv:LiveView = LiveViewTest.view(lvTuple);
		assertTrue(lv != null);
		var html:String = LiveViewTest.render(lv);
		assertTrue(html != null);
	}
	// Keep additional CRUD steps in Playwright E2E for now; minimal LV mount here
}

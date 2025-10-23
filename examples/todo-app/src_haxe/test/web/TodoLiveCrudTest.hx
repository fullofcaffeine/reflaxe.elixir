package web;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

@:exunit
class TodoLiveCrudTest extends TestCase {
    @:test
    public function testMountTodos(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = untyped __elixir__("case Phoenix.LiveViewTest.live({0}, {1}) do {:ok, v, _html} -> v end", conn, "/todos");
        assertTrue(lv != null);
        var html: String = untyped __elixir__('Phoenix.LiveViewTest.render({0})', lv);
        assertTrue(html != null);
    }

    // Keep additional CRUD steps in Playwright E2E for now; minimal LV mount here
}

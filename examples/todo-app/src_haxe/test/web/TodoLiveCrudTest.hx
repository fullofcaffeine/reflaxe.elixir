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
        var lvTuple = LiveViewTest.live(conn, "/todos");
        var lv: LiveView = viewHandle(lvTuple);
        assertTrue(lv != null);
        var html: String = LiveViewTest.render(lv);
        assertTrue(html != null);
    }

    // Keep additional CRUD steps in Playwright E2E for now; minimal LV mount here

    private static inline function viewHandle(lvTuple: Dynamic): LiveView {
        return untyped __elixir__('elem({0}, 1)', lvTuple);
    }
}

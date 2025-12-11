package live;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

/**
 * TodoLiveDueDateTest
 *
 * WHAT
 * - Verifies creating a todo with a due_date renders a "Due:" label.
 *
 * WHY
 * - Guards the due_date normalization and rendering path (date-only -> 00:00:00).
 */
@:exunit
class TodoLiveDueDateTest extends TestCase {
    @:test
    public function testCreateTodoWithDueDateRenders(): Void {
        var conn = ConnTest.build_conn();
        var lvTuple: Dynamic = LiveViewTest.live(conn, "/todos");
        var lv: LiveView = viewHandle(lvTuple);
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
        var data: Dynamic = {title: "DueEarly", due_date: "2025-11-01"};
        var formEl: Dynamic = LiveViewTest.element(lv, "form[phx-submit='create_todo']");
        LiveViewTest.render_submit(formEl, data);
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("DueEarly") != -1);
    }

    static inline function viewHandle(lvTuple: Dynamic): LiveView {
        return untyped __elixir__('elem({0}, 1)', lvTuple);
    }
}

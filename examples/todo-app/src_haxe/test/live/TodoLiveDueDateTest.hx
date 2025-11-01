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
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "DueEarly");
        data.set("due_date", "2025-11-01");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Due:") != -1);
    }
}

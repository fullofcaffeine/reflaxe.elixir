package test.live;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

/**
 * TodoLiveClassTest
 *
 * WHAT
 * - Verifies that priority and completion state produce the expected card CSS classes
 *   in the rendered LiveView (indirectly exercising the typed helper).
 *
 * WHY
 * - Ensures our HXX → HEEx pipeline and typed helper produce idiomatic classes without
 *   relying on private helper visibility.
 */
@:exunit
class TodoLiveClassTest extends TestCase {
  @:test
  public function testHighPriorityClass(): Void {
    var conn = ConnTest.build_conn();
    var lv: LiveView = viewHandle(LiveViewTest.live(conn, "/todos"));
    // Open form and create a High priority todo
    LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
    var data: Dynamic = {title: "Priority High", priority: "high"};
    LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
    var html = LiveViewTest.render(lv);
    assertTrue(html.indexOf("border-red-500") != -1);
  }

  @:test
  public function testCompletedOpacity(): Void {
    var conn = ConnTest.build_conn();
    var lv: LiveView = viewHandle(LiveViewTest.live(conn, "/todos"));
    // Create and complete a todo
    LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
    var data: Dynamic = {title: "Done Item"};
    LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
    LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_todo']"));
    var html = LiveViewTest.render(lv);
    assertTrue(html.indexOf("opacity-60") != -1);
  }

  static inline function viewHandle(lvTuple: Dynamic): LiveView {
    return untyped __elixir__('elem({0}, 1)', lvTuple);
  }
}

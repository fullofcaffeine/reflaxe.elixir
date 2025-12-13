package test.live;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

/**
 * TodoLiveCrudTest
 *
 * Server-side LiveView integration tests authored in Haxe, compiled to ExUnit.
 */
@:exunit
class TodoLiveCrudTest extends TestCase {
    @:test
    public function testMountTodos(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = viewHandle(LiveViewTest.live(conn, "/todos"));
        assertTrue(lv != null);
        var html = LiveViewTest.render(lv);
        assertTrue(html != null);
    }

    @:test
    public function testCreateTodoViaLiveView(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = viewHandle(LiveViewTest.live(conn, "/todos"));
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
        var data: Dynamic = {title: "LV created"};
        LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("LV created") != -1);
    }

    @:test
    public function testToggleTodoStatus(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = viewHandle(LiveViewTest.live(conn, "/todos"));
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
        var data: Dynamic = {title: "Toggle Me"};
        LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_todo']"));
        var html = LiveViewTest.render(lv);
        var hasLine = html.indexOf("line-through") != -1;
        var hasOpacity = html.indexOf("opacity-60") != -1;
        assertTrue(hasLine || hasOpacity);
    }

    @:test
    public function testEditTodo(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = viewHandle(LiveViewTest.live(conn, "/todos"));
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
        var data: Dynamic = {title: "Edit Me"};
        LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='edit_todo']"));
        var newData: Dynamic = {title: "Edited Title"};
        LiveViewTest.render_submit(lv, "form[phx-submit='save_todo']", newData);
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Edited Title") != -1);
    }

    @:test
    public function testDeleteTodo(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = viewHandle(LiveViewTest.live(conn, "/todos"));
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
        var data: Dynamic = {title: "Delete Me"};
        LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='delete_todo']"));
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Delete Me") == -1);
    }

    @:test
    public function testFilters(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = viewHandle(LiveViewTest.live(conn, "/todos"));
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
        LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", {title: "Active One"});
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_form']"));
        LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", {title: "Completed One"});
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='toggle_todo']"));
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='filter_todos'][phx-value-filter='completed']"));
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Active One") == -1);
        assertTrue(html.indexOf("Completed One") != -1);
        LiveViewTest.render_click(LiveViewTest.element(lv, "button[phx-click='filter_todos'][phx-value-filter='active']"));
        html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Completed One") == -1);
        assertTrue(html.indexOf("Active One") != -1);
    }

    static inline function viewHandle(lvTuple: Dynamic): LiveView {
        return cast elixir.Tuple.elem(lvTuple, 1);
    }
}

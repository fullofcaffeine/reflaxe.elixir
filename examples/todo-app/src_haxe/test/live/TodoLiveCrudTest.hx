package test.live;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

/**
 * TodoLiveCrudTest
 *
 * WHAT
 * - Server-side LiveView integration tests authored in Haxe, compiled to ExUnit.
 *
 * WHY
 * - Provides fast, deterministic tests of CRUD + filters without a browser.
 * - Complements Playwright smokes (Testing Trophy).
 *
 * HOW
 * - Uses Phoenix.ConnTest and Phoenix.LiveViewTest externs.
 */
@:exunit
class TodoLiveCrudTest extends TestCase {
    @:test
    public function testMountTodos(): Void {
        var conn = ConnTest.build_conn();
        // LiveViewTest.live(conn, "/todos") should return a LiveView handle
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        assertTrue(lv != null);
        // Basic render contains page title
        var html = LiveViewTest.render(lv);
        assertTrue(html != null);
    }

    @:test
    public function testCreateTodoViaLiveView(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Toggle form
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        // Submit minimal form (title only)
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "LV created");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        // Render and assert content contains the title
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("LV created") != -1);
    }

    @:test
    public function testToggleTodoStatus(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Create a fresh todo
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "Toggle Me");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        // Click the first toggle button
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_todo']");
        var html = LiveViewTest.render(lv);
        // Completed item should have line-through or container opacity
        var hasLine = html.indexOf("line-through") != -1;
        var hasOpacity = html.indexOf("opacity-60") != -1;
        assertTrue(hasLine || hasOpacity);
    }

    @:test
    public function testEditTodo(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Create
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "Edit Me");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        // Click edit
        lv = LiveViewTest.render_click(lv, "button[phx-click='edit_todo']");
        // Fill and save
        var newData: Map<String, Dynamic> = new Map();
        newData.set("title", "Edited Title");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='save_todo']", newData);
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Edited Title") != -1);
    }

    @:test
    public function testDeleteTodo(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Create
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "Delete Me");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        // Delete
        lv = LiveViewTest.render_click(lv, "button[phx-click='delete_todo']");
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Delete Me") == -1);
    }

    @:test
    public function testFilters(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Create Active
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var a: Map<String, Dynamic> = new Map();
        a.set("title", "Active One");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", a);
        // Create another and toggle complete
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var c: Map<String, Dynamic> = new Map();
        c.set("title", "Completed One");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", c);
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_todo']");
        // Filter Completed
        lv = LiveViewTest.render_click(lv, "button[phx-click='filter_todos'][phx-value-filter='completed']");
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Active One") == -1);
        assertTrue(html.indexOf("Completed One") != -1);
        // Filter Active
        lv = LiveViewTest.render_click(lv, "button[phx-click='filter_todos'][phx-value-filter='active']");
        html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Completed One") == -1);
        assertTrue(html.indexOf("Active One") != -1);
    }
}

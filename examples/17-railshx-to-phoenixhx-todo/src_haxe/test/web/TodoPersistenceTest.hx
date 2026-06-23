package web;

import elixir.types.Term;
import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;
import phoenix.test.LiveView;
import phoenix.test.LiveViewTest;

@:exunit
class TodoPersistenceTest extends TestCase {
	@:test
	public function testSignedInUserCanCreatePersistedTodo():Void {
		var runId = Std.string(Std.random(1000000000));
		var title = 'Persisted PhoenixHx todo ${runId}';

		var conn = ConnTest.build_conn();
		conn = ConnTest.post(conn, "/auth/demo", {name: "Persisted User", email: 'persisted-${runId}@example.test'});

		var lvTuple:Term = LiveViewTest.live(conn, "/todos");
		var lv:LiveView = LiveViewTest.view(lvTuple);
		LiveViewTest.render_submit(LiveViewTest.element(lv, "form[phx-submit='create_todo']"), {title: title, notes: "Ecto-backed"});

		var html = LiveViewTest.render(lv);
		assertTrue(html.indexOf(title) != -1);
		assertTrue(html.indexOf("Task added through Ecto") != -1);
	}
}

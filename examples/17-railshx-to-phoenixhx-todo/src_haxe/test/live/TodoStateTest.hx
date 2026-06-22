package live;

import exunit.Assert.*;
import exunit.TestCase;
import phoenix_hx_todo_hx.live.TodoState;

@:exunit
class TodoStateTest extends TestCase {
	@:test
	public function testCreateAddsNewestTaskFirst():Void {
		var todos = TodoState.seed("Guest Workspace");
		var updated = TodoState.create(todos, 9, "  Port the board  ", " Keep the UX familiar ", "Guest Workspace");

		assertEqual(4, updated.length);
		assertEqual("Port the board", updated[0].title);
		assertEqual("Keep the UX familiar", updated[0].notes);
		assertFalse(updated[0].completed);
	}

	@:test
	public function testToggleAndDeleteUpdateState():Void {
		var todos = TodoState.seed("Guest Workspace");
		var toggled = TodoState.toggle(todos, 1);
		assertTrue(toggled[0].completed);

		var deleted = TodoState.deleteById(toggled, 1);
		assertEqual(2, deleted.length);
		assertEqual(0, deleted.filter(todo -> todo.id == 1).length);
	}

	@:test
	public function testStatsSeparateOpenAndCompleted():Void {
		var stats = TodoState.stats(TodoState.seed("Guest Workspace"));
		assertEqual(2, stats.open_count);
		assertEqual(1, stats.completed_count);
		assertEqual(5, stats.typed_column_count);
	}
}

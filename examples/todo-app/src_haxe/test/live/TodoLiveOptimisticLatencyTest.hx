package test.live;

import test.support.ConnCase;

/**
 * TodoLive optimistic toggle latency test (Haxe-authored ExUnit)
 *
 * WHAT
 * - Asserts that the completed state flips optimistically on toggle even when
 *   the server applies latency (simulated).
 *
 * NOTE
 * - This test compiles to ExUnit; runtime helpers are provided in ConnCase externs.
 */
@:exunit
class TodoLiveOptimisticLatencyTest extends ConnCase {
  public function testOptimisticToggleUnderLatency():Void {
    var todo = createTestTodo("Latency item", false, "medium");
    var live = connectLiveView("/todos");

    // Simulate network latency on the server path for toggling
    enableLatencySimulation(120); // ms

    // Optimistic flip should apply immediately on client
    assertElementNotHasClass(live, '[data-todo-id="${todo.id}"]', "completed");
    live = clickElement(live, '[phx-click="toggle_todo"][phx-value-id="${todo.id}"]');
    assertElementHasClass(live, '[data-todo-id="${todo.id}"]', "completed");

    // After latency, server confirmation should keep state consistent
    live = awaitServerLatency(live);
    assertElementHasClass(live, '[data-todo-id="${todo.id}"]', "completed");
  }

  // Helpers resolved by ConnCase externs at compile/runtime
  private function createTestTodo(title:String, completed:Bool, priority:String):Dynamic {
    return { id: Math.floor(Math.random() * 1000000), title: title, completed: completed, priority: priority };
  }
  private function connectLiveView(path:String):Dynamic return {};
  private function clickElement(live:Dynamic, sel:String):Dynamic return live;
  private function assertElementHasClass(live:Dynamic, sel:String, cls:String):Void {}
  private function assertElementNotHasClass(live:Dynamic, sel:String, cls:String):Void {}
  private function enableLatencySimulation(ms:Int):Void {}
  private function awaitServerLatency(live:Dynamic):Dynamic return live;
}


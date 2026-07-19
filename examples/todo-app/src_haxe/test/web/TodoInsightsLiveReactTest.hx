package web;

import elixir.ElixirMap;
import elixir.types.Term;
import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;
import phoenix.test.LiveView;
import phoenix.test.LiveViewMountResult;
import phoenix.test.LiveViewTest;
import shared.liveview.TodoInsightsEvents.TodoInsightsEvents;

/**
 * Server-side contract tests for the optional TodoInsights React island.
 *
 * These tests never run React. They prove the Phoenix half of the boundary:
 * the Haxe-authored HEEx keeps a useful native LiveView summary, and the same
 * typed event name used by the Haxe/Genes component reaches the LiveView
 * dispatcher safely. Browser mounting remains the responsibility of the thin
 * Playwright lane.
 */
@:exunit
class TodoInsightsLiveReactTest extends TestCase {
	@:test
	public function testRendersUsefulNativeFallbackAroundIsland():Void {
		var liveView = mountTodos();

		assertTrue(LiveViewTest.has_element(liveView, "[data-testid='todo-insights-shell']"));
		assertTrue(LiveViewTest.has_element(liveView, "[data-testid='todo-insights-native-fallback']", "LiveView summary:"));
	}

	@:test
	public function testTypedIslandEventUpdatesNativeFilterState():Void {
		var liveView = mountTodos();

		LiveViewTest.render_hook(liveView, TodoInsightsEvents.SetFilterEvent, filterPayload("completed"));

		assertTrue(LiveViewTest.has_element(liveView, "button[phx-click='filter_todos'][phx-value-filter='completed'].todo-filter-btn-active"));
	}

	@:test
	public function testMalformedKnownIslandPayloadIsConsumedSafely():Void {
		var liveView = mountTodos();

		var html = LiveViewTest.render_hook(liveView, TodoInsightsEvents.SetFilterEvent, ElixirMap.new_());

		assertTrue(html.indexOf("Todo signal") != -1);
		assertTrue(LiveViewTest.has_element(liveView, "button[phx-click='filter_todos'][phx-value-filter='all'].todo-filter-btn-active"));
	}

	static function mountTodos():LiveView {
		var result:LiveViewMountResult = LiveViewTest.live(ConnTest.build_conn(), "/todos");
		return result.view();
	}

	static function filterPayload(filter:String):Term {
		return ElixirMap.put(ElixirMap.new_(), "filter", filter);
	}
}

package web;

import elixir.ElixirString;
import elixir.ElixirMap;
import elixir.types.Term;
import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.LiveView;
import phoenix.test.LiveViewMountResult;
import phoenix.test.LiveViewTest;
import phoenix.test.ConnTest;
import phoenixhx_live_react_hx.live.SignalConsoleEvents.SignalConsoleEvents;

/**
 * Server-side integration proof for the generated Haxe LiveReact boundary.
 *
 * The real browser test owns hydration and interaction. This faster
 * LiveViewTest proves Phoenix can render the island and dispatch its typed event.
 */
@:exunit
class PageSmokeTest extends TestCase {
	@:test
	public function testHomeRendersSignalConsoleBoundaryAndDispatchesTypedPulse():Void {
		var result:LiveViewMountResult = LiveViewTest.live(ConnTest.build_conn(), "/");
		var liveView:LiveView = result.view();
		var initialHtml = LiveViewTest.render(liveView);

		assertTrue(ElixirString.contains(initialHtml, "Signal console"));
		assertTrue(ElixirString.contains(initialHtml, "SignalConsole"));
		assertTrue(ElixirString.contains(initialHtml, "Native LiveView fallback"));

		var payload:Term = ElixirMap.put(ElixirMap.new_(), "channel", "BETA");
		var updatedHtml = LiveViewTest.render_hook(liveView, SignalConsoleEvents.PulseEvent, payload);

		assertTrue(ElixirString.contains(updatedHtml, "Server received BETA pulse 01."));
	}
}

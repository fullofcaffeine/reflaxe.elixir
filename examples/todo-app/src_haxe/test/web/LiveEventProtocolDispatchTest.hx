package web;

import elixir.ElixirMap;
import elixir.types.Term;
import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.Conn;
import phoenix.test.ConnTest;
import phoenix.test.LiveView;
import phoenix.test.LiveViewMountResult;
import phoenix.test.LiveViewTest;
import shared.liveview.HookEvents;

/**
 * LiveEventProtocolDispatchTest
 *
 * WHAT
 * - Exercises todo-app LiveView hook events through the generated shared
 *   `HookEvents` companion and the dispatcher compiled into the Phoenix app.
 *
 * WHY
 * - Guards the PhoenixHx Live Event Protocol contract at the app boundary:
 *   generated event constants, generated server dispatch, malformed known
 *   payload consumption, and ordinary unknown-event fallback.
 */
@:exunit
class LiveEventProtocolDispatchTest extends TestCase {
	@:test
	public function testClipboardCopiedHookEventSetsFlash():Void {
		var lv = mountProfile("hook_flash@example.com");
		var message = "Typed hook dispatch worked.";
		var html = LiveViewTest.render_hook(lv, HookEvents.ClipboardCopiedEvent, payloadWithMessage(message));

		assertTrue(html.indexOf(message) != -1);
	}

	@:test
	public function testPingHookEventNoOps():Void {
		var lv = mountProfile("hook_ping@example.com");
		var html = LiveViewTest.render_hook(lv, HookEvents.HookPingEvent, ElixirMap.new_());

		assertTrue(html.indexOf("Profile") != -1);
	}

	@:test
	public function testMalformedKnownHookPayloadIsConsumedSafely():Void {
		var lv = mountProfile("hook_invalid@example.com");
		var message = "This invalid hook payload should not show.";
		var html = LiveViewTest.render_hook(lv, HookEvents.ClipboardCopiedEvent, ElixirMap.new_());

		assertTrue(html.indexOf("Profile") != -1);
		assertTrue(html.indexOf(message) == -1);
	}

	@:test
	public function testUnknownHookEventFallsThroughSafely():Void {
		var lv = mountProfile("hook_unknown@example.com");
		var html = LiveViewTest.render_hook(lv, "unknown_live_event_protocol_test", ElixirMap.new_());

		assertTrue(html.indexOf("Profile") != -1);
	}

	static function mountProfile(email:String):LiveView {
		var conn:Conn = ConnTest.build_conn();
		conn = ConnTest.post(conn, "/auth/login", {name: "Hook Tester", email: email});
		assertEqual(302, conn.status);

		var result:LiveViewMountResult = LiveViewTest.live(conn, "/profile");
		return result.view();
	}

	static function payloadWithMessage(message:String):Term {
		var payload = ElixirMap.new_();
		payload = ElixirMap.put(payload, "message", message);
		return payload;
	}
}

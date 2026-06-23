package web;

import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;
import phoenix.test.LiveView;
import phoenix.test.LiveViewMountResult;
import phoenix.test.LiveViewTest;

@:exunit
class ChatPanelTest extends TestCase {
	@:test
	public function testSignedInUserCanPostPersistedRoomNote():Void {
		var runId = Std.string(Std.random(1000000000));
		var body = 'Phoenix PubSub room note ${runId}';

		var conn = ConnTest.build_conn();
		conn = ConnTest.post(conn, "/auth/demo", {name: "Chat User", email: 'chat-${runId}@example.test'});

		var mounted:LiveViewMountResult = LiveViewTest.live(conn, "/todos");
		var lv:LiveView = mounted.view();
		LiveViewTest.render_submit(LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), {body: body});

		var html = LiveViewTest.render(lv);
		assertTrue(html.indexOf(body) != -1);
		assertTrue(html.indexOf("Room note persisted through Ecto") != -1);
	}

	@:test
	public function testShipRoomShowsSixMostRecentNotes():Void {
		var runId = Std.string(Std.random(1000000000));

		var conn = ConnTest.build_conn();
		conn = ConnTest.post(conn, "/auth/demo", {name: "Recent Chat User", email: 'recent-chat-${runId}@example.test'});

		var mounted:LiveViewMountResult = LiveViewTest.live(conn, "/todos");
		var lv:LiveView = mounted.view();
		for (index in 0...7) {
			LiveViewTest.render_submit(LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), {body: 'Recent note ${runId}-${index}'});
		}

		var html = LiveViewTest.render(lv);
		assertTrue(html.indexOf('Recent note ${runId}-6') != -1);
		assertTrue(html.indexOf('Recent note ${runId}-1') != -1);
		assertTrue(html.indexOf('Recent note ${runId}-0') == -1);
	}
}

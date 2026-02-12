package live;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix_chat_hx.live.AppLiveTypes.ChatMessage;
import phoenix_chat_hx.live.ChatState;

@:exunit
class ChatStateTest extends TestCase {
	@:test
	public function appendMessageReturnsNewArrayAndAppends():Void {
		var original:ChatMessage = {
			id: 1,
			user_id: "u1",
			user_name: "alice",
			body: "hello",
			at: 1.0,
			row_class: "msg"
		};

		var next:ChatMessage = {
			id: 2,
			user_id: "u2",
			user_name: "bob",
			body: "world",
			at: 2.0,
			row_class: "msg"
		};

		var current = [original];
		var updated = ChatState.appendMessage(current, next);

		assertEqual(1, current.length);
		assertEqual(2, updated.length);
		assertEqual("world", updated[1].body);
	}
}

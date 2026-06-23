package phoenix_hx_todo_hx.data;

import ecto.Changeset;

typedef ChatMessageParams = {
	?body:String,
	?userId:Int
}

/**
 * Chat message schema for the optional RailsHx panel port.
 *
 * WHAT
 * - Stores room notes with server-owned user attribution.
 *
 * WHY
 * - The RailsHx sample uses ActiveRecord plus Turbo Streams. This PhoenixHx
 *   slice keeps persistence in Ecto and realtime refresh in Phoenix.PubSub.
 */
@:native("PhoenixHxTodo.ChatMessage")
@:schema("chat_messages")
@:timestamps
@:changeset(["body", "userId"], ["body", "userId"])
class ChatMessage {
	@:field @:primary_key public var id:Int;
	@:field public var body:String;
	@:field public var userId:Int;

	public function new() {}
}

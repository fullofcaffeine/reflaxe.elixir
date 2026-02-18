package phoenix_chat_hx.live;

import phoenix_chat_hx.live.AppLiveTypes.ChatMessage;

/**
 * Pure helpers for chat state updates.
 */
class ChatState {
	public static function appendMessage(messages:Array<ChatMessage>, message:ChatMessage):Array<ChatMessage> {
		var next = messages.copy();
		next.push(message);
		return next;
	}
}

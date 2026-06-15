package shared.chat;

import shared.chat.MessageRules.ChatMessage;
import shared.chat.MessageRules.MessageDecision;

class Transcript {
	public static function empty():Array<ChatMessage> {
		return [];
	}

	public static function add(history:Array<ChatMessage>, author:String, body:String):Array<ChatMessage> {
		var next = history.copy();

		switch MessageRules.validate(author, body) {
			case Accepted(message):
				next.push(message);
			case Rejected(_):
		}

		return next;
	}

	public static function render(history:Array<ChatMessage>):Array<String> {
		var lines = [];

		for (message in history) {
			lines.push(MessageRules.format(message));
		}

		return lines;
	}
}

package client;

import shared.chat.Transcript;

class PortableChatClient {
	public static function main():Void {
		var history = Transcript.empty();
		history = Transcript.add(history, "Ada", " Hello from the browser side. ");
		history = Transcript.add(history, "Grace", "The same Haxe rules compiled to JS.");

		for (line in Transcript.render(history)) {
			trace(line);
		}
	}
}

package server;

import shared.chat.Transcript;

class PortableChatServer {
	public static function sampleLines():Array<String> {
		var history = Transcript.empty();
		history = Transcript.add(history, "Ada", " Hello from the BEAM side. ");
		history = Transcript.add(history, "Grace", "The same Haxe rules compiled to Elixir.");
		history = Transcript.add(history, "", "This message is rejected.");

		return Transcript.render(history);
	}

	public static function sampleSummary():String {
		return sampleLines().join(" | ");
	}
}

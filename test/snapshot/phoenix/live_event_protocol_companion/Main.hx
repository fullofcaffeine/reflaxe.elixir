import elixir.types.Term;
import elixir.ElixirMap;
import elixir.Kernel;
import phoenix.channels.EncodedEvent;
import phoenix.channels.Payload;
import phoenix.live_view.LiveEventProtocolCompanion;

@:liveEventProtocol("ProfileHookEvents")
enum ProfileHookEvent {
	@:event("clipboard_copied")
	ClipboardCopied(message:String);

	Ping;

	TodoSelected(todoId:Int, fromHook:Bool);
}

typedef ProfileHookEvents = LiveEventProtocolCompanion<ProfileHookEvent>;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function main():Void {
		assertThat(ProfileHookEvents.ClipboardCopiedEvent == "clipboard_copied", "clipboard event constant failed");
		assertThat(ProfileHookEvents.PingEvent == "ping", "ping event constant failed");
		assertThat(ProfileHookEvents.TodoSelectedEvent == "todo_selected", "todo event constant failed");

		var copied:EncodedEvent = ProfileHookEvents.encode(ClipboardCopied("Copied."));
		assertThat(copied.event == "clipboard_copied", "clipboard encode event failed");
		var copiedMessage:Term = ElixirMap.get(copied.payload, "message");
		assertThat(Kernel.isBinary(copiedMessage) && Kernel.toString(copiedMessage) == "Copied.", "clipboard encode payload failed");

		var copiedDecoded = ProfileHookEvents.decode("clipboard_copied", copied.payload);
		assertThat(copiedDecoded != null, "clipboard decode failed");

		var selectedPayload:Term = ElixirMap.new_();
		selectedPayload = ElixirMap.put(selectedPayload, "todo_id", 42);
		selectedPayload = ElixirMap.put(selectedPayload, "from_hook", true);

		var selectedDecoded = ProfileHookEvents.decode("todo_selected", selectedPayload);
		assertThat(selectedDecoded != null, "todo decode failed");

		var invalidPayload:Payload = ElixirMap.new_();
		assertThat(ProfileHookEvents.decode("clipboard_copied", invalidPayload) == null, "invalid payload should fail");
		assertThat(ProfileHookEvents.decode("unknown", invalidPayload) == null, "unknown event should fail");
	}
}

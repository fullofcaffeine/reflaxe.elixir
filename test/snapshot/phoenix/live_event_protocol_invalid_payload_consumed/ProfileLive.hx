import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;

typedef ProfileAssigns = {
	var flash_message:String;
}

@:liveEventProtocol("ProfileHookEvents")
enum ProfileHookEvent {
	@:event("clipboard_copied")
	ClipboardCopied(message:String);
}

@:liveview
@:liveEvents(ProfileHookEvent, "dispatchProfileHookEvent")
class ProfileLive {
	public static function handleEvent(event:String, params:Term, socket:Socket<ProfileAssigns>):HandleEventResult<ProfileAssigns> {
		var hookResult = dispatchProfileHookEvent(event, params, socket);
		if (hookResult != null) {
			return hookResult;
		}

		return switch (event) {
			case "clipboard_copied":
				NoReply(LiveView.assign(socket, "flash_message", "fallback should not handle malformed protocol payloads"));
			case _:
				NoReply(socket);
		}
	}

	static function handleClipboardCopied(message:String, socket:Socket<ProfileAssigns>):HandleEventResult<ProfileAssigns> {
		return NoReply(LiveView.assign(socket, "flash_message", message));
	}
}

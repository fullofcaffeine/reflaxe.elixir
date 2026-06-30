import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;

typedef ProfileAssigns = {
	var flash_message:String;
}

@:liveEventProtocol
enum ProfileHookEvent {
	@:event
	ClipboardCopied(message:String);

	Ping;
}

@:liveview
@:liveEvents(ProfileHookEvent)
class ProfileLive {
	public static function handleEvent(event:String, params:Term, socket:Socket<ProfileAssigns>):HandleEventResult<ProfileAssigns> {
		var hookResult = dispatchProfileHookEvent(event, params, socket);
		if (hookResult != null) {
			return hookResult;
		}

		return switch (event) {
			case "save_profile":
				NoReply(LiveView.assign(socket, "flash_message", "Saved."));
			case _:
				NoReply(socket);
		}
	}

	static function handleClipboardCopied(message:String, socket:Socket<ProfileAssigns>):HandleEventResult<ProfileAssigns> {
		return NoReply(LiveView.assign(socket, "flash_message", message));
	}

	static function handlePing(socket:Socket<ProfileAssigns>):HandleEventResult<ProfileAssigns> {
		return NoReply(socket);
	}
}

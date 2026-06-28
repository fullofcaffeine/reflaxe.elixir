import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;
import phoenix.channels.EncodedEvent;
import phoenix.channels.Payload;
import phoenix.live_view.LiveEventProtocolCompanion;

typedef ProfileAssigns = {
	var flashMessage:String;
}

typedef ClipboardCopiedPayload = {
	var message:String;

	@:wire("copied_at")
	var copiedAt:String;
}

@:liveEventProtocol("ProfileHookEvents")
enum ProfileHookEvent {
	@:event("clipboard_copied")
	ClipboardCopied(payload:ClipboardCopiedPayload);

	Ping;
}

typedef ProfileHookEvents = LiveEventProtocolCompanion<ProfileHookEvent>;

@:liveview
@:liveEvents(ProfileHookEvent, "dispatchProfileHookEvent")
class ProfileLive {
	public static function encodeCopied(message:String, copiedAt:String):EncodedEvent {
		var payload:ClipboardCopiedPayload = {message: message, copiedAt: copiedAt};
		return ProfileHookEvents.encode(ClipboardCopied(payload));
	}

	public static function decodeCopied(payload:Payload):Null<ProfileHookEvent> {
		return ProfileHookEvents.decode(ProfileHookEvents.ClipboardCopiedEvent, payload);
	}

	public static function handleEvent(event:String, params:Term, socket:Socket<ProfileAssigns>):HandleEventResult<ProfileAssigns> {
		var hookResult = dispatchProfileHookEvent(event, params, socket);
		if (hookResult != null) {
			return hookResult;
		}

		return NoReply(socket);
	}

	static function handleClipboardCopied(payload:ClipboardCopiedPayload, socket:Socket<ProfileAssigns>):HandleEventResult<ProfileAssigns> {
		return NoReply(LiveView.assign(socket, "flash_message", payload.message));
	}

	static function handlePing(socket:Socket<ProfileAssigns>):HandleEventResult<ProfileAssigns> {
		return NoReply(socket);
	}
}

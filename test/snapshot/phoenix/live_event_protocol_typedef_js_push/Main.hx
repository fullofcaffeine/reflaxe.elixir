import phoenix.live_view.HookContext;
import phoenix.live_view.LiveEventProtocolCompanion;
import phoenix.channels.WirePayload;

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

class Main {
	static function main():Void {
		var pushed:Array<String> = [];
		var hook:HookContext = cast {
			el: null,
			pushEvent: function(event:String, payload:phoenix.channels.Payload):Void {
				pushed.push(event + ":" + WirePayload.getString(payload, "message") + ":" + WirePayload.getString(payload, "copied_at"));
			}
		};
		var payload:ClipboardCopiedPayload = {message: "Copied.", copiedAt: "2026-06-28T16:00:00Z"};

		ProfileHookEvents.pushClipboardCopied(hook, payload);
		ProfileHookEvents.push(hook, ClipboardCopied(payload));
		ProfileHookEvents.pushPing(hook);

		if (pushed.length != 3) {
			throw "expected three pushed events";
		}
	}
}

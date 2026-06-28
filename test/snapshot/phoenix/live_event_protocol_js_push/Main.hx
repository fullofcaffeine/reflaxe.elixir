import phoenix.live_view.HookContext;
import phoenix.live_view.LiveEventProtocolCompanion;

@:liveEventProtocol("ProfileHookEvents")
enum ProfileHookEvent {
	@:event("clipboard_copied")
	ClipboardCopied(message:String);

	Ping;
}

typedef ProfileHookEvents = LiveEventProtocolCompanion<ProfileHookEvent>;

class Main {
	static function main():Void {
		var pushed:Array<String> = [];
		var hook:HookContext = cast {
			el: null,
			pushEvent: function(event:String, _payload:phoenix.channels.Payload):Void {
				pushed.push(event);
			}
		};

		ProfileHookEvents.pushClipboardCopied(hook, "Copied.");
		ProfileHookEvents.pushPing(hook);
		ProfileHookEvents.push(hook, Ping);

		if (pushed.length != 3) {
			throw "expected three pushed events";
		}
	}
}

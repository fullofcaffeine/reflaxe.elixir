import phoenix.live_view.HookContext;
import phoenix.live_view.LiveEventProtocolCompanion;

@:liveEventProtocol("TodoEvents")
enum TodoEvent {
	@:templateEvent("toggle_todo")
	ToggleTodo(id:Int);

	@:hookEvent("clipboard_copied")
	ClipboardCopied(message:String);
}

typedef TodoEvents = LiveEventProtocolCompanion<TodoEvent>;

class Main {
	static function main():Void {
		var pushed:Array<String> = [];
		var hook:HookContext = {
			el: null,
			pushEvent: function(event:String, _payload:phoenix.channels.Payload):Void {
				pushed.push(event);
			}
		};

		TodoEvents.pushClipboardCopied(hook, "Copied.");

		if (pushed.length != 1 || pushed[0] != TodoEvents.ClipboardCopiedEvent) {
			throw "expected one hook-origin push";
		}
	}
}

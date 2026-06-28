import phoenix.channels.Payload;
import phoenix.channels.WirePayload;
import phoenix.live_view.HookContext;
import phoenix.live_view.LiveEventProtocolCompanion;

typedef TodoSelectedPayload = {
	@:codec(TodoIdCodec.codec())
	var todoId:TodoId;

	var source:String;
}

@:liveEventProtocol("TodoHookEvents")
enum TodoHookEvent {
	@:event("todo_selected")
	TodoSelected(payload:TodoSelectedPayload);

	Ping;
}

typedef TodoHookEvents = LiveEventProtocolCompanion<TodoHookEvent>;

class Main {
	static function main():Void {
		var pushed:Array<String> = [];
		var hook:HookContext = cast {
			el: null,
			pushEvent: function(event:String, payload:Payload):Void {
				var nested = WirePayload.getPayload(payload, "todo_id");
				var id = nested == null ? null : WirePayload.getInt(nested, "value");
				pushed.push(event + ":" + id + ":" + WirePayload.getString(payload, "source"));
			}
		};

		TodoHookEvents.pushTodoSelected(hook, {todoId: new TodoId(42), source: "row"});
		TodoHookEvents.push(hook, TodoSelected({todoId: new TodoId(43), source: "keyboard"}));
		TodoHookEvents.pushPing(hook);

		if (pushed.length != 3) {
			throw "expected three pushed events";
		}
	}
}

import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;
import phoenix.channels.EncodedEvent;
import phoenix.channels.Payload;
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

typedef TodoAssigns = {
	var selectedTodoId:Int;
}

@:liveview
@:liveEvents(TodoHookEvent, "dispatchTodoHookEvent")
class ProfileLive {
	public static function encodeSelected(todoId:TodoId, source:String):EncodedEvent {
		var payload:TodoSelectedPayload = {todoId: todoId, source: source};
		return TodoHookEvents.encode(TodoSelected(payload));
	}

	public static function decodeSelected(payload:Payload):Null<TodoHookEvent> {
		return TodoHookEvents.decode(TodoHookEvents.TodoSelectedEvent, payload);
	}

	public static function handleEvent(event:String, params:Term, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
		var hookResult = dispatchTodoHookEvent(event, params, socket);
		if (hookResult != null) {
			return hookResult;
		}

		return NoReply(socket);
	}

	static function handleTodoSelected(payload:TodoSelectedPayload, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
		return NoReply(LiveView.assign(socket, "selected_todo_id", payload.todoId));
	}

	static function handlePing(socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
		return NoReply(socket);
	}
}

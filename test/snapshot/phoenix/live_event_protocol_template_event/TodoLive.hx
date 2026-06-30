import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;
import phoenix.channels.Payload;
import phoenix.live_view.LiveEventProtocolCompanion;

typedef TodoAssigns = {
	var last_id:String;
}

@:liveEventProtocol
enum TodoEvent {
	@:templateEvent
	ToggleTodo(id:Int);

	@:hookEvent
	ClipboardCopied(message:String);
}

typedef TodoEvents = LiveEventProtocolCompanion<TodoEvent>;

@:liveview
@:liveEvents(TodoEvent)
class TodoLive {
	public static function render(assigns:TodoAssigns):String {
		return <button phx-click=${TodoEvents.ToggleTodoEvent} phx-value-id="1">${assigns.last_id}</button>;
	}

	public static function toggleEventName():String {
		return TodoEvents.ToggleTodoEvent;
	}

	public static function decodeToggle(payload:Payload):Null<TodoEvent> {
		return TodoEvents.decode(TodoEvents.ToggleTodoEvent, payload);
	}

	public static function handleEvent(event:String, params:Term, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
		var handled = dispatchTodoEvent(event, params, socket);
		if (handled != null) {
			return handled;
		}

		return NoReply(socket);
	}

	static function handleToggleTodo(id:Int, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
		return NoReply(LiveView.assign(socket, "last_id", Std.string(id)));
	}

	static function handleClipboardCopied(message:String, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
		return NoReply(LiveView.assign(socket, "last_id", message));
	}
}

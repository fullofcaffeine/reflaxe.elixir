import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;
import phoenix.live_view.LiveEventProtocolCompanion;

typedef TodoAssigns = {
	var label:String;
}

@:liveEventProtocol("TodoEvents")
enum TodoEvent {
	@:templateEvent("toggle_todo")
	ToggleTodo(id:Int);
}

typedef TodoEvents = LiveEventProtocolCompanion<TodoEvent>;

@:liveview
@:liveEvents(TodoEvent, "dispatchTodoEvent")
class TodoLive {
	public static function render(assigns:TodoAssigns):String {
		return <button phx-click=${TodoEvents.ToggleTodoEvent} phx-value-id="1" phx-value-extra="nope">${assigns.label}</button>;
	}

	public static function handleEvent(event:String, params:Term, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
		var handled = dispatchTodoEvent(event, params, socket);
		if (handled != null) {
			return handled;
		}
		return NoReply(socket);
	}

	static function handleToggleTodo(id:Int, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
		return NoReply(LiveView.assign(socket, "label", Std.string(id)));
	}
}

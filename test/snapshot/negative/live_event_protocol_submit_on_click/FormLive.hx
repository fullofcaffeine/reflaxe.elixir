import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;
import phoenix.live_view.LiveEventProtocolCompanion;

typedef FormAssigns = {
	var label:String;
}

typedef TodoForm = {
	var title:String;
}

@:liveEventProtocol("TodoFormEvents")
enum TodoFormEvent {
	@:submitEvent("create_todo", "todo")
	CreateTodo(payload:TodoForm);
}

typedef TodoFormEvents = LiveEventProtocolCompanion<TodoFormEvent>;

@:liveview
@:liveEvents(TodoFormEvent, "dispatchTodoFormEvent")
class FormLive {
	public static function render(assigns:FormAssigns):String {
		return <button phx-click=${TodoFormEvents.CreateTodoEvent}>${assigns.label}</button>;
	}

	public static function handleEvent(event:String, params:Term, socket:Socket<FormAssigns>):HandleEventResult<FormAssigns> {
		var handled = dispatchTodoFormEvent(event, params, socket);
		if (handled != null) {
			return handled;
		}
		return NoReply(socket);
	}

	static function handleCreateTodo(payload:TodoForm, socket:Socket<FormAssigns>):HandleEventResult<FormAssigns> {
		return NoReply(LiveView.assign(socket, "label", payload.title));
	}
}

import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;
import phoenix.channels.Payload;
import phoenix.live_view.LiveEventProtocolCompanion;

typedef FormAssigns = {
	var summary:String;
}

typedef TodoForm = {
	var title:String;
	@:optional var notes:Null<String>;
	var priority:Int;
	var done:Bool;
	var estimate:Float;
}

@:liveEventProtocol
enum TodoFormEvent {
	@:submitEvent("todo")
	CreateTodo(payload:TodoForm);

	@:changeEvent("todo")
	UpdateForm(payload:TodoForm);

	@:submitEvent("todo")
	ClearCompleted;
}

typedef TodoFormEvents = LiveEventProtocolCompanion<TodoFormEvent>;

@:liveview
@:liveEvents(TodoFormEvent)
class FormLive {
	public static function render(assigns:FormAssigns):String {
		return <form phx-submit=${TodoFormEvents.CreateTodoEvent} phx-change=${TodoFormEvents.UpdateFormEvent}>
			<input type="text" name="todo[title]" value=${assigns.summary} />
		</form>;
	}

	public static function createEventName():String {
		return TodoFormEvents.CreateTodoEvent;
	}

	public static function decodeCreate(payload:Payload):Null<TodoFormEvent> {
		return TodoFormEvents.decode(TodoFormEvents.CreateTodoEvent, payload);
	}

	public static function handleEvent(event:String, params:Term, socket:Socket<FormAssigns>):HandleEventResult<FormAssigns> {
		var handled = dispatchTodoFormEvent(event, params, socket);
		if (handled != null) {
			return handled;
		}

		return NoReply(socket);
	}

	static function handleCreateTodo(payload:TodoForm, socket:Socket<FormAssigns>):HandleEventResult<FormAssigns> {
		return NoReply(LiveView.assign(socket, "summary", payload.title + ":" + Std.string(payload.priority)));
	}

	static function handleUpdateForm(payload:TodoForm, socket:Socket<FormAssigns>):HandleEventResult<FormAssigns> {
		return NoReply(LiveView.assign(socket, "summary", payload.title + ":" + Std.string(payload.done)));
	}

	static function handleClearCompleted(socket:Socket<FormAssigns>):HandleEventResult<FormAssigns> {
		return NoReply(LiveView.assign(socket, "summary", "cleared"));
	}
}

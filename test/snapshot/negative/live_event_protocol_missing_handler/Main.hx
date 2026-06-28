import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.Socket;

typedef Assigns = {}

@:liveEventProtocol("BadHookEvents")
enum BadHookEvent {
	Bad(message:String);
}

@:liveview
@:liveEvents(BadHookEvent, "dispatchBadHookEvent")
class Main {
	public static function handleEvent(event:String, params:Term, socket:Socket<Assigns>):HandleEventResult<Assigns> {
		var hookResult = dispatchBadHookEvent(event, params, socket);
		if (hookResult != null) {
			return hookResult;
		}
		return NoReply(socket);
	}
}

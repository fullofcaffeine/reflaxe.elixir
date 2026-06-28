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
	public static function handleEvent(_event:String, _params:Term, socket:Socket<Assigns>):HandleEventResult<Assigns> {
		return NoReply(socket);
	}

	static function handleBad(message:String, socket:Socket<Assigns>):HandleEventResult<Assigns> {
		return NoReply(socket);
	}
}

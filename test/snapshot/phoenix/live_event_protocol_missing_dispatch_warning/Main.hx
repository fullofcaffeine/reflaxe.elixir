import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.Socket;

typedef Assigns = {
	var touched:Bool;
}

@:liveEventProtocol("SoftHookEvents")
enum SoftHookEvent {
	SoftPing;
}

@:liveview
@:liveEvents(SoftHookEvent, "dispatchSoftHookEvent")
class Main {
	public static function handleEvent(_event:String, _params:Term, socket:Socket<Assigns>):HandleEventResult<Assigns> {
		return NoReply(socket);
	}

	static function handleSoftPing(socket:Socket<Assigns>):HandleEventResult<Assigns> {
		return NoReply(socket);
	}
}

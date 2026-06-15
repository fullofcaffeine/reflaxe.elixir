package;

import phoenix.LiveSocket;
import phoenix.Phoenix.Socket;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.HandleEventResult;
import HXX;
import phoenix.Phoenix.LiveView;
import elixir.types.Term;

typedef DerivedAssigns = {
	var count:Int;
}

@:liveview
@:hxx_mode("balanced")
class CounterLiveDerivedEventsIf {
	public static function handleEvent(event:String, _params:Term, socket:Socket<DerivedAssigns>):HandleEventResult<DerivedAssigns> {
		if (event == "increment") {
			var nextCount = socket.assigns.count + 1;
			return NoReply(LiveView.assign(socket, "count", nextCount));
		}
		if (event == "decrement") {
			var nextCount = socket.assigns.count - 1;
			return NoReply(LiveView.assign(socket, "count", nextCount));
		}
		return NoReply(socket);
	}

	public function mount(params:Term, session:Term, socket:Socket<DerivedAssigns>):MountResult<DerivedAssigns> {
		socket = LiveView.assign(socket, "count", 0);
		return Ok(socket);
	}

	public function render(assigns:DerivedAssigns):String {
		return HXX.hxx('<div>
          <h1>Counter: ${assigns.count}</h1>
          <button phx-click="increment">+</button>
          <button phx-click="decrement">-</button>
        </div>');
	}
}

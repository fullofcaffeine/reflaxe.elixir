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
class CounterLiveDerivedEvents {
	@:native("handle_event")
	public static function handle_event(event:String, _params:Term, socket:Socket<DerivedAssigns>):HandleEventResult<DerivedAssigns> {
		return switch (event) {
			case "increment":
				var nextCount = socket.assigns.count + 1;
				NoReply(LiveView.assign(socket, "count", nextCount));
			case "decrement":
				var nextCount = socket.assigns.count - 1;
				NoReply(LiveView.assign(socket, "count", nextCount));
			case _:
				NoReply(socket);
		}
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

package;

import phoenix.LiveSocket;
import phoenix.Phoenix.Socket;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.HandleEventResult;
import HXX;
import phoenix.Phoenix.LiveView;
import elixir.types.Term;

typedef CounterAssigns = {
	var count: Int;
}

/**
 * Basic LiveView test case using current Phoenix API
 * Tests @:liveview annotation compilation
 */
@:liveview
class CounterLive {
	
	public function mount(params: Term, session: Term, socket: Socket<CounterAssigns>): MountResult<CounterAssigns> {
		// Use LiveView.assign like todo-app does
		socket = LiveView.assign(socket, "count", 0);
		return Ok(socket);
	}
	
	public function handle_event_increment(params: Term, socket: Socket<CounterAssigns>): HandleEventResult<CounterAssigns> {
		var count = socket.assigns.count;
		socket = LiveView.assign(socket, "count", count + 1);
		return NoReply(socket);
	}
	
	public function handle_event_decrement(params: Term, socket: Socket<CounterAssigns>): HandleEventResult<CounterAssigns> {
		var count = socket.assigns.count;
		socket = LiveView.assign(socket, "count", count - 1);
		return NoReply(socket);
	}
	
    public function render(assigns: CounterAssigns): String {
        return HXX.hxx('<div>
          <h1>Counter: ${assigns.count}</h1>
          <button phx-click="increment">+</button>
          <button phx-click="decrement">-</button>
        </div>');
    }
}

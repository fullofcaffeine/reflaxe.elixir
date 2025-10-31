package;

import phoenix.LiveSocket;
import phoenix.Phoenix.Socket;
import HXX;
import phoenix.Phoenix.LiveView;

typedef CounterAssigns = {
	var count: Int;
}

/**
 * Basic LiveView test case using current Phoenix API
 * Tests @:liveview annotation compilation
 */
@:liveview
class CounterLive {
	
	public function mount(params: Dynamic, session: Dynamic, socket: Socket<CounterAssigns>): Dynamic {
		// Use LiveView.assign like todo-app does
		socket = LiveView.assign(socket, "count", 0);
		return {ok: socket};
	}
	
	public function handle_event_increment(params: Dynamic, socket: Socket<CounterAssigns>): Dynamic {
		var count = socket.assigns.count;
		socket = LiveView.assign(socket, "count", count + 1);
		return {noreply: socket};
	}
	
	public function handle_event_decrement(params: Dynamic, socket: Socket<CounterAssigns>): Dynamic {
		var count = socket.assigns.count;
		socket = LiveView.assign(socket, "count", count - 1);
		return {noreply: socket};
	}
	
    public function render(assigns: CounterAssigns): String {
        return HXX.hxx('<div>
          <h1>Counter: ${assigns.count}</h1>
          <button phx-click="increment">+</button>
          <button phx-click="decrement">-</button>
        </div>');
    }
}

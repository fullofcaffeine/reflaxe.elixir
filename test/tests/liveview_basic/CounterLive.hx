package;

import phoenix.LiveView;
import phoenix.Socket;

/**
 * Basic LiveView test case
 * Tests @:liveview annotation compilation
 */
@:liveview
class CounterLive extends LiveView {
	
	public function mount(params: Dynamic, session: Dynamic, socket: Phoenix.Socket): Dynamic {
		socket = Phoenix.LiveView.assign(socket, "count", 0);
		return {ok: socket};
	}
	
	public function handle_event_increment(params: Dynamic, socket: Phoenix.Socket): Dynamic {
		var count = socket.assigns.count;
		socket = Phoenix.LiveView.assign(socket, "count", count + 1);
		return {noreply: socket};
	}
	
	public function handle_event_decrement(params: Dynamic, socket: Phoenix.Socket): Dynamic {
		var count = socket.assigns.count;
		socket = Phoenix.LiveView.assign(socket, "count", count - 1);
		return {noreply: socket};
	}
	
	public function render(assigns: Dynamic): String {
		return '<div>
		  <h1>Counter: <%= @count %></h1>
		  <button phx-click="increment">+</button>
		  <button phx-click="decrement">-</button>
		</div>';
	}
}
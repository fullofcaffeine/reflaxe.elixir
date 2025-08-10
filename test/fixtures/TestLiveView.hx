package fixtures;

import phoenix.Phoenix;

/**
 * Test fixture for LiveView compilation
 * This class demonstrates the expected @:liveview usage pattern
 */
@:liveview
class TestLiveView extends Phoenix.LiveView {
    
    /**
     * Mount the LiveView with initial state
     */
    public function mount(params: Dynamic, session: Dynamic, socket: Phoenix.Socket): Dynamic {
        // Initialize socket with default assigns
        socket = Phoenix.LiveView.assign(socket, "counter", 0);
        socket = Phoenix.LiveView.assign(socket, "message", "Hello LiveView!");
        
        return {ok: socket};
    }
    
    /**
     * Handle increment button click
     */
    public function handle_event_increment(params: Dynamic, socket: Phoenix.Socket): Dynamic {
        var counter = socket.assigns.counter;
        socket = Phoenix.LiveView.assign(socket, "counter", counter + 1);
        
        return {noreply: socket};
    }
    
    /**
     * Handle decrement button click
     */
    public function handle_event_decrement(params: Dynamic, socket: Phoenix.Socket): Dynamic {
        var counter = socket.assigns.counter;
        socket = Phoenix.LiveView.assign(socket, "counter", counter - 1);
        
        return {noreply: socket};
    }
    
    /**
     * Handle message update
     */
    public function handle_event_update_message(params: Dynamic, socket: Phoenix.Socket): Dynamic {
        var newMessage = params.message != null ? params.message : "Default message";
        socket = Phoenix.LiveView.assign(socket, "message", newMessage);
        
        return {noreply: socket};
    }
    
    /**
     * Render the LiveView template
     */
    public function render(assigns: Dynamic): String {
        return '''
        <div>
          <h1>Phoenix LiveView Test</h1>
          <p>Message: ${assigns.message}</p>
          <p>Counter: ${assigns.counter}</p>
          
          <button phx-click="increment">+</button>
          <button phx-click="decrement">-</button>
          
          <form phx-change="update_message">
            <input type="text" name="message" value="${assigns.message}" />
          </form>
        </div>
        ''';
    }
}
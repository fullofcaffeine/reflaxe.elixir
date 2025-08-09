package phoenix;

/**
 * Phoenix Application entry point compiled from Haxe
 * This demonstrates how to create a Phoenix application using Haxe→Elixir compilation
 */
class Application {
    public static function main() {
        trace("Phoenix Haxe Example starting...");
    }
    
    /**
     * Application callback for Phoenix startup
     */
    public static function start(type: String, args: Array<Dynamic>): {status: String, pid: Dynamic} {
        var children = [
            // Add your supervised processes here
            // Example: {UserServer, []}
        ];
        
        var opts = ["strategy" => "one_for_one", "name" => "PhoenixHaxeExample.Supervisor"];
        
        // In real implementation, this would call Supervisor.start_link
        return {status: "ok", pid: null};
    }
}

@:liveview
class CounterLive {
    var count = 0;
    
    function mount(_params: Dynamic, _session: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        return {status: "ok", socket: assign(socket, "count", count)};
    }
    
    function handle_event(event: String, params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        switch(event) {
            case "increment":
                count++;
                return {status: "noreply", socket: assign(socket, "count", count)};
            case "decrement":
                count--;
                return {status: "noreply", socket: assign(socket, "count", count)};
            default:
                return {status: "noreply", socket: socket};
        }
    }
    
    function render(assigns: Dynamic): String {
        return '
        <div>
            <h1>Counter: <%= @count %></h1>
            <button phx-click="increment">+</button>
            <button phx-click="decrement">-</button>
        </div>';
    }
    
    static function assign(socket: Dynamic, key: String, value: Dynamic): Dynamic {
        // This would be implemented by the Reflaxe.Elixir compiler
        return socket;
    }
}
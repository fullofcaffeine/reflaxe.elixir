package;

import phoenix.Phoenix;
import elixir.Supervisor;

/**
 * Main TodoApp application module
 * Defines the OTP application supervision tree
 */
@:native("TodoApp.Application")
@:application
class TodoApp {
    /**
     * Start the application
     */
    public static function start(type: Dynamic, args: Dynamic): Dynamic {
        // Define children for the supervision tree
        var children = [
            // Database repository
            {
                id: "TodoApp.Repo",
                start: {module: "TodoApp.Repo", "function": "start_link", args: []}
            },
            // PubSub system
            {
                id: "Phoenix.PubSub",
                start: {
                    module: "Phoenix.PubSub", 
                    "function": "start_link",
                    args: [{name: "TodoApp.PubSub"}]
                }
            },
            // Telemetry supervisor
            {
                id: "TodoAppWeb.Telemetry",
                start: {module: "TodoAppWeb.Telemetry", "function": "start_link", args: []}
            },
            // Web endpoint
            {
                id: "TodoAppWeb.Endpoint", 
                start: {module: "TodoAppWeb.Endpoint", "function": "start_link", args: []}
            }
        ];

        // Start supervisor with children
        var opts = {strategy: "one_for_one", name: "TodoApp.Supervisor"};
        return Supervisor.startLink(children, opts);
    }

    /**
     * Called when application is preparing to shut down
     */
    public static function prep_stop(state: Dynamic): Dynamic {
        return state;
    }
}
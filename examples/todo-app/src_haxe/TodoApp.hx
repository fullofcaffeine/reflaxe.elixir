package;

import phoenix.Phoenix;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorStrategy;

/**
 * Main TodoApp application module
 * Defines the OTP application supervision tree
 */
@:native("TodoApp.Application")
@:application
@:appName("TodoApp")  
class TodoApp {
    /**
     * Get the app name from the @:appName annotation
     * Simplified version for testing
     */
    private static function getAppName(): String {
        return "TodoApp";
    }
    /**
     * Start the application
     */
    public static function start(type: Dynamic, args: Dynamic): Dynamic {
        // Get the app name dynamically - this will be replaced by the compiler
        var appName = getAppName();
        
        // Define children for the supervision tree
        var children = [
            // Database repository
            {
                id: '${appName}.Repo',
                start: {module: '${appName}.Repo', func: "start_link", args: []}
            },
            // PubSub system
            {
                id: "Phoenix.PubSub",
                start: {
                    module: "Phoenix.PubSub", 
                    func: "start_link",
                    args: [{name: '${appName}.PubSub'}]
                }
            },
            // Telemetry supervisor
            {
                id: '${appName}Web.Telemetry',
                start: {module: '${appName}Web.Telemetry', func: "start_link", args: []}
            },
            // Web endpoint
            {
                id: '${appName}Web.Endpoint', 
                start: {module: '${appName}Web.Endpoint', func: "start_link", args: []}
            }
        ];

        // Start supervisor with children
        var opts = {strategy: OneForOne, name: '${appName}.Supervisor'};
        return SupervisorExtern.start_link(children, opts);
    }

    /**
     * Called when application is preparing to shut down
     */
    public static function prep_stop(state: Dynamic): Dynamic {
        return state;
    }
}
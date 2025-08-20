package;

import phoenix.Phoenix;
import elixir.otp.Application;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.ChildSpec;

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
    public static function start(type: ApplicationStartType, args: ApplicationArgs): ApplicationResult {
        // Get the app name dynamically - this will be replaced by the compiler
        var appName = getAppName();
        
        // Define children for the supervision tree
        var children: Array<ChildSpec> = [
            // Database repository - temporarily disabled due to PostgreSQL TypeManager issues
            // {
            //     id: '${appName}.Repo',
            //     start: {module: '${appName}.Repo', func: "start_link", args: []}
            // },
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
        var opts: SupervisorOptions = {
            strategy: OneForOne,
            max_restarts: 3,
            max_seconds: 5
        };
        
        // Start the supervisor and return proper ApplicationResult
        var supervisorResult = SupervisorExtern.start_link(children, opts);
        
        // Return the supervisor result directly - it's already {:ok, pid} format
        return supervisorResult;
    }

    /**
     * Called when application is preparing to shut down
     * State is whatever was returned from start/2
     */
    public static function prep_stop(state: Dynamic): Dynamic {
        // For now, keep Dynamic since this is rarely customized
        // and state type varies based on application needs
        return state;
    }
}
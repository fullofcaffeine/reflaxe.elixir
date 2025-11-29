package;

import phoenix.Phoenix;
import elixir.otp.Application;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.TypeSafeChildSpec;
import elixir.otp.Supervisor.ChildSpecFormat;

/**
 * Main TodoApp application module
 * Defines the OTP application supervision tree
 */
@:application
@:appName("TodoApp")  
class TodoApp {
    /**
     * Start the application
     */
    @:keep
    public static function start(_type: ApplicationStartType, _args: ApplicationArgs): ApplicationResult {
        // Define children for the supervision tree using type-safe child specs
        var children: Array<ChildSpecFormat> = [
            // Database repository - Ecto.Repo handles Postgrex.TypeManager internally
            ModuleRef("TodoApp.Repo"),
            
            // PubSub system with proper child spec
            TypeSafeChildSpec.pubSub("TodoApp.PubSub"),
            
            // Presence tracker - starts Phoenix.Tracker backing ETS tables
            // Presence module defines child_spec via `use Phoenix.Presence`
            ModuleRef("TodoAppWeb.Presence"),
            
            // Telemetry supervisor
            TypeSafeChildSpec.telemetry("TodoAppWeb.Telemetry"),
            
            // Web endpoint
            TypeSafeChildSpec.endpoint("TodoAppWeb.Endpoint")
        ];

        final options: SupervisorOptions = {
            strategy: SupervisorStrategy.OneForOne,
            max_restarts: 3,
            max_seconds: 5
        };
        // Start supervisor with children using type-safe SupervisorExtern
        return SupervisorExtern.startLink(children, options);
    }

    /**
     * Called when application is preparing to shut down
     * State is whatever was returned from start/2
     */
    @:keep
    public static function prep_stop(state: Dynamic): Dynamic {
        // For now, keep Dynamic since this is rarely customized
        // and state type varies based on application needs
        return state;
    }
}

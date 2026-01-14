package;

import elixir.otp.Application;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.types.Term;

@:native("MyApp.Application")
@:application
class ApplicationModule {
    public static function start(type: ApplicationStartType, args: ApplicationArgs): ApplicationResult {
        // Intentionally unused: the compiler should underscore these in Elixir to avoid warnings.
        final options: SupervisorOptions = {
            strategy: SupervisorStrategy.OneForOne,
            max_restarts: 3,
            max_seconds: 5
        };
        return cast SupervisorExtern.startLink([], options);
    }

    public static function prep_stop(state: Term): Term {
        return state;
    }
}

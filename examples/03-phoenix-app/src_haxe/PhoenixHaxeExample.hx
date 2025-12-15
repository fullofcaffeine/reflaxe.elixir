package;

import elixir.otp.Application;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.TypeSafeChildSpec;
import elixir.otp.Supervisor.ChildSpecFormat;

/**
 * PhoenixHaxeExample application entry point.
 *
 * A minimal Phoenix application written in Haxe and compiled to idiomatic Elixir.
 */
@:application
@:appName("PhoenixHaxeExample")
class PhoenixHaxeExample {
    /**
     * Start the application supervision tree.
     */
    @:keep
    public static function start(_type: ApplicationStartType, _args: ApplicationArgs): ApplicationResult {
        // Ack OTP callback args to keep Elixir warnings clean.
        var _ = _type;
        var _ = _args;

        var children: Array<ChildSpecFormat> = [
            TypeSafeChildSpec.pubSub("PhoenixHaxeExample.PubSub"),
            TypeSafeChildSpec.endpoint("PhoenixHaxeExampleWeb.Endpoint")
        ];

        final options: SupervisorOptions = {
            strategy: SupervisorStrategy.OneForOne,
            max_restarts: 3,
            max_seconds: 5
        };

        return SupervisorExtern.startLink(children, options);
    }
}


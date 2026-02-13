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
// @:application: marks this class as an OTP application entry module.
@:application
// @:appName: sets the OTP app identifier used for generated module/config wiring.
@:appName("PhoenixHaxeExample")
class PhoenixHaxeExample {
	/**
	 * Start the application supervision tree.
	 */
		// @:keep: required because OTP invokes Application.start/2 via runtime callback dispatch, not direct Haxe callsites.
		@:keep
		public static function start(type:ApplicationStartType, args:ApplicationArgs):ApplicationResult {
		var children:Array<ChildSpecFormat> = [
			TypeSafeChildSpec.pubSub("PhoenixHaxeExample.PubSub"),
			TypeSafeChildSpec.endpoint("PhoenixHaxeExampleWeb.Endpoint")
		];

		final options:SupervisorOptions = {
			strategy: SupervisorStrategy.OneForOne,
			max_restarts: 3,
			max_seconds: 5
		};

		return SupervisorExtern.startLink(children, options);
	}
}

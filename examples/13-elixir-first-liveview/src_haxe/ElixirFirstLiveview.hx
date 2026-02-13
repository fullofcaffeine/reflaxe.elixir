package;

import elixir.otp.Application;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.TypeSafeChildSpec;
import elixir.otp.Supervisor.ChildSpecFormat;

/**
 * ElixirFirstLiveview application entry point.
 */
// @:application: marks this class as an OTP application entry module.
@:application
// @:appName: sets the OTP app identifier used for generated module/config wiring.
@:appName("ElixirFirstLiveview")
class ElixirFirstLiveview {
		// @:keep: required because OTP calls Application.start/2 by convention at runtime, so Haxe DCE cannot see a direct Haxe callsite.
		@:keep
		public static function start(type:ApplicationStartType, args:ApplicationArgs):ApplicationResult {
		var children:Array<ChildSpecFormat> = [
			TypeSafeChildSpec.pubSub("ElixirFirstLiveview.PubSub"),
			TypeSafeChildSpec.endpoint("ElixirFirstLiveviewWeb.Endpoint")
		];

		final options:SupervisorOptions = {
			strategy: SupervisorStrategy.OneForOne,
			max_restarts: 3,
			max_seconds: 5
		};

		return SupervisorExtern.startLink(children, options);
	}
}

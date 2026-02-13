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
@:application
@:appName("ElixirFirstLiveview")
class ElixirFirstLiveview {
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

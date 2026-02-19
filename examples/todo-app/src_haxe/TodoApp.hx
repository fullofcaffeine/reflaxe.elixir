package;

import phoenix.Phoenix;
import elixir.otp.Application;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.TypeSafeChildSpec;
import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.types.Term;
import server.infrastructure.Endpoint;
import server.infrastructure.PubSub;
import server.infrastructure.Repo;
import server.infrastructure.Telemetry;
import server.presence.TodoPresence;
import server.support.DevAutoMigrate;

/**
 * Main TodoApp application module
 * Defines the OTP application supervision tree
 */
// @:application: marks this class as an OTP application entry module.
@:application
// @:appName: sets the OTP app identifier used for generated module/config wiring.
@:appName("TodoApp")
class TodoApp {
	/**
	 * Start the application
	 */
	public static function start(type:ApplicationStartType, args:ApplicationArgs):ApplicationResult {
		// `start/2` callback args are intentionally unused in this app; the compiler
		// should emit underscored Elixir parameters to keep warnings clean.

		DevAutoMigrate.runIfEnabled();

		// Define children for the supervision tree using type-safe child specs
		var children:Array<ChildSpecFormat> = [
			// Database repository - Ecto.Repo handles Postgrex.TypeManager internally
			TypeSafeChildSpec.moduleRef(Repo),

			// PubSub system with proper child spec
			TypeSafeChildSpec.pubSub(PubSub),

			// Presence tracker - starts Phoenix.Tracker backing ETS tables
			// Presence module defines child_spec via `use Phoenix.Presence`
			TypeSafeChildSpec.moduleRef(TodoPresence),

			// Telemetry supervisor
			TypeSafeChildSpec.telemetry(Telemetry),

			// Web endpoint
			TypeSafeChildSpec.endpoint(Endpoint)
		];

		final options:SupervisorOptions = {
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
	public static function prep_stop(state:Term):Term {
		return state;
	}
}

package;

import elixir.otp.Application;
import elixir.otp.Application.ApplicationResultTools;
import elixir.otp.Supervisor.ChildSpec;
import elixir.otp.Supervisor.ChildType;
import elixir.types.Term;

@:native("MyAppWeb.Telemetry")
@:supervisor
class TelemetryModule {
	public static function child_spec(opts:Term):ChildSpec {
		return {
			id: "MyAppWeb.Telemetry",
			start: {
				module: "MyAppWeb.Telemetry",
				func: "start_link",
				args: [opts]
			},
			type: ChildType.Supervisor
		};
	}

	public static function start_link(args:Term):ApplicationResult {
		return ApplicationResultTools.ok(cast({} : Term));
	}

	public static function init(args:Term):Term {
		return cast({} : Term);
	}
}

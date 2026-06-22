package;

import elixir.Atom;
import elixir.otp.Application;
import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.TypeSafeChildSpec;
import phoenix_hx_todo_hx.infrastructure.DNSCluster;
import phoenix_hx_todo_hx.infrastructure.Endpoint;
import phoenix_hx_todo_hx.infrastructure.PubSub;
import phoenix_hx_todo_hx.infrastructure.Telemetry;

@:application
@:appName("PhoenixHxTodo")
class PhoenixHxTodo {
	@:keep
	public static function start(type:ApplicationStartType, args:ApplicationArgs):ApplicationResult {
		var dnsClusterQuery = elixir.Application.get_env(Atom.create("phoenix_hx_todo"), Atom.create("dns_cluster_query"), Atom.create("ignore"));

		var children:Array<ChildSpecFormat> = [
			TypeSafeChildSpec.telemetry(Telemetry),
			TypeSafeChildSpec.moduleWithConfig(DNSCluster, [{key: "query", value: dnsClusterQuery}]),
			TypeSafeChildSpec.pubSub(PubSub),
			TypeSafeChildSpec.endpoint(Endpoint)
		];

		final options:SupervisorOptions = {
			strategy: SupervisorStrategy.OneForOne,
			max_restarts: 3,
			max_seconds: 5
		};

		return SupervisorExtern.startLink(children, options);
	}
}

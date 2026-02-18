package;

import elixir.Atom;
import elixir.otp.Application;
import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.TypeSafeChildSpec;

/**
 * PhoenixChat OTP application entrypoint authored in Haxe.
 *
 * WHY
 * - Keeps the supervision tree source-of-truth in Haxe for this Haxe-first example.
 */
@:application
@:appName("PhoenixChat")
class PhoenixChat {
	@:keep
	public static function start(type:ApplicationStartType, args:ApplicationArgs):ApplicationResult {
		var dnsClusterQuery = elixir.Application.get_env(Atom.create("phoenix_chat"), Atom.create("dns_cluster_query"), Atom.create("ignore"));

		var children:Array<ChildSpecFormat> = [
			TypeSafeChildSpec.telemetry("PhoenixChatWeb.Telemetry"),
			ModuleWithConfig("DNSCluster", [{key: "query", value: dnsClusterQuery}]),
			TypeSafeChildSpec.pubSub("PhoenixChat.PubSub"),
			ModuleRef("PhoenixChatWeb.Presence"),
			TypeSafeChildSpec.endpoint("PhoenixChatWeb.Endpoint")
		];

		final options:SupervisorOptions = {
			strategy: SupervisorStrategy.OneForOne,
			max_restarts: 3,
			max_seconds: 5
		};

		return SupervisorExtern.startLink(children, options);
	}
}

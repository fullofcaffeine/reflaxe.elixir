package server.channels;

import elixir.types.Term;
import phoenix.channels.JoinResult;
import phoenix.channels.ReplyResult;
import phoenix.channels.TypedChannelServer;
import StringTools;
import shared.channels.PingProtocol;
import shared.channels.PingProtocol.PingClientEvent;
import shared.channels.PingProtocol.PingServerEvent;

/**
 * PingChannel
 *
 * WHAT
 * - Minimal Phoenix Channel used to validate typed channel APIs across:
 *   - Haxe→JS (genes) client
 *   - Haxe→Elixir server
 *
 * WHY
 * - Proves we can share protocol types/keys across the client/server boundary and
 *   keep the runtime surface faithful to Phoenix.
 *
 * HOW
 * - Client pushes `"ping"` with payload `%{"request_id" => "..."}`
 * - Server broadcasts `"pong"` with the same payload and returns `{:noreply, socket}`
 */
@:native("TodoAppWeb.PingChannel")
@:channel
class PingChannel {
	public static inline var Topic:String = PingProtocol.Topic;

	public static function join(topic:String, _payload:Term, socket:Term):JoinResult<Term> {
		return (topic == Topic) ? Ok(socket) : Error("unauthorized");
	}

	public static function handle_in(event:String, payload:Term, socket:Term):ReplyResult<Term> {
		var protocol = PingProtocol.serverProtocol();
		var decoded:Null<PingClientEvent> = TypedChannelServer.decode(protocol, event, payload);

		if (decoded == null) {
			return Noreply(socket);
		}

		return switch (decoded) {
			case Ping(ping):
				if (ping.requestId == null || StringTools.trim(ping.requestId) == "") {
					Noreply(socket);
				} else {
					var pong:PingServerEvent = Pong({requestId: ping.requestId});
					TypedChannelServer.broadcast(socket, protocol, pong);
					Noreply(socket);
				}
		};
	}
}

package server.channels;

import elixir.types.Term;
import phoenix.Channel;
import phoenix.channels.JoinResult;
import phoenix.channels.ReplyResult;
import StringTools;
import shared.channels.WirePayload;
import shared.channels.PingProtocol;

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
    public static inline var Topic: String = PingProtocol.Topic;

    public static function join(topic: String, _payload: Term, socket: Term): JoinResult<Term> {
        return (topic == Topic) ? Ok(socket) : Error("unauthorized");
    }

    public static function handle_in(event: String, payload: Term, socket: Term): ReplyResult<Term> {
        if (event != PingProtocol.EventPing) {
            return Noreply(socket);
        }

        var requestId = WirePayload.getString(payload, PingProtocol.WireKeyRequestId);
        if (requestId == null || StringTools.trim(requestId) == "") {
            return Noreply(socket);
        }

        var outgoing: Term = {};
        outgoing = elixir.ElixirMap.put(outgoing, PingProtocol.WireKeyRequestId, requestId);
        Channel.broadcast(socket, PingProtocol.EventPong, outgoing);
        return Noreply(socket);
    }
}

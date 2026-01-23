package phoenix.channels;

#if (macro || reflaxe_runtime)

import elixir.types.Term;
import phoenix.Channel;
import phoenix.channels.ChannelProtocol;

/**
 * TypedChannelServer
 *
 * WHAT
 * - Tiny helpers for Phoenix Channels (server-side) that pair a `ChannelProtocol`
 *   with the Phoenix-native `Phoenix.Channel` API.
 *
 * WHY
 * - The client/server wire is string-key JSON. Sharing a protocol description between
 *   Haxe→JS and Haxe→Elixir lets applications keep a single source of truth for:
 *   - event names
 *   - payload encode/decode
 * - These helpers keep the runtime calls faithful to Phoenix (`broadcast/push`) while
 *   making typed messages ergonomic.
 *
 * HOW
 * - `broadcast(socket, protocol, msg)` encodes to `{event, payload}` then calls `Phoenix.Channel.broadcast/3`.
 * - `push(socket, protocol, msg)` encodes to `{event, payload}` then calls `Phoenix.Channel.push/3`.
 * - `decode(protocol, event, payload)` delegates to `protocol.decodeRecv/2`.
 */
#if !js
@:native("Phoenix.Channels.TypedChannelServer")
#end
class TypedChannelServer {
    public static inline function decode<TSend, TRecv>(protocol: ChannelProtocol<TSend, TRecv>, event: String, payload: Term): Null<TRecv> {
        return protocol.decodeRecv(event, payload);
    }

    public static function broadcast<TSend, TRecv>(socket: Term, protocol: ChannelProtocol<TSend, TRecv>, message: TSend): Term {
        var encoded = protocol.encodeSend(message);
        return Channel.broadcast(socket, encoded.event, encoded.payload);
    }

    public static function push<TSend, TRecv>(socket: Term, protocol: ChannelProtocol<TSend, TRecv>, message: TSend): Term {
        var encoded = protocol.encodeSend(message);
        return Channel.push(socket, encoded.event, encoded.payload);
    }
}

#end

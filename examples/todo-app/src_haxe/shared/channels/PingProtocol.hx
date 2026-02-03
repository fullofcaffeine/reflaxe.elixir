package shared.channels;

import phoenix.channels.ChannelProtocol;
import phoenix.channels.EncodedEvent;
import phoenix.channels.Payload;
import phoenix.channels.WireCodec;
import phoenix.channels.WireCodecs;
import phoenix.channels.WireField;
import phoenix.channels.WireFields;

/**
 * PingProtocol (todo-app)
 *
 * WHAT
 * - A fully typed Phoenix Channel wire protocol shared by:
 *   - server (Haxe→Elixir): `server.channels.PingChannel`
 *   - client (Haxe→JS via genes): `client.channels.PingChannelClient`
 *
 * WHY
 * - Channels are a client/server boundary. We want a single authoritative definition of:
 *   - topic + event names
 *   - payload keys and encoding/decoding
 *   - the allowed direction of messages (client→server vs server→client)
 *
 * HOW
 * - `WireFields` defines stable JSON keys (snake_case atoms/strings on the wire).
 * - `WireCodecs` builds small decoders/encoders that are usable on both targets.
 * - `ChannelProtocol` is then used by each side to register exactly what it can send/receive.
 */
typedef PingPayload = {
    var requestId: String;
}

enum PingClientEvent {
    Ping(payload: PingPayload);
}

enum PingServerEvent {
    Pong(payload: PingPayload);
}

class PingProtocol {
    public static inline var WireKeyRequestId: String = "request_id";
    public static inline var Topic: String = "typed:lobby";
    public static inline var EventPing: String = "ping";
    public static inline var EventPong: String = "pong";

    static final requestIdField: WireField<String> = WireFields.string(WireKeyRequestId);
    static final pingPayloadCodec: WireCodec<PingPayload> = WireCodecs.object1(
        requestIdField,
        function(requestId: String): PingPayload return {requestId: requestId},
        function(payload: PingPayload): String return payload.requestId
    );

    static inline function encodePingPayload(payload: PingPayload): Payload {
        return pingPayloadCodec.encode(payload);
    }

    static inline function decodePingPayload(payload: Payload): Null<PingPayload> {
        return pingPayloadCodec.decode(payload);
    }

    static function encodeClientSend(event: PingClientEvent): EncodedEvent {
        return switch (event) {
            case Ping(payload):
                {event: EventPing, payload: encodePingPayload(payload)};
        };
    }

    static function decodeClientRecv(eventName: String, payload: Payload): Null<PingServerEvent> {
        return switch (eventName) {
            case EventPong:
                var decoded = decodePingPayload(payload);
                decoded != null ? Pong(decoded) : null;
            default:
                null;
        };
    }

    static function encodeServerSend(event: PingServerEvent): EncodedEvent {
        return switch (event) {
            case Pong(payload):
                {event: EventPong, payload: encodePingPayload(payload)};
        };
    }

    static function decodeServerRecv(eventName: String, payload: Payload): Null<PingClientEvent> {
        return switch (eventName) {
            case EventPing:
                var decoded = decodePingPayload(payload);
                decoded != null ? Ping(decoded) : null;
            default:
                null;
        };
    }

    public static function clientProtocol(): ChannelProtocol<PingClientEvent, PingServerEvent> {
        return {
            eventNames: [EventPong],
            encodeSend: encodeClientSend,
            decodeRecv: decodeClientRecv
        };
    }

    public static function serverProtocol(): ChannelProtocol<PingServerEvent, PingClientEvent> {
        return {
            eventNames: [EventPing],
            encodeSend: encodeServerSend,
            decodeRecv: decodeServerRecv
        };
    }
}

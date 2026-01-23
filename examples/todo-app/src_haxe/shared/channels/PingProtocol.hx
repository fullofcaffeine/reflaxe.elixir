package shared.channels;

import phoenix.channels.ChannelProtocol;
import phoenix.channels.EncodedEvent;
import phoenix.channels.Payload;
import phoenix.channels.WirePayload;

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

    static function encodePingPayload(payload: PingPayload): Payload {
        var out = WirePayload.empty();
        return WirePayload.putString(out, WireKeyRequestId, payload.requestId);
    }

    static function decodePingPayload(payload: Payload): Null<PingPayload> {
        var requestId = WirePayload.getString(payload, WireKeyRequestId);
        return requestId != null ? {requestId: requestId} : null;
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

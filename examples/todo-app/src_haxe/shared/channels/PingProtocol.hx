package shared.channels;

typedef PingPayload = {
    var requestId: String;
}

#if js
typedef PingEncodedEvent = {
    var event: String;
    var payload: js.lib.Object;
}

typedef PingWirePayload = {
    @:optional var request_id: String;
}
#end

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

    #if js
    public static function encodePingPayload(payload: PingPayload): js.lib.Object {
        var out: PingWirePayload = {request_id: payload.requestId};
        return cast out;
    }

    public static function decodePingPayload(payload: PingWirePayload): Null<PingPayload> {
        var requestId = payload != null ? payload.request_id : null;
        return requestId != null ? {requestId: requestId} : null;
    }

    public static function encodeSend(event: PingClientEvent): PingEncodedEvent {
        return switch (event) {
            case Ping(payload):
                {event: EventPing, payload: encodePingPayload(payload)};
        }
    }

    public static function decodeRecv(eventName: String, payload: js.lib.Object): Null<PingServerEvent> {
        return switch (eventName) {
            case EventPong:
                var decoded = decodePingPayload(cast payload);
                decoded != null ? Pong(decoded) : null;
            default:
                null;
        };
    }
    #end
}

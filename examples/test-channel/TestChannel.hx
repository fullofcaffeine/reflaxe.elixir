import phoenix.Channel;

/**
 * Test channel for validating @:channel annotation
 */
@:channel
class TestChannel {
    public function join(topic: String, payload: Dynamic, socket: Dynamic): Dynamic {
        return switch (topic) {
            case "room:lobby": {ok: socket};
            case _: {error: {reason: "unauthorized"}};
        };
    }
    
    public function handleIn(event: String, payload: Dynamic, socket: Dynamic): Dynamic {
        return switch (event) {
            case "ping": 
                {reply: {ok: payload}, socket: socket};
            case "broadcast": 
                Channel.broadcast(socket, "new_message", payload);
                {noreply: socket};
            case _: 
                {noreply: socket};
        };
    }
    
    public function handleInfo(message: Dynamic, socket: Dynamic): Dynamic {
        return {noreply: socket};
    }
}
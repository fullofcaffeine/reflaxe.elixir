package phoenix;

/**
 * Phoenix.Channel extern definitions for real-time bidirectional communication
 * 
 * Channels provide a means for bidirectional communication from clients that
 * integrate with the Phoenix.PubSub layer for soft-realtime functionality.
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.Channel.html
 */

/**
 * Payload type for channel messages - can be maps, binary data, or any term
 */
typedef Payload = Dynamic;

/**
 * Reply status and response for channel operations
 */
typedef Reply = {
    var status: String; // "ok", "error", etc.
    var ?response: Payload;
};

/**
 * Socket reference for async operations
 */
typedef SocketRef = {
    var transport_pid: Dynamic;
    var serializer: String;
    var topic: String;
    var ref: String;
    var join_ref: String;
};

/**
 * Phoenix.Channel functions for managing real-time communication
 */
@:native("Phoenix.Channel")
extern class Channel {
    /**
     * Broadcast an event to all subscribers of the socket's topic
     * Returns {:ok, message} or {:error, reason}
     */
    @:native("Phoenix.Channel.broadcast")
    public static function broadcast(socket: Dynamic, event: String, message: Payload): Dynamic;
    
    /**
     * Broadcast an event to all subscribers, raising if it fails
     * Same as broadcast/3 but raises on error instead of returning error tuple
     */
    @:native("Phoenix.Channel.broadcast!")
    public static function broadcastUnsafe(socket: Dynamic, event: String, message: Payload): Dynamic;
    
    /**
     * Broadcast an event to all subscribers except the socket's transport
     * Useful to avoid echoing messages back to the sender
     */
    @:native("Phoenix.Channel.broadcast_from")
    public static function broadcastFrom(socket: Dynamic, event: String, message: Payload): Dynamic;
    
    /**
     * Broadcast from, raising if it fails
     * Same as broadcast_from/3 but raises on error
     */
    @:native("Phoenix.Channel.broadcast_from!")
    public static function broadcastFromUnsafe(socket: Dynamic, event: String, message: Payload): Dynamic;
    
    /**
     * Push an event directly to the connected client
     * Sends message only to the specific socket connection
     */
    @:native("Phoenix.Channel.push")
    public static function push(socket: Dynamic, event: String, message: Payload): Dynamic;
    
    /**
     * Reply to a client message asynchronously using socket reference
     * Used for request/response style messaging
     */
    @:native("Phoenix.Channel.reply")
    public static function reply(socketRef: SocketRef, response: Reply): Dynamic;
    
    /**
     * Get socket reference for async operations
     * Returns SocketRef for use with reply/2
     */
    @:native("Phoenix.Channel.socket_ref")
    public static function socketRef(socket: Dynamic): SocketRef;
}

/**
 * Channel behavior callbacks - typically implemented via @:channel annotation
 * These are the callbacks that channels must implement
 */
extern interface ChannelBehavior {
    /**
     * Handle channel joins by topic
     * Return {:ok, socket}, {:ok, reply, socket}, or {:error, reason}
     */
    function join(topic: String, payload: Payload, socket: Dynamic): Dynamic;
    
    /**
     * Handle incoming events from clients
     * Return {:noreply, socket}, {:reply, reply, socket}, {:stop, reason, socket}, etc.
     */
    function handleIn(event: String, payload: Payload, socket: Dynamic): Dynamic;
    
    /**
     * Intercept outgoing events (optional callback)
     * Used with intercept/1 to customize outgoing messages
     */
    function handleOut(event: String, payload: Payload, socket: Dynamic): Dynamic;
    
    /**
     * Handle regular Elixir process messages
     * For handling PubSub messages, timers, etc.
     */
    function handleInfo(message: Dynamic, socket: Dynamic): Dynamic;
}
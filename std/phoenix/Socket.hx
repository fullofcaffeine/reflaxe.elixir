package phoenix;

/**
 * Phoenix Socket types - Server-side and client-side
 */

// This module is JavaScript-only (Phoenix channels/socket client).
// Importing it in non-JS builds is almost certainly a mistake.
#if !js
#error "phoenix.Socket is a JavaScript-only extern. Only import it when compiling to JavaScript."
#end

#if js
import js.lib.Object as JsObject;
import js.lib.Function as JsFunction;
#end

// DEPRECATED: LiveViewSocket has been removed
// Use phoenix.Phoenix.Socket<T> instead for type-safe LiveView sockets
// See Phoenix.hx for the three-layer socket design documentation

/**
 * Phoenix Socket for client-side WebSocket connections (JavaScript)
 */
@:native("Socket")
extern class Socket {
	/**
	 * Create a new Phoenix Socket
	 * @param endpointUrl - WebSocket endpoint URL
	 * @param opts - Socket configuration options
	 */
	function new(?endpointUrl: String, ?opts: SocketOptions): Void;
	
	/**
	 * Connect to the socket
	 */
	function connect(): Void;
	
	/**
	 * Disconnect from the socket
	 */
	function disconnect(?code: Int, ?reason: String): Void;
	
	/**
	 * Check if socket is connected
	 */
	function isConnected(): Bool;
	
	/**
	 * Join a channel
	 */
	function channel(topic: String, ?params: JsObject): Channel;
	
	/**
	 * Remove a channel
	 */
	function remove(channel: Channel): Void;
	
	/**
	 * Get connection state
	 */
	function connectionState(): String;
	
	/**
	 * Make a reference
	 */
	function makeRef(): String;
	
	/**
	 * Send heartbeat
	 */
	function sendHeartbeat(): Void;
}

/**
 * Socket configuration options
 */
typedef SocketOptions = {
	?transport: JsFunction,
	?timeout: Int,
	?heartbeatIntervalMs: Int,
	?reconnectAfterMs: Int -> Int,
	?rejoinAfterMs: Int -> Int,
	?logger: String -> String -> JsObject -> Void,
	?longpollerTimeout: Int,
	?params: JsObject,
	?binaryType: String,
	?vsn: String
};

/**
 * Phoenix Channel for pub/sub messaging (JavaScript)
 */  
@:native("Channel")
extern class Channel {
	/**
	 * Join the channel
	 */
	function join(?timeout: Int): Push;
	
	/**
	 * Leave the channel
	 */
	function leave(?timeout: Int): Push;
	
	/**
	 * Push a message to the channel
	 */
	function push(event: String, payload: JsObject, ?timeout: Int): Push;
	
	/**
	 * Listen for channel events
	 */
	function on(event: String, callback: JsObject -> Void): Void;
	
	/**
	 * Stop listening for channel events
	 */
	function off(event: String, ?callback: JsObject -> Void): Void;
	
	/**
	 * Get channel state
	 */
	function state(): String;
}

/**
 * Phoenix Push for tracking message delivery (JavaScript)
 */
@:native("Push")  
extern class Push {
	/**
	 * Handle successful response
	 */
	function receive(status: String, callback: JsObject -> Void): Push;
}

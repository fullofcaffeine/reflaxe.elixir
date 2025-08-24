package phoenix;

import phoenix.types.Socket;
import haxe.DynamicAccess;

/**
 * Phoenix LiveView - Server-side and client-side definitions  
 */

/**
 * Phoenix.LiveView for real-time interactive applications (Server-side)
 */
@:native("Phoenix.LiveView")
extern class LiveView {
	/**
	 * Mount callback - called when LiveView is first rendered
	 */
	function mount<T>(params: DynamicAccess<String>, session: DynamicAccess<String>, socket: Socket<T>): Socket<T>;
	
	/**
	 * Handle event from client
	 */
	function handle_event<T>(event: String, params: DynamicAccess<String>, socket: Socket<T>): Socket<T>;
	
	/**
	 * Handle info messages
	 */
	function handle_info<T>(info: Any, socket: Socket<T>): Socket<T>;
	
	/**
	 * Render the LiveView template
	 */
	function render<T>(assigns: T): String;
	
	/**
	 * Assign single key-value pair to the socket
	 * Maps to Phoenix.LiveView.assign/3
	 * 
	 * @param socket The LiveView socket with typed assigns
	 * @param key The assign key name
	 * @param value The value to assign
	 * @return Updated socket with new assign
	 */
	@:overload(function<TAssigns>(socket: Socket<TAssigns>, key: String, value: Any): Socket<TAssigns> {})
	static function assign<TAssigns>(socket: Socket<TAssigns>, key: String, value: Any): Socket<TAssigns>;
	
	/**
	 * Assign multiple values to the socket using map/keyword structure
	 * Maps to Phoenix.LiveView.assign/2
	 * 
	 * Usage: assign(socket, %{key1: value1, key2: value2})
	 * 
	 * @param socket The LiveView socket with typed assigns
	 * @param assigns Map or keyword list of assigns to merge
	 * @return Updated socket with new assigns
	 */
	@:overload(function<TAssigns>(socket: Socket<TAssigns>, assigns: TAssigns): Socket<TAssigns> {})
	static function assign<TAssigns>(socket: Socket<TAssigns>, assigns: TAssigns): Socket<TAssigns>;
	
	/**
	 * Assign multiple values to the socket using map/keyword structure
	 * 
	 * ARCHITECTURAL NOTE: This extern function maps directly to Phoenix.LiveView.assign/2
	 * during compilation via the method name mapping system in MethodCallCompiler.
	 * This approach is more reliable than inline functions with __elixir__() injection.
	 * 
	 * @param socket The LiveView socket with typed assigns
	 * @param assigns Map or keyword list of assigns to merge
	 * @return Updated socket with new assigns
	 */
	@:native("assign")
	static function assign_multiple<TAssigns>(socket: Socket<TAssigns>, assigns: TAssigns): Socket<TAssigns>;
	
	/**
	 * Conditionally assign a value if not already present
	 * Maps to Phoenix.LiveView.assign_new/3
	 * 
	 * @param socket The LiveView socket
	 * @param key The assign key name
	 * @param defaultFunction Function that returns the default value
	 * @return Updated socket with new assign if key was not present
	 */
	static function assign_new<TAssigns, TValue>(socket: Socket<TAssigns>, key: String, defaultFunction: Void -> TValue): Socket<TAssigns>;
	
	/**
	 * Update an assign value
	 */
	static function update(socket: Dynamic, key: String, updater: Dynamic): Dynamic;
	
	/**
	 * Push a patch to the client (navigation)
	 */
	static function push_patch(socket: Dynamic, to: String): Dynamic;
	
	/**
	 * Push a redirect to the client
	 */
	static function push_redirect(socket: Dynamic, to: String): Dynamic;
	
	/**
	 * Put flash message for LiveView
	 */
	static function put_flash(socket: Dynamic, type: String, message: String): Dynamic;
	
	/**
	 * Clear flash messages
	 */
	static function clear_flash(socket: Dynamic, ?type: String): Dynamic;
}

// Client-side JavaScript LiveView types

/**
 * Phoenix LiveSocket for client-side LiveView integration (JavaScript)
 */
@:native("LiveSocket")
extern class LiveSocket {
	/**
	 * Registered LiveView hooks
	 */
	var hooks: Dynamic;
	
	/**
	 * Create a new LiveSocket
	 * @param url - WebSocket URL (e.g., "/live")  
	 * @param socket - Phoenix Socket instance
	 * @param opts - Configuration options
	 */
	function new(url: String, socket: Socket, ?opts: LiveSocketOptions): Void;
	
	/**
	 * Connect the LiveSocket
	 */
	function connect(): Void;
	
	/**
	 * Disconnect the LiveSocket
	 */
	function disconnect(): Void;
	
	/**
	 * Enable debug logging
	 */
	function enableDebug(): Void;
	
	/**
	 * Enable latency simulation for testing
	 */
	function enableLatencySim(upperMs: Int): Void;
	
	/**
	 * Disable latency simulation
	 */
	function disableLatencySim(): Void;
	
	/**
	 * Check if connected
	 */
	function isConnected(): Bool;
}

/**
 * LiveSocket configuration options
 */
typedef LiveSocketOptions = {
	?longPollFallbackMs: Int,
	?params: Dynamic,
	?hooks: Dynamic,
	?uploaders: Dynamic,
	?reconnectAfterMs: Dynamic,
	?rejoinAfterMs: Dynamic,
	?logger: Dynamic,
	?loggerWriteFn: Dynamic,
	?vsn: String,
	?timeout: Int,
	?heartbeatIntervalMs: Int,
	?metadata: Dynamic
};

/**
 * LiveView Hook for client-side enhancements
 * Hooks are called by LiveView during element lifecycle
 */
extern class LiveViewHook {
	/**
	 * The DOM element the hook is attached to
	 */
	#if js
	var el: js.html.Element;
	#else
	var el: Dynamic;
	#end
	
	/**
	 * Push an event to the LiveView process
	 */
	function pushEvent(event: String, payload: Dynamic, ?callback: Dynamic -> Void): Void;
	
	/**
	 * Push an event to a specific target
	 */
	function pushEventTo(target: Dynamic, event: String, payload: Dynamic, ?callback: Dynamic -> Void): Void;
	
	/**
	 * Handle incoming events
	 */
	function handleEvent(event: String, callback: Dynamic -> Void): Void;
	
	/**
	 * Upload files
	 */
	var upload: Dynamic;
	
	// Lifecycle callbacks (implemented by user)
	
	/**
	 * Called when element is added to DOM
	 */
	@:optional function mounted(): Void;
	
	/**
	 * Called when element is updated
	 */
	@:optional function updated(): Void;
	
	/**
	 * Called before element update
	 */
	@:optional function beforeUpdate(): Void;
	
	/**
	 * Called when element is removed from DOM
	 */
	@:optional function destroyed(): Void;
	
	/**
	 * Called when connection is lost
	 */
	@:optional function disconnected(): Void;
	
	/**
	 * Called when connection is restored
	 */
	@:optional function reconnected(): Void;
}
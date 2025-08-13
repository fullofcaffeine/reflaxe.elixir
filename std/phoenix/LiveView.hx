package phoenix;

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
	function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic;
	
	/**
	 * Handle event from client
	 */
	function handle_event(event: String, params: Dynamic, socket: Dynamic): Dynamic;
	
	/**
	 * Handle info messages
	 */
	function handle_info(info: Dynamic, socket: Dynamic): Dynamic;
	
	/**
	 * Render the LiveView template
	 */
	function render(assigns: Dynamic): String;
	
	/**
	 * Assign values to the socket
	 */
	static function assign(socket: Dynamic, key: String, value: Dynamic): Dynamic;
	
	/**
	 * Assign multiple values to the socket
	 */
	@:overload(function(socket: Dynamic, assigns: Dynamic): Dynamic {})
	static function assign_new(socket: Dynamic, assigns: Dynamic): Dynamic;
	
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
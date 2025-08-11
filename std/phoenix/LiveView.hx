package phoenix;

/**
 * Phoenix.LiveView for real-time interactive applications
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
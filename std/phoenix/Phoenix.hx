package phoenix;

/**
 * Core Phoenix framework extern definitions
 * Provides type-safe interfaces for Phoenix controllers, LiveView, and HTML helpers
 */

/**
 * Phoenix.Controller for handling HTTP requests
 */
@:native("Phoenix.Controller")
extern class Controller {
	/**
	 * Render a template with assigns
	 */
	static function render(conn: Dynamic, template: String, ?assigns: Dynamic): Dynamic;
	
	/**
	 * Redirect to a path or URL
	 */
	static function redirect(conn: Dynamic, to: String): Dynamic;
	
	/**
	 * Send a JSON response
	 */
	static function json(conn: Dynamic, data: Dynamic): Dynamic;
	
	/**
	 * Send plain text response
	 */
	static function text(conn: Dynamic, text: String): Dynamic;
	
	/**
	 * Send HTML response
	 */
	static function html(conn: Dynamic, html: String): Dynamic;
	
	/**
	 * Put status code
	 */
	static function put_status(conn: Dynamic, status: Int): Dynamic;
	
	/**
	 * Put response header
	 */
	static function put_resp_header(conn: Dynamic, key: String, value: String): Dynamic;
	
	/**
	 * Put flash message
	 */
	static function put_flash(conn: Dynamic, type: String, message: String): Dynamic;
	
	/**
	 * Get flash message
	 */
	static function get_flash(conn: Dynamic, ?type: String): Dynamic;
	
	/**
	 * Assign values to the connection for templates
	 */
	static function assign(conn: Dynamic, key: String, value: Dynamic): Dynamic;
}

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

/**
 * Phoenix.HTML helpers for generating HTML
 */
@:native("Phoenix.HTML")
extern class HTML {
	/**
	 * Generate a link
	 */
	static function link(text: String, to: String, ?opts: Dynamic): String;
	
	/**
	 * Generate a form
	 */
	static function form_for(changeset: Dynamic, action: String, ?opts: Dynamic, content: Dynamic): String;
	
	/**
	 * Generate form inputs
	 */
	static function text_input(form: Dynamic, field: String, ?opts: Dynamic): String;
	static function email_input(form: Dynamic, field: String, ?opts: Dynamic): String;
	static function password_input(form: Dynamic, field: String, ?opts: Dynamic): String;
	static function textarea(form: Dynamic, field: String, ?opts: Dynamic): String;
	static function select(form: Dynamic, field: String, options: Dynamic, ?opts: Dynamic): String;
	static function checkbox(form: Dynamic, field: String, ?opts: Dynamic): String;
	
	/**
	 * Form labels and errors
	 */
	static function label(form: Dynamic, field: String, ?opts: Dynamic): String;
	static function error_tag(form: Dynamic, field: String): String;
	
	/**
	 * Submit button
	 */
	static function submit(text: String, ?opts: Dynamic): String;
	
	/**
	 * Raw HTML (mark as safe)
	 */
	static function raw(html: String): String;
	
	/**
	 * Escape HTML
	 */
	static function html_escape(text: String): String;
}

/**
 * Phoenix.Router helpers for generating paths and URLs
 */
@:native("Phoenix.Router")
extern class Router {
	/**
	 * Generate a path for a route
	 */
	static function path(conn: Dynamic, route: String, ?params: Dynamic): String;
	
	/**
	 * Generate a URL for a route
	 */
	static function url(conn: Dynamic, route: String, ?params: Dynamic): String;
	
	/**
	 * Get current path from connection
	 */
	static function current_path(conn: Dynamic): String;
	
	/**
	 * Get current URL from connection
	 */
	static function current_url(conn: Dynamic): String;
}

/**
 * Phoenix.LiveView.Socket for managing LiveView state
 */
@:native("Phoenix.LiveView.Socket")
extern class Socket {
	var assigns: Dynamic;
	var changed: Dynamic;
	var connected: Bool;
	var endpoint: Dynamic;
	var id: String;
	var parent_pid: Dynamic;
	var root_pid: Dynamic;
	var router: Dynamic;
	var transport_pid: Dynamic;
	var view: Dynamic;
}

/**
 * Namespace class for Phoenix framework - just for compatibility
 */
class Phoenix {
	// Empty - just provides namespace
}
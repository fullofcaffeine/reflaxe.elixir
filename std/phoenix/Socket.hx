package phoenix;

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
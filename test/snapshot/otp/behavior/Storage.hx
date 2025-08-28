package;

/**
 * Behavior compiler test case
 * Tests @:behaviour annotation compilation
 */
@:behaviour
interface Storage {
	// Required callbacks
	function init(config: Dynamic): Dynamic;
	function get(key: String): Dynamic;
	function put(key: String, value: Dynamic): Bool;
	function delete(key: String): Bool;
	function list(): Array<String>;
}

// Implementation for memory storage
@:behaviour_impl(Storage)
class MemoryStorage {
	private var data: Map<String, Dynamic>;
	
	public function new() {
		data = new Map();
	}
	
	public function init(config: Dynamic): Dynamic {
		// Initialize with config
		return {ok: this};
	}
	
	public function get(key: String): Dynamic {
		return data.get(key);
	}
	
	public function put(key: String, value: Dynamic): Bool {
		data.set(key, value);
		return true;
	}
	
	public function delete(key: String): Bool {
		return data.remove(key);
	}
	
	public function list(): Array<String> {
		return [for (k in data.keys()) k];
	}
}

// Implementation for file storage
@:behaviour_impl(Storage)
class FileStorage {
	private var basePath: String;
	
	public function new() {
		basePath = "/tmp/storage";
	}
	
	public function init(config: Dynamic): Dynamic {
		if (config.path != null) {
			basePath = config.path;
		}
		return {ok: this};
	}
	
	public function get(key: String): Dynamic {
		// Read from file
		return null; // Simplified
	}
	
	public function put(key: String, value: Dynamic): Bool {
		// Write to file
		return true; // Simplified
	}
	
	public function delete(key: String): Bool {
		// Delete file
		return true; // Simplified
	}
	
	public function list(): Array<String> {
		// List files
		return []; // Simplified
	}
}

// Optional callbacks example
@:behaviour
interface Logger {
	function log(message: String): Void;
	
	@:optional
	function debug(message: String): Void;
	
	@:optional
	function error(message: String, error: Dynamic): Void;
}

@:behaviour_impl(Logger)
class ConsoleLogger {
	public function new() {}
	
	public function log(message: String): Void {
		trace('[LOG] $message');
	}
	
	// Optional - can be omitted
	public function debug(message: String): Void {
		trace('[DEBUG] $message');
	}
	
	// Optional - can be omitted
	// Not implementing error() is valid
}
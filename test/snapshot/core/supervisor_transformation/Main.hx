package;

/**
 * Test for @:supervisor transformation
 * Verifies that classes with @:supervisor annotation generate proper Elixir supervisor modules
 * with 'use Supervisor', child_spec, start_link, and init callbacks
 */

// Simple worker module for testing
@:keep
class Worker {
	public static function startLink(args: Dynamic): Dynamic {
		// Simulate a GenServer start_link
		return untyped __elixir__("{:ok, self()}");
	}
	
	public static function childSpec(args: Dynamic): Dynamic {
		// Return a child spec map
		return untyped __elixir__("%{
			id: Worker,
			start: {Worker, :start_link, [{0}]},
			restart: :permanent,
			type: :worker
		}", args);
	}
}

// Another worker for testing multiple children
@:keep
class DatabaseConnection {
	public static function startLink(config: Dynamic): Dynamic {
		return untyped __elixir__("{:ok, self()}");
	}
	
	public static function childSpec(config: Dynamic): Dynamic {
		return untyped __elixir__("%{
			id: DatabaseConnection,
			start: {DatabaseConnection, :start_link, [{0}]},
			restart: :permanent,
			shutdown: 5000,
			type: :worker
		}", config);
	}
}

// Main supervisor class with @:supervisor annotation
@:supervisor
@:keep
class ApplicationSupervisor {
	// Child spec function for the supervisor itself
	public static function childSpec(args: Dynamic): Dynamic {
		// This should be transformed to proper Elixir child_spec
		return untyped __elixir__("%{
			id: __MODULE__,
			start: {__MODULE__, :start_link, [{0}]},
			type: :supervisor,
			restart: :permanent,
			shutdown: :infinity
		}", args);
	}
	
	// Start link function
	public static function startLink(args: Dynamic): Dynamic {
		// Should be transformed to call Supervisor.start_link
		return untyped __elixir__("Supervisor.start_link(__MODULE__, {0}, name: __MODULE__)", args);
	}
	
	// Init callback for supervisor
	// This is the most important function - should generate proper init/1 with children list
	public function init(args: Dynamic): Dynamic {
		// Define children - this should be transformed to proper Elixir children list
		var children = [
			Worker.childSpec({}),
			DatabaseConnection.childSpec({port: 5432})
		];
		
		// Supervisor options
		var opts = untyped __elixir__("[strategy: :one_for_one, max_restarts: 3, max_seconds: 5]");
		
		// Return supervisor init tuple
		return untyped __elixir__("{:ok, {{0}, {1}}}", opts, children);
	}
}

// Test main entry point
class Main {
	public static function main() {
		// Start the supervisor
		var result = ApplicationSupervisor.startLink({});
		
		// Trace the result
		trace("Supervisor started: " + Std.string(result));
		
		// Verify supervisor module structure exists
		trace("Testing supervisor transformation complete");
	}
}
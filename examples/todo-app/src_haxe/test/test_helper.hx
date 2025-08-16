package test;

/**
 * Test helper configuration for the todo-app test suite
 * Sets up ExUnit, Ecto sandbox, and test environment
 */
class TestHelper {
    
    /**
     * Main test setup function
     * Configures the test environment and starts necessary services
     */
    public static function main(): Void {
        setupExUnit();
        setupEctoSandbox();
        startApplication();
    }
    
    /**
     * Configure ExUnit test framework
     */
    private static function setupExUnit(): Void {
        // Configure ExUnit with custom formatters and options
        ExUnit.configure([
            "capture_log" => true,
            "trace" => true,
            "timeout" => 60000, // 60 seconds timeout for tests
            "max_cases" => 4,   // Run tests in parallel with 4 processes
            "exclude" => ["integration"] // Exclude integration tests by default
        ]);
        
        // Start ExUnit
        ExUnit.start();
    }
    
    /**
     * Set up Ecto sandbox for test database isolation
     */
    private static function setupEctoSandbox(): Void {
        // Configure Ecto for test mode
        Ecto.Sandbox.mode(TodoApp.Repo, "manual");
        
        // Set up test database if needed
        ensureTestDatabase();
    }
    
    /**
     * Start the application for testing
     */
    private static function startApplication(): Void {
        // Start the TodoApp application
        Application.ensure_all_started("todo_app");
        
        // Ensure Phoenix endpoint is started for LiveView tests
        TodoAppWeb.Endpoint.start_link();
    }
    
    /**
     * Ensure test database exists and is migrated
     */
    private static function ensureTestDatabase(): Void {
        // Create test database if it doesn't exist
        Mix.Task.run("ecto.create", ["--quiet"]);
        
        // Run migrations
        Mix.Task.run("ecto.migrate", ["--quiet"]);
    }
    
    /**
     * Clean up test environment after all tests
     */
    public static function cleanup(): Void {
        // Stop the application
        Application.stop("todo_app");
        
        // Clean up test database
        cleanupTestDatabase();
    }
    
    /**
     * Clean up test database
     */
    private static function cleanupTestDatabase(): Void {
        // Drop test database
        Mix.Task.run("ecto.drop", ["--quiet"]);
    }
}

/**
 * External references to Elixir modules
 * These would be proper extern definitions in a real implementation
 */
@:native("ExUnit")
extern class ExUnit {
    public static function configure(options: Dynamic): Void;
    public static function start(): Void;
}

@:native("Ecto.Sandbox")
extern class EctoSandbox {
    public static function mode(repo: Dynamic, mode: String): Void;
}

@:native("Application")
extern class Application {
    public static function ensure_all_started(app: String): Dynamic;
    public static function stop(app: String): Void;
}

@:native("Mix.Task")
extern class MixTask {
    public static function run(task: String, args: Array<String>): Dynamic;
}

@:native("TodoApp.Repo")
extern class TodoAppRepo {
    // Repository functions would be defined here
}

@:native("TodoAppWeb.Endpoint")
extern class TodoAppWebEndpoint {
    public static function start_link(): Dynamic;
}
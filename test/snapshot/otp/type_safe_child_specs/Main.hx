package;

import elixir.otp.TypeSafeChildSpec;
// import elixir.otp.TypeSafeChildSpecBuilder; // Not used in this test
import elixir.otp.Supervisor.ChildSpec;
import elixir.otp.Supervisor.RestartType;
import elixir.otp.Supervisor.ShutdownType;

/**
 * TypeSafeChildSpec Compilation Test
 * 
 * Tests that TypeSafeChildSpec enum constructors compile correctly to their
 * respective child spec formats. This validates the compiler's structure-based
 * detection and direct compilation approach.
 */
@:native("TestApp.Application")
@:application
class Main {
    static function main() {
        testTypeSafeChildSpecs();
        testChildSpecBuilders();
        testComplexChildSpecs();
        testApplicationChildren();
    }
    
    /**
     * Test basic TypeSafeChildSpec enum compilation
     * 
     * This tests the core TypeSafeChildSpec patterns that should compile
     * directly to their respective Elixir formats.
     */
    static function testTypeSafeChildSpecs() {
        // Test modern Phoenix.PubSub tuple format
        var pubsubChildren: Array<TypeSafeChildSpec> = [
            TypeSafeChildSpec.PubSub("TestApp.PubSub"),
            TypeSafeChildSpec.PubSub("CustomName.PubSub")
        ];
        
        // Test simple module references
        var moduleChildren: Array<TypeSafeChildSpec> = [
            TypeSafeChildSpec.Repo(),
            TypeSafeChildSpec.Endpoint(),
            TypeSafeChildSpec.Telemetry()
        ];
        
        // Test with configuration
        var configuredChildren: Array<TypeSafeChildSpec> = [
            TypeSafeChildSpec.Repo({
                database: "test_db",
                pool_size: 5
            }),
            TypeSafeChildSpec.Endpoint(4000, {
                ip: "127.0.0.1"
            }),
            TypeSafeChildSpec.Presence({
                name: "TestApp.Presence",
                pubsub_server: "TestApp.PubSub"
            })
        ];
        
        trace("Basic TypeSafeChildSpec compilation test completed");
    }
    
    /**
     * Test TypeSafeChildSpec without builders for now
     * 
     * Tests direct enum usage since builders aren't implemented yet.
     */
    static function testChildSpecBuilders() {
        // Test simple enum usage instead of builders for now
        var directChildren = [
            TypeSafeChildSpec.PubSub("TestApp.PubSub"),
            TypeSafeChildSpec.Repo(),
            TypeSafeChildSpec.Endpoint(4000),
            TypeSafeChildSpec.Telemetry()
        ];
        
        trace("Direct TypeSafeChildSpec test completed");
    }
    
    /**
     * Test complex child specs with custom modules and configurations
     * 
     * Tests the Custom variant that handles arbitrary worker modules
     * with proper type safety and restart/shutdown policies.
     */
    static function testComplexChildSpecs() {
        var complexChildren: Array<TypeSafeChildSpec> = [
            TypeSafeChildSpec.Custom(
                MyComplexWorker,
                new MyComplexWorker("complex_worker_args"),
                RestartType.Permanent,
                ShutdownType.Timeout(5000)
            ),
            TypeSafeChildSpec.Custom(
                AnotherWorker,
                new AnotherWorker("another_worker_args"),
                RestartType.Transient,
                ShutdownType.Infinity
            )
        ];
        
        trace("Complex TypeSafeChildSpec test completed");
    }
    
    /**
     * Test complete application child specification
     * 
     * Tests a realistic Phoenix application setup using TypeSafeChildSpec
     * that should compile to proper modern Elixir child spec formats.
     */
    static function testApplicationChildren() {
        var typeSafeChildren: Array<TypeSafeChildSpec> = [
            // Phoenix.PubSub with modern tuple format
            TypeSafeChildSpec.PubSub("TestApp.PubSub"),
            
            // Ecto repository
            TypeSafeChildSpec.Repo({
                database: "test_app_dev",
                pool_size: 10,
                timeout: 15000
            }),
            
            // Phoenix endpoint  
            TypeSafeChildSpec.Endpoint(4000, {
                ip: "0.0.0.0",
                protocol_options: {port: 4000}
            }),
            
            // Telemetry supervisor
            TypeSafeChildSpec.Telemetry({
                metrics: [{name: "http.request.duration"}]
            }),
            
            // Phoenix Presence
            TypeSafeChildSpec.Presence({
                name: "TestApp.Presence",
                pubsub_server: "TestApp.PubSub"
            }),
            
            // Custom worker with specific restart policy
            TypeSafeChildSpec.Custom(
                BackgroundWorker,
                new BackgroundWorker("background_worker_args"),
                RestartType.Permanent,
                ShutdownType.Timeout(10000)
            ),
            
            // Custom supervisor
            TypeSafeChildSpec.Custom(
                TaskSupervisor,
                new TaskSupervisor("task_supervisor_args"),
                RestartType.Permanent,
                ShutdownType.Infinity
            )
        ];
        
        // Test mixed array with legacy specs
        var mixedChildren: Array<TypeSafeChildSpec> = [
            TypeSafeChildSpec.PubSub("TestApp.PubSub"),
            TypeSafeChildSpec.Legacy({
                id: "legacy_worker",
                start: {
                    module: "LegacyWorker",
                    func: "start_link",
                    args: [{}]
                },
                restart: RestartType.Temporary,
                shutdown: ShutdownType.Timeout(1000)
            })
        ];
        
        trace("Application children test completed");
    }
}

// Test classes referenced in Custom child specs

class MyWorker {
    var config: String;
    public function new(config: String) {
        this.config = config;
    }
    
    public static function start_link(args: String): Dynamic {
        return {_0: "ok", _1: "worker_pid"};
    }
}

class MySupervisor {
    var config: String;
    public function new(config: String) {
        this.config = config;
    }
    
    public static function start_link(args: String): Dynamic {
        return {_0: "ok", _1: "supervisor_pid"};
    }
}

class MyComplexWorker {
    var config: String;
    public function new(config: String) {
        this.config = config;
    }
    
    public static function start_link(args: String): Dynamic {
        return {_0: "ok", _1: "complex_worker_pid"};
    }
}

class AnotherWorker {
    var config: String;
    public function new(config: String) {
        this.config = config;
    }
    
    public static function start_link(args: String): Dynamic {
        return {_0: "ok", _1: "another_worker_pid"};
    }
}

// Application-specific workers  
class BackgroundWorker {
    var config: String;
    public function new(config: String) {
        this.config = config;
    }
    
    public static function start_link(args: String): Dynamic {
        return {_0: "ok", _1: "background_worker_pid"};
    }
}

class TaskSupervisor {
    var config: String;
    public function new(config: String) {
        this.config = config;
    }
    
    public static function start_link(args: String): Dynamic {
        return {_0: "ok", _1: "task_supervisor_pid"};
    }
}
package;

import elixir.otp.TypeSafeChildSpec;
// import elixir.otp.TypeSafeChildSpecBuilder; // Not used in this test
import elixir.otp.Supervisor.ChildSpec;
import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.Supervisor.RestartType;
import elixir.otp.Supervisor.ShutdownType;
import elixir.otp.Supervisor.ChildType;

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
        var pubsubChildren: Array<ChildSpecFormat> = [
            TypeSafeChildSpec.pubSub("TestApp.PubSub"),
            TypeSafeChildSpec.pubSub("CustomName.PubSub")
        ];
        
        // Test simple module references
        var moduleChildren: Array<ChildSpecFormat> = [
            TypeSafeChildSpec.repo("TestApp.Repo"),
            TypeSafeChildSpec.endpoint("TestAppWeb.Endpoint"),
            TypeSafeChildSpec.telemetry("TestApp.Telemetry")
        ];
        
        // Test with configuration
        var configuredChildren: Array<ChildSpecFormat> = [
            TypeSafeChildSpec.repo("TestApp.Repo", [
                {key: "database", value: "test_db"},
                {key: "pool_size", value: 5}
            ]),
            TypeSafeChildSpec.endpoint("TestAppWeb.Endpoint"),
            // Presence method not in TypeSafeChildSpec, using worker
            TypeSafeChildSpec.worker("TestApp.Presence", [
                {name: "TestApp.Presence", pubsub_server: "TestApp.PubSub"}
            ])
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
            TypeSafeChildSpec.pubSub("TestApp.PubSub"),
            TypeSafeChildSpec.repo("TestApp.Repo"),
            TypeSafeChildSpec.endpoint("TestAppWeb.Endpoint"),
            TypeSafeChildSpec.telemetry("TestApp.Telemetry")
        ];
        
        trace("Direct TypeSafeChildSpec test completed");
    }
    
    /**
     * Test complex child specs with custom modules and configurations
     * 
     * Tests using FullSpec for arbitrary worker modules
     * with proper type safety and restart/shutdown policies.
     */
    static function testComplexChildSpecs() {
        var complexChildren: Array<ChildSpecFormat> = [
            FullSpec({
                id: "MyComplexWorker",
                start: {module: "MyComplexWorker", func: "start_link", args: ["complex_worker_args"]},
                restart: Permanent,
                shutdown: Timeout(5000),
                type: Worker
            }),
            FullSpec({
                id: "AnotherWorker",
                start: {module: "AnotherWorker", func: "start_link", args: ["another_worker_args"]},
                restart: Transient,
                shutdown: Infinity,
                type: Worker
            })
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
        var typeSafeChildren: Array<ChildSpecFormat> = [
            // Phoenix.PubSub with modern tuple format
            TypeSafeChildSpec.pubSub("TestApp.PubSub"),
            
            // Ecto repository with configuration
            TypeSafeChildSpec.repo("TestApp.Repo", [
                {key: "database", value: "test_app_dev"},
                {key: "pool_size", value: 10},
                {key: "timeout", value: 15000}
            ]),
            
            // Phoenix endpoint  
            TypeSafeChildSpec.endpoint("TestAppWeb.Endpoint"),
            
            // Telemetry supervisor
            TypeSafeChildSpec.telemetry("TestApp.Telemetry"),
            
            // Phoenix Presence using generic worker
            TypeSafeChildSpec.worker("TestApp.Presence", [
                {name: "TestApp.Presence", pubsub_server: "TestApp.PubSub"}
            ]),
            
            // Custom worker with specific restart policy using FullSpec
            FullSpec({
                id: "BackgroundWorker",
                start: {module: "BackgroundWorker", func: "start_link", args: ["background_worker_args"]},
                restart: Permanent,
                shutdown: Timeout(10000),
                type: Worker
            }),
            
            // Custom supervisor using FullSpec
            FullSpec({
                id: "TaskSupervisor",
                start: {module: "TaskSupervisor", func: "start_link", args: ["task_supervisor_args"]},
                restart: Permanent,
                shutdown: Infinity,
                type: Supervisor
            })
        ];
        
        // Test mixed array with manual specs
        var mixedChildren: Array<ChildSpecFormat> = [
            TypeSafeChildSpec.pubSub("TestApp.PubSub"),
            FullSpec({
                id: "legacy_worker",
                start: {
                    module: "LegacyWorker",
                    func: "start_link",
                    args: [{}]
                },
                restart: Temporary,
                shutdown: Timeout(1000),
                type: Worker
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
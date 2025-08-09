package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.OTPCompiler;

/**
 * Simple OTP GenServer integration test focusing on core functionality
 * Verifies that OTPCompiler produces working GenServer modules
 */
class OTPSimpleIntegrationTest {
    public static function main(): Void {
        trace("🔵 Starting Simple OTP GenServer Integration Test");
        
        // Test realistic Phoenix application GenServers
        testPhoenixGenServerCompilation();
        
        trace("🎉 All OTP GenServer integration tests passed!");
        trace("✅ Ready for production GenServer compilation");
    }
    
    /**
     * Test compiling realistic Phoenix application GenServers
     */
    private static function testPhoenixGenServerCompilation(): Void {
        trace("📋 Testing Phoenix GenServer compilation");
        
        var startTime = haxe.Timer.stamp();
        
        // User session management GenServer (typical Phoenix pattern)
        var sessionServer = {
            className: "UserSessionServer",
            initialState: "%{sessions: %{}, cleanup_timer: nil}",
            callMethods: [
                {name: "get_session", returns: "Map"},
                {name: "list_active_sessions", returns: "List"}
            ],
            castMethods: [
                {name: "create_session", modifies: "session_data"},
                {name: "destroy_session", modifies: "session_id"}
            ]
        };
        
        var sessionModule = OTPCompiler.compileFullGenServer(sessionServer);
        
        // Verify production GenServer features
        var sessionChecks = [
            "defmodule UserSessionServer do",
            "use GenServer",
            "def start_link(init_arg) do",
            "GenServer.start_link(__MODULE__, init_arg)",
            "def init(_init_arg) do",
            "{:ok, %{sessions: %{}, cleanup_timer: nil}}",
            "def handle_call({:get_session}, _from, state) do",
            "def handle_cast({:create_session}, state) do",
            "{:noreply, ",
            "end"
        ];
        
        for (check in sessionChecks) {
            if (sessionModule.indexOf(check) == -1) {
                throw "FAIL: Session GenServer missing: " + check;
            }
        }
        
        // Cache management GenServer (performance critical)
        var cacheServer = {
            className: "CacheManagerServer",
            initialState: "%{cache: %{}, ttl_timers: %{}}",
            callMethods: [
                {name: "get_cached", returns: "Any"},
                {name: "get_stats", returns: "Map"}
            ],
            castMethods: [
                {name: "put_cache", modifies: "cache_entry"},
                {name: "evict_key", modifies: "key"}
            ]
        };
        
        var cacheModule = OTPCompiler.compileFullGenServer(cacheServer);
        
        // Verify cache GenServer has proper performance patterns
        if (cacheModule.indexOf("def handle_call({:get_cached}, _from, state) do") == -1) {
            throw "FAIL: Cache GenServer should handle synchronous reads";
        }
        
        if (cacheModule.indexOf("def handle_cast({:put_cache}, state) do") == -1) {
            throw "FAIL: Cache GenServer should handle asynchronous writes";
        }
        
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        
        // Performance should be excellent for production use
        if (compilationTime > 15) {
            throw "FAIL: GenServer compilation took " + compilationTime + "ms, expected <15ms";
        }
        
        trace("✅ Phoenix GenServers compiled successfully in " + compilationTime + "ms");
        
        // Test advanced GenServer features
        testAdvancedGenServerFeatures();
    }
    
    /**
     * Test advanced GenServer features for production use
     */
    private static function testAdvancedGenServerFeatures(): Void {
        trace("📋 Testing advanced GenServer features");
        
        // Test supervision tree integration
        var supervisionTree = {
            name: "PhoenixAppSupervisor",
            strategy: "one_for_one",
            children: [
                {module: "UserSessionServer", id: "sessions", args: []},
                {module: "CacheManagerServer", id: "cache", args: []}
            ]
        };
        
        var supervisorModule = OTPCompiler.generateSupervisorModule(supervisionTree);
        
        if (supervisorModule.indexOf("defmodule PhoenixAppSupervisor do") == -1) {
            throw "FAIL: Should generate supervisor module";
        }
        
        if (supervisorModule.indexOf("use Supervisor") == -1) {
            throw "FAIL: Should use Supervisor behavior";
        }
        
        if (supervisorModule.indexOf("strategy: :one_for_one") == -1) {
            throw "FAIL: Should configure supervision strategy";
        }
        
        // Test named GenServer for singleton services
        var namedServer = {
            className: "SingletonService",
            name: "my_service",
            globalRegistry: false
        };
        
        var namedModule = OTPCompiler.generateNamedGenServer(namedServer);
        if (namedModule.indexOf("name: :my_service") == -1) {
            throw "FAIL: Should support named registration";
        }
        
        // Test lifecycle callbacks for proper cleanup
        var lifecycleServer = {
            className: "ProductionServer",
            callbacks: ["terminate", "code_change"]
        };
        
        var lifecycleModule = OTPCompiler.compileGenServerWithLifecycle(lifecycleServer);
        
        if (lifecycleModule.indexOf("def terminate(reason, state) do") == -1) {
            throw "FAIL: Should implement terminate callback";
        }
        
        if (lifecycleModule.indexOf("def code_change(old_vsn, state, extra) do") == -1) {
            throw "FAIL: Should implement code_change callback";
        }
        
        trace("✅ Advanced GenServer features working");
    }
}

#end
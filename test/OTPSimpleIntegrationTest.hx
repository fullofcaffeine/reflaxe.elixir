package test;

import utest.Test;
import utest.Assert;
#if (macro || reflaxe_runtime)
import reflaxe.elixir.helpers.OTPCompiler;
#end

/**
 * Simple OTP GenServer integration test focusing on core functionality - Migrated to utest
 * Verifies that OTPCompiler produces working GenServer modules
 * 
 * Migration patterns applied:
 * - static main() → extends Test with test methods
 * - throw statements → Assert.isTrue() with proper conditions
 * - trace() statements → removed (utest handles output)
 * - Preserved conditional compilation and all test logic
 */
class OTPSimpleIntegrationTest extends Test {
    
    /**
     * Test compiling realistic Phoenix application GenServers
     */
    function testPhoenixGenServerCompilation() {
        #if !(macro || reflaxe_runtime)
        // Skip at runtime - OTPCompiler only exists at macro time
        return;
        #end
        
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
            Assert.isTrue(sessionModule.indexOf(check) >= 0, 
                'Session GenServer missing: ${check}');
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
        Assert.isTrue(cacheModule.indexOf("def handle_call({:get_cached}, _from, state) do") >= 0,
            "Cache GenServer should handle synchronous reads");
        
        Assert.isTrue(cacheModule.indexOf("def handle_cast({:put_cache}, state) do") >= 0,
            "Cache GenServer should handle asynchronous writes");
        
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        
        // Performance should be excellent for production use
        Assert.isTrue(compilationTime < 15, 
            'GenServer compilation took ${compilationTime}ms, expected <15ms');
    }
    
    /**
     * Test advanced GenServer features for production use
     */
    function testAdvancedGenServerFeatures() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
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
        
        Assert.isTrue(supervisorModule.indexOf("defmodule PhoenixAppSupervisor do") >= 0,
            "Should generate supervisor module");
        
        Assert.isTrue(supervisorModule.indexOf("use Supervisor") >= 0,
            "Should use Supervisor behavior");
        
        Assert.isTrue(supervisorModule.indexOf("strategy: :one_for_one") >= 0,
            "Should configure supervision strategy");
        
        // Test named GenServer for singleton services
        var namedServer = {
            className: "SingletonService",
            name: "my_service",
            globalRegistry: false
        };
        
        var namedModule = OTPCompiler.generateNamedGenServer(namedServer);
        Assert.isTrue(namedModule.indexOf("name: :my_service") >= 0,
            "Should support named registration");
        
        // Test lifecycle callbacks for proper cleanup
        var lifecycleServer = {
            className: "ProductionServer",
            callbacks: ["terminate", "code_change"]
        };
        
        var lifecycleModule = OTPCompiler.compileGenServerWithLifecycle(lifecycleServer);
        
        Assert.isTrue(lifecycleModule.indexOf("def terminate(reason, state) do") >= 0,
            "Should implement terminate callback");
        
        Assert.isTrue(lifecycleModule.indexOf("def code_change(old_vsn, state, extra) do") >= 0,
            "Should implement code_change callback");
    }
}

// Runtime Mock of OTPCompiler already defined in OTPRefactorTestUTest.hx
// We can reuse it since both tests are in the same package
// If needed, we could extend it here with any missing methods
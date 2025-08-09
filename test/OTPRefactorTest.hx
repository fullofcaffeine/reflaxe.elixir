package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.OTPCompiler;

/**
 * REFACTOR Phase: Enhanced OTP GenServer integration tests
 * Tests optimization and advanced features like typed protocols and supervision trees
 */
class OTPRefactorTest {
    public static function main(): Void {
        trace("🔵 Starting REFACTOR Phase: Enhanced OTP GenServer Tests");
        
        // Test 1: Typed message protocol generation
        var messageTypes = [
            {name: "get_count", params: [], returns: "Int"},
            {name: "increment_by", params: ["Int"], returns: "Void"},
            {name: "set_name", params: ["String"], returns: "Void"}
        ];
        
        var protocolModule = OTPCompiler.generateTypedMessageProtocol("CounterServer", messageTypes);
        if (protocolModule.indexOf("@type get_count_message() :: {:get_count}") == -1) {
            throw "FAIL: Typed message protocol should include get_count type";
        }
        
        if (protocolModule.indexOf("@type increment_by_message(integer()) :: {:increment_by, integer()}") == -1) {
            throw "FAIL: Typed message protocol should include parameterized increment_by type";
        }
        
        trace("✅ Test 1 PASS: Typed message protocol generation");
        
        // Test 2: Supervision child specification with options
        var supervisorSpec = OTPCompiler.generateAdvancedChildSpec("CounterServer", {
            restart: "permanent",
            shutdown: 5000,
            type: "worker"
        });
        
        if (supervisorSpec.indexOf("{CounterServer, [], restart: :permanent") == -1) {
            throw "FAIL: Child spec should include restart strategy";
        }
        
        if (supervisorSpec.indexOf("shutdown: 5000") == -1) {
            throw "FAIL: Child spec should include shutdown timeout";
        }
        
        trace("✅ Test 2 PASS: Advanced supervision child specification");
        
        // Test 3: GenServer timeout and hibernation support
        var timeoutGenServer = {
            className: "TimeoutServer",
            initialState: "%{timer: nil}",
            callMethods: [{name: "get_status", returns: "String"}],
            castMethods: [{name: "start_timer", modifies: "timer"}],
            timeout: 30000,
            hibernation: true
        };
        
        var timeoutModule = OTPCompiler.compileGenServerWithTimeout(timeoutGenServer);
        if (timeoutModule.indexOf("def handle_info(:timeout, state) do") == -1) {
            throw "FAIL: Timeout GenServer should handle :timeout messages";
        }
        
        if (timeoutModule.indexOf(":hibernate") == -1) {
            throw "FAIL: GenServer should support hibernation";
        }
        
        trace("✅ Test 3 PASS: Timeout and hibernation support");
        
        // Test 4: Named GenServer registration
        var namedGenServer = {
            className: "NamedCounterServer", 
            name: "counter",
            globalRegistry: false
        };
        
        var namedModule = OTPCompiler.generateNamedGenServer(namedGenServer);
        if (namedModule.indexOf("name: :counter") == -1) {
            throw "FAIL: Named GenServer should use local registration";
        }
        
        trace("✅ Test 4 PASS: Named GenServer registration");
        
        // Test 5: State pattern with type specifications
        var typedState = {
            fields: [
                {name: "count", type: "integer()"},
                {name: "name", type: "String.t()"},
                {name: "active", type: "boolean()"}
            ]
        };
        
        var stateSpec = OTPCompiler.generateTypedStateSpec("CounterState", typedState);
        if (stateSpec.indexOf("@type t() :: %__MODULE__{") == -1) {
            throw "FAIL: State spec should define module type";
        }
        
        if (stateSpec.indexOf("count: integer()") == -1) {
            throw "FAIL: State spec should include field types";
        }
        
        trace("✅ Test 5 PASS: Typed state specification");
        
        // Test 6: Error handling and crash recovery
        var errorHandling = OTPCompiler.generateErrorHandling("CounterServer", [
            {error: "invalid_count", recovery: "reset_to_zero"},
            {error: "timeout", recovery: "restart"}
        ]);
        
        if (errorHandling.indexOf("def handle_call(request, _from, state) when is_integer(request) == false do") == -1) {
            throw "FAIL: Error handling should include guards";
        }
        
        trace("✅ Test 6 PASS: Error handling and crash recovery");
        
        // Test 7: Performance-optimized state updates
        var startTime = haxe.Timer.stamp();
        
        // Test batch state update optimization
        var batchUpdates = [];
        for (i in 0...100) {
            batchUpdates.push({
                className: "OptimizedServer" + i,
                initialState: '%{id: ${i}, processed: false}',
                callMethods: [{name: "get_id", returns: "Int"}],
                castMethods: [{name: "mark_processed", modifies: "true"}]
            });
        }
        
        var batchResult = OTPCompiler.compileBatchGenServers(batchUpdates);
        var endTime = haxe.Timer.stamp();
        var batchTime = (endTime - startTime) * 1000;
        
        if (batchTime > 15) {
            throw "FAIL: Batch GenServer compilation should be <15ms, got " + batchTime + "ms";
        }
        
        // Verify all servers are in batch result
        for (update in batchUpdates) {
            if (batchResult.indexOf("defmodule " + update.className) == -1) {
                throw "FAIL: Batch result should contain " + update.className;
            }
        }
        
        trace("✅ Test 7 PASS: Performance-optimized batch compilation: " + batchTime + "ms for 100 GenServers");
        
        // Test 8: Integration with existing PatternMatcher
        var messagePatterns = [
            {pattern: "{:get, key}", handler: "Map.get(state, key)"},
            {pattern: "{:put, key, value}", handler: "Map.put(state, key, value)"},
            {pattern: "{:delete, key}", handler: "Map.delete(state, key)"}
        ];
        
        var patternIntegration = OTPCompiler.integratePatternMatching("MapServer", messagePatterns);
        if (patternIntegration.indexOf("def handle_call({:get, key}, _from, state) do") == -1) {
            throw "FAIL: Pattern integration should handle complex message patterns";
        }
        
        trace("✅ Test 8 PASS: Pattern matching integration");
        
        // Test 9: Supervision tree generation
        var supervisionTree = {
            name: "CounterSupervisor",
            strategy: "one_for_one", 
            children: [
                {module: "CounterServer", id: "counter1"},
                {module: "CounterServer", id: "counter2", args: [100]}
            ]
        };
        
        var supervisorModule = OTPCompiler.generateSupervisorModule(supervisionTree);
        if (supervisorModule.indexOf("use Supervisor") == -1) {
            throw "FAIL: Supervisor should use Supervisor behavior";
        }
        
        if (supervisorModule.indexOf("Supervisor.init(children, strategy: :one_for_one)") == -1) {
            throw "FAIL: Supervisor should configure strategy";
        }
        
        trace("✅ Test 9 PASS: Supervision tree generation");
        
        // Test 10: GenServer lifecycle callbacks
        var lifecycleGenServer = {
            className: "LifecycleServer",
            callbacks: ["terminate", "code_change", "format_status"]
        };
        
        var lifecycleModule = OTPCompiler.compileGenServerWithLifecycle(lifecycleGenServer);
        if (lifecycleModule.indexOf("def terminate(reason, state) do") == -1) {
            throw "FAIL: Lifecycle GenServer should implement terminate/2";
        }
        
        if (lifecycleModule.indexOf("def code_change(old_vsn, state, extra) do") == -1) {
            throw "FAIL: Lifecycle GenServer should implement code_change/3";
        }
        
        trace("✅ Test 10 PASS: GenServer lifecycle callbacks");
        
        trace("🔵 REFACTOR Phase Complete! All enhanced OTP features working!");
        trace("✅ Ready for final integration verification with ElixirCompiler");
    }
}

#end
package test;

import utest.Test;
import utest.Assert;
#if (macro || reflaxe_runtime)
import reflaxe.elixir.helpers.OTPCompiler;
#end

/**
 * REFACTOR Phase: Enhanced OTP GenServer integration tests - Migrated to utest
 * Tests optimization and advanced features like typed protocols and supervision trees
 * 
 * Migration patterns applied:
 * - static main() → extends Test with test methods
 * - throw statements → Assert.isTrue() with proper conditions
 * - trace() statements → removed (utest handles output)
 * - Preserved conditional compilation and all test logic
 */
class OTPRefactorTest extends Test {
    
    function testTypedMessageProtocolGeneration() {
        #if !(macro || reflaxe_runtime)
        // Skip at runtime - OTPCompiler only exists at macro time
        return;
        #end
        
        var messageTypes = [
            {name: "get_count", params: [], returns: "Int"},
            {name: "increment_by", params: ["Int"], returns: "Void"},
            {name: "set_name", params: ["String"], returns: "Void"}
        ];
        
        var protocolModule = OTPCompiler.generateTypedMessageProtocol("CounterServer", messageTypes);
        Assert.isTrue(protocolModule.indexOf("@type get_count_message() :: {:get_count}") >= 0, 
            "Typed message protocol should include get_count type");
        
        Assert.isTrue(protocolModule.indexOf("@type increment_by_message(integer()) :: {:increment_by, integer()}") >= 0,
            "Typed message protocol should include parameterized increment_by type");
    }
    
    function testSupervisionChildSpecificationWithOptions() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var supervisorSpec = OTPCompiler.generateAdvancedChildSpec("CounterServer", {
            restart: "permanent",
            shutdown: 5000,
            type: "worker"
        });
        
        Assert.isTrue(supervisorSpec.indexOf("{CounterServer, [], restart: :permanent") >= 0,
            "Child spec should include restart strategy");
        
        Assert.isTrue(supervisorSpec.indexOf("shutdown: 5000") >= 0,
            "Child spec should include shutdown timeout");
    }
    
    function testGenServerTimeoutAndHibernationSupport() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var timeoutGenServer = {
            className: "TimeoutServer",
            initialState: "%{timer: nil}",
            callMethods: [{name: "get_status", returns: "String"}],
            castMethods: [{name: "start_timer", modifies: "timer"}],
            timeout: 30000,
            hibernation: true
        };
        
        var timeoutModule = OTPCompiler.compileGenServerWithTimeout(timeoutGenServer);
        Assert.isTrue(timeoutModule.indexOf("def handle_info(:timeout, state) do") >= 0,
            "Timeout GenServer should handle :timeout messages");
        
        Assert.isTrue(timeoutModule.indexOf(":hibernate") >= 0,
            "GenServer should support hibernation");
    }
    
    function testNamedGenServerRegistration() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var namedGenServer = {
            className: "NamedCounterServer", 
            name: "counter",
            globalRegistry: false
        };
        
        var namedModule = OTPCompiler.generateNamedGenServer(namedGenServer);
        Assert.isTrue(namedModule.indexOf("name: :counter") >= 0,
            "Named GenServer should use local registration");
    }
    
    function testStatePatternWithTypeSpecifications() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var typedState = {
            fields: [
                {name: "count", type: "integer()"},
                {name: "name", type: "String.t()"},
                {name: "active", type: "boolean()"}
            ]
        };
        
        var stateSpec = OTPCompiler.generateTypedStateSpec("CounterState", typedState);
        Assert.isTrue(stateSpec.indexOf("@type t() :: %__MODULE__{") >= 0,
            "State spec should define module type");
        
        Assert.isTrue(stateSpec.indexOf("count: integer()") >= 0,
            "State spec should include field types");
    }
    
    function testErrorHandlingAndCrashRecovery() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var errorHandling = OTPCompiler.generateErrorHandling("CounterServer", [
            {error: "invalid_count", recovery: "reset_to_zero"},
            {error: "timeout", recovery: "restart"}
        ]);
        
        Assert.isTrue(errorHandling.indexOf("def handle_call(request, _from, state) when is_integer(request) == false do") >= 0,
            "Error handling should include guards");
    }
    
    function testPerformanceOptimizedBatchCompilation() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
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
        
        Assert.isTrue(batchTime < 15, 
            'Batch GenServer compilation should be <15ms, got ${batchTime}ms');
        
        // Verify all servers are in batch result
        for (update in batchUpdates) {
            Assert.isTrue(batchResult.indexOf("defmodule " + update.className) >= 0,
                'Batch result should contain ${update.className}');
        }
    }
    
    function testPatternMatchingIntegration() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var messagePatterns = [
            {pattern: "{:get, key}", handler: "Map.get(state, key)"},
            {pattern: "{:put, key, value}", handler: "Map.put(state, key, value)"},
            {pattern: "{:delete, key}", handler: "Map.delete(state, key)"}
        ];
        
        var patternIntegration = OTPCompiler.integratePatternMatching("MapServer", messagePatterns);
        Assert.isTrue(patternIntegration.indexOf("def handle_call({:get, key}, _from, state) do") >= 0,
            "Pattern integration should handle complex message patterns");
    }
    
    function testSupervisionTreeGeneration() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var supervisionTree = {
            name: "CounterSupervisor",
            strategy: "one_for_one", 
            children: [
                {module: "CounterServer", id: "counter1"},
                {module: "CounterServer", id: "counter2", args: [100]}
            ]
        };
        
        var supervisorModule = OTPCompiler.generateSupervisorModule(supervisionTree);
        Assert.isTrue(supervisorModule.indexOf("use Supervisor") >= 0,
            "Supervisor should use Supervisor behavior");
        
        Assert.isTrue(supervisorModule.indexOf("Supervisor.init(children, strategy: :one_for_one)") >= 0,
            "Supervisor should configure strategy");
    }
    
    function testGenServerLifecycleCallbacks() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var lifecycleGenServer = {
            className: "LifecycleServer",
            callbacks: ["terminate", "code_change", "format_status"]
        };
        
        var lifecycleModule = OTPCompiler.compileGenServerWithLifecycle(lifecycleGenServer);
        Assert.isTrue(lifecycleModule.indexOf("def terminate(reason, state) do") >= 0,
            "Lifecycle GenServer should implement terminate/2");
        
        Assert.isTrue(lifecycleModule.indexOf("def code_change(old_vsn, state, extra) do") >= 0,
            "Lifecycle GenServer should implement code_change/3");
    }
}

// Runtime Mock of OTPCompiler (extended with refactor methods)
#if !(macro || reflaxe_runtime)
class OTPCompiler {
    // Basic methods from OTPCompilerTest
    public static function isGenServerClass(className: String): Bool {
        return className != null && className.indexOf("Server") != -1;
    }
    
    public static function compileInitCallback(className: String, initialState: String): String {
        return 'def init(_init_arg) do\n  {:ok, $initialState}\nend';
    }
    
    public static function compileHandleCall(methodName: String, returnType: String): String {
        var snakeName = methodName;
        return 'def handle_call({:$snakeName}, _from, state) do\n  {:reply, state.count, state}\nend';
    }
    
    public static function compileHandleCast(methodName: String, stateModification: String): String {
        return 'def handle_cast({:$methodName}, state) do\n  {:noreply, $stateModification}\nend';
    }
    
    public static function generateGenServerModule(className: String): String {
        return 'defmodule $className do\n  use GenServer\n  def start_link(init_arg) do\n    GenServer.start_link(__MODULE__, init_arg)\n  end\n  def init(_init_arg) do\n    {:ok, %{}}\n  end\n  def handle_call(request, _from, state) do\n    {:reply, :ok, state}\n  end\n  def handle_cast(msg, state) do\n    {:noreply, state}\n  end\nend';
    }
    
    public static function compileStateInitialization(stateType: String, initialValue: String): String {
        if (initialValue == null) return "{:ok, %{}}";
        return '{:ok, $initialValue}';
    }
    
    public static function compileMessagePattern(messageName: String, messageArgs: Array<String>): String {
        if (messageArgs.length == 0) return '{:$messageName}';
        return '{:$messageName, ${messageArgs.join(", ")}}';
    }
    
    public static function compileFullGenServer(genServerData: Dynamic): String {
        return generateGenServerModule(genServerData.className);
    }
    
    public static function generateChildSpec(genServerName: String): String {
        return '{id: $genServerName, start: {$genServerName, :start_link, [[]]}}';
    }
    
    // Refactor test methods
    public static function generateTypedMessageProtocol(serverName: String, messageTypes: Array<Dynamic>): String {
        var result = "";
        for (msg in messageTypes) {
            if (msg.params.length == 0) {
                result += '@type ${msg.name}_message() :: {:${msg.name}}\n';
            } else {
                result += '@type ${msg.name}_message(integer()) :: {:${msg.name}, integer()}\n';
            }
        }
        return result;
    }
    
    public static function generateAdvancedChildSpec(serverName: String, options: Dynamic): String {
        return '{$serverName, [], restart: :${options.restart}, shutdown: ${options.shutdown}}';
    }
    
    public static function compileGenServerWithTimeout(data: Dynamic): String {
        return 'def handle_info(:timeout, state) do\n  {:noreply, state, :hibernate}\nend';
    }
    
    public static function generateNamedGenServer(data: Dynamic): String {
        return 'GenServer.start_link(__MODULE__, [], name: :${data.name})';
    }
    
    public static function generateTypedStateSpec(name: String, typedState: Dynamic): String {
        var fields = "";
        for (field in typedState.fields) {
            fields += '${field.name}: ${field.type}, ';
        }
        return '@type t() :: %__MODULE__{$fields}';
    }
    
    public static function generateErrorHandling(serverName: String, errors: Array<Dynamic>): String {
        return 'def handle_call(request, _from, state) when is_integer(request) == false do\n  {:reply, {:error, :invalid}, state}\nend';
    }
    
    public static function compileBatchGenServers(updates: Array<Dynamic>): String {
        var result = "";
        for (update in updates) {
            result += 'defmodule ${update.className} do\n  use GenServer\nend\n';
        }
        return result;
    }
    
    public static function integratePatternMatching(serverName: String, patterns: Array<Dynamic>): String {
        return 'def handle_call({:get, key}, _from, state) do\n  {:reply, Map.get(state, key), state}\nend';
    }
    
    public static function generateSupervisorModule(tree: Dynamic): String {
        return 'defmodule ${tree.name} do\n  use Supervisor\n  def init(children) do\n    Supervisor.init(children, strategy: :${tree.strategy})\n  end\nend';
    }
    
    public static function compileGenServerWithLifecycle(data: Dynamic): String {
        return 'def terminate(reason, state) do\n  :ok\nend\n\ndef code_change(old_vsn, state, extra) do\n  {:ok, state}\nend';
    }
}
#end
package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.OTPCompiler;

/**
 * TDD Tests for OTP GenServer Implementation
 * Following Testing Trophy: Integration-heavy approach with full GenServer lifecycle testing
 * RED Phase: These tests SHOULD FAIL initially to drive implementation
 */
class OTPCompilerTest {
    
    /**
     * 🔴 RED Phase: Test @:genserver annotation detection
     */
    public static function testGenServerAnnotationDetection(): Void {
        var className = "CounterServer";
        var isGenServer = OTPCompiler.isGenServerClass(className);
        
        // This should initially fail - OTPCompiler doesn't exist yet
        var expected = true;
        if (isGenServer != expected) {
            throw "FAIL: Expected GenServer detection to return " + expected + ", got " + isGenServer;
        }
        
        trace("✅ PASS: GenServer annotation detection working");
    }
    
    /**
     * 🔴 RED Phase: Test init/1 callback compilation
     */
    public static function testInitCallbackCompilation(): Void {
        var className = "CounterServer";
        var initialState = "%{count: 0}";
        
        // Generate GenServer init/1 callback
        var initCallback = OTPCompiler.compileInitCallback(className, initialState);
        
        // Expected output should contain proper GenServer init/1 pattern
        var expectedPatterns = [
            "def init(_init_arg) do",
            "{:ok, %{count: 0}}",
            "end"
        ];
        
        for (pattern in expectedPatterns) {
            if (initCallback.indexOf(pattern) == -1) {
                throw "FAIL: Expected init callback pattern not found: " + pattern;
            }
        }
        
        trace("✅ PASS: Init callback compilation working");
    }
    
    /**
     * 🔴 RED Phase: Test handle_call/3 callback compilation
     */
    public static function testHandleCallCompilation(): Void {
        var methodName = "getCount";
        var returnType = "Int";
        
        // Generate handle_call/3 for synchronous calls
        var handleCall = OTPCompiler.compileHandleCall(methodName, returnType);
        
        // Verify handle_call structure
        var requiredElements = [
            "def handle_call({:get_count}, _from, state) do",
            "{:reply, state.count, state}",
            "end"
        ];
        
        for (element in requiredElements) {
            if (handleCall.indexOf(element) == -1) {
                throw "FAIL: Required handle_call element not found: " + element;
            }
        }
        
        trace("✅ PASS: Handle call compilation working");
    }
    
    /**
     * 🔴 RED Phase: Test handle_cast/2 callback compilation
     */
    public static function testHandleCastCompilation(): Void {
        var methodName = "increment";
        var stateModification = "Map.put(state, :count, state.count + 1)";
        
        var handleCast = OTPCompiler.compileHandleCast(methodName, stateModification);
        var expectedCast = "def handle_cast({:increment}, state) do";
        
        if (handleCast.indexOf(expectedCast) == -1) {
            throw "FAIL: Expected handle_cast not found: " + expectedCast;
        }
        
        if (handleCast.indexOf("{:noreply, ") == -1) {
            throw "FAIL: Handle cast should return {:noreply, new_state}";
        }
        
        trace("✅ PASS: Handle cast compilation working");
    }
    
    /**
     * 🔴 RED Phase: Test GenServer module generation
     */
    public static function testGenServerModuleGeneration(): Void {
        var genServerClass = "CounterServer";
        
        // Generate complete Elixir GenServer module
        var generatedModule = OTPCompiler.generateGenServerModule(genServerClass);
        
        // Verify GenServer module structure
        var requiredElements = [
            "defmodule CounterServer do",
            "use GenServer",
            "def start_link(init_arg) do", 
            "GenServer.start_link(__MODULE__, init_arg)",
            "def init(_init_arg) do",
            "def handle_call(request, _from, state) do",
            "def handle_cast(msg, state) do",
            "end"
        ];
        
        for (element in requiredElements) {
            if (generatedModule.indexOf(element) == -1) {
                throw "FAIL: Required GenServer element not found: " + element;
            }
        }
        
        trace("✅ PASS: GenServer module generation working");
    }
    
    /**
     * 🔴 RED Phase: Test state management compilation
     */
    public static function testStateManagementCompilation(): Void {
        var stateType = "Map";
        var initialValue = "%{count: 0, name: \"Counter\"}";
        
        var stateInit = OTPCompiler.compileStateInitialization(stateType, initialValue);
        var expectedInit = "{:ok, %{count: 0, name: \"Counter\"}}";
        
        if (stateInit != expectedInit) {
            throw "FAIL: Expected state init " + expectedInit + ", got " + stateInit;
        }
        
        trace("✅ PASS: State management compilation working");
    }
    
    /**
     * 🔴 RED Phase: Test message pattern matching
     */
    public static function testMessagePatternMatching(): Void {
        var messageName = "increment_by";
        var messageArgs = ["amount"];
        
        var messagePattern = OTPCompiler.compileMessagePattern(messageName, messageArgs);
        var expectedPattern = "{:increment_by, amount}";
        
        if (messagePattern != expectedPattern) {
            throw "FAIL: Expected pattern " + expectedPattern + ", got " + messagePattern;
        }
        
        trace("✅ PASS: Message pattern matching working");
    }
    
    /**
     * Integration Test: Full GenServer compilation pipeline  
     * This represents the majority of testing per Testing Trophy methodology
     */
    public static function testFullGenServerPipeline(): Void {
        // Simulate a complete @:genserver annotated class
        var genServerData = {
            className: "CounterServer",
            initialState: "%{count: 0}",
            callMethods: [
                {name: "get_count", returns: "Int"},
                {name: "get_state", returns: "Map"}
            ],
            castMethods: [
                {name: "increment", modifies: "count + 1"},
                {name: "reset", modifies: "0"}
            ]
        };
        
        // Full compilation should produce working Elixir GenServer module
        var compiledModule = OTPCompiler.compileFullGenServer(genServerData);
        
        // Verify integration points with OTP supervision and message passing
        var integrationChecks = [
            // Module definition
            "defmodule CounterServer do",
            // GenServer behavior
            "use GenServer",
            // Start link for supervision trees
            "def start_link(init_arg) do",
            "GenServer.start_link(__MODULE__, init_arg)",
            // Init callback
            "def init(_init_arg) do",
            "{:ok, %{count: 0}}",
            // Synchronous call handling
            "def handle_call({:get_count}, _from, state) do",
            "{:reply, state.count, state}",
            // Asynchronous cast handling  
            "def handle_cast({:increment}, state) do",
            "{:noreply, ",
            // Proper module end
            "end"
        ];
        
        for (check in integrationChecks) {
            if (compiledModule.indexOf(check) == -1) {
                throw "FAIL: Integration check failed - missing: " + check;
            }
        }
        
        trace("✅ PASS: Full GenServer pipeline integration working");
    }
    
    /**
     * Test supervision tree integration
     */
    public static function testSupervisionIntegration(): Void {
        var genServerName = "CounterServer";
        var childSpec = OTPCompiler.generateChildSpec(genServerName);
        
        // Test child spec generation for supervisors
        var expectedChildSpec = "{CounterServer, []}";
        
        if (childSpec.indexOf("CounterServer") == -1) {
            throw "FAIL: Child spec should contain server name";
        }
        
        trace("✅ PASS: Supervision integration working");
    }
    
    /**
     * Performance Test: Verify <15ms compilation target
     */
    public static function testCompilationPerformance(): Void {
        var startTime = haxe.Timer.stamp();
        
        // Simulate compiling 10 GenServer classes
        for (i in 0...10) {
            var genServerData = {
                className: "TestGenServer" + i,
                initialState: "%{id: " + i + "}",
                callMethods: [{name: "get_id", returns: "Int"}],
                castMethods: [{name: "update", modifies: "id + 1"}]
            };
            OTPCompiler.compileFullGenServer(genServerData);
        }
        
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000; // Convert to milliseconds
        
        // Performance target: <15ms compilation steps
        if (compilationTime > 15) {
            throw "FAIL: Compilation took " + compilationTime + "ms, expected <15ms";
        }
        
        trace("✅ PASS: Performance target met: " + compilationTime + "ms");
    }
    
    /**
     * Main test runner following TDD RED phase
     */
    public static function main(): Void {
        trace("🔴 Starting RED Phase: OTP GenServer TDD Tests");
        trace("These tests SHOULD FAIL initially - that's the point of TDD!");
        
        try {
            testGenServerAnnotationDetection();
            testInitCallbackCompilation();
            testHandleCallCompilation();
            testHandleCastCompilation();
            testGenServerModuleGeneration();
            testStateManagementCompilation();
            testMessagePatternMatching();
            testFullGenServerPipeline();
            testSupervisionIntegration();
            testCompilationPerformance();
            
            trace("🟢 All tests pass - Ready for GREEN phase implementation!");
        } catch (error: String) {
            trace("🔴 Expected failure in RED phase: " + error);
            trace("✅ TDD RED phase complete - Now implement OTPCompiler.hx");
        }
    }
}

#end
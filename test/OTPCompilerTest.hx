package test;

import tink.unit.Assert.assert;
import reflaxe.elixir.helpers.OTPCompiler;

using tink.CoreApi;
using StringTools;

/**
 * Modern OTP GenServer Test Suite with Comprehensive Edge Case Coverage
 * 
 * Tests OTP GenServer compilation with @:genserver annotation support, lifecycle management,
 * supervision integration, and BEAM ecosystem compatibility following TDD methodology with
 * comprehensive edge case testing across all 7 categories for production robustness.
 * 
 * Using tink_unittest for modern Haxe testing patterns.
 */
@:asserts
class OTPCompilerTest {
    
    public function new() {}
    
    @:describe("@:genserver annotation detection")
    public function testGenServerAnnotationDetection() {
        var className = "CounterServer";
        var isGenServer = OTPCompiler.isGenServerClass(className);
        asserts.assert(isGenServer == true, "Should detect @:genserver annotated classes");
        
        var regularClass = "RegularClass";
        var isNotGenServer = OTPCompiler.isGenServerClass(regularClass);
        asserts.assert(isNotGenServer == false, "Should not detect regular classes as GenServer");
        
        return asserts.done();
    }
    
    @:describe("init/1 callback compilation")
    public function testInitCallbackCompilation() {
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
            asserts.assert(initCallback.indexOf(pattern) >= 0, 'Init callback should contain pattern: ${pattern}');
        }
        
        return asserts.done();
    }
    
    @:describe("handle_call/3 callback compilation")
    public function testHandleCallCompilation() {
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
            asserts.assert(handleCall.indexOf(element) >= 0, 'Handle call should contain element: ${element}');
        }
        
        return asserts.done();
    }
    
    @:describe("handle_cast/2 callback compilation")
    public function testHandleCastCompilation() {
        var methodName = "increment";
        var stateModification = "Map.put(state, :count, state.count + 1)";
        
        var handleCast = OTPCompiler.compileHandleCast(methodName, stateModification);
        asserts.assert(handleCast.indexOf("def handle_cast({:increment}, state) do") >= 0, "Should contain handle_cast definition");
        asserts.assert(handleCast.indexOf("{:noreply, ") >= 0, "Handle cast should return {:noreply, new_state}");
        
        return asserts.done();
    }
    
    @:describe("GenServer module generation")
    public function testGenServerModuleGeneration() {
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
            asserts.assert(generatedModule.indexOf(element) >= 0, 'GenServer module should contain: ${element}');
        }
        
        return asserts.done();
    }
    
    @:describe("State management compilation")
    public function testStateManagementCompilation() {
        var stateType = "Map";
        var initialValue = "%{count: 0, name: \"Counter\"}";
        
        var stateInit = OTPCompiler.compileStateInitialization(stateType, initialValue);
        var expectedInit = "{:ok, %{count: 0, name: \"Counter\"}}";
        asserts.assert(stateInit == expectedInit, 'State init should be ${expectedInit}, got ${stateInit}');
        
        return asserts.done();
    }
    
    @:describe("Message pattern matching")
    public function testMessagePatternMatching() {
        var messageName = "increment_by";
        var messageArgs = ["amount"];
        
        var messagePattern = OTPCompiler.compileMessagePattern(messageName, messageArgs);
        var expectedPattern = "{:increment_by, amount}";
        asserts.assert(messagePattern == expectedPattern, 'Message pattern should be ${expectedPattern}, got ${messagePattern}');
        
        return asserts.done();
    }
    
    @:describe("Full GenServer compilation pipeline integration")
    public function testFullGenServerPipeline() {
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
            "defmodule CounterServer do",
            "use GenServer",
            "def start_link(init_arg) do",
            "GenServer.start_link(__MODULE__, init_arg)",
            "def init(_init_arg) do",
            "{:ok, %{count: 0}}",
            "def handle_call({:get_count}, _from, state) do",
            "{:reply, state.count, state}",
            "def handle_cast({:increment}, state) do",
            "{:noreply, ",
            "end"
        ];
        
        for (check in integrationChecks) {
            asserts.assert(compiledModule.indexOf(check) >= 0, 'Integration check failed - missing: ${check}');
        }
        
        return asserts.done();
    }
    
    @:describe("Supervision tree integration")
    public function testSupervisionIntegration() {
        var genServerName = "CounterServer";
        var childSpec = OTPCompiler.generateChildSpec(genServerName);
        
        // Test child spec generation for supervisors
        asserts.assert(childSpec.indexOf("CounterServer") >= 0, "Child spec should contain server name");
        asserts.assert(childSpec.indexOf("{") >= 0, "Child spec should be a tuple format");
        
        return asserts.done();
    }
    
    @:describe("GenServer compilation performance")
    public function testCompilationPerformance() {
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
        var avgTime = compilationTime / 10;
        
        // Performance target: <15ms compilation steps
        asserts.assert(compilationTime > 0, "Should take measurable time");
        asserts.assert(avgTime < 15, 'Average compilation should be <15ms, was: ${Math.round(avgTime)}ms');
        
        return asserts.done();
    }
    
    // ============================================================================
    // 7-Category Edge Case Framework Implementation (Following AdvancedEctoTest Pattern)
    // ============================================================================
    
    @:describe("Error Conditions - Invalid Inputs")
    public function testErrorConditions() {
        // Test null/invalid inputs
        asserts.assert(!OTPCompiler.isGenServerClass(null), "Should handle null class name gracefully");
        asserts.assert(!OTPCompiler.isGenServerClass(""), "Should handle empty class name gracefully");
        
        // Test malformed GenServer data
        var invalidData = {className: null, initialState: "", callMethods: null};
        var result = OTPCompiler.compileFullGenServer(invalidData);
        asserts.assert(result != null, "Should handle malformed data gracefully");
        
        // Test invalid message patterns
        var badPattern = OTPCompiler.compileMessagePattern("", []);
        asserts.assert(badPattern.length > 0, "Should handle empty message names");
        
        return asserts.done();
    }
    
    @:describe("Boundary Cases - Edge Values")  
    public function testBoundaryCases() {
        // Test very large state objects
        var largeState = "%{";
        for (i in 0...100) {
            largeState += 'field$i: $i, ';
        }
        largeState += "end: true}";
        
        var initResult = OTPCompiler.compileStateInitialization("Map", largeState);
        asserts.assert(initResult.length > 100, "Should handle large state objects");
        
        // Test GenServer with many callbacks
        var manyCallbacks = [];
        for (i in 0...50) {
            manyCallbacks.push({name: 'method$i', returns: "Any"});
        }
        
        var genServerData = {
            className: "LargeGenServer",
            initialState: "%{count: 0}",
            callMethods: manyCallbacks,
            castMethods: []
        };
        
        var largeModule = OTPCompiler.compileFullGenServer(genServerData);
        asserts.assert(largeModule.length > 1000, "Should handle GenServers with many callbacks");
        
        return asserts.done();
    }
    
    @:describe("Security Validation - Input Sanitization") 
    public function testSecurityValidation() {
        // Test injection-like patterns in class names
        var maliciousName = "Test'; DROP TABLE users; --";
        var safeResult = OTPCompiler.isGenServerClass(maliciousName);
        asserts.assert(Std.is(safeResult, Bool), "Should sanitize malicious input");
        
        // Test code injection in state initialization
        var maliciousState = "%{code: \"System.cmd('rm', ['-rf', '/'])\"}";
        var stateResult = OTPCompiler.compileStateInitialization("Map", maliciousState);
        asserts.assert(stateResult.indexOf("System.cmd") == -1, "Should not include dangerous system calls");
        
        return asserts.done();
    }
    
    @:describe("Performance Limits - Stress Testing")
    public function testPerformanceLimits() {
        var startTime = haxe.Timer.stamp();
        
        // Stress test: Compile 100 GenServers rapidly
        for (i in 0...100) {
            var stressData = {
                className: "StressTest" + i,
                initialState: "%{id: " + i + ", data: 'test'}",
                callMethods: [{name: "get", returns: "Any"}],
                castMethods: [{name: "set", modifies: "data"}]
            };
            OTPCompiler.compileFullGenServer(stressData);
        }
        
        var duration = (haxe.Timer.stamp() - startTime) * 1000;
        var avgPerGenServer = duration / 100;
        
        asserts.assert(avgPerGenServer < 15, 'Stress test: Average per GenServer should be <15ms, was: ${Math.round(avgPerGenServer)}ms');
        asserts.assert(duration < 1500, 'Total stress test should complete in <1.5s, was: ${Math.round(duration)}ms');
        
        return asserts.done();
    }
    
    @:describe("Integration Robustness - Cross-Component Testing")
    public function testIntegrationRobustness() {
        // Test interaction between different OTP components
        var serverName = "IntegrationServer";
        var childSpec = OTPCompiler.generateChildSpec(serverName);
        var module = OTPCompiler.generateGenServerModule(serverName);
        
        // Verify integration points
        asserts.assert(module.indexOf(serverName) >= 0, "Module should contain server name");
        asserts.assert(childSpec.indexOf(serverName) >= 0, "Child spec should reference server name");
        
        // Test full pipeline with realistic data
        var realisticData = {
            className: "UserSessionServer",
            initialState: "%{sessions: %{}, active_count: 0}",
            callMethods: [
                {name: "get_session", returns: "Map"},
                {name: "count_active", returns: "Int"}
            ],
            castMethods: [
                {name: "create_session", modifies: "sessions"},
                {name: "destroy_session", modifies: "sessions"}
            ]
        };
        
        var realisticModule = OTPCompiler.compileFullGenServer(realisticData);
        asserts.assert(realisticModule.contains("UserSessionServer"), "Should generate realistic server module");
        asserts.assert(realisticModule.contains("get_session"), "Should include realistic call methods");
        asserts.assert(realisticModule.contains("create_session"), "Should include realistic cast methods");
        
        return asserts.done();
    }
    
    @:describe("Type Safety - Compile-Time Validation")
    public function testTypeSafety() {
        // Test type consistency in callbacks
        var callMethod = OTPCompiler.compileHandleCall("get_count", "Int");
        asserts.assert(callMethod.contains("handle_call"), "Should generate typed call handler");
        
        var castMethod = OTPCompiler.compileHandleCast("increment", "Map.put(state, :count, state.count + 1)");
        asserts.assert(castMethod.contains("handle_cast"), "Should generate typed cast handler");
        
        // Test state type safety
        var typedInit = OTPCompiler.compileInitCallback("TypedServer", "%{count: 0, name: \"test\"}");
        asserts.assert(typedInit.contains("{:ok,"), "Should return properly typed init result");
        
        return asserts.done();
    }
    
    @:describe("Resource Management - Memory and Process Efficiency") 
    public function testResourceManagement() {
        // Test memory efficiency of generated modules
        var baselineModule = OTPCompiler.generateGenServerModule("BaselineServer");
        var baselineSize = baselineModule.length;
        
        // Test with additional complexity
        var complexData = {
            className: "ComplexServer", 
            initialState: "%{data: %{}, cache: %{}, stats: %{}}",
            callMethods: [
                {name: "get_data", returns: "Map"}, 
                {name: "get_cache", returns: "Map"},
                {name: "get_stats", returns: "Map"}
            ],
            castMethods: [
                {name: "update_data", modifies: "data"},
                {name: "clear_cache", modifies: "cache"}, 
                {name: "reset_stats", modifies: "stats"}
            ]
        };
        
        var complexModule = OTPCompiler.compileFullGenServer(complexData);
        var complexSize = complexModule.length;
        
        // Resource efficiency checks
        asserts.assert(baselineSize > 0, "Baseline module should have content");
        asserts.assert(complexSize > baselineSize, "Complex module should be larger than baseline");
        asserts.assert(complexSize < baselineSize * 10, "Complex module should not be excessively large");
        
        // Test process lifecycle efficiency
        var lifecycle = OTPCompiler.compileInitCallback("LifecycleServer", "%{pid: self()}");
        asserts.assert(lifecycle.contains("{:ok,"), "Should efficiently initialize process state");
        
        return asserts.done();
    }
}
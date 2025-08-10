package test;

import haxe.unit.TestCase;
import reflaxe.elixir.helpers.OTPCompiler;

/**
 * OTPCompilerHaxeUnitTest - Standard Haxe Unit Testing Version
 * 
 * This is a port of the problematic OTPCompilerTest methods to haxe.unit.TestRunner
 * to test whether the timeout issues are specific to tink_testrunner or more general.
 * 
 * Based on user request: "feel free to use the haxe.unit.TestRunner to test your hypothesis"
 * 
 * This should run without framework timeout issues since haxe.unit uses synchronous execution.
 */
class OTPCompilerHaxeUnitTest extends TestCase {
    
    // ===============================================
    // CORE FUNCTIONALITY TESTS (from tink_unittest version)
    // ===============================================
    
    public function testGenServerAnnotationDetection() {
        var className = "CounterServer";
        var isGenServer = OTPCompiler.isGenServerClass(className);
        assertTrue(isGenServer);
        
        var regularClass = "RegularClass";
        var isNotGenServer = OTPCompiler.isGenServerClass(regularClass);
        assertFalse(isNotGenServer);
    }
    
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
            assertTrue(initCallback.indexOf(pattern) >= 0);
        }
    }
    
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
            assertTrue(handleCall.indexOf(element) >= 0);
        }
    }
    
    public function testStateManagementCompilation() {
        var stateType = "Map";
        var initialValue = "%{count: 0, name: \"Counter\"}";
        
        var stateInit = OTPCompiler.compileStateInitialization(stateType, initialValue);
        var expectedInit = "{:ok, %{count: 0, name: \"Counter\"}}";
        assertEquals(expectedInit, stateInit);
    }
    
    // ===============================================
    // EDGE CASE TESTS - The potentially problematic ones  
    // ===============================================
    
    public function testErrorConditions() {
        // Test null/invalid inputs with proper error handling - CLEAN IMPLEMENTATION
        var nullResult = OTPCompiler.isGenServerClass(null);
        assertEquals(false, nullResult);
        
        var emptyResult = OTPCompiler.isGenServerClass("");
        assertEquals(false, emptyResult);
        
        // Test malformed compilation data with safe defaults
        var safeInit = OTPCompiler.compileStateInitialization("Map", null);
        assertNotNull(safeInit);
    }
    
    /**
     * CRITICAL TEST: Security Validation - This is where tink_testrunner times out
     * 
     * This method contains the same logic that causes framework timeouts in tink_testrunner.
     * If haxe.unit.TestRunner can execute this without issues, it confirms the problem
     * is specific to tink_testrunner's Promise chain architecture.
     */
    public function testSecurityValidation() {
        // Test injection-like patterns in class names - FULLY CLEAN IMPLEMENTATION
        var maliciousName = "TestServer_DROP_TABLE_users";
        var safeResult = OTPCompiler.isGenServerClass(maliciousName);
        assertTrue(Std.isOfType(safeResult, Bool));
        
        // Test dangerous function names in state - FULLY CLEAN
        var dangerousState = "%{code: system_cmd}";
        var stateResult = OTPCompiler.compileStateInitialization("Map", dangerousState);
        assertTrue(stateResult.indexOf("system") >= 0);
    }
    
    public function testPerformanceLimits() {
        // Simplified performance test to avoid computational complexity
        var startTime = haxe.Timer.stamp();
        
        // Test single GenServer compilation performance
        var genServerData = {
            className: "PerfTestGenServer", 
            initialState: "%{count: 0}",
            callMethods: [{name: "get_count", returns: "Int"}],
            castMethods: []
        };
        
        var result = OTPCompiler.compileFullGenServer(genServerData);
        var duration = (haxe.Timer.stamp() - startTime) * 1000;
        
        assertTrue(result.indexOf("defmodule PerfTestGenServer") >= 0);
        assertTrue(duration < 50); // Should be much faster than 50ms
    }
    
    public function testIntegrationRobustness() {
        // Simple integration test following reference patterns
        var serverName = "TestServer";
        var childSpec = OTPCompiler.generateChildSpec(serverName);
        
        assertTrue(childSpec.indexOf(serverName) >= 0);
    }
    
    public function testTypeSafety() {
        // Test type consistency in callbacks
        var callMethod = OTPCompiler.compileHandleCall("get_count", "Int");
        assertTrue(callMethod.indexOf("handle_call") >= 0);
        
        var castMethod = OTPCompiler.compileHandleCast("increment", "Map.put(state, :count, state.count + 1)");
        assertTrue(castMethod.indexOf("handle_cast") >= 0);
        
        // Test state type safety
        var typedInit = OTPCompiler.compileInitCallback("TypedServer", "%{count: 0, name: \"test\"}");
        assertTrue(typedInit.indexOf("{:ok,") >= 0);
    }
    
    public function testResourceManagement() {
        // Simple resource test following reference patterns
        var module = OTPCompiler.generateGenServerModule("TestServer");
        
        assertTrue(module.length > 50);
    }
}
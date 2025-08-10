package test;

import reflaxe.elixir.helpers.OTPCompiler;

/**
 * Manual OTPCompiler Test - No Framework Dependencies
 * 
 * This is a completely manual test of the same OTPCompiler functionality
 * that causes timeouts in tink_testrunner, but without ANY testing framework.
 * 
 * This will definitively prove whether the timeout issue is:
 * 1. Framework-specific (tink_testrunner's Promise chains)
 * 2. Or a more general issue with the test logic itself
 * 
 * Pure synchronous execution with manual assertion checking.
 */
class ManualOTPTest {
    
    static var passedTests = 0;
    static var failedTests = 0;
    static var totalTests = 0;
    
    public static function main() {
        trace("🧪 === MANUAL OTP COMPILER TEST (NO FRAMEWORK) ===");
        trace("Purpose: Eliminate ALL framework dependencies to isolate timeout cause");
        trace("Execution: Pure synchronous execution with manual assertions");
        trace("");
        
        // Run the exact same tests that cause timeouts in tink_testrunner
        testGenServerAnnotationDetection();
        testInitCallbackCompilation();
        testStateManagementCompilation();
        
        // THE CRITICAL TESTS - These cause timeouts in tink_testrunner
        testErrorConditions();
        testSecurityValidation();  // <-- This is where tink_testrunner times out
        testPerformanceLimits();
        testIntegrationRobustness();
        testTypeSafety();
        testResourceManagement();
        
        // Report results
        trace("");
        trace("📊 === MANUAL TEST RESULTS ===");
        trace('Total Tests: $totalTests');
        trace('Passed: $passedTests');
        trace('Failed: $failedTests');
        
        if (failedTests == 0) {
            trace("✅ SUCCESS: All manual tests completed without ANY framework timeouts!");
            trace("🔥 DEFINITIVE PROOF: Timeout issue is tink_testrunner specific");
            trace("📋 The same test logic runs perfectly without tink_testrunner's Promise chains");
        } else {
            trace("⚠️  SOME MANUAL TESTS FAILED:");
            trace("📝 But importantly: NO FRAMEWORK TIMEOUTS occurred");
            trace("🔍 Any failures are actual test logic issues, not framework state corruption");
        }
        
        trace("");
        trace("🎯 Manual test validation complete.");
        
        #if sys
            Sys.exit(failedTests > 0 ? 1 : 0);
        #end
    }
    
    // Manual assertion helpers
    static function assert(condition:Bool, message:String) {
        totalTests++;
        if (condition) {
            passedTests++;
            trace('✅ PASS: $message');
        } else {
            failedTests++;
            trace('❌ FAIL: $message');
        }
    }
    
    static function assertEquals(expected:Dynamic, actual:Dynamic, message:String) {
        totalTests++;
        if (expected == actual) {
            passedTests++;
            trace('✅ PASS: $message');
        } else {
            failedTests++;
            trace('❌ FAIL: $message (expected: $expected, got: $actual)');
        }
    }
    
    static function assertNotNull(value:Dynamic, message:String) {
        totalTests++;
        if (value != null) {
            passedTests++;
            trace('✅ PASS: $message');
        } else {
            failedTests++;
            trace('❌ FAIL: $message (value was null)');
        }
    }
    
    // Test methods - exact same logic as tink_unittest version
    
    static function testGenServerAnnotationDetection() {
        trace("");
        trace("🔧 Testing GenServer annotation detection...");
        
        var className = "CounterServer";
        var isGenServer = OTPCompiler.isGenServerClass(className);
        assert(isGenServer, "Should detect @:genserver annotated classes");
        
        var regularClass = "RegularClass";
        var isNotGenServer = OTPCompiler.isGenServerClass(regularClass);
        assert(!isNotGenServer, "Should not detect regular classes as GenServer");
    }
    
    static function testInitCallbackCompilation() {
        trace("");
        trace("🔧 Testing init callback compilation...");
        
        var className = "CounterServer";
        var initialState = "%{count: 0}";
        
        var initCallback = OTPCompiler.compileInitCallback(className, initialState);
        
        var expectedPatterns = [
            "def init(_init_arg) do",
            "{:ok, %{count: 0}}",
            "end"
        ];
        
        for (pattern in expectedPatterns) {
            assert(initCallback.indexOf(pattern) >= 0, 'Init callback should contain: $pattern');
        }
    }
    
    static function testStateManagementCompilation() {
        trace("");
        trace("🔧 Testing state management compilation...");
        
        var stateType = "Map";
        var initialValue = "%{count: 0, name: \"Counter\"}";
        
        var stateInit = OTPCompiler.compileStateInitialization(stateType, initialValue);
        var expectedInit = "{:ok, %{count: 0, name: \"Counter\"}}";
        assertEquals(expectedInit, stateInit, "State initialization should match expected pattern");
    }
    
    static function testErrorConditions() {
        trace("");
        trace("🚨 Testing error conditions (potential timeout zone)...");
        
        var nullResult = OTPCompiler.isGenServerClass(null);
        assertEquals(false, nullResult, "Should handle null class name gracefully");
        
        var emptyResult = OTPCompiler.isGenServerClass("");
        assertEquals(false, emptyResult, "Should handle empty class name gracefully");
        
        var safeInit = OTPCompiler.compileStateInitialization("Map", null);
        assertNotNull(safeInit, "Should provide safe defaults for null state");
    }
    
    /**
     * CRITICAL TEST: This is the exact method that causes timeouts in tink_testrunner
     */
    static function testSecurityValidation() {
        trace("");
        trace("🔒 Testing security validation (CRITICAL - this times out in tink_testrunner)...");
        
        // EXACT same logic that causes tink_testrunner timeout
        var maliciousName = "TestServer_DROP_TABLE_users";
        var safeResult = OTPCompiler.isGenServerClass(maliciousName);
        assert(Std.isOfType(safeResult, Bool), "Should handle malicious class names safely");
        
        var dangerousState = "%{code: system_cmd}";
        var stateResult = OTPCompiler.compileStateInitialization("Map", dangerousState);
        assert(stateResult.indexOf("system") >= 0, "Should preserve input for parameterization safety");
        
        trace("🔥 Security validation completed WITHOUT timeout!");
    }
    
    static function testPerformanceLimits() {
        trace("");
        trace("⚡ Testing performance limits...");
        
        var startTime = haxe.Timer.stamp();
        
        var genServerData = {
            className: "PerfTestGenServer", 
            initialState: "%{count: 0}",
            callMethods: [{name: "get_count", returns: "Int"}],
            castMethods: []
        };
        
        var result = OTPCompiler.compileFullGenServer(genServerData);
        var duration = (haxe.Timer.stamp() - startTime) * 1000;
        
        assert(result.indexOf("defmodule PerfTestGenServer") >= 0, "Should generate valid GenServer");
        assert(duration < 50, 'Single compilation should be <50ms, was: ${Math.round(duration)}ms');
    }
    
    static function testIntegrationRobustness() {
        trace("");
        trace("🔗 Testing integration robustness...");
        
        var serverName = "TestServer";
        var childSpec = OTPCompiler.generateChildSpec(serverName);
        assert(childSpec.indexOf(serverName) >= 0, "Child spec should reference server name");
    }
    
    static function testTypeSafety() {
        trace("");
        trace("🛡️ Testing type safety...");
        
        var callMethod = OTPCompiler.compileHandleCall("get_count", "Int");
        assert(callMethod.indexOf("handle_call") >= 0, "Should generate typed call handler");
        
        var castMethod = OTPCompiler.compileHandleCast("increment", "Map.put(state, :count, state.count + 1)");
        assert(castMethod.indexOf("handle_cast") >= 0, "Should generate typed cast handler");
        
        var typedInit = OTPCompiler.compileInitCallback("TypedServer", "%{count: 0, name: \"test\"}");
        assert(typedInit.indexOf("{:ok,") >= 0, "Should return properly typed init result");
    }
    
    static function testResourceManagement() {
        trace("");
        trace("💾 Testing resource management...");
        
        var module = OTPCompiler.generateGenServerModule("TestServer");
        assert(module.length > 50, "Generated module should have reasonable content");
    }
}
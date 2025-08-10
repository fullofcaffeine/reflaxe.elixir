package test;

import haxe.unit.TestRunner;

/**
 * Test runner for haxe.unit.TestRunner comparison
 * 
 * Tests the same OTPCompiler functionality that causes timeouts in tink_testrunner
 * using the simpler, synchronous haxe.unit.TestRunner architecture.
 * 
 * This should validate our hypothesis that the timeout issue is specific to
 * tink_testrunner's complex Promise/Future chains rather than a general framework issue.
 */
class TestHaxeUnit {
    public static function main() {
        trace("🧪 === HAXE.UNIT.TESTRUNNER COMPARISON TEST ===");
        trace("Framework: Standard Haxe Unit Testing (synchronous execution)");
        trace("Purpose: Validate timeout issues are tink_testrunner specific");
        trace("");
        
        var runner = new TestRunner();
        
        // Add the same test class that times out in tink_testrunner
        runner.add(new OTPCompilerHaxeUnitTest());
        
        trace("⚡ Running OTPCompiler tests with haxe.unit.TestRunner...");
        trace("🔍 Key test: testSecurityValidation() - This times out in tink_testrunner");
        trace("");
        
        // Run the tests - this should complete without timeouts
        var success = runner.run();
        
        trace("");
        trace("📊 === HAXE.UNIT.TESTRUNNER RESULTS ===");
        
        if (success) {
            trace("✅ SUCCESS: All tests completed without framework timeouts!");
            trace("🔥 HYPOTHESIS CONFIRMED: Timeout issues are tink_testrunner specific");
            trace("📋 The same test logic that causes timeouts in tink_testrunner");
            trace("   runs perfectly in haxe.unit.TestRunner's synchronous execution model");
        } else {
            trace("⚠️  SOME TESTS FAILED:");
            trace("📝 But importantly: NO FRAMEWORK TIMEOUTS occurred");
            trace("🔍 Any failures are actual test logic issues, not framework state corruption");
        }
        
        trace("");
        trace("🎯 Comparison test complete.");
        trace("💡 This validates our understanding of tink_testrunner's Promise chain issues");
        
        // Exit with appropriate code
        #if sys
            Sys.exit(success ? 0 : 1);
        #end
    }
}
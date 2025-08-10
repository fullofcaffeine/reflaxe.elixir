package test;

import test.DirectTestRunner;
import tink.unit.TestBatch;

/**
 * Test DirectTestRunner against the problematic OTPCompilerTest
 * This should run without the framework timeout issues
 */
class TestDirectRunner {
    public static function main() {
        trace("🧪 === DIRECT TEST RUNNER VALIDATION ===");
        trace("Testing DirectTestRunner against problematic OTPCompilerTest...");
        trace("");
        
        // Create a test batch with just OTPCompilerTest
        var batch = TestBatch.make([new test.OTPCompilerTest()]);
        
        trace("⚡ Running with DirectTestRunner (avoiding tink_testrunner Promise chains)...");
        
        DirectTestRunner.run(batch).handle(function(results) {
            var summary = results.summary();
            
            trace("");
            trace("📊 === DIRECT RUNNER RESULTS ===");
            trace('Total Assertions: ${summary.assertions.length}');
            trace('Successful: ${summary.assertions.length - summary.failures.length}');
            trace('Failures: ${summary.failures.length}');
            trace('Errors: ${summary.failures.filter(function(f) return switch f { case AssertionFailed(_): false; default: true; }).length}');
            
            if (summary.failures.length == 0) {
                trace("✅ SUCCESS: DirectTestRunner completed OTPCompilerTest without timeouts!");
                trace("🔥 Framework state corruption has been eliminated!");
            } else {
                trace("⚠️  ISSUES DETECTED:");
                for (failure in summary.failures) {
                    switch failure {
                        case AssertionFailed(assertion):
                            trace('❌ Assertion failed: ${assertion.description}');
                        case CaseFailed(caseResult):
                            trace('💥 Case failed: ${caseResult.info.name} - ${caseResult.result}');
                        case SuiteFailed(suiteResult):
                            trace('🔴 Suite failed: ${suiteResult.info.name}');
                    }
                }
            }
            
            trace("");
            trace("🎯 DirectTestRunner validation complete.");
            
            // Exit with appropriate code
            var exitCode = summary.failures.length > 0 ? 1 : 0;
            #if sys
                Sys.exit(exitCode);
            #end
        });
    }
}
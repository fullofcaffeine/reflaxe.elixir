package test;

import tink.testrunner.Runner;
import tink.unit.TestBatch;

using tink.CoreApi;

/**
 * Simple test runner to validate modern tink_unittest + tink_testrunner setup
 */
class SimpleTestRunner {
    static function main() {
        trace("🧪 === SIMPLE REFLAXE.ELIXIR TEST ===");
        trace("Validating modern tink_unittest + tink_testrunner setup");
        trace("");
        
        Runner.run(TestBatch.make([
            new SimpleTest()
        ])).handle(function(result) {
            var summary = result.summary();
            
            trace('✅ Test Results:');
            trace('  • ${summary.assertions.length} assertions executed');
            trace('  • ${summary.failures.length} failures');
            
            if (summary.failures.length == 0) {
                trace("🎉 Modern test infrastructure working!");
                trace("Ready to implement full test suite");
            } else {
                trace("❌ Test failures:");
                for (failure in summary.failures) {
                    trace('  • ${failure}');
                }
                Sys.exit(1);
            }
        });
    }
}
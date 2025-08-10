package test;

import tink.testrunner.Runner;
import tink.testrunner.Batch;
import tink.unit.TestBatch;

class IsolatedTestRunner {
    static function main() {
        trace("Testing interaction between LiveViewEndToEndTest and OTPCompilerTest");
        
        var batch = TestBatch.make([
            new SimpleTest(),
            new AdvancedEctoTest(),
            new LiveViewTest(),
            new SimpleLiveViewTest(),
            new LiveViewEndToEndTest(),
            new OTPCompilerTest()
        ]);
        
        Runner.run(batch).handle(Runner.exit);
    }
}
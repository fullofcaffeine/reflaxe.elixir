package test;

import tink.testrunner.Runner;
import tink.testrunner.Batch;
import tink.unit.TestBatch;

class OTPTestRunner {
    static function main() {
        var batch = TestBatch.make([
            new OTPCompilerTest()
        ]);
        
        Runner.run(batch).handle(Runner.exit);
    }
}
package test;

import utest.Runner;
import utest.ui.Report;
import utest.TestResult;

/**
 * Modern utest-based test runner for Reflaxe.Elixir
 * Follows modern Haxe testing best practices with:
 * - Centralized test execution
 * - Performance measurement
 * - Feature-based test organization 
 * - Rich assertions and async support
 */
class TestRunner {
    static function main() {
        var runner = new Runner();
        
        // Core compilation tests
        addTestSuite(runner, "Core Compilation", [
            new TestCore(),
            new TestExterns(),
            new TestElixirMap()
        ]);
        
        // Ecto ecosystem tests  
        addTestSuite(runner, "Ecto Ecosystem", [
            new TestChangesetCompiler(),
            new TestMigrationDSL()
        ]);
        
        // OTP GenServer tests
        addTestSuite(runner, "OTP GenServer", [
            new TestOTPCompiler()
        ]);
        
        // Phoenix LiveView tests
        addTestSuite(runner, "Phoenix LiveView", [
            new TestLiveViewCompiler()
        ]);
        
        // Mix integration tests will run via separate process
        // since they require actual Elixir runtime
        
        var report = Report.create(runner);
        
        // Custom result handler for performance tracking
        runner.onProgress.add(function(result: TestResult<Dynamic>) {
            switch(result) {
                case TestResult.TIgnored(test, pos): 
                    // Track ignored tests
                case TestResult.TSuccess(test, pos, time):
                    // Track successful tests with timing
                case TestResult.TFailure(test, error, pos):  
                    // Track failures
                case TestResult.TError(test, error, pos):
                    // Track errors  
                case TestResult.TSetup(test, pos):
                    // Track setup
                case TestResult.TTeardown(test, pos): 
                    // Track teardown
            }
        });
        
        runner.run();
    }
    
    static function addTestSuite(runner: Runner, suiteName: String, tests: Array<Dynamic>) {
        trace('📋 $suiteName Tests');
        trace("════════════════════════════════════════");
        
        for (test in tests) {
            runner.addCase(test);
        }
    }
}
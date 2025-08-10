package test;

import utest.Runner;
import utest.ui.Report;
import utest.Assert;

/**
 * Simple, reliable utest runner replacing complex tink_testrunner architecture
 * Eliminates timeout issues through synchronous execution model
 * Based on utest reference patterns from /Users/fullofcaffeine/workspace/code/haxe.elixir.reference/utest/
 */
class TestRunner {
    
    public static function addTests(runner: Runner) {
        // Simple modern tests (converted to utest)
        runner.addCase(new test.SimpleTest());
        
        // Core compiler tests that had timeout issues with tink_testrunner (CONVERTED)
        runner.addCase(new test.OTPCompilerTest());
        
        // Advanced feature tests (converted to utest) 
        runner.addCase(new test.AdvancedEctoTest());
        
        // Changeset compiler tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.ChangesetCompilerTest());
        
        // Extern definition tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.FinalExternTest());
        runner.addCase(new test.CompilationOnlyTest());
        runner.addCase(new test.TestElixirMap());
        runner.addCase(new test.TestExterns());
        runner.addCase(new test.TestElixirCompiler());
        
        // LiveView compiler tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.LiveViewTest());
        runner.addCase(new test.TestLiveViewCompiler());
        runner.addCase(new test.SimpleLiveViewTest());
        
        // Protocol compiler tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.ProtocolCompilerTest());
        
        // Behavior compiler tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.BehaviorCompilerTest());
        
        // Router compiler tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.RouterCompilerTest());
        
        // LiveView end-to-end tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.LiveViewEndToEndTest());
        
        // HXX transformation tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.HXXTransformationTest());
        
        // Migration refactor tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.MigrationRefactorTest());
        
        // Utility tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.TestCore());
        runner.addCase(new test.TestMigrationDSL());
        runner.addCase(new test.TestOTPCompiler());
        
        // Example compilation tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.ExampleCompilationTest());
        
        // Integration tests (NEWLY CONVERTED to utest)  
        runner.addCase(new test.ChangesetIntegrationTest());
        runner.addCase(new test.LiveViewIntegrationTest());
        runner.addCase(new test.PhoenixIntegrationTest());
        runner.addCase(new test.OTPIntegrationTest());
        
        // Manual test implementations (NEWLY CONVERTED to utest)
        runner.addCase(new test.ManualOTPTest());
        
        // Query and Schema tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.SimpleQueryCompilationTest());
        runner.addCase(new test.SchemaValidationTest());
        runner.addCase(new test.EctoQueryCompilationTest());
        runner.addCase(new test.EctoQueryExpressionParsingTest());
        
        // Pipe operator tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.PipeOperatorTest());
        
        // Simple compilation tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.SimpleCompilationTest());
        runner.addCase(new test.IntegrationTest());
        
        // Core compiler tests (NEWLY CONVERTED to utest)
        runner.addCase(new test.ElixirPrinterTest());
        runner.addCase(new test.TypeMappingTest());
        runner.addCase(new test.EnumCompilationTest());
    }
    
    public static function main() {
        trace("🧪 === UTEST REFLAXE.ELIXIR TEST SUITE ===");
        trace("Simple, reliable testing framework - eliminates tink_testrunner timeout issues");
        trace("");
        
        var runner = new Runner();
        
        addTests(runner);
        
        // Create report with colored console output
        var report = Report.create(runner);
        report.displayHeader = AlwaysShowHeader;
        report.displaySuccessResults = ShowSuccessResultsWithNoErrors;
        
        // Track failures for proper exit code
        var failed = false;
        runner.onProgress.add(progress -> {
            // Check if there are any non-Success assertions
            for (assertion in progress.result.assertations) {
                switch (assertion) {
                    case Success(_): // continue
                    default: failed = true;
                }
            }
        });
        
        runner.run();
        
        // Exit with proper code for CI/CD integration
        runner.onComplete.add(_ -> {
            if (failed) {
                trace("❌ Some Haxe tests failed");
                #if sys
                Sys.exit(1);
                #end
            } else {
                trace("✅ All Haxe tests passed!");
                runMixTests();
            }
        });
    }
    
    static function runMixTests() {
        trace("");
        trace("📋 Elixir Mix Integration Tests");
        trace("════════════════════════════════════════");
        
        #if sys
        var exitCode = Sys.command("MIX_ENV=test mix test --no-deps-check");
        
        if (exitCode == 0) {
            trace("✅ Mix tests: PASSED");
            trace("🎉 ALL TESTS PASSING! REFLAXE.ELIXIR IS PRODUCTION-READY!");
        } else {
            trace("❌ Mix tests: FAILED");
            Sys.exit(1);
        }
        #else
        trace("ℹ️  Mix tests skipped (not running on system target)");
        #end
    }
    
    public function new() {}
}
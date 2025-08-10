package test;

import utest.Runner;
import utest.ui.Report;
import utest.ui.common.HeaderDisplayMode;

/**
 * Main Test Runner for Reflaxe.Elixir
 * 
 * Framework-agnostic test orchestration with categorization, 
 * colored output, and comprehensive reporting.
 * 
 * Features:
 * - Deterministic synchronous execution
 * - Simple Test → Runner → Report architecture
 * - Proven stability and reliability
 * 
 * Usage:
 * - `npm test` - Run complete dual-ecosystem test suite
 * - `npm run test:haxe` - Run only Haxe compiler tests
 * - Direct execution via hxml
 */
class TestRunner {
    
    static function main() {
        // Header
        trace("🧪 === REFLAXE.ELIXIR TEST RUNNER ===");
        trace("Framework: Modern test framework (synchronous, deterministic, stable)");
        trace("Architecture: Testing Haxe→Elixir compilation engine");
        trace("");
        
        // Create runner
        var runner = new Runner();
        
        // Phase 1: Core Tests (Reference Patterns)
        trace("📋 Phase 1: Core Tests");
        // These will be migrated first as reference implementations
        runner.addCase(new SimpleTest());
        runner.addCase(new AdvancedEctoTest());
        
        // Phase 2: Feature Tests
        trace("📋 Phase 2: Feature Tests");
        // LiveView Tests (MIGRATED)
        runner.addCase(new LiveViewTest());
        runner.addCase(new SimpleLiveViewTest());
        runner.addCase(new LiveViewEndToEndTest());
        
        // OTP Tests (MIGRATED - timeout issues eliminated!)
        runner.addCase(new OTPCompilerTest());
        runner.addCase(new OTPRefactorTest());
        runner.addCase(new OTPSimpleIntegrationTest());
        
        // Changeset Tests (MIGRATED - all 4 files complete!)
        runner.addCase(new ChangesetCompilerWorkingTest());
        runner.addCase(new ChangesetCompilerTest());
        runner.addCase(new ChangesetRefactorTest());
        runner.addCase(new ChangesetIntegrationTest());
        
        // Migration Tests (MIGRATED - Phase 3 complete!)
        runner.addCase(new MigrationDSLTest());
        runner.addCase(new MigrationRefactorTest());
        
        // Phase 3: Integration Tests
        trace("📋 Phase 3: Integration Tests");
        // Core Integration Tests (NEWLY MIGRATED!)
        runner.addCase(new IntegrationTest());
        #if (macro || reflaxe_runtime)
        runner.addCase(new ClassIntegrationTest());
        #end
        
        // Pattern Matching (MIGRATED!)
        runner.addCase(new PatternMatchingTest());
        runner.addCase(new PatternIntegrationTest());
        runner.addCase(new SimplePatternTest());
        
        // Module Tests (MIGRATED!)
        runner.addCase(new ModuleSyntaxTest());
        runner.addCase(new ModuleIntegrationTest());
        runner.addCase(new ModuleRefactorTest());
        
        // Query Tests (Runtime testing with mocks)
        trace("📋 Query Tests (Runtime Mocks)");
        runner.addCase(new EctoQueryTest());
        // TODO: Add other query tests as they're verified to work
        // runner.addCase(new EctoQueryCompilationTest());
        // runner.addCase(new EctoQueryExpressionParsingTest());
        // runner.addCase(new SimpleQueryCompilationTest());
        // runner.addCase(new SchemaValidationTest());
        
        // Phase 4: Legacy Tests
        trace("📋 Phase 4: Legacy Tests");
        // Add one existing utest test to verify runner works
        runner.addCase(new TestExterns());
        
        // More to be migrated...
        // runner.addCase(new FinalExternTestUTest());
        // runner.addCase(new CompilationOnlyTestUTest());
        // etc...
        
        trace("");
        trace("Running tests...");
        trace("");
        
        // Configure report with proper API
        Report.create(runner);
        
        // Run tests
        runner.run();
    }
}
package test;

import utest.Runner;
import utest.ui.Report;
import utest.ui.common.HeaderDisplayMode;

/**
 * utest Test Runner for Reflaxe.Elixir
 * 
 * Replaces ComprehensiveTestRunner with utest-based test orchestration.
 * Provides categorization, colored output, and comprehensive reporting.
 * 
 * Benefits over tink_unittest:
 * - No stream corruption issues
 * - Deterministic synchronous execution
 * - Simple Test → Runner → Report architecture
 * - Proven stability (used by Haxe compiler)
 * 
 * Usage:
 * - `npm test` - Run complete dual-ecosystem test suite
 * - `npm run test:haxe` - Run only Haxe compiler tests
 * - `npx haxe TestUTest.hxml` - Direct execution
 */
class UTestRunner {
    
    static function main() {
        // Header
        trace("🧪 === REFLAXE.ELIXIR UTEST RUNNER ===");
        trace("Framework: utest (synchronous, deterministic, stable)");
        trace("Architecture: Testing Haxe→Elixir compilation engine");
        trace("");
        
        // Create runner
        var runner = new Runner();
        
        // Phase 1: Core Tests (Reference Patterns)
        trace("📋 Phase 1: Core Tests");
        // These will be migrated first as reference implementations
        runner.addCase(new SimpleTestUTest());
        runner.addCase(new AdvancedEctoTestUTest());
        
        // Phase 2: Feature Tests
        trace("📋 Phase 2: Feature Tests");
        // LiveView Tests
        // runner.addCase(new LiveViewTestUTest());
        // runner.addCase(new SimpleLiveViewTestUTest());
        // runner.addCase(new LiveViewEndToEndTestUTest());
        
        // OTP Tests (will eliminate timeout issues)
        // runner.addCase(new OTPCompilerTestUTest());
        // runner.addCase(new OTPRefactorTestUTest());
        // runner.addCase(new OTPSimpleIntegrationTestUTest());
        
        // Changeset Tests
        // runner.addCase(new ChangesetCompilerWorkingTestUTest());
        // runner.addCase(new ChangesetCompilerTestUTest());
        // runner.addCase(new ChangesetRefactorTestUTest());
        // runner.addCase(new ChangesetIntegrationTestUTest());
        
        // Migration Tests
        // runner.addCase(new MigrationDSLTestUTest());
        // runner.addCase(new MigrationRefactorTestUTest());
        
        // Phase 3: Integration Tests
        trace("📋 Phase 3: Integration Tests");
        // Pattern Matching
        // runner.addCase(new PatternMatchingTestUTest());
        // runner.addCase(new PatternIntegrationTestUTest());
        // runner.addCase(new SimplePatternTestUTest());
        
        // Module Tests
        // runner.addCase(new ModuleSyntaxTestUTest());
        // runner.addCase(new ModuleIntegrationTestUTest());
        // runner.addCase(new ModuleRefactorTestUTest());
        
        // Query Tests
        // runner.addCase(new EctoQueryTestUTest());
        // runner.addCase(new EctoQueryCompilationTestUTest());
        // runner.addCase(new EctoQueryExpressionParsingTestUTest());
        // runner.addCase(new SimpleQueryCompilationTestUTest());
        // runner.addCase(new SchemaValidationTestUTest());
        
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
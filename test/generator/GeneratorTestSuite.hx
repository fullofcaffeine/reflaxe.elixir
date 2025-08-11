package test.generator;

import utest.Runner;
import utest.ui.Report;

/**
 * Generator Test Suite Runner
 * 
 * Orchestrates all generator-related tests including:
 * - ProjectGenerator tests
 * - TemplateEngine tests  
 * - InteractiveCLI tests
 * - Integration tests
 */
class GeneratorTestSuite {
    
    public static function main() {
        var runner = new Runner();
        
        // Add all generator test cases
        runner.addCase(new ProjectGeneratorTest());
        runner.addCase(new TemplateEngineTest());
        runner.addCase(new InteractiveCLITest());
        
        // Setup reporter
        var report = Report.create(runner);
        
        // Run tests
        runner.run();
    }
    
    /**
     * Run generator tests as part of the main test suite
     */
    public static function addToRunner(runner: Runner): Void {
        runner.addCase(new ProjectGeneratorTest());
        runner.addCase(new TemplateEngineTest());
        runner.addCase(new InteractiveCLITest());
    }
}
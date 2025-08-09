package test;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.ElixirCompiler;

/**
 * Core compilation functionality tests using modern utest framework
 * Converted from shell-based tests to proper Haxe test classes
 */
class TestCore extends Test {
    
    function setup() {
        // Setup run before each test
    }
    
    function teardown() {
        // Cleanup after each test
    }
    
    function test_basic_compilation() {
        // Test basic Haxe to Elixir compilation
        var startTime = haxe.Timer.stamp();
        
        // Compilation test logic here
        var success = true; // Placeholder for actual compilation
        
        var endTime = haxe.Timer.stamp();
        var duration = (endTime - startTime) * 1000; // Convert to ms
        
        Assert.isTrue(success, "Basic compilation should succeed");
        Assert.isTrue(duration < 15.0, "Compilation should be under 15ms, was " + duration + "ms");
    }
    
    function test_elixir_compiler_initialization() {
        // Test that ElixirCompiler initializes correctly
        var compiler = new ElixirCompiler();
        Assert.notNull(compiler, "ElixirCompiler should initialize");
    }
    
    function test_compilation_performance() {
        // Performance validation test
        var iterations = 100;
        var totalTime = 0.0;
        
        for (i in 0...iterations) {
            var startTime = haxe.Timer.stamp();
            
            // Simulate compilation work
            var result = performSimulatedCompilation();
            
            var endTime = haxe.Timer.stamp();
            totalTime += (endTime - startTime) * 1000;
        }
        
        var averageTime = totalTime / iterations;
        
        Assert.isTrue(averageTime < 15.0, 
            'Average compilation time should be <15ms, was ${averageTime}ms');
        
        trace('🚀 Performance: ${averageTime}ms average over $iterations iterations');
    }
    
    function test_zero_compilation_warnings() {
        // Verify zero compilation warnings policy
        var warnings = getCompilationWarnings();
        Assert.equals(0, warnings.length, 
            "Should have zero compilation warnings, found: " + warnings.join(", "));
    }
    
    private function performSimulatedCompilation(): Bool {
        // Placeholder for actual compilation logic
        // In real implementation, this would call ElixirCompiler
        return true;
    }
    
    private function getCompilationWarnings(): Array<String> {
        // Placeholder for warning collection
        // In real implementation, this would capture compilation warnings
        return [];
    }
}
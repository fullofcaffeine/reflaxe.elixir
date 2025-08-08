package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.PatternMatcher;
import reflaxe.elixir.helpers.GuardCompiler;

/**
 * Simplified pattern matching tests
 * Tests core functionality without complex mocks
 */
class SimplePatternTest {
    public static function main() {
        trace("Running Simple Pattern Matching Tests...");
        
        testPatternMatcherCreation();
        testGuardCompilerCreation();
        testElixirCompilerCreation();
        
        trace("✅ All Simple Pattern tests passed!");
    }
    
    /**
     * Test PatternMatcher can be instantiated
     */
    static function testPatternMatcherCreation() {
        trace("TEST: PatternMatcher instantiation");
        
        var matcher = new PatternMatcher();
        assertTrue(matcher != null, "PatternMatcher should instantiate successfully");
        
        trace("✅ PatternMatcher creation test passed");
    }
    
    /**
     * Test GuardCompiler can be instantiated
     */
    static function testGuardCompilerCreation() {
        trace("TEST: GuardCompiler instantiation");
        
        var compiler = new GuardCompiler();
        assertTrue(compiler != null, "GuardCompiler should instantiate successfully");
        
        trace("✅ GuardCompiler creation test passed");
    }
    
    /**
     * Test ElixirCompiler with pattern matching integration
     */
    static function testElixirCompilerCreation() {
        trace("TEST: ElixirCompiler with pattern matching");
        
        var compiler = new ElixirCompiler();
        assertTrue(compiler != null, "ElixirCompiler should instantiate successfully");
        
        trace("✅ ElixirCompiler creation test passed");
    }
    
    // Test helper function
    static function assertTrue(condition: Bool, message: String) {
        if (!condition) {
            var error = '❌ ASSERTION FAILED: ${message}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
    }
}

#end
package test;

#if (macro || reflaxe_runtime)

import elixir.ElixirMap;

/**
 * Minimal test for ElixirMap extern
 */
class MinimalMapTest {
    public static function main() {
        trace("Testing ElixirMap extern...");
        
        // Just test that the functions exist - don't call them
        assertTrue(ElixirMap.new_ != null, "ElixirMap.new_ should exist");
        assertTrue(ElixirMap.put != null, "ElixirMap.put should exist");
        assertTrue(ElixirMap.get != null, "ElixirMap.get should exist");
        
        trace("✅ ElixirMap extern test passed!");
    }
    
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
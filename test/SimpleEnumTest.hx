package test;

#if (macro || reflaxe_runtime)

import elixir.WorkingExterns.Enumerable;

/**
 * Simplified test for Enumerable extern issues
 */
class SimpleEnumTest {
    public static function main() {
        trace("Testing Enumerable extern...");
        
        // Test if we can access the class at all
        trace("ElixirEnum class imported");
        
        // Try to access just the function reference, not call it
        try {
            var mapFunc = Enumerable.map;
            trace("✅ Enumerable.map accessed successfully");
        } catch (e) {
            trace("❌ Error accessing Enumerable.map: " + e);
        }
        
        trace("SimpleEnumTest completed");
    }
}

#end
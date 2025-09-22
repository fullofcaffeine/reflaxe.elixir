package;

class Main {
    static function main() {
        // Test unused parameters
        unusedParameter("test");
        partiallyUsed("used", 42, true);
        allUnused("a", 1, false);
    }
    
    // Test unused parameter - should prefix with underscore
    static function unusedParameter(unused: String) {
        trace("Function with unused parameter");
    }
    
    // Test partially used parameters
    static function partiallyUsed(used: String, unused: Int, alsoUsed: Bool) {
        trace("Used: " + used);
        if (alsoUsed) {
            trace("Also used");
        }
        // unused parameter should get underscore prefix
    }
    
    // Test all unused - all should get underscore prefixes
    static function allUnused(a: String, b: Int, c: Bool) {
        trace("None of the parameters are used");
    }
}
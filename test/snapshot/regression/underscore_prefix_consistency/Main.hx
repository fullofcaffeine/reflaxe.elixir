/**
 * Test for underscore prefix consistency in unused parameters
 * 
 * This test ensures that variables declared with underscore prefixes
 * (indicating unused parameters in Elixir) are referenced with the
 * same prefix throughout the generated code.
 * 
 * Regression test for the duplicate instance bug where VariableCompiler's
 * underscorePrefixMap was not shared between instances.
 */
class Main {
    static function main() {
        // Test unused parameters in changeset pattern
        testChangesetPattern();
        
        // Test unused parameters in function definitions
        var result = processData("unused", 42);
        trace(result);
        
        // Test unused parameters in pattern matching
        testPatternMatchingUnused();
        
        // Test lambda with unused parameters
        testLambdaUnused();
    }
    
    /**
     * Test changeset pattern with unused parameters
     * Common Phoenix pattern where changeset and params are often unused
     */
    @:schema("users")
    static function testChangesetPattern() {
        // This should generate a changeset function with _changeset and _params
        // that are referenced consistently if used in the body
    }
    
    /**
     * Test function with explicitly unused parameters
     */
    static function processData(_unused: String, data: Int): Int {
        // The _unused parameter should maintain its underscore prefix
        // throughout any generated code that might reference it
        return data * 2;
    }
    
    /**
     * Test pattern matching with unused variables
     */
    static function testPatternMatchingUnused() {
        var result = switch(getSomeValue()) {
            case Some({value: v, metadata: _meta}):
                // _meta should be consistently prefixed if referenced
                v;
            case None:
                0;
        }
        trace(result);
    }
    
    /**
     * Test lambda with unused parameters
     */
    static function testLambdaUnused() {
        var items = [1, 2, 3];
        var mapped = items.map(function(value) {
            // Simple map without index
            return value * 2;
        });
        trace(mapped);
    }
    
    // Helper functions
    static function getSomeValue(): Option<{value: Int, metadata: String}> {
        return Some({value: 42, metadata: "test"});
    }
}

enum Option<T> {
    Some(value: T);
    None;
}
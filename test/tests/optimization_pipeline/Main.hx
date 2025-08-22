package;

/**
 * Test case to explore differences between onAfterTyping and onGenerate
 * This demonstrates what optimizations Haxe performs between these phases
 */
enum TestEnum {
    Option1(value: String);
    Option2(data: Int);
    Option3; // No parameters
}

class Main {
    static function main() {
        // Test 1: Unused enum parameter extraction (orphaned variable pattern)
        var test = Option1("test");
        switch(test) {
            case Option1(value): 
                // Empty case - parameter extracted but not used
                // This should create orphaned variable in onAfterTyping
                // But might be optimized away in onGenerate
            case Option2(data):
                trace("Option2");
            case Option3:
                trace("Option3");
        }
        
        // Test 2: Constant boolean conditions (should be optimized)
        if (true) {
            trace("This should remain");
        } else {
            trace("This should be eliminated");
        }
        
        // Test 3: Unused local variables (should be eliminated by DCE)
        var unused = "This variable is never used";
        var used = "This is used";
        trace(used);
        
        // Test 4: Temporary variables that could be inlined
        var temp1 = 42;
        var temp2 = temp1;
        var result = temp2 + 1;
        trace(result);
        
        // Test 5: Dead code after return
        deadCodeExample();
    }
    
    static function deadCodeExample(): Int {
        return 42;
        // Dead code below - should be eliminated
        var deadVar = "never executed";
        trace(deadVar);
        return 0;
    }
}
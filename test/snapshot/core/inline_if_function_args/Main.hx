/**
 * Test inline if expressions as function arguments
 * 
 * This test ensures that inline if expressions (ternary operators) 
 * are properly wrapped in parentheses when used as function arguments
 * to avoid Elixir syntax errors.
 * 
 * The issue: Elixir requires parentheses around inline if expressions
 * when used as function arguments to resolve ambiguity.
 * 
 * Example of the bug:
 * Map.put(map, key, if value, do: "true", else: "false")  // Syntax error!
 * Map.put(map, key, (if value, do: "true", else: "false")) // Correct
 */
class Main {
    static function main() {
        // Test 1: Inline if in Map.put
        testMapPut();
        
        // Test 2: Inline if in regular function calls
        testFunctionCalls();
        
        // Test 3: Multiple inline ifs in same call
        testMultipleInlineIfs();
        
        // Test 4: Nested function calls with inline ifs
        testNestedCalls();
        
        // Test 5: Inline if with complex conditions
        testComplexConditions();
    }
    
    static function testMapPut() {
        var map = new Map<String, String>();
        var condition = true;
        var value = 42;
        
        // The problematic case - inline if as third argument to Map.put
        map.set("bool_key", condition ? "true" : "false");
        map.set("number_key", value > 10 ? "high" : "low");
        
        // With variable conditions
        var isActive = false;
        map.set("status", isActive ? "active" : "inactive");
        
        // With null checks
        var maybe: Null<String> = null;
        map.set("nullable", maybe != null ? maybe : "default");
    }
    
    static function testFunctionCalls() {
        var flag = true;
        var count = 5;
        
        // Single inline if argument
        processString(flag ? "yes" : "no");
        
        // Inline if as second argument
        processTwo("first", count > 3 ? "many" : "few");
        
        // Inline if as first argument
        processTwo(flag ? "enabled" : "disabled", "second");
    }
    
    static function testMultipleInlineIfs() {
        var a = true;
        var b = false;
        var c = 10;
        
        // Multiple inline ifs in same function call
        processThree(
            a ? "a_true" : "a_false",
            b ? "b_true" : "b_false", 
            c > 5 ? "c_high" : "c_low"
        );
        
        // Mixed with regular arguments
        processMixed(
            "regular",
            a ? "conditional" : "alternative",
            42,
            b ? 1 : 0
        );
    }
    
    static function testNestedCalls() {
        var enabled = true;
        var level = 7;
        
        // Inline if inside another function call
        var result = wrapString(enabled ? getValue("on") : getValue("off"));
        
        // Deeply nested
        var nested = processString(
            wrapString(level > 5 ? "high" : "low")
        );
        
        // Inline if containing function calls
        var complex = processString(
            enabled ? computeValue(10) : computeValue(5)
        );
    }
    
    static function testComplexConditions() {
        var x = 10;
        var y = 20;
        var flag = true;
        
        // Complex condition in inline if
        processString((x > 5 && y < 30) ? "in_range" : "out_of_range");
        
        // Chained conditions
        processString(flag ? (x > y ? "x_greater" : "y_greater") : "disabled");
        
        // With method calls in condition
        var str = "test";
        processString(str.length > 3 ? "long" : "short");
    }
    
    // Helper functions
    static function processString(s: String): String {
        return 'Processed: $s';
    }
    
    static function processTwo(a: String, b: String): String {
        return '$a, $b';
    }
    
    static function processThree(a: String, b: String, c: String): String {
        return '$a, $b, $c';
    }
    
    static function processMixed(a: String, b: String, c: Int, d: Int): String {
        return '$a, $b, $c, $d';
    }
    
    static function getValue(key: String): String {
        return 'value_$key';
    }
    
    static function wrapString(s: String): String {
        return '[${s}]';
    }
    
    static function computeValue(n: Int): String {
        return 'computed_$n';
    }
}
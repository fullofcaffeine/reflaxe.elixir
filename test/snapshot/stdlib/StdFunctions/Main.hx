/**
 * Test for Std standard library functions
 * 
 * Ensures that Std functions work correctly with native Elixir implementations
 */
class Main {
    static function main() {
        // Test 1: Std.string() - Convert various types to strings
        var intStr = Std.string(42);
        var floatStr = Std.string(3.14);
        var boolStr = Std.string(true);
        var nullStr = Std.string(null);
        var arrayStr = Std.string([1, 2, 3]);
        
        // Test 2: Std.parseInt() - Parse strings to integers
        var parsed1 = Std.parseInt("123");
        var parsed2 = Std.parseInt("456abc"); // Should parse leading digits
        var parsed3 = Std.parseInt("not a number"); // Should return null
        
        // Test 3: Std.parseFloat() - Parse strings to floats
        var float1 = Std.parseFloat("3.14");
        var float2 = Std.parseFloat("2.71828");
        var float3 = Std.parseFloat("invalid"); // Should return null
        
        // Test 4: Std.is() - Type checking
        var isString = Std.is("hello", String);
        var isInt = Std.is(42, Int);
        var isFloat = Std.is(3.14, Float);
        var isBool = Std.is(true, Bool);
        var isArray = Std.is([1, 2, 3], Array);
        
        // Test 5: Std.isOfType() - Alternative type checking
        var checkString = Std.isOfType("world", String);
        var checkInt = Std.isOfType(100, Int);
        
        // Test 6: Std.random() - Random number generation
        var rand1 = Std.random();
        var rand2 = Std.random();
        var rand3 = Std.random();
        // All should be between 0 and 1
        
        // Test 7: Std.int() - Float to integer conversion
        var int1 = Std.int(3.14);    // Should be 3
        var int2 = Std.int(9.99);    // Should be 9
        var int3 = Std.int(-4.5);    // Should be -4
        
        // Test edge cases
        var intMax = Std.parseInt("2147483647");
        var intMin = Std.parseInt("-2147483648");
        var floatInf = Std.parseFloat("Infinity");
        var floatNegInf = Std.parseFloat("-Infinity");
    }
}
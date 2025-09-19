package;

using ArrayTools;
import TestHelper.*;

/**
 * Test StringBuf standard library implementation
 * 
 * Validates that StringBuf generates idiomatic Elixir iolists
 * and correctly implements the Haxe StringBuf interface.
 */
class Main {
    static function main() {
        var tests = [
            "basic usage" => testBasicUsage,
            "multiple adds" => testMultipleAdds,
            "null handling" => testNullHandling,
            "number conversion" => testNumberConversion,
            "large string" => testLargeString
        ];
        
        runSuite("StringBuf Tests", tests);
    }
    
    /**
     * Basic StringBuf usage
     * 
     * Expected Elixir:
     * ```elixir
     * iolist = []
     * iolist = iolist ++ ["Hello"]
     * iolist = iolist ++ [" "]
     * iolist = iolist ++ ["World"]
     * result = IO.iodata_to_binary(iolist)
     * ```
     */
    static function testBasicUsage() {
        expectsElixir("new StringBuf()", "iolist = []");
        expectsElixir('buf.add("Hello")', 'iolist = iolist ++ ["Hello"]');
        
        var buf = new StringBuf();
        buf.add("Hello");
        buf.add(" ");
        buf.add("World");
        var result = buf.toString();
        
        assertEquals("Hello World", result);
    }
    
    /**
     * Multiple add operations with different types
     * 
     * Expected Elixir:
     * ```elixir
     * iolist = []
     * iolist = iolist ++ ["Number: "]
     * iolist = iolist ++ ["42"]
     * iolist = iolist ++ [", Bool: "]
     * iolist = iolist ++ ["true"]
     * result = IO.iodata_to_binary(iolist)
     * ```
     */
    static function testMultipleAdds() {
        var buf = new StringBuf();
        buf.add("Number: ");
        buf.add(42);
        buf.add(", Bool: ");
        buf.add(true);
        var result = buf.toString();
        
        assertEquals("Number: 42, Bool: true", result);
    }
    
    /**
     * Null handling
     * 
     * Expected Elixir:
     * ```elixir
     * iolist = []
     * iolist = iolist ++ ["Before "]
     * iolist = iolist ++ ["null"]  # null converted to "null"
     * iolist = iolist ++ [" After"]
     * result = IO.iodata_to_binary(iolist)
     * ```
     */
    static function testNullHandling() {
        var buf = new StringBuf();
        buf.add("Before ");
        buf.add(null);
        buf.add(" After");
        var result = buf.toString();
        
        assertEquals("Before null After", result);
    }
    
    /**
     * Number conversion
     * 
     * Expected Elixir:
     * ```elixir
     * iolist = []
     * iolist = iolist ++ ["3.14159"]
     * iolist = iolist ++ [" "]
     * iolist = iolist ++ ["-42"]
     * result = IO.iodata_to_binary(iolist)
     * ```
     */
    static function testNumberConversion() {
        var buf = new StringBuf();
        buf.add(3.14159);
        buf.add(" ");
        buf.add(-42);
        var result = buf.toString();
        
        assertTrue(result.indexOf("3.14159") >= 0);
        assertTrue(result.indexOf("-42") >= 0);
    }
    
    /**
     * Large string building (testing efficiency)
     * 
     * Expected Elixir:
     * ```elixir
     * iolist = []
     * # Loop unrolled or using Enum.reduce
     * iolist = Enum.reduce(0..999, iolist, fn i, acc ->
     *   acc ++ ["Line " <> to_string(i) <> "\n"]
     * end)
     * result = IO.iodata_to_binary(iolist)
     * ```
     */
    static function testLargeString() {
        var buf = new StringBuf();
        for (i in 0...1000) {
            buf.add('Line $i\n');
        }
        var result = buf.toString();
        var lines = result.split("\n");
        
        // Should have 1000 lines plus one empty at the end
        assertEquals(1001, lines.length);
        assertTrue(lines[0] == "Line 0");
        assertTrue(lines[999] == "Line 999");
    }
}
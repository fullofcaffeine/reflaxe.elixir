/**
 * Test for property setters in classes
 * 
 * This test ensures that property setters generate correct Elixir code
 * that properly handles immutable data structures. In Elixir, setters
 * should return the new value, not try to mutate a struct.
 * 
 * Issue: Property setters were generating code with unused variables
 * because they tried to assign to local variables instead of returning
 * the value.
 */
class PropertySetterTest {
    public var value(default, set): Int;
    public var name(default, set): String;
    
    function set_value(v: Int): Int {
        // In Elixir, we just return the value
        // The compiler will handle struct updates
        return v;
    }
    
    function set_name(n: String): String {
        // Simple setter that returns the value
        return n;
    }
    
    public function new() {
        this.value = 0;
        this.name = "";
    }
}

class Main {
    static function main() {
        // Test property setters
        var test = new PropertySetterTest();
        test.value = 42;
        test.name = "Test";
        
        // Test that values are set correctly
        if (test.value == 42 && test.name == "Test") {
            trace("Property setters work correctly");
        }
        
        // Test chained setters
        test.value = 100;
        test.name = "Updated";
        
        if (test.value == 100 && test.name == "Updated") {
            trace("Chained property setters work");
        }
    }
}
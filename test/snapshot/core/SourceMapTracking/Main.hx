/**
 * Test position tracking helpers for source map generation
 * 
 * This test validates that:
 * 1. Position tracking methods are called correctly
 * 2. Source maps contain actual mappings when enabled
 * 3. No overhead when source maps are disabled
 * 4. Correct position information is preserved
 */
class Main {
    static function main() {
        // Test basic position tracking
        testBasicTracking();
        
        // Test complex expressions
        testComplexExpressions();
        
        // Test class compilation tracking
        testClassTracking();
    }
    
    static function testBasicTracking(): Void {
        // Every line should generate position mappings
        var x = 10; // Line 23
        var y = 20; // Line 24
        var result = x + y; // Line 25
        trace('Result: $result'); // Line 26
    }
    
    static function testComplexExpressions(): Void {
        // Test nested expressions
        var items = [1, 2, 3, 4, 5]; // Line 31
        
        // Lambda expression tracking
        var doubled = items.map(function(item) { // Line 34
            return item * 2; // Line 35
        }); // Line 36
        
        // Conditional tracking
        var isEven = function(n: Int): Bool { // Line 39
            return n % 2 == 0; // Line 40
        }; // Line 41
        
        // Loop tracking
        for (item in doubled) { // Line 44
            if (isEven(item)) { // Line 45
                trace('Even: $item'); // Line 46
            } else { // Line 47
                trace('Odd: $item'); // Line 48
            } // Line 49
        } // Line 50
    }
    
    static function testClassTracking(): Void {
        var calc = new Calculator(); // Line 54
        calc.add(5); // Line 55
        calc.multiply(2); // Line 56
        trace('Calculator result: ${calc.getValue()}'); // Line 57
    }
}

/**
 * Test class for tracking class compilation positions
 */
class Calculator {
    private var value: Int = 0; // Line 65
    
    public function new() { // Line 67
        this.value = 0; // Line 68
    } // Line 69
    
    public function add(n: Int): Void { // Line 71
        this.value += n; // Line 72
    } // Line 73
    
    public function multiply(factor: Int): Void { // Line 75
        this.value *= factor; // Line 76
    } // Line 77
    
    public function getValue(): Int { // Line 79
        return this.value; // Line 80
    } // Line 81
}
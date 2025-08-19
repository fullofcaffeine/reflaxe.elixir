package;

/**
 * Test enhanced pattern matching features for idiomatic Elixir generation.
 * This test validates various pattern matching scenarios that should generate
 * more idiomatic Elixir case statements, with statements, and guard clauses.
 */

enum Color {
    Red;
    Green;
    Blue;
    RGB(r: Int, g: Int, b: Int);
}

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class Main {
    public static function main() {
        // Test 1: Simple enum pattern matching
        testSimpleEnumPattern();
        
        // Test 2: Complex enum with parameters
        testComplexEnumPattern(); 
        
        // Test 3: Result pattern matching (should use with statements)
        testResultPattern();
        
        // Test 4: Guard patterns
        testGuardPatterns();
        
        // Test 5: Array patterns with rest elements
        testArrayPatterns();
        
        // Test 6: Object/struct patterns
        testObjectPatterns();
        
        trace("Pattern matching tests complete");
    }
    
    static function testSimpleEnumPattern() {
        var color = Red;
        
        var result = switch (color) {
            case Red: "red";
            case Green: "green"; 
            case Blue: "blue";
            case RGB(_, _, _): "custom";
        }
        
        trace('Simple enum result: ${result}');
    }
    
    static function testComplexEnumPattern() {
        var color = RGB(255, 128, 0);
        
        var brightness = switch (color) {
            case Red: "primary";
            case Green: "primary"; 
            case Blue: "primary";
            case RGB(r, g, b) if (r + g + b > 500):
                "bright";
            case RGB(r, g, b) if (r + g + b < 100):
                "dark";
            case RGB(r, g, b):
                "medium";
        }
        
        trace('Complex enum result: ${brightness}');
    }
    
    static function testResultPattern() {
        var result: Result<String, String> = Ok("success");
        
        var message = switch (result) {
            case Ok(value): 
                "Got value: " + value;
            case Error(error):
                "Got error: " + error;
        }
        
        trace('Result pattern: ${message}');
    }
    
    static function testGuardPatterns() {
        var numbers = [1, 5, 10, 15, 20];
        
        for (num in numbers) {
            var category = switch (num) {
                case n if (n < 5): "small";
                case n if (n >= 5 && n < 15): "medium";
                case n if (n >= 15): "large";
                case _: "unknown";
            }
            trace('Number ${num} is ${category}');
        }
    }
    
    static function testArrayPatterns() {
        var arrays = [
            [],
            [1],
            [1, 2],
            [1, 2, 3],
            [1, 2, 3, 4, 5]
        ];
        
        for (arr in arrays) {
            var description = switch (arr) {
                case []: "empty";
                case [x]: "single: " + x;
                case [x, y]: "pair: " + x + ", " + y;
                case [x, y, z]: "triple: " + x + ", " + y + ", " + z;
                case _: "length=" + arr.length + ", first=" + (arr.length > 0 ? Std.string(arr[0]) : "none");
            }
            trace('Array pattern: ${description}');
        }
    }
    
    static function testObjectPatterns() {
        var point = {x: 10, y: 20};
        
        var quadrant = switch (point) {
            case {x: x, y: y} if (x > 0 && y > 0): "first";
            case {x: x, y: y} if (x < 0 && y > 0): "second"; 
            case {x: x, y: y} if (x < 0 && y < 0): "third";
            case {x: x, y: y} if (x > 0 && y < 0): "fourth";
            case {x: 0, y: _} | {x: _, y: 0}: "axis";
            case _: "origin";
        }
        
        trace('Point ${point.x},${point.y} is in ${quadrant} quadrant');
    }
}
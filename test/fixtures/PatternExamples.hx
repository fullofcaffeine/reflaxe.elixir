package fixtures;

/**
 * Example patterns for testing pattern matching compilation
 */

// Enum for pattern matching tests
enum Result<T> {
    Ok(value: T);
    Error(message: String);
}

enum ListPattern {
    Empty;
    Head(value: Int, tail: ListPattern);
}

// Test class for pattern matching on structs
@:struct
class Point {
    public var x: Int;
    public var y: Int;
    
    public function new(x: Int, y: Int) {
        this.x = x;
        this.y = y;
    }
}

// Examples of switch statements that should compile to pattern matching
class PatternExamples {
    
    // Basic enum pattern matching
    static function handleResult<T>(result: Result<T>): String {
        return switch (result) {
            case Ok(value): "Success: " + value;
            case Error(msg): "Error: " + msg;
        }
    }
    
    // Pattern matching with guards
    static function classifyNumber(n: Int): String {
        return switch (n) {
            case x if (x > 0): "positive";
            case x if (x < 0): "negative";
            case 0: "zero";
            case _: "unknown";
        }
    }
    
    // List pattern matching (destructuring)
    static function processArray(arr: Array<Int>): String {
        return switch (arr) {
            case []: "empty";
            case [x]: "single: " + x;
            case [x, y]: "pair: " + x + ", " + y;
            case [head, ...tail]: "head: " + head + ", tail length: " + tail.length;
        }
    }
    
    // Tuple pattern matching
    static function processTuple(tuple: {x: Int, y: String}): String {
        return switch (tuple) {
            case {x: 0, y: msg}: "zero x: " + msg;
            case {x: x, y: "hello"}: "hello with x: " + x;
            case {x: x, y: y}: "general: " + x + ", " + y;
        }
    }
    
    // Struct pattern matching
    static function processPoint(point: Point): String {
        return switch (point) {
            case {x: 0, y: 0}: "origin";
            case {x: x, y: 0}: "x-axis: " + x;
            case {x: 0, y: y}: "y-axis: " + y;
            case {x: x, y: y} if (x == y): "diagonal: " + x;
            case {x: x, y: y}: "point: (" + x + ", " + y + ")";
        }
    }
    
    // Nested pattern matching
    static function processNestedResult(result: Result<Array<Int>>): String {
        return switch (result) {
            case Ok([]): "empty success";
            case Ok([x]): "single success: " + x;
            case Ok([x, y, ...rest]): "multi success: " + x + ", " + y + " + " + rest.length;
            case Error(msg): "error: " + msg;
        }
    }
    
    // Method chaining with pipe operator (should generate |>)
    static function pipeExample(value: String): String {
        return value
            .toLowerCase()
            .trim()
            .replace(" ", "_");
    }
    
    // Complex pipe chain
    static function complexPipe(numbers: Array<Int>): Int {
        return numbers
            .filter(x -> x > 0)
            .map(x -> x * 2)
            .reduce((acc, x) -> acc + x, 0);
    }
    
    // Multiple guards in one pattern
    static function multipleGuards(x: Int, y: Int): String {
        return switch ([x, y]) {
            case [a, b] if (a > 0 && b > 0): "both positive";
            case [a, b] if (a < 0 && b < 0): "both negative";
            case [a, b] if (a == 0 || b == 0): "has zero";
            case _: "other";
        }
    }
}
/**
 * Advanced Pattern Matching Test
 * Tests binary patterns, pin operators, advanced guards, and complex matching scenarios
 */

// Define proper types for testing
typedef PacketSegment = {
    variable: String,
    ?size: Int,
    ?type: String
}

typedef Packet = {
    type: String,
    segments: Array<PacketSegment>
}

typedef TupleResult = {
    ?ok: Bool,
    ?error: Bool,
    ?value: Dynamic,
    ?reason: String,
    ?status: String,
    ?code: Int
}

typedef Message = {
    type: String,
    ?data: {id: Int, name: String},
    ?priority: Int,
    ?message: String,
    ?items: Array<Dynamic>,
    ?cmd: String,
    ?confirmed: Bool
}

typedef BinaryData = {
    binary: String,
    size: Int
}

typedef Request = {
    method: String,
    ?path: String,
    ?body: String,
    ?contentType: String,
    ?id: Int
}

class Main {
    
    /**
     * Simple enum-like pattern matching
     */
    public static function matchSimpleValue(value: Int): String {
        return switch (value) {
            case 0: "zero";
            case 1: "one";
            case 2: "two";
            case n if (n < 0): "negative";
            case n if (n > 100): "large";
            case _: "other";
        };
    }
    
    /**
     * Array pattern matching with guards
     */
    public static function processArray(arr: Array<Int>): String {
        return switch (arr) {
            case []: "empty";
            case [x]: 'single: ${x}';
            case [x, y]: 'pair: ${x},${y}';
            case [x, y, z]: 'triple: ${x},${y},${z}';
            case [first, second, third, fourth]: 'quad: ${first},${second},${third},${fourth}';
            case a if (a.length > 4): 'many: ${a.length} elements';
            case _: "unknown";
        };
    }
    
    /**
     * String pattern matching with guards
     */
    public static function classifyString(str: String): String {
        return switch (str) {
            case "": "empty";
            case "hello": "greeting";
            case "goodbye": "farewell";
            case s if (s.length == 1): "single char";
            case s if (s.length > 10 && s.length <= 20): "medium";
            case s if (s.length > 20): "long";
            case _: "other";
        };
    }
    
    /**
     * Complex number range guards
     */
    public static function classifyNumber(n: Float): String {
        return switch (n) {
            case 0.0: "zero";
            case x if (x > 0 && x <= 1): "tiny";
            case x if (x > 1 && x <= 10): "small";
            case x if (x > 10 && x <= 100): "medium";
            case x if (x > 100 && x <= 1000): "large";
            case x if (x > 1000): "huge";
            case x if (x < 0 && x >= -10): "small negative";
            case x if (x < -10): "large negative";
            case _: "unknown";
        };
    }
    
    /**
     * Boolean combinations with tuples
     */
    public static function matchFlags(active: Bool, verified: Bool, premium: Bool): String {
        return switch ([active, verified, premium]) {
            case [true, true, true]: "full access";
            case [true, true, false]: "verified user";
            case [true, false, false]: "basic user";
            case [false, _, _]: "inactive";
            case [_, false, true]: "unverified premium";
            case _: "other state";
        };
    }
    
    /**
     * Nested array patterns
     */
    public static function matchMatrix(matrix: Array<Array<Int>>): String {
        return switch (matrix) {
            case []: "empty matrix";
            case [[x]]: 'single element: ${x}';
            case [[a, b], [c, d]]: '2x2 matrix: [[${a},${b}],[${c},${d}]]';
            case [[a, b, c], [d, e, f], [g, h, i]]: "3x3 matrix";
            case m if (m.length == m[0].length): 'square matrix ${m.length}x${m.length}';
            case _: "non-square matrix";
        };
    }
    
    /**
     * Multiple guard conditions
     */
    public static function validateAge(age: Int, hasPermission: Bool): String {
        return switch ([age, hasPermission]) {
            case [a, _] if (a < 0): "invalid age";
            case [a, _] if (a >= 0 && a < 13): "child";
            case [a, false] if (a >= 13 && a < 18): "teen without permission";
            case [a, true] if (a >= 13 && a < 18): "teen with permission";
            case [a, _] if (a >= 18 && a < 21): "young adult";
            case [a, _] if (a >= 21 && a < 65): "adult";
            case [a, _] if (a >= 65): "senior";
            case _: "unknown";
        };
    }
    
    /**
     * Type checking guards (simulating is_binary, is_integer, etc.)
     */
    public static function classifyValue(value: Dynamic): String {
        return switch (value) {
            case v if (Std.isOfType(v, String)): 'string: "${v}"';
            case v if (Std.isOfType(v, Int)): 'integer: ${v}';
            case v if (Std.isOfType(v, Float)): 'float: ${v}';
            case v if (Std.isOfType(v, Bool)): 'boolean: ${v}';
            case v if (Std.isOfType(v, Array)): 'array of length ${v.length}';
            case null: "null value";
            case _: "unknown type";
        };
    }
    
    /**
     * List membership simulation
     */
    public static function checkColor(color: String): String {
        var primaryColors = ["red", "green", "blue"];
        var secondaryColors = ["orange", "purple", "yellow"];
        
        return switch (color) {
            case c if (primaryColors.indexOf(c) >= 0): "primary color";
            case c if (secondaryColors.indexOf(c) >= 0): "secondary color";
            case "black" | "white" | "gray": "monochrome";
            case _: "unknown color";
        };
    }
    
    /**
     * Combined patterns with OR
     */
    public static function matchStatus(status: String): String {
        return switch (status) {
            case "active" | "running" | "online": "operational";
            case "paused" | "suspended" | "waiting": "temporarily stopped";
            case "stopped" | "offline" | "disabled": "not operational";
            case "error" | "failed" | "crashed": "error state";
            case _: "unknown status";
        };
    }
    
    public static function main() {
        trace("Advanced pattern matching test");
        
        // Test simple patterns
        trace(matchSimpleValue(0));
        trace(matchSimpleValue(42));
        trace(matchSimpleValue(-5));
        trace(matchSimpleValue(150));
        
        // Test array patterns
        trace(processArray([]));
        trace(processArray([1]));
        trace(processArray([1, 2]));
        trace(processArray([1, 2, 3]));
        trace(processArray([1, 2, 3, 4, 5]));
        
        // Test string patterns
        trace(classifyString(""));
        trace(classifyString("hello"));
        trace(classifyString("x"));
        trace(classifyString("medium length string"));
        trace(classifyString("this is a very long string that exceeds twenty characters"));
        
        // Test number ranges
        trace(classifyNumber(0.0));
        trace(classifyNumber(0.5));
        trace(classifyNumber(5.0));
        trace(classifyNumber(50.0));
        trace(classifyNumber(500.0));
        trace(classifyNumber(5000.0));
        trace(classifyNumber(-5.0));
        trace(classifyNumber(-50.0));
        
        // Test boolean combinations
        trace(matchFlags(true, true, true));
        trace(matchFlags(true, true, false));
        trace(matchFlags(false, false, false));
        
        // Test nested arrays
        trace(matchMatrix([]));
        trace(matchMatrix([[1]]));
        trace(matchMatrix([[1, 2], [3, 4]]));
        trace(matchMatrix([[1, 2, 3], [4, 5, 6], [7, 8, 9]]));
        
        // Test age validation
        trace(validateAge(10, false));
        trace(validateAge(15, true));
        trace(validateAge(25, false));
        trace(validateAge(70, true));
        
        // Test type checking
        trace(classifyValue("hello"));
        trace(classifyValue(42));
        trace(classifyValue(3.14));
        trace(classifyValue(true));
        trace(classifyValue([1, 2, 3]));
        trace(classifyValue(null));
        
        // Test color membership
        trace(checkColor("red"));
        trace(checkColor("orange"));
        trace(checkColor("black"));
        trace(checkColor("pink"));
        
        // Test status patterns
        trace(matchStatus("active"));
        trace(matchStatus("paused"));
        trace(matchStatus("error"));
        trace(matchStatus("unknown"));
    }
}
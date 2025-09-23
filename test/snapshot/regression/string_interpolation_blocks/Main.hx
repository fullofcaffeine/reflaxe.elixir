package;

class Main {
    public static function main() {
        // Test various block expressions in string interpolation
        
        // Case expression
        var status = Status.Active(42);
        trace('Status: ${switch(status) {
            case Active(id): "Active user " + id;
            case Inactive: "Inactive";
            case Suspended(reason): "Suspended: " + reason;
        }}');
        
        // If-else expression
        var count = 5;
        trace('Count: ${if (count > 0) "positive" else if (count < 0) "negative" else "zero"}');
        
        // Nested case in interpolation
        var result: Result = Ok("data");
        trace('Result: ${switch(result) {
            case Ok(value): "Success: " + value;
            case Error(msg): "Failed: " + msg;
        }}');
        
        // Multiple block expressions
        var x = 10;
        var y = 20;
        trace('Comparison: ${if (x > y) "x is greater" else "y is greater"} and sum is ${x + y}');
        
        // Method calls returning blocks (via inline functions)
        trace('Complex: ${getComplexValue(5)}');
        
        // Array comprehension in interpolation
        var nums = [1, 2, 3];
        trace('Doubled: ${[for (n in nums) n * 2]}');
        
        // Nested interpolation with blocks
        var flag = true;
        trace('Nested: ${if (flag) 'Flag is ${if (x > 5) "high" else "low"}' else "No flag"}');
    }
    
    static inline function getComplexValue(n: Int): String {
        return switch(n) {
            case 0: "zero";
            case 1: "one";
            case v if (v < 5): "low";
            case v if (v < 10): "medium";
            case _: "high";
        };
    }
}

enum Status {
    Active(id: Int);
    Inactive;
    Suspended(reason: String);
}

enum Result {
    Ok(value: String);
    Error(message: String);
}
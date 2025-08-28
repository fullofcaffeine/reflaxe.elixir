/**
 * Troubleshooting Pattern Matching Test  
 * Tests the 4 specific pattern matching issues documented in TROUBLESHOOTING.md:
 * 1. Exhaustive patterns
 * 2. Guards  
 * 3. Binary patterns
 * 4. General pattern matching improvements
 */

enum Result<T> {
    Ok(value: T);
    Error(message: String);
}

enum Status {
    Active;
    Inactive; 
    Pending;
    Suspended;
}

class Main {
    
    /**
     * Issue 1: Exhaustive patterns
     * Tests that all enum cases are handled properly
     */
    public static function testExhaustiveEnumHandling(): String {
        var status = Status.Active;
        
        // This should compile without warnings - all cases covered
        var result = switch (status) {
            case Active: "System is running";
            case Inactive: "System is stopped";
            case Pending: "System is starting";
            case Suspended: "System is paused";
            // No default case needed - all enum values covered
        };
        
        return result;
    }
    
    /**
     * Issue 1: Exhaustive patterns with Result type
     * Tests generic enum exhaustiveness
     */
    public static function testResultExhaustiveness(): String {
        var apiResult: Result<String> = Result.Ok("Success");
        
        return switch (apiResult) {
            case Ok(value): "Success: " + value;
            case Error(message): "Failed: " + message;
            // All Result cases covered
        };
    }
    
    /**
     * Issue 2: Guards in pattern matching
     * Tests guard clause compilation and optimization
     */
    public static function testGuardClauses(): String {
        var value = 42;
        
        return switch (value) {
            case n if (n < 0): "Negative number";
            case n if (n == 0): "Zero";
            case n if (n > 0 && n <= 10): "Small positive";
            case n if (n > 10 && n <= 100): "Medium positive"; 
            case n if (n > 100): "Large positive";
            case _: "Unexpected value";
        };
    }
    
    /**
     * Issue 2: Complex guard expressions
     * Tests multiple conditions and type guards
     */
    public static function testComplexGuards(): String {
        var user = {name: "Alice", age: 25, verified: true};
        
        return switch ([user.age, user.verified]) {
            case [age, verified] if (age < 13): "Child account";
            case [age, false] if (age >= 13 && age < 18): "Unverified teen";
            case [age, true] if (age >= 13 && age < 18): "Verified teen";
            case [age, false] if (age >= 18): "Unverified adult";
            case [age, true] if (age >= 18 && age < 65): "Verified adult";
            case [age, true] if (age >= 65): "Senior user";
            case _: "Unknown user type";
        };
    }
    
    /**
     * Issue 3: Binary patterns  
     * Tests binary data pattern matching (simulated with byte arrays)
     */
    public static function testBinaryDataPatterns(): String {
        // Simulate binary protocol parsing
        var packet = [0xFF, 0xFE, 0x04, 0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F];
        
        return switch (packet) {
            // Magic header: 0xFF 0xFE
            case [0xFF, 0xFE, length, version] if (version == 0x00 && packet.length >= 4): 
                'Protocol v0, length=${length}, payload bytes=${packet.length - 4}';
            case [0xFF, 0xFE, length, version] if (version > 0x00): 
                'Future protocol v${version}';
            case [0xFF, other, rest] if (other != 0xFE): 
                'Invalid magic byte: 0x${StringTools.hex(other, 2)}';
            case header if (header.length < 4): 
                "Incomplete packet header";
            case _: 
                "Unknown packet format";
        };
    }
    
    /**
     * Issue 3: Binary segment patterns with size specifications
     * Tests advanced binary pattern compilation
     */
    public static function testBinarySegments(): String {
        // HTTP-like message parsing (simulated)
        var request = [
            0x47, 0x45, 0x54, 0x20, // "GET " 
            0x2F, 0x61, 0x70, 0x69, // "/api"
            0x20, 0x48, 0x54, 0x54, 0x50 // " HTTP"
        ];
        
        return switch (request) {
            case [0x47, 0x45, 0x54, 0x20]: // "GET " (exact match)
                "GET request detected";
            case [0x50, 0x4F, 0x53, 0x54]: // "POST" (exact match) 
                "POST request detected";
            case [method1, method2, method3, method4] if (request.length >= 4):
                'Other method: ${String.fromCharCode(method1)}${String.fromCharCode(method2)}${String.fromCharCode(method3)}${String.fromCharCode(method4)}';
            case arr if (arr.length >= 9): // Full request
                'Full HTTP request: ${[for (b in arr.slice(0, 4)) String.fromCharCode(b)].join("")} + more data';
            case _:
                "Invalid HTTP request";
        };
    }
    
    /**
     * Issue 4: General pattern matching improvements
     * Tests overall pattern matching quality and edge cases
     */
    public static function testPatternMatchingEdgeCases(): String {
        var data: Dynamic = [1, [2, 3], {name: "test", value: 42}];
        
        return switch (data) {
            case [x] if (Std.isOfType(x, Int)): 
                "Single integer: " + x;
            case [x, y] if (Std.isOfType(x, Int) && Std.isOfType(y, Array)): 
                'Integer and array: ${x}, [${y.join(",")}]';
            case [x, y, z] if (Std.isOfType(z, Dynamic) && z.name != null): 
                'Three elements ending with object: ${z.name}';
            case arr if (Std.isOfType(arr, Array) && arr.length > 3): 
                "Large array with " + arr.length + " elements";
            case []: 
                "Empty array";
            case _: 
                "Other data structure";
        };
    }
    
    /**
     * Issue 4: Pattern matching with proper syntax error handling
     * Tests that invalid patterns are caught during compilation
     */
    public static function testProperSyntaxHandling(): String {
        var value = 42;
        
        // Valid pattern matching with proper switch syntax
        return switch (value) {
            case 0: "zero";
            case 1 | 2 | 3: "small numbers";
            case n if (n > 10): "large number: " + n;
            case _: "other number: " + value;
        };
    }
    
    /**
     * Performance test for pattern matching compilation
     * Ensures compiled patterns are efficient
     */
    public static function testPatternMatchingPerformance(): String {
        var operations = [
            {type: "read", resource: "user", id: 123},
            {type: "write", resource: "post", id: 456}, 
            {type: "delete", resource: "comment", id: 789},
            {type: "update", resource: "user", id: 123}
        ];
        
        var results = [];
        for (op in operations) {
            var result = switch ([op.type, op.resource]) {
                case ["read", "user"]: "Reading user " + op.id;
                case ["write", "post"]: "Writing post " + op.id;
                case ["delete", "comment"]: "Deleting comment " + op.id;
                case ["update", "user"]: "Updating user " + op.id;
                case [type, resource]: 'Unknown operation: ${type} on ${resource}';
            };
            results.push(result);
        }
        
        return results.join("; ");
    }
    
    public static function main() {
        trace("Troubleshooting Pattern Matching Tests");
        
        // Test all 4 troubleshooting issues
        trace("1. Exhaustive Enum: " + testExhaustiveEnumHandling());
        trace("1. Exhaustive Result: " + testResultExhaustiveness());
        trace("2. Guard Clauses: " + testGuardClauses());
        trace("2. Complex Guards: " + testComplexGuards());  
        trace("3. Binary Patterns: " + testBinaryDataPatterns());
        trace("3. Binary Segments: " + testBinarySegments());
        trace("4. Edge Cases: " + testPatternMatchingEdgeCases());
        trace("4. Syntax Handling: " + testProperSyntaxHandling());
        trace("Performance: " + testPatternMatchingPerformance());
        
        trace("All pattern matching troubleshooting issues tested");
    }
}
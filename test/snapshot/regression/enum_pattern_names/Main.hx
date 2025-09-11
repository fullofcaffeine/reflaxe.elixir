/**
 * Test case for enum pattern variable names
 * 
 * This test verifies that enum patterns preserve user-specified variable names
 * instead of using generic names (g, g1, g2)
 */

// Test regular enum with meaningful parameter names
enum Status {
    Loading;
    Success(data: String);
    Failure(error: String, code: Int);
}

// Test nested enum patterns  
enum NestedResult {
    Ok(status: Status);
    Error(message: String);
}

class Main {
    public static function main() {
        // Test 1: Simple enum pattern with meaningful names
        var status = Success("Hello World");
        var result1 = switch(status) {
            case Loading:
                "Loading...";
            case Success(data):
                // Should use 'data' not 'g'
                'Got data: $data';
            case Failure(error, code):
                // Should use 'error' and 'code' not 'g' and 'g1'
                'Error $code: $error';
        }
        trace(result1);
        
        // Test 2: Nested enum patterns
        var nested = Ok(Success("Nested"));
        var result2 = switch(nested) {
            case Ok(Loading):
                "Still loading";
            case Ok(Success(data)):
                // Should preserve 'data' name
                'Nested success: $data';
            case Ok(Failure(error, code)):
                'Nested failure $code: $error';
            case Error(message):
                'Top level error: $message';
        }
        trace(result2);
        
        // Test 3: Pattern with unused parameters
        var mixed = Failure("Network error", 500);
        var result3 = switch(mixed) {
            case Success(_):
                "Success (data ignored)";
            case Failure(error, _):
                // Should use 'error' for first param, underscore for second
                'Error occurred: $error';
            case Loading:
                "Loading";
        }
        trace(result3);
    }
}
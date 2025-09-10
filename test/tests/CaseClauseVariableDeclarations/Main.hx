// Test for variable declarations in case clause bodies
// Regression test for issue where assignmentExtractionPass was dropping variable declarations

enum Result<T> {
    Ok(value: T);
    Error(error: String);
}

class Main {
    // Test case clause with variable declaration
    static function processResult(result: Result<String>): String {
        return switch(result) {
            case Ok(value):
                // Simple case - just return the value
                value;
            case Error(error):
                // Variable declaration that was being dropped
                var message = "Error occurred: " + error;
                var details = "Details: " + message;
                
                // Use both variables
                trace(message);
                trace(details);
                
                // Return the details
                details;
        }
    }
    
    // Test nested blocks in case clauses
    static function processNestedCase(result: Result<Int>): String {
        return switch(result) {
            case Ok(value):
                if (value > 0) {
                    // Variable declaration inside nested if
                    var positive = "Positive: " + value;
                    positive;
                } else {
                    var negative = "Negative or zero: " + value;
                    negative;
                }
            case Error(error):
                // Variable in error case
                var errorMsg = "Failed: " + error;
                errorMsg;
        }
    }
    
    // Test fn body with variable declaration
    static function testFunctionBody(): Void {
        var fn = function(x: Int) {
            // Variable declaration at start of function body
            var doubled = x * 2;
            var tripled = x * 3;
            trace('Doubled: $doubled, Tripled: $tripled');
            return doubled + tripled;
        };
        
        fn(5);
    }
    
    // Test try/catch with variable declarations
    static function testTryCatch(): String {
        try {
            var risky = performRiskyOperation();
            var processed = "Processed: " + risky;
            return processed;
        } catch (e: Dynamic) {
            // Variable declaration in catch block
            var errorMessage = "Caught error: " + Std.string(e);
            var timestamp = "At: " + Date.now().toString();
            return errorMessage + " " + timestamp;
        }
    }
    
    static function performRiskyOperation(): String {
        if (Math.random() > 0.5) {
            throw "Random failure";
        }
        return "Success";
    }
    
    static function main() {
        // Test all cases
        trace(processResult(Ok("success")));
        trace(processResult(Error("failure")));
        
        trace(processNestedCase(Ok(10)));
        trace(processNestedCase(Ok(-5)));
        trace(processNestedCase(Error("invalid")));
        
        testFunctionBody();
        trace(testTryCatch());
    }
}
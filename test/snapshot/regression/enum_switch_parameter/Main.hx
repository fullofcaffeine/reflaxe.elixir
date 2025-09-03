/**
 * Regression test for parameter underscore consistency with enum switch expressions
 * 
 * Issue: When a function parameter is only used in a switch expression on an enum,
 * the compiler incorrectly marked it as unused and prefixed with underscore.
 * This caused "undefined variable" errors because the switch still referenced
 * the non-underscored name.
 * 
 * Fix: Enhanced isParameterUsedInExpr to properly detect TEnumParameter and 
 * TEnumIndex expressions that reference the parameter.
 */

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class Main {
    public static function main() {
        var testResult: Result<String, String> = Ok("success");
        
        // Test all the affected functions
        var opt = toOption(testResult);
        var unwrapped = unwrapOr(testResult, "default");
        
        trace(opt);
        trace(unwrapped);
    }
    
    /**
     * Convert Result to Option - parameter MUST be used in switch
     */
    public static function toOption<T, E>(result: Result<T, E>): Option<T> {
        return switch(result) {
            case Ok(value): Some(value);
            case Error(_): None;
        };
    }
    
    /**
     * Extract value or return default - parameter MUST be used in switch
     */
    public static function unwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T {
        return switch(result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        };
    }
}

enum Option<T> {
    Some(value: T);
    None;
}
/**
 * Test for PatternMatchingTransforms module
 * Verifies that switch statements are properly transformed to Elixir case expressions
 */
class Main {
    static function main() {
        // Test basic switch transformation
        var result = processValue(Ok("success"));
        trace(result);
        
        result = processValue(Error("failed"));
        trace(result);
        
        // Test switch with default case
        var color = describeColor(Red);
        trace(color);
        
        color = describeColor(Green);
        trace(color);
        
        color = describeColor(Blue);
        trace(color);
        
        // Test nested pattern matching
        var nested = handleNested(Some(Ok(42)));
        trace(nested);
    }
    
    static function processValue(value: Result<String, String>): String {
        return switch(value) {
            case Ok(msg):
                'Success: $msg';
            case Error(err):
                'Error: $err';
        };
    }
    
    static function describeColor(color: Color): String {
        return switch(color) {
            case Red:
                "The color is red";
            case Green:
                "The color is green";
            case Blue:
                "The color is blue";
        };
    }
    
    static function handleNested(value: Option<Result<Int, String>>): String {
        return switch(value) {
            case Some(Ok(n)):
                'Got number: $n';
            case Some(Error(e)):
                'Got error: $e';
            case None:
                'Got nothing';
        };
    }
}

// Simple enums for testing
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

enum Color {
    Red;
    Green;
    Blue;
}

enum Option<T> {
    Some(value: T);
    None;
}
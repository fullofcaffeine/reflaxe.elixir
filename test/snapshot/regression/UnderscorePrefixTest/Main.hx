package;

class Main {
    static function main() {
        // Test 1: Unused variable in function
        testUnusedVariable();
        
        // Test 2: Unused enum extraction
        testUnusedEnumExtraction();
        
        // Test 3: Unused function parameter
        testUnusedParameter(42);
    }
    
    static function testUnusedVariable() {
        var x = 10;  // Not used
        var y = 20;  // Used
        trace(y);
    }
    
    static function testUnusedEnumExtraction() {
        var result: Result<String, String> = Ok("success");
        
        switch(result) {
            case Ok(value):  // value is not used
                trace("Success!");
            case Error(msg):  // msg is used
                trace("Error: " + msg);
        }
    }
    
    static function testUnusedParameter(unusedParam: Int) {
        // unusedParam is not used in the function body
        trace("This function doesn't use its parameter");
    }
}

enum Result<T, E> {
    Ok(value: T);
    Error(msg: E);
}
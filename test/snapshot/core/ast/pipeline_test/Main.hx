class Main {
    static function main() {
        // Test basic literals
        var x = 42;
        var y = 3.14;
        var s = "Hello, AST!";
        var b = true;
        
        // Test basic operations
        var sum = x + 10;
        var product = x * 2;
        var comparison = x > 20;
        
        // Test simple if
        if (b) {
            trace("Boolean is true");
        } else {
            trace("Boolean is false");
        }
        
        // Test function call
        trace("Sum: " + sum);
    }
}
/**
 * Test for class instance methods and field access
 * 
 * This test validates that instance methods can properly access instance fields
 * using 'this' and that it gets correctly translated to the struct parameter.
 */
class Main {
    static function main() {
        var printer = new SimplePrinter("Hello");
        var result = printer.print(" World");
        trace(result); // Should output "Hello World"
    }
}

/**
 * Simple class with instance field and method
 */
class SimplePrinter {
    var prefix: String;
    
    public function new(prefix: String) {
        this.prefix = prefix;
    }
    
    public function print(suffix: String): String {
        // This should compile to accessing struct.prefix
        return this.prefix + suffix;
    }
}
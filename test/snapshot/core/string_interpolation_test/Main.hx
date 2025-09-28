class Main {
    static function main() {
        var name = "World";
        var age = 25;
        
        // Test basic concatenation
        var greeting = "Hello " + name + "!";
        trace(greeting);
        
        // Test mixed type concatenation
        var info = "Name: " + name + ", Age: " + age;
        trace(info);
        
        // Test complex expression
        var result = "Result: " + (10 + 5) + " points";
        trace(result);
    }
}
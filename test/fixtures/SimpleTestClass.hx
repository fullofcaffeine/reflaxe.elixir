package;

/**
 * Simple test class to verify ElixirCompiler works
 * This will be compiled to Elixir code
 */
class SimpleTestClass {
    public var name: String;
    public var age: Int;
    
    public function new(name: String, age: Int) {
        this.name = name;
        this.age = age;
    }
    
    public function greet(): String {
        return "Hello, my name is " + name + " and I am " + age + " years old";
    }
    
    public static function main() {
        var person = new SimpleTestClass("Alice", 30);
        trace(person.greet());
    }
}
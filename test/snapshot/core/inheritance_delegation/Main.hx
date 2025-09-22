/**
 * Comprehensive inheritance test for Haxe→Elixir delegation pattern
 * 
 * Tests:
 * - Basic class inheritance with super method calls
 * - Exception inheritance with haxe.Exception
 * - Method delegation to parent classes
 * - Field inheritance and override
 */
class Main {
    public static function main() {
        // Test basic inheritance
        testBasicInheritance();
        
        // Test exception inheritance
        testExceptionInheritance();
        
        // Test method override
        testMethodOverride();
    }
    
    /**
     * Test basic class inheritance
     */
    static function testBasicInheritance() {
        var child = new Child("Alice", 25);
        trace("Name: " + child.getName());
        trace("Age: " + child.getAge());
        trace("Description: " + child.getDescription());
    }
    
    /**
     * Test exception class inheritance
     */
    static function testExceptionInheritance() {
        try {
            throw new CustomException("Something went wrong!");
        } catch (e: CustomException) {
            trace("Caught exception: " + e.toString());
        }
    }
    
    /**
     * Test method override with super call
     */
    static function testMethodOverride() {
        var special = new SpecialChild("Bob", 30);
        trace("Special description: " + special.getDescription());
    }
}

/**
 * Base class for inheritance testing
 */
class Parent {
    private var name: String;
    
    public function new(name: String) {
        this.name = name;
    }
    
    public function getName(): String {
        return name;
    }
    
    public function getDescription(): String {
        return "Parent: " + name;
    }
}

/**
 * Child class extending Parent
 */
class Child extends Parent {
    private var age: Int;
    
    public function new(name: String, age: Int) {
        super(name);
        this.age = age;
    }
    
    public function getAge(): Int {
        return age;
    }
    
    override public function getDescription(): String {
        return super.getDescription() + ", Age: " + age;
    }
}

/**
 * Grandchild class with additional override
 */
class SpecialChild extends Child {
    public function new(name: String, age: Int) {
        super(name, age);
    }
    
    override public function getDescription(): String {
        return "Special " + super.getDescription();
    }
}

/**
 * Custom exception class extending haxe.Exception
 */
class CustomException extends haxe.Exception {
    public function new(message: String) {
        super(message);
    }
    
    override public function toString(): String {
        return "CustomException: " + message;
    }
}
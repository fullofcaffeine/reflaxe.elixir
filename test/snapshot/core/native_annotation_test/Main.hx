// Test @:native annotations on extern class static methods

@:native("TestModule")
extern class TestExtern {
    @:native("original_name")
    static function mappedMethod(): String;
    
    // Method without @:native should be snake_cased
    static function normalMethod(): String;
}

class Main {
    static function main() {
        // Test both mapped and normal methods
        var result1 = TestExtern.mappedMethod();
        var result2 = TestExtern.normalMethod();
        
        trace('Mapped method result: $result1');
        trace('Normal method result: $result2');
    }
}
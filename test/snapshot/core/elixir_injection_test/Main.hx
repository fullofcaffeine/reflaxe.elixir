package;

class Main {
    static function main() {
        testElixirInjection();
    }
    
    static function testElixirInjection() {
        var result = untyped __elixir__("42");
        trace("Result: " + result);
    }
}
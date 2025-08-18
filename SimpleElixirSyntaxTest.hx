import elixir.Syntax;

class SimpleElixirSyntaxTest {
    static function main() {
        // Test direct elixir.Syntax.code() call
        var directTest = Syntax.code("DateTime.utc_now()");
        trace("Direct syntax test: " + directTest);
        
        // Test with placeholders
        var name = "Alice";
        var age = 30;
        var withArgs = Syntax.code("Map.put(%{}, {0}, {1})", name, age);
        trace("With args: " + withArgs);
    }
}
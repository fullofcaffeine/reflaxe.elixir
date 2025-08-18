import elixir.Syntax;

class Test {
    static function main() {
        // Test direct elixir.Syntax.code() call
        var directTest = Syntax.code("DateTime.utc_now()");
        trace("Direct syntax test: " + directTest);
        
        // Test that Date.hx compiles with new elixir.Syntax approach
        var date = new Date(2024, 0, 1, 12, 0, 0);
        trace("Date compilation test successful");
        trace("Current time: " + Date.now().toString());
        trace("Date created: " + date.toString());
    }
}
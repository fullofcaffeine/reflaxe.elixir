// Test for synthetic bindings in case clauses
// The Haxe optimizer removes "unused" variables that are only referenced in __elixir__() injections

enum Result<T> {
    Ok(value: T);
    Error(error: String);
}

class Main {
    static function processResult(result: Result<String>): String {
        return switch(result) {
            case Ok(value):
                // Simple case - just return the value
                value;
            case Error(error):
                // This variable declaration gets optimized away by Haxe
                // because it only sees usage inside __elixir__()
                var message = "Error occurred: " + error;
                
                // The reference to 'message' here is inside an Elixir injection
                // So Haxe thinks 'message' is unused and removes the TVar
                untyped __elixir__('IO.puts({0})', message);
                
                // Return something
                "failed";
        }
    }
    
    static function main() {
        processResult(Ok("success"));
        processResult(Error("something went wrong"));
    }
}
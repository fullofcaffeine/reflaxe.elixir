/**
 * Test for @:elixirIdiomatic annotation
 * 
 * Validates that user-defined enums with @:elixirIdiomatic annotation
 * generate idiomatic Elixir patterns ({:ok, value} / :error)
 * instead of literal patterns ({:some, value} / :none).
 */

// User-defined enum WITH @:elixirIdiomatic annotation
@:elixirIdiomatic
enum UserOption<T> {
    Some(value: T);
    None;
}

// User-defined enum WITHOUT @:elixirIdiomatic annotation (for comparison)
enum PlainOption<T> {
    Some(value: T);
    None;
}

// Custom Result-like enum WITH @:elixirIdiomatic annotation
@:elixirIdiomatic
enum ApiResult<T, E> {
    Ok(value: T);
    Error(reason: E);
}

class Main {
    
    /**
     * Test idiomatic Option pattern generation
     * Should generate {:ok, value} and :error patterns
     */
    static function testIdiomaticOption(): Void {
        // These should compile to idiomatic patterns
        var some = UserOption.Some("test");     // → {:ok, "test"}
        var none = UserOption.None;             // → :error
        
        trace("Idiomatic option some: " + some);
        trace("Idiomatic option none: " + none);
    }
    
    /**
     * Test literal Option pattern generation  
     * Should generate {:some, value} and :none patterns
     */
    static function testLiteralOption(): Void {
        // These should compile to literal patterns
        var some = PlainOption.Some("test");    // → {:some, "test"}
        var none = PlainOption.None;            // → :none
        
        trace("Literal option some: " + some);
        trace("Literal option none: " + none);
    }
    
    /**
     * Test idiomatic Result pattern generation
     * Should generate {:ok, value} and {:error, reason} patterns
     */
    static function testIdiomaticResult(): Void {
        // These should compile to idiomatic patterns
        var ok = Ok("success");          // → {:ok, "success"}
        var error = Error("failed");    // → {:error, "failed"}
        
        trace("Idiomatic result ok: " + ok);
        trace("Idiomatic result error: " + error);
    }
    
    /**
     * Test pattern matching with idiomatic patterns
     */
    static function testPatternMatching(): Void {
        var userOpt = UserOption.Some(42);
        
        // Pattern matching should work with idiomatic patterns
        switch (userOpt) {
            case Some(value):
                trace("Got value: " + value);
            case None:
                trace("Got none");
        }
        
        var result = Ok("data");
        
        switch (result) {
            case Ok(data):
                trace("Success: " + data);
            case Error(reason):
                trace("Error: " + reason);
        }
    }
    
    static function main(): Void {
        trace("=== Testing @:elixirIdiomatic Annotation ===");
        
        testIdiomaticOption();
        testLiteralOption();
        testIdiomaticResult();
        testPatternMatching();
        
        trace("=== Test Complete ===");
    }
}
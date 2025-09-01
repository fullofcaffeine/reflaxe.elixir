package;

/**
 * Test for @:phoenixWeb annotation transformation
 * 
 * Verifies that:
 * 1. ModuleBuilder detects @:phoenixWeb annotation
 * 2. Metadata is preserved through compilation pipeline
 * 3. AnnotationTransforms applies phoenixWebTransformPass
 * 4. Generated module contains Phoenix Web macros
 */
@:phoenixWeb
@:native("TestAppWeb")
class TestAppWeb {
    /**
     * Static paths for Phoenix asset serving
     */
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }
}

// Test that @:phoenixWebModule also works (alternative annotation)
@:phoenixWebModule
@:native("AlternateAppWeb")
class AlternateAppWeb {
    public static function static_paths(): Array<String> {
        return ["css", "js", "img"];
    }
}
/**
 * Display: Haxe display server types for Elixir target
 * 
 * WHY: Reflaxe framework expects certain display server types to exist.
 * 
 * WHAT: Provides minimal types needed for Reflaxe compilation.
 * 
 * HOW: Stub implementations for metadata and display-related types.
 */
package haxe.display;

/**
 * Display server types container.
 */
class Display {
    // Empty class for now - Reflaxe imports Display.MetadataTarget
}

/**
 * Metadata target enumeration.
 * Defines where metadata can be applied in Haxe code.
 * This will be accessible as Display.MetadataTarget through the import.
 */
typedef MetadataTarget = DisplayMetadataTarget;

/**
 * Actual metadata target enum implementation.
 */
enum abstract DisplayMetadataTarget(String) to String {
    var Class = "class";
    var Field = "field";
    var Expr = "expr";
    var Function = "function";
    var Variable = "variable";
    var Type = "type";
    var Argument = "argument";
}
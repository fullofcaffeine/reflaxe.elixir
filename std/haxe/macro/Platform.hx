/**
 * Platform: Cross-platform target enumeration for Haxe
 * 
 * WHY: Reflaxe needs to identify the compilation target platform.
 * 
 * WHAT: Defines all available Haxe compilation targets.
 * 
 * HOW: String-based enum abstract for platform identification.
 */
package haxe.macro;

/**
 * Cross-platform target enumeration.
 */
enum abstract Platform(String) to String from String {
    var Cross = "cross";
    var Js = "js";
    var Lua = "lua";
    var Neko = "neko";
    var Flash = "flash";
    var Php = "php";
    var Cpp = "cpp";
    var Cs = "cs";
    var Java = "java";
    var Jvm = "jvm";
    var Python = "python";
    var Hl = "hl";
    var Eval = "eval";
    var Interp = "interp";
}

// Global constant for Reflaxe compatibility
final Cross = "cross";
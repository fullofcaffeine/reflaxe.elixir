/**
 * Compiler: Minimal stub for Elixir target
 * 
 * WHY: The standard Haxe macro.Compiler uses exception handling that's
 * incompatible with the Elixir target's catch clause typing.
 * 
 * WHAT: A minimal stub that provides the Compiler API without the
 * problematic exception handling. Most macro operations are compile-time
 * only and don't need runtime implementation.
 * 
 * HOW: Empty implementations for methods that would use exceptions.
 * Macro operations happen at Haxe compile time, not Elixir runtime.
 */
package haxe.macro;

// Global constant for Reflaxe compatibility
final Cross = "cross";

/**
 * Metadata description type used by the compiler.
 */
typedef MetadataDescription = {
    var metadata: String;  // The metadata name (single string, not array)
    var doc: String;
    var params: Array<String>;  // Changed from 'parameters' to 'params' to match Reflaxe
    var platforms: Array<String>;
    var targets: Array<haxe.display.Display.MetadataTarget>;  // Array of MetadataTarget enum values
}

/**
 * Compiler configuration type.
 */
typedef CompilerConfiguration = {
    var version: String;
    var args: Array<String>;
    var debug: Bool;
    var verbose: Bool;
    var foptimize: Bool;
    var platform: String;
    var platformConfig: Dynamic;
    var stdPath: Array<String>;
    var mainClass: String;
    var packages: Array<String>;
}

// Move Platform out of class to make it directly accessible

/**
 * Compiler API for macro-time operations.
 * Note: Most of these are compile-time only and don't need runtime implementation.
 */
class Compiler {
    /**
     * Add a compilation define.
     * This is a compile-time operation.
     */
    public static function define(flag: String, ?value: String): Void {
        // Compile-time only
    }
    
    /**
     * Get a compilation define value.
     * This is a compile-time operation.
     */
    public static function getDefine(key: String): String {
        // Compile-time only
        return null;
    }
    
    /**
     * Add a classpath for compilation.
     * This is a compile-time operation.
     */
    public static function addClassPath(path: String): Void {
        // Compile-time only
    }
    
    /**
     * Include a package or type.
     * This is a compile-time operation.
     */
    public static function include(pack: String, ?rec: Bool = true, ?ignore: Array<String> = null, ?classPaths: Array<String> = null): Void {
        // Compile-time only
    }
    
    /**
     * Exclude a package or type.
     * This is a compile-time operation.
     */
    public static function exclude(pack: String, ?rec: Bool = true): Void {
        // Compile-time only
    }
    
    /**
     * Keep a type from being eliminated by DCE.
     * This is a compile-time operation.
     */
    public static function keep(?path: String, ?paths: Array<String>, ?recursive: Bool = true): Void {
        // Compile-time only
    }
    
    /**
     * Set null safety mode for compilation.
     * This is a compile-time operation.
     */
    public static function nullSafety(mode: String, ?paths: Array<String>): Void {
        // Compile-time only
    }
    
    /**
     * Get compiler configuration.
     * This is a compile-time operation.
     */
    public static function getConfiguration(): CompilerConfiguration {
        // Compile-time only
        return null;
    }
    
    /**
     * Add global metadata.
     * This is a compile-time operation.
     */
    public static function addGlobalMetadata(path: String, meta: String, ?recursive: Bool = true): Void {
        // Compile-time only
    }
    
    /**
     * Register custom metadata.
     * This is a compile-time operation.
     */
    public static function registerCustomMetadata(meta: MetadataDescription, ?tags: Array<String>): Void {
        // Compile-time only
    }
}
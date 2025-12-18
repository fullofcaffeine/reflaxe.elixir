package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * Path module extern definitions for Elixir standard library
 * Provides type-safe interfaces for path manipulation operations
 * 
 * Maps to Elixir's Path module functions with proper type signatures
 * Essential for file system path operations, joining, and normalization
 */
@:native("Path")
extern class Path {
    
    // Path construction and joining
    @:native("Path.join")
    public static function join(paths: Array<String>): String; // Join multiple path components
    
    @:native("Path.join")
    public static function joinTwo(left: String, right: String): String; // Join two paths
    
    @:native("Path.absname")
    public static function absname(path: String): String; // Convert to absolute path
    
    @:native("Path.absname")
    public static function absnameRelativeTo(path: String, relativeTo: String): String;
    
    @:native("Path.expand")
    public static function expand(path: String): String; // Expand path with ~ and environment variables
    
    @:native("Path.expand")
    public static function expandRelativeTo(path: String, relativeTo: String): String;
    
    // Path information and decomposition
    @:native("Path.basename")
    public static function basename(path: String): String; // Get basename (filename with extension)
    
    @:native("Path.basename")
    public static function basenameWithExtension(path: String, extension: String): String; // Remove specific extension
    
    @:native("Path.dirname")
    public static function dirname(path: String): String; // Get directory name
    
    @:native("Path.extname")
    public static function extname(path: String): String; // Get file extension
    
    @:native("Path.rootname")
    public static function rootname(path: String): String; // Remove extension from filename
    
    @:native("Path.rootname")
    public static function rootnameWithExtension(path: String, extension: String): String; // Remove specific extension
    
    @:native("Path.split")
    public static function split(path: String): Array<String>; // Split path into components
    
    // Path type checking and validation
    @:native("Path.type")
    public static function type(name: String): String; // :absolute | :relative | :volumerelative
    
    @:native("Path.absname?")
    public static function isAbsolute(path: String): Bool; // Check if path is absolute
    
    // Path normalization and cleaning
    @:native("Path.relative")
    public static function relative(name: String): String; // Convert absolute to relative
    
    @:native("Path.relative_to")
    public static function relativeTo(path: String, from: String): String; // Make path relative to another
    
    @:native("Path.relative_to_cwd")
    public static function relativeToCwd(path: String): String; // Make relative to current directory
    
    // Path wildcard matching
    @:native("Path.wildcard")
    public static function wildcard(glob: String): Array<String>; // Find files matching glob pattern
    
    @:native("Path.wildcard")
    public static function wildcardWithOptions(glob: String, options: Map<String, Term>): Array<String>;
    
    // Path constants
    public static inline var SEPARATOR: String = "/"; // Path separator for current OS
    public static inline var CURRENT_DIR: String = "."; // Current directory
    public static inline var PARENT_DIR: String = ".."; // Parent directory
    
    // Common path operations helpers
    public static inline function normalize(path: String): String {
        return expand(path);
    }
    
    public static inline function getFilename(path: String): String {
        return basename(path);
    }
    
    public static inline function getFilenameWithoutExtension(path: String): String {
        return rootname(basename(path));
    }
    
    public static inline function getExtension(path: String): String {
        var ext = extname(path);
        return ext.length > 0 && ext.charAt(0) == "." ? ext.substr(1) : ext;
    }
    
    public static inline function getDirectory(path: String): String {
        return dirname(path);
    }
    
    public static inline function changeExtension(path: String, newExtension: String): String {
        var root = rootname(path);
        var ext = newExtension.charAt(0) == "." ? newExtension : "." + newExtension;
        return root + ext;
    }
    
    public static inline function appendPath(basePath: String, subPath: String): String {
        return join([basePath, subPath]);
    }
    
    public static inline function combinePaths(paths: Array<String>): String {
        return join(paths);
    }
    
    // Common path checks
    public static inline function hasExtension(path: String, extension: String): Bool {
        var pathExt = extname(path);
        var checkExt = extension.charAt(0) == "." ? extension : "." + extension;
        return pathExt == checkExt;
    }
    
    public static inline function isRelative(path: String): Bool {
        return !isAbsolute(path);
    }
    
    public static inline function isEmpty(path: String): Bool {
        return path == null || path == "";
    }
    
    // File path utilities
    public static inline function ensureTrailingSeparator(path: String): String {
        return path.charAt(path.length - 1) == SEPARATOR ? path : path + SEPARATOR;
    }
    
    public static inline function removeTrailingSeparator(path: String): String {
        return path.charAt(path.length - 1) == SEPARATOR ? path.substr(0, path.length - 1) : path;
    }
    
    // Common directory operations
    public static inline function parentDirectory(path: String): String {
        return dirname(path);
    }
    
    public static inline function currentDirectory(): String {
        return CURRENT_DIR;
    }
    
    public static inline function isCurrentDirectory(path: String): Bool {
        return path == CURRENT_DIR;
    }
    
    public static inline function isParentDirectory(path: String): Bool {
        return path == PARENT_DIR;
    }
    
    // Path building helpers
    public static inline function buildPath(directory: String, filename: String, extension: String = ""): String {
        var fullFilename = extension != "" ? filename + (extension.charAt(0) == "." ? extension : "." + extension) : filename;
        return join([directory, fullFilename]);
    }
    
    public static inline function tempPath(filename: String = "temp"): String {
        return join(["/tmp", filename]);
    }
    
    public static inline function homePath(subpath: String = ""): String {
        var home = expand("~/");
        return subpath != "" ? join([home, subpath]) : home;
    }
}

#end

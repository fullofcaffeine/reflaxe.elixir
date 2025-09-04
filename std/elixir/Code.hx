package elixir;

#if (macro || reflaxe_runtime)

/**
 * Code module extern definitions for Elixir standard library
 * Provides type-safe interfaces for code compilation, evaluation, and module management
 * 
 * Maps to Elixir's Code module functions with proper type signatures
 * Essential for metaprogramming, dynamic evaluation, and module inspection
 */
@:native("Code")
extern class Code {
    
    // Code evaluation
    @:native("eval_string")
    static function evalString(string: String, ?binding: Array<{_0: Dynamic, _1: Dynamic}>): {_0: Dynamic, _1: Array<{_0: Dynamic, _1: Dynamic}>}; // {result, binding}
    
    @:native("eval_string")
    static function evalStringWithOpts(string: String, binding: Array<{_0: Dynamic, _1: Dynamic}>, opts: CodeEvalOptions): {_0: Dynamic, _1: Array<{_0: Dynamic, _1: Dynamic}>};
    
    @:native("eval_file")
    static function evalFile(file: String, ?relativeTo: String): {_0: Dynamic, _1: Array<{_0: Dynamic, _1: Dynamic}>};
    
    @:native("eval_quoted")
    static function evalQuoted(quoted: Dynamic, ?binding: Array<{_0: Dynamic, _1: Dynamic}>): {_0: Dynamic, _1: Array<{_0: Dynamic, _1: Dynamic}>};
    
    // Code compilation
    @:native("compile_string")
    static function compileString(string: String, ?file: String): Array<{_0: Dynamic, _1: String}>; // [{module, binary}]
    
    @:native("compile_file")
    static function compileFile(file: String, ?destDir: String): Array<{_0: Dynamic, _1: String}>;
    
    @:native("compile_quoted")
    static function compileQuoted(quoted: Dynamic): Array<{_0: Dynamic, _1: String}>;
    
    @:native("string_to_quoted")
    static function stringToQuoted(string: String): {_0: String, _1: Dynamic}; // {:ok, quoted} | {:error, reason}
    
    @:native("string_to_quoted!")
    static function stringToQuotedBang(string: String): Dynamic; // Returns quoted or raises
    
    @:native("string_to_quoted")
    static function stringToQuotedWithOpts(string: String, opts: CodeParseOptions): {_0: String, _1: Dynamic};
    
    @:native("quoted_to_algebra")
    static function quotedToAlgebra(quoted: Dynamic, ?opts: CodeFormatOptions): Dynamic; // Returns document algebra
    
    // Code loading
    @:native("require_file")
    static function requireFile(file: String, ?relativeTo: String): Array<Dynamic>; // List of loaded modules
    
    @:native("load_file")
    static function loadFile(file: String, ?relativeTo: String): Array<{_0: Dynamic, _1: String}>;
    
    @:native("unload_files")
    static function unloadFiles(files: Array<String>): Void;
    
    @:native("prepend_path")
    static function prependPath(path: String): Bool; // true if added, false if already present
    
    @:native("append_path")
    static function appendPath(path: String): Bool;
    
    @:native("delete_path")
    static function deletePath(path: String): Bool; // true if removed, false if not present
    
    // Code paths
    @:native("get_path")
    static function getPath(): Array<String>; // Get code load paths
    
    @:native("set_path")
    static function setPath(paths: Array<String>): Array<String>; // Set code load paths
    
    @:native("compiler_options")
    static function compilerOptions(): Map<String, Dynamic>; // Get compiler options
    
    @:native("compiler_options")
    static function setCompilerOptions(opts: Map<String, Dynamic>): Map<String, Dynamic>;
    
    // Module operations
    @:native("ensure_loaded")
    static function ensureLoaded(module: Dynamic): {_0: String, _1: Dynamic}; // {:module, module} | {:error, reason}
    
    @:native("ensure_loaded?")
    static function isEnsureLoaded(module: Dynamic): Bool;
    
    @:native("ensure_compiled")
    static function ensureCompiled(module: Dynamic): {_0: String, _1: Dynamic}; // {:module, module} | {:error, reason}
    
    @:native("ensure_compiled!")
    static function ensureCompiledBang(module: Dynamic): Dynamic; // Returns module or raises
    
    @:native("ensure_all_loaded")
    static function ensureAllLoaded(modules: Array<Dynamic>): String; // :ok | raises
    
    // Module availability
    @:native("loaded?")
    static function isLoaded(module: Dynamic): Bool;
    
    @:native("available?")
    static function isAvailable(module: Dynamic): Bool;
    
    @:native("module?")
    static function isModule(module: Dynamic): Bool;
    
    // Module information
    @:native("fetch_docs")
    static function fetchDocs(module: Dynamic): {_0: String, _1: Dynamic}; // {:docs_v1, ...} | {:error, reason}
    
    @:native("get_docs")
    static function getDocs(module: Dynamic, kind: String): Null<Dynamic>; // :all, :moduledoc, :docs, :callback_docs, :type_docs
    
    // Formatting
    @:native("format_string!")
    static function formatStringBang(string: String, ?opts: CodeFormatOptions): String;
    
    @:native("format_file!")
    static function formatFileBang(file: String, ?opts: CodeFormatOptions): String;
    
    // Cursor information
    @:native("cursor_context")
    static function cursorContext(string: String, ?opts: CursorOptions): Dynamic;
    
    @:native("fragment")
    static function fragment(string: String, ?opts: FragmentOptions): {_0: String, _1: Dynamic};
    
    // Helper functions for common operations
    public static inline function eval(code: String): Dynamic {
        var result = evalString(code);
        return result._0;
    }
    
    public static inline function evalWithBinding(code: String, vars: Map<String, Dynamic>): Dynamic {
        var binding: Array<{_0: Dynamic, _1: Dynamic}> = [];
        for (key in vars.keys()) {
            binding.push({_0: untyped __elixir__(':{0}', key), _1: vars.get(key)});
        }
        var result = evalString(code, binding);
        return result._0;
    }
    
    public static inline function loadAndRequire(file: String): Bool {
        try {
            requireFile(file);
            return true;
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    public static inline function safeEval(code: String): Null<Dynamic> {
        try {
            return eval(code);
        } catch (e: Dynamic) {
            return null;
        }
    }
    
    public static inline function parseCode(code: String): Null<Dynamic> {
        var result = stringToQuoted(code);
        return result._0 == "ok" ? result._1 : null;
    }
    
    public static inline function format(code: String): String {
        try {
            return formatStringBang(code);
        } catch (e: Dynamic) {
            return code; // Return original if formatting fails
        }
    }
    
    public static inline function moduleExists(moduleName: String): Bool {
        var atom = untyped __elixir__('String.to_atom({0})', moduleName);
        return isAvailable(atom);
    }
}

/**
 * Options for Code.eval_* functions
 */
typedef CodeEvalOptions = {
    ?file: String,
    ?line: Int,
    ?tracers: Array<Dynamic>,
    ?localTracking: Bool,
    ?parserOptions: Array<Dynamic>
}

/**
 * Options for Code.string_to_quoted
 */
typedef CodeParseOptions = {
    ?file: String,
    ?line: Int,
    ?column: Int,
    ?columns: Bool,
    ?tokenMetadata: Bool,
    ?literalEncoder: Dynamic -> Dynamic,
    ?quotedGenerator: Dynamic -> Dynamic,
    ?unescape: Bool,
    ?warnOnUnusedAlias: Bool
}

/**
 * Options for Code.format_*
 */
typedef CodeFormatOptions = {
    ?file: String,
    ?lineLength: Int,
    ?localWithoutParens: Array<Dynamic>,
    ?forceDoEndBlocks: Bool,
    ?normalizeCompilerMetadata: Bool
}

/**
 * Options for Code.cursor_context
 */
typedef CursorOptions = {
    ?line: Int,
    ?column: Int,
    ?file: String,
    ?tokenMetadata: Bool
}

/**
 * Options for Code.fragment
 */
typedef FragmentOptions = {
    ?line: Int,
    ?column: Int,
    ?indentationColumn: Int,
    ?tokenMetadata: Bool
}

#end
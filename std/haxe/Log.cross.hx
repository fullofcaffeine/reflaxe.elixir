package haxe;

/**
 * Cross-platform Log implementation for Elixir target
 * 
 * This overrides Haxe's standard Log class to generate idiomatic Elixir output.
 * Instead of generating Log.trace() calls, we generate IO.inspect() for better
 * Elixir idioms.
 */
@:coreApi
class Log {
    /**
     * Format output with position information
     */
    public static function formatOutput(v: Dynamic, infos: PosInfos): String {
        var str = Std.string(v);
        if (infos == null) {
            return str;
        }
        
        // For Elixir, we'll just return the value since IO.inspect handles formatting
        // The position info can be passed as a label option
        return str;
    }
    
    /**
     * Main trace function - outputs to IO.inspect in Elixir
     * 
     * This generates idiomatic Elixir code using IO.inspect instead of Log.trace
     */
    public static dynamic function trace(v: Dynamic, ?infos: PosInfos): Void {
        // Use IO.inspect for idiomatic Elixir output
        if (infos != null) {
            // Generate IO.inspect with label showing position info
            var label = '${infos.fileName}:${infos.lineNumber}';
            if (infos.className != null) {
                label = '${infos.className}.${infos.methodName} - ' + label;
            }
            untyped __elixir__('IO.inspect({0}, label: {1})', v, label);
        } else {
            untyped __elixir__('IO.inspect({0})', v);
        }
    }
}
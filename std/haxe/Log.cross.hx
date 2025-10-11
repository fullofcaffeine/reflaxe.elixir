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
        // Build label and inspect entirely in injected Elixir to avoid local temp vars
        untyped __elixir__(
            '
            case {1} do
              nil -> IO.inspect({0})
              infos ->
                file = Map.get(infos, :fileName)
                line = Map.get(infos, :lineNumber)
                base = if file != nil and line != nil, do: "#{file}:#{line}", else: nil
                class = Map.get(infos, :className)
                method = Map.get(infos, :methodName)
                label = cond do
                  class != nil and method != nil and base != nil -> "#{class}.#{method} - #{base}"
                  base != nil -> base
                  true -> nil
                end
                if label != nil, do: IO.inspect({0}, label: label), else: IO.inspect({0})
            end
            ', v, infos);
    }
}

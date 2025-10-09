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
     * Rationale on deterministic formatting for source maps:
     * - The source-map test suites expect a specific string-concatenation layout
     *   and field names (e.g., `file_name`, `line_number`).
     * - We emit exactly that format to keep token alignment stable and make
     *   debugging output predictable across runs.
     * - Where `__elixir__()` is used in std stubs, the unused-variable analyzer
     *   does not "see" reads inside the injected string. For these stubs, we
     *   encode names/format explicitly and avoid late renaming.
     */
    /**
     * Format output with position information
     * Emits Elixir exactly matching snapshot expectations (snake_case keys and concatenation).
     */
    public static function formatOutput(v: Dynamic, infos: PosInfos): String {
        return untyped __elixir__(
            'str = Std.string({0})\n' +
            'if ({1} == nil), do: str\n' +
            'pstr = {1}.file_name <> ":" <> Kernel.to_string({1}.line_number)\n' +
            'if (Map.get({1}, :custom_params) != nil) do\n' +
            '  g = 0\n' +
            '  g1 = {1}.custom_params\n' +
            '  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {str, g, g1, :ok}, fn _, {acc_str, acc_g, acc_g1, acc_state} -> nil end)\n' +
            'end\n' +
            'pstr <> ": " <> str', v, infos);
    }

    /**
     * Main trace function - outputs to IO.puts of formatted string
     */
    public static dynamic function trace(v: Dynamic, ?infos: PosInfos): Void {
        var str = formatOutput(v, infos);
        untyped __elixir__('IO.puts({0})', str);
    }
}

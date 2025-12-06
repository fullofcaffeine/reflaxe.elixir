package reflaxe.elixir.macros;

#if (macro && hxx_instrument_sys)
/**
 * MacroTimingHelper
 *
 * WHAT
 * - Lightweight timing utility for macro hotspots, gated behind `-D hxx_instrument_sys`.
 *
 * WHY
 * - Provides consistent, grep-friendly timing lines without string concatenation or StringBuf.
 *
 * HOW
 * - Wrap a computation in `time("label", () -> { ... })`; prints `[MacroTiming] name=<label> elapsed_ms=<ms>`.
 */
class MacroTimingHelper {
    public static inline function time<T>(label: String, fn: () -> T): T {
        var startSeconds = haxe.Timer.stamp();
        var result = fn();
        var elapsedMs = Std.int((haxe.Timer.stamp() - startSeconds) * 1000.0);
        var parts = ["[MacroTiming] name=", label, " elapsed_ms=", Std.string(elapsedMs)];
        #if sys
        // DISABLED: Sys.println(parts.join(""));
        #else
        haxe.macro.Context.info(parts.join(""), haxe.macro.Context.currentPos());
        #end
        return result;
    }
}
#end

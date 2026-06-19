package reflaxe.elixir.macros;

#if (macro && hxx_instrument_sys)
/**
 * MacroTimingHelper
 *
 * WHAT
 * - Lightweight timing utility for macro hotspots, gated behind `-D hxx_instrument_sys`.
 *
 * WHY
 * - Uses Haxe's macro-native timer API instead of `haxe.Timer`.
 * - That avoids pulling target `sys.*` classes into cross-target compilations.
 *
 * HOW
 * - Wrap a computation in `time("label", () -> { ... })`.
 * - Compile with `-D hxx_instrument_sys --times` to include the label in Haxe's timing report.
 */
class MacroTimingHelper {
	public static inline function time<T>(label:String, fn:() -> T):T {
		var stopTimer = haxe.macro.Context.timer(label);
		try {
			var result = fn();
			stopTimer();
			return result;
		} catch (error:Dynamic) {
			// Stop the timer before rethrowing so failed macro expansions still leave
			// Haxe's timing report in a consistent state.
			stopTimer();
			throw error;
		}
	}
}
#end

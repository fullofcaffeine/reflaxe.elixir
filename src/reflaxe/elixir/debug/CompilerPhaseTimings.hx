package reflaxe.elixir.debug;

#if (macro || reflaxe_runtime)
import haxe.Json;

using StringTools;

typedef CompilerPhaseTiming = {
	final name:String;
	final durationMs:Float;
	final count:Int;
}

/**
 * Optional coarse timing for one Reflaxe.Elixir compilation request.
 *
 * WHAT
 * - Accumulates a few large target-side phases such as AST construction,
 *   transformations, printing, source maps, and output publication.
 *
 * WHY
 * - End-to-end build time alone cannot tell whether Haxe typing, target
 *   generation, file output, or Mix owns a slowdown. These spans provide that
 *   attribution without enabling expensive per-node or per-pass fingerprints.
 *
 * HOW
 * - Set `REFLAXE_ELIXIR_TIMINGS=1` for a diagnostic compile.
 * - Callers record durations on this compiler-owned instance.
 * - One machine-readable JSON line is printed after publication succeeds.
 *
 * Normal compilation pays only an enabled check and never writes a timing file.
 */
class CompilerPhaseTimings {
	public static inline var OUTPUT_PREFIX = "REFLAXE_ELIXIR_TIMINGS ";

	public var enabled(default, null):Bool;

	var totals:Map<String, Float> = new Map();
	var counts:Map<String, Int> = new Map();
	var requestStartedMs:Float = 0.0;
	var reported:Bool = false;

	public function new(?enabledOverride:Null<Bool>) {
		enabled = enabledOverride != null ? enabledOverride : environmentEnabled();
		reset();
	}

	/** Starts a fresh request; server requests must never share accumulated spans. */
	public function reset():Void {
		totals = new Map();
		counts = new Map();
		reported = false;
		requestStartedMs = enabled ? nowMs() : 0.0;
	}

	/** Returns a monotonic start value, or zero when instrumentation is disabled. */
	public inline function start():Float {
		return enabled ? nowMs() : 0.0;
	}

	/** Adds the elapsed time since `startedMs` to one coarse phase. */
	public function finish(name:String, startedMs:Float):Void {
		if (enabled)
			record(name, nowMs() - startedMs);
	}

	/** Records an already measured duration. Public for focused contract tests. */
	public function record(name:String, durationMs:Float):Void {
		if (!enabled)
			return;
		if (name == null || name.length == 0)
			throw "Compiler timing phase names must not be empty.";
		if (durationMs < 0)
			throw 'Compiler timing phase `$name` reported a negative duration.';

		var previous = totals.get(name);
		totals.set(name, (previous == null ? 0.0 : previous) + durationMs);
		var count = counts.get(name);
		counts.set(name, (count == null ? 0 : count) + 1);
	}

	/** Stable snapshot used by the report and focused tests. */
	public function snapshot():Array<CompilerPhaseTiming> {
		var names = [for (name in totals.keys()) name];
		names.sort(Reflect.compare);
		return names.map(name -> {
			name: name,
			durationMs: totals.get(name),
			count: counts.get(name)
		});
	}

	/** Prints one idempotent machine-readable request summary. */
	public function report():Void {
		if (!enabled || reported)
			return;
		reported = true;
		Sys.println(OUTPUT_PREFIX + Json.stringify({
			schema_version: 1,
			total_wall_ms: nowMs() - requestStartedMs,
			phases: snapshot()
		}));
	}

	static inline function nowMs():Float {
		return haxe.Timer.stamp() * 1000.0;
	}

	static function environmentEnabled():Bool {
		#if sys
		var value = Sys.getEnv("REFLAXE_ELIXIR_TIMINGS");
		if (value == null)
			return false;
		return switch (value.toLowerCase().trim()) {
			case "1" | "true" | "yes" | "y": true;
			default: false;
		};
		#else
		return false;
		#end
	}
}
#end

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
 * - One machine-readable JSON line is printed after publication succeeds and
 *   the warm-cache results are committed (`ElixirCompiler.onOutputComplete`).
 * - Phases that run before the compiler's request starts (initialization
 *   macros, after-typing callbacks) are kept with `startEarly`/`finishEarly`
 *   and added to the next report by `addEarlyPhases`.
 *
 * Normal compilation pays only an enabled check and never writes a timing file.
 */
class CompilerPhaseTimings {
	public static inline var OUTPUT_PREFIX = "REFLAXE_ELIXIR_TIMINGS ";

	public var enabled(default, null):Bool;

	/**
	 * Phases that ran before the compiler object exists or before its request
	 * starts in `ElixirCompiler.filterTypes`: the initialization macros, and the
	 * callbacks that Haxe calls after typing. Not `@:persistent`, so Haxe clears
	 * the list at the start of each compilation-server request.
	 */
	static var earlyPhases:Array<CompilerPhaseTiming> = [];

	/** Start of `CompilerInit.Start` in this request, or zero. Not `@:persistent`. */
	static var requestBeganMs:Float = 0.0;

	static var environmentChecked = false;
	static var environmentOn = false;

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

	/** Returns a compiler-process timestamp, or zero when instrumentation is disabled. */
	public inline function start():Float {
		return enabled ? nowMs() : 0.0;
	}

	/** Adds the elapsed time since `startedMs` to one coarse phase. */
	public function finish(name:String, startedMs:Float):Void {
		if (enabled)
			record(name, nowMs() - startedMs);
	}

	/**
	 * Records an already measured duration. `count` says how many runs of the
	 * phase the duration covers, for example the number of classes scanned.
	 * Public for focused contract tests.
	 */
	public function record(name:String, durationMs:Float, count:Int = 1):Void {
		if (!enabled)
			return;
		if (name == null || name.length == 0)
			throw "Compiler timing phase names must not be empty.";
		if (durationMs < 0)
			throw 'Compiler timing phase `$name` reported a negative duration.';

		var previous = totals.get(name);
		totals.set(name, (previous == null ? 0.0 : previous) + durationMs);
		if (count < 1)
			throw 'Compiler timing phase `$name` reported a count below one.';
		var previousCount = counts.get(name);
		counts.set(name, (previousCount == null ? 0 : previousCount) + count);
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

	/**
	 * Returns a timestamp for an early phase when `REFLAXE_ELIXIR_TIMINGS` is on,
	 * or zero. Use it where no compiler object exists yet, for example in an
	 * initialization macro.
	 */
	public static function startEarly():Float {
		return earlyEnabled() ? nowMs() : 0.0;
	}

	/** Records an early phase that started at `startedMs`; see `startEarly`. */
	public static function finishEarly(name:String, startedMs:Float, count:Int = 1):Void {
		if (!earlyEnabled())
			return;
		earlyPhases.push({name: name, durationMs: nowMs() - startedMs, count: count < 1 ? 1 : count});
	}

	/** Marks the start of `CompilerInit.Start`, the first macro of a request. */
	public static function markRequestBegan():Void {
		if (earlyEnabled() && requestBeganMs == 0.0)
			requestBeganMs = nowMs();
	}

	/**
	 * Adds the early phases of this request to this compiler's report, and the
	 * time from `markRequestBegan` until now as `request_start_to_filter_types`.
	 * That span holds the initialization macros, Haxe's typing, the after-typing
	 * callbacks, and dead-code elimination. Call it after `reset`.
	 */
	public function addEarlyPhases():Void {
		if (!enabled)
			return;
		for (phase in earlyPhases)
			record(phase.name, phase.durationMs, phase.count);
		earlyPhases = [];
		if (requestBeganMs > 0.0)
			record("request_start_to_filter_types", nowMs() - requestBeganMs);
	}

	/**
	 * Registers `callback` with `Context.onAfterTyping` and records its time as
	 * the early phase `after_typing:<name>`. Haxe calls after-typing callbacks
	 * before the compiler's request starts, so their cost is otherwise not in
	 * the report. With timings off, this only registers the callback.
	 */
	public static function onAfterTyping(name:String, callback:Array<haxe.macro.Type.ModuleType>->Void):Void {
		#if macro
		if (!earlyEnabled()) {
			haxe.macro.Context.onAfterTyping(callback);
			return;
		}
		haxe.macro.Context.onAfterTyping(types -> {
			final started = nowMs();
			callback(types);
			finishEarly("after_typing:" + name, started);
		});
		#end
	}

	static function earlyEnabled():Bool {
		if (!environmentChecked) {
			environmentOn = environmentEnabled();
			environmentChecked = true;
		}
		return environmentOn;
	}

	static inline function nowMs():Float {
		// This class is initialized while Haxe is still bootstrapping the target.
		// `haxe.Timer` can pull target event-loop overrides into that macro phase before
		// Reflaxe has registered `__elixir__`; `Sys.time()` is the direct compiler-side
		// clock already used by the pass runner and has no target runtime dependency.
		return Sys.time() * 1000.0;
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

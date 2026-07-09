package haxe;

import elixir.types.Term;
import haxe.PosInfos;
import sys.thread.EventLoop.EventHandler;
import sys.thread.Thread;

/**
 * BEAM-backed `haxe.Timer`.
 *
 * WHAT
 * - Provides Haxe Timer semantics on the Elixir target using the existing
 *   `sys.thread.EventLoop` runtime.
 *
 * WHY
 * - Upstream `haxe.Timer` mutates the dynamic `run` field after construction.
 *   Elixir structs are immutable, so the callback must live outside the struct
 *   and be reached through compiler-lowered `timer.run` reads/writes/calls.
 *
 * HOW
 * - Each Timer owns an ETS-backed callback cell.
 * - `new` schedules a repeated event on the current thread event loop.
 * - Compiler special cases lower `timer.run = f`, `timer.run`, and
 *   `timer.run()` to the `__set_run`, `__get_run`, and `__invoke_run` helpers.
 */
@:native("Haxe.Timer")
class Timer {
	var thread:Null<Thread>;
	var eventHandler:Null<EventHandler>;
	var callbackRef:Null<Term>;

	public function new(time_ms:Int, ?deferStart:Bool) {
		#if (macro || (!reflaxe_runtime && !elixir))
		thread = null;
		eventHandler = null;
		callbackRef = null;
		#else
		callbackRef = TimerRuntime.create();
		if (deferStart != true) {
			thread = Thread.current();
			var ref = callbackRef;
			eventHandler = thread.events.repeat(function() {
				TimerRuntime.invoke(ref, function() {});
			}, time_ms);
		}
		#end
	}

	public function stop():Void {
		#if !(macro || (!reflaxe_runtime && !elixir))
		if (thread != null && eventHandler != null)
			thread.events.cancel(eventHandler);
		if (callbackRef != null)
			TimerRuntime.delete(callbackRef);
		#end
		eventHandler = null;
		callbackRef = null;
	}

	public dynamic function run():Void {}

	public static function delay(f:Void->Void, time_ms:Int):Timer {
		#if (macro || (!reflaxe_runtime && !elixir))
		var timer = new Timer(time_ms);
		timer.run = function() {
			timer.stop();
			f();
		};
		return timer;
		#else
		var timer = new Timer(time_ms, true);
		var ref = timer.callbackRef;
		TimerRuntime.storeCallback(ref, function() {
			TimerRuntime.delete(ref);
			f();
		});
		timer.thread = Thread.current();
		var events = timer.thread.events;
		timer.eventHandler = untyped __elixir__('apply(EventLoopRuntime, :run_delayed, [{0}.ref, fn -> Haxe.TimerRuntime.invoke({1}, fn -> nil end) end, {2}])',
			events, ref, time_ms);
		return timer;
		#end
	}

	public static function measure<T>(f:Void->T, ?pos:PosInfos):T {
		var start = stamp();
		var result = f();
		Log.trace((stamp() - start) + "s", pos);
		return result;
	}

	public static function stamp():Float {
		#if (macro || (!reflaxe_runtime && !elixir))
		return Sys.time();
		#else
		return untyped __elixir__('System.monotonic_time(:nanosecond) / 1_000_000_000.0');
		#end
	}

	@:keep
	@:noCompletion
	public static function __set_run(timer:Timer, f:Void->Void):Void->Void {
		#if !(macro || (!reflaxe_runtime && !elixir))
		TimerRuntime.storeCallback(timer.callbackRef, f);
		#end
		return f;
	}

	@:keep
	@:noCompletion
	public static function __get_run(timer:Timer):Void->Void {
		#if (macro || (!reflaxe_runtime && !elixir))
		return function() {
			timer.run();
		};
		#else
		return TimerRuntime.get(timer.callbackRef, function() {
			TimerRuntime.invoke_default(timer);
		});
		#end
	}

	@:keep
	@:noCompletion
	public static function __invoke_run(timer:Timer):Void {
		#if (macro || (!reflaxe_runtime && !elixir))
		timer.run();
		#else
		TimerRuntime.invoke(timer.callbackRef, function() {
			TimerRuntime.invoke_default(timer);
		});
		#end
	}
}

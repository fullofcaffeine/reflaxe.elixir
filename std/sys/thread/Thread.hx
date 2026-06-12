package sys.thread;

import elixir.types.Term;

/**
 * BEAM-backed `sys.thread.Thread`.
 *
 * WHAT
 * - Maps Haxe thread handles to Erlang process identifiers.
 * - Maps `sendMessage`/`readMessage` to BEAM mailbox messages.
 *
 * WHY
 * - Elixir has lightweight isolated processes, not shared-memory OS threads.
 * - The Haxe API requires dynamically typed message payloads; keep that
 *   compatibility exception local to this module.
 *
 * HOW
 * - `create` spawns a BEAM process that invokes the Haxe closure.
 * - `current` wraps `self()`.
 * - messages are tagged with `:reflaxe_sys_thread_message` so they do not
 *   consume unrelated BEAM messages.
 */
@:native("Sys.Thread.Thread")
class Thread {
	final pid:Term;

	public var events(get, never):EventLoop;

	function new(pid:Term):Void {
		this.pid = pid;
	}

	function get_events():EventLoop {
		return ThreadRuntime.currentEventLoop();
	}

	public function sendMessage(msg:Dynamic):Void {
		ThreadRuntime.sendMessage(pid, msg);
	}

	public static function current():Thread {
		return new Thread(ThreadRuntime.selfPid());
	}

	public static function create(job:() -> Void):Thread {
		return new Thread(ThreadRuntime.spawnProcess(job));
	}

	public static function runWithEventLoop(job:() -> Void):Void {
		var loop = ThreadRuntime.ensureEventLoop();
		job();
		loop.loop();
	}

	public static function createWithEventLoop(job:() -> Void):Thread {
		return create(function() {
			runWithEventLoop(job);
		});
	}

	public static function readMessage(block:Bool):Dynamic {
		return ThreadRuntime.readMessage(block);
	}

	static function processEvents():Void {
		ThreadRuntime.currentEventLoop().progress();
	}
}

private class ThreadRuntime {
	static final EVENT_LOOP_KEY:Term = untyped __elixir__('{:reflaxe_sys_thread_event_loop}');

	public static function selfPid():Term {
		return untyped __elixir__('self()');
	}

	public static function spawnProcess(job:() -> Void):Term {
		return untyped __elixir__('spawn(fn -> {0}.() end)', job);
	}

	public static function sendMessage(pid:Term, msg:Dynamic):Void {
		untyped __elixir__('send({0}, {:reflaxe_sys_thread_message, {1}})', pid, msg);
	}

	public static function readMessage(block:Bool):Dynamic {
		if (block) {
			return untyped __elixir__('(
                receive do
                  {:reflaxe_sys_thread_message, msg} -> msg
                end
            )');
		}

		return untyped __elixir__('(
            receive do
              {:reflaxe_sys_thread_message, msg} -> msg
            after
              0 -> nil
            end
        )');
	}

	public static function ensureEventLoop():EventLoop {
		var existing:EventLoop = untyped __elixir__('Process.get({0})', EVENT_LOOP_KEY);
		if (existing != null)
			return existing;

		var created = new EventLoop();
		untyped __elixir__('Process.put({0}, {1})', EVENT_LOOP_KEY, created);
		return created;
	}

	public static function currentEventLoop():EventLoop {
		return ensureEventLoop();
	}
}

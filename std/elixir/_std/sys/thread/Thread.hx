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
		var loop = ThreadRuntime.existingEventLoop();
		if (loop != null)
			return loop;
		if (ThreadRuntime.isPlainThread())
			throw new NoEventLoopException();
		return ThreadRuntime.installEventLoop();
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
		var existing = ThreadRuntime.existingEventLoop();
		if (existing != null) {
			job();
			return;
		}

		var loop = ThreadRuntime.installEventLoop();
		try {
			job();
			loop.loop();
		} catch (error) {
			ThreadRuntime.clearEventLoop();
			throw error;
		}
		ThreadRuntime.clearEventLoop();
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
		Thread.current().events.progress();
	}
}

private class ThreadRuntime {
	static final EVENT_LOOP_KEY:Term = untyped __elixir__('{:reflaxe_sys_thread_event_loop}');
	// This marker distinguishes plain Haxe children from the main BEAM process.
	static final THREAD_ROLE_KEY:Term = untyped __elixir__('{:reflaxe_sys_thread_role}');

	public static function selfPid():Term {
		return untyped __elixir__('self()');
	}

	public static function spawnProcess(job:() -> Void):Term {
		return untyped __elixir__('(
            role_key = {1}
            spawn(fn ->
              Process.put(role_key, :plain)
              {0}.()
            end)
        )', job, THREAD_ROLE_KEY);
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

	public static function installEventLoop():EventLoop {
		var created = new EventLoop();
		untyped __elixir__('Process.put({0}, {1})', EVENT_LOOP_KEY, created);
		return created;
	}

	public static function existingEventLoop():Null<EventLoop> {
		return untyped __elixir__('Process.get({0})', EVENT_LOOP_KEY);
	}

	public static function clearEventLoop():Void {
		untyped __elixir__('Process.delete({0})', EVENT_LOOP_KEY);
	}

	public static function isPlainThread():Bool {
		return untyped __elixir__('Process.get({0}) == :plain', THREAD_ROLE_KEY);
	}
}

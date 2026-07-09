package sys.thread;

import elixir.types.Term;

/**
 * Fixed-size pool backed by BEAM worker processes.
 */
@:native("Sys.Thread.FixedThreadPool")
class FixedThreadPool implements IThreadPool {
	public var threadsCount(get, null):Int;
	public var isShutdown(get, never):Bool;

	final queue:Deque<() -> Void>;
	final stateRef:Term;

	public function new(threadsCount:Int):Void {
		if (threadsCount < 1)
			throw new ThreadPoolException("FixedThreadPool needs threadsCount to be at least 1.");

		this.threadsCount = threadsCount;
		queue = new Deque();
		stateRef = ThreadPoolRuntime.createState();
		var workerQueue = queue;
		var created = 0;
		while (created < threadsCount) {
			Thread.create(function() {
				workerLoop(workerQueue);
			});
			created += 1;
		}
	}

	function get_threadsCount():Int {
		return threadsCount;
	}

	function get_isShutdown():Bool {
		return ThreadPoolRuntime.isShutdown(stateRef);
	}

	public function run(task:() -> Void):Void {
		if (ThreadPoolRuntime.isShutdown(stateRef))
			throw new ThreadPoolException("Task is rejected. Thread pool is shut down.");
		if (task == null)
			throw new ThreadPoolException("Task to run must not be null.");
		queue.add(task);
	}

	public function shutdown():Void {
		if (ThreadPoolRuntime.isShutdown(stateRef))
			return;
		ThreadPoolRuntime.markShutdown(stateRef);
		for (_ in 0...threadsCount) {
			queue.add(shutdownTask);
		}
	}

	static function shutdownTask():Void {}

	static function workerLoop(workerQueue:Deque<() -> Void>):Void {
		while (true) {
			var task = workerQueue.pop(true);
			if (task == shutdownTask)
				break;
			task();
		}
	}
}

private class ThreadPoolRuntime {
	public static function createState():Term {
		return untyped __elixir__('(
            ref = make_ref()
            Process.put({:reflaxe_sys_thread_pool, ref}, %{shutdown: false})
            ref
        )');
	}

	public static function isShutdown(ref:Term):Bool {
		return untyped __elixir__('(
            case Process.get({:reflaxe_sys_thread_pool, {0}}) do
              %{shutdown: shutdown} -> shutdown
              _ -> false
            end
        )', ref);
	}

	public static function markShutdown(ref:Term):Void {
		untyped __elixir__('Process.put({:reflaxe_sys_thread_pool, {0}}, %{shutdown: true})', ref);
	}
}

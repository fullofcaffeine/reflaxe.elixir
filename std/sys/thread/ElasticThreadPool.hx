package sys.thread;

import elixir.types.Term;

/**
 * Elastic pool for BEAM.
 *
 * Each submitted task runs in a BEAM process while a semaphore bounds
 * concurrency to `maxThreadsCount`.
 */
@:native("Sys.Thread.ElasticThreadPool")
class ElasticThreadPool implements IThreadPool {
	public var threadsCount(get, never):Int;
	public var maxThreadsCount:Int;
	public var isShutdown(get, never):Bool;

	final capacity:Semaphore;
	final stateRef:Term;

	public function new(maxThreadsCount:Int, threadTimeout:Float = 60):Void {
		if (maxThreadsCount < 1)
			throw new ThreadPoolException("ElasticThreadPool needs maxThreadsCount to be at least 1.");

		this.maxThreadsCount = maxThreadsCount;
		capacity = new Semaphore(maxThreadsCount);
		stateRef = ElasticThreadPoolRuntime.createState();
	}

	function get_threadsCount():Int {
		// BEAM worker processes are spawned per task and are not retained.
		return 0;
	}

	function get_isShutdown():Bool {
		return ElasticThreadPoolRuntime.isShutdown(stateRef);
	}

	public function run(task:() -> Void):Void {
		if (ElasticThreadPoolRuntime.isShutdown(stateRef))
			throw new ThreadPoolException("Task is rejected. Thread pool is shut down.");
		if (task == null)
			throw new ThreadPoolException("Task to run must not be null.");

		Thread.create(function() {
			capacity.acquire();
			try {
				task();
			} catch (e) {
				capacity.release();
				throw e;
			}
			capacity.release();
		});
	}

	public function shutdown():Void {
		ElasticThreadPoolRuntime.markShutdown(stateRef);
	}
}

private class ElasticThreadPoolRuntime {
	public static function createState():Term {
		return untyped __elixir__('(
            ref = make_ref()
            Process.put({:reflaxe_sys_elastic_thread_pool, ref}, %{shutdown: false})
            ref
        )');
	}

	public static function isShutdown(ref:Term):Bool {
		return untyped __elixir__('(
            case Process.get({:reflaxe_sys_elastic_thread_pool, {0}}) do
              %{shutdown: shutdown} -> shutdown
              _ -> false
            end
        )', ref);
	}

	public static function markShutdown(ref:Term):Void {
		untyped __elixir__('Process.put({:reflaxe_sys_elastic_thread_pool, {0}}, %{shutdown: true})', ref);
	}
}

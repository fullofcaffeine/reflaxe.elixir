package sys.thread;

/**
 * Condition variable surface for the Elixir target.
 *
 * BEAM processes do not share mutable memory, so POSIX condition variables are
 * not a natural primitive. The mutex portion is supported for API compatibility;
 * wait/signal/broadcast fail explicitly until this can be modeled with a
 * faithful mailbox protocol.
 */
@:native("Sys.Thread.Condition")
class Condition {
	final mutex:Mutex;

	public function new():Void {
		mutex = new Mutex();
	}

	public function acquire():Void {
		mutex.acquire();
	}

	public function tryAcquire():Bool {
		return mutex.tryAcquire();
	}

	public function release():Void {
		mutex.release();
	}

	public function wait():Void {
		throw "sys.thread.Condition.wait is not supported on the Elixir target; use Thread messages, Deque, Lock, or Semaphore instead";
	}

	public function signal():Void {
		throw "sys.thread.Condition.signal is not supported on the Elixir target; use Thread messages, Deque, Lock, or Semaphore instead";
	}

	public function broadcast():Void {
		throw "sys.thread.Condition.broadcast is not supported on the Elixir target; use Thread messages, Deque, Lock, or Semaphore instead";
	}
}

package sys.thread;

import elixir.types.Term;

/**
 * Counting semaphore backed by the same BEAM server model as `Lock`.
 */
@:native("Sys.Thread.Semaphore")
class Semaphore {
	final ref:Term;

	public function new(value:Int):Void {
		ref = SemaphoreRuntime.create(value);
	}

	public function acquire():Void {
		SemaphoreRuntime.acquire(ref);
	}

	public function tryAcquire(?timeout:Float):Bool {
		return SemaphoreRuntime.tryAcquire(ref, timeout);
	}

	public function release():Void {
		SemaphoreRuntime.release(ref);
	}
}

private class SemaphoreRuntime {
	public static function create(value:Int):Term {
		if (value < 0)
			throw "sys.thread.Semaphore initial value must be >= 0";

		return untyped __elixir__('(
            ref = make_ref()
            pid = spawn(fn -> SemaphoreRuntime.server_loop(ref, {0}, :queue.new()) end)
            {ref, pid}
        )', value);
	}

	public static function acquire(ref:Term):Void {
		acquireWithTimeout(ref, untyped __elixir__(':infinity'));
	}

	public static function tryAcquire(ref:Term, ?timeout:Float):Bool {
		var shouldQueue = timeout != null && timeout > 0;
		var timeoutMs:Term = shouldQueue ? secondsToTimeout(timeout) : 5000;
		return acquireWithTimeout(ref, timeoutMs, shouldQueue);
	}

	static function acquireWithTimeout(ref:Term, timeoutMs:Term, shouldQueue:Bool = true):Bool {
		return untyped __elixir__('(
            {semaphore_ref, pid} = {0}
            token = make_ref()
            send(pid, {:acquire, self(), token, {2}})
            receive do
              {:semaphore_acquire, ^semaphore_ref, ^token, ok} -> ok
            after
              {1} ->
                send(pid, {:cancel, token})
                false
            end
        )', ref, timeoutMs, shouldQueue);
	}

	public static function release(ref:Term):Void {
		untyped __elixir__('(
            {_semaphore_ref, pid} = {0}
            send(pid, :release)
            :ok
        )', ref);
	}

	static function secondsToTimeout(timeout:Null<Float>):Term {
		if (timeout == null)
			return 0;
		if (timeout <= 0)
			return 0;
		return Math.ceil(timeout * 1000);
	}

	public static function server_loop(ref:Term, available:Int, waiters:Term):Void {
		untyped __elixir__('
            receive do
              {:acquire, caller, token, should_queue} ->
                cond do
                  {1} > 0 ->
                    send(caller, {:semaphore_acquire, {0}, token, true})
                    SemaphoreRuntime.server_loop({0}, {1} - 1, {2})
                  should_queue ->
                    SemaphoreRuntime.server_loop({0}, {1}, :queue.in({caller, token}, {2}))
                  true ->
                    send(caller, {:semaphore_acquire, {0}, token, false})
                    SemaphoreRuntime.server_loop({0}, {1}, {2})
                end

              {:cancel, token} ->
                filtered =
                  {2}
                  |> :queue.to_list()
                  |> Enum.reject(fn {_caller, waiter_token} -> waiter_token == token end)
                  |> Enum.reduce(:queue.new(), fn waiter, queue -> :queue.in(waiter, queue) end)
                SemaphoreRuntime.server_loop({0}, {1}, filtered)

              :release ->
                case :queue.out({2}) do
                  {{:value, {caller, token}}, rest} ->
                    send(caller, {:semaphore_acquire, {0}, token, true})
                    SemaphoreRuntime.server_loop({0}, {1}, rest)
                  {:empty, _} ->
                    SemaphoreRuntime.server_loop({0}, {1} + 1, {2})
                end
            end
        ', ref, available, waiters);
	}
}

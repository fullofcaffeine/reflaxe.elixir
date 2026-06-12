package sys.thread;

import elixir.types.Term;

/**
 * Counting lock backed by a BEAM server process.
 *
 * Each `release` allows exactly one `wait` to continue. A release that happens
 * before a wait is counted, matching Haxe's `sys.thread.Lock` contract.
 */
@:native("Sys.Thread.Lock")
class Lock {
	final ref:Term;

	public function new():Void {
		ref = LockRuntime.create();
	}

	public function wait(?timeout:Float):Bool {
		return LockRuntime.wait(ref, timeout);
	}

	public function release():Void {
		LockRuntime.release(ref);
	}
}

private class LockRuntime {
	public static function create():Term {
		return untyped __elixir__('(
            ref = make_ref()
            pid = spawn(fn -> LockRuntime.server_loop(ref, 0, :queue.new()) end)
            {ref, pid}
        )');
	}

	public static function wait(ref:Term, ?timeout:Float):Bool {
		var shouldQueue = timeout == null || timeout > 0;
		var timeoutMs:Term = shouldQueue ? secondsToTimeout(timeout) : 5000;
		return untyped __elixir__('(
            {lock_ref, pid} = {0}
            token = make_ref()
            send(pid, {:wait, self(), token, {2}})
            receive do
              {:lock_wait, ^lock_ref, ^token, ok} -> ok
            after
              {1} ->
                send(pid, {:cancel, token})
                false
            end
        )', ref, timeoutMs, shouldQueue);
	}

	public static function release(ref:Term):Void {
		untyped __elixir__('(
            {_lock_ref, pid} = {0}
            send(pid, :release)
            :ok
        )', ref);
	}

	static function secondsToTimeout(timeout:Null<Float>):Term {
		if (timeout == null)
			return untyped __elixir__(':infinity');
		if (timeout <= 0)
			return 0;
		return Math.ceil(timeout * 1000);
	}

	public static function server_loop(ref:Term, permits:Int, waiters:Term):Void {
		untyped __elixir__('
            receive do
              {:wait, caller, token, should_queue} ->
                cond do
                  {1} > 0 ->
                    send(caller, {:lock_wait, {0}, token, true})
                    LockRuntime.server_loop({0}, {1} - 1, {2})
                  should_queue ->
                    LockRuntime.server_loop({0}, {1}, :queue.in({caller, token}, {2}))
                  true ->
                    send(caller, {:lock_wait, {0}, token, false})
                    LockRuntime.server_loop({0}, {1}, {2})
                end

              {:cancel, token} ->
                filtered =
                  {2}
                  |> :queue.to_list()
                  |> Enum.reject(fn {_caller, waiter_token} -> waiter_token == token end)
                  |> Enum.reduce(:queue.new(), fn waiter, queue -> :queue.in(waiter, queue) end)
                LockRuntime.server_loop({0}, {1}, filtered)

              :release ->
                case :queue.out({2}) do
                  {{:value, {caller, token}}, rest} ->
                    send(caller, {:lock_wait, {0}, token, true})
                    LockRuntime.server_loop({0}, {1}, rest)
                  {:empty, _} ->
                    LockRuntime.server_loop({0}, {1} + 1, {2})
                end
            end
        ', ref, permits, waiters);
	}
}

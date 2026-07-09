package sys.thread;

import elixir.types.Term;

/**
 * Re-entrant mutex backed by a BEAM server process.
 */
@:native("Sys.Thread.Mutex")
class Mutex {
	final ref:Term;

	public function new():Void {
		ref = MutexRuntime.create();
	}

	public function acquire():Void {
		MutexRuntime.acquire(ref);
	}

	public function tryAcquire():Bool {
		return MutexRuntime.tryAcquire(ref);
	}

	public function release():Void {
		MutexRuntime.release(ref);
	}
}

private class MutexRuntime {
	public static function create():Term {
		return untyped __elixir__('(
            ref = make_ref()
            pid = spawn(fn -> MutexRuntime.server_loop(ref, nil, 0, :queue.new()) end)
            {ref, pid}
        )');
	}

	public static function acquire(ref:Term):Void {
		untyped __elixir__('(
            {mutex_ref, pid} = {0}
            token = make_ref()
            send(pid, {:acquire, self(), token})
            receive do
              {:mutex_acquire, ^mutex_ref, ^token, :ok} -> :ok
              {:mutex_acquire, ^mutex_ref, ^token, {:error, message}} -> raise message
            end
        )', ref);
	}

	public static function tryAcquire(ref:Term):Bool {
		return untyped __elixir__('(
            {mutex_ref, pid} = {0}
            token = make_ref()
            send(pid, {:try_acquire, self(), token})
            receive do
              {:mutex_try_acquire, ^mutex_ref, ^token, ok} -> ok
            end
        )', ref);
	}

	public static function release(ref:Term):Void {
		untyped __elixir__('(
            {mutex_ref, pid} = {0}
            token = make_ref()
            send(pid, {:release, self(), token})
            receive do
              {:mutex_release, ^mutex_ref, ^token, :ok} -> :ok
              {:mutex_release, ^mutex_ref, ^token, {:error, message}} -> raise message
            end
        )', ref);
	}

	public static function server_loop(ref:Term, owner:Term, count:Int, waiters:Term):Void {
		untyped __elixir__('
            receive do
              {:acquire, caller, token} ->
                cond do
                  is_nil({1}) or {1} == caller ->
                    send(caller, {:mutex_acquire, {0}, token, :ok})
                    MutexRuntime.server_loop({0}, caller, {2} + 1, {3})
                  true ->
                    MutexRuntime.server_loop({0}, {1}, {2}, :queue.in({caller, token}, {3}))
                end

              {:try_acquire, caller, token} ->
                cond do
                  is_nil({1}) or {1} == caller ->
                    send(caller, {:mutex_try_acquire, {0}, token, true})
                    MutexRuntime.server_loop({0}, caller, {2} + 1, {3})
                  true ->
                    send(caller, {:mutex_try_acquire, {0}, token, false})
                    MutexRuntime.server_loop({0}, {1}, {2}, {3})
                end

              {:release, caller, token} ->
                cond do
                  {1} != caller ->
                    send(caller, {:mutex_release, {0}, token, {:error, "sys.thread.Mutex.release called by a process that does not own the mutex"}})
                    MutexRuntime.server_loop({0}, {1}, {2}, {3})
                  {2} > 1 ->
                    send(caller, {:mutex_release, {0}, token, :ok})
                    MutexRuntime.server_loop({0}, {1}, {2} - 1, {3})
                  true ->
                    send(caller, {:mutex_release, {0}, token, :ok})
                    case :queue.out({3}) do
                      {{:value, {next_caller, next_token}}, rest} ->
                        send(next_caller, {:mutex_acquire, {0}, next_token, :ok})
                        MutexRuntime.server_loop({0}, next_caller, 1, rest)
                      {:empty, _} ->
                        MutexRuntime.server_loop({0}, nil, 0, {3})
                    end
                end
            end
        ', ref, owner, count, waiters);
	}
}

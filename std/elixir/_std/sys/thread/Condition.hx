package sys.thread;

import elixir.types.Term;

/**
 * A condition variable backed by one BEAM server process.
 *
 * The server owns both the re-entrant mutex and the waiter queues. This makes
 * `wait` one atomic state change: it queues the caller, releases every mutex
 * hold, and grants the mutex to the next caller. A signaled caller returns only
 * after it acquires the mutex again with its previous hold count.
 */
@:native("Sys.Thread.Condition")
class Condition {
	final ref:Term;

	public function new():Void {
		ref = ConditionRuntime.create();
	}

	public function acquire():Void {
		ConditionRuntime.acquire(ref);
	}

	public function tryAcquire():Bool {
		return ConditionRuntime.tryAcquire(ref);
	}

	public function release():Void {
		ConditionRuntime.release(ref);
	}

	public function wait():Void {
		ConditionRuntime.wait(ref);
	}

	public function signal():Void {
		ConditionRuntime.signal(ref);
	}

	public function broadcast():Void {
		ConditionRuntime.broadcast(ref);
	}
}

private class ConditionRuntime {
	public static function create():Term {
		return untyped __elixir__('(
            ref = make_ref()
            pid = spawn(fn -> ConditionRuntime.server_loop(ref, nil, 0, :queue.new(), :queue.new()) end)
            {ref, pid}
        )');
	}

	public static function acquire(ref:Term):Void {
		untyped __elixir__('(
            {condition_ref, pid} = {0}
            token = make_ref()
            send(pid, {:acquire, self(), token})
            receive do
              {:condition_acquire, ^condition_ref, ^token, :ok} -> :ok
              {:condition_acquire, ^condition_ref, ^token, {:error, message}} -> raise message
            end
        )', ref);
	}

	public static function tryAcquire(ref:Term):Bool {
		return untyped __elixir__('(
            {condition_ref, pid} = {0}
            token = make_ref()
            send(pid, {:try_acquire, self(), token})
            receive do
              {:condition_try_acquire, ^condition_ref, ^token, acquired} -> acquired
            end
        )', ref);
	}

	public static function release(ref:Term):Void {
		untyped __elixir__('(
            {condition_ref, pid} = {0}
            token = make_ref()
            send(pid, {:release, self(), token})
            receive do
              {:condition_release, ^condition_ref, ^token, :ok} -> :ok
              {:condition_release, ^condition_ref, ^token, {:error, message}} -> raise message
            end
        )', ref);
	}

	public static function wait(ref:Term):Void {
		untyped __elixir__('(
            {condition_ref, pid} = {0}
            token = make_ref()
            send(pid, {:wait, self(), token})
            receive do
              {:condition_wait, ^condition_ref, ^token, :ok} -> :ok
              {:condition_wait, ^condition_ref, ^token, {:error, message}} -> raise message
            end
        )', ref);
	}

	public static function signal(ref:Term):Void {
		untyped __elixir__('(
            {condition_ref, pid} = {0}
            token = make_ref()
            send(pid, {:signal, self(), token})
            receive do
              {:condition_signal, ^condition_ref, ^token, :ok} -> :ok
            end
        )', ref);
	}

	public static function broadcast(ref:Term):Void {
		untyped __elixir__('(
            {condition_ref, pid} = {0}
            token = make_ref()
            send(pid, {:broadcast, self(), token})
            receive do
              {:condition_broadcast, ^condition_ref, ^token, :ok} -> :ok
            end
        )', ref);
	}

	@:keep
	public static function serverLoop(ref:Term, owner:Term, count:Int, mutexWaiters:Term, conditionWaiters:Term):Void {
		untyped __elixir__('
            receive do
              {:acquire, caller, token} ->
                cond do
                  is_nil({1}) or {1} == caller ->
                    send(caller, {:condition_acquire, {0}, token, :ok})
                    ConditionRuntime.server_loop({0}, caller, {2} + 1, {3}, {4})
                  true ->
                    waiter = {caller, token, 1, :acquire}
                    ConditionRuntime.server_loop({0}, {1}, {2}, :queue.in(waiter, {3}), {4})
                end

              {:try_acquire, caller, token} ->
                cond do
                  is_nil({1}) or {1} == caller ->
                    send(caller, {:condition_try_acquire, {0}, token, true})
                    ConditionRuntime.server_loop({0}, caller, {2} + 1, {3}, {4})
                  true ->
                    send(caller, {:condition_try_acquire, {0}, token, false})
                    ConditionRuntime.server_loop({0}, {1}, {2}, {3}, {4})
                end

              {:release, caller, token} ->
                cond do
                  {1} != caller ->
                    send(caller, {:condition_release, {0}, token, {:error, "sys.thread.Condition.release called by a process that does not own the mutex"}})
                    ConditionRuntime.server_loop({0}, {1}, {2}, {3}, {4})
                  {2} > 1 ->
                    send(caller, {:condition_release, {0}, token, :ok})
                    ConditionRuntime.server_loop({0}, {1}, {2} - 1, {3}, {4})
                  true ->
                    send(caller, {:condition_release, {0}, token, :ok})
                    ConditionRuntime.continue_or_grant({0}, nil, 0, {3}, {4})
                end

              {:wait, caller, token} ->
                if {1} != caller do
                  send(caller, {:condition_wait, {0}, token, {:error, "sys.thread.Condition.wait called by a process that does not own the mutex"}})
                  ConditionRuntime.server_loop({0}, {1}, {2}, {3}, {4})
                else
                  waiter = {caller, token, {2}, :wait}
                  ConditionRuntime.continue_or_grant({0}, nil, 0, {3}, :queue.in(waiter, {4}))
                end

              {:signal, caller, token} ->
                send(caller, {:condition_signal, {0}, token, :ok})
                case :queue.out({4}) do
                  {{:value, waiter}, remaining_condition_waiters} ->
                    ConditionRuntime.continue_or_grant(
                      {0},
                      {1},
                      {2},
                      :queue.in(waiter, {3}),
                      remaining_condition_waiters
                    )
                  {:empty, _} ->
                    ConditionRuntime.server_loop({0}, {1}, {2}, {3}, {4})
                end

              {:broadcast, caller, token} ->
                send(caller, {:condition_broadcast, {0}, token, :ok})
                ConditionRuntime.continue_or_grant(
                  {0},
                  {1},
                  {2},
                  :queue.join({3}, {4}),
                  :queue.new()
                )
            end
        ', ref, owner, count, mutexWaiters, conditionWaiters);
	}

	@:keep
	public static function continueOrGrant(ref:Term, owner:Term, count:Int, mutexWaiters:Term, conditionWaiters:Term):Void {
		untyped __elixir__('
            if is_nil({1}) do
              case :queue.out({3}) do
                {{:value, {next_caller, next_token, next_count, reply_kind}}, remaining_mutex_waiters} ->
                  case reply_kind do
                    :acquire -> send(next_caller, {:condition_acquire, {0}, next_token, :ok})
                    :wait -> send(next_caller, {:condition_wait, {0}, next_token, :ok})
                  end
                  ConditionRuntime.server_loop({0}, next_caller, next_count, remaining_mutex_waiters, {4})
                {:empty, _} ->
                  ConditionRuntime.server_loop({0}, nil, 0, {3}, {4})
              end
            else
              ConditionRuntime.server_loop({0}, {1}, {2}, {3}, {4})
            end
        ', ref, owner, count, mutexWaiters, conditionWaiters);
	}
}

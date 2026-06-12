package sys.thread;

import elixir.types.Term;

/**
 * Process-backed blocking deque.
 *
 * The queue lives in a BEAM process so it can be shared across spawned Haxe
 * threads instead of relying on process-local state.
 */
@:native("Sys.Thread.Deque")
class Deque<T> {
	final ref:Term;

	public function new():Void {
		ref = DequeRuntime.create();
	}

	public function add(i:T):Void {
		DequeRuntime.add(ref, i);
	}

	public function push(i:T):Void {
		DequeRuntime.push(ref, i);
	}

	public function pop(block:Bool):Null<T> {
		return DequeRuntime.pop(ref, block);
	}
}

private class DequeRuntime {
	public static function create():Term {
		return untyped __elixir__('(
            ref = make_ref()
            pid = spawn(fn -> DequeRuntime.server_loop(ref, :queue.new(), :queue.new()) end)
            {ref, pid}
        )');
	}

	public static function add<T>(ref:Term, value:T):Void {
		untyped __elixir__('(
            {_deque_ref, pid} = {0}
            send(pid, {:add, {1}})
            :ok
        )', ref, value);
	}

	public static function push<T>(ref:Term, value:T):Void {
		untyped __elixir__('(
            {_deque_ref, pid} = {0}
            send(pid, {:push, {1}})
            :ok
        )', ref, value);
	}

	public static function pop<T>(ref:Term, block:Bool):Null<T> {
		return untyped __elixir__('(
            {deque_ref, pid} = {0}
            token = make_ref()
            send(pid, {:pop, self(), token, {1}})
            receive do
              {:deque_pop, ^deque_ref, ^token, value} -> value
            end
        )', ref, block);
	}

	public static function server_loop(ref:Term, queue:Term, waiters:Term):Void {
		untyped __elixir__('
            receive do
              {:add, value} ->
                case :queue.out({2}) do
                  {{:value, {caller, token}}, remaining_waiters} ->
                    send(caller, {:deque_pop, {0}, token, value})
                    DequeRuntime.server_loop({0}, {1}, remaining_waiters)
                  {:empty, _} ->
                    DequeRuntime.server_loop({0}, :queue.in(value, {1}), {2})
                end

              {:push, value} ->
                case :queue.out({2}) do
                  {{:value, {caller, token}}, remaining_waiters} ->
                    send(caller, {:deque_pop, {0}, token, value})
                    DequeRuntime.server_loop({0}, {1}, remaining_waiters)
                  {:empty, _} ->
                    DequeRuntime.server_loop({0}, :queue.in_r(value, {1}), {2})
                end

              {:pop, caller, token, block} ->
                case :queue.out({1}) do
                  {{:value, value}, remaining_queue} ->
                    send(caller, {:deque_pop, {0}, token, value})
                    DequeRuntime.server_loop({0}, remaining_queue, {2})
                  {:empty, _} ->
                    if block do
                      DequeRuntime.server_loop({0}, {1}, :queue.in({caller, token}, {2}))
                    else
                      send(caller, {:deque_pop, {0}, token, nil})
                      DequeRuntime.server_loop({0}, {1}, {2})
                    end
                end
            end
        ', ref, queue, waiters);
	}
}

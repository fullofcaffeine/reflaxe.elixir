package sys.thread;

import elixir.types.Term;

enum NextEventTime {
	Now;
	Never;
	AnyTime(time:Null<Float>);
	At(time:Float);
}

/**
 * BEAM-backed event loop for `sys.thread.Thread`.
 *
 * Events are stored in a small server process, but callbacks are drained and
 * executed by the caller of `progress`/`loop`, preserving the Haxe event-loop
 * shape instead of running user callbacks inside the storage process.
 */
@:native("Sys.Thread.EventLoop")
class EventLoop {
	final ref:Term;

	public function new():Void {
		ref = EventLoopRuntime.create();
	}

	public function repeat(event:() -> Void, intervalMs:Int):EventHandler {
		return EventLoopRuntime.repeat(ref, event, intervalMs);
	}

	public function cancel(eventHandler:EventHandler):Void {
		EventLoopRuntime.cancel(eventHandler);
	}

	public function promise():Void {
		EventLoopRuntime.promise(ref);
	}

	public function run(event:() -> Void):Void {
		EventLoopRuntime.run(ref, event);
	}

	public function runPromised(event:() -> Void):Void {
		EventLoopRuntime.runPromised(ref, event);
	}

	public function progress():NextEventTime {
		var info = EventLoopRuntime.drain(ref);
		var ran = EventLoopRuntime.runDrainedEvents(info);
		if (ran)
			return Now;
		if (EventLoopRuntime.hasPromisedEvents(info))
			return AnyTime(null);
		return Never;
	}

	public function wait(?timeout:Float):Bool {
		return EventLoopRuntime.wait(ref, timeout);
	}

	public function loop():Void {
		while (true) {
			switch progress() {
				case Now:
				case AnyTime(_):
					wait();
				case At(time):
					wait(Math.max(0, time - Sys.time()));
				case Never:
					break;
			}
		}
	}
}

abstract EventHandler(Term) from Term to Term {}

private class EventLoopRuntime {
	public static function create():Term {
		return untyped __elixir__('(
            ref = make_ref()
            pid = spawn(fn -> EventLoopRuntime.server_loop(ref, :queue.new(), 0, :queue.new()) end)
            {ref, pid}
        )');
	}

	public static function run(ref:Term, event:() -> Void):Void {
		untyped __elixir__('(
            {_loop_ref, pid} = {0}
            send(pid, {:run, {1}})
            :ok
        )', ref, event);
	}

	public static function promise(ref:Term):Void {
		untyped __elixir__('(
            {_loop_ref, pid} = {0}
            send(pid, :promise)
            :ok
        )', ref);
	}

	public static function runPromised(ref:Term, event:() -> Void):Void {
		untyped __elixir__('(
            {_loop_ref, pid} = {0}
            send(pid, {:run_promised, {1}})
            :ok
        )', ref, event);
	}

	public static function repeat(ref:Term, event:() -> Void, intervalMs:Int):EventHandler {
		if (intervalMs < 0)
			throw "sys.thread.EventLoop.repeat interval must be >= 0";

		return untyped __elixir__('(
            loop_ref = {0}
            interval = max({2}, 0)
            timer_pid = spawn(fn ->
              repeat_fn = fn repeat_fn ->
                receive do
                  :cancel -> :ok
                after
                  interval ->
                    EventLoopRuntime.run(loop_ref, {1})
                    repeat_fn.(repeat_fn)
                end
              end
              repeat_fn.(repeat_fn)
            end)
            timer_pid
        )', ref, event, intervalMs);
	}

	public static function cancel(handler:EventHandler):Void {
		untyped __elixir__('send({0}, :cancel)', handler);
	}

	public static function drain(ref:Term):Term {
		return untyped __elixir__('(
            {loop_ref, pid} = {0}
            token = make_ref()
            send(pid, {:drain, self(), token})
            receive do
              {:event_loop_drain, ^loop_ref, ^token, events, promised} -> {events, promised}
            end
        )', ref);
	}

	public static function runDrainedEvents(info:Term):Bool {
		return untyped __elixir__('(
            {events, _promised} = {0}
            Enum.each(events, fn event -> event.() end)
            events != []
        )', info);
	}

	public static function hasPromisedEvents(info:Term):Bool {
		return untyped __elixir__('(
            {_events, promised} = {0}
            promised > 0
        )', info);
	}

	public static function wait(ref:Term, ?timeout:Float):Bool {
		var timeoutMs:Term = secondsToTimeout(timeout);
		return untyped __elixir__('(
            {loop_ref, pid} = {0}
            token = make_ref()
            send(pid, {:wait, self(), token})
            receive do
              {:event_loop_wait, ^loop_ref, ^token, ok} -> ok
            after
              {1} ->
                send(pid, {:cancel_wait, token})
                false
            end
        )', ref, timeoutMs);
	}

	static function secondsToTimeout(timeout:Null<Float>):Term {
		if (timeout == null)
			return untyped __elixir__(':infinity');
		if (timeout <= 0)
			return 0;
		return Math.ceil(timeout * 1000);
	}

	public static function server_loop(ref:Term, queue:Term, promised:Int, waiters:Term):Void {
		untyped __elixir__('
            receive do
              {:run, event} ->
                EventLoopRuntime.notify_waiters({0}, :queue.in(event, {1}), {2}, {3})

              :promise ->
                EventLoopRuntime.server_loop({0}, {1}, {2} + 1, {3})

              {:run_promised, event} ->
                EventLoopRuntime.notify_waiters({0}, :queue.in(event, {1}), max({2} - 1, 0), {3})

              {:drain, caller, token} ->
                events = :queue.to_list({1})
                send(caller, {:event_loop_drain, {0}, token, events, {2}})
                EventLoopRuntime.server_loop({0}, :queue.new(), {2}, {3})

              {:wait, caller, token} ->
                if :queue.is_empty({1}) and {2} == 0 do
                  EventLoopRuntime.server_loop({0}, {1}, {2}, :queue.in({caller, token}, {3}))
                else
                  send(caller, {:event_loop_wait, {0}, token, true})
                  EventLoopRuntime.server_loop({0}, {1}, {2}, {3})
                end

              {:cancel_wait, token} ->
                filtered =
                  {3}
                  |> :queue.to_list()
                  |> Enum.reject(fn {_caller, waiter_token} -> waiter_token == token end)
                  |> Enum.reduce(:queue.new(), fn waiter, acc -> :queue.in(waiter, acc) end)
                EventLoopRuntime.server_loop({0}, {1}, {2}, filtered)
            end
        ', ref, queue, promised, waiters);
	}

	public static function notify_waiters(ref:Term, queue:Term, promised:Int, waiters:Term):Void {
		untyped __elixir__('(
            Enum.each(:queue.to_list({3}), fn {caller, token} ->
              send(caller, {:event_loop_wait, {0}, token, true})
            end)
            EventLoopRuntime.server_loop({0}, {1}, {2}, :queue.new())
        )', ref, queue, promised, waiters);
	}
}

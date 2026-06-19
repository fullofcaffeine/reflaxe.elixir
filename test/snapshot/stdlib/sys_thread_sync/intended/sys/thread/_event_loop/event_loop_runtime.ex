defmodule EventLoopRuntime do
  def create() do
    (
            ref = make_ref()
            pid = spawn(fn -> EventLoopRuntime.server_loop(ref, :queue.new(), 0, :queue.new()) end)
            {ref, pid}
        )
  end
  def run(ref, event) do
    (
            {_loop_ref, pid} = ref
            send(pid, {:run, event})
            :ok
        )
  end
  def promise(ref) do
    (
            {_loop_ref, pid} = ref
            send(pid, :promise)
            :ok
        )
  end
  def run_promised(ref, event) do
    (
            {_loop_ref, pid} = ref
            send(pid, {:run_promised, event})
            :ok
        )
  end
  def repeat(ref, event, interval_ms) do
    if (interval_ms < 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.thread.EventLoop.repeat interval must be >= 0"]
    end
    (
            loop_ref = ref
            interval = max(interval_ms, 0)
            timer_pid = spawn(fn ->
              repeat_fn = fn repeat_fn ->
                receive do
                  :cancel -> :ok
                after
                  interval ->
                    EventLoopRuntime.run(loop_ref, event)
                    repeat_fn.(repeat_fn)
                end
              end
              repeat_fn.(repeat_fn)
            end)
            timer_pid
        )
  end
  def cancel(handler) do
    send(handler, :cancel)
  end
  def drain(ref) do
    (
            {loop_ref, pid} = ref
            token = make_ref()
            send(pid, {:drain, self(), token})
            receive do
              {:event_loop_drain, ^loop_ref, ^token, events, promised} -> {events, promised}
            end
        )
  end
  def run_drained_events(info) do
    (
            {events, _promised} = info
            Enum.each(events, fn event -> event.() end)
            events != []
        )
  end
  def has_promised_events(info) do
    (
            {_events, promised} = info
            promised > 0
        )
  end
  def wait(ref, timeout) do
    timeout_ms = seconds_to_timeout(timeout)
    (
            {loop_ref, pid} = ref
            token = make_ref()
            send(pid, {:wait, self(), token})
            receive do
              {:event_loop_wait, ^loop_ref, ^token, ok} -> ok
            after
              timeout_ms ->
                send(pid, {:cancel_wait, token})
                false
            end
        )
  end
  defp seconds_to_timeout(timeout) do
    if (Reflaxe.Elixir.HaxeFloat.eq(timeout, nil)) do
      :infinity
    else
      if (Reflaxe.Elixir.HaxeFloat.lte(timeout, 0)) do
        0
      else
        Reflaxe.Elixir.HaxeFloat.ceil_int(Reflaxe.Elixir.HaxeFloat.mul(timeout, 1000))
      end
    end
  end
  def server_loop(ref, queue, promised, waiters) do
    
            receive do
              {:run, event} ->
                EventLoopRuntime.notify_waiters(ref, :queue.in(event, queue), promised, waiters)

              :promise ->
                EventLoopRuntime.server_loop(ref, queue, promised + 1, waiters)

              {:run_promised, event} ->
                EventLoopRuntime.notify_waiters(ref, :queue.in(event, queue), max(promised - 1, 0), waiters)

              {:drain, caller, token} ->
                events = :queue.to_list(queue)
                send(caller, {:event_loop_drain, ref, token, events, promised})
                EventLoopRuntime.server_loop(ref, :queue.new(), promised, waiters)

              {:wait, caller, token} ->
                if :queue.is_empty(queue) and promised == 0 do
                  EventLoopRuntime.server_loop(ref, queue, promised, :queue.in({caller, token}, waiters))
                else
                  send(caller, {:event_loop_wait, ref, token, true})
                  EventLoopRuntime.server_loop(ref, queue, promised, waiters)
                end

              {:cancel_wait, token} ->
                filtered =
                  waiters
                  |> :queue.to_list()
                  |> Enum.reject(fn {_caller, waiter_token} -> waiter_token == token end)
                  |> Enum.reduce(:queue.new(), fn waiter, acc -> :queue.in(waiter, acc) end)
                EventLoopRuntime.server_loop(ref, queue, promised, filtered)
            end
        
  end
  def notify_waiters(ref, queue, promised, waiters) do
    (
            Enum.each(:queue.to_list(waiters), fn {caller, token} ->
              send(caller, {:event_loop_wait, ref, token, true})
            end)
            EventLoopRuntime.server_loop(ref, queue, promised, :queue.new())
        )
  end
end

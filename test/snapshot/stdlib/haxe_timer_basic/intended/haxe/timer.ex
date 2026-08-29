defmodule Haxe.Timer do
  def new(time_ms, defer_start \\ nil) do
    struct = %{:__reflaxe_class__ => Haxe.Timer, :thread => nil, :event_handler => nil, :callback_ref => nil}
    struct = %{struct | callback_ref: Reflaxe.Elixir.Runtime.TimerRuntime.create()}
    struct = if (defer_start != true) do
      struct = %{struct | thread: Sys.Thread.Thread.current()}
      ref = struct.callback_ref
      reflaxe_dispatch_receiver = Sys.Thread.Thread.get_events(struct.thread)
      %{struct | event_handler: apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :repeat, [reflaxe_dispatch_receiver, fn -> Reflaxe.Elixir.Runtime.TimerRuntime.invoke(ref, fn -> nil end) end, time_ms])}
    else
      struct
    end
    struct
  end
  def stop(struct) do
    if (not Kernel.is_nil(struct.thread) and not Kernel.is_nil(struct.event_handler)) do
      reflaxe_dispatch_receiver = Sys.Thread.Thread.get_events(struct.thread)
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :cancel, [reflaxe_dispatch_receiver, struct.event_handler])
    end
    if (not Kernel.is_nil(struct.callback_ref)) do
      Reflaxe.Elixir.Runtime.TimerRuntime.delete(struct.callback_ref)
    end
    struct = %{struct | event_handler: nil}
    struct = %{struct | callback_ref: nil}
    struct
  end
  def run(_struct) do

  end
  def delay(f, time_ms) do
    timer = Haxe.Timer.new(time_ms, true)
    ref = timer.callback_ref
    Reflaxe.Elixir.Runtime.TimerRuntime.store_callback(ref, fn ->
      Reflaxe.Elixir.Runtime.TimerRuntime.delete(ref)
      f.()
    end)
    timer = %{timer | thread: Sys.Thread.Thread.current()}
    events = Sys.Thread.Thread.get_events(timer.thread)
    timer = %{timer | event_handler: apply(EventLoopRuntime, :run_delayed, [events.ref, fn -> Reflaxe.Elixir.Runtime.TimerRuntime.invoke(ref, fn -> nil end) end, time_ms])}
    timer
  end
  def measure(f, pos \\ nil) do
    start = stamp()
    Log.__get_trace().("#{Reflaxe.Elixir.HaxeFloat.to_string(Reflaxe.Elixir.HaxeFloat.sub(stamp(), start))}s", pos)
    f.()
  end
  def stamp() do
    System.monotonic_time(:nanosecond) / 1_000_000_000.0
  end
  def __set_run(timer, f) do
    Reflaxe.Elixir.Runtime.TimerRuntime.store_callback(timer.callback_ref, f)
    f
  end
  def __get_run(timer) do
    Reflaxe.Elixir.Runtime.TimerRuntime.get(timer.callback_ref, fn -> Reflaxe.Elixir.Runtime.TimerRuntime.invoke_default(timer) end)
  end
  def __invoke_run(timer) do
    Reflaxe.Elixir.Runtime.TimerRuntime.invoke(timer.callback_ref, fn -> Reflaxe.Elixir.Runtime.TimerRuntime.invoke_default(timer) end)
  end
end

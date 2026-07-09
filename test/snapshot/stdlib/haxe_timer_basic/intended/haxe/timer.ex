defmodule Haxe.Timer do
  def new(time_ms, defer_start) do
    struct = %{:__reflaxe_class__ => Haxe.Timer, :thread => nil, :event_handler => nil, :callback_ref => nil}
    struct = %{struct | callback_ref: Haxe.TimerRuntime.create()}
    struct = if (defer_start != true) do
      struct = %{struct | thread: Sys.Thread.Thread.current()}
      ref = struct.callback_ref
      reflaxe_dispatch_receiver = Sys.Thread.Thread.get_events(struct.thread)
      %{struct | event_handler: apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :repeat, [reflaxe_dispatch_receiver, fn -> Haxe.TimerRuntime.invoke(ref, fn -> nil end) end, time_ms])}
    else
      struct
    end
    struct
  end
  def stop(struct) do
    if (not Kernel.is_nil(struct.thread) and Reflaxe.Elixir.HaxeFloat.neq(struct.event_handler, nil)) do
      reflaxe_dispatch_receiver = Sys.Thread.Thread.get_events(struct.thread)
      _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :cancel, [reflaxe_dispatch_receiver, struct.event_handler])
    end
    if (Reflaxe.Elixir.HaxeFloat.neq(struct.callback_ref, nil)) do
      Haxe.TimerRuntime.delete(struct.callback_ref)
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
    _ =
      Haxe.TimerRuntime.store_callback(ref, fn ->
        _ = Haxe.TimerRuntime.delete(ref)
        _ = f.()
      end)
    timer = %{timer | thread: Sys.Thread.Thread.current()}
    events = Sys.Thread.Thread.get_events(timer.thread)
    timer = %{timer | event_handler: apply(EventLoopRuntime, :run_delayed, [events.ref, fn -> Haxe.TimerRuntime.invoke(ref, fn -> nil end) end, time_ms])}
    timer
  end
  def measure(f, pos) do
    start = stamp()
    _ = Log.trace("#{Reflaxe.Elixir.HaxeFloat.to_string(Reflaxe.Elixir.HaxeFloat.sub(stamp(), start))}s", pos)
    f.()
  end
  def stamp() do
    System.monotonic_time(:nanosecond) / 1_000_000_000.0
  end
  def __set_run(timer, f) do
    _ = Haxe.TimerRuntime.store_callback(timer.callback_ref, f)
    f
  end
  def __get_run(timer) do
    Haxe.TimerRuntime.get(timer.callback_ref, fn -> Haxe.TimerRuntime.invoke_default(timer) end)
  end
  def __invoke_run(timer) do
    Haxe.TimerRuntime.invoke(timer.callback_ref, fn -> Haxe.TimerRuntime.invoke_default(timer) end)
  end
end

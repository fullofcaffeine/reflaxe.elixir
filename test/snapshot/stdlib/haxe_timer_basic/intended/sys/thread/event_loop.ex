defmodule Sys.Thread.EventLoop do
  def new() do
    struct = %{:__reflaxe_class__ => Sys.Thread.EventLoop, :ref => nil}
    struct = %{struct | ref: EventLoopRuntime.create()}
    struct
  end
  def repeat(struct, event, interval_ms) do
    EventLoopRuntime.repeat(struct.ref, event, interval_ms)
  end
  def cancel(_struct, event_handler) do
    EventLoopRuntime.cancel(event_handler)
  end
  def promise(struct) do
    EventLoopRuntime.promise(struct.ref)
  end
  def run(struct, event) do
    EventLoopRuntime.run(struct.ref, event)
  end
  def run_promised(struct, event) do
    EventLoopRuntime.run_promised(struct.ref, event)
  end
  def progress(struct) do
    info = EventLoopRuntime.drain(struct.ref)
    ran = EventLoopRuntime.run_drained_events(info)
    if (ran) do
      {:now}
    else
      if (EventLoopRuntime.has_promised_events(info)), do: {:any_time, nil}, else: {:never}
    end
  end
  def wait(struct, timeout) do
    EventLoopRuntime.wait(struct.ref, timeout)
  end
  def loop(struct) do
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
      try do
        (case apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :progress, [struct]) do
          {:now} -> nil
          {:never} -> throw({:break, acc})
          {:any_time, payload_struct} ->
            apply(Map.get(payload_struct, :__reflaxe_class__) || Map.get(payload_struct, :__struct__), :wait, [payload_struct, nil])
          {:at, time} ->
            apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :wait, (fn -> [struct, (fn ->
              b = Reflaxe.Elixir.HaxeFloat.sub(time, System.system_time(:second))
              Reflaxe.Elixir.HaxeFloat.max(0, b)
            end).()] end).())
        end)
        {:cont, acc}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, acc}
        :throw, :continue ->
          {:cont, acc}
      end
    end)
  end
end

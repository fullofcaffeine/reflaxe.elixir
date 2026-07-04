defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp require_message(expected) do
    actual = Sys.Thread.Thread.read_message(false)
    if (actual != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "expected " <> expected <> ", got " <> actual]
    end
  end
  defp drive_timer_once() do
    events = Sys.Thread.Thread.get_events(Sys.Thread.Thread.current())
    _ = assert_that(apply(Map.get(events, :__reflaxe_class__) || Map.get(events, :__struct__), :wait, [events, 0.2]), "timer event did not become ready")
    _ = apply(Map.get(events, :__reflaxe_class__) || Map.get(events, :__struct__), :progress, [events])
  end
  def main() do
    manual = Haxe.Timer.new(1000, nil)
    _ = Haxe.Timer.__set_run(manual, fn ->
  reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "manual-1"])
end)
    _ = Haxe.Timer.__invoke_run(manual)
    _ = require_message("manual-1")
    run_ref = Haxe.Timer.__get_run(manual)
    _ = run_ref.()
    _ = require_message("manual-1")
    _ = Haxe.Timer.__set_run(manual, fn ->
  reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "manual-2"])
end)
    _ = Haxe.Timer.__invoke_run(manual)
    _ = require_message("manual-2")
    _ = apply(Map.get(manual, :__reflaxe_class__) || Map.get(manual, :__struct__), :stop, [manual])
    repeated = Haxe.Timer.new(1, nil)
    _ = Haxe.Timer.__set_run(repeated, fn ->
  reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "tick"])
end)
    _ = drive_timer_once()
    _ = require_message("tick")
    _ = drive_timer_once()
    _ = require_message("tick")
    _ = apply(Map.get(repeated, :__reflaxe_class__) || Map.get(repeated, :__struct__), :stop, [repeated])
    _ = Haxe.Timer.delay(fn ->
  reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "delay"])
end, 1)
    _ = drive_timer_once()
    _ = require_message("delay")
    start = Haxe.Timer.stamp()
    milliseconds = 1
    Process.sleep(milliseconds)
    _ = assert_that(Reflaxe.Elixir.HaxeFloat.gte(Haxe.Timer.stamp(), start), "stamp should be monotonic")
    _ = assert_that(Haxe.Timer.measure(fn -> "ok" end, %{file_name: "Main.hx", line_number: 60, class_name: "Main", method_name: "main"}) == "ok", "measure should return result")
  end
end

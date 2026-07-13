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
    assert_that(apply(Map.get(events, :__reflaxe_class__) || Map.get(events, :__struct__), :wait, [events, 0.2]), "timer event did not become ready")
    apply(Map.get(events, :__reflaxe_class__) || Map.get(events, :__struct__), :progress, [events])
  end
  def main() do
    manual = Haxe.Timer.new(1000, nil)
    Haxe.Timer.__set_run(manual, fn ->
      reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "manual-1"])
    end)
    Haxe.Timer.__invoke_run(manual)
    require_message("manual-1")
    run_ref = Haxe.Timer.__get_run(manual)
    run_ref.()
    require_message("manual-1")
    Haxe.Timer.__set_run(manual, fn ->
      reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "manual-2"])
    end)
    Haxe.Timer.__invoke_run(manual)
    require_message("manual-2")
    apply(Map.get(manual, :__reflaxe_class__) || Map.get(manual, :__struct__), :stop, [manual])
    repeated = Haxe.Timer.new(1, nil)
    Haxe.Timer.__set_run(repeated, fn ->
      reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "tick"])
    end)
    drive_timer_once()
    require_message("tick")
    drive_timer_once()
    require_message("tick")
    apply(Map.get(repeated, :__reflaxe_class__) || Map.get(repeated, :__struct__), :stop, [repeated])
    Haxe.Timer.delay(fn ->
      reflaxe_dispatch_receiver = Sys.Thread.Thread.current()
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :send_message, [reflaxe_dispatch_receiver, "delay"])
    end, 1)
    drive_timer_once()
    require_message("delay")
    start = Haxe.Timer.stamp()
    milliseconds = 1
    Process.sleep(milliseconds)
    assert_that(Reflaxe.Elixir.HaxeFloat.gte(Haxe.Timer.stamp(), start), "stamp should be monotonic")
    assert_that(Haxe.Timer.measure(fn -> "ok" end, %{file_name: "Main.hx", line_number: 60, class_name: "Main", method_name: "main"}) == "ok", "measure should return result")
  end
end

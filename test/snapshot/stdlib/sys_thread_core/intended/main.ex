defmodule Main do
  def main() do
    current = Sys.Thread.Thread.current()
    _ = apply(Map.get(current, :__reflaxe_class__) || Map.get(current, :__struct__), :send_message, [current, "self-message"])
    if (Reflaxe.Elixir.HaxeFloat.neq(Sys.Thread.Thread.read_message(false), "self-message")) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Thread self message mismatch"]
    end
    if (Reflaxe.Elixir.HaxeFloat.neq(Sys.Thread.Thread.read_message(false), nil)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Thread non-blocking empty read should return null"]
    end
    deque = Sys.Thread.Deque.new()
    _ = apply(Map.get(deque, :__reflaxe_class__) || Map.get(deque, :__struct__), :add, [deque, "tail"])
    _ = apply(Map.get(deque, :__reflaxe_class__) || Map.get(deque, :__struct__), :push, [deque, "head"])
    if (apply(Map.get(deque, :__reflaxe_class__) || Map.get(deque, :__struct__), :pop, [deque, false]) != "head" or apply(Map.get(deque, :__reflaxe_class__) || Map.get(deque, :__struct__), :pop, [deque, false]) != "tail" or not Kernel.is_nil(apply(Map.get(deque, :__reflaxe_class__) || Map.get(deque, :__struct__), :pop, [deque, false]))) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Deque order mismatch"]
    end
    mailbox = Sys.Thread.Thread.current()
    blocking_deque = Sys.Thread.Deque.new()
    _ =
      Sys.Thread.Thread.create(fn ->
        _ = apply(Map.get(blocking_deque, :__reflaxe_class__) || Map.get(blocking_deque, :__struct__), :add, [blocking_deque, "from-child"])
        _ = apply(Map.get(mailbox, :__reflaxe_class__) || Map.get(mailbox, :__struct__), :send_message, [mailbox, "child-finished"])
      end)
    if (apply(Map.get(blocking_deque, :__reflaxe_class__) || Map.get(blocking_deque, :__struct__), :pop, [blocking_deque, true]) != "from-child") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Deque blocking pop mismatch"]
    end
    if (Reflaxe.Elixir.HaxeFloat.neq(Sys.Thread.Thread.read_message(true), "child-finished")) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Thread child message mismatch"]
    end
    tls = Sys.Thread.Tls.new()
    _ = Sys.Thread.Tls.set_value(tls, "main")
    tls_mailbox = Sys.Thread.Thread.current()
    _ =
      Sys.Thread.Thread.create(fn ->
        _ = Sys.Thread.Tls.set_value(tls, "child")
        _ = apply(Map.get(tls_mailbox, :__reflaxe_class__) || Map.get(tls_mailbox, :__struct__), :send_message, [tls_mailbox, Sys.Thread.Tls.get_value(tls)])
      end)
    if (Reflaxe.Elixir.HaxeFloat.neq(Sys.Thread.Thread.read_message(true), "child")) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Tls child value mismatch"]
    end
    if (Sys.Thread.Tls.get_value(tls) != "main") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Tls main value mismatch"]
    end
    loop = Sys.Thread.EventLoop.new()
    loop_mailbox = Sys.Thread.Thread.current()
    _ = apply(Map.get(loop, :__reflaxe_class__) || Map.get(loop, :__struct__), :run, [loop, fn -> apply(Map.get(loop_mailbox, :__reflaxe_class__) || Map.get(loop_mailbox, :__struct__), :send_message, [loop_mailbox, "loop-ran"]) end])
    (case apply(Map.get(loop, :__reflaxe_class__) || Map.get(loop, :__struct__), :progress, [loop]) do
      {:now} -> nil
      _ ->
        other = apply(Map.get(loop, :__reflaxe_class__) || Map.get(loop, :__struct__), :progress, [loop])
        raise Reflaxe.Elixir.HaxeThrow, [value: "EventLoop progress should return Now, got " <> Reflaxe.Elixir.HaxeFloat.to_string(other)]
    end)
    if (Reflaxe.Elixir.HaxeFloat.neq(Sys.Thread.Thread.read_message(true), "loop-ran")) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "EventLoop run did not execute callback"]
    end
  end
end

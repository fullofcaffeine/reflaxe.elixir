defmodule Main do
  def main() do
    p = Sys.IO.Process.new("sh", ["-c", "printf hello"], nil)
    reflaxe_dispatch_receiver = p.stdout
    reflaxe_dispatch_receiver = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :read_all, [reflaxe_dispatch_receiver, nil])
    out = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
    code = apply(Map.get(p, :__reflaxe_class__) || Map.get(p, :__struct__), :exit_code, [p, true])
    _ = apply(Map.get(p, :__reflaxe_class__) || Map.get(p, :__struct__), :close, [p])
    detached = Sys.IO.Process.new("sh", ["-c", "exit 3"], true)
    detached_code = apply(Map.get(detached, :__reflaxe_class__) || Map.get(detached, :__struct__), :exit_code, [detached, true])
    _ = apply(Map.get(detached, :__reflaxe_class__) || Map.get(detached, :__struct__), :close, [detached])
    if (out != "hello") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.io.Process stdout mismatch: \"" <> out <> "\""]
    end
    if (code != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.io.Process exitCode mismatch: " <> Reflaxe.Elixir.HaxeFloat.to_string(code)]
    end
    if (detached_code != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.io.Process detached exitCode mismatch: " <> Reflaxe.Elixir.HaxeFloat.to_string(detached_code)]
    end
  end
end

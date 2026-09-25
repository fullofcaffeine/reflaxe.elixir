defmodule Main do
  defp receiver(label) do
    IO.puts(label <> ":receiver")
    EReg.new("^[a-z]+$", "")
  end
  defp argument(label, value) do
    IO.puts(label <> ":argument")
    value
  end
  defp left(label, value) do
    IO.puts(label <> ":left")
    value
  end
  defp rejects(value) do
    String.length(value) != 3 or not (reflaxe_dispatch_receiver_node_0 = EReg.new("^[a-z]+$", "")
    apply(Map.get(reflaxe_dispatch_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_0, :__struct__), :match, [reflaxe_dispatch_receiver_node_0, value]))
  end
  defp fail() do
    IO.puts("throw:argument")
    raise Reflaxe.Elixir.HaxeThrow, [value: "expected"]
  end
  def main() do
    if (rejects("abc") or not rejects("a!c") or not rejects("abcd")) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "validation changed"]
    end
    v = left("or-skip", true) or not (reflaxe_dispatch_receiver_node_1 = receiver("unexpected")
    apply(Map.get(reflaxe_dispatch_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_1, :__struct__), :match, [reflaxe_dispatch_receiver_node_1, argument("unexpected", "abc")]))
    IO.puts(v)
    v = left("or-run", false) or not (reflaxe_dispatch_receiver_node_2 = receiver("or-run")
    apply(Map.get(reflaxe_dispatch_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_2, :__struct__), :match, [reflaxe_dispatch_receiver_node_2, argument("or-run", "a!c")]))
    IO.puts(v)
    v = left("and-skip", false) and not (reflaxe_dispatch_receiver_node_3 = receiver("unexpected")
    apply(Map.get(reflaxe_dispatch_receiver_node_3, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_3, :__struct__), :match, [reflaxe_dispatch_receiver_node_3, argument("unexpected", "abc")]))
    IO.puts(v)
    v = left("and-run", true) and not (reflaxe_dispatch_receiver_node_4 = receiver("and-run")
    apply(Map.get(reflaxe_dispatch_receiver_node_4, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_4, :__struct__), :match, [reflaxe_dispatch_receiver_node_4, argument("and-run", "abc")]))
    IO.puts(v)
    v = not (reflaxe_dispatch_receiver_node_5 = receiver("standalone")
    apply(Map.get(reflaxe_dispatch_receiver_node_5, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_5, :__struct__), :match, [reflaxe_dispatch_receiver_node_5, argument("standalone", "a!c")]))
    IO.puts(v)
    reflaxe_dispatch_receiver_node_6 = receiver("double")
    v = apply(Map.get(reflaxe_dispatch_receiver_node_6, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_6, :__struct__), :match, [reflaxe_dispatch_receiver_node_6, argument("double", "abc")])
    IO.puts(v)
    v = -(IO.puts("numeric:block")
    7)
    IO.puts(v)
    try do
      v = left("throw", false) or not (reflaxe_dispatch_receiver_node_7 = receiver("throw")
    apply(Map.get(reflaxe_dispatch_receiver_node_7, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_7, :__struct__), :match, [reflaxe_dispatch_receiver_node_7, fail()]))
      IO.puts(v)
      raise Reflaxe.Elixir.HaxeThrow, [value: "unreachable"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {message, _} when is_binary(message) ->
            if (message != "expected") do
              raise Reflaxe.Elixir.HaxeThrow, [value: message]
            end
            IO.puts("throw:caught")
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
end

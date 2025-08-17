defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * MapTools functional methods test case
     * Tests MapTools static extension methods for proper compilation to idiomatic Elixir
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    _g = Haxe.Ds.StringMap.new()
    _g.set("one", 1)
    _g.set("two", 2)
    _g.set("three", 3)
    _g.set("four", 4)
    _g.set("five", 5)
    count = Map.size(_g)
    Log.trace("Map size: " <> Integer.to_string(count), %{"fileName" => "Main.hx", "lineNumber" => 13, "className" => "Main", "methodName" => "main"})
    not_empty = Map.equal?(_g, %{})
    Log.trace("Numbers empty check: " <> Std.string(not_empty), %{"fileName" => "Main.hx", "lineNumber" => 17, "className" => "Main", "methodName" => "main"})
    empty = Haxe.Ds.StringMap.new()
    is_empty_result = Map.equal?(empty, %{})
    Log.trace("Empty map check: " <> Std.string(is_empty_result), %{"fileName" => "Main.hx", "lineNumber" => 22, "className" => "Main", "methodName" => "main"})
    has_even = Enum.any?(Map.to_list(_g), fn {k, v} -> v rem 2 == 0 end)
    Log.trace("Has even values: " <> Std.string(has_even), %{"fileName" => "Main.hx", "lineNumber" => 26, "className" => "Main", "methodName" => "main"})
    all_positive = Enum.all?(Map.to_list(_g), fn {k, v} -> v > 0 end)
    Log.trace("All positive: " <> Std.string(all_positive), %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "main"})
    sum = Map.fold(_g, 0, fn k, v, acc -> acc + v end)
    Log.trace("Sum of values: " <> Integer.to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 34, "className" => "Main", "methodName" => "main"})
    found = Enum.find(Map.to_list(_g), fn {k, v} -> v > 3 end)
    if (found != nil), do: Log.trace("Found item with value > 3: " <> found.key <> " = " <> Integer.to_string(found.value), %{"fileName" => "Main.hx", "lineNumber" => 39, "className" => "Main", "methodName" => "main"}), else: nil
    key_array = Map.keys(_g)
    Log.trace("Keys array length: " <> Integer.to_string(length(key_array)), %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "main"})
    value_array = Map.values(_g)
    Log.trace("Values array length: " <> Integer.to_string(length(value_array)), %{"fileName" => "Main.hx", "lineNumber" => 48, "className" => "Main", "methodName" => "main"})
    pair_array = Map.to_list(_g)
    Log.trace("Pairs array length: " <> Integer.to_string(length(pair_array)), %{"fileName" => "Main.hx", "lineNumber" => 52, "className" => "Main", "methodName" => "main"})
  end

end

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
    g = %{}
    g.set("one", 1)
    g.set("two", 2)
    g.set("three", 3)
    g.set("four", 4)
    g.set("five", 5)
    count = Map.size(g)
    Log.trace("Map size: " <> Integer.to_string(count), %{"fileName" => "Main.hx", "lineNumber" => 13, "className" => "Main", "methodName" => "main"})
    not_empty = MapTools.is_empty(g)
    Log.trace("Numbers empty check: " <> Std.string(not_empty), %{"fileName" => "Main.hx", "lineNumber" => 17, "className" => "Main", "methodName" => "main"})
    empty = %{}
    is_empty_result = MapTools.is_empty(empty)
    Log.trace("Empty map check: " <> Std.string(is_empty_result), %{"fileName" => "Main.hx", "lineNumber" => 22, "className" => "Main", "methodName" => "main"})
    has_even = Enum.any?(Map.to_list(g), fn {k, v} -> v rem 2 == 0 end)
    Log.trace("Has even values: " <> Std.string(has_even), %{"fileName" => "Main.hx", "lineNumber" => 26, "className" => "Main", "methodName" => "main"})
    all_positive = Enum.all?(Map.to_list(g), fn {k, v} -> v > 0 end)
    Log.trace("All positive: " <> Std.string(all_positive), %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "main"})
    sum = Map.fold(g, 0, fn k, v, acc -> acc + v end)
    Log.trace("Sum of values: " <> Integer.to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 34, "className" => "Main", "methodName" => "main"})
    found = Enum.find(Map.to_list(g), fn {k, v} -> v > 3 end)
    if (found != nil), do: Log.trace("Found item with value > 3: " <> found.key <> " = " <> Integer.to_string(found.value), %{"fileName" => "Main.hx", "lineNumber" => 39, "className" => "Main", "methodName" => "main"}), else: nil
    key_array = Map.keys(g)
    Log.trace("Keys array length: " <> Integer.to_string(key_array.length), %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "main"})
    value_array = Map.values(g)
    Log.trace("Values array length: " <> Integer.to_string(value_array.length), %{"fileName" => "Main.hx", "lineNumber" => 48, "className" => "Main", "methodName" => "main"})
    pair_array = MapTools.to_array(g)
    Log.trace("Pairs array length: " <> Integer.to_string(pair_array.length), %{"fileName" => "Main.hx", "lineNumber" => 52, "className" => "Main", "methodName" => "main"})
  end

end
